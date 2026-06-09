--[[---------------------------------------------------------------------------
    Galactic Banking System
---------------------------------------------------------------------------]]

SWGRP = SWGRP or {}
SWGRP.Banking = SWGRP.Banking or {}

function SWGRP.Banking.GetBalance( ply )
	return ply.SWGRP_BankBalance or 0
end

function SWGRP.Banking.Deposit( ply, amount )
	amount = math.floor( amount )
	if amount <= 0 then return false end

	-- Only deposit what actually fits, so credits over the cap are never destroyed.
	local space = SWGRP.Config.MaxBankBalance - ( ply.SWGRP_BankBalance or 0 )
	if space <= 0 then
		SWGRP.Notify( ply, "Your bank account is full." )
		return false
	end
	amount = math.min( amount, space )

	if not ply:SWGRP_TakeCredits( amount ) then
		SWGRP.Notify( ply, SWGRP.Lang.cant_afford )
		return false
	end

	ply.SWGRP_BankBalance = math.min( SWGRP.Config.MaxBankBalance, ( ply.SWGRP_BankBalance or 0 ) + amount )
	ply:SetNWInt( "SWGRP_Bank", ply.SWGRP_BankBalance )
	SWGRP.Notify( ply, "Deposited " .. SWGRP.FormatCredits( amount ) .. ". Balance: " .. SWGRP.FormatCredits( ply.SWGRP_BankBalance ) )
	SWGRP.Hooks.Call( "SWGRPPlayerDeposited", ply, amount )
	SWGRP.Persistence.ScheduleSave( ply )
	return true
end

function SWGRP.Banking.Withdraw( ply, amount )
	amount = math.floor( amount )
	if amount <= 0 then return false end
	if ( ply.SWGRP_BankBalance or 0 ) < amount then
		SWGRP.Notify( ply, "Insufficient bank balance." )
		return false
	end

	ply.SWGRP_BankBalance = ply.SWGRP_BankBalance - amount
	ply:SetNWInt( "SWGRP_Bank", ply.SWGRP_BankBalance )
	ply:SWGRP_AddCredits( amount )
	SWGRP.Notify( ply, "Withdrew " .. SWGRP.FormatCredits( amount ) )
	SWGRP.Hooks.Call( "SWGRPPlayerWithdrew", ply, amount )
	SWGRP.Persistence.ScheduleSave( ply )
	return true
end

function SWGRP.Banking.Transfer( from, toName, amount )
	amount = math.floor( amount )
	if amount <= 0 then return false end

	local to = SWGRP.FindPlayer( toName )
	if not IsValid( to ) then
		SWGRP.Notify( from, "Player not found." )
		return false
	end
	if to == from then return false end

	local fee = math.floor( amount * SWGRP.Config.BankTransferFee )
	local total = amount + fee
	if ( from.SWGRP_BankBalance or 0 ) < total then
		SWGRP.Notify( from, "Insufficient bank balance (includes " .. SWGRP.FormatCredits( fee ) .. " fee)." )
		return false
	end

	-- Don't let a transfer push the recipient over the bank cap.
	if ( to.SWGRP_BankBalance or 0 ) + amount > SWGRP.Config.MaxBankBalance then
		SWGRP.Notify( from, "Recipient's bank account cannot hold that much." )
		return false
	end

	from.SWGRP_BankBalance = from.SWGRP_BankBalance - total
	from:SetNWInt( "SWGRP_Bank", from.SWGRP_BankBalance )
	to.SWGRP_BankBalance = ( to.SWGRP_BankBalance or 0 ) + amount
	to:SetNWInt( "SWGRP_Bank", to.SWGRP_BankBalance )

	SWGRP.Notify( from, "Transferred " .. SWGRP.FormatCredits( amount ) .. " to " .. to:Nick() )
	SWGRP.Notify( to, "Received " .. SWGRP.FormatCredits( amount ) .. " from " .. from:Nick() )
	SWGRP.Persistence.ScheduleSave( from )
	SWGRP.Persistence.ScheduleSave( to )
	return true
end
