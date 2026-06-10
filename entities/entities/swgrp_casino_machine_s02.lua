AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "swgrp_casino_machine_s01"
ENT.PrintName = "Casino Machine (Neon)"
ENT.Category = "SWGRP"
ENT.Spawnable = false

ENT.DefaultModel = "models/props/starwars/tech/imp_datapad.mdl"
ENT.Theme = "neon"
ENT.SpinSound = "buttons/button17.wav"
ENT.WinSound = "ambient/levels/labs/electric_explosion1.wav"

if CLIENT then
	function ENT:Draw()
		self:DrawModel()
		local label = self:GetSpinning() and "SPINNING..." or "NEON SLOTS - Press E"
		if SWGRP.UI and SWGRP.UI.DrawWorldLabel then
			SWGRP.UI.DrawWorldLabel( self, label, "High stakes gambling", Color( 120, 255, 200 ) )
		end
	end
end
