// Grain logic
// Brutality Isle modded to make growth chance slower

#include "PlantGrowthCommon.as";
#include "brutality_Time.as";

const u8 GRAIN_GROWTH_TIME = 20; // tick frequency for growth script
const u8 GRAIN_GROWTH_DAYS = 1; // on average fully grown after 2 days

void onInit(CBlob@ this)
{
	this.SetFacingLeft(XORRandom(2) == 0);

	this.getCurrentScript().tickFrequency = 45;
	this.getSprite().SetZ(10.0f);

    this.set_u8(growth_time, GRAIN_GROWTH_TIME);
    this.set_u8(growth_chance, getDayDurationTicks() * GRAIN_GROWTH_DAYS * GRAIN_GROWTH_TIME); 

	// this script gets removed so onTick won't be run on client on server join, just onInit
	if (this.hasTag("instant_grow"))
	{
		GrowGrain(this);
	}
}


void onTick(CBlob@ this)
{
	if (this.hasTag(grown_tag))
	{
		GrowGrain(this);
	}
}

void GrowGrain(CBlob @this)
{
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

		CSpriteLayer@ grain = this.getSprite().addSpriteLayer("grain", "Entities/Natural/Farming/Grain/Grain.png" , 8, 8);

		if (grain !is null)
		{
			Animation@ anim = grain.addAnimation("default", 0, false);
			anim.AddFrame(0);
			grain.SetAnimation("default");
			grain.SetOffset(offset);
			grain.SetRelativeZ(0.01f * (XORRandom(3) == 0 ? -1 : 1));
		}
	}

	this.Tag("has grain");
	this.getCurrentScript().runFlags |= Script::remove_after_this;
}
