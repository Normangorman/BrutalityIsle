void onTick(CBlob@ this)
{
    if (this.hasTag("invincible") && this.getHealth() < this.getInitialHealth())
    {
        this.server_SetHealth(this.getInitialHealth());
    }
}
