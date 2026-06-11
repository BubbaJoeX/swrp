FAdmin.ScoreBoard.Player.Information = {}
FAdmin.ScoreBoard.Player.ActionButtons = {}

local QUICK_STATS = {
	Name = true,
	Kills = true,
	Deaths = true,
	Health = true,
	Ping = true,
}

function FAdmin.ScoreBoard.Player.Show(ply)
	ply = ply or FAdmin.ScoreBoard.Player.Player
	FAdmin.ScoreBoard.Player.Player = ply

	if not IsValid(ply) or not IsValid(FAdmin.ScoreBoard.Player.Player) then
		FAdmin.ScoreBoard.ChangeView("Main")
		return
	end

	local UI = SWGRP.UI
	local L = UI and UI.ScoreboardLayout or {}
	local bx, by, bw, bh = FAdmin.ScoreBoard.X, FAdmin.ScoreBoard.Y, FAdmin.ScoreBoard.Width, FAdmin.ScoreBoard.Height
	local margin = L.margin or 24
	local gap = L.sectionGap or 12
	local pad = L.panelPad or 14
	local leftW = L.playerLeftW or 212
	local avatarSize = L.playerAvatar or 136

	local bodyY = UI and UI.ScoreboardBodyY(by) or (by + 120)
	local bodyX = bx + margin
	local contentW = bw - margin * 2
	local contentH = bh - (bodyY - by) - margin
	if UI and UI.ScoreboardContentRect then
		bodyX, bodyY, contentW, contentH = UI.ScoreboardContentRect(bx, by, bw, bh)
	end

	local profileH = math.min(contentH * 0.42, avatarSize + gap + 130)
	local actionsTop = bodyY + profileH + gap
	local actionsH = bodyY + contentH - actionsTop

	local infoW = contentW - leftW - gap

	-- Avatar column
	local avatarPanel = FAdmin.ScoreBoard.Player.Controls.AvatarPanel or vgui.Create("DPanel")
	FAdmin.ScoreBoard.Player.Controls.AvatarPanel = avatarPanel
	avatarPanel:SetPos(bodyX, bodyY)
	avatarPanel:SetSize(leftW, profileH)
	avatarPanel.Paint = UI and UI.PaintTerminalPanel or function() end
	avatarPanel:SetVisible(true)

	FAdmin.ScoreBoard.Player.Controls.AvatarBackground = FAdmin.ScoreBoard.Player.Controls.AvatarBackground or vgui.Create("AvatarImage", avatarPanel)
	FAdmin.ScoreBoard.Player.Controls.AvatarBackground:SetPlayer(ply, avatarSize)
	FAdmin.ScoreBoard.Player.Controls.AvatarBackground:SetSize(avatarSize, avatarSize)
	FAdmin.ScoreBoard.Player.Controls.AvatarBackground:SetPos(pad, pad)
	FAdmin.ScoreBoard.Player.Controls.AvatarBackground:SetVisible(true)

	local statsPanel = FAdmin.ScoreBoard.Player.Controls.InfoPanel1 or vgui.Create("DPanel", avatarPanel)
	statsPanel:SetParent(avatarPanel)
	statsPanel:SetPos(pad, pad + avatarSize + gap)
	statsPanel:SetSize(leftW - pad * 2, profileH - avatarSize - gap - pad)
	statsPanel.Paint = function(s, w, h)
		if not UI then return end
		UI.SyncColors()
		surface.SetDrawColor(UI.Colors.bgLight)
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(UI.Colors.borderDim)
		surface.DrawOutlinedRect(0, 0, w, h, 1)
	end
	FAdmin.ScoreBoard.Player.Controls.InfoPanel1 = statsPanel

	local statsLayout = FAdmin.ScoreBoard.Player.Controls.StatsLayout
	if not IsValid(statsLayout) then
		statsLayout = vgui.Create("DListLayout", statsPanel)
		statsLayout:Dock(FILL)
		statsLayout:DockPadding(10, 8, 10, 8)
		FAdmin.ScoreBoard.Player.Controls.StatsLayout = statsLayout
	else
		for _, child in ipairs(statsLayout:GetChildren()) do
			child:Remove()
		end
	end

	-- Detail column
	local detailPanel = FAdmin.ScoreBoard.Player.Controls.DetailPanel or vgui.Create("DPanel")
	FAdmin.ScoreBoard.Player.Controls.DetailPanel = detailPanel
	detailPanel:SetPos(bodyX + leftW + gap, bodyY)
	detailPanel:SetSize(infoW, profileH)
	detailPanel.Paint = UI and UI.PaintTerminalPanel or function() end
	detailPanel:SetVisible(true)

	if IsValid(FAdmin.ScoreBoard.Player.Controls.InfoPanel2) then
		FAdmin.ScoreBoard.Player.Controls.InfoPanel2:Remove()
	end

	local detailScroll = vgui.Create("DScrollPanel", detailPanel)
	detailScroll:Dock(FILL)
	detailScroll:DockMargin(pad, pad, pad, pad)
	if UI and UI.StyleScrollPanel then UI.StyleScrollPanel(detailScroll) end
	FAdmin.ScoreBoard.Player.Controls.InfoPanel2 = detailScroll

	local detailInner = vgui.Create("DPanel", detailScroll)
	detailInner:Dock(TOP)
	detailInner.Paint = function() end

	FAdmin.ScoreBoard.Player.InfoPanels = FAdmin.ScoreBoard.Player.InfoPanels or {}
	for k, v in pairs(FAdmin.ScoreBoard.Player.InfoPanels) do
		if IsValid(v) then
			v:Remove()
			FAdmin.ScoreBoard.Player.InfoPanels[k] = nil
		end
	end

	for _, v in pairs(FAdmin.ScoreBoard.Player.Information) do
		local Value = v.func(FAdmin.ScoreBoard.Player.Player)
		if not Value or Value == "" then continue end

		local parent = QUICK_STATS[v.name] and statsLayout or detailInner
		local accent = v.name == "Profession" or v.name == "Credits" or v.name == "Bank"
		local row, valLabel = UI.AddScoreboardInfoRow(parent, v.name, Value, {
			accent = accent,
			tooltip = "Click to copy " .. v.name,
			onClick = function()
				SetClipboardText(Value)
			end,
		})

		timer.Create("FAdmin_Scoreboard_text_update_" .. v.name, 1, 0, function()
			if not IsValid(ply) or not IsValid(FAdmin.ScoreBoard.Player.Player) or not IsValid(valLabel) then
				timer.Remove("FAdmin_Scoreboard_text_update_" .. v.name)
				if FAdmin.ScoreBoard.Visible and (not IsValid(ply) or not IsValid(FAdmin.ScoreBoard.Player.Player)) then
					FAdmin.ScoreBoard.ChangeView("Main")
				end
				return
			end
			local newVal = v.func(FAdmin.ScoreBoard.Player.Player)
			if not newVal or newVal == "" then newVal = "N/A" end
			valLabel:SetText(newVal)
		end)

		table.insert(FAdmin.ScoreBoard.Player.InfoPanels, row)
	end

	detailInner:SizeToChildren(false, true)
	detailScroll:InvalidateLayout(true)

	local CatColor = team.GetColor(ply:Team())
	CatColor = hook.Run("FAdmin_PlayerRowColour", ply, CatColor) or CatColor

	FAdmin.ScoreBoard.Player.Controls.ButtonCat = FAdmin.ScoreBoard.Player.Controls.ButtonCat or vgui.Create("FAdminPlayerCatagory")
	FAdmin.ScoreBoard.Player.Controls.ButtonCat:SetLabel("  PLAYER ACTIONS")
	FAdmin.ScoreBoard.Player.Controls.ButtonCat.CatagoryColor = CatColor
	FAdmin.ScoreBoard.Player.Controls.ButtonCat:SetSize(contentW, actionsH)
	FAdmin.ScoreBoard.Player.Controls.ButtonCat:SetPos(bodyX, actionsTop)
	FAdmin.ScoreBoard.Player.Controls.ButtonCat:SetVisible(true)
	function FAdmin.ScoreBoard.Player.Controls.ButtonCat:Toggle() end

	FAdmin.ScoreBoard.Player.Controls.ButtonPanel = FAdmin.ScoreBoard.Player.Controls.ButtonPanel or vgui.Create("FAdminPanelList", FAdmin.ScoreBoard.Player.Controls.ButtonCat)
	FAdmin.ScoreBoard.Player.Controls.ButtonPanel:SetSpacing(L.actionGap or 8)
	FAdmin.ScoreBoard.Player.Controls.ButtonPanel:EnableHorizontal(true)
	FAdmin.ScoreBoard.Player.Controls.ButtonPanel:EnableVerticalScrollbar(true)
	FAdmin.ScoreBoard.Player.Controls.ButtonPanel:SetVisible(true)
	FAdmin.ScoreBoard.Player.Controls.ButtonPanel:Clear()
	FAdmin.ScoreBoard.Player.Controls.ButtonPanel:DockMargin(pad, pad, pad, pad)
	if UI and UI.StylePanelList then UI.StylePanelList(FAdmin.ScoreBoard.Player.Controls.ButtonPanel) end

	for _, v in ipairs(FAdmin.ScoreBoard.Player.ActionButtons) do
		if v.Visible == true or (isfunction(v.Visible) and v.Visible(FAdmin.ScoreBoard.Player.Player) == true) then
			local ActionButton = vgui.Create("FAdminActionButton")
			local imageType = TypeID(v.Image)
			if imageType == TYPE_STRING then
				ActionButton:SetImage(v.Image or "icon16/exclamation")
			elseif imageType == TYPE_TABLE then
				ActionButton:SetImage(v.Image[1])
				if v.Image[2] then ActionButton:SetImage2(v.Image[2]) end
			elseif imageType == TYPE_FUNCTION then
				local img1, img2 = v.Image(ply)
				ActionButton:SetImage(img1)
				if img2 then ActionButton:SetImage2(img2) end
			else
				ActionButton:SetImage("icon16/exclamation")
			end

			local name = v.Name
			if isfunction(name) then name = name(FAdmin.ScoreBoard.Player.Player) end
			ActionButton:SetText(DarkRP.deLocalise(name))
			ActionButton:SetBorderColor(v.color)
			ActionButton:DockMargin(0, 0, L.actionGap or 8, L.actionGap or 8)

			function ActionButton:DoClick()
				if not IsValid(FAdmin.ScoreBoard.Player.Player) then return end
				return v.Action(FAdmin.ScoreBoard.Player.Player, self)
			end

			FAdmin.ScoreBoard.Player.Controls.ButtonPanel:AddItem(ActionButton)
			if v.OnButtonCreated then
				v.OnButtonCreated(FAdmin.ScoreBoard.Player.Player, ActionButton)
			end
		end
	end

	FAdmin.ScoreBoard.Player.Controls.ButtonPanel:Dock(TOP)
end

function FAdmin.ScoreBoard.Player:AddInformation(name, func, ForceNewPanel)
	table.insert(FAdmin.ScoreBoard.Player.Information, {name = name, func = func, NewPanel = ForceNewPanel})
end

function FAdmin.ScoreBoard.Player:AddActionButton(Name, Image, color, Visible, Action, OnButtonCreated)
	table.insert(FAdmin.ScoreBoard.Player.ActionButtons, {Name = Name, Image = Image, color = color, Visible = Visible, Action = Action, OnButtonCreated = OnButtonCreated})
end

FAdmin.ScoreBoard.Player:AddInformation("Name", function(ply) return ply:Nick() end)
FAdmin.ScoreBoard.Player:AddInformation("Kills", function(ply) return ply:Frags() end)
FAdmin.ScoreBoard.Player:AddInformation("Deaths", function(ply) return ply:Deaths() end)
FAdmin.ScoreBoard.Player:AddInformation("Health", function(ply) return ply:Health() end)
FAdmin.ScoreBoard.Player:AddInformation("Ping", function(ply) return ply:Ping() end)
FAdmin.ScoreBoard.Player:AddInformation("SteamID", function(ply) return ply:SteamID() end, true)
