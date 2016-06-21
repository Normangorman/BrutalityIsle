// Knight Workshop

#include "Requirements.as"
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
	this.set_string("required class", "knight");

	{
		ShopItem@ s = addShopItem(this, "Bomb", "$bomb$", "mat_bombs", descriptions[1], true);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", COST_WOOD_BOMB);
		AddRequirement(s.requirements, "blob", "mat_stone", "Stone", COST_STONE_BOMB);
	}
	{
		ShopItem@ s = addShopItem(this, "Water Bomb", "$waterbomb$", "mat_waterbombs", descriptions[52], true);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", COST_WOOD_WATER_BOMB);
		AddRequirement(s.requirements, "blob", "mat_stone", "Stone", COST_STONE_WATER_BOMB);
		AddRequirement(s.requirements, "blob", "mat_sparkwood", "Sparkwood", COST_SPARKWOOD_WATER_BOMB);
	}
	{
		ShopItem@ s = addShopItem(this, "Mine", "$mine$", "mine", descriptions[20], false);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", COST_WOOD_MINE);
		AddRequirement(s.requirements, "blob", "mat_stone", "Stone", COST_STONE_MINE);
		AddRequirement(s.requirements, "blob", "mat_sparkwood", "Sparkwood", COST_SPARKWOOD_MINE);
	}
	{
		ShopItem@ s = addShopItem(this, "Keg", "$keg$", "keg", descriptions[4], false);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", COST_WOOD_KEG);
		AddRequirement(s.requirements, "blob", "mat_stone", "Stone", COST_STONE_KEG);
		AddRequirement(s.requirements, "blob", "mat_sparkwood", "Sparkwood", COST_SPARKWOOD_KEG);
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
