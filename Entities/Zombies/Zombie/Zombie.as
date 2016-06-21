#include "Hitters.as"
#include "Logging.as";
#include "BuilderHittable.as";

const u8 CLIMB_STATE_NOT_CLIMBING   = 0;
const u8 CLIMB_STATE_SIMPLE         = 1;
const u8 CLIMB_STATE_OVERHANG       = 2;
const u8 CLIMB_STATE_SUSPENDED      = 3;

const float runForce  = 4.0;
const f32 max_vel = 8.0;
const float jumpForce = 60.0;
const float climbForce  = 4.0;
const u32 dig_chance = 3; // likelihood to break blocks
const float dig_damage = 0.5; // same as builders
const int dig_frame = 2;
const f32 dig_distance = 16.0;
const int time_between_jumps = 30;
const int overhang_check_dist = 8; // how many blocks along to check for an overhang when climbing

class HitData
{
    u16 blobID;
    Vec2f tilepos;
}

void onInit(CBlob@ this)
{
    //log("onInit(CBlob)", "Hook called");
	//for EatOthers
	string[] tags = {"player","lantern"};
	this.set("tags to eat", tags);

    this.set_u8("climb state", CLIMB_STATE_NOT_CLIMBING);
	this.set_f32("gib health", -1.5f);	
	this.set_f32("bite damage", 1.0f);
	this.set_u16("bite freq", 30);
    this.set_bool("climb", false);
    this.set_u32("target netid", 0);
    this.set_Vec2f("target pos", Vec2f(0,0));
    this.set_u32("last jump time", 0);

	HitData hitdata;
	this.set("hitdata", hitdata);
	
	this.getShape().SetRotationsAllowed(false);
	
	this.Tag("flesh");
	this.Tag("zombie");

    Sound::Play( "ZombieSpawn.ogg" );
	this.getCurrentScript().runFlags = Script::tick_not_attached;
}

bool canBePickedUp( CBlob@ this, CBlob@ byBlob )
{
    return this.hasTag("dead");
}

void onTick(CBlob@ this)
{

    //log("onTick(CBlob)", "Hook called");
    if (this.hasTag("dead"))
        return;

    if (!hasTarget(this))
    {
        //log("onTick", "Currently no target.");

        if (getNet().isServer() && (getGameTime() % 20 == 0))
        {
            if (!getNewTarget(this))
                log("onTick", "Failed to get new target");
        }
    }
    else
    {
        CBlob@ target = getBlobByNetworkID(this.get_u32("target netid"));
        Vec2f delta = target.getPosition() - this.getPosition();
        Vec2f direction = delta;
        direction.Normalize();

        /*
        log("onTick", "My Pos: (" + this.getPosition().x + ":" + this.getPosition().y + ")"
                + ", Rounded: (" + this.getPosition().x/8.0 + ":" + this.getPosition().y/8.0 + ")");
        log("onTick", "Delta: (" + delta.x + ":" + delta.y + ")");
        */

        // Face in the right direction
        f32 x = this.getVelocity().x;
        if (Maths::Abs(x) > 1.0f)
        {
            this.SetFacingLeft(x < 0);
        }
        else
        {
            this.SetFacingLeft(direction.x < 0);
        }

        u8 old_climb_state    = this.get_u8("climb state");
        bool already_climbing = old_climb_state != CLIMB_STATE_NOT_CLIMBING;
        u8 new_climb_state    = CLIMB_STATE_NOT_CLIMBING;

        if (this.isInWater())
        {
            this.AddForce(Vec2f(0, direction.y < 0 ? -runForce : runForce));
        }
        else if (already_climbing || getGameTime() % 20 == 0)
        {
            // If we're already climbing then update every tick, else update every 20 ticks to save CPU
            new_climb_state = tryClimbing(this, direction);
        }

        if (new_climb_state == CLIMB_STATE_NOT_CLIMBING)
        {
            if (direction.x > 0)
            {
                // A small y component helps with corners
                //log("onTick", "Moving right");
                this.AddForce(Vec2f(runForce, -runForce));
            }
            else
            {
                //log("onTick", "Moving left");
                this.AddForce(Vec2f(-runForce, -runForce));
            }

            tryJumping(this, delta);
        }
        else
        {
            //log("onTick", "Climbing! state: " + climb_state);
        }

        // Limit max velocity
        Vec2f vel = this.getVelocity();
        int x_dir = vel.x > 0 ? 1 : -1;
        if (Maths::Abs(vel.x) > max_vel)
        {
            this.setVelocity(Vec2f(x_dir * max_vel, vel.y));
        }

        int y_dir = vel.y > 0 ? 1 : -1;
        if (Maths::Abs(vel.y) > max_vel)
        {
            this.setVelocity(Vec2f(vel.x, y_dir * max_vel));
        }
	
        // Scan in a radius around the zombie
        // Use its direction of movement to determine which blocks to break
        // Only dig when climbing is suspended or above the target
        if ((new_climb_state == CLIMB_STATE_SUSPENDED
                    || (new_climb_state == CLIMB_STATE_NOT_CLIMBING && direction.y > 0)
            )
                && getGameTime() % 10 == 0
                && XORRandom(dig_chance) == 0
           )
        {	
            //log("onTick", "Doing block break");
            Dig(this, direction);
        }
    }

    //this.setVelocity(Vec2f(0,0));// TODO: just for testing
}

void onInit(CSprite@ this)
{
}

void onTick(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
    if (this.isAnimation("revive") && !this.isAnimationEnded()) return;
	if (this.isAnimation("bite") && !this.isAnimationEnded()) return;

    if (blob.getHealth() > 0.0)
    {
		f32 x = blob.getVelocity().x;
		
		if (this.isAnimation("dead"))
		{
			this.SetAnimation("revive");
		}
        else if (isBiting(blob))
        {
			if (!this.isAnimation("bite"))
            {
				this.SetAnimation("bite");
			}
        }
		else if(blob.get_u8("climb state") != CLIMB_STATE_NOT_CLIMBING) 
		{
            u8 cs = blob.get_u8("climb state");

            if (cs == CLIMB_STATE_SIMPLE && !this.isAnimation("climb"))
            {
				this.SetAnimation("climb");
            }
            else if (cs == CLIMB_STATE_OVERHANG && !this.isAnimation("overhang_climb"))
            {
				this.SetAnimation("overhang_climb");
            }
            else if (cs == CLIMB_STATE_SUSPENDED && !this.isAnimation("suspended_climb"))
            {
				this.SetAnimation("suspended_climb");
            }
		}
		else if (Maths::Abs(x) > 0.1f)
		{
			if (!this.isAnimation("walk"))
            {
				this.SetAnimation("walk");
			}
		}
		else
		{
			if (XORRandom(200)==0)
			{
				Sound::Play( "/ZombieGroan" );
			}

			if (!this.isAnimation("idle"))
            {
                this.SetAnimation("idle");
			}
		}
	}
	else 
	{
		if (!this.isAnimation("dead"))
		{
			this.SetAnimation("dead");
			Sound::Play( "/ZombieDie" );
		}
	}
}

void onGib(CSprite@ this)
{
    if (g_kidssafe) {
        return;
    }

    CBlob@ blob = this.getBlob();
    Vec2f pos = blob.getPosition();
    Vec2f vel = blob.getVelocity();
	vel.y -= 3.0f;
    f32 hp = Maths::Min(Maths::Abs(blob.getHealth()), 2.0f) + 1.0;
	const u8 team = blob.getTeamNum();
    CParticle@ Body     = makeGibParticle( "ZombieGibs.png", pos, vel + getRandomVelocity( 90, hp , 80 ),       1, 0, Vec2f (8,8), 2.0f, 20, "/BodyGibFall", team );
    CParticle@ Arm1     = makeGibParticle( "ZombieGibs.png", pos, vel + getRandomVelocity( 90, hp - 0.2 , 80 ), 1, 1, Vec2f (8,8), 2.0f, 20, "/BodyGibFall", team );
    CParticle@ Arm2     = makeGibParticle( "ZombieGibs.png", pos, vel + getRandomVelocity( 90, hp - 0.2 , 80 ), 1, 2, Vec2f (8,8), 2.0f, 20, "/BodyGibFall", team );
    CParticle@ Shield   = makeGibParticle( "ZombieGibs.png", pos, vel + getRandomVelocity( 90, hp , 80 ),       1, 3, Vec2f (8,8), 2.0f, 0, "/BodyGibFall", team );
    CParticle@ Sword    = makeGibParticle( "ZombieGibs.png", pos, vel + getRandomVelocity( 90, hp + 1 , 80 ),   1, 4, Vec2f (8,8), 2.0f, 0, "/BodyGibFall", team );
}

f32 onHit( CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData )
{		
    if (this.hasTag("dead"))
        return damage;

    log("onHit", "Hook called. intial health=" + this.getHealth() + ", damage=" + damage);

    this.Damage( damage, hitterBlob );
    log("onHit", "final health=" + this.getHealth());

    if (this.getHealth() <= 0)
    {
        this.Tag("dead");
        this.getShape().SetGravityScale(1.0); // fixes bug where gravity is still 0 from climbing
        log("onHit", "Damage was fatal");
    }

    return 0.0;
}														


bool doesCollideWithBlob( CBlob@ this, CBlob@ blob )
{
	if ( blob.hasTag("dead") || blob.hasTag("zombie"))
		return false;
	
	return true;
}

void onCollision( CBlob@ this, CBlob@ blob, bool solid, Vec2f normal, Vec2f point1 )
{
    /*
    */
}

void onHitBlob( CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitBlob, u8 customData )
{
/*	if (hitBlob !is null)
	{
		Vec2f force = velocity * this.getMass() * 0.35f ;
		force.y -= 1.0f;
		hitBlob.AddForce( force);
	}*/
}

void dropHeart( CBlob@ this )
{
    if (!this.hasTag("dropped heart")) //double check
    {
        CPlayer@ killer = this.getPlayerOfRecentDamage();
        CPlayer@ myplayer = this.getDamageOwnerPlayer();

        if (killer is null || ((myplayer !is null) && killer.getUsername() == myplayer.getUsername())) { return; }

        this.Tag("dropped heart");

        if ((XORRandom(1024) / 1024.0f) < 0.25)
        {
            CBlob@ heart = server_CreateBlob( "heart", -1, this.getPosition() );

            if (heart !is null)
            {
                Vec2f vel( XORRandom(2) == 0 ? -2.0 : 2.0f, -5.0f );
                heart.setVelocity(vel);
            }
        }
    }
}

void onDie( CBlob@ this )
{
	if (!getNet().isServer()) return;

    if (this.hasTag("dropped heart"))
    {
        return;
    }
    else
    {
        dropHeart(this);
    }
}

bool isBiting(CBlob@ this)
{
    u32 t = getGameTime();
    // last bite time is set by EatOthers
    return t >= 100 && (t - this.get_u32("last bite time") <= this.get_u16("bite freq"));
}

bool hasTarget(CBlob@ this)
{
    u32 target_netid = this.get_u32("target netid");
    if (target_netid == 0)
    {
        return false;
    }
    else
    {
        CBlob@ target = getBlobByNetworkID(target_netid);

        if (target is null)
        {
            log("hasTarget", "Target is null. (ID " + target_netid + ")");
            return false;
        }
        else if (target.hasTag("dead"))
        {
            log("hasTarget", "Target is dead. (ID " + target_netid + ")");
            return false;
        }
    }

    return true;
}

// Returns true if a target was found
bool getNewTarget(CBlob@ this)
{
    log("getNewTarget", "Function called");
    // Target the closest targetable thing
    CBlob@[] potential_targets;
    string[]@ tags;
    this.get("tags to eat", @tags);

    for (int i=0; i < tags.length(); i++)
    {
        CBlob@[] blobs;
        getBlobsByTag(tags[i], blobs);

        for (int j=0; j < blobs.length(); j++)
        {
            if (!blobs[j].hasTag("dead"))
                potential_targets.push_back(blobs[j]);
        }
    }

    if (potential_targets.length() == 0)
        return false;

    u32 closest_target;
    f32 closest_distance = 10000.0;

    for (int i=0; i < potential_targets.length(); i++)
    {
        CBlob@ blob = potential_targets[i];
        f32 dist    = this.getDistanceTo(blob);

        if (dist < closest_distance)
        {
            closest_target = blob.getNetworkID();
            closest_distance = dist;
        }
    }

    log("getNewTarget", "Choosing target with netid " + closest_target);
    this.set_u32("target netid", closest_target);
    this.Sync("target netid", true);

    calcPathToTarget(this);

    return true;
}

void calcPathToTarget(CBlob@ this)
{
    //log("calcPathToTarget", "Function called");
    CBrain@ brain = this.getBrain();
    CBlob@ target = getBlobByNetworkID(this.get_u32("target netid"));
    if (target is null)
    {
        log("calcPathToTarget", "Target is null! Returning prematurely.");
        return;
    }

    brain.SetPathTo(target.getPosition(), false);
    //log("calcPathToTarget", "Current path size: " + brain.getPathSize());

    this.set_Vec2f("target pos", target.getPosition());
}

void Dig(CBlob@ this, Vec2f direction)
{

    CMap@ map = getMap();
    HitInfo@[] hitInfos;


    Vec2f pos = this.getPosition() - Vec2f(2, 0).RotateBy(-direction.Angle());
    f32 arcdegrees = 90.0;
    f32 attack_distance = this.getRadius() + dig_distance;
    if (map.getHitInfosFromArc(this.getPosition(), -direction.Angle()-arcdegrees/2.0, arcdegrees, attack_distance, this, @hitInfos))
    {
        //log("Dig", "Number of hitInfos: " + hitInfos.length());

        for (int i=0; i < hitInfos.length(); i++)
        {
            HitInfo@ hi = hitInfos[i];

            if (hi.blob is null)
            {
                //log("Dig", "Tile type: " + hi.tile);
                Tile tile = map.getTile(hi.tileOffset);  
                
                if (map.isTileBackgroundNonEmpty(tile) || map.isTileSolid(tile))
                {
                    //log("Dig", "It's hittable");
                    Vec2f tilepos = map.getTileWorldPosition(hi.tileOffset) + Vec2f(4, 4);
                    map.server_DestroyTile(tilepos, dig_damage);
                    break;
                }
                else
                {
                    //log("Dig", "It's not hittable");
                }
            }
        }
    }
    else
    {
        //log("Dig", "No hitInfos!");
    }
}


// Trys to climb, adjusting 'climb state'
// Returns the new climbing state
// direction refers to the direction of the target from the zombie
u8 tryClimbing(CBlob@ this, Vec2f direction)
{
    //log("tryClimbing", "Trying to climb...");
    CMap@ map = getMap();

    Vec2f tilepos = this.getPosition();
    float tx = tilepos.x;
    float ty = tilepos.y;
    int   ts = map.tilesize;

    bool blockLeft        = IsTileClimbable(Vec2f(tx-ts, ty     ));
    bool blockRight       = IsTileClimbable(Vec2f(tx+ts, ty     ));
    bool blockTopLeft     = IsTileClimbable(Vec2f(tx-ts, ty-ts  ));
    bool blockTopTopLeft  = IsTileClimbable(Vec2f(tx-ts, ty-ts*2));
    bool blockTopRight    = IsTileClimbable(Vec2f(tx+ts, ty-ts  ));
    bool blockTopTopRight = IsTileClimbable(Vec2f(tx+ts, ty-ts*2));
    bool blockAbove       = IsTileClimbable(Vec2f(tx   , ty-ts  ));
    bool blockAboveTop    = IsTileClimbable(Vec2f(tx   , ty-ts*2));
    bool blockBelow       = IsTileClimbable(Vec2f(tx   , ty+ts  ));
    bool blockBotLeft     = IsTileClimbable(Vec2f(tx-ts, ty+ts  ));
    bool blockBotRight    = IsTileClimbable(Vec2f(tx+ts, ty+ts  ));

    Vec2f up    = Vec2f(0.0, -climbForce);
    Vec2f left  = Vec2f(-climbForce, 0.0);
    Vec2f right = Vec2f(climbForce, 0.0);

    u8 old_climb_state = this.get_u8("climb state");
    bool already_climbing = old_climb_state != CLIMB_STATE_NOT_CLIMBING;
    u8 climb_state = CLIMB_STATE_NOT_CLIMBING;

    // Key: 0=air, #=block, ?=maybe block, Z=zombie
    // Should handle these cases:
    // # #      # #     0 0
    // # #      0 0     0 #
    // Z 0      Z #     Z #
    bool canWalkRight = blockBelow
                        && ((!blockRight)
                            || ((!blockAbove) && (!blockTopRight))
                            || ((!blockAbove) && (!blockAboveTop) && (!blockTopTopRight))
                           );

    bool clearRight = (!blockRight) && (!blockBotRight);

    // # #      # #     0 0
    // # #      0 0     # 0
    // 0 Z      # Z     # Z
    bool canWalkLeft = blockBelow
                       && ((!blockLeft)
                           || ((!blockAbove) && (!blockTopLeft))
                           || ((!blockAbove) && (!blockAboveTop) && (!blockTopTopLeft))
                          );

    bool clearLeft = (!blockLeft) && (!blockBotLeft);

    if (   direction.x > 0 && (canWalkRight || (!already_climbing) && clearRight)
        || direction.x < 0 && (canWalkLeft  || (!already_climbing) && clearLeft))
    {
        //log("tryClimbing", "Not climbing because walking is possible");
    }
    else if (blockLeft || blockRight || blockTopLeft || blockTopRight || blockAbove || blockBotLeft || blockBotRight)
    {
        //log("tryClimbing", "Potential climb block found.");
        climb_state = CLIMB_STATE_SIMPLE;

        if (blockAbove) // deal with overhangs
        {
            //log("tryClimbing", "blockAbove");
            climb_state = CLIMB_STATE_OVERHANG;

            if (blockTopLeft && (!blockTopRight) && (!blockRight))
            {
                // Case 1 
                // # # 0
                // ? Z 0
                //log("tryClimbing", "Case 1");
                this.AddForce(right);
                this.SetFacingLeft(false);
            }
            else if ((!blockTopLeft) && blockTopRight && (!blockLeft))
            {
                // Case 2 
                // 0 # #
                // 0 Z ?
                //log("tryClimbing", "Case 2");
                this.AddForce(left);
                this.SetFacingLeft(true);
            }
            else if (blockLeft && blockRight)
            {
                // Case 3 
                // ? # ?
                // # Z #
                //log("tryClimbing", "Case 3 - can't continue, relying on digging");

                climb_state = CLIMB_STATE_SUSPENDED;
                this.AddForce(up);
            }
            else if (blockTopLeft && blockTopRight)
            {
                // Case 4 
                // # # #
                // ? Z ?
                //log("tryClimbing", "Case 4");

                bool endsLeft = false;
                for (int x = tx; x >= tx - overhang_check_dist*ts; x -= ts)
                {
                    if (x < 0) // gone off edge of map
                        break;

                    Vec2f overhangTilepos = Vec2f(x, ty-8);
                    Vec2f climbTilepos    = Vec2f(x, ty);
                    if (IsTileClimbable(climbTilepos)) // this tile would be impassible
                        break;
                    else if (IsTileClimbable(overhangTilepos))
                        continue;
                    else // there's space to get up
                    {
                        endsLeft = true;
                        break;
                    }
                } 

                if (endsLeft)
                {
                    //log("tryClimbing", "Opening found on the left side");
                    this.AddForce(left);
                    this.SetFacingLeft(true);
                }
                else
                {
                    bool endsRight = false;
                    for (int x = tx; x <= tx + overhang_check_dist*ts; x += ts)
                    {
                        if (x > map.tilemapwidth*ts) // gone off edge of map
                            break;

                        Vec2f overhangTilepos = Vec2f(x, ty-8);
                        Vec2f climbTilepos    = Vec2f(x, ty);
                        if (IsTileClimbable(climbTilepos)) // this tile would be impassible
                            break;
                        else if (IsTileClimbable(overhangTilepos))
                            continue;
                        else // there's space to get up
                        {
                            endsRight = true;
                            break;
                        }
                    } 

                    if (endsRight)
                    {
                        //log("tryClimbing", "Opening found on the right side");
                        this.AddForce(right);
                        this.SetFacingLeft(false);
                    }
                    else
                    {
                        //log("tryClimbing", "No opening found. Moving in direction of target.");
                        if (direction.x > 0)
                        {
                            this.AddForce(right);
                            this.SetFacingLeft(false);
                        }
                        else
                        {
                            this.AddForce(left);
                            this.SetFacingLeft(true);
                        }

                        climb_state = CLIMB_STATE_SUSPENDED;
                    }
                }
            }
        }
        else
        {
            if (blockRight || blockLeft || blockBotLeft || blockBotRight || blockTopLeft || blockTopRight)
            {
                //log("tryClimbing", "Going straight up");
                this.AddForce(up);

                if (blockBotLeft || blockLeft || blockTopLeft)
                {
                    this.SetFacingLeft(true);
                }
                else
                {
                    this.SetFacingLeft(false);
                }
            }
                
            // If partially in the left/right tile, then
            // Snap to the centre of the current tile so we don't get stuck
            float left  = Maths::Floor((tx - this.getShape().getWidth()/2)/8.0);
            float right = Maths::Floor((tx + this.getShape().getWidth()/2)/8.0);
            //log("tryClimbing", "left=" + left + ", right=" + right);
            if (left != right)
                centreInTile(this);

            this.setVelocity(Vec2f(0, this.getVelocity().y)); // prevent falling off 
        }
    }

    this.set_u8("climb state", climb_state);
    this.Sync("climb state", true);

    if (climb_state == CLIMB_STATE_NOT_CLIMBING)
    {
        this.getShape().SetGravityScale(1.0);
    }
    else
    {
        this.getShape().SetGravityScale(0.0);
    }

    return climb_state;
}

// Returns true if jumping was successful
// delta refers to the offset of the target from the zombie
bool tryJumping(CBlob@ this, Vec2f delta)
{
    //log("tryJumping", "Function called");
    if (delta.y > -6 && !this.isOnWall()) // target is below us or not far above us - no need to jump
    {
        //log("tryJumping", "Not jumping because target is not above us");
        return false;
    }

    u32 time_since_last_jump = getGameTime() - this.get_u32("last jump time");
    bool canJump = this.isOnGround();

    if (time_since_last_jump > time_between_jumps && canJump)
    {
        float force = -jumpForce;

        if (this.isInWater()) force *= 1.5;

        this.AddForce(Vec2f(0, force));

        //log("onTick", "Jumping up");
        //this.set_u32("last jump time", getGameTime());
        return true;
    }
    else
    {
        //log("tryJumping", "Not enough time since last jump");
        return false;
    }
}

// Moves the zombie to the centre of the current tile - useful for not getting stuck when climbing
void centreInTile(CBlob@ this)
{
    //log("centreInTile", "Function called");

    CMap@ map = getMap();
    f32 div_maptile = 1.0f / map.tilesize;

    Vec2f p = this.getPosition();

    Vec2f tp = p * div_maptile;
    Vec2f round_tp = tp;
    round_tp.x = Maths::Floor(round_tp.x);
    round_tp.y = Maths::Floor(round_tp.y);

    f32 width = this.getShape().getWidth() * div_maptile;
    f32 height = this.getShape().getHeight() * div_maptile;

    f32 x_margin = (map.tilesize - width)/2.0;
    f32 y_margin = (map.tilesize - height)/2.0;

    p.x = round_tp.x * map.tilesize + x_margin;
    p.y = round_tp.y * map.tilesize + y_margin;
    this.setPosition(p);
}

bool IsTileClimbable(Vec2f pos)
{
    CMap@ map = getMap();

    if (map.isTileSolid(pos))
        return true;
    else
    {
        // Check for climbable blobs
        // i.e. doors
        CBlob@[] blobs; 
        map.getBlobsAtPosition(pos, blobs);

        for (u8 i = 0; i < blobs.length; i++)
        {
            string name = blobs[i].getName();
            if (name == "stone_door" || name == "wooden_door")
            {
                return true;
            }
        }
    }

    return false;
}
