//script for a chicken
// Brutality Isle modded to add "gib health" setting

#include "AnimalConsts.as"
#include "Logging.as"

const u8 DEFAULT_PERSONALITY = AGGRO_BIT;

int g_lastSoundPlayedTime = 0;
int g_layEggInterval = 0;

//sprite
void onInit(CSprite@ this)
{
	this.ReloadSprites(0, 0); //always blue
}

void onTick(CSprite@ this)
{
	CBlob@ blob = this.getBlob();

	if (!blob.hasTag("dead"))
	{
		f32 x = Maths::Abs(blob.getVelocity().x);
		if (blob.isAttached())
		{
			AttachmentPoint@ ap = blob.getAttachmentPoint(0);
			if (ap !is null && ap.getOccupied() !is null)
			{
				if (Maths::Abs(ap.getOccupied().getVelocity().y) > 0.2f)
				{
					this.SetAnimation("fly");
				}
				else
					this.SetAnimation("idle");
			}
		}
        else if (blob.hasTag("biting"))
        {
            if (this.animation.name != "peck")
            {
                this.PlaySound(blob.get_string("bite sound"));
            }
            this.SetAnimation("peck");
            return;
        }
		else if (!blob.isOnGround())
		{
			this.SetAnimation("fly");
		}
		else if (x > 0.02f)
		{
			this.SetAnimation("walk");
		}
		else
		{
			if (this.isAnimationEnded())
			{
				uint r = XORRandom(20);
				if (r == 0)
					this.SetAnimation("peck_twice");
				else if (r < 5)
					this.SetAnimation("peck");
				else
					this.SetAnimation("idle");
			}
		}
	}
	else
	{
		this.SetAnimation("dead");
		this.getCurrentScript().runFlags |= Script::remove_after_this;
		this.PlaySound("/ScaredChicken");
	}
}

//blob
void onInit(CBlob@ this)
{
    string[] tags = {"player", "flesh"};
    this.set("tags to eat", tags);

    string[] names_not_to_eat = {this.getName(), "fishy", "shark"};
    this.set("names not to eat", names_not_to_eat);
    //test

	this.set_f32("bite damage", 0.5f);

	//brain
	this.set_u8(personality_property, DEFAULT_PERSONALITY);
	this.getBrain().server_SetActive(true);
	this.set_f32(target_searchrad_property, 240.0f);
	this.set_f32(terr_rad_property, 75.0f);
	this.set_u8(target_lose_random, 34);

	//for shape
	this.getShape().SetRotationsAllowed(false);

	//for flesh hit
	this.set_f32("gib health", -1.0);
	this.Tag("flesh");

	this.getShape().SetOffset(Vec2f(0, 6));

	this.getCurrentScript().runFlags |= Script::tick_blob_in_proximity;
	this.getCurrentScript().runProximityTag = "player";
	this.getCurrentScript().runProximityRadius = 320.0f;

	// attachment

	AttachmentPoint@ att = this.getAttachments().getAttachmentPointByName("PICKUP");
	att.SetKeysToTake(key_action1);

	// movement
	AnimalVars vars;
	vars.walkForce.Set(1.0f, -0.1f);
	vars.runForce.Set(2.0f, -1.0f);
	vars.slowForce.Set(1.0f, 0.0f);
	vars.jumpForce.Set(0.0f, -20.0f);
	vars.maxVelocity = 1.1f;
    this.set("vars", vars);
    log("onInit", "using custom zombie chicken vars");
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return false;
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return !blob.hasTag("flesh");
}

void onTick(CBlob@ this)
{
    if (this.hasTag("dead"))
    {
        //blah
        this.getCurrentScript().runFlags |= Script::remove_after_this;
        return;
    }

	f32 x = this.getVelocity().x;
	if (Maths::Abs(x) > 1.0f)
	{
		this.SetFacingLeft(x < 0);
	}
	else
	{
		if (this.isKeyPressed(key_left))
		{
			this.SetFacingLeft(true);
		}
		if (this.isKeyPressed(key_right))
		{
			this.SetFacingLeft(false);
		}
	}

    /*
	if (!this.isOnGround())
	{
		Vec2f vel = this.getVelocity();
		if (vel.y > 0.5f)
		{
			this.AddForce(Vec2f(0, -10));
		}
	}
    */
    if (getNet().isServer() && getGameTime() % 10 == 0)
    {
        if(this.get_u8(state_property) == MODE_TARGET)
        {
            CBlob@ b = getBlobByNetworkID(this.get_netid(target_property));
            log("onTick", "Targetting: " + b.getName());
			if (b !is null && this.getDistanceTo(b) < 56.0f)
			{
                log("onTick", "Tagging 'biting'");
				this.Tag("biting");
			}
			else
			{
                //log("onTick", "Remove tag 'biting'");
				this.Untag("biting");
			}

        }
        else
        {
            //log("onTick", "State is " + this.get_u8(state_property));
        }
    }
	else if (XORRandom(128) == 0 && g_lastSoundPlayedTime + 30 < getGameTime())
	{
		this.getSprite().PlaySound("/Pluck");
		g_lastSoundPlayedTime =  getGameTime();
	}
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid, Vec2f normal, Vec2f point1)
{
	if (blob is null || this.hasTag("dead"))
		return;

	if (blob.getRadius() > this.getRadius() && g_lastSoundPlayedTime + 25 < getGameTime() && blob.hasTag("flesh"))
	{
		this.getSprite().PlaySound("/ScaredChicken");
		g_lastSoundPlayedTime = getGameTime();
	}
}

