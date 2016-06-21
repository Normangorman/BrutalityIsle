#include "Logging.as"
#include "StormCommon.as"

int start_time;
const int stop_chance = 200;

void onInit(CBlob@ this)
{
    start_time = getGameTime();
    this.addCommandID("start_storm");
    this.addCommandID("stop_storm");
    this.getCurrentScript().tickFrequency = 20;
    this.set_bool("started", false);
}

void onTick(CBlob@ this)
{
    if (!getNet().isServer())
        return;

    int time_elapsed_secs = (getGameTime() - start_time)/getTicksASecond();
    
    if (!this.get_bool("started") && time_elapsed_secs >= warning_delay_time_secs)
    {
        log("onTick", "Starting storm!");
        this.SendCommand(this.getCommandID("start_storm"));
        this.set_bool("started", true);
        this.Sync("started", true);
    }
    else if (this.get_bool("started"))
    {
        if(time_elapsed_secs >= warning_delay_time_secs + this.get_u8("duration secs"))
        {
            // storm exceeded max duration so stop it
            log("onTick", "Storm exceeded max duration and was stopped.");
            this.SendCommand(this.getCommandID("stop_storm"));
        }
    }
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
    if (cmd == this.getCommandID("stop_storm"))
    {
        this.server_Die();
    }
}
