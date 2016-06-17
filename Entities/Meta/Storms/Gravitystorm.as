#include "Logging.as"
#include "StormCommon.as"
#include "Modname.as"

const float gravity_vary_factor = 0.8;
const float gravity_vary_speed = 40.0; // higher = slower
const float original_sv_gravity = sv_gravity;

void onInit(CBlob@ this)
{
    log("onInit", "Hook called");
    this.set_string("storm_music", "../Mods/" + getModname() + "/Entities/Meta/Storms/gravity.ogg");
}

void onTick(CBlob@ this)
{
    //log("onTick", "Hook called");
    if (!getNet().isServer() || !this.get_bool("started"))
        return;

    float m = gravity_vary_factor * (Maths::Sin(getGameTime() / gravity_vary_speed));
    float mod = 1.0 + m;
    sv_gravity = original_sv_gravity * mod;

    /*
    log("onTick",
            "original_sv_gravity: " + original_sv_gravity
            + ", getGameTime: " + getGameTime()
            + ", t/s: " + getGameTime()/gravity_vary_speed
            + ", sin(t/s): " + Maths::Sin(getGameTime()/gravity_vary_speed)
            + ", m: " + m
            + ", mod: " + mod
            + ", sv_gravity: " + sv_gravity
            );
            */

}

void onDie(CBlob@ this)
{
    sv_gravity = original_sv_gravity;
}
