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

function SWGRP.Economy.BuyShipment( ply, shipmentId, separate )
	local ship = SWGRP.Shipments[shipmentId]
	if not ship then return end

	if ship.allowed then
		local ok = false
		for _, t in ipairs( ship.allowed ) do
			if ply:Team() == t then ok = true break end
		end
		if not ok then return end
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

	local ent = ents.Create( "swgrp_shipment" )
	if not IsValid( ent ) then
		ply:SWGRP_AddCredits( price )
		return
	end
	ent:SetPos( ply:GetPos() + ply:GetForward() * 50 + Vector( 0, 0, 10 ) )
	ent:SetShipmentData( ship, separate )
	ent:Spawn()
	if ent.CPPISetOwner then ent:CPPISetOwner( ply ) end
	SWGRP.Hooks.Call( "SWGRPEntityPurchased", ply, ship.name .. ( separate and " (single)" or " crate" ), price )
end

function SWGRP.Economy.BuyEntity( ply, class )
	local data = SWGRP.Entities[class]
	if not data then return end

	if data.allowed then
		local ok = false
		for _, t in ipairs( data.allowed ) do
			if ply:Team() == t then ok = true break end
		end
		if not ok then return end
	end

	local count = 0
	for _, ent in ipairs( ents.FindByClass( class ) ) do
		if ent.SWGRP_Owner == ply then count = count + 1 end
	end
	if data.max and count >= data.max then
		SWGRP.Notify( ply, "Maximum entity limit reached." )
		return
	end

	if not ply:SWGRP_TakeCredits( data.price ) then
		SWGRP.Notify( ply, SWGRP.Lang.cant_afford )
		return
	end

	local ent = ents.Create( class )
	if not IsValid( ent ) then
		ply:SWGRP_AddCredits( data.price )
		SWGRP.Notify( ply, "Failed to deploy structure." )
		return
	end
	ent:SetPos( ply:GetPos() + ply:GetForward() * 50 + Vector( 0, 0, 10 ) )
	ent:Spawn()
	ent.SWGRP_Owner = ply
	if class == "swgrp_letter" then
		ent:SetLetterText( "Write your message with /letter" )
		ent:SetAuthorName( ply:Nick() )
	end
	if ent.CPPISetOwner then ent:CPPISetOwner( ply ) end
	SWGRP.Hooks.Call( "SWGRPEntityPurchased", ply, data.name or class, data.price )
end

function SWGRP.Economy.BuyAmmo( ply, ammoName )
	local data = SWGRP.AmmoTypes[ammoName]
	if not data then return end

	if data.allowed then
		local ok = false
		for _, t in ipairs( data.allowed ) do
			if ply:Team() == t then ok = true break end
		end
		if not ok then return end
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
