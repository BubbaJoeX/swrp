--[[---------------------------------------------------------------------------
    F1 MOTD - Galactic Information Terminal
---------------------------------------------------------------------------]]

local UI = SWGRP.UI

function SWGRP.OpenMOTD()
	if IsValid( SWGRP.MOTDFrame ) then
		SWGRP.MOTDFrame:Remove()
	end

	local scrW, scrH = ScrW(), ScrH()
	local frame = UI.CreateTerminalFrame( "GALACTIC INFORMATION NETWORK", scrW * 0.5, scrH * 0.6 )
	SWGRP.MOTDFrame = frame

	local html = vgui.Create( "DHTML", frame )
	html:Dock( FILL )
	html:DockMargin( UI.Spacing.frame, 40, UI.Spacing.frame, UI.Spacing.frame )
	html:SetHTML( [[
		<html><body style="background:#0a0f19;color:#c8c8c8;font-family:Arial,sans-serif;padding:20px;">
		<h1 style="color:#ffb432;">Star Wars Galaxies Roleplay</h1>
		<p>Welcome to the Outer Rim. Choose your profession, build your story, and survive Imperial law.</p>
		<h2 style="color:#ffb432;">Controls</h2>
		<ul>
			<li><b>F1</b> - This information terminal</li>
			<li><b>F4</b> - Profession & commerce terminal</li>
			<li><b>F3</b> - Colony datapad (missions, crafting, status, banking)</li>
			<li><b>F2</b> - Manage / buy the door you are looking at</li>
			<li><b>T</b> - Pocket inventory</li>
			<li><b>Alt + T</b> - Quick-pocket (aimed item or active weapon)</li>
		</ul>
		<h2 style="color:#ffb432;">Chat Commands</h2>
		<ul>
			<li><b>/ooc</b> - Out of character chat</li>
			<li><b>/me</b> - Roleplay action</li>
			<li><b>/advert</b> - Galactic advertisement</li>
			<li><b>/pm [name] [msg]</b> - Private message</li>
			<li><b>/yell</b> - Yell to nearby players</li>
			<li><b>/whisper</b> - Whisper to nearby players</li>
			<li><b>/dropcredits [amount]</b> - Drop credits</li>
			<li><b>/wanted [name] [reason]</b> - Mark wanted (Imperial Security)</li>
			<li><b>/warrant [name] [reason]</b> - Search warrant</li>
			<li><b>/hit [name] [price]</b> - Place bounty contract</li>
			<li><b>/demote [name]</b> - Vote to demote</li>
			<li><b>/lockdown</b> - Governor lockdown</li>
			<li><b>/give [amount]</b> - Hand credits to the player you look at</li>
			<li><b>/pocket</b> - Store aimed equipment or active weapon</li>
			<li><b>/droppocket</b> - Open pocket menu</li>
			<li><b>/whitelist [name] [job]</b> - Whitelist a player (admin)</li>
		</ul>
		<h2 style="color:#ffb432;">Door Commands</h2>
		<ul>
			<li><b>swgrp_buydoor</b> - Purchase structure door</li>
			<li><b>swgrp_selldoor</b> - Sell structure door</li>
			<li><b>swgrp_toggledoor</b> - Lock/unlock owned door</li>
		</ul>
		<h2 style="color:#ffb432;">New Systems</h2>
		<ul>
			<li><b>Banking</b> — /deposit, /withdraw, /balance, /transfer</li>
			<li><b>Missions</b> — F3 Missions tab or Mission Terminal entity</li>
			<li><b>Crafting</b> — F3 Crafting tab, gather materials, /craft [id]</li>
			<li><b>Factions</b> — Imperial, Rebel, Underworld standing</li>
			<li><b>Hunger</b> — Eat rations, visit cantinas, /eat</li>
			<li><b>Contraband</b> — /contraband (smugglers), /scan (Imperial)</li>
			<li><b>Vehicles</b> — F4 Vehicles tab</li>
			<li><b>Profession XP</b> — Level up by working, missions, crafting</li>
			<li><b>Pocket</b> — Carry items discreetly (<b>T</b>, <b>Alt+T</b>, /pocket, /droppocket)</li>
			<li><b>Keypads</b> — Buy a Security Keypad to control a door; underworld jobs carry a Keypad Cracker</li>
			<li><b>Disguise</b> — Smugglers use a Disguise Kit to conceal identity</li>
			<li><b>New Life Rule</b> — Stay away from your death location after respawning</li>
			<li><b>Adverts</b> — /advert shows an on-screen banner to everyone</li>
		</ul>
		<h2 style="color:#ffb432;">Professions</h2>
		<p>SWG-inspired professions: Colonist, Smuggler, Bounty Hunter, Stormtrooper, Governor, and more.</p>
		<p style="color:#50c8ff;">May the Force be with you.</p>
		</body></html>
	]] )
end

function GM:ShowHelp()
	SWGRP.OpenMOTD()
end
