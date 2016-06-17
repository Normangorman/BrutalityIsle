#include "HealAmountsCommon.as"

void onInit(CBlob@ this)
{
    this.set_u8("heal_amount", heal_amount_heart);
	this.set_string("eat sound", "/Heart.ogg");
	this.getCurrentScript().runFlags |= Script::remove_after_this;
	this.server_SetTimeToDie(40);
}
