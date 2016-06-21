#include "EmotesCommon.as"
#include "Logging.as"
#include "Hitters.as"

const u8 STATE_SOARING          = 0;
const u8 STATE_TRYING_TO_PERCH  = 1;
const u8 STATE_PERCHING         = 2;
const u8 STATE_ATTACKING        = 3;

const u8 FLY_STATE_FLAPPING     = 0;
const u8 FLY_STATE_GLIDING      = 1;

const float horizontal_vel = 10.0;
const float max_horizontal_vel = 20.0;
const float flap_vel = 360.0;
const float aggro_radius = 80.0;
//const u32 delay_between_flaps = 15;
const u32 wing_flap_sound_time = 120;
const float target_reached_radius = 25.0;
const float target_reached_y_band = 0.0; // in this band we don't flap
const int min_target_pos_offset_from_sky = 32; // in tiles
const int max_target_pos_offset_from_sky = 42;
const int flap_wings_down_frame = 2;
const int flap_talons_wings_down_frame = 8;
const int territory_width = 80;
const int drop_held_target_p = 100; 
//const int max_drop_height = 40; // in tiles 

const int min_state_time = 100; // remain in any state for at least this many ticks
const int state_transition_p = 260;

Random eagleRand(Time());

void onInit(CBlob@ this)
{
    log("onInit(Blob)", "Hook called");
    Sound::Play("GregCry.ogg", this.getPosition());

    this.set_u8("number of steaks", 5);
    this.set_u8("state", STATE_SOARING);
    this.set_u8("fly state", FLY_STATE_GLIDING);
    this.set_u32("last wing sound time", 0);
    this.set_u32("state transition time", 0);
    this.set_Vec2f("target pos", Vec2f(0,0));
    //this.set("perching spots", nil); // an array of 3 Vec2f positions which are the highest in the eagle's territory
    this.set_u16("target blob netid", 0);
    this.set_bool("holding target", false); // the time at which the target was picked up

    f32 territory_left = Maths::Max(0, this.getPosition().x - territory_width * 8);
    f32 territory_right = Maths::Min(this.getPosition().x + territory_width * 8, getMap().tilemapwidth*8);
    this.set_f32("territory left boundary", territory_left);
    this.set_f32("territory right boundary", territory_right);
    log("onInit(Blob)",
            "Territory left: " + territory_left
            + ", Right: " + territory_right
       );

    this.addCommandID("flap wings");

    this.set_bool("has calculated territory", false);
    pickRandTargetPos(this);

    this.getShape().SetGravityScale(0.5);
}

void onInit(CSprite@ this)
{
    log("onInit(Sprite)", "Hook called");
    this.SetAnimation("glide");
    this.SetRelativeZ(2.0f);
}

void onTick(CBlob@ this)
{
    // Doesn't work in onInit if eagle is created at map creation time, since map is incomplete
    if (this.get_bool("has calculated territory") == false && getGameTime() > 10)
    {
        if (getNet().isServer())
            calcPerchingSpots(this);
        this.set_bool("has calculated territory", true);
    }

    Vec2f eagleVel = this.getVelocity();
    bool faceLeft = (eagleVel.x > 0);
    this.SetFacingLeft(faceLeft);

    u8 state = this.get_u8("state");
    u8 fly_state = this.get_u8("fly state");

    Vec2f eaglePos = this.getPosition();
    Vec2f targetPos = this.get_Vec2f("target pos");
    Vec2f delta = targetPos - eaglePos;

    /*
    log("onTick",
            "targetPos: " + targetPos.x + ":" + targetPos.y
            + "\neaglePos: " + eaglePos.x + ":" + eaglePos.y
            + "\neagleVel: " + eagleVel.x + ":" + eagleVel.y
            + "\ndelta = " + delta.x + ":" + delta.y
            + "\nfly state = " + getFlyStateName(this.get_u8("fly state"))
            );
            */
    
    // Handle state first
    if (getNet().isServer())
    {
        if (state == STATE_SOARING)
        { // If target has been pursued for too long then stop
            if (delta.Length() < target_reached_radius) // If close to target then stop
            {
                log("onTick", "Target reached");
                pickRandTargetPos(this);
            }
        }
        else if (state == STATE_PERCHING)
        {
        }
        else if (state == STATE_TRYING_TO_PERCH)
        {
            if (delta.Length() < target_reached_radius) // If close to target then stop
            {
                this.setPosition(targetPos);
                this.setVelocity(Vec2f(0,0));
                changeState(this, STATE_PERCHING);
            }
        }
        else if (state == STATE_ATTACKING)
        {
            if (this.get_bool("holding target"))
            {
                //if ((eagleRand.NextRanged(drop_held_target_p) == 0) && (getHeightAboveLand(this) < max_drop_height))
                if (eagleRand.NextRanged(drop_held_target_p) == 0)
                {
                    log("onTick", "Dropping player from a height of " + getHeightAboveLand(this));
                    this.server_DetachAll();
                    this.set_bool("holding target", false);
                    changeState(this, STATE_SOARING);
                }
                else if (delta.Length() < target_reached_radius)
                {
                    log("onTick", "Target reached");
                    pickRandTargetPos(this);
                }
            }
            else
            {
                u16 target_netid = this.get_u16("target blob netid");

                bool should_abandon_target = false;
                if (target_netid > 0)
                {
                    CBlob@ target = getBlobByNetworkID(target_netid);

                    if (target is null || target.hasTag("dead"))
                    {
                        log("onTick", "Target blob cannot be found!");
                        should_abandon_target = true;
                    }
                    else
                    {
                        this.set_Vec2f("target pos", target.getPosition());
                        this.Sync("target pos", true);
                    }
                }

                s16 burn_time = this.get_s16("burn timer");
                if(this.isInFlames() || burn_time > 0 || should_abandon_target)
                {
                    log("onTick", "Abandoning target");
                    changeState(this, STATE_SOARING);
                }
            }
        }

        doRandomStateTransitions(this);
    }

    // Vars may have changed so recalc
    state       = this.get_u8("state");
    fly_state   = this.get_u8("fly state");

    eagleVel    = this.getVelocity();
    eaglePos    = this.getPosition();
    targetPos   = this.get_Vec2f("target pos");
    delta       = targetPos - eaglePos;

    // Now handle fly state (also done clientside)
    if (state == STATE_SOARING || state == STATE_TRYING_TO_PERCH || state == STATE_ATTACKING)
    {
        if (fly_state == FLY_STATE_GLIDING)
        {
            // Apply a gravity counteracting force
            this.AddForce(Vec2f(0, -1.0 * 9.81));
        }

        if (delta.y < 0)
        {
            // CSprite onTick checks for this and send the flap wings command when the wings are down in the animation
            if (fly_state != FLY_STATE_FLAPPING)
            {
                //log("onTick", "Trying to move upwards. fly state=FLY_STATE_FLAPPING");
                this.set_u8("fly state", FLY_STATE_FLAPPING);
                this.Sync("fly state", true);
            }
        }
        else
        {
            if (fly_state != FLY_STATE_GLIDING)
            {
                //log("onTick", "Gliding. fly state=FLY_STATE_GLIDING");
                this.set_u8("fly state", FLY_STATE_GLIDING);
                this.Sync("fly state", true);
            }
        }

        // Move horizontally
        // Move 3x faster horizontally when gliding
        float gliding_multiplier = fly_state == FLY_STATE_GLIDING ? 3.0 : 1.0;
        float desired_dir = delta.x > 0 ? 1.0 : -1.0;

        this.AddForce(Vec2f(desired_dir * horizontal_vel * gliding_multiplier, 0));
        
        // Slow down horizontally if directly above target
        if (Maths::Abs(delta.x) < target_reached_radius)
        {
            int delta_x_sign = delta.x < 0 ? -1 : 1;
            this.AddForce(Vec2f(0.5 * delta_x_sign * horizontal_vel, 0));
        }

        // Don't allow velocity to go above max
        Vec2f vel = this.getVelocity();
        if (Maths::Abs(vel.x) > max_horizontal_vel)
        {
            int sign = vel.x > 0 ? 1 : -1;
            this.setVelocity(Vec2f(max_horizontal_vel * sign, vel.y));
        }
    }
}

void onTick(CSprite@ this)
{
    CBlob@ blob = this.getBlob();
    u8 state = blob.get_u8("state");
    u8 fly_state = blob.get_u8("fly state");

    if (state == STATE_PERCHING)
    {
        if (this.animation.name == "peck")
        {
            if (this.animation.ended())
            {
                //log("onTick", "Peck animation ended");
                this.SetAnimation("perch");
            }
        }
        else if (this.animation.name == "perch")
        {
            if (eagleRand.NextRanged(state_transition_p) == 0)
            {
                //log("onTick", "Changing animation to peck");
                this.SetAnimation("peck");
            }
        }
        else
        {
            this.SetAnimation("perch");
        }
    }
    else if (fly_state == FLY_STATE_FLAPPING)
    {
        if (state == STATE_ATTACKING)
        {
            if (this.animation.name != "flap_talons")
            {
                this.SetAnimation("flap_talons");
            }
        }
        else
        {
            if (this.animation.name != "flap")
            {
                this.SetAnimation("flap");
            }
        }
    }
    else if (fly_state == FLY_STATE_GLIDING)
    {
        if (state == STATE_ATTACKING)
        {
            if (this.animation.name != "glide_talons")
            {
                this.SetAnimation("glide_talons");
            }
        }
        else
        {
            if (this.animation.name != "glide")
            {
                this.SetAnimation("glide");
            }
        }
    }

    // Ensure that the flap happens as the eagle's wings go down
    //log("onTick(CSprite)", "fly_state: " + getFlyStateName(fly_state) + ", this.getFrame(): " + this.getFrame());
    if ((this.isAnimation("flap") && this.getFrame() == flap_wings_down_frame)
         || (this.isAnimation("flap_talons") && this.getFrame() == flap_talons_wings_down_frame))
    {
        //log("onTick(CSprite)", "Sending flap wings command");
        blob.SendCommand(blob.getCommandID("flap wings"));
    }
}

void doRandomStateTransitions(CBlob@ this)
{
    u32 time_since_last_transition = getGameTime() - this.get_u32("state transition time");
    if (time_since_last_transition < min_state_time)
    {
        //log("doRandomStateTransitions", "Not enough time has passed since the last transition.");
        return;
    }

    u32 rand = eagleRand.NextRanged(state_transition_p);
    if (rand != 0)
        return;
    else
    {
       //log("doRandomStateTransitions", "Random state transition is happening!");
    }

    u8 state = this.get_u8("state");

    if (state == STATE_SOARING)
    {
        rand = eagleRand.NextRanged(state_transition_p);

        if (rand < state_transition_p * 0.33)
        {
            changeState(this, STATE_TRYING_TO_PERCH);
        }
        else if (rand < state_transition_p * 0.66)
        {
            changeState(this, STATE_SOARING);
        }
        else
        {
            if (isAnyoneWithinAggroRadius(this))
                changeState(this, STATE_ATTACKING);
        }
    }
    else if (state == STATE_TRYING_TO_PERCH)
    {
        changeState(this, STATE_SOARING);
    }
    else if (state == STATE_ATTACKING && !this.get_bool("holding target"))
    {
        changeState(this, STATE_SOARING);
    }
    else if (state == STATE_PERCHING)
    {
        changeState(this, STATE_SOARING);
    }
}

string getStateName(u8 state)
{
    switch(state)
    {
        case STATE_SOARING:
            return "STATE_SOARING";

        case STATE_PERCHING:
            return "STATE_PERCHING";

        case STATE_TRYING_TO_PERCH:
            return "STATE_TRYING_TO_PERCH";

        case STATE_ATTACKING:
            return "STATE_ATTACKING";
    }

    return "NO_STATE";
}

string getFlyStateName(u8 state)
{
    switch(state)
    {
        case FLY_STATE_FLAPPING:
            return "FLY_STATE_FLAPPING";

        case FLY_STATE_GLIDING:
            return "FLY_STATE_GLIDING";
    }

    return "NO_FLY_STATE";
}

void changeState(CBlob@ this, u8 new_state)
{
    u8 current_state = this.get_u8("state");

    //log("changeState", "Changing state from: " + getStateName(current_state) + ", to: " + getStateName(new_state));
    if (new_state == STATE_TRYING_TO_PERCH)
    {
        pickRandPerchingSpot(this);
    }
    else if (new_state == STATE_SOARING)
    {
        pickRandTargetPos(this);

        if (current_state != STATE_SOARING)
        {
            // Flap wings straight away to get some height
            this.SendCommand(this.getCommandID("flap wings"));
        }
    }
    else if (new_state == STATE_PERCHING)
    {
        // Randomize facing direction
        this.SetFacingLeft(eagleRand.NextRanged(2) == 0 ? true : false);
    }
    else if (new_state == STATE_ATTACKING)
    {
        pickClosestPlayer(this);
        set_emote(this, Emotes::skull);
    }

    this.set_u8("state", new_state);
    this.Sync("state", true);

    this.set_u32("state transition time", getGameTime());
}

void calcPerchingSpots(CBlob@ this)
{
    log("calcPerchingSpots", "Function called");
    f32 left = this.get_f32("territory left boundary");
    f32 right = this.get_f32("territory right boundary");

    CMap@ map = getMap();
    if (map is null)
    {
        log("calcPerchingSpots", "Map is null!");
        return;
    }

    float map_height = map.tilemapheight * map.tilesize;
    Vec2f[] points;
    for (int x = left; x <= right; x += map.tilesize)
    {
        Vec2f top    = Vec2f(x, 0);
        Vec2f bottom = Vec2f(x, map_height);
        Vec2f highest_point; 
        map.rayCastSolidNoBlobs(top, bottom, highest_point);

        // Raise each point up a bit so it isn't considered solid later
        highest_point.y -= map.tilesize*2;

        //log("calcPerchingSpots", "" + x + ": (" + highest_point.x + ", " + highest_point.y +")");
        points.push_back(highest_point);
    }

    // Now take the top 3 highest points
    Vec2f[] perching_spots;
    for (int i=0; i < points.length(); i++)
    {
        //printf("i=" + i);
        Vec2f p = points[i];
        //printf("p.y=" + p.y);

        if (perching_spots.length() < 3 || p.y < perching_spots[0].y)
        {
            int j;
            for (j=0; j < perching_spots.length() && p.y < perching_spots[j].y; j++) {}

            //printf("j=" + j);

            perching_spots.insert(j, p);
            if (perching_spots.length() > 3)
                perching_spots.removeAt(0);
        }
    }

    for (int i=0; i < 3; i++)
    {
        log("calcPerchingSpots", "Spot " + i + " = " + perching_spots[i].x + ":" + perching_spots[i].y);
    }

    this.set("perching spots", perching_spots);
}

void pickRandPerchingSpot(CBlob@ this)
{
    Vec2f[] perching_spots;
    this.get("perching spots", perching_spots);
 
    Vec2f spot;
    if (perching_spots is null)
    {
        log("pickRandPerchingSpot", "ERROR: Perching spots is null!");
    }

    int attempts = 0;
    while(true)
    {
        spot = perching_spots[eagleRand.NextRanged(3)];
        log("pickRandPerchingSpot", "Considering spot: " + spot.x + ":" + spot.y);

        if (getMap().isTileSolid(spot))
        {
            log("pickRandPerchingSpot", "Spot is solid! Recalculating spots.");
            calcPerchingSpots(this);
            attempts++;

            if (attempts == 3)
            {
                log("pickRandPerchingSpot", "ERROR: Tried 3 times to find a perching spot and failed. Returning.");
                return;
            }
        }
        else
        {
            //log("pickRandPerchingSpot", "It's not solid so using it.");
            this.set_Vec2f("target pos", spot);
            this.Sync("target pos", true);
            //log("pickRandPerchingSpot", "Target pos is: "+spot.x+":"+spot.y);
            return;
        }
    }
}

void pickRandTargetPos(CBlob@ this)
{
    if (this.get_bool("has calculated territory") == false)
    {
        log("pickRandTargetPos", "Haven't calculated territory yet!");
        this.set_Vec2f("target pos", this.getPosition());
        this.Sync("target pos", true);
    }

    float left  = this.get_f32("territory left boundary");
    float right = this.get_f32("territory right boundary");

    int width = right - left;
    float x = eagleRand.NextRanged(width) + left;
    float y = eagleRand.NextRanged(max_target_pos_offset_from_sky*8) + min_target_pos_offset_from_sky*8;

    Vec2f pos = Vec2f(x,y);
    this.set_Vec2f("target pos", pos);
    this.Sync("target pos", true);

    //log("pickRandTargetPos", "Chose position: " + pos.x + ", " + pos.y);

    // Return the farthest of the two testing target points
    /*
    Vec2f tpos1 = Vec2f(32.0, 64.0);
    Vec2f tpos2 = Vec2f((getMap().tilemapwidth - 4)*8, 64.0);

    float d1 = (tpos1 - this.getPosition()).Length();
    float d2 = (tpos2 - this.getPosition()).Length();
    if (d1 > d2)
    {
        log("pickRandTargetPos", "Chose position tpos1 ");
        this.set_Vec2f("target pos", tpos1);
    }
    else
    {
        log("pickRandTargetPos", "Chose position tpos2 ");
        this.set_Vec2f("target pos", tpos2);
    }

    this.set_u32("state transition time", getGameTime());
    return;
    */
}

bool isAnyoneWithinAggroRadius(CBlob@ this)
{
    CBlob@[] blobs;
    getMap().getBlobsInRadius(this.getPosition(), aggro_radius, blobs);
    for (u8 i = 0; i < blobs.length; i++)
    {
        if (isValidTarget(this, blobs[i]))
            return true;
    }

    return false;
}

void pickClosestPlayer(CBlob@ this)
{
    CBlob@[] players;
    getBlobsByTag("player", players);

    u16 closest_player_pid = 0;
    float closest_distance = 1000.0;
    for (u8 i = 0; i < players.length; i++)
    {
        CBlob@ player = players[i];
        if (!isValidTarget(this, player))
            continue;
        else
        {
            if (this.getDistanceTo(player) < closest_distance)
            {
                closest_distance = this.getDistanceTo(player);
                closest_player_pid = player.getNetworkID();
            }
        }
    }

    if(closest_player_pid == 0)
    {
        log("pickClosestPlayer", "WARNING: Closest player is null. Maybe no players are within territory bounds?");
    }
    else
    {
        log("pickClosestPlayer", "Chose player with netID: " + closest_player_pid);
    }

    this.set_u16("target blob netid", closest_player_pid);
}

void onCollision( CBlob@ this, CBlob@ blob, bool solid )
{
    if(blob !is null
        && blob.hasTag("flesh")
        && !this.isOnGround()
        && getNet().isServer())
    {
        u8 state = this.get_u8("state");

        // Pick up the target if it's the target player
        if (state == STATE_ATTACKING && blob.getNetworkID() == this.get_u16("target blob netid"))
        {
            log("onCollision", "Picking up target!");
            this.server_Pickup(blob);
            this.set_bool("holding target", true);
            pickRandTargetPos(this);
        }
        else
        {
            log("onCollision", "Damaging the blob that was hit");
            this.server_Hit(blob, blob.getPosition(), Vec2f(1, 1), 2.0f, 0);
        }

        set_emote(this, Emotes::troll);
    }
}

void onCommand( CBlob@ this, u8 cmd, CBitStream @params )
{
    //log("onCommand", "Hook called");
    //blah
    if(cmd == this.getCommandID("flap wings"))
    {
        //log("onCommand", "flap wings command received");

        if (getGameTime() - this.get_u32("last wing sound time") > wing_flap_sound_time)
        {
            //Sound::Play("Wings.ogg", this.getPosition(), 0.5);
            this.set_u32("last wing sound time", getGameTime());
        }

        if (getNet().isServer())
        {
            float force = -flap_vel;

            if (this.isOnGround()) // take off faster from the ground
            {
                log("onCommand", "Taking off from ground");
                force *= 2.0;
            }

            if (this.get_bool("holding target"))
            {
                force *= 1.1;
            }

            this.AddForce(Vec2f(0, force));
        }
    }
}

f32 onHit( CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData )
{
    log("onHit", "Hook called");
    if (getNet().isServer()
            && this.get_u8("state") != STATE_ATTACKING
            && (customData == Hitters::crush
                || customData == Hitters::water_stun
                || customData == Hitters::stomp
                || customData == Hitters::builder
                || customData == Hitters::sword
                || customData == Hitters::shield
                || customData == Hitters::bomb
                || customData == Hitters::arrow
                || customData == Hitters::explosion
                || customData == Hitters::spikes
                ))
    {
        changeState(this, STATE_ATTACKING);
    }
    return damage;
}

bool doesCollideWithBlob( CBlob@ this, CBlob@ blob )
{
    return blob.getName() != "eagle";
}

int getHeightAboveLand(CBlob@ this)
{
    float x = this.getPosition().x / getMap().tilesize;
    float height = getMap().getLandYAtX(x) - this.getPosition().y/getMap().tilesize;
    //log("getHeightAboveLand", "Returning " + height);
    return height;
}

bool isValidTarget(CBlob@ this, CBlob@ blob)
{
    Vec2f pos = blob.getPosition();
    if (pos.x < this.get_f32("territory left boundary")
            || pos.x > this.get_f32("territory right boundary")
            || blob.isInWater()
            || blob.isAttached()
            || (!blob.hasTag("player")))
        return false;
    else
        return true;
}
