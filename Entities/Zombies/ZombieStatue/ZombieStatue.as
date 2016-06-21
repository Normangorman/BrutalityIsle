#include "Logging.as"
#include "brutality_Time.as"

const f32 min_spawn_dist = 40;
const f32 spawn_radius = 32;

void onInit(CBlob@ this)
{
    this.getShape().SetStatic(true);
    this.getCurrentScript().tickFrequency = 100;

    //this.set_TileType("background tile", CMap::tile_wood_back);

	this.getSprite().SetZ(-50); //background
	this.getShape().getConsts().mapCollisions = false;

    this.SetLight(true);
    this.SetLightRadius(96.0);
    this.SetLightColor(SColor(255,255,255,0));

    this.Tag("midnight_hook");
    this.addCommandID("midnight_hook");
}

f32 onHit( CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData )
{
    // Don't take damage
    return 0.0;
}

void onTick(CSprite@ this)
{
    //log("onTick(CSprite", "Hook called");
    if (isNight())
    {
        if (!this.isAnimation("active"))
        {
            log("onTick(CSprite", "Using active animation");
            this.SetAnimation("active");
        }
    }
    else
    {
        if (!this.isAnimation("default"))
        {
            log("onTick(CSprite", "Using default animation");
            this.SetAnimation("default");
        }
    }
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
    if (!getNet().isServer()) return;

    if (cmd == this.getCommandID("midnight_hook"))
    {
        SpawnZombieWave(this);
    }
}

void SpawnZombieWave(CBlob@ this)
{
    log("SpawnZombieWave", "Function called");
    
    CBlob@[] statues;
    getBlobsByName(this.getName(), statues);

    if (statues.length != 2)
    {
        log("SpawnZombieWave", "ERROR: Expecting there to be 2 zombie statues on map but there are actually " + statues.length);
        return;
    }

    CBlob@ other_statue = statues[0] is this ? statues[1] : statues[0];
    bool is_this_left_statue = other_statue.getPosition().x > this.getPosition().x;

    int dayNum = getDayNumber();
    int num_zombies_to_spawn_total = dayNum * 2; // spawns are divided between all existing zombie statues
    int num_zombies_to_spawn_here = 0;

    // Between days 1 and 7, alternate the spawns between the two statues
    // After day 8 spawn half the zombies at each statue
    if (dayNum < 8)
    {
        if (is_this_left_statue && (dayNum % 2 == 0)
                || ((!is_this_left_statue) && (dayNum % 2 == 1)))
        {
            num_zombies_to_spawn_here = num_zombies_to_spawn_total;
        }
    }
    else
    {
        num_zombies_to_spawn_here = num_zombies_to_spawn_total / 2;
    }

    log("SpawnZombieWave",
            "Is left statue: " + is_this_left_statue
            + ", Day num: " + dayNum
            + ", Number of zombies to spawn: " + num_zombies_to_spawn_here
            );
    for (int i=0; i < num_zombies_to_spawn_here; i++)
    {
        Vec2f spawnOffset = Vec2f(1,1);
        spawnOffset.RotateBy(XORRandom(360));
        spawnOffset *= min_spawn_dist + XORRandom(spawn_radius);

        Vec2f spawnPos = this.getPosition() + spawnOffset;

        for (int attempts=0; attempts < 3; attempts++)
        {
            if (!getMap().isTileSolid(spawnPos))
            {
                server_CreateBlob("zombie", -1, this.getPosition() + spawnOffset);
                break;
            }
        }
    }
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ other)
{
    return false;
}
