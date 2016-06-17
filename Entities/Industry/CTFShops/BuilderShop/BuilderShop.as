// BuilderShop.as
// Brutality Isle modded to:
// add waterproof lantern
// add sparkwood arrows
// increase shop interface size

#include "Requirements.as"
#include "ShopCommon.as";
#include "Descriptions.as";
#include "WARCosts.as";
#include "CheckSpam.as";

void onInit(CBlob@ this)
{
	this.set_TileType("background tile", CMap::tile_wood_back);

	this.getSprite().SetZ(-50); //background
	this.getShape().getConsts().mapCollisions = false;

	// SHOP
	this.set_Vec2f("shop offset", Vec2f_zero);
	this.set_Vec2f("shop menu size", Vec2f(4, 4));
	this.set_string("shop description", "Buy");
	this.set_u8("shop icon", 25);

	// CLASS
	this.set_Vec2f("class offset", Vec2f(-6, 0));
	this.set_string("required class", "builder");

	{
		ShopItem@ s = addShopItem(this, "Lantern", "$lantern$", "lantern", descriptions[9], false);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", COST_WOOD_LANTERN);
	}
	{
		ShopItem@ s = addShopItem(this, "Bucket", "$bucket$", "bucket", descriptions[36], false);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", COST_WOOD_BUCKET);
	}
	{
		ShopItem@ s = addShopItem(this, "Sponge", "$sponge$", "sponge", descriptions[53], false);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", COST_WOOD_SPONGE);
	}
	{
		ShopItem@ s = addShopItem(this, "Boulder", "$boulder$", "boulder", descriptions[17], false);
		AddRequirement(s.requirements, "blob", "mat_stone", "Stone", 35);
	}
	{
		ShopItem@ s = addShopItem(this, "Trampoline", "$trampoline$", "trampoline", descriptions[30], false);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", COST_WOOD_TRAMPOLINE);
	}
	{
		ShopItem@ s = addShopItem(this, "Saw", "$saw$", "saw", descriptions[12], false);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", COST_WOOD_SAW);
		AddRequirement(s.requirements, "blob", "mat_stone", "Stone", 100);
	}
	{
		ShopItem@ s = addShopItem(this, "Drill", "$drill$", "drill", descriptions[43], false);
		AddRequirement(s.requirements, "blob", "mat_stone", "Stone", COST_STONE_DRILL);
		AddRequirement(s.requirements, "coin", "", "Coins", 25);
	}
	{
		ShopItem@ s = addShopItem(this, "Waterproof Lantern", "$waterproof_lantern$", "waterproof_lantern", descriptions[61], false);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", COST_WOOD_WATERPROOF_LANTERN);
		AddRequirement(s.requirements, "blob", "mat_purple_gold", "Purple Gold", COST_PURPLE_GOLD_WATERPROOF_LANTERN);
	}
    {
		ShopItem@ s = addShopItem(this, "Sparkwood Arrows", "$mat_firearrows$", "mat_firearrows", descriptions[32], true);
		AddRequirement(s.requirements, "coin", "", "Coins", COST_SPARKWOOD_ARROWS);
		AddRequirement(s.requirements, "blob", "mat_sparkwood", "Sparkwood", COST_SPARKWOOD_SPARKWOOD_ARROWS);
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if(caller.getConfig() == this.get_string("required class"))
	{
		this.set_Vec2f("shop offset", Vec2f_zero);
	}
	else
	{
		this.set_Vec2f("shop offset", Vec2f(6, 0));
	}
	this.set_bool("shop available", this.isOverlapping(caller));
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("shop made item"))
	{
		this.getSprite().PlaySound("/ChaChing.ogg");
	}
}
