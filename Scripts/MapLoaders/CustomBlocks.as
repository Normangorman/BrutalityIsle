/**
 *	Template for modders - add custom blocks by
 *		putting this file in your mod with custom
 *		logic for creating tiles in HandleCustomTile.
 *
 * 		Don't forget to check your colours don't overlap!
 *
 *		Note: don't modify this file directly, do it in a mod!
 */
#include "BasePNGLoader.as"
#include "Logging.as"

const SColor color_eagle(               0xFFF4FF23); // ARGB(255,  244, 175, 223);
const SColor color_crocodile(               0xFF2CAFDF); // ARGB(255,  44, 175, 223);
const SColor color_cactus(                  0xFF5B7E19); // ARGB(255,  91, 126,  25);
const SColor color_tile_purple_gold(         0xFF00EE00); // ARGB(255,  0, 238,  0);
const SColor color_waterproof_lantern(      0xFF00EEEE); // ARGB(255,  0, 238,  238);
const SColor color_mushroom_plant(      0xFF936E16); // ARGB(255,  147, 110, 22);
const SColor color_zombie(               0xFF4E2F00); // ARGB(255,  78, 47, 0);
const SColor color_zombie_statue(        0xFF9A37A3); // ARGB(255,  154, 55, 163);
const SColor color_sparkwood_tree(        0xFF2A0B47); // ARGB(255, 42,  11, 71);


namespace CMap
{
	enum CustomTiles
	{
		//pick tile indices from here - indices > 256 are advised.
		//tile_purple_gold = 384 // important because in world.png purple gold is the 384th tile // purple GOLD IS A BLOB NOW
	};
};

void HandleCustomTile(CMap@ map, int offset, SColor pixel)
{
    //log("HandleCustomTile", "Called RGB: " + pixel.getRed() + " " + pixel.getGreen() + " " + pixel.getBlue());
    if (pixel == color_eagle)
    {
        log("HandleCustomTile", "Called for eagle");
        spawnBlob(map, "eagle", offset, -1);
        PlaceMostLikelyTile(map, offset);
    }
    else if (pixel == color_cactus)
    {
        server_CreateBlob("cactus", -1, map.getTileWorldPosition(offset) + Vec2f(4, 4));
        PlaceMostLikelyTile(map, offset);
    }
    else if (pixel == color_mushroom_plant)
    {
        log("HandleCustomTile", "Called for mushroom plant");
        CBlob@ mushroom = server_CreateBlobNoInit("mushroom_plant");
        PlaceMostLikelyTile(map, offset);

        if(mushroom !is null)
        {
            mushroom.setPosition(map.getTileWorldPosition(offset) + Vec2f(4, 4));
            mushroom.Tag("instant_grow");
            mushroom.Init();
        }
    }
    else if (pixel == color_crocodile)
    {
        spawnBlob( map, "crocodile", offset, -1);
        PlaceMostLikelyTile(map, offset);
    }
    else if (pixel == color_tile_purple_gold)
    {
        log("HandleCustomTile", "Called for color_tile_purple_gold");
        spawnBlob( map, "purplegold", offset, -1, true); // true means it's attached to map
        PlaceMostLikelyTile(map, offset);
        //blah
        //map.SetTile(offset, CMap::CustomTiles::tile_purple_gold);
        //map.AddTileFlag(offset, Tile::SOLID | Tile::COLLISION | Tile::LIGHT_SOURCE);
    }
    else if (pixel == color_waterproof_lantern)
    {
        spawnBlob( map, "waterproof_lantern", offset, -1);
        PlaceMostLikelyTile(map, offset);
    }
    else if (pixel == color_zombie)
    {
        log("HandleCustomTile", "Called for zombie!");
        spawnBlob(map, "zombie", offset, -1);
        PlaceMostLikelyTile(map, offset);
    }
    else if (pixel == color_zombie_statue)
    {
        log("HandleCustomTile", "Called for zombie statue!");
        spawnBlob(map, "zombiestatue", offset, -1);
        PlaceMostLikelyTile(map, offset);
    }
    else if (pixel == color_sparkwood_tree)
    {
        log("HandleCustomTile", "Called for sparkwood tree!");

        // Brutality Isle: To implement this check we'd have to spawn trees after all the other blocks
        /*
        if(!map.isTileSolid(map.getTile(offset + map.tilemapwidth)))
        {
            log("HandleCustomTile", "No solid tile under the tree so returning");
            return;
        }
        */


        CBlob@ tree = server_CreateBlobNoInit("tree_sparkwood");
        if(tree !is null)
        {
            log("HandleCustomTile", "Tree is not null");

            tree.Tag("startbig");
            tree.setPosition( getSpawnPosition( map, offset ) );
            tree.Init();
            if (map.getTile(offset).type == CMap::tile_empty)
            {
                map.SetTile(offset, CMap::tile_grass + map_random.NextRanged(3) );
            }
        }
        else
        {
            log("HandleCustomTile", "Tree is null");
        }
    }
}
