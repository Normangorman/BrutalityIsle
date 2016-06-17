#include "Logging.as"

const string heal_id = "heal command";

void onInit(CBlob@ this)
{
	if (!this.exists("eat sound"))
	{
		this.set_string("eat sound", "/Eat.ogg");
	}

	this.addCommandID(heal_id);
}

/*
void Heal(CBlob@ this, CBlob@ blob)
{
	bool exists = getBlobByNetworkID(this.getNetworkID()) !is null;
	if (getNet().isServer() && blob.hasTag("player") && blob.getHealth() < blob.getInitialHealth() && !this.hasTag("healed") && exists)
	{
		CBitStream params;
		params.write_u16(blob.getNetworkID());

		this.SendCommand(this.getCommandID(heal_id), params);

		this.Tag("healed");
	}
}
*/

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID(heal_id))
	{
		this.getSprite().PlaySound(this.get_string("eat sound"));

		if (getNet().isServer())
		{
			u16 blob_id;
			if (!params.saferead_u16(blob_id)) return;

			CBlob@ theBlob = getBlobByNetworkID(blob_id);
			if (theBlob !is null)
			{
				u8 heal_amount = 255;
                if (this.exists("heal_amount"))
                {
                    heal_amount = this.get_u8("heal_amount");
                    log("onCommand", "Using item's heal_amount property for heal_amount.");
                }
                else
                {
                    log("onCommand", "Item has no heal_amount property so using default of 255.");
                }
                log("onCommand", "heal_amount="+heal_amount);


				if (heal_amount == 255)
				{
					theBlob.server_SetHealth(theBlob.getInitialHealth());
				}
				else
				{
					theBlob.server_Heal(f32(heal_amount) * 0.25f);
				}

			}

			this.server_Die();
		}
	}
}

/*
void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (blob is null)
	{
		return;
	}

	if (getNet().isServer() && !blob.hasTag("dead"))
	{
		Heal(this, blob);
	}
}

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint @attachedPoint)
{
	if (getNet().isServer())
	{
		Heal(this, attached);
	}
}

void onDetach(CBlob@ this, CBlob@ detached, AttachmentPoint @attachedPoint)
{
	if (getNet().isServer())
	{
		Heal(this, detached);
	}
}
*/
