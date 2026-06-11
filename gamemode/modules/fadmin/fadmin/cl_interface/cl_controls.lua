FAdmin.PlayerIcon = {}
FAdmin.PlayerIcon.RightClickOptions = {}

function FAdmin.PlayerIcon.AddRightClickOption(name, func)
    FAdmin.PlayerIcon.RightClickOptions[name] = func
end

-- FAdminPanelList
local PANEL = {}

function PANEL:Init()
    self.Padding = 5
end

function PANEL:SizeToContents()
    local w, h = self:GetSize()

    -- Fix size of w to have the same size as the scoreboard
    w = math.Clamp(w, ScrW() * 0.9, ScrW() * 0.9)
    h = math.Min(h, ScrH() * 0.95)

    -- It fucks up when there's only one icon in
    if #self:GetChildren() == 1 then
        h = math.Max(0, 120)
    end

    self:SetSize(w, h)
    self:PerformLayout()
end

function PANEL:Paint( w, h )
    local UI = SWGRP.UI
    if UI and UI.PaintTerminalPanel then
        UI.PaintTerminalPanel( self, w, h )
    end
end

derma.DefineControl("FAdminPanelList", "DPanellist adapted for FAdmin", PANEL, "DPanelList")

-- FAdminPlayerCatagoryHeader
local PANEL2 = {}

function PANEL2:PerformLayout()
    self:SetFont("SWGRP_ScoreboardSubtitle")
    local UI = SWGRP.UI
    if UI then
        UI.SyncColors()
        self:SetTextColor( UI.Colors.primary )
    end
    self:DockMargin( 4, 4, 4, 2 )
    self:SetTall( 28 )
end

derma.DefineControl("FAdminPlayerCatagoryHeader", "DCatagoryCollapse header adapted for FAdmin", PANEL2, "DCategoryHeader")

-- FAdminPlayerCatagory
local PANEL3 = {}

function PANEL3:Init()
    if self.Header then
        self.Header:Remove() -- the old header is still there don't ask me why
    end
    self.Header = vgui.Create("FAdminPlayerCatagoryHeader", self)
    self.Header:SetSize(20, 25)
    self:SetPadding(5)
    self.Header:Dock(TOP)

    self:SetExpanded(true)
    self:SetMouseInputEnabled(true)

    self:SetAnimTime(0.2)
    self.animSlide = Derma_Anim("Anim", self, self.AnimSlide)

    self:SetPaintBackgroundEnabled(true)

end

function PANEL3:Paint()
    local UI = SWGRP.UI
    if not self.CatagoryColor then return end
    local col = self.CatagoryColor
    if UI then
        surface.SetDrawColor( col.r, col.g, col.b, 140 )
    else
        surface.SetDrawColor( col )
    end
    surface.DrawRect( 0, 0, self:GetWide(), self.Header:GetTall() )
    if UI then
        surface.SetDrawColor( UI.Colors.borderDim )
        surface.DrawOutlinedRect( 0, 0, self:GetWide(), self.Header:GetTall(), 1 )
    end
end

derma.DefineControl("FAdminPlayerCatagory", "DCatagoryCollapse adapted for FAdmin", PANEL3, "DCollapsibleCategory")

-- FAdmin player row (from the sandbox player row)
PANEL = {}

local PlayerRowSize = CreateClientConVar("FAdmin_PlayerRowSize", 44, true, false)
function PANEL:Init()
    local UI = SWGRP.UI
    local minRow = UI and UI.ScoreboardLayout and UI.ScoreboardLayout.rowHeight or 44
    self.Size = math.max(PlayerRowSize:GetInt(), minRow)

    self.lblName   = vgui.Create("DLabel", self)
    self.lblFrags  = vgui.Create("DLabel", self)
    self.lblTeam   = vgui.Create("DLabel", self)
    self.lblDeaths = vgui.Create("DLabel", self)
    self.lblPing   = vgui.Create("DLabel", self)
    self.lblWanted = vgui.Create("DLabel", self)

    -- If you don't do this it'll block your clicks
    self.lblName:SetMouseInputEnabled(false)
    self.lblTeam:SetMouseInputEnabled(false)
    self.lblFrags:SetMouseInputEnabled(false)
    self.lblDeaths:SetMouseInputEnabled(false)
    self.lblPing:SetMouseInputEnabled(false)
    self.lblWanted:SetMouseInputEnabled(false)

    if UI then UI.RegisterFonts() end
    local pri = UI and UI.Colors.primary or Color(255, 180, 50)
    local sec = UI and UI.Colors.secondary or Color(200, 200, 200)
    local acc = UI and UI.Colors.accent or Color(80, 200, 255)
    local dan = UI and UI.Colors.danger or Color(255, 60, 60)

    self.lblName:SetColor(pri)
    self.lblTeam:SetColor(acc)
    self.lblFrags:SetColor(sec)
    self.lblDeaths:SetColor(sec)
    self.lblPing:SetColor(sec)
    self.lblWanted:SetColor(dan)

    self.imgAvatar = vgui.Create("AvatarImage", self)

    self:SetCursor("hand")
end

function PANEL:Paint()
    if not IsValid(self.Player) then return end

    local UI = SWGRP.UI
    local minRow = UI and UI.ScoreboardLayout and UI.ScoreboardLayout.rowHeight or 44
    self.Size = math.max(PlayerRowSize:GetInt(), minRow)
    local pad = 6
    local avatarSize = math.min(self.Size - pad * 2, 36)
    self.imgAvatar:SetSize(avatarSize, avatarSize)

    local w, rowH = self:GetWide(), self.Size
    local teamCol = team.GetColor(self.Player:Team())

    if self.Player.SWGRP_IsWanted and self.Player:SWGRP_IsWanted() then
        teamCol = UI and UI.Colors.danger or Color(255, 60, 60)
    elseif self.Player.SWGRP_IsAFK and self.Player:SWGRP_IsAFK() then
        teamCol = Color(100, 100, 100)
    end

    local hooks = hook.GetTable().FAdmin_PlayerRowColour
    if hooks then
        for _, v in pairs(hooks) do
            teamCol = (v and v(self.Player, teamCol)) or teamCol
            break
        end
    end

    if UI then
        UI.SyncColors()
        local inset = 4
        surface.SetDrawColor(UI.Colors.bgLight)
        surface.DrawRect(inset, inset, w - inset * 2, rowH - inset * 2)
        surface.SetDrawColor(teamCol.r, teamCol.g, teamCol.b, 90)
        surface.DrawRect(w - inset - 6, inset, 5, rowH - inset * 2)
        if self.Player == LocalPlayer() then
            surface.SetDrawColor(UI.Colors.borderDim)
            surface.DrawOutlinedRect(inset, inset, w - inset * 2, rowH - inset * 2, 1)
        end
        if self.Hovered then
            surface.SetDrawColor(UI.Colors.primary.r, UI.Colors.primary.g, UI.Colors.primary.b, 18)
            surface.DrawRect(inset, inset, w - inset * 2, rowH - inset * 2)
        end
    else
        draw.RoundedBox(4, 0, 0, w, rowH, teamCol)
    end

    return true
end

function PANEL:SetPlayer(ply)
    self.Player = ply

    self.imgAvatar:SetPlayer(ply)

    self:UpdatePlayerData()
end

function PANEL:UpdatePlayerData()
    if not self.Player then return end
    if not self.Player:IsValid() then return end

    self.lblName:SetText(DarkRP.deLocalise(self.Player:Nick()))
    local jobText = (self.Player.SWGRP_GetJobName and self.Player:SWGRP_GetJobName())
        or (self.Player.DarkRPVars and DarkRP.deLocalise(self.Player:getDarkRPVar("job") or ""))
        or team.GetName(self.Player:Team())
    self.lblTeam:SetText(jobText)
    self.lblTeam:SizeToContents()
    self.lblFrags:SetText(self.Player:Frags())
    self.lblDeaths:SetText(self.Player:Deaths())
    self.lblPing:SetText(self.Player:Ping())
    self.lblWanted:SetText(self.Player:isWanted() and DarkRP.getPhrase("Wanted_text") or "")
end

function PANEL:ApplySchemeSettings()
    self.lblName:SetFont("SWGRP_ScoreboardRow")
    self.lblTeam:SetFont("SWGRP_ScoreboardRowSmall")
    self.lblFrags:SetFont("SWGRP_ScoreboardRowSmall")
    self.lblDeaths:SetFont("SWGRP_ScoreboardRowSmall")
    self.lblPing:SetFont("SWGRP_ScoreboardRowSmall")
    self.lblWanted:SetFont("SWGRP_ScoreboardRow")
end

function PANEL:DoClick(x, y)
    if not IsValid(self.Player) then self:Remove() return end
    FAdmin.ScoreBoard.ChangeView("Player", self.Player)
end

function PANEL:DoRightClick()
    if table.IsEmpty(FAdmin.PlayerIcon.RightClickOptions) then return end
    local menu = DermaMenu()

    menu:SetPos(gui.MouseX(), gui.MouseY())

    for Name, func in SortedPairs(FAdmin.PlayerIcon.RightClickOptions) do
        menu:AddOption(Name, function() if IsValid(self.Player) then func(self.Player, self) end end)
    end

    menu:Open()
end

function PANEL:Think()
    if not self.PlayerUpdate or self.PlayerUpdate < CurTime() then
        self.PlayerUpdate = CurTime() + 0.5
        self:UpdatePlayerData()
    end
end

function PANEL:PerformLayout()
    local UI = SWGRP.UI
    local minRow = UI and UI.ScoreboardLayout and UI.ScoreboardLayout.rowHeight or 44
    self.Size = math.max(PlayerRowSize:GetInt(), minRow)
    local pad = 6
    local rowH = self.Size
    local avatarSize = math.min(rowH - pad * 2, 36)

    self.imgAvatar:SetPos(pad, (rowH - avatarSize) / 2)
    self.imgAvatar:SetSize(avatarSize, avatarSize)
    self:SetSize(self:GetWide(), rowH)

    local cy = rowH / 2
    self.lblName:SizeToContents()
    self.lblName:SetPos(pad + avatarSize + 10, cy - self.lblName:GetTall() / 2)

    local COLUMN_SIZE = 75
    local rightInset = 12

    self.lblPing:SizeToContents()
    self.lblPing:SetPos(self:GetWide() - rightInset - self.lblPing:GetWide(), cy - self.lblPing:GetTall() / 2)
    self.lblDeaths:SizeToContents()
    self.lblDeaths:SetPos(self:GetWide() - COLUMN_SIZE * 1.4, cy - self.lblDeaths:GetTall() / 2)
    self.lblFrags:SizeToContents()
    self.lblFrags:SetPos(self:GetWide() - COLUMN_SIZE * 2.4, cy - self.lblFrags:GetTall() / 2)

    self.lblTeam:SizeToContents()
    self.lblTeam:SetPos(self:GetWide() / 2 - self.lblTeam:GetWide() / 2, cy - self.lblTeam:GetTall() / 2)

    self.lblWanted:SizeToContents()
    self.lblWanted:SetPos(math.floor(self:GetWide() / 4), cy - self.lblWanted:GetTall() / 2)
end
vgui.Register("FadminPlayerRow", PANEL, "Button")

-- FAdminActionButton
local PANEL6 = {}

function PANEL6:Init()
    local UI = SWGRP.UI
    local L = UI and UI.ScoreboardLayout
    local btnH = L and L.actionBtnH or 42
    local minW = L and L.actionBtnMinW or 140

    self:SetDrawBackground(false)
    self:SetDrawBorder(false)
    self:SetStretchToFit(false)
    self:SetSize(minW, btnH)

    self.TextLabel = vgui.Create("DLabel", self)
    local sec = UI and UI.Colors.secondary or Color(200, 200, 200)
    self.TextLabel:SetColor(sec)
    self.TextLabel:SetFont("SWGRP_ScoreboardRowSmall")

    self.m_Image2 = vgui.Create("DImage", self)

    self.BorderColor = Color(190,40,0,255)
end

function PANEL6:SetImage(img, backup)
    if SWGRP.Assets and SWGRP.Assets.ResolveIconPath then
        img = SWGRP.Assets.ResolveIconPath(img)
    end
    DImageButton.SetImage(self, img, backup)
end

function PANEL6:SetImage2(Mat, bckp)
    if SWGRP.Assets and SWGRP.Assets.ResolveIconPath then
        Mat = SWGRP.Assets.ResolveIconPath(Mat)
    end
    self.m_Image2:SetImage(Mat, bckp)
end

function PANEL6:SetText(text)
    local UI = SWGRP.UI
    local L = UI and UI.ScoreboardLayout
    local minW = L and L.actionBtnMinW or 140
    local btnH = L and L.actionBtnH or 42

    self.TextLabel:SetText(text)
    self.TextLabel:SizeToContents()

    self:SetWide(math.max(self.TextLabel:GetWide() + 52, minW))
    self:SetTall(btnH)
end

function PANEL6:PerformLayout()
    local pad = 8
    local icon = 24
    self.m_Image:SetSize(icon, icon)
    self.m_Image:SetPos(pad, (self:GetTall() - icon) / 2)

    self.m_Image2:SetSize(icon, icon)
    self.m_Image2:SetPos(pad, (self:GetTall() - icon) / 2)

    self.TextLabel:SetPos(pad + icon + 8, (self:GetTall() - self.TextLabel:GetTall()) / 2)
end

function PANEL6:SetBorderColor(Col)
    self.BorderColor = Col or Color(190,40,0,255)
end

function PANEL6:Paint()
    local UI = SWGRP.UI
    local w, h = self:GetWide(), self:GetTall()
    local accent = self.BorderColor or (UI and UI.Colors.primary) or Color(255, 180, 50)

    if UI then
        UI.SyncColors()
        local col = UI.Colors.bgLight
        if self.Hovered then col = UI.Colors.bgHover end
        if self.Depressed then col = Color(col.r + 8, col.g + 8, col.b + 12, col.a) end
        surface.SetDrawColor(col)
        surface.DrawRect(2, 2, w - 4, h - 4)
        surface.SetDrawColor(accent.r, accent.g, accent.b, self.Hovered and 200 or 120)
        surface.DrawOutlinedRect(2, 2, w - 4, h - 4, 1)
        if self.Hovered then
            surface.SetDrawColor(accent.r, accent.g, accent.b, 25)
            surface.DrawRect(2, 2, w - 4, h - 4)
        end
        self.TextLabel:SetColor(self.Hovered and UI.Colors.primary or UI.Colors.secondary)
    else
        draw.RoundedBox(4, 0, 0, w, h, accent)
        draw.RoundedBox(4, 2, 2, w - 4, h - 4, Color(40, 40, 40, 255))
    end
end

function PANEL6:OnMousePressed(mouse)
    if self:GetDisabled() then return end

    self.m_Image:SetSize(24,24)
    self.m_Image:SetPos(8,8)
    self.Depressed = true
end

function PANEL6:OnMouseReleased(mouse)
    if self:GetDisabled() then return end

    self.m_Image:SetSize(32,32)
    self.m_Image:SetPos(4,4)
    self.Depressed = false
    self:DoClick()
end

derma.DefineControl("FAdminActionButton", "Button for doing actions", PANEL6, "DImageButton")
