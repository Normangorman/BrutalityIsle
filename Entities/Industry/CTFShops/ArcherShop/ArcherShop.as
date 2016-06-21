// ArcherShop.as

#include "Requirements.as";
#include "ShopCommon.as";
#include "Descriptions.as";
#include "CheckSpam.as";
#include "WARCosts.as";

void onInit(CBlob@ this)
{
	this.set_TileType("background tile", CMap::tile_wood_back);

	this.getSprite().SetZ(-50); //background
	this.getShape().getConsts().mapCollisions = false;

	// SHOP
	this.set_Vec2f("shop offset", Vec2f_zero);
	this.set_Vec2f("shop menu size", Vec2f(4, 1));
	this.set_string("shop description", "Buy");
	this.set_u8("shop icon", 25);

	// CLASS
	this.set_Vec2f("class offset", Vec2f(-6, 0));
	this.set_string("required class", "archer");

	{
		ShopItem@ s = addShopItem(this, "Arrows", "$mat_arrows$", "mat_arrows", descriptions[2], true);
		AddRequirement(s.requirements, "blob", "mat_stone", "Stone", COST_STONE_ARROWS);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", COST_WOOD_ARROWS);
	}
	{
		ShopItem@ s = addShopItem(this, "Water Arrows", "$mat_waterarrows$", "mat_waterarrows", descriptions[50], true);
		AddRequirement(s.requirements, "blob", "mat_stone", "Stone", COST_STONE_WATER_ARROWS);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", COST_WOOD_WATER_ARROWS);
	}
	{
		ShopItem@ s = addShopItem(this, "Fire Arrows", "$mat_firearrows$", "mat_firearrows", descriptions[32], true);
		AddRequirement(s.requirements, "blob", "mat_stone", "Stone", COST_STONE_FIRE_ARROWS);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", COST_WOOD_FIRE_ARROWS);
		AddRequirement(s.requirements, "blob", "mat_sparkwood", "Sparkwood", COST_SPARKWOOD_FIRE_ARROWS);
	}
	{
		ShopItem@ s = addShopItem(this, "Bomb Arrows", "$mat_bombarrows$", "mat_bombarrows", descriptions[51], true);
		AddRequirement(s.requirements, "blob", "mat_stone", "Stone", COST_STONE_BOMB_ARROWS);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", COST_WOOD_BOMB_ARROWS);
		AddRequirement(s.requirements, "blob", "mat_sparkwood", "Sparkwood", COST_SPARKWOOD_BOMB_ARROWS);
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
	if(cmd == this.getCommandID("shop made item"))
	{
		this.getSprite().PlaySound("/ChaChing.ogg");
	}
}
