// Brutality Isle modded to increase number of potential fish and prevent them clumping together
#define SERVER_ONLY

#include "Logging.as"

const int max_fish = 30;
const int max_local_fish = 5;
const float fish_local_radius = 256.0;
const string fish_name = "fishy";

void onTick(CRules@ this)
{
	if (getGameTime() % 29 != 0) return;
	if (XORRandom(512) < 256) return; //50% chance of actually doing anything

	CMap@ map = getMap();
	if (map is null || map.tilemapwidth < 2) return; //failed to load map?

	CBlob@[] fish;
	getBlobsByName(fish_name, @fish);

    //log("onTick", "Total fish: " + fish.length);

	if (fish.length < max_fish)
	{
		if (fish.length > 2 && XORRandom(128) > 32) //breed fish
		{
            //log("onTick", "Trying to breed fish");
			uint first = XORRandom(fish.length);
			uint second = XORRandom(fish.length);

			CBlob@ first_fish = fish[first];
			CBlob@ second_fish = fish[second];

            int num_local_fish = 2;
            for (int i=0; i < fish.length; i++)
            {
                CBlob@ f = fish[i];
                if (i != first && i != second && f.getDistanceTo(first_fish) < fish_local_radius)
                    num_local_fish++;
            }

            //log("onTick", "local fish: " + num_local_fish);

			if (first != second && //not the same fish
			        first_fish.getDistanceTo(second_fish) < 32 && //close
			        !first_fish.hasTag("dead") && //both parents alive
			        !second_fish.hasTag("dead") &&
                    num_local_fish < max_local_fish)
			{
				CBlob@ babby_fish = server_CreateBlobNoInit(fish_name);
				if (babby_fish !is null)
				{
					babby_fish.server_setTeamNum(-1);
					babby_fish.setPosition((first_fish.getPosition() + second_fish.getPosition()) * 0.5f);

					u8 col1 = first_fish.get_u8("colour");
					u8 col2 = second_fish.get_u8("colour");

					if (XORRandom(16) > 0) //inherit a colour
						babby_fish.set_u8("colour", XORRandom(1024) > 512 ? col1 : col2);

					//otherwise mutated, will be set in init

					babby_fish.Init();
				}
			}
		}
		else //spawn from nowhere
		{
            //log("onTick", "Trying to spawning fish from nowhere");
			f32 x = (f32((getGameTime() * 997) % map.tilemapwidth) + 0.5f) * map.tilesize;

			Vec2f top = Vec2f(x, map.tilesize);
			Vec2f bottom = Vec2f(x, map.tilemapheight * map.tilesize);
			Vec2f end;

			if (map.rayCastSolid(top, bottom, end))
			{
				f32 y = end.y;
				int i = 0;
				while (i ++ < 3)
				{
					Vec2f pos = Vec2f(x, y - i * map.tilesize);
					if (map.isInWater(pos))
					{
                        //log("onTick", "Found a suitable position");
						server_CreateBlob(fish_name, -1, pos);
						break;
					}
				}
			}
		}
	}
}
