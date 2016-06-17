#include "Hitters.as"
#include "Logging.as"

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
    log("onHit", "Hook called. damage: "  + damage + ", customData: " + customData);
    if (customData == Hitters::arrow)
    {
        log("onHit", "Hit was from an arrow, so stopped it.");
        return 0.0;
    }
    else
    {
        log("onHit", "Hit was not from an arrow");
        return damage;
    }
}
