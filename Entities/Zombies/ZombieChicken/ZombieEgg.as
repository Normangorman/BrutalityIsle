#include "HealAmountsCommon.as";

const int grow_time = 80 * getTicksASecond();
const int max_chickens = 8;

void onInit(CBlob@ this)
{
    this.set_u8("heal_amount", heal_amount_zombie_egg);
	this.getCurrentScript().tickFrequency = grow_time + 1;
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
        this.SendCommand(this.getCommandID("hatch"));
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("hatch") && getNumChickensOnMap() <= max_chickens)
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
			server_CreateBlob("zombie_chicken", -1, this.getPosition() + Vec2f(0, -5.0f));
		}
	}
}

int getNumChickensOnMap()
{
    CBlob@[] chickens;
    getBlobsByName("zombie_chicken", @chickens);
    return chickens.length;
}
