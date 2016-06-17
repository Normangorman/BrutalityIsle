// Brutality Isle modded to prevent grain dropping if burned or exploded
#include "Hitters.as";
#include "Logging.as";

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return false;
}

void onDie(CBlob@ this)
{
	if (getNet().isServer())
	{
		if (this.hasTag("has grain"))
		{
			for (int i = 1; i <= 1; i++)
			{
				CBlob@ grain = server_CreateBlob("grain", this.getTeamNum(), this.getPosition() + Vec2f(0, -12));
				if (grain !is null)
				{
					grain.setVelocity(Vec2f(XORRandom(5) - 2.5f, XORRandom(5) - 2.5f));
				}
			}
		}
	}
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
    log("onHit", "Hook called. health: " + this.getHealth() + ", damage: " + damage);
    log("onHit", "Hitters::fire = " + Hitters::fire + ", Hitters::explosion = " + Hitters::explosion + ", hitter = " + customData);
    if (damage >= this.getHealth() && !this.hasTag("dead"))
    {
        log("onHit", "The hit was deadly");
        if (customData == Hitters::fire || customData == Hitters::burn || isExplosionHitter(customData))
        {
        log("onHit", "The hit was from fire or an explosion so untagging 'has grain'");
            this.Untag("has grain");
        }
        this.Tag("dead");
    }

    return damage;
}
