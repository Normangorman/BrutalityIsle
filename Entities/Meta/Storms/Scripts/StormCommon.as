const int warning_delay_time_secs = 30;
const int min_duration_secs = 20;
const int max_duration_secs = 30;

Vec2f getRandomHailstonePos()
{
    for (u8 attempts = 0; attempts < 5; attempts++)
    {
        // Choose a random location
        CMap@ map = getMap();
        int x = XORRandom(map.tilemapwidth) * map.tilesize;
        int y = 8;

        Vec2f pos = Vec2f(x,y);
        Tile tileAtPos = map.getTile(pos);
        bool isBackground = map.isTileBackground(tileAtPos);
        bool isSolid = map.isTileSolid(tileAtPos);
        /*
        log("getRandomHailstonePos",
                "x: " + x 
                + ", y: " + y
                + ", tiletype: " + tileAtPos.type
                + ", isBackground: " + isBackground
                + ", isSolid: " + isSolid
        );
        */

        if (!isSolid)
        {
            return pos;
        }
    }

    return Vec2f(0,0);
}
