#include "Logging.as"
#include "Hitters.as"
#include "FireCommon.as"

void onInit(CBlob@ this)
{
    this.Tag(spread_fire_tag);

    if (!this.exists("gib health"))
        this.set_f32("gib health", -1.5f);	
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
    //log("onHit", "Hook called");
    if (!this.hasTag("dead"))
    {
        //log("onHit", "Not dead so returning damage");
        return damage;
    }

    // Only allow damage from certain sources so that players have to deal with corpses specially
    u8[] allowed_hit_types = {
        Hitters::fire,
        Hitters::burn,
        Hitters::explosion,
        Hitters::saw,
        Hitters::drill
        };

    //log("onHit", "Health before: " + this.getHealth());
    if (allowed_hit_types.find(customData) != -1)
    {
        //log("onHit", "Took damage from an allowed source: " + customData);
        this.Damage(damage, hitterBlob);
    }
    else
    {
        //log("onHit", "Blocked damage from a disallowed source: " + customData);
    }

    //log("onHit", "Health after: " + this.getHealth());

    if (this.getHealth() <= this.get_f32("gib health"))
    {
        log("onHit", "Gibbing sprite");
        this.getSprite().Gib();
        this.server_Die();
    }

    return 0.0;
}
