// Brutality Isle temporarily modded to add shader

#include "Default/DefaultGUI.as"
#include "Default/DefaultLoaders.as"
#include "EmotesCommon.as"
#include "Modname.as"
#include "Logging.as"

const string shader = "../../Mods/" + getModname() + "/Shaders/brutality";

void onInit(CRules@ this)
{
	LoadDefaultMapLoaders();
	LoadDefaultGUI();

	sv_gravity = 9.81f;
	particles_gravity.y = 0.25f;
	sv_visiblity_scale = 1.25f;
	cc_halign = 2;
	cc_valign = 2;

	s_effects = false;

	sv_max_localplayers = 1;

	//don't override this any more, some people like to change it
	//and it's exposed in options for KAG.
	//v_camera_ints = true;

	//smooth shader
    Driver@ driver = getDriver();

    driver.AddShader(shader, 1.0f);
    driver.SetShader(shader, true);
}

//chat stuff!

void onEnterChat(CRules @this)
{
	if(getChatChannel() != 0) return; //no dots for team chat

	CBlob@ localblob = getLocalPlayerBlob();
	if(localblob !is null)
		set_emote(localblob, Emotes::dots, 100000);
}

void onExitChat(CRules @this)
{
	CBlob@ localblob = getLocalPlayerBlob();
	if(localblob !is null)
		set_emote(localblob, Emotes::off);
}
