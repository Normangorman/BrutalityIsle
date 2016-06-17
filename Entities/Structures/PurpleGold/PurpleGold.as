#include "Hitters.as"
#include "MakeMat.as"
#include "Logging.as"

void onInit(CBlob@ this)
{
    this.getSprite().getConsts().accurateLighting = true;
	this.getShape().getConsts().waterPasses = false;
    //this.set_TileType("background tile", CMap::tile_castle_back);
    this.server_setTeamNum(-1); //allow anyone to break them
	this.Tag("place norotate");
	this.Tag("stone"); // Brutality Isle might not want this?
	this.Tag("large");
}

bool canBePickedUp( CBlob@ this, CBlob@ byBlob )
{
	return false;
}

f32 onHit( CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData )
{
    log("onHit", "Hook called");
	this.getSprite().PlaySound("/destroy_gold");

	switch(customData)
	{
        case Hitters::builder:
            log("onHit", "Hit was from builder");
            damage *= 4.0f;
            if (getNet().isServer()) MakeMat(hitterBlob, hitterBlob.getPosition(), "mat_purple_gold", 4 * damage );
            break;
        case Hitters::saw:
            damage *= 0.25;
            break;		
        case Hitters::bomb:
        case Hitters::keg:
        case Hitters::arrow:
        case Hitters::cata_stones:
        default:
            damage=0;
            break;
	}		

	return damage;
}

bool doesCollideWithBlob( CBlob@ this, CBlob@ blob )
{
	return true;
}
