#include "Logging.as"
#include "StormCommon.as"
#include "Modname.as"

const int raindrop_horizontal_speed = 12.0;
const int spawn_raindrop_chance = 8;
const Vec2f particle_ar = Vec2f(255,0);
const Vec2f particle_gb = Vec2f(0,255);

void onInit(CBlob@ this)
{
    log("onInit", "Hook called");
    s8 direction = XORRandom(3) - 1;

    this.set_s8("direction", direction);
    this.set_string("storm_music", "../Mods/" + getModname() + "/Entities/Meta/Storms/heavy_rain.ogg");
    this.set_Vec2f("particle_ar", particle_ar);
    this.set_Vec2f("particle_gb", particle_gb);
}

void onTick(CBlob@ this)
{
    if (!getNet().isServer() || !this.get_bool("started"))
        return;

    if (XORRandom(spawn_raindrop_chance) == 0)
    {
        //log("onTick", "Spawning hailstone!");
        SpawnRaindrop(this);
    }
}

void SpawnRaindrop(CBlob@ this)
{
    Vec2f pos = getRandomHailstonePos();
    CBlob@ raindrop = server_CreateBlob("raindrop", -1, pos);
    raindrop.setVelocity(Vec2f(this.get_s8("direction") * raindrop_horizontal_speed, 0));
}
