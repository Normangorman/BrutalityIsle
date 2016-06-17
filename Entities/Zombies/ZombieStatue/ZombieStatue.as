#include "Logging.as"
#include "brutality_Time.as"

const u8 spawn_zombie_chance = 4;
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
}

f32 onHit( CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData )
{
    // Don't take damage
    return 0.0;
}

void onTick(CSprite@ this)
{
    log("onTick(CSprite", "Hook called");
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

void onTick(CBlob@ this)
{
    if (!getNet().isServer()) return;

    if (isNight() && (XORRandom(spawn_zombie_chance) == 0))
    {
        SpawnZombie(this);
    }
}

void SpawnZombie(CBlob@ this)
{
    log("SpawnZombie", "Function called");
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

bool doesCollidWithBlob(CBlob@ this, CBlob@ other)
{
    return false;
}
