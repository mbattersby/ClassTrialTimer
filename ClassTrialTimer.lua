--[[----------------------------------------------------------------------------

  ClassTrialTimer - World of Warcraft AddOn

  Copyright 2017 Mike Battersby

  ClassTrialTimer is free software: you can redistribute it and/or modify it
  under the terms of the GNU General Public License, version 2, as published
  by the Free Software Foundation.

  ClassTrialTimer is distributed in the hope that it will be useful, but
  WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
  or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
  more details.

  The file LICENSE.txt included with LiteMount contains a copy of the
  license. If the LICENSE.txt file is missing, you can find a copy at
  http://www.gnu.org/licenses/old-licenses/gpl-2.0.txt

----------------------------------------------------------------------------]]--

-- Your new trial character is playable for eight hours, or until you
-- receive your first artifact weapon and create your Order Hall. After the
-- trial is over, your character is locked from further play. You can purchase
-- and use a Character Boost to permanently unlock your trial character.
--
--   https://us.battle.net/support/en/article/64574

local function Update(self)
    if not self.expireTime then return end

    local remainingTime = self.expireTime - time()
    local h = floor((remainingTime % 86400) / 3600)
    local m = floor((remainingTime % 3600) / 60)
    local s = remainingTime % 60

    if self.db.showSeconds then
        local string = format('%02d:%02d', h, m)
        self.remainingTime:SetText(string)
    else
        local string = format('%02s:%02d:%02d', h, m, s)
        self.remainingTime:SetText(string)
    end

    if remainingTime < 15 * 60 then
        self.remainingTime:SetTextColor(1, 1, 0.5, 0.7)
    else
        self.remainingTime:SetTextColor(0.5, 1, 0.5, 0.7)
    end
end

local function SavePosition(self)
    local p, _, r, x, y = self:GetPoint(1)
    self.db.position = { p, r, x, y }
end

local function LoadPosition(self)
    if self.db.position then
        self:ClearAllPoints()
        local p, r, x, y = unpack(self.db.position)
        self:SetPoint(p, UIParent, r, x, y)
    else
        self:ClearAllPoints()
        self:SetPoint("TOP", UIParent, "TOP", 0, -64)
    end
end

local function ResetPosition(self)
    self.db.position = nil
    LoadPosition(self)
end

local function SlashCommand(self, argstr)
    local args = { strsplit(" ", argstr) }
    local cmd = table.remove(args, 1)

    if cmd == "hide" then
        self:Hide()
    elseif cmd == "show" then
        self:Show()
    elseif cmd == "seconds" then
        if args[1] == "on" then
            self.db.showSeconds = true
        else
            self.db.showSeconds = nil
        end
    elseif cmd == "reset" then
        wipe(self.db)
        ResetPosition(self)
        Update(self)
    else
        RequestTimePlayed()
    end
end

function ClassTrialTimer_OnUpdate(self, elapsed)
    self.totalElapsed = (self.totalElapsed or 0) + elapsed
    if self.totalElapsed >= 1 then
        self.totalElapsed = 0
        Update(self)
    end
end

function ClassTrialTimer_OnLoad(self)
    local name, realm = UnitName("player")
    realm = realm or GetRealmName()
    self.characterName:SetText(format('%s-%s', name, realm))

    self:RegisterForDrag("LeftButton")

    SlashCmdList["ClassTrialTimer"] = function (...) SlashCommand(self, ...) end
    SLASH_ClassTrialTimer1 = "/ctt"

    -- How to detect trial account?
    if UnitLevel("player") == 100 then
        self:RegisterEvent("TIME_PLAYED_MSG")
        RequestTimePlayed()
    end

    -- For the DB stuff, not available yet when OnLoad fires
    self:RegisterEvent("VARIABLES_LOADED")
end

function ClassTrialTimer_OnShow(self)
    LoadPosition(self)
    self:SetScript("OnUpdate", ClassTrialTimer_OnUpdate)
end

function ClassTrialTimer_OnHide(self)
    self:SetScript("OnUpdate", nil)
end

function ClassTrialTimer_OnDragStart(self)
    self:StartMoving()
end

function ClassTrialTimer_OnDragStop(self)
    self:StopMovingOrSizing()
    self:SetUserPlaced(false)
    SavePosition(self)
end

function ClassTrialTimer_OnEvent(self, event, ...)
    if event == "VARIABLES_LOADED" then
        ClassTrialTimerDB = ClassTrialTimerDB or { }
        self.db = ClassTrialTimerDB
    elseif event == "TIME_PLAYED_MSG" then
        local totalTime, levelTime = ...
        if totalTime < 8 * 60 * 60 then
            self.expireTime = time() + (8 * 60 * 60) - totalTime
            Update(self)
            self:Show()
        else
            self:Hide()
        end
    end
end
