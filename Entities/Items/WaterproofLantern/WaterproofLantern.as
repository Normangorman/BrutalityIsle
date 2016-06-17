// Lantern script
// Brutality Isle modded Lantern.as to change light colour to cyan and prevent decay in water

void onInit(CBlob@ this)
{
	this.SetLight(true);
	this.SetLightRadius(128.0f);
	this.SetLightColor(SColor(255, 0, 255, 255));
	this.addCommandID("light on");
	this.addCommandID("light off");
	AddIconToken("$lantern on$", "WaterproofLantern.png", Vec2f(8, 8), 0);
	AddIconToken("$lantern off$", "WaterproofLantern.png", Vec2f(8, 8), 3);

	this.Tag("dont deactivate");
	this.Tag("fire source");

	this.getCurrentScript().tickFrequency = 24;
}

/*
void onTick(CBlob@ this)
{
	if (this.isLight() && this.isInWater())
	{
		Light(this, false);
	}
}
*/

void Light(CBlob@ this, bool on)
{
	if (!on)
	{
		this.SetLight(false);
		this.getSprite().SetAnimation("nofire");
	}
	else
	{
		this.SetLight(true);
		this.getSprite().SetAnimation("fire");
	}
	this.getSprite().PlaySound("SparkleShort.ogg");
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("activate"))
	{
		Light(this, !this.isLight());
	}

}
