-- NAMESPACE: FiveSecondRule
local ADDON_NAME = "FiveSecondRule"
FiveSecondRule = {}
FiveSecondRuleTick = {}

local DEFAULT_BAR_WIDTH = 117
local DEFAULT_BAR_HEIGHT = 11

local defaults = {
    ["unlocked"] = false,
    ["showTicks"] = true,
    ["barWidth"] = DEFAULT_BAR_WIDTH,
    ["barHeight"] = DEFAULT_BAR_HEIGHT,
    ["barLeft"] = 90,
    ["barTop"] = -68,
    ["flat"] = false,
    ["showText"] = true,
    ["transparent"] = false,
}

-- CONSTANTS
local manaRegenTime = 2
local updateTimerEverySeconds = 0.05
local mp5delay = 5
local spiritConsts = { -- key: {Base Regen, Spirit Divisor}
    ["Druid"] = {15, 4.5},
    ["Hunter"] = {15, 5},
    ["Paladin"] = {15, 5},
    ["Warlock"] = {15, 5},
    ["Mage"] = {12.5, 4},
    ["Priest"] = {12.5, 4},
    ["Shaman"] = {17, 5},
}

-- STATE VARIABLES
local gainingMana = false
local fullmana = false
local castCounter = 0
local mp5StartTime = 0
local manaTickTime = 0
local lowballMp5 = 0
local rezExpireTime = nil

-- INTERFACE
local FiveSecondRuleFrame = CreateFrame("Frame") -- Root frame
local statusbar = CreateFrame("StatusBar", "Five Second Rule Statusbar", UIParent) -- StatusBar for the 5SR tracker
local tickbar = CreateFrame("StatusBar", "Five Second Rule Statusbar - Mana Ticks", UIParent) -- StatusBar for tracking mana ticks after 5SR is fulfilled

-- REGISTER EVENTS
FiveSecondRuleFrame:RegisterEvent("ADDON_LOADED")
FiveSecondRuleFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
FiveSecondRuleFrame:RegisterEvent("CURRENT_SPELL_CAST_CHANGED")
FiveSecondRuleFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
FiveSecondRuleFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
FiveSecondRuleFrame:RegisterEvent("PLAYER_UNGHOST")

-- REGISTER EVENT LISTENERS
FiveSecondRuleFrame:SetScript("OnUpdate", function(self, sinceLastUpdate) FiveSecondRuleFrame:onUpdate(sinceLastUpdate); end);
FiveSecondRuleFrame:SetScript("OnEvent", function(self, event, arg1, ...) FiveSecondRule:onEvent(self, event, arg1, ...) end);

-- INITIALIZATION
function FiveSecondRule:Init()
    -- Initialize FiveSecondRule_Options
    FiveSecondRule:LoadOptions()
    FiveSecondRule_Options.unlocked = false

    -- Create UI
    FiveSecondRule:Update()
end

function FiveSecondRule:Update()
    FiveSecondRule:UpdateStatusBar()
    FiveSecondRule:UpdateTickBar()
end

function FiveSecondRule:LoadOptions()
    FiveSecondRule_Options = FiveSecondRule_Options or AddonUtils:deepcopy(defaults)

    for key,value in pairs(defaults) do
        if (FiveSecondRule_Options[key] == nil) then
            FiveSecondRule_Options[key] = value
        end
    end
end

-- UI INFLATION
function FiveSecondRule:UpdateStatusBar()
    -- POSITION, SIZE
    statusbar:ClearAllPoints()
    statusbar:SetWidth(FiveSecondRule_Options.barWidth)
    statusbar:SetHeight(FiveSecondRule_Options.barHeight)
    statusbar:SetPoint("TOPLEFT", FiveSecondRule_Options.barLeft, FiveSecondRule_Options.barTop)

    -- DRAGGING
    statusbar:SetScript("OnMouseDown", function(self, button) FiveSecondRule:onMouseDown(button); end)
    statusbar:SetScript("OnMouseUp", function(self, button) FiveSecondRule:onMouseUp(button); end)
    statusbar:SetMovable(true)
    statusbar:SetResizable(true)
    statusbar:EnableMouse(FiveSecondRule_Options.unlocked)
    statusbar:SetClampedToScreen(true)

    -- VALUE
    statusbar:SetMinMaxValues(0, mp5delay)

    -- FOREGROUND
    statusbar:SetStatusBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
    statusbar:GetStatusBarTexture():SetHorizTile(false)
    statusbar:GetStatusBarTexture():SetVertTile(false)
    if FiveSecondRule_Options.transparent then
        statusbar:SetStatusBarColor(0, 0, 0)
        statusbar:GetStatusBarTexture():SetColorTexture(0, 0, 0, 0)
    else
        statusbar:SetStatusBarColor(0, 0, 0.95)
        if FiveSecondRule_Options.flat then
            statusbar:GetStatusBarTexture():SetColorTexture(0, 0, 0.95, 1)
        end
    end

    -- BACKGROUND
    if (not statusbar.bg) then
        statusbar.bg = statusbar:CreateTexture(nil, "BACKGROUND")
    end
    statusbar.bg:SetTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
    statusbar.bg:SetAllPoints(true)
    if FiveSecondRule_Options.transparent then
        statusbar.bg:SetVertexColor(0, 0, 0)
        statusbar.bg:SetAlpha(0)
        statusbar.bg:SetColorTexture(0, 0, 0, 0)
    else
        statusbar.bg:SetVertexColor(0, 0, 0.55)
        statusbar.bg:SetAlpha(0.8)
        if FiveSecondRule_Options.flat then
            statusbar.bg:SetColorTexture(0, 0, 0.55, 0.5)
        end
    end

    -- TEXT
    if (not statusbar.value) then
        statusbar.value = statusbar:CreateFontString(nil, "OVERLAY")
    end

    statusbar.value:SetPoint("LEFT", statusbar, "LEFT", 4, 0)
    statusbar.value:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
    statusbar.value:SetJustifyH("LEFT")
    statusbar.value:SetShadowOffset(1, -1)
    statusbar.value:SetTextColor(1, 1, 1)

    -- SPARK
    if not (statusbar.bg.spark) then
        local spark = statusbar:CreateTexture(nil, "OVERLAY")
        spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
        spark:SetWidth(16)
        spark:SetVertexColor(1, 1, 1)
        spark:SetBlendMode("ADD")
        statusbar.bg.spark = spark
    end

    FiveSecondRule:SetDefaultFont(statusbar)

    if (not FiveSecondRule_Options.unlocked) then
        statusbar:Hide()
    end
end

function FiveSecondRule:UpdateTickBar()
    -- POSITION, SIZE
    tickbar:SetWidth(FiveSecondRule_Options.barWidth)
    tickbar:SetHeight(FiveSecondRule_Options.barHeight)
    tickbar:SetPoint("TOPLEFT", statusbar, 0, 0)

    -- DRAGGING
    tickbar:SetMovable(true)
    tickbar:SetResizable(true)
    tickbar:EnableMouse(false)
    tickbar:SetClampedToScreen(true)

    -- VALUE
    tickbar:SetMinMaxValues(0, 2)

    -- FOREGROUND
    tickbar:SetStatusBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
    tickbar:GetStatusBarTexture():SetHorizTile(false)
    tickbar:GetStatusBarTexture():SetVertTile(false)
    if FiveSecondRule_Options.transparent then
        tickbar:SetStatusBarColor(0, 0, 0)
        tickbar:GetStatusBarTexture():SetColorTexture(0, 0, 0, 0)
    else
        tickbar:SetStatusBarColor(0.95, 0.95, 0.95)
        if FiveSecondRule_Options.flat then
            tickbar:GetStatusBarTexture():SetColorTexture(0.55, 0.55, 0.55, 1)
        end
    end

    -- BACKGROUND
    if (not tickbar.bg) then
        tickbar.bg = tickbar:CreateTexture(nil, "BACKGROUND")
    end
    tickbar.bg:SetTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
    tickbar.bg:SetAllPoints(true)
    if FiveSecondRule_Options.transparent then
        tickbar.bg:SetVertexColor(0, 0, 0)
        tickbar.bg:SetAlpha(0)
        tickbar.bg:SetColorTexture(0, 0, 0, 0)
    else
        tickbar.bg:SetVertexColor(0.55, 0.55, 0.55)
        tickbar.bg:SetAlpha(0.8)
        if FiveSecondRule_Options.flat then
            tickbar.bg:SetColorTexture(0.35, 0.35, 0.35, 0.8)
        end
    end

    -- TEXT
    if (not tickbar.value) then
        tickbar.value = tickbar:CreateFontString(nil, "OVERLAY")
    end
    tickbar.value:SetPoint("LEFT", tickbar, "LEFT", 4, 0)
    tickbar.value:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
    tickbar.value:SetJustifyH("LEFT")
    tickbar.value:SetShadowOffset(1, -1)
    tickbar.value:SetTextColor(1, 1, 1, 1)

    -- SPARK
    if not (tickbar.bg.spark) then
        local spark = tickbar:CreateTexture(nil, "OVERLAY")
        spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
        spark:SetWidth(16)
        spark:SetVertexColor(1, 1, 1)
        spark:SetBlendMode("ADD")
        tickbar.bg.spark = spark
    end

    FiveSecondRule:SetDefaultFont(tickbar)

    tickbar:Hide()
end

-- DRAG HANDLERS

function FiveSecondRule:onMouseDown(button)
    if button == "LeftButton" then
        statusbar:StartMoving();
    elseif button == "RightButton" then
        statusbar:StartSizing("BOTTOMRIGHT");
        statusbar.resizing = 1
    end
end

function FiveSecondRule:onMouseUp()
    statusbar:StopMovingOrSizing();

    FiveSecondRule_Options.barLeft = statusbar:GetLeft()
    FiveSecondRule_Options.barTop = -1 * (GetScreenHeight() - statusbar:GetTop())
    FiveSecondRule_Options.barWidth = statusbar:GetWidth()
    FiveSecondRule_Options.barHeight = statusbar:GetHeight()

    FiveSecondRule:UpdateStatusBar()
    FiveSecondRule:UpdateTickBar()

    FiveSecondRule.OptionsPanelFrame:UpdateOptionValues()
end

-- EVENT HANDLER

function FiveSecondRule:onEvent(self, event, arg1, ...)
    if event == "ADDON_LOADED" then
        if arg1 == ADDON_NAME then
            FiveSecondRule:Init()
            FiveSecondRule:PrintHelp()
        end
    end

    if event == "PLAYER_ENTERING_WORLD" then
        FiveSecondRule:updatePlayerMana()
        FiveSecondRule:checkForSickness()
        FiveSecondRule:updatePlayerMp5()
    end

    if event == "CURRENT_SPELL_CAST_CHANGED"  then
        castCounter = castCounter + 1

        if (castCounter == 1) then
             FiveSecondRule:updatePlayerMana()
        elseif (castCounter == 2) then
            FiveSecondRule:updatePlayerMana()
        else
            castCounter = 0
        end
    end

    if event == "UNIT_SPELLCAST_SUCCEEDED" then
        if FiveSecondRule:getPlayerMana() < currentMana then
            gainingMana = false

            FiveSecondRule:updatePlayerMana()
            mp5StartTime = GetTime() + 5

            tickbar:Hide()
            statusbar:Show()
        end
    end

    if event == "PLAYER_EQUIPMENT_CHANGED" then
        FiveSecondRule:updatePlayerMana()
        FiveSecondRule:updatePlayerMp5()
    end

    -- NOTE: Wisdom and some other buffs may be unaffected by sickness.
    --       Very likely that their mana ticks break the 2s tick timer.
    if event == "PLAYER_UNGHOST" then
        FiveSecondRule:checkForSickness()
        FiveSecondRule:updatePlayerMp5()
    end
end

function FiveSecondRuleFrame:onUpdate(sinceLastUpdate)
    local isDead = UnitIsDead("player")

    if isDead then
      statusbar:Hide()
      tickbar:Hide()
      return
    end

    local now = GetTime()
    local newMana = FiveSecondRule:getPlayerMana()

    fullmana = newMana >= FiveSecondRule:getPlayerManaMax()

    if not (now == nil) then -- time needs to be defined for this to work
        self.sinceLastUpdate = (self.sinceLastUpdate or 0) + sinceLastUpdate;

        if ( self.sinceLastUpdate >= updateTimerEverySeconds ) then -- in seconds
            self.sinceLastUpdate = 0;

            if (mp5StartTime > 0) then
                local remaining = (mp5StartTime - now)

                if (remaining > 0) then
                    local name = nil
                    if newMana - currentMana > lowballMp5 then
                        for i=1,40 do
                            name = UnitBuff("player",i)
                            if name=="Drink" then
                                break
                            end
                        end
                    end

                    if name then
                        FiveSecondRule:resetManaGain()
                    else
                        statusbar:SetValue(remaining)

                        if (FiveSecondRule_Options.showText == true) then
                            statusbar.value:SetText(string.format("%.1f", remaining).."s")
                        else
                            statusbar.value:SetText("")
                        end

                        local ratio = FiveSecondRule_Options.barWidth * (remaining/mp5delay)
                        statusbar.bg.spark:SetPoint("CENTER", statusbar.bg, "LEFT", ratio, 0)
                    end
                else
                    FiveSecondRule:resetManaGain()
                end
            end
        end

        if FiveSecondRule_Options.showTicks then
            if fullmana then
                if not FiveSecondRule_Options.unlocked then
                    tickbar:Hide()
                end
            else
                if gainingMana then
                    if newMana - currentMana > lowballMp5 then
                        tickbar:Show()
                        manaTickTime = now + manaRegenTime
                        FiveSecondRule:updatePlayerMana()
                    end

                    local val = manaTickTime - now
                    tickbar:SetValue(manaRegenTime - val)

                    if (FiveSecondRule_Options.showText == true) then
                        tickbar.value:SetText(string.format("%.1f", val).."s")
                    else
                        tickbar.value:SetText("")
                    end

                    local ratio = FiveSecondRule_Options.barWidth * (1 - (val/manaRegenTime))
                    tickbar.bg.spark:SetPoint("CENTER", tickbar.bg, "LEFT", ratio-2, 0)
                end
            end
        end

    end
end

-- HELPER FUNCTIONS
function FiveSecondRule:SetDefaultFont(target)
    local height = target:GetHeight()
    local remainder = AddonUtils:modulus(height, 2)
    local px = height - remainder

    px = math.min(px, 20)
    px = math.max(px, 1)

    if (px < 8) then
        target.value:SetTextColor(0, 0, 0, 0)
    else
        target.value:SetTextColor(0.95, 0.95, 0.95)
    end

    target.value:SetFont("Fonts\\FRIZQT__.TTF", px, "OUTLINE")
end

function FiveSecondRule:updatePlayerMana()
    currentMana = FiveSecondRule:getPlayerMana()
end

function FiveSecondRule:resetManaGain()
    gainingMana = true
    mp5StartTime = 0

    if not FiveSecondRule_Options.unlocked then
        statusbar:Hide()
    end
end

function FiveSecondRule:updatePlayerMp5()
    local playerClass = UnitClass("player")
    local _, spirit = UnitStat("player", 5)
    spiritArray = spiritConsts[playerClass]
    lowballMp5 = spiritArray[1] + spirit/spiritArray[2]

    if rezExpirationTime and GetTime() > rezExpirationTime then
        lowballMp5 = lowballMp5 * .75
    end
end

function FiveSecondRule:checkForSickness()
    for i=1,40 do
        local name, _, _, _, _, expirationTime = UnitDebuff("player",i)
        if name=="Resurrection Sickness" then
            rezExpireTime = expirationTime
        end
    end
end

function FiveSecondRule:getPlayerMana()
    return UnitPower("player" , 0); -- 0 is mana
end

function FiveSecondRule:getPlayerManaMax()
    return UnitPowerMax("player", 0) -- 0 is mana
end

function FiveSecondRule:unlock()
    FiveSecondRule_Options.unlocked = true

    statusbar:Show()
    statusbar:EnableMouse(true)
    statusbar:SetValue(2)

    tickbar:Hide()
end

function FiveSecondRule:lock()
    FiveSecondRule_Options.unlocked = false

    statusbar:Hide()
    statusbar:EnableMouse(false)
    statusbar:StopMovingOrSizing();
    statusbar.resizing = nil
end

function FiveSecondRule:reset()
    tickbar:SetUserPlaced(false)
    statusbar:SetUserPlaced(false)

    FiveSecondRule_Options = AddonUtils:deepcopy(defaults)

    FiveSecondRule:Init()
end

function FiveSecondRule:flat(flat)
    FiveSecondRule_Options.flat = flat;
    FiveSecondRule:Update();
end

-- HELP
function FiveSecondRule:PrintHelp()
    local colorHex = "2979ff"
    print("|cff"..colorHex.."FiveSecondRule loaded - /fsr")
end
