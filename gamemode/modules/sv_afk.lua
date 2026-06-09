--[[---------------------------------------------------------------------------
    AFK Detection
---------------------------------------------------------------------------]]

hook.Add( "PlayerInitialSpawn", "SWGRP_AFKInit", function( ply )
	ply.SWGRP_LastActivity = CurTime()
	ply.SWGRP_AFKPos = ply:GetPos()
end )

hook.Add( "KeyPress", "SWGRP_AFKActivity", function( ply )
	ply.SWGRP_LastActivity = CurTime()
	if ply:SWGRP_IsAFK() then
		ply:SWGRP_SetAFK( false )
	end
end )

hook.Add( "SetupMove", "SWGRP_AFKMove", function( ply, mv )
	if mv:GetVelocity():Length() > 10 then
		ply.SWGRP_LastActivity = CurTime()
	end
end )

timer.Create( "SWGRP_AFKCheck", 30, 0, function()
	for _, ply in ipairs( player.GetAll() ) do
		local last = ply.SWGRP_LastActivity or CurTime()
		if CurTime() - last > SWGRP.Config.AFKTime then
			if not ply:SWGRP_IsAFK() then
				ply:SWGRP_SetAFK( true )
				SWGRP.Notify( ply, "You are now AFK." )
			end

			if SWGRP.Config.AFKDemote and ply:SWGRP_IsAFK() then
				local job = SWGRP.GetJob( ply:Team() )
				if job and ( job.governor or job.chief or job.vote ) then
					SWGRP.JobsMgr.SetJob( ply, TEAM_COLONIST, true )
					SWGRP.Notify( ply, SWGRP.Lang.afk_demoted )
				end
			end
		end
	end
end )
