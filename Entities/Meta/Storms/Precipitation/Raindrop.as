#include "Hitters.as";
#include "Logging.as";

void onInit(CBlob@ this)
{
	this.set_f32("explosive_radius", 24.0f);
	this.set_f32("explosive_damage", 1.5f);
	this.set_u8("custom_hitter", Hitters::water);
	this.set_string("custom_explosion_sound", "Entities/Common/Sounds/WaterBubble" + (XORRandom(2) + 1) + ".ogg");
	this.set_f32("map_damage_radius", 24.0f);
	this.set_f32("map_damage_ratio", 1.6f);
	this.set_bool("map_damage_raycast", true);
	this.Tag("medium weight");
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
    //log("onHit", "Hook called");
    Vec2f dir = velocity;
	dir.Normalize();
	this.AddForce(dir * 30);
	return damage;
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
    //log("onCollision", "Hook called. solid: " + solid);
	if (!solid)
	{
		return;
	}

	//f32 vellen = this.getOldVelocity().Length();

    Sound::Play("Bomb.ogg", this.getPosition(), 1.1f);
    Boom(this);
}

void Boom(CBlob@ this)
{
    this.Tag("exploding");
    this.server_SetHealth(-1.0);
    this.server_Die();
}
