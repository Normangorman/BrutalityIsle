#include "Modname.as"
#include "Logging.as"
#include "brutality_Time.as"

const string shader = "../../Mods/" + getModname() + "/Shaders/brutality";
const float PI = 3.141592653;
const float night_duration = (1.0 + day_begin) - night_begin;

void onInit(CBlob@ this)
{
    log("onInit", "Hook called");
    Driver@ driver = getDriver();
    if (driver !is null)
    {
        driver.SetShaderFloat(shader, "player_x", 0.0);
        driver.SetShaderFloat(shader, "player_y", 0.0);
        driver.SetShaderInt(shader, "enable_darkness", 0);
        driver.SetShaderFloat(shader, "darkness_factor", 1.0);
    }

    this.Tag("nighttime_hook");
    this.addCommandID("nighttime_hook");

    this.Tag("daytime_hook");
    this.addCommandID("daytime_hook");
}

void onTick(CBlob@ this)
{
    if (getNet().isServer())
        return;

    //log("onTick", "Hook called");
    Driver@ driver = getDriver();
    if ((getGameTime() % 5 == 0) && (driver !is null))
    {
        // set player_x and player_y
        CPlayer@ local_player = getLocalPlayer();
        if (local_player is null)
        {
            log("onTick", "Local player is null");
            return;
        }

        CBlob@ b = local_player.getBlob();
        if (b is null)
        {
            log("onTick", "Local player blob is null");
            return;
        }

        Vec2f pos = driver.getScreenPosFromWorldPos(b.getPosition());
        driver.SetShaderFloat(shader, "player_x", pos.x);
        driver.SetShaderFloat(shader, "player_y", pos.y);

        // set darkness factor
        float t = getMap().getDayTime();
        if (t < day_begin) { t += 1.0; } 
        t -= night_begin;

        float progression = t/night_duration;
        float darkness_factor = 0.0;
        if (progression > 0 && progression < 1.0)
        {
            // failsafe for during daytime
            darkness_factor = Maths::FastSin(progression * PI);
            //log("onTick", "darkness factor: " + darkness_factor);
        }

        driver.SetShaderFloat(shader, "darkness_factor", darkness_factor);
    }
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
    if (getNet().isServer())
        return;

    log("onCommand", "Hook called");

    Driver@ driver = getDriver();
    if (driver is null)
    {
        log("onCommand", "Driver is null so returning!");
        return;
    }

    if (cmd == this.getCommandID("nighttime_hook"))
    {
        log("onCommand", "Nighttime hook received. Setting enable_darkness to 1.");
        driver.SetShaderInt(shader, "enable_darkness", 1);
    }
    else if (cmd == this.getCommandID("daytime_hook"))
    {
        log("onCommand", "Daytime hook received. Setting enable_darkness to 0.");
        driver.SetShaderInt(shader, "enable_darkness", 0);
    }
}
