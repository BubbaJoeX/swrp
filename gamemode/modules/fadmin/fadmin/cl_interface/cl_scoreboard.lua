local OverrideScoreboard = CreateClientConVar("FAdmin_OverrideScoreboard", 0, true, false) -- Set if it's a scoreboard or not

function FAdmin.ScoreBoard.ChangeView(newView, ...)
    if FAdmin.ScoreBoard.CurrentView == newView or not FAdmin.ScoreBoard.Visible then return end

    for _, v in pairs(FAdmin.ScoreBoard[FAdmin.ScoreBoard.CurrentView].Controls) do
        v:SetVisible(false)
    end

    FAdmin.ScoreBoard.CurrentView = newView
    FAdmin.ScoreBoard[newView].Show(...)
    FAdmin.ScoreBoard.ChangeGmodLogo(FAdmin.ScoreBoard[newView].Logo)

    local UI = SWGRP.UI
    local L = UI and UI.ScoreboardLayout
    FAdmin.ScoreBoard.Controls.BackButton = FAdmin.ScoreBoard.Controls.BackButton or vgui.Create("DButton")
    FAdmin.ScoreBoard.Controls.BackButton:SetText("")
    FAdmin.ScoreBoard.Controls.BackButton:SetTooltip("Return to census")
    FAdmin.ScoreBoard.Controls.BackButton:SetCursor("hand")
    FAdmin.ScoreBoard.Controls.BackButton:SetZPos(999)

    if newView == "Main" then
        FAdmin.ScoreBoard.Controls.BackButton:SetVisible(false)
    else
        local bx, by = FAdmin.ScoreBoard.X, FAdmin.ScoreBoard.Y
        local lx, ly, lw, lh = bx + 24, by + 24, 56, 56
        if UI and UI.ScoreboardLogoRect then
            lx, ly, lw, lh = UI.ScoreboardLogoRect( bx, by )
        end
        FAdmin.ScoreBoard.Controls.BackButton:SetVisible(true)
        FAdmin.ScoreBoard.Controls.BackButton:SetPos(lx, ly)
        FAdmin.ScoreBoard.Controls.BackButton:SetSize(lw, lh)
    end

    function FAdmin.ScoreBoard.Controls.BackButton:DoClick()
        FAdmin.ScoreBoard.ChangeView("Main")
    end
    if UI and UI.PaintBackButton then
        FAdmin.ScoreBoard.Controls.BackButton.Paint = UI.PaintBackButton
    end
end

local GmodLogo, TempGmodLogo, GmodLogoColor = surface.GetTextureID("gui/gmod_logo"), surface.GetTextureID("gui/gmod_logo"), color_white
function FAdmin.ScoreBoard.ChangeGmodLogo(new)
    if surface.GetTextureID(new) == TempGmodLogo then return end
    TempGmodLogo = surface.GetTextureID(new)
    for i = 0, 0.5, 0.01 do
        timer.Simple(i, function() GmodLogoColor = Color(255,255,255,GmodLogoColor.a-5.1) end)
    end
    timer.Simple(0.5, function() GmodLogo = surface.GetTextureID(new) end)
    for i = 0.5, 1, 0.01 do
        timer.Simple(i, function()
            GmodLogoColor = Color(255, 255, 255, GmodLogoColor.a + 5.1)
        end)
    end
end

function FAdmin.ScoreBoard.Background()
    local UI = SWGRP.UI
    if UI and UI.PaintScoreboardPane then
        UI.RegisterFonts()
        local paintSort = FAdmin.ScoreBoard.CurrentView == "Main"
        UI.PaintScoreboardPane( FAdmin.ScoreBoard.X, FAdmin.ScoreBoard.Y, FAdmin.ScoreBoard.Width, FAdmin.ScoreBoard.Height, {
            paintSortBar = paintSort,
        } )
        local lx, ly, lw, lh = UI.ScoreboardLogoRect( FAdmin.ScoreBoard.X, FAdmin.ScoreBoard.Y )
        local A = SWGRP.Assets
        if FAdmin.ScoreBoard.CurrentView == "Main" and A and A.DrawScoreboardLogo then
            A.DrawScoreboardLogo( lx, ly, lw, lh, GmodLogoColor.a * 0.85 )
        elseif GmodLogo then
            surface.SetTexture( GmodLogo )
            surface.SetDrawColor( UI.Colors.primary.r, UI.Colors.primary.g, UI.Colors.primary.b, GmodLogoColor.a * 0.85 )
            surface.DrawTexturedRect( lx, ly, lw, lh )
        end
        return
    end

    surface.SetDrawColor(0,0,0,200)
    surface.DrawRect(FAdmin.ScoreBoard.X, FAdmin.ScoreBoard.Y, FAdmin.ScoreBoard.Width, FAdmin.ScoreBoard.Height)
    surface.SetTexture(GmodLogo)
    surface.SetDrawColor(255,255,255,GmodLogoColor.a)
    surface.DrawTexturedRect(FAdmin.ScoreBoard.X - 20, FAdmin.ScoreBoard.Y, 128, 128)
end


function FAdmin.ScoreBoard.DrawScoreBoard()
    if (input.IsMouseDown(MOUSE_4) or input.IsKeyDown(KEY_BACKSPACE)) and not FAdmin.ScoreBoard.DontGoBack then
        FAdmin.ScoreBoard.ChangeView("Main")
    elseif FAdmin.ScoreBoard.DontGoBack then
        FAdmin.ScoreBoard.DontGoBack = input.IsMouseDown(MOUSE_4) or input.IsKeyDown(KEY_BACKSPACE)
    end
    FAdmin.ScoreBoard.Background()
end

function FAdmin.ScoreBoard.ShowScoreBoard()
    FAdmin.ScoreBoard.Visible = true
    FAdmin.ScoreBoard.DontGoBack = input.IsMouseDown(MOUSE_4) or input.IsKeyDown(KEY_BACKSPACE)

    local UI = SWGRP.UI
    if UI then UI.RegisterFonts() end
    local L = UI and UI.ScoreboardLayout
    local bx, by = FAdmin.ScoreBoard.X, FAdmin.ScoreBoard.Y
    local margin = L and L.margin or 24
    local textX = bx + margin + ( L and L.logoSize or 56 ) + 16
    local headerTextY = by + margin + 38

    FAdmin.ScoreBoard.Controls.Hostname = FAdmin.ScoreBoard.Controls.Hostname or vgui.Create("DLabel")
    FAdmin.ScoreBoard.Controls.Hostname:SetText(DarkRP.deLocalise(GetHostName()))
    FAdmin.ScoreBoard.Controls.Hostname:SetFont("SWGRP_ScoreboardSubtitle")
    FAdmin.ScoreBoard.Controls.Hostname:SetColor(UI and UI.Colors.accent or Color(80, 200, 255))
    FAdmin.ScoreBoard.Controls.Hostname:SetPos(textX, headerTextY)
    FAdmin.ScoreBoard.Controls.Hostname:SizeToContents()
    FAdmin.ScoreBoard.Controls.Hostname:SetVisible(true)

    FAdmin.ScoreBoard.Controls.Description = FAdmin.ScoreBoard.Controls.Description or vgui.Create("DLabel")
    FAdmin.ScoreBoard.Controls.Description:SetText(string.format("%s  |  %s", GAMEMODE.Name, GAMEMODE.Author))
    FAdmin.ScoreBoard.Controls.Description:SetFont("SWGRP_ScoreboardRowSmall")
    FAdmin.ScoreBoard.Controls.Description:SetColor(UI and UI.Colors.secondary or Color(200,200,200))
    FAdmin.ScoreBoard.Controls.Description:SetPos(textX, headerTextY + 22)
    FAdmin.ScoreBoard.Controls.Description:SizeToContents()
    FAdmin.ScoreBoard.Controls.Description:SetVisible(true)

    local rightX = bx + FAdmin.ScoreBoard.Width - margin

    FAdmin.ScoreBoard.Controls.ServerSettingsLabel = FAdmin.ScoreBoard.Controls.ServerSettingsLabel or vgui.Create("DLabel")
    FAdmin.ScoreBoard.Controls.ServerSettingsLabel:SetFont("SWGRP_ScoreboardRowSmall")
    FAdmin.ScoreBoard.Controls.ServerSettingsLabel:SetText("Colony settings")
    FAdmin.ScoreBoard.Controls.ServerSettingsLabel:SetColor(UI and UI.Colors.primary or Color(255, 180, 50))
    FAdmin.ScoreBoard.Controls.ServerSettingsLabel:SizeToContents()
    FAdmin.ScoreBoard.Controls.ServerSettingsLabel:SetPos(rightX - FAdmin.ScoreBoard.Controls.ServerSettingsLabel:GetWide(), by + margin + 44)
    FAdmin.ScoreBoard.Controls.ServerSettingsLabel:SetVisible(true)

    FAdmin.ScoreBoard.Controls.ServerSettings = FAdmin.ScoreBoard.Controls.ServerSettings or vgui.Create("DImageButton")
    FAdmin.ScoreBoard.Controls.ServerSettings:SetMaterial("icon16/wrench.png")
    FAdmin.ScoreBoard.Controls.ServerSettings:SetPos(rightX - 20, by + margin + 8)
    FAdmin.ScoreBoard.Controls.ServerSettings:SizeToContents()
    FAdmin.ScoreBoard.Controls.ServerSettings:SetVisible(true)
    FAdmin.ScoreBoard.Controls.ServerSettings.PaintOver = function( btn, w, h )
        if not btn.Hovered then return end
        local C = UI and UI.Colors
        if C then
            surface.SetDrawColor( C.primary.r, C.primary.g, C.primary.b, 40 )
            surface.DrawRect( 0, 0, w, h )
        end
    end

    function FAdmin.ScoreBoard.Controls.ServerSettings:DoClick()
        FAdmin.ScoreBoard.ChangeView("Server")
    end

    if FAdmin.ScoreBoard.Controls.BackButton then
        FAdmin.ScoreBoard.Controls.BackButton:SetVisible( FAdmin.ScoreBoard.CurrentView ~= "Main" )
    end

    FAdmin.ScoreBoard[FAdmin.ScoreBoard.CurrentView].Show()

    gui.EnableScreenClicker(true)
    hook.Add("HUDPaint", "FAdmin_ScoreBoard", FAdmin.ScoreBoard.DrawScoreBoard)
    hook.Call("FAdmin_ShowFAdminMenu")
    return true
end
concommand.Add("+FAdmin_menu", FAdmin.ScoreBoard.ShowScoreBoard)

hook.Add("ScoreboardShow", "FAdmin_scoreboard", function()
    if FAdmin.GlobalSetting.FAdmin or OverrideScoreboard:GetBool() then -- Don't show scoreboard when FAdmin is not installed on server
        return FAdmin.ScoreBoard.ShowScoreBoard()
    end
end)

function FAdmin.ScoreBoard.HideScoreBoard()
    if not FAdmin.GlobalSetting.FAdmin then return end
    FAdmin.ScoreBoard.Visible = false
    CloseDermaMenus()

    gui.EnableScreenClicker(false)
    hook.Remove("HUDPaint", "FAdmin_ScoreBoard")

    for _, v in pairs(FAdmin.ScoreBoard[FAdmin.ScoreBoard.CurrentView].Controls) do
        v:SetVisible(false)
    end

    for _, v in pairs(FAdmin.ScoreBoard.Controls) do
        v:SetVisible(false)
    end
    return true
end
concommand.Add("-FAdmin_menu", FAdmin.ScoreBoard.HideScoreBoard)

hook.Add("ScoreboardHide", "FAdmin_scoreboard", function()
    if FAdmin.GlobalSetting.FAdmin or OverrideScoreboard:GetBool() then -- Don't show scoreboard when FAdmin is not installed on server
        return FAdmin.ScoreBoard.HideScoreBoard()
    end
end)
