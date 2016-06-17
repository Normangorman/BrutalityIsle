#define SERVER_ONLY

#include "EmotesCommon.as"

const u8 LAY_EGG_CHANCE = 300;

void onInit(CBlob@ this)
{
    this.getCurrentScript().tickFrequency = 30;
}

void onTick(CBlob@ this)
{
    if (XORRandom(LAY_EGG_CHANCE) == 0
        && !this.hasTag("dead"))
    {
        CBlob@ egg = server_CreateBlob("zombie_egg");
        egg.setPosition(this.getPosition());

        u8 emote = Emotes::skull;
        set_emote(this, emote);
    }
}
