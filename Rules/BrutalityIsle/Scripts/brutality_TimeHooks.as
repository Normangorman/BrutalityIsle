#include "Logging.as"
#include "brutality_Time.as"

void onInit(CRules@ this)
{
    log("onInit", "Hook called");
    this.set_u32("game start time", getGameTime());
    this.set_u32("game added time", 0);
    this.set_u16("start day number", 1); // useful to change for testing
    this.set_bool("is night", false);
}

void onTick(CRules@ this)
{
    if (!getNet().isServer())
        return;

    if (getGameTime() % starvation_frequency_ticks == 0)
    {
        doStarvationDamage(this);
    }

    displayDateAndTime(this);

    bool is_night = this.get_bool("is night");
    float t = getMap().getDayTime();
    if ((!is_night) && t >= night_begin)
    {
        this.set_bool("is night", true);
        sendAlert(this, "nighttime_hook");
    }
    else if (is_night && t >= day_begin && t < night_begin)
    {
        this.set_bool("is night", false);
        sendAlert(this, "daytime_hook");
    }
}

void sendAlert(CRules@ this, string alert)
{
    CBlob@[] blobs;
    getBlobsByTag(alert, @blobs);

    log("onTick", "Sending " + alert + " alert to " + blobs.length() + " blobs");
    for (int i=0; i < blobs.length(); i++)
    {
        CBlob@ blob = blobs[i];

        if (blob.hasCommandID(alert))
        {
            blob.SendCommand(blob.getCommandID(alert));
        }
        else
        {
            log("onTick", "WARNING: Blob " + blob.getName() + " has alert tag but no alert command.");
        }
    }
}

void doStarvationDamage(CRules@ this)
{
    log("doStarvationDamage", "Causing damage to all players");
    CBlob@[] players;
    getBlobsByTag("player", @players);

    for(int i=0; i < players.length(); i++)
    {
        CBlob@ b = players[i];
        b.server_Hit(b, b.getPosition(), Vec2f(0,0), starvation_damage, 0, true);
    }
}

void displayDateAndTime(CRules@ this)
{
    int day = getDayNumber();
    Vec2f time = get24hTime();

    int hour = time.x;
    int min  = time.y;

    string hour_padded = (""+hour).length == 2 ? (""+hour) : ("0"+hour);
    string min_padded  = (""+min).length  == 2 ? (""+min)  : ("0"+min);
    string timestring  = hour_padded + ":" + min_padded;


    if (this.getCurrentState() != GAME_OVER)
        this.SetGlobalMessage("Day " + day + " | Survivors remaining: " + getNumRemainingSurvivors() + " | Time: " + timestring);
}
