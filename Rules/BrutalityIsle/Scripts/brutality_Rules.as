#include "GameplayEvents.as"
#include "Logging.as"
#include "Modname.as"
#include "brutality_Time.as"

#define SERVER_ONLY

void doConfig(CRules@ this)
{
    log("doConfig", "Function called");
    ConfigFile cfg = ConfigFile("../Mods/" + getModname() + "/Rules/BrutalityIsle/brutality.cfg");

    this.set_u16(   "days survived to win" , cfg.read_u16("days_survived_to_win", 15)   );
    this.set_u16(   "no spawning after day", cfg.read_u16("no spawning after day", 3)   );
    this.set_string("default class"        , cfg.read_string("default_class", "builder"));


}

void doReset(CRules@ this)
{
    log("doReset", "Function called");
    sv_gravity = 9.81f;
    particles_gravity.y = 0.125f;

    doConfig(this);

    this.SetCurrentState(GAME);

    server_CreateBlob("stormmanager");
    server_CreateBlob("darknessshader");

    string[]@ active_player_usernames;
    this.get("active player usernames", @active_player_usernames);

    for (int i=0; i < active_player_usernames.length; i++)
    {
        CPlayer@ player = getPlayerByUsername(active_player_usernames[i]);

        doRespawn(this, player);
    }
}

CBlob@ doRespawn(CRules@ this, CPlayer@ player)
{
    log("doRespawn", "Function called");

	if (player !is null)
	{
		// remove previous players blob
		CBlob @blob = player.getBlob();

		if (blob !is null)
		{
			CBlob @blob = player.getBlob();
			blob.server_SetPlayer(null);
			blob.server_Die();
		}

		CBlob @newBlob = server_CreateBlob(this.get_string("default class"), 0, getSpawnLocation(player));
		newBlob.server_SetPlayer(player);
        newBlob.Tag("player"); // important for timemanager to do starvation damage
		return newBlob;
	}

	return null;
}

Vec2f getSpawnLocation(CPlayer@ player)
{
    log("getSpawnLocation", "Function called");
    Vec2f[] spawn_locs;

    if (getMap().getMarkers("blue spawn", spawn_locs))
    {
        return spawn_locs[ XORRandom(spawn_locs.length) ];
    }
    else if (getMap().getMarkers("blue main spawn", spawn_locs))
    {
        return spawn_locs[ XORRandom(spawn_locs.length) ];
    }

    log("BrutalityRespawns::getSpawnLocation", "[ERROR] Couldn't find spawn");
    return Vec2f(0, 0);
}

//////////////
// MAJOR HOOKS
void onInit(CRules@ this) // also in CoreHooks.as
{
    log("onInit", "Hook called");
    SetupGameplayEvents(this);
    string[] active_player_usernames;
    this.set("active player usernames", active_player_usernames);

    doReset(this);
}

void onRestart(CRules@ this)
{
    log("onRestart", "Hook called");
    doReset(this);
}

void onTick(CRules@ this)
{
    if (getGameTime() % 300 == 0)
    {
        log("onTick", "Checking for game win/lose");
        string[]@ active_player_usernames;
        this.get("active player usernames", @active_player_usernames);

        int num_players = active_player_usernames.length();
        int num_players_alive = getNumRemainingSurvivors();
        log("onTick", "num_players_alive=" + num_players_alive);

        if (num_players_alive == 0)
        {
            log("onTick", "Game lost!");
            this.SetTeamWon(0);
            this.SetCurrentState(GAME_OVER);
            this.SetGlobalMessage("You lose! The isle was just too brutal...");
        }
        else if (getDayNumber() >= this.get_u16("days survived to win"))
        {
            log("onTick", "Game won!");
            this.SetTeamWon(1);
            this.SetCurrentState(GAME_OVER);
            this.SetGlobalMessage("Congratulations! You have survived for 15 days - you win!");
            // TODO: Add names to hall of fame
        }
    }
}

void onPlayerDie(CRules@ this, CPlayer@ victim, CPlayer@ killer, u8 customData)
{
    log("onPlayerDie", "Hook called");
}

// also in JoinCoreHooks.as
void onNewPlayerJoin(CRules@ this, CPlayer@ player)
{
    log("onNewPlayerJoin", "Hook called. Player joined: " + player.getUsername());

    string[]@ active_player_usernames;
    this.get("active player usernames", @active_player_usernames);

    if (active_player_usernames.find(player.getUsername()) == -1)
        active_player_usernames.push_back(player.getUsername());
    else
        log("onNewPlayerJoin", "ERROR: Player " + player.getUsername() + " joined but their name is already in the list.");

    log("onNewPlayerJoin", "New number of players: " + active_player_usernames.length);
}

void onPlayerLeave(CRules@ this, CPlayer@ player)
{
    log("onPlayerLeave", "Hook called");

    string[]@ active_player_usernames;
    this.get("active player usernames", @active_player_usernames);

    int index = active_player_usernames.find(player.getUsername());
    if (index == -1)
    {
        log("onPlayerLeave", "ERROR: player " + player.getUsername() + " left but is not in active players list.");
    }
    else
    {
        log("onPlayerLeave", "Removing player: " + player.getUsername());
        active_player_usernames.removeAt(index);
        log("onPlayerLeave", "New number of players: " + active_player_usernames.length);
    }
}

void onPlayerRequestSpawn(CRules@ this, CPlayer@ player)
{
    log("onPlayerRequestSpawn", "Hook called");

    string[]@ active_player_usernames;
    this.get("active player usernames", @active_player_usernames);

    // Sanity check
    if (active_player_usernames.find(player.getUsername()) == -1)
    {
        log("onPlayerRequestSpawn", "ERROR: player " + player.getUsername() + " requested spawn but is not in active players list.");
    }
    else
    {
        bool canSpawn = sv_test || getDayNumber() <= this.get_u16("no spawning after day");

        if (canSpawn)
        {
            doRespawn(this, player);
        }
        else
        {
            log("onPlayerRequestSpawn", "canSpawn is false so not respawning player.");
        }
    }
}

void onStateChange(CRules@ this, const u8 oldState)
{
    log("onStateChange", "Hook called");
}

void onPlayerRequestTeamChange(CRules@ this, CPlayer@ player, u8 newteam)
{
    log("onPlayerRequestTeamChange", "Hook called");
}

//////////////
// MINOR HOOKS
void onCommand(CRules@ this, u8 cmd, CBitStream @params)
{
    log("onCommand", "Hook called");
}

void onReload(CRules@ this)
{
    log("onReload", "Hook called");
}


TileType server_onTileHit(CMap@ this, f32 damage, u32 index, TileType oldTileType)
{
    log("server_onTileHit", "Hook called");
    return oldTileType;
}

void onEnterChat(CRules@ this)
{
    log("onEnterChat", "Hook called");
}

void onExitChat(CRules@ this)
{
    log("onExitChat", "Hook called");
}

// Also in CoreHooks.as
void onSetPlayer(CRules@ this, CBlob@ blob, CPlayer@ player)
{
    log("onSetPlayer", "Hook called");

}

f32 onPlayerTakeDamage(CRules@ this, CPlayer@ victim, CPlayer@ attacker, f32 damageScale)
{
    //log("onPlayerTakeDamage", "Hook called");
    return damageScale;
}

/* Conflicts with chatCommands.as
bool onServerProcessChat(CRules@ this, const string &in textIn, string &out textOut, CPlayer@ player)
{
    log("onServerProcessChat", "Hook called");
    return true;
}
*/

void onPlayerChangedTeam(CRules@ this, CPlayer@ player, u8 oldteam, u8 newteam)
{
    log("onPlayerChangedTeam", "Hook called");
}

/*
void onBlobCreated(CRules@ this, CBlob@ blob)
{
    //log("onBlobCreated", "Hook called. blob created: " + blob.getName());
}
*/

/*
void onBlobDie(CRules@ this, CBlob@ blob)
{
    log("onBlobDie", "Hook called. blob died: " + blob.getName());
}
*/

void onBlobChangeTeam(CRules@ this, CBlob@ blob, const int oldTeam)
{
    //log("onBlobChangeTeam", "Hook called");
}

/* Seems to not be working? damageScale provided is always 0. Not used in Base/ anywhere.
f32 onBlobTakeDamage(CRules@ this, CBlob@ victim, CBlob@ attacker, f32 damageScale)
{
    log("onBlobTakeDamage", "Hook called. damageScale=" + damageScale);
    return damageScale;
}
*/

void onRulesRestart(CMap@ this, CRules@ rules)
{
    log("onRulesRestart", "Hook called");
}
