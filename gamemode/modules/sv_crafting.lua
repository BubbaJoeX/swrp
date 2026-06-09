--[[---------------------------------------------------------------------------
    Crafting System
---------------------------------------------------------------------------]]

SWGRP = SWGRP or {}
SWGRP.Crafting = SWGRP.Crafting or {}

function SWGRP.Crafting.CanCraft( ply, recipeId )
	local recipe = SWGRP.Recipes[recipeId]
	if not recipe then return false, "Unknown recipe." end

	if recipe.allowed then
		local ok = false
		for _, t in ipairs( recipe.allowed ) do
			if ply:Team() == t then ok = true break end
		end
		if not ok then return false, "Wrong profession." end
	end

	if recipe.materials and not SWGRP.Materials.Has( ply, recipe.materials ) then
		return false, "Insufficient materials."
	end

	return true
end

function SWGRP.Crafting.Craft( ply, recipeId )
	local can, reason = SWGRP.Crafting.CanCraft( ply, recipeId )
	if not can then
		SWGRP.Notify( ply, reason )
		return false
	end

	local recipe = SWGRP.Recipes[recipeId]
	if recipe.materials then
		SWGRP.Materials.Take( ply, recipe.materials )
	end

	if recipe.credits and recipe.credits > 0 then
		ply:SWGRP_AddCredits( recipe.credits )
	end

	if recipe.giveAmmo then
		ply:GiveAmmo( recipe.giveAmmo.amount, recipe.giveAmmo.type, true )
	end

	if recipe.heal then
		ply:SetHealth( math.min( ply:GetMaxHealth(), ply:Health() + recipe.heal ) )
	end

	if recipe.giveHunger then
		SWGRP.Hunger.Add( ply, recipe.giveHunger )
	end

	if recipe.xp then
		SWGRP.Profession.AddXP( ply, recipe.xp )
	end

	SWGRP.Notify( ply, "Crafted: " .. recipe.name )
	SWGRP.Hooks.Call( "SWGRPCraftedItem", ply, recipe )
	return true
end

function SWGRP.Crafting.ListFor( ply )
	local list = {}
	for id, recipe in pairs( SWGRP.Recipes ) do
		local can = SWGRP.Crafting.CanCraft( ply, id )
		if can or ( recipe.allowed == nil ) then
			table.insert( list, { id = id, recipe = recipe, can = can } )
		end
	end
	return list
end
