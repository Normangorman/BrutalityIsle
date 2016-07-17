#include "Logging.as"

const float night_begin = 0.875;
const float day_begin = 0.25;
const f32 starvation_damage = 0.5;
const int starvation_frequency_ticks = 1200; // about once every 2 mins 

/*
void addVirtualHoursToGameTime(int num_hours)
{
    log("addToGameTime", "Function called with num_hours="+num_hours);
    int ticks_to_add = getVirtualHourDurationTicks() * num_hours;

    game_added_time += ticks_to_add;
    
    // Advance daycycle_start so it appears that time has shifted
    float daycycle_shift = num_hours / 24.0;
    getRules().daycycle_start += daycycle_shift;
    while (getRules().daycycle_start > 1.0) { getRules().daycycle_start -= 1.0; }
}
*/

int getNumRemainingSurvivors()
{
    CBlob@[] players;
    getBlobsByTag("player", @players);

    int survivors = 0;
    for (int i=0; i < players.length(); i++)
    {
        CBlob@ b = players[i];
        if (b.hasTag("player") && !b.hasTag("dead"))
            survivors++;
    }

    return survivors;
}

f32 getTimeElapsedSecs()
{
    CRules@ rules = getRules();
    u32 start = rules.get_u32("game start time");
    u32 added = rules.get_u32("game added time");

    return (getGameTime() - start + added)/getTicksASecond();
}

Vec2f get24hTime()
{
    float dayTime = getMap().getDayTime();

    int hour = dayTime * 24.0;
    int min  = (dayTime - (hour / 24.0)) * 24 * 60.0;

    return Vec2f(hour, min);
}

int getDayDurationSecs()
{
    return getRules().daycycle_speed * 60;
}

int getDayDurationTicks()
{
    return getDayDurationSecs() * getTicksASecond();
}

int getVirtualHourDurationTicks()
{
    return getDayDurationTicks() / 24;
}

int getDayNumber()
{
    return getRules().get_u16("start day number") + getTimeElapsedSecs() / (getRules().daycycle_speed * 60) ;
}

bool isNight()
{
    return getRules().get_bool("is night");
}
