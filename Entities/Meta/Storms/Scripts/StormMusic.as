#include "Logging.as"
#include "StormCommon.as"
#include "Modname.as"

const float fade_in_time = 4.0;
const float fade_out_time = 4.0;
const int background_mixer_id = 100;
const int storm_mixer_id = 101;
const string background_storm_music = "../Mods/" + getModname() + "/Entities/Meta/Storms/thunder_and_lightning2.ogg";

void onInit(CBlob@ this)
{
	CMixer@ mixer = getMixer();
	if (mixer is null)
    {
        log("onInit", "Mixer not found so not starting music.");
		return;
    }

    log("onInit", "Starting background music: " + background_storm_music);
    mixer.AddTrack(background_storm_music, background_mixer_id);
    mixer.StopAll();
    mixer.FadeInRandom(background_mixer_id, fade_in_time);

    if (this.exists("storm_music"))
    {
        string music_path = this.get_string("storm_music");
        mixer.AddTrack(music_path, storm_mixer_id);
    }
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
    CMixer@ mixer = getMixer();
    if (cmd == this.getCommandID("start_storm") && this.exists("storm_music") && mixer !is null)
    {
        log("onCommand", "Got start_storm cmd");
        mixer.FadeInRandom(storm_mixer_id, fade_in_time);
    }
    else if (cmd == this.getCommandID("stop_storm") && mixer !is null)
    {
        log("onCommand", "Got stop_storm cmd");

        if (mixer.isPlaying(background_mixer_id))
        {
            log("onCommand", "Stopping background music");
            mixer.FadeOut(background_mixer_id, fade_out_time);
        }

        if (mixer.isPlaying(storm_mixer_id))
        {
            log("onCommand", "Stopping storm music");
            mixer.FadeOut(storm_mixer_id, fade_out_time);
        }
    }
}
