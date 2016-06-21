#include "Logging.as"
#include "brutality_Time.as"
#include "StormCommon.as"

int spawn_storm_chance = 140;
int last_storm_start_time;

void onInit(CBlob@ this)
{
    log("onInit", "Hook called");
    this.getCurrentScript().tickFrequency = 500;
    last_storm_start_time = getGameTime();
}

void onTick(CBlob@ this)
{
    if ((!getNet().isServer()) || isNight()) // don't spawn storms at night
        return;

    int time_since_last_storm_secs = (getGameTime() - last_storm_start_time)/getTicksASecond();
    if (time_since_last_storm_secs > warning_delay_time_secs + max_duration_secs)
    {
        //log("onTick", "Randomly deciding whether to spawn a storm");

        if (XORRandom(spawn_storm_chance) == 0)
        {
            switch(XORRandom(3)) 
            {
                case 0: SpawnHailstorm(); break;
                case 1: SpawnRainstorm(); break;
                case 2: SpawnGravitystorm(); break;
            }

            last_storm_start_time = getGameTime();
            log("onTick", "Spawned a storm!");
        }
    }
    else 
    {
        //log("onTick", "Storm might be happening so not making another");
    }
}

void SpawnHailstorm()
{
    log("SpawnHailstorm", "Hailstorm spawned.");
    server_CreateBlob("hailstorm");
}

void SpawnRainstorm()
{
    log("SpawnRainstorm", "Rainstorm spawned.");
    server_CreateBlob("rainstorm");
}

void SpawnGravitystorm()
{
    log("SpawnGravitystorm", "Gravitystorm spawned.");
    server_CreateBlob("gravitystorm");
}
