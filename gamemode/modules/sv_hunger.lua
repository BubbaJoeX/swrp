--[[---------------------------------------------------------------------------
    Hunger & Survival System
---------------------------------------------------------------------------]]

SWGRP = SWGRP or {}
SWGRP.Hunger = SWGRP.Hunger or {}

function SWGRP.Hunger.Get( ply )
	return ply:GetNWInt( "SWGRP_Hunger", SWGRP.Config.HungerMax )
end

function SWGRP.Hunger.Set( ply, amount )
	amount = math.Clamp( math.floor( amount ), 0, SWGRP.Config.HungerMax )
	ply:SetNWInt( "SWGRP_Hunger", amount )
	if SWGRP.Persistence then SWGRP.Persistence.ScheduleSave( ply, 10 ) end
end

function SWGRP.Hunger.Add( ply, amount )
	SWGRP.Hunger.Set( ply, SWGRP.Hunger.Get( ply ) + amount )
end

function SWGRP.Hunger.Feed( ply, amount )
	SWGRP.Hunger.Add( ply, amount or 25 )
	ply:EmitSound( "npc/barnacle/barnacle gulp2.wav", 60, 120 )
	SWGRP.Notify( ply, "You consumed rations. Hunger restored." )
end

timer.Create( "SWGRP_HungerTick", 30, 0, function()
	if not SWGRP.Config.HungerEnabled:GetBool() then return end

	for _, ply in ipairs( player.GetAll() ) do
		if not ply:Alive() or ply:SWGRP_IsArrested() then continue end

		local rate = SWGRP.Config.HungerRate:GetInt()
		local job = SWGRP.GetJob( ply:Team() )
		if job and job.hobo then rate = rate * 2 end

		local hunger = SWGRP.Hunger.Get( ply ) - rate
		SWGRP.Hunger.Set( ply, hunger )

		if hunger <= 0 then
			ply:TakeDamage( SWGRP.Config.StarveDamage, game.GetWorld(), game.GetWorld() )
		elseif hunger < 20 then
			ply:TakeDamage( SWGRP.Config.HungerDamage, game.GetWorld(), game.GetWorld() )
		end
	end
end )
