#include "HealAmountsCommon.as";

const int grow_time = 120 * getTicksASecond();

const int MAX_CHICKENS_TO_HATCH = 5; // maximum in a small area
const int MAX_CHICKENS_ON_MAP = 10; // maximum on the entire map
const f32 CHICKEN_LIMIT_RADIUS = 120.0f;

void onInit(CBlob@ this)
{
    this.set_u8("heal_amount", heal_amount_egg);
	this.getCurrentScript().tickFrequency = 120;
	this.addCommandID("hatch");
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return true;
}

void onTick(CBlob@ this)
{
	if (getNet().isServer() && this.getTickSinceCreated() > grow_time)
	{
		int chickenCount = 0;
		CBlob@[] blobs;
		this.getMap().getBlobsInRadius(this.getPosition(), CHICKEN_LIMIT_RADIUS, @blobs);
		for (uint step = 0; step < blobs.length; ++step)
		{
			CBlob@ other = blobs[step];
			if (other.getName() == "chicken")
			{
				chickenCount++;
			}
		}

		if (chickenCount < MAX_CHICKENS_TO_HATCH
                && getNumChickensOnMap() < MAX_CHICKENS_ON_MAP)
		{
			this.SendCommand(this.getCommandID("hatch"));
		}
	}
}

int getNumChickensOnMap()
{
    CBlob@[] chickens;
    getBlobsByName("chicken", @chickens);
    return chickens.length();
}


void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("hatch"))
	{
		CSprite@ s = this.getSprite();
		if (s !is null)
		{
			s.Gib();
		}

		if (getNet().isServer())
		{
			this.server_SetHealth(-1);
			this.server_Die();
			server_CreateBlob("chicken", -1, this.getPosition() + Vec2f(0, -5.0f));
		}
	}
}
