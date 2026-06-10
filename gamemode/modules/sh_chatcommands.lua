--[[---------------------------------------------------------------------------
    Chat Commands Registration
---------------------------------------------------------------------------]]

SWGRP.RegisterChatCommand( "ooc", {
	description = "Out of character global chat",
	execute = function( ply, args )
		local msg = table.concat( args, " " )
		for _, p in ipairs( player.GetAll() ) do
			p:ChatPrint( "[OOC] " .. ply:Nick() .. ": " .. msg )
		end
	end,
})

SWGRP.RegisterChatCommand( "a", {
	description = "Alias for OOC",
	execute = function( ply, args )
		SWGRP.ChatCmds["ooc"].execute( ply, args )
	end,
})

SWGRP.RegisterChatCommand( "yell", {
	description = "Yell to nearby players",
	execute = function( ply, args )
		local msg = table.concat( args, " " )
		for _, p in ipairs( SWGRP.Util.PlayerInRange( ply, SWGRP.Config.ChatRangeYell ) ) do
			p:ChatPrint( "[YELL] " .. ply:Nick() .. ": " .. msg )
		end
	end,
})

SWGRP.RegisterChatCommand( "y", {
	description = "Alias for yell",
	execute = function( ply, args )
		SWGRP.ChatCmds["yell"].execute( ply, args )
	end,
})

SWGRP.RegisterChatCommand( "whisper", {
	description = "Whisper to nearby players",
	execute = function( ply, args )
		local msg = table.concat( args, " " )
		for _, p in ipairs( SWGRP.Util.PlayerInRange( ply, SWGRP.Config.ChatRangeWhisper ) ) do
			p:ChatPrint( "[Whisper] " .. ply:Nick() .. ": " .. msg )
		end
	end,
})

SWGRP.RegisterChatCommand( "w", {
	description = "Alias for whisper",
	execute = function( ply, args )
		SWGRP.ChatCmds["whisper"].execute( ply, args )
	end,
})

SWGRP.RegisterChatCommand( "me", {
	description = "Perform an action",
	execute = function( ply, args )
		local msg = table.concat( args, " " )
		for _, p in ipairs( SWGRP.Util.PlayerInRange( ply, SWGRP.Config.ChatRangeMe ) ) do
			p:ChatPrint( "* " .. ply:Nick() .. " " .. msg )
		end
	end,
})

SWGRP.RegisterChatCommand( "advert", {
	description = "Galactic advertisement",
	execute = function( ply, args )
		local msg = table.concat( args, " " )
		if SWGRP.Advert and SWGRP.Advert.Send then
			if not SWGRP.Advert.Send( ply, "Advert - " .. ply:Nick(), msg ) then return end
		end
		for _, p in ipairs( player.GetAll() ) do
			p:ChatPrint( "[Advert] " .. ply:Nick() .. ": " .. msg )
		end
	end,
})

SWGRP.RegisterChatCommand( "pm", {
	description = "Private message",
	execute = function( ply, args )
		local target = SWGRP.FindPlayer( args[1] )
		if not IsValid( target ) then return end
		table.remove( args, 1 )
		local msg = table.concat( args, " " )
		ply:ChatPrint( "[PM -> " .. target:Nick() .. "] " .. msg )
		target:ChatPrint( "[PM <- " .. ply:Nick() .. "] " .. msg )
	end,
})

SWGRP.RegisterChatCommand( "g", {
	description = "Profession group chat",
	execute = function( ply, args )
		local msg = table.concat( args, " " )
		local teamId = ply:Team()
		for _, p in ipairs( player.GetAll() ) do
			if p:Team() == teamId then
				p:ChatPrint( "[Group] " .. ply:Nick() .. ": " .. msg )
			end
		end
	end,
})

SWGRP.RegisterChatCommand( "broadcast", {
	description = "Governor broadcast",
	execute = function( ply, args )
		if not ply:SWGRP_IsGovernor() then
			SWGRP.Notify( ply, SWGRP.Lang.not_governor )
			return
		end
		local msg = table.concat( args, " " )
		if SWGRP.Advert and SWGRP.Advert.Broadcast then
			SWGRP.Advert.Broadcast( "Governor Broadcast", msg, SWGRP.Config.HUDColorDanger )
		end
		for _, p in ipairs( player.GetAll() ) do
			p:ChatPrint( "[GOVERNOR] " .. msg )
		end
	end,
})

SWGRP.RegisterChatCommand( "give", {
	description = "Hand credits to the player you are looking at",
	execute = function( ply, args )
		local amount = tonumber( args[1] ) or 0
		amount = math.floor( amount )
		if amount <= 0 then
			SWGRP.Notify( ply, "Usage: /give <amount> (while looking at a player)" )
			return
		end

		local target = ply:GetEyeTrace().Entity
		if not IsValid( target ) or not target:IsPlayer() or target == ply then
			SWGRP.Notify( ply, "Look at a player to give them credits." )
			return
		end

		if ply:GetPos():DistToSqr( target:GetPos() ) > 40000 then -- 200 units
			SWGRP.Notify( ply, "You are too far away." )
			return
		end

		if SWGRP.Economy.GiveCredits( ply, target, amount ) then
			SWGRP.Notify( ply, "Gave " .. SWGRP.FormatCredits( amount ) .. " to " .. target:Nick() .. "." )
			SWGRP.Notify( target, "Received " .. SWGRP.FormatCredits( amount ) .. " from " .. ply:Nick() .. "." )
			SWGRP.Log( "economy", ply:Nick() .. " gave " .. SWGRP.FormatCredits( amount ) .. " to " .. target:Nick() )
		else
			SWGRP.Notify( ply, SWGRP.Lang.cant_afford )
		end
	end,
})

SWGRP.RegisterChatCommand( "dropcredits", {
	description = "Drop credits on the ground",
	execute = function( ply, args )
		local amount = tonumber( args[1] ) or 0
		SWGRP.Economy.DropCredits( ply, amount )
	end,
})

SWGRP.RegisterChatCommand( "moneydrop", {
	description = "Alias for dropcredits",
	execute = function( ply, args )
		SWGRP.ChatCmds["dropcredits"].execute( ply, args )
	end,
})

SWGRP.RegisterChatCommand( "wanted", {
	description = "Mark a player wanted",
	execute = function( ply, args )
		if not SWGRP.Police.CanEnforce( ply ) then
			SWGRP.Notify( ply, SWGRP.Lang.not_government )
			return
		end
		local target = SWGRP.FindPlayer( args[1] )
		table.remove( args, 1 )
		if IsValid( target ) then
			SWGRP.Police.SetWanted( target, table.concat( args, " " ), ply )
		end
	end,
})

SWGRP.RegisterChatCommand( "unwanted", {
	description = "Clear wanted status",
	execute = function( ply, args )
		if not SWGRP.Police.CanEnforce( ply ) then return end
		local target = SWGRP.FindPlayer( args[1] )
		if IsValid( target ) then SWGRP.Police.ClearWanted( target, ply ) end
	end,
})

SWGRP.RegisterChatCommand( "warrant", {
	description = "Issue search warrant",
	execute = function( ply, args )
		if not SWGRP.Police.CanEnforce( ply ) then return end
		local target = SWGRP.FindPlayer( args[1] )
		table.remove( args, 1 )
		if IsValid( target ) then
			SWGRP.Police.SetWarrant( target, table.concat( args, " " ), ply )
		end
	end,
})

SWGRP.RegisterChatCommand( "givelicense", {
	description = "Grant weapon permit",
	execute = function( ply, args )
		local target = SWGRP.FindPlayer( args[1] )
		if IsValid( target ) then SWGRP.Police.GrantLicense( target, ply ) end
	end,
})

SWGRP.RegisterChatCommand( "takelicense", {
	description = "Revoke weapon permit",
	execute = function( ply, args )
		local target = SWGRP.FindPlayer( args[1] )
		if IsValid( target ) then SWGRP.Police.RevokeLicense( target, ply ) end
	end,
})

SWGRP.RegisterChatCommand( "hit", {
	description = "Place bounty contract",
	execute = function( ply, args )
		local target = SWGRP.FindPlayer( args[1] )
		local price = tonumber( args[2] ) or SWGRP.Config.HitMinPrice
		if IsValid( target ) then SWGRP.Hitman.PlaceContract( ply, target, price ) end
	end,
})

SWGRP.RegisterChatCommand( "lottery", {
	description = "Buy lottery ticket",
	execute = function( ply, args )
		SWGRP.Government.BuyLotteryTicket( ply )
	end,
})

SWGRP.RegisterChatCommand( "demote", {
	description = "Start demotion vote",
	execute = function( ply, args )
		local target = SWGRP.FindPlayer( args[1] )
		if IsValid( target ) then SWGRP.Demote.StartVote( ply, target ) end
	end,
})

SWGRP.RegisterChatCommand( "lockdown", {
	description = "Start imperial lockdown",
	execute = function( ply, args )
		if ply:SWGRP_IsGovernor() then SWGRP.Government.StartLockdown( ply ) end
	end,
})

SWGRP.RegisterChatCommand( "unlockdown", {
	description = "End imperial lockdown",
	execute = function( ply, args )
		if ply:SWGRP_IsGovernor() then SWGRP.Government.EndLockdown() end
	end,
})

SWGRP.RegisterChatCommand( "addlaw", {
	description = "Add a planetary law",
	execute = function( ply, args )
		if ply:SWGRP_IsGovernor() then
			SWGRP.Government.AddLaw( table.concat( args, " " ) )
		end
	end,
})

SWGRP.RegisterChatCommand( "radio", {
	description = "Transmit on your profession radio channel",
	execute = function( ply, args )
		local msg = table.concat( args, " " )
		local job = SWGRP.GetJob( ply:Team() )
		local channel = job and job.category or "General"
		for _, p in ipairs( player.GetAll() ) do
			local pJob = SWGRP.GetJob( p:Team() )
			if pJob and pJob.category == channel then
				p:ChatPrint( "[Radio:" .. channel .. "] " .. ply:Nick() .. ": " .. msg )
			end
		end
	end,
})

SWGRP.RegisterChatCommand( "channel", {
	description = "Alias for radio",
	execute = function( ply, args )
		SWGRP.ChatCmds["radio"].execute( ply, args )
	end,
})

SWGRP.RegisterChatCommand( "heal", {
	description = "Heal targeted player (medics)",
	execute = function( ply, args )
		if not ply:SWGRP_IsMedic() then return end
		ply:ConCommand( "swgrp_heal" )
	end,
})

SWGRP.RegisterChatCommand( "agenda", {
	description = "Set governor agenda",
	execute = function( ply, args )
		if not ply:SWGRP_IsGovernor() then return end
		SWGRP.Government.SetAgenda( table.concat( args, " " ) )
	end,
})

SWGRP.RegisterChatCommand( "removelaw", {
	description = "Remove a planetary law",
	execute = function( ply, args )
		if ply:SWGRP_IsGovernor() then
			SWGRP.Government.RemoveLaw( tonumber( args[1] ) or 0 )
		end
	end,
})

SWGRP.RegisterChatCommand( "deposit", {
	description = "Deposit credits to bank",
	execute = function( ply, args )
		SWGRP.Banking.Deposit( ply, tonumber( args[1] ) or 0 )
	end,
})

SWGRP.RegisterChatCommand( "withdraw", {
	description = "Withdraw credits from bank",
	execute = function( ply, args )
		SWGRP.Banking.Withdraw( ply, tonumber( args[1] ) or 0 )
	end,
})

SWGRP.RegisterChatCommand( "balance", {
	description = "Check bank balance",
	execute = function( ply, args )
		SWGRP.Notify( ply, "Bank: " .. SWGRP.FormatCredits( SWGRP.Banking.GetBalance( ply ) ) .. " | Wallet: " .. SWGRP.FormatCredits( ply:SWGRP_GetCredits() ) )
	end,
})

SWGRP.RegisterChatCommand( "transfer", {
	description = "Bank transfer to player",
	execute = function( ply, args )
		SWGRP.Banking.Transfer( ply, args[1], tonumber( args[2] ) or 0 )
	end,
})

SWGRP.RegisterChatCommand( "craft", {
	description = "Craft a recipe by id",
	execute = function( ply, args )
		SWGRP.Crafting.Craft( ply, args[1] or "" )
	end,
})

SWGRP.RegisterChatCommand( "scan", {
	description = "Imperial contraband scan",
	execute = function( ply, args )
		local target = SWGRP.FindPlayer( args[1] ) or ply:GetEyeTrace().Entity
		if IsValid( target ) and target:IsPlayer() then
			SWGRP.Contraband.Scan( ply, target )
		end
	end,
})

SWGRP.RegisterChatCommand( "contraband", {
	description = "Acquire contraband (smugglers)",
	execute = function( ply, args )
		local job = SWGRP.GetJob( ply:Team() )
		if job and ( job.name == "Smuggler" or job.bountyhunter ) then
			SWGRP.Contraband.AcquireRandom( ply )
		else
			SWGRP.Notify( ply, "Only smugglers and bounty hunters can acquire contraband." )
		end
	end,
})

SWGRP.RegisterChatCommand( "eat", {
	description = "Consume rations",
	execute = function( ply, args )
		SWGRP.Hunger.Feed( ply, 30 )
	end,
})

SWGRP.RegisterChatCommand( "collect", {
	description = "Collect mission sample",
	execute = function( ply, args )
		if ply.SWGRP_ActiveMission and ply.SWGRP_ActiveMission.data.type == "collection" then
			SWGRP.MissionsMgr.AddProgress( ply, 1 )
			SWGRP.Materials.Add( ply, "metal", 1 )
		end
	end,
})

SWGRP.RegisterChatCommand( "sign", {
	description = "Set holo sign text",
	execute = function( ply, args )
		local tr = ply:GetEyeTrace()
		if IsValid( tr.Entity ) and tr.Entity:GetClass() == "swgrp_holo_sign" and tr.Entity.SWGRP_Owner == ply then
			tr.Entity:SetSignText( string.sub( table.concat( args, " " ), 1, 64 ) )
			SWGRP.Notify( ply, "Sign updated." )
		end
	end,
})

SWGRP.RegisterChatCommand( "addcoowner", {
	description = "Add co-owner to structure door you are looking at",
	execute = function( ply, args )
		local target = SWGRP.FindPlayer( args[1] )
		local tr = ply:GetEyeTrace()
		if IsValid( target ) and IsValid( tr.Entity ) and tr.Entity:isDoor() then
			SWGRP.Doors.AddCoOwner( ply, tr.Entity, target )
			SWGRP.Notify( ply, "Co-owner added: " .. target:Nick() )
		else
			SWGRP.Notify( ply, "Look at your door and specify a player name." )
		end
	end,
})

SWGRP.RegisterChatCommand( "removecoowner", {
	description = "Remove co-owner from structure door you are looking at",
	execute = function( ply, args )
		local target = SWGRP.FindPlayer( args[1] )
		local tr = ply:GetEyeTrace()
		if IsValid( target ) and IsValid( tr.Entity ) and tr.Entity:isDoor() then
			SWGRP.Doors.RemoveCoOwner( ply, tr.Entity, target )
			SWGRP.Notify( ply, "Co-owner removed: " .. target:Nick() )
		else
			SWGRP.Notify( ply, "Look at your door and specify a player name." )
		end
	end,
})

SWGRP.RegisterChatCommand( "settitle", {
	description = "Set title on owned structure door",
	execute = function( ply, args )
		local tr = ply:GetEyeTrace()
		if IsValid( tr.Entity ) and tr.Entity:isDoor() then
			SWGRP.Doors.SetTitle( ply, tr.Entity, table.concat( args, " " ) )
			SWGRP.Notify( ply, "Structure title updated." )
		end
	end,
})

SWGRP.RegisterChatCommand( "sellalldoors", {
	description = "Sell every structure you own",
	execute = function( ply )
		if SWGRP.Doors.SellAll then
			SWGRP.Doors.SellAll( ply )
		end
	end,
})

SWGRP.RegisterChatCommand( "pocket", {
	description = "Pocket aimed equipment or your active weapon (Alt+R quick-pocket)",
	execute = function( ply, args )
		SWGRP.Pocket.Store( ply )
	end,
})

SWGRP.RegisterChatCommand( "droppocket", {
	description = "Open the pocket inventory",
	execute = function( ply, args )
		if SWGRP.Pocket.RequestDrop then
			SWGRP.Pocket.RequestDrop( ply )
		else
			SWGRP.Pocket.Drop( ply )
		end
	end,
})

SWGRP.RegisterChatCommand( "letter", {
	description = "Drop a galactic letter with message",
	execute = function( ply, args )
		local text = string.sub( table.concat( args, " " ), 1, 128 )
		if text == "" then
			SWGRP.Notify( ply, "Usage: /letter your message here" )
			return
		end

		local tr = ply:GetEyeTrace()
		local pos = tr.HitPos + tr.HitNormal * 8

		local ent = ents.Create( "swgrp_letter" )
		if not IsValid( ent ) then return end
		ent:SetPos( pos )
		ent:SetLetterText( text )
		ent:SetAuthorName( ply:Nick() )
		ent:Spawn()
		ent.SWGRP_Owner = ply
		if ent.CPPISetOwner then ent:CPPISetOwner( ply ) end
		SWGRP.Notify( ply, "Letter dropped." )
	end,
})

SWGRP.RegisterChatCommand( "voteban", {
	description = "Start voteban against a player",
	execute = function( ply, args )
		local target = SWGRP.FindPlayer( args[1] )
		if IsValid( target ) then
			SWGRP.VoteBan.Start( ply, target )
		end
	end,
})
