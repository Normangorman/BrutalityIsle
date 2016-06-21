// Mushroom logic
// Brutality Isle modded to make growth chance slower
// Brutality Isle modded to prevent mushroom dropping if burned or exploded
#include "Hitters.as";
#include "Logging.as";
#include "PlantGrowthCommon.as";
#include "brutality_Time.as";

const u8 MUSHROOM_GROWTH_TIME = 20; // tick frequency for growth script
const u8 MUSHROOM_GROWTH_DAYS = 2; // on average fully grown after 2 days

void onInit(CBlob@ this)
{
    //blah
	this.SetFacingLeft(XORRandom(2) == 0);

	this.getCurrentScript().tickFrequency = 45;
	this.getSprite().SetZ(10.0f);

    this.set_u8(growth_time, MUSHROOM_GROWTH_TIME);
    this.set_u8(growth_chance, getDayDurationTicks() * MUSHROOM_GROWTH_DAYS * MUSHROOM_GROWTH_TIME); 

	// this script gets removed so onTick won't be run on client on server join, just onInit
	if (this.hasTag("instant_grow"))
	{
		GrowMushroom(this);
	}
}


void onTick(CBlob@ this)
{
    //log("onTick", "Hook called");
	if (this.hasTag(grown_tag))
	{
		GrowMushroom(this);
	}
}

void GrowMushroom(CBlob @this)
{
    //log("GrowMushroom", "Function called");
	for (int i = 0; i < 3; i++)
	{
		Vec2f offset;
		int v = this.isFacingLeft() ? 0 : 1;
		switch (i)
		{
			case 0: offset = Vec2f(-1 + v, -16); break;
			case 1: offset = Vec2f(2 + v, -10); break;
			case 2: offset = Vec2f(-4 + v, -5); break;
		}

        /*
		CSpriteLayer@ mushroom = this.getSprite().addSpriteLayer("mushroom", "Entities/Natural/Farming/Mushroom/Mushroom.png" , 8, 8);

		if (mushroom !is null)
		{
			Animation@ anim = mushroom.addAnimation("default", 0, false);
			anim.AddFrame(0);
			mushroom.SetAnimation("default");
			mushroom.SetOffset(offset);
			mushroom.SetRelativeZ(0.01f * (XORRandom(3) == 0 ? -1 : 1));
		}
        */
	}

	this.Tag("has mushroom");
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return false;
}

void onDie(CBlob@ this)
{
    //log("onDie", "Hook called");
	if (getNet().isServer())
	{
		if (this.hasTag("has mushroom"))
		{
			for (int i = 1; i <= 1; i++)
			{
				CBlob@ mushroom = server_CreateBlob("mushroom", this.getTeamNum(), this.getPosition() + Vec2f(0, -12));
				if (mushroom !is null)
				{
					mushroom.setVelocity(Vec2f(XORRandom(5) - 2.5f, XORRandom(5) - 2.5f));
				}
			}
		}

        // Make a new mushroom plant in the same position
        // like a phoenix
        // a tasty, hallucinogenic phoenix
        server_CreateBlob("mushroom_plant", -1, this.getPosition());
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
        log("onHit", "The hit was from fire or an explosion so untagging 'has mushroom'");
            this.Untag("has mushroom");
        }
        this.Tag("dead");
    }

    return damage;
}
