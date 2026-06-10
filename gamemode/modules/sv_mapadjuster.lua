--[[---------------------------------------------------------------------------
    Map Atmosphere Adjuster - fog and ambient light per map
---------------------------------------------------------------------------]]

SWGRP = SWGRP or {}
SWGRP.MapAdjust = SWGRP.MapAdjust or {}

local MA = SWGRP.MapAdjust

MA.Defaults = {
	fogEnabled = true,
	fogStart = 0,
	fogEnd = 8000,
	fogColor = { r = 180, g = 200, b = 220 },
	ambientR = 40,
	ambientG = 40,
	ambientB = 50,
}

function MA.StorageKey()
	return "swgrp_mapadjust_" .. game.GetMap()
end

function MA.Get()
	return MA.Settings or table.Copy( MA.Defaults )
end

function MA.Save()
	if not SWGRP.DB or not SWGRP.DB.SetWorld then return end
	SWGRP.DB.SetWorld( MA.StorageKey(), util.TableToJSON( MA.Settings or MA.Defaults ) )
end

function MA.Load()
	MA.Settings = table.Copy( MA.Defaults )

	if not SWGRP.DB or not SWGRP.DB.GetWorld then return end

	local raw = SWGRP.DB.GetWorld( MA.StorageKey(), "" )
	if raw == "" then return end

	local parsed = SWGRP.DB.ParseJSON( raw )
	if istable( parsed ) then
		for k, v in pairs( parsed ) do
			MA.Settings[k] = v
		end
	end
end

function MA.Apply()
	local s = MA.Get()
	if s.fogColor and istable( s.fogColor ) then
		s.fogColor = Color( s.fogColor.r or 180, s.fogColor.g or 200, s.fogColor.b or 220 )
	else
		s.fogColor = Color( 180, 200, 220 )
	end

	if s.fogEnabled then
		render.FogMode( MATERIAL_FOG_LINEAR )
		render.FogStart( s.fogStart or 0 )
		render.FogEnd( s.fogEnd or 8000 )
		render.FogColor( s.fogColor.r, s.fogColor.g, s.fogColor.b )
		render.FogMaxDensity( 1 )
	else
		render.FogMode( MATERIAL_FOG_NONE )
	end
end

function MA.SyncTo( ply )
	if not IsValid( ply ) then return end

	local s = MA.Get()
	net.Start( "SWGRP_MapAdjustSync" )
		net.WriteBool( s.fogEnabled )
		net.WriteFloat( s.fogStart or 0 )
		net.WriteFloat( s.fogEnd or 8000 )
		net.WriteUInt( s.fogColor and s.fogColor.r or 180, 8 )
		net.WriteUInt( s.fogColor and s.fogColor.g or 200, 8 )
		net.WriteUInt( s.fogColor and s.fogColor.b or 220, 8 )
		net.WriteUInt( s.ambientR or 40, 8 )
		net.WriteUInt( s.ambientG or 40, 8 )
		net.WriteUInt( s.ambientB or 50, 8 )
	net.Send( ply )
end

function MA.OpenMenu( ply )
	if not IsValid( ply ) or not ply:IsAdmin() then return end

	net.Start( "SWGRP_MapAdjustMenu" )
	net.Send( ply )

	MA.SyncTo( ply )
end

function MA.SetField( ply, field, value )
	if not IsValid( ply ) or not ply:IsAdmin() then return end

	MA.Settings = MA.Settings or table.Copy( MA.Defaults )

	if field == "fogEnabled" then
		MA.Settings.fogEnabled = value and true or false
	elseif field == "fogStart" then
		MA.Settings.fogStart = math.Clamp( tonumber( value ) or 0, 0, 50000 )
	elseif field == "fogEnd" then
		MA.Settings.fogEnd = math.Clamp( tonumber( value ) or 8000, 100, 50000 )
	elseif field == "fogR" or field == "fogG" or field == "fogB" then
		MA.Settings.fogColor = MA.Settings.fogColor or { r = 180, g = 200, b = 220 }
		local ch = string.sub( field, 4 )
		MA.Settings.fogColor[ch] = math.Clamp( tonumber( value ) or 0, 0, 255 )
	elseif field == "ambientR" or field == "ambientG" or field == "ambientB" then
		MA.Settings[field] = math.Clamp( tonumber( value ) or 0, 0, 255 )
	elseif field == "reset" then
		MA.Settings = table.Copy( MA.Defaults )
	end

	MA.Save()
	MA.SyncToAll()
	SWGRP.Notify( ply, "Map atmosphere updated." )
end

function MA.SyncToAll()
	for _, p in ipairs( player.GetAll() ) do
		MA.SyncTo( p )
	end
end

function MA.AdminToolPrimary( ply )
	MA.OpenMenu( ply )
end

hook.Add( "SetupWorldFog", "SWGRP_MapAdjustFog", function()
	if MA.Settings then
		MA.Apply()
		return true
	end
end )

hook.Add( "InitPostEntity", "SWGRP_LoadMapAdjust", function()
	timer.Simple( 0, function()
		MA.Load()
		MA.SyncToAll()
	end )
end )

net.Receive( "SWGRP_MapAdjustAction", function( _, ply )
	if not IsValid( ply ) or not ply:IsAdmin() then return end

	local action = net.ReadString()
	if action == "set" then
		local field = net.ReadString()
		local value = net.ReadString()
		MA.SetField( ply, field, value )
	elseif action == "refresh" then
		MA.SyncTo( ply )
	end
end )
