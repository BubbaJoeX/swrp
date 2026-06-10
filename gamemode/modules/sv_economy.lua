--[[---------------------------------------------------------------------------
    Economy - Credits, Paydays, Tax, Drops
---------------------------------------------------------------------------]]

SWGRP = SWGRP or {}
SWGRP.Economy = SWGRP.Economy or {}

SWGRP.Economy.Treasury = SWGRP.Economy.Treasury or 0

function SWGRP.Economy.Payday()
	local taxRate = SWGRP.Config.TaxRate:GetFloat()
	local taxOn = SWGRP.Config.TaxEnabled:GetBool()

	for _, ply in ipairs( player.GetAll() ) do
		if not ply:Alive() or ply:SWGRP_IsAFK() or ply:SWGRP_IsArrested() then continue end

		local salary = ply:SWGRP_GetSalary()
		if salary <= 0 then continue end

		local tax = 0
		if taxOn and not ply:SWGRP_IsGovernor() then
			tax = math.floor( salary * taxRate )
			SWGRP.Economy.Treasury = SWGRP.Economy.Treasury + tax
			salary = salary - tax
		end

		ply:SWGRP_AddCredits( salary )
		SWGRP.Profession.AddXP( ply, 5 )
		ply:ChatPrint( string.format( SWGRP.Lang.payday_received, SWGRP.FormatCredits( salary ) ) )
		SWGRP.Hooks.Call( "SWGRPPlayerPaid", ply, salary, tax )
		if tax > 0 then
			ply:ChatPrint( string.format( SWGRP.Lang.payday_tax, SWGRP.FormatCredits( tax ) ) )
		end
	end

	if SWGRP.Persistence then SWGRP.Persistence.SaveWorld() end
end

function SWGRP.Economy.DropCredits( ply, amount )
	amount = math.Clamp( math.floor( amount ), 1, SWGRP.Config.DropCreditLimit )

	if not ply:SWGRP_TakeCredits( amount ) then
		SWGRP.Notify( ply, SWGRP.Lang.cant_afford )
		return
	end

	local tr = ply:GetEyeTrace()
	local pos = tr.HitPos + tr.HitNormal * 16

	local ent = ents.Create( "swgrp_dropped_credits" )
	if not IsValid( ent ) then
		ply:SWGRP_AddCredits( amount )
		return
	end

	ent:SetPos( pos )
	ent:SetCredits( amount )
	ent:Spawn()
	ent.SWGRP_DroppedBy = ply
end

function SWGRP.Economy.GiveCredits( from, to, amount )
	amount = math.floor( amount )
	if amount <= 0 then return false end
	if not IsValid( from ) or not IsValid( to ) then return false end
	if not from:SWGRP_TakeCredits( amount ) then return false end

	to:SWGRP_AddCredits( amount )
	return true
end

-- Pick a spot just in front of the buyer, resting on the ground. The forward
-- vector is flattened (yaw only) so looking up/down doesn't fling the spot into
-- the air or bury it in the floor, and a downward trace drops it onto the
-- surface the player is standing on. Returns the position and a facing angle.
function SWGRP.Economy.GroundSpawn( ply, dist )
	dist = dist or 48

	local fwd = ply:GetAngles()
	fwd.p = 0
	fwd.r = 0
	local forward = fwd:Forward()

	local startPos = ply:GetPos() + Vector( 0, 0, 16 ) + forward * dist
	local tr = util.TraceLine( {
		start  = startPos,
		endpos = startPos - Vector( 0, 0, 200 ),
		filter = ply,
		mask   = MASK_SOLID_BRUSHONLY,
	} )

	local pos = tr.Hit and ( tr.HitPos + Vector( 0, 0, 4 ) ) or ( ply:GetPos() + forward * dist + Vector( 0, 0, 8 ) )
	return pos, Angle( 0, fwd.y, 0 )
end

function SWGRP.Economy.BuyShipment( ply, shipmentId, separate )
	local ship = SWGRP.Shipments[shipmentId]
	if not ship then
		SWGRP.Notify( ply, SWGRP.Lang.shipment_unavailable )
		return
	end

	-- Gate by profession command rather than a pre-resolved team id so the check
	-- can't break when team ids shift across content reloads / Lua refreshes.
	if not SWGRP.PlayerJobAllowedPurchase( ply, ship.allowedcmds ) then
		local job = SWGRP.GetJob( ply:Team() )
		SWGRP.Log( "economy", string.format(
			"%s (job '%s') denied shipment '%s' (allowed: %s)",
			ply:Nick(),
			job and job.command or "?",
			ship.name or "?",
			ship.allowedcmds and table.concat( ship.allowedcmds, "," ) or "*"
		) )
		SWGRP.Notify( ply, SWGRP.Lang.shipment_not_allowed )
		return
	end

	-- Never honor a single-item purchase on a shipment that isn't separable;
	-- pricesep defaults to 0, which would otherwise hand out near-free items.
	if separate and not ship.separate then
		separate = false
	end

	local price = math.max( 0, math.floor( ( separate and ship.pricesep or ship.price ) or 0 ) )
	if not ply:SWGRP_TakeCredits( price ) then
		SWGRP.Notify( ply, SWGRP.Lang.cant_afford )
		return
	end

	local class = ship.entities and ship.entities[1] or ""
	if class == "" then
		ply:SWGRP_AddCredits( price )
		SWGRP.Notify( ply, SWGRP.Lang.shipment_no_contents )
		return
	end

	local pos, ang = SWGRP.Economy.GroundSpawn( ply )

	-- A single-item purchase drops the weapon as a pickup on the ground in front
	-- of the buyer; only full crates spawn the shipment crate entity.
	if separate then
		local wep = ents.Create( class )
		if not IsValid( wep ) then
			ply:SWGRP_AddCredits( price )
			SWGRP.Notify( ply, SWGRP.Lang.shipment_spawn_fail )
			return
		end
		wep:SetPos( pos )
		wep:SetAngles( ang )
		wep:Spawn()
		wep:Activate()
		if SWGRP.Ownership and SWGRP.Ownership.SetOwner then
			SWGRP.Ownership.SetOwner( wep, ply )
		end
		SWGRP.Notify( ply, string.format( "Purchased %s for %s. It dropped in front of you.", ship.name, SWGRP.FormatCredits( price ) ) )
		SWGRP.Hooks.Call( "SWGRPEntityPurchased", ply, ship.name .. " (single)", price )
		return
	end

	local ent = ents.Create( "swgrp_shipment" )
	if not IsValid( ent ) then
		ply:SWGRP_AddCredits( price )
		SWGRP.Notify( ply, SWGRP.Lang.shipment_spawn_fail )
		return
	end
	ent:SetShipmentData( ship, separate )
	ent:Spawn()
	ent:Activate()
	-- Position after Spawn so the (now guaranteed) physics object is moved with
	-- the entity rather than leaving it parked at the world origin or in the floor.
	ent:SetPos( pos )
	ent:SetAngles( ang )
	if SWGRP.Ownership and SWGRP.Ownership.SetOwner then
		SWGRP.Ownership.SetOwner( ent, ply )
	end
	SWGRP.Notify( ply, string.format( "Purchased %s crate (%d items) for %s.", ship.name, ship.amount or 0, SWGRP.FormatCredits( price ) ) )
	SWGRP.Hooks.Call( "SWGRPEntityPurchased", ply, ship.name .. " crate", price )
end

function SWGRP.Economy.BuyFood( ply, foodId )
	if not IsValid( ply ) then return end

	local food = SWGRP.Foods[foodId]
	if not food then
		SWGRP.Notify( ply, "That ration is unavailable." )
		return
	end

	if not SWGRP.PlayerJobAllowedPurchase( ply, food.allowedcmds ) then
		SWGRP.Notify( ply, "Your profession can't buy that ration." )
		return
	end

	-- Must be standing at a ration terminal to purchase (prevents buying from
	-- anywhere by replaying the net message).
	local near = false
	for _, ent in ipairs( ents.FindInSphere( ply:GetPos(), 200 ) ) do
		if IsValid( ent ) and ent:GetClass() == "swgrp_ration_dispenser" then
			near = true
			break
		end
	end
	if not near then
		SWGRP.Notify( ply, "You must be at a ration terminal." )
		return
	end

	local price = math.max( 0, math.floor( food.price or 0 ) )
	if not ply:SWGRP_TakeCredits( price ) then
		SWGRP.Notify( ply, SWGRP.Lang.cant_afford )
		return
	end

	if SWGRP.Hunger and ( food.hunger or 0 ) > 0 then
		SWGRP.Hunger.Add( ply, food.hunger )
	end
	if ( food.health or 0 ) > 0 then
		ply:SetHealth( math.min( ply:GetMaxHealth(), ply:Health() + food.health ) )
	end

	ply:EmitSound( "npc/barnacle/barnacle gulp2.wav", 60, math.random( 95, 110 ) )
	SWGRP.Notify( ply, string.format( "Consumed %s for %s.", food.name, SWGRP.FormatCredits( price ) ) )
	SWGRP.Hooks.Call( "SWGRPEntityPurchased", ply, food.name, price )
end

-- Unlike food (consumed instantly), spice is crafted at a Spice Storage Terminal
-- and spawns a physical pickup in the world that can be carried, sold, or
-- consumed later by anyone who presses E on it.
function SWGRP.Economy.CraftSpice( ply, spiceId )
	if not IsValid( ply ) then return end

	local spice = SWGRP.Spices[spiceId]
	if not spice then
		SWGRP.Notify( ply, "That spice is unavailable." )
		return
	end

	if not SWGRP.PlayerJobAllowedPurchase( ply, spice.allowedcmds ) then
		SWGRP.Notify( ply, "Your profession can't craft that spice." )
		return
	end

	-- Must be standing at a spice terminal (prevents crafting anywhere by
	-- replaying the net message).
	local near = false
	for _, ent in ipairs( ents.FindInSphere( ply:GetPos(), 200 ) ) do
		if IsValid( ent ) and ent:GetClass() == "swgrp_spice_terminal" then
			near = true
			break
		end
	end
	if not near then
		SWGRP.Notify( ply, "You must be at a spice storage terminal." )
		return
	end

	local price = math.max( 0, math.floor( spice.price or 0 ) )
	if not ply:SWGRP_TakeCredits( price ) then
		SWGRP.Notify( ply, SWGRP.Lang.cant_afford )
		return
	end

	local pos, ang = SWGRP.Economy.GroundSpawn( ply )
	local ent = ents.Create( "swgrp_spice" )
	if not IsValid( ent ) then
		ply:SWGRP_AddCredits( price )
		SWGRP.Notify( ply, "Failed to craft spice." )
		return
	end

	ent:SetPos( pos )
	ent:SetAngles( ang )
	ent:Spawn()
	ent:Activate()
	ent:SetSpice( spiceId )
	-- Re-place after the model/physics swap in SetSpice so the pickup lands in
	-- front of the crafter rather than wherever the new physics object settled.
	ent:SetPos( pos )
	ent:SetAngles( ang )

	if SWGRP.Ownership and SWGRP.Ownership.SetOwner then
		SWGRP.Ownership.SetOwner( ent, ply )
	end

	SWGRP.Notify( ply, string.format( "Crafted %s for %s. It dropped in front of you.", spice.name, SWGRP.FormatCredits( price ) ) )
	SWGRP.Hooks.Call( "SWGRPSpiceCrafted", ply, spice.name, price )
end

-- Create, place and take ownership of an SWGRP equipment entity. Shared by the
-- F4 purchase path and the pocket "drop" path so both spawn entities the same
-- way. Returns the spawned entity (or nil). The caller owns credits/limits.
function SWGRP.Economy.SpawnStructure( ply, class, pos, ang )
	local ent = ents.Create( class )
	if not IsValid( ent ) then return end

	pos = pos or ( IsValid( ply ) and ply:GetPos() or vector_origin )
	ang = ang or Angle( 0, 0, 0 )

	-- Position before Spawn so entities that link to nearby props in Initialize
	-- (e.g. keypads binding the closest door) run with the entity already placed.
	ent:SetPos( pos )
	ent:SetAngles( ang )
	ent:Spawn()
	ent:Activate()

	-- Make the data file the source of truth for the model, but only if it
	-- yields a valid physics object; otherwise keep the entity's built-in model
	-- so a missing CSV model can't leave an invisible, collisionless structure.
	-- SetModel/PhysicsInit don't move the entity, so the placement above holds.
	local data = SWGRP.Entities[class]
	if data and data.model and data.model ~= "" and data.model ~= ent:GetModel() then
		local builtin = ent:GetModel()
		ent:SetModel( data.model )
		ent:PhysicsInit( SOLID_VPHYSICS )
		if not IsValid( ent:GetPhysicsObject() ) then
			ent:SetModel( builtin )
			ent:PhysicsInit( SOLID_VPHYSICS )
		end
		ent:SetSolid( SOLID_VPHYSICS )
		ent:SetMoveType( MOVETYPE_VPHYSICS )
		ent:SetPos( pos )
		ent:SetAngles( ang )
		local phys = ent:GetPhysicsObject()
		if IsValid( phys ) then phys:Wake() end
	end

	if IsValid( ply ) and SWGRP.Ownership and SWGRP.Ownership.SetOwner then
		SWGRP.Ownership.SetOwner( ent, ply )
	end

	return ent
end

function SWGRP.Economy.BuyEntity( ply, class )
	local data = SWGRP.Entities[class]
	if not data then return end

	-- Command-based gate (robust against team-id drift on content reloads).
	if not SWGRP.PlayerJobAllowedPurchase( ply, data.allowedcmds ) then
		SWGRP.Notify( ply, "Your profession can't deploy that structure." )
		return
	end

	local count = 0
	for _, ent in ipairs( ents.FindByClass( class ) ) do
		if SWGRP.Ownership and SWGRP.Ownership.IsOwner( ply, ent ) then
			count = count + 1
		end
	end
	if data.max and data.max > 0 and count >= data.max then
		SWGRP.Notify( ply, "Maximum number of that structure reached." )
		return
	end

	if not ply:SWGRP_TakeCredits( data.price ) then
		SWGRP.Notify( ply, SWGRP.Lang.cant_afford )
		return
	end

	local pos, ang = SWGRP.Economy.GroundSpawn( ply )
	local ent = SWGRP.Economy.SpawnStructure( ply, class, pos, ang )
	if not IsValid( ent ) then
		ply:SWGRP_AddCredits( data.price )
		SWGRP.Notify( ply, "Failed to deploy structure." )
		return
	end

	if class == "swgrp_letter" then
		ent:SetLetterText( "Write your message with /letter" )
		ent:SetAuthorName( ply:Nick() )
	end

	SWGRP.Notify( ply, string.format( "Deployed %s for %s.", data.name or class, SWGRP.FormatCredits( data.price ) ) )
	SWGRP.Hooks.Call( "SWGRPEntityPurchased", ply, data.name or class, data.price )
end

function SWGRP.Economy.BuyAmmo( ply, ammoName )
	local data = SWGRP.AmmoTypes[ammoName]
	if not data then return end

	if not SWGRP.PlayerTeamAllowedPurchase( ply, data.allowed ) then
		return
	end

	if not ply:SWGRP_TakeCredits( data.price ) then
		SWGRP.Notify( ply, SWGRP.Lang.cant_afford )
		return
	end

	ply:GiveAmmo( data.amountGiven, data.ammoType, true )
	SWGRP.Hooks.Call( "SWGRPEntityPurchased", ply, data.name or ammoName, data.price )
end

local function SWGRP_SchedulePayday()
	timer.Create( "SWGRP_Payday", SWGRP.Config.PaydayInterval:GetInt(), 1, function()
		SWGRP.Economy.Payday()
		SWGRP_SchedulePayday()
	end )
end

SWGRP_SchedulePayday()

hook.Add( "PlayerDeath", "SWGRP_DeathDrop", function( ply )
	if not ply:SWGRP_IsArrested() then
		local credits = math.floor( ply:SWGRP_GetCredits() * 0.1 )
		if credits > 0 then
			ply:SWGRP_TakeCredits( credits )
			local ent = ents.Create( "swgrp_dropped_credits" )
			if IsValid( ent ) then
				ent:SetPos( ply:GetPos() )
				ent:SetCredits( credits )
				ent:Spawn()
			end
		end
	end
end )

concommand.Add( "swgrp_givecredits", function( ply, cmd, args )
	if IsValid( ply ) and not ply:IsAdmin() then return end
	local target = SWGRP.FindPlayer( args[1] )
	local amount = tonumber( args[2] ) or 0
	if IsValid( target ) and amount > 0 then
		target:SWGRP_AddCredits( amount )
	end
end )
