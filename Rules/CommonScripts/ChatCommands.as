// Simple chat processing example.
// If the player sends a command, the server does what the command says.
// You can also modify the chat message before it is sent to clients by modifying text_out
#include "MakeSeed.as";
#include "MakeCrate.as";
#include "MakeScroll.as";

bool onServerProcessChat(CRules@ this, const string& in text_in, string& out text_out, CPlayer@ player)
{
	if (player is null)
		return true;


	CBlob@ blob = player.getBlob();

	if (blob is null)
	{
		return true;
	}

	//commands that don't rely on sv_test

	if (text_in == "!killme")
	{
		blob.server_Hit(blob, blob.getPosition(), Vec2f(0, 0), blob.getInitialHealth(), 0);
	}
    else if (text_in == "!hurtme")
	{
		blob.server_Hit(blob, blob.getPosition(), Vec2f(0, 0), 1.0f, 0);
	}
    else if (text_in == "!killall" && player.isMod())
    {
        CBlob@[] blobs;
        getMap().getBlobs(blobs);

        for (int i=0; i < blobs.length; i++)
        {
            CBlob@ b = blobs[i];

            if (b.hasTag("flesh") && b.getNetworkID() != player.getNetworkID())
            {
                printf("Killing: " + b.getName());
                b.server_Die();
            }
        }
    }
	else if (text_in == "!invincible" && player.isMod())
	{
        if (blob.hasTag("invincible"))
            blob.Untag("invincible");
        else
            blob.Tag("invincible");
	}
	else if (text_in == "!deadly" && player.isMod())
	{
        if (blob.hasTag("deadly"))
            blob.Untag("deadly");
        else
            blob.Tag("deadly");
	}
	else if (text_in == "!healme" && player.isMod())
    {
        blob.server_SetHealth(blob.getInitialHealth());
    }
	else if (text_in == "!bot" && player.isMod())
	{
		CPlayer@ bot = AddBot("Henry");
		return true;
	}
	else if (text_in == "!classarcher" && player.isMod())
	{
        CBlob@ new_blob = server_CreateBlob("archer", blob.getTeamNum(), blob.getPosition());
        blob.server_SetPlayer(null);
        blob.server_Die();
        new_blob.server_SetPlayer(player);
		return true;
	}
	else if (text_in == "!classbuilder" && player.isMod())
	{
        CBlob@ new_blob = server_CreateBlob("builder", blob.getTeamNum(), blob.getPosition());
        blob.server_SetPlayer(null);
        blob.server_Die();
        new_blob.server_SetPlayer(player);
		return true;
	}
	else if (text_in == "!classknight" && player.isMod())
	{
        CBlob@ new_blob = server_CreateBlob("knight", blob.getTeamNum(), blob.getPosition());
        blob.server_SetPlayer(null);
        blob.server_Die();
        new_blob.server_SetPlayer(player);
		return true;
	}
	else if (text_in == "!debug" && player.isMod())
	{
		// print all blobs
		CBlob@[] all;
		getBlobs(@all);

		for (u32 i = 0; i < all.length; i++)
		{
			CBlob@ blob = all[i];
			print("[" + blob.getName() + " " + blob.getNetworkID() + "] ");
		}
	}

	//spawning things

	//these all require sv_test - no spawning without it
	//some also require the player to have mod status
	if (sv_test)
	{
		Vec2f pos = blob.getPosition();
		int team = blob.getTeamNum();

        if (text_in == "!chicken")
        {
            CBlob@ chicken = server_CreateBlob("chicken");
            chicken.setPosition(pos);
        }
        else if (text_in == "!zombie")
        {
            CBlob@ zombie = server_CreateBlob("zombie", -1, pos);
        }
        else if (text_in == "!tree")
		{
			//server_MakeSeed(pos, "tree_pine", 600, 1, 16);
			server_MakeSeed(pos, "tree_pine"); 
		}
		else if (text_in == "!btree")
		{
			server_MakeSeed(pos, "tree_bushy", 400, 2, 16);
		}
		else if (text_in == "!stones")
		{
			CBlob@ b = server_CreateBlob("Entities/Materials/MaterialStone.cfg", team, pos);

			if (b !is null)
			{
				b.server_SetQuantity(320);
			}
		}
		else if (text_in == "!wood")
		{
			CBlob@ b = server_CreateBlob("Entities/Materials/MaterialWood.cfg", team, pos);

			if (b !is null)
			{
				b.server_SetQuantity(320);
			}
		}
		else if (text_in == "!arrows")
		{
			for (int i = 0; i < 3; i++)
			{
				CBlob@ b = server_CreateBlob("Entities/Materials/MaterialArrows.cfg", team, pos);

				if (b !is null)
				{
					b.server_SetQuantity(30);
				}
			}
		}
		else if (text_in == "!bombs")
		{
			//  for (int i = 0; i < 3; i++)
			CBlob@ b = server_CreateBlob("Entities/Materials/MaterialBombs.cfg", team, pos);

			if (b !is null)
			{
				b.server_SetQuantity(30);
			}
		}
		else if (text_in == "!spawnwater" && player.isMod())
		{
			getMap().server_setFloodWaterWorldspace(pos, true);
		}
		else if (text_in == "!seed")
		{
			// crash prevention?
		}
		else if (text_in == "!crate")
		{
			client_AddToChat("usage: !crate BLOBNAME [DESCRIPTION]", SColor(255, 255, 0, 0));
			server_MakeCrate("", "", 0, team, Vec2f(pos.x, pos.y - 30.0f));
		}
		else if (text_in == "!coins")
		{
			player.server_setCoins(player.getCoins() + 100);
		}
		else if (text_in.substr(0, 1) == "!")
		{
			// check if we have tokens
			string[]@ tokens = text_in.split(" ");

			if (tokens.length > 1)
			{
				if (tokens[0] == "!crate")
				{
					int frame = tokens[1] == "catapult" ? 1 : 0;
					string description = tokens.length > 2 ? tokens[2] : tokens[1];
					server_MakeCrate(tokens[1], description, frame, -1, Vec2f(pos.x, pos.y));
				}
				else if (tokens[0] == "!team")
				{
					int team = parseInt(tokens[1]);
					blob.server_setTeamNum(team);
				}
				else if (tokens[0] == "!scroll")
				{
					string s = tokens[1];
					for (uint i = 2; i < tokens.length; i++)
						s += " " + tokens[i];
					server_MakePredefinedScroll(pos, s);
				}

				return true;
			}

			// try to spawn an actor with this name !actor
			string name = text_in.substr(1, text_in.size());

			if (server_CreateBlob(name, team, pos) is null)
			{
				client_AddToChat("blob " + text_in + " not found", SColor(255, 255, 0, 0));
			}
		}
	}

	return true;
}

bool onClientProcessChat(CRules@ this, const string& in text_in, string& out text_out, CPlayer@ player)
{
	if (text_in == "!debug" && !getNet().isServer())
	{
		// print all blobs
		CBlob@[] all;
		getBlobs(@all);

		for (u32 i = 0; i < all.length; i++)
		{
			CBlob@ blob = all[i];
			print("[" + blob.getName() + " " + blob.getNetworkID() + "] ");

			if (blob.getShape() !is null)
			{
				CBlob@[] overlapping;
				if (blob.getOverlapping(@overlapping))
				{
					for (uint i = 0; i < overlapping.length; i++)
					{
						CBlob@ overlap = overlapping[i];
						print("       " + overlap.getName() + " " + overlap.isLadder());
					}
				}
			}
		}
	}

	return true;
}
