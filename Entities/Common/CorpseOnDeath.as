#include "Logging.as"

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
    //blah
    log("onHit", "Hook called");
    if (damage >= this.getHealth() && !this.hasTag("dead"))
    {
        log("onHit", "Making corpse");
        this.Damage(damage, hitterBlob);
        this.Tag("dead");
        this.UnsetMinimapVars();

        // add pickup attachment so we can pickup body
		CAttachment@ a = this.getAttachments();

		if (a !is null)
		{
			AttachmentPoint@ ap = a.AddAttachmentPoint("PICKUP", false);
		}

        this.getCurrentScript().tickFrequency = 30;

		// new physics vars so bodies don't slide
		this.getShape().setFriction(0.75f);
		this.getShape().setElasticity(0.2f);

        /* corpses seem to bug out in shallow water for some reason
		this.getShape().getConsts().buoyancy = 0.6;
		this.getShape().getConsts().mass *= 4.0;
		this.getShape().setElasticity(0.0);
        */

        this.getShape().getVars().isladder = false;
		this.getShape().getVars().onladder = false;
		this.getShape().checkCollisionsAgain = true;
		this.getShape().SetGravityScale(1.0f);
		// fall out of attachments/seats // drop all held things
		this.server_DetachAll();

        this.set_f32("hit dmg modifier", 0.5f);

        this.set_u32("death time", getGameTime());

        return 0.0;
    }
    else
    {
        return damage;
    }
}
