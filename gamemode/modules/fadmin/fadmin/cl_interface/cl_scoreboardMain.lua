local Sorted, SortDown = CreateClientConVar("FAdmin_SortPlayerList", "Team", true), CreateClientConVar("FAdmin_SortPlayerListDown", 1, true)
local allowedSorts = {
    ["Name"] = true,
    ["Team"] = true,
    ["Frags"] = true,
    ["Deaths"] = true,
    ["Ping"] = true
}

function FAdmin.ScoreBoard.Main.Show()
    local Sort = {}
    local ScreenWidth, ScreenHeight = ScrW(), ScrH()

    FAdmin.ScoreBoard.X = ScreenWidth * 0.05
    FAdmin.ScoreBoard.Y = ScreenHeight * 0.025
    FAdmin.ScoreBoard.Width = ScreenWidth * 0.9
    FAdmin.ScoreBoard.Height = ScreenHeight * 0.95

    FAdmin.ScoreBoard.ChangeView("Main")

    FAdmin.ScoreBoard.Main.Controls.FAdminPanelList = FAdmin.ScoreBoard.Main.Controls.FAdminPanelList or vgui.Create("DPanelList")
    FAdmin.ScoreBoard.Main.Controls.FAdminPanelList:SetVisible(true)
    FAdmin.ScoreBoard.Main.Controls.FAdminPanelList:Clear(true)

    local UI = SWGRP.UI
    local L = UI and UI.ScoreboardLayout
    local bx, by = FAdmin.ScoreBoard.X, FAdmin.ScoreBoard.Y
    local bw, bh = FAdmin.ScoreBoard.Width, FAdmin.ScoreBoard.Height
    local margin = L and L.margin or 24
    local listPad = L and L.listPad or 10
    local sortLabelY = UI and UI.ScoreboardSortLabelY( by ) or ( by + 120 )
    local listX, listY, listW, listH = bx + margin, by + 160, bw - margin * 2, bh - 180
    if UI and UI.ScoreboardListRect then
        listX, listY, listW, listH = UI.ScoreboardListRect( bx, by, bw, bh )
    end

    FAdmin.ScoreBoard.Main.Controls.FAdminPanelList.Padding = listPad
    FAdmin.ScoreBoard.Main.Controls.FAdminPanelList:EnableVerticalScrollbar(true)
    FAdmin.ScoreBoard.Main.Controls.FAdminPanelList:SetPos(listX, listY)
    FAdmin.ScoreBoard.Main.Controls.FAdminPanelList:SetSize(listW, listH)

    if UI and UI.StylePanelList then
        UI.StylePanelList( FAdmin.ScoreBoard.Main.Controls.FAdminPanelList )
    end

    if FAdmin.ScoreBoard.Controls.BackButton then
        FAdmin.ScoreBoard.Controls.BackButton:SetVisible(false)
    end

    Sort.Name = Sort.Name or vgui.Create("DLabel")
    Sort.Name:SetText("Sort by:  Name")
    Sort.Name:SetPos(bx + margin + listPad, sortLabelY)
    Sort.Name.Type = "Name"
    Sort.Name:SetVisible(true)

    Sort.Team = Sort.Team or vgui.Create("DLabel")
    Sort.Team:SetText("Team")
    Sort.Team:SetPos(ScreenWidth * 0.5 - 30, sortLabelY)
    Sort.Team.Type = "Team"
    Sort.Team:SetVisible(true)

    Sort.Frags = Sort.Frags or vgui.Create("DLabel")
    Sort.Frags:SetText("Kills")
    Sort.Frags:SetPos(listX + listW - 200, sortLabelY)
    Sort.Frags.Type = "Frags"
    Sort.Frags:SetVisible(true)

    Sort.Deaths = Sort.Deaths or vgui.Create("DLabel")
    Sort.Deaths:SetText("Deaths")
    Sort.Deaths:SetPos(listX + listW - 140, sortLabelY)
    Sort.Deaths.Type = "Deaths"
    Sort.Deaths:SetVisible(true)

    Sort.Ping = Sort.Ping or vgui.Create("DLabel")
    Sort.Ping:SetText("Ping")
    Sort.Ping:SetPos(listX + listW - 56, sortLabelY)
    Sort.Ping.Type = "Ping"
    Sort.Ping:SetVisible(true)

    local sortBy = Sorted:GetString()
    sortBy = allowedSorts[sortBy] and sortBy or "Team"

    FAdmin.ScoreBoard.Main.PlayerListView(sortBy, SortDown:GetBool())

    for _, v in pairs(Sort) do
        if UI and UI.StyleTerminalLabel then
            UI.StyleTerminalLabel( v, "SWGRP_ScoreboardRow", UI.Colors.primary )
        else
            v:SetFont("Trebuchet20")
        end
        v:SizeToContents()

        local X, Y = v:GetPos()

        v.BtnSort = vgui.Create("DButton")
        v.BtnSort:SetText("")
        v.BtnSort.Type = "Down"
        if Sorted:GetString() == v.Type then
            v.BtnSort.Type = (SortDown:GetBool() and "Down") or "Up"
        end
        v.BtnSort.Paint = function( panel, w, h )
            if UI and UI.PaintSortArrow then
                UI.PaintSortArrow( panel, w, h, v.BtnSort.Type, Sorted:GetString() == v.Type )
            end
        end
        v.BtnSort:SetSize(18, 18)
        v.BtnSort:SetPos(X + v:GetWide() + 6, Y + math.floor((v:GetTall() - 18) / 2))
        function v.BtnSort.DoClick()
            v.BtnSort.Type = (v.BtnSort.Type == "Down" and "Up") or "Down"

            RunConsoleCommand("FAdmin_SortPlayerList", v.Type)
            RunConsoleCommand("FAdmin_SortPlayerListDown", (v.BtnSort.Type == "Down" and "1") or "0")
            FAdmin.ScoreBoard.Main.Controls.FAdminPanelList:Clear(true)
            FAdmin.ScoreBoard.Main.PlayerListView(v.Type, v.BtnSort.Type == "Down")
        end
        table.insert(FAdmin.ScoreBoard.Main.Controls, v) -- Add them to the table so they get removed when you close the scoreboard
        table.insert(FAdmin.ScoreBoard.Main.Controls, v.BtnSort)
    end
end

function FAdmin.ScoreBoard.Main.AddPlayerRightClick(Name, func)
    FAdmin.PlayerIcon.RightClickOptions[Name] = func
end

FAdmin.StartHooks["CopySteamID"] = function()
    FAdmin.ScoreBoard.Main.AddPlayerRightClick("Copy SteamID", function(ply) SetClipboardText(ply:SteamID()) end)
end
