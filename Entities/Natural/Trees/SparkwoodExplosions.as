#include "Logging.as"

const float explosion_vel = 7.3f;

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (!solid || this.isAttached())
	{
		return;
	}

	f32 vellen = this.getOldVelocity().Length();

	if (vellen > 1.7f)
	{
        // The sound is played by Wooden.as so we don't need to
		//Sound::Play("/WoodLightBump", this.getPosition(), Maths::Min(vellen / 8.0f, 1.1f));

		log("onCollision", "vellen " + vellen);
		if (vellen > explosion_vel)
		{
            this.Tag("exploding"); // for ExplodeOnDie
			Boom(this);
		}
	}
}

void Boom(CBlob@ this)
{
	this.server_SetHealth(-1.0f);
	this.server_Die();
}
