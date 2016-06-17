#define SERVER_ONLY

#include "EmotesCommon.as"

const u8 LAY_EGG_CHANCE = 600;
const u8 MAX_EGGS_ON_MAP = 10;

void onInit(CBlob@ this)
{
    this.getCurrentScript().tickFrequency = 30;
}

void onTick(CBlob@ this)
{
    if (XORRandom(LAY_EGG_CHANCE) == 0
        && getNumEggsOnMap() < MAX_EGGS_ON_MAP
        && !this.hasTag("dead"))
    {
        CBlob@ egg = server_CreateBlob("egg");
        egg.setPosition(this.getPosition());

        u8 emote = XORRandom(2) == 0 ? Emotes::smile : Emotes::troll;
        set_emote(this, emote);
    }
}

int getNumEggsOnMap()
{
    CBlob@[] eggs;
    getBlobsByName("egg", @eggs);
    return eggs.length();
}
