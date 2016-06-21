#include "TreeCommon.as"
#include "Logging.as"

void onInit(CBlob@ this)
{
    TreeVars@ vars;
    this.get("TreeVars", @vars);

    if (vars is null)
    {
        log("onInit", "WARNING: TreeVars is null");
    }
    else
    {
        vars.growth_time *= 2;
    }
}
