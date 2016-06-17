#include "Logging.as"

void onInit(CBlob@ this)
{
    this.Tag("nighttime_hook");
    this.addCommandID("nighttime_hook");
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
    if (this.hasTag("dead") && cmd == this.getCommandID("nighttime_hook"))
    {
        log("onCommand", "nighttime_hook command received");

        string entity_to_reanimate_as;
        if (this.get_string("reanimate_entity") != "")
        {
            log("onCommand", "I have a custom reanimate_entity");

            entity_to_reanimate_as = this.get_string("reanimate_entity");
        }
        else
        {
            entity_to_reanimate_as = this.getName();
        }
        log("onCommand", "Reanimating as: " + entity_to_reanimate_as);

        CBlob@ reanimated = server_CreateBlob(entity_to_reanimate_as, -1, this.getPosition());
        this.server_Die();
    }
}
