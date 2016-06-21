#include "Logging.as"
#include "StormCommon.as"
#include "Modname.as"

const float hailstone_horizontal_speed = 12.0;
const int spawn_hailstone_chance = 10;
const Vec2f particle_ar = Vec2f(255,255);
const Vec2f particle_gb = Vec2f(255,255);

void onInit(CBlob@ this)
{
    log("onInit", "Hook called");
    s8 direction = XORRandom(3) - 1;

    this.set_s8("direction", direction);
    this.set_string("storm_music", "../Mods/" + getModname() + "/Entities/Meta/Storms/Hailstorm.ogg");
    this.set_Vec2f("particle_ar", particle_ar); // set_SColor doesn't exist so this is a workaround
    this.set_Vec2f("particle_gb", particle_gb); // blah

    this.set_u8("duration secs", 60);
}

void onTick(CBlob@ this)
{
    //log("onTick", "Hook called");
    if (!this.get_bool("started"))
        return;

    if (getNet().isServer() && XORRandom(spawn_hailstone_chance) == 0)
    {
        log("onTick", "Spawning hailstone!");
        SpawnHailstone(this);
    }
}

void SpawnHailstone(CBlob@ this)
{
    Vec2f pos = getRandomHailstonePos();
    //Vec2f pos = spawn_positions[XORRandom(spawn_positions.length())];
    CBlob@ hailstone = server_CreateBlob("hailstone", -1, pos);
    hailstone.setVelocity(Vec2f(this.get_s8("direction") * hailstone_horizontal_speed, 0));
}
