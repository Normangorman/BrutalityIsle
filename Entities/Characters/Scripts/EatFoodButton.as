#define SERVER_ONLY

#include "Logging.as"

const keys eat_food_key = key_use;
const string heal_id = "heal command";

void onInit(CBlob@ this)
{
    log("onInit", "Hook called");
    //this.getCurrentScript().runFlags |= Script::tick_myplayer;
	this.getCurrentScript().removeIfTag = "dead";
}

void onTick(CBlob@ this)
{
    //log("onTick", "Hook called");
    // Eat the held object if G is pressed and it can be eaten
    //CControls@ controls = getControls();
    /*
    if (this.isKeyJustPressed(key_up))
        log("onTick", "Key pressed: key_up");

    if (this.isKeyJustPressed(key_down))
        log("onTick", "Key pressed: key_down");

    if (this.isKeyJustPressed(key_left))
        log("onTick", "Key pressed: key_left");

    if (this.isKeyJustPressed(key_right))
        log("onTick", "Key pressed: key_right");

    if (this.isKeyJustPressed(key_action1))
        log("onTick", "Key pressed: key_action1");

    if (this.isKeyJustPressed(key_action2))
        log("onTick", "Key pressed: key_action2");

    if (this.isKeyJustPressed(key_action3))
        log("onTick", "Key pressed: key_action3");

    if (this.isKeyJustPressed(key_use))
        log("onTick", "Key pressed: key_use");

    if (this.isKeyJustPressed(key_inventory))
        log("onTick", "Key pressed: key_inventory");

    if (this.isKeyJustPressed(key_pickup))
        log("onTick", "Key pressed: key_pickup");

    if (this.isKeyJustPressed(key_jump))
        log("onTick", "Key pressed: key_jump");

    if (this.isKeyJustPressed(key_taunts))
        log("onTick", "Key pressed: key_taunts");

    if (this.isKeyJustPressed(key_map))
        log("onTick", "Key pressed: key_map");

    if (this.isKeyJustPressed(key_bubbles))
        log("onTick", "Key pressed: key_bubbles");

    if (this.isKeyJustPressed(key_crouch))
        log("onTick", "Key pressed: key_crouch");
        */

    if (this.isKeyJustPressed(eat_food_key))
    {
        log("onTick", "Eat key pressed");
        CBlob@ held_blob = this.getCarriedBlob();
        if (held_blob !is null
            && held_blob.exists("eat sound")
            && this.getHealth() < this.getInitialHealth()
            && !held_blob.hasTag("healed")
            && held_blob.hasCommandID(heal_id))
        {
            log("onTick", "Sending eat command");
            CBitStream params;
            params.write_u16(this.getNetworkID());

            held_blob.SendCommand(held_blob.getCommandID(heal_id), params);
            held_blob.Tag("healed");
        } 
    }
}
