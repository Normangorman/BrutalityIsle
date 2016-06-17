#define CLIENT_ONLY

#include "Logging.as"

Vec2f[] spawn_positions;
SColor color;
s8 direction;
const int spawn_particle_chance = 10;
const float particle_horizontal_speed = 8.0;

void onInit(CBlob@ this)
{
    calcSpawnPositions();
    Vec2f ar = this.get_Vec2f("particle_ar");
    Vec2f gb = this.get_Vec2f("particle_gb");
    color = SColor(ar.x, ar.y, gb.x, gb.y);
    direction = this.get_s8("direction");
}

void onTick(CBlob@ this)
{
    //log("onTick", "Spawning particles!");

    if (this.get_bool("started"))
        SpawnParticles(this);
}

void calcSpawnPositions()
{
    spawn_positions.clear();
    CMap@ map = getMap();
    for (int x=0; x < map.tilemapwidth; x++)
    {
        int y = map.tilemapheight - 1;
        Vec2f pos = Vec2f(x*map.tilesize,y);
        bool isSolid = map.isTileSolid(pos);
        if (!isSolid)
        {
            spawn_positions.push_back(pos);
        }
    }
}

void SpawnParticles(CBlob@ this)
{
    for(int i=0; i < spawn_positions.length(); i++)
    {
        if (XORRandom(spawn_particle_chance) == 0)
        {
            Vec2f pos = spawn_positions[i];
            Vec2f vel = Vec2f(direction * particle_horizontal_speed, 0.0);
            ParticlePixel(pos, vel, color, true); 
        }
    }
}
