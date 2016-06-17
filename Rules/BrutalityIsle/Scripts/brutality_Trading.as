//not server only so the client also gets the game event setup stuff

#include "GameplayEvents.as"
#include "Logging.as"

const int coinsOnRestartAdd = 0;
const bool keepCoinsOnRestart = false;

const int coinsOnBuild = 4;
const int coinsOnBuildWood = 1;
const int coinsOnBuildWorkshop = 10;

const int coinsOnKillCrop = 20; // given for farming grain or mushrooms
const int coinsOnKillZombieChicken = 20; // given for farming grain or mushrooms
const int coinsOnKillZombie = 40; 
const int coinsOnKillShark = 60; 
const int coinsOnKillBison = 60; 
const int coinsOnKillEagle = 60; 
const int coinsOnKillCrocodile = 80; 
const int coinsOnKillTree = 10; 
const int coinsOnKillPurpleGold = 10; 

string[] names;

void GiveRestartCoins(CPlayer@ p)
{
	if (keepCoinsOnRestart)
		p.server_setCoins(p.getCoins() + coinsOnRestartAdd);
	else
		p.server_setCoins(coinsOnRestartAdd);
}

void GiveRestartCoinsIfNeeded(CPlayer@ player)
{
	const string s = player.getUsername();
	for (uint i = 0; i < names.length; ++i)
	{
		if (names[i] == s)
		{
			return;
		}
	}

	names.push_back(s);
	GiveRestartCoins(player);
}

//extra coins on start to prevent stagnant round start
void Reset(CRules@ this)
{
	if (!getNet().isServer())
		return;

	names.clear();

	uint count = getPlayerCount();
	for (uint p_step = 0; p_step < count; ++p_step)
	{
		CPlayer@ p = getPlayer(p_step);
		GiveRestartCoins(p);
		names.push_back(p.getUsername());
	}
}

void onRestart(CRules@ this)
{
	Reset(this);
}

void onInit(CRules@ this)
{
	Reset(this);

    this.addCommandID("coins for kill");
}

//also given when plugging player -> on first spawn
void onSetPlayer(CRules@ this, CBlob@ blob, CPlayer@ player)
{
	if (!getNet().isServer())
		return;

	if (player !is null)
	{
		GiveRestartCoinsIfNeeded(player);
	}
}

void onBlobDie(CRules@ this, CBlob@ blob)
{
	//only important on server
	if (!getNet().isServer())
		return;

    //log("onBlobDie", "Hook called. blob died: " + blob.getName());

    CPlayer@ player = blob.getPlayerOfRecentDamage();
    string blobname = blob.getName();
    if (player is null)
    {
        log("onBlobDie", "player is null");
        return;
    }
    else if (blobname == "grain_plant" || blobname == "mushroom_plant")
    {
        log("onBlobDie", "blobname is grain_plant/mushroom_plant");

        if (blob.hasTag("has grain") || blob.hasTag("has mushroom"))
            AwardCoins(player, coinsOnKillCrop);
        else
            log("onBlobDie", "crop is not fully grown so not awarding coins");
    }
    else if (blobname == "zombie_chicken")
    {
        log("onBlobDie", "blobname is zombie_chicken");
        AwardCoins(player, coinsOnKillZombieChicken);
    }
    else if (blobname == "zombie")
    {
        log("onBlobDie", "blobname is zombie");
        AwardCoins(player, coinsOnKillZombie);
    }
    else if (blobname == "shark")
    {
        log("onBlobDie", "blobname is shark");
        AwardCoins(player, coinsOnKillShark);
    }
    else if (blobname == "bison")
    {
        log("onBlobDie", "blobname is bison");
        AwardCoins(player, coinsOnKillBison);
    }
    else if (blobname == "eagle")
    {
        log("onBlobDie", "blobname is eagle");
        AwardCoins(player, coinsOnKillEagle);
    }
    else if (blobname == "crocodile")
    {
        log("onBlobDie", "blobname is crocodile");
        AwardCoins(player, coinsOnKillCrocodile);
    }
    else if (blobname.length > 3 && blobname.substr(0,4) == "tree")
    {
        log("onBlobDie", "blobname is some kind of tree");
        AwardCoins(player, coinsOnKillTree);
    }
    else if (blobname == "purplegold")
    {
        log("onBlobDie", "blobname is purplegold");
        AwardCoins(player, coinsOnKillPurpleGold);
    }
}

void onCommand(CRules@ this, u8 cmd, CBitStream @params)
{
	//only important on server
	if (!getNet().isServer())
		return;

    log("onCommand", "Hook called");

    if (cmd == getGameplayEventID(this))
	{
		GameplayEvent g(params);

		CPlayer@ p = g.getPlayer();
		if (p !is null)
		{
			switch (g.getType())
			{
				case GE_built_block:

				{
					g.params.ResetBitIndex();
					u16 tile = g.params.read_u16();
					if (tile == CMap::tile_castle)
					{
                        AwardCoins(p, coinsOnBuild);
					}
					else if (tile == CMap::tile_wood)
					{
                        AwardCoins(p, coinsOnBuildWood);
					}
				}

				break;

				case GE_built_blob:

				{
					g.params.ResetBitIndex();
					string name = g.params.read_string();

					if (name.findFirst("door") != -1 ||
					        name == "wooden_platform" ||
					        name == "trap_block" ||
					        name == "spikes")
					{
                        AwardCoins(p, coinsOnBuild);
					}
					else if (name == "building")
					{
                        AwardCoins(p, coinsOnBuildWorkshop);
					}
				}

				break;
			}

		}
	}
}

void AwardCoins(CPlayer@ player, int amount)
{
    log("AwardCoins", "Awarding " + amount + " coins to " + player.getUsername());
    if (amount != 0)
    {
        player.server_setCoins(player.getCoins() + amount);
    }
}
