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
    ["showSpark"] = true,
    ["statusBarColor"] = {0,0,1,0.95},
    ["statusBarBackgroundColor"] = {0,0,0,0.55},
    ["manaTicksColor"] = {0.95, 0.95, 0.95, 1},
    ["manaTicksBackgroundColor"] = {0.35, 0.35, 0.35, 0.8},
}

-- CONSTANTS
local manaRegenTime = 2
local updateTimerEverySeconds = 0.05
local mp5delay = 5
local mp5Sensitivty = 0.8

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
local castCounter = 0
local mp5StartTime = 0
local manaTickTime = 0
local isDead = false

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
FiveSecondRuleFrame:RegisterEvent("UNIT_AURA")

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
    local sc = FiveSecondRule_Options.statusBarColor
    statusbar:SetStatusBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
    statusbar:GetStatusBarTexture():SetHorizTile(false)
    statusbar:GetStatusBarTexture():SetVertTile(false)
    statusbar:SetStatusBarColor(sc[1], sc[2], sc[3], sc[4])

    if FiveSecondRule_Options.flat then
        statusbar:GetStatusBarTexture():SetColorTexture(sc[1], sc[2], sc[3], sc[4])
    end    

    -- BACKGROUND
    local sbc = FiveSecondRule_Options.statusBarBackgroundColor
    if (not statusbar.bg) then
        statusbar.bg = statusbar:CreateTexture(nil, "BACKGROUND")
    end
    statusbar.bg:SetTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
    statusbar.bg:SetAllPoints(true)
    statusbar.bg:SetVertexColor(sbc[1], sbc[2], sbc[3])
    statusbar.bg:SetAlpha(sbc[4])

    if FiveSecondRule_Options.flat then
        statusbar.bg:SetColorTexture(sbc[1], sbc[2], sbc[3], sbc[4])
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
    if (FiveSecondRule_Options.showSpark) then
        if (not statusbar.bg.spark) then
            local spark = statusbar:CreateTexture(nil, "OVERLAY")
            spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
            spark:SetWidth(16)        
            spark:SetVertexColor(1, 1, 1)
            spark:SetBlendMode("ADD")
            statusbar.bg.spark = spark
        end
    else
        if (statusbar.bg.spark) then
            statusbar.bg.spark:SetTexture(nil)
            statusbar.bg.spark = nil
        end
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
    local fgc = FiveSecondRule_Options.manaTicksColor
    tickbar:SetStatusBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
    tickbar:GetStatusBarTexture():SetHorizTile(false)
    tickbar:GetStatusBarTexture():SetVertTile(false)
    tickbar:SetStatusBarColor(fgc[1], fgc[2], fgc[3], fgc[4])

    if FiveSecondRule_Options.flat then
        tickbar:GetStatusBarTexture():SetColorTexture(fgc[1], fgc[2], fgc[3], fgc[4])
    end     

    -- BACKGROUND
    local bgc = FiveSecondRule_Options.manaTicksBackgroundColor
    if (not tickbar.bg) then
        tickbar.bg = tickbar:CreateTexture(nil, "BACKGROUND")
    end
    tickbar.bg:SetTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
    tickbar.bg:SetAllPoints(true)
    tickbar.bg:SetVertexColor(bgc[1], bgc[2], bgc[3])
    tickbar.bg:SetAlpha(bgc[4])

    if FiveSecondRule_Options.flat then
        tickbar.bg:SetColorTexture(bgc[1], bgc[2], bgc[3], bgc[4])
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
    if (FiveSecondRule_Options.showSpark) then
        if (not tickbar.bg.spark) then
            local spark = tickbar:CreateTexture(nil, "OVERLAY")
            spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
            spark:SetWidth(16)        
            spark:SetVertexColor(1, 1, 1)
            spark:SetBlendMode("ADD")
            tickbar.bg.spark = spark
        end
    else
        if (tickbar.bg.spark) then
            tickbar.bg.spark:SetTexture(nil)
            tickbar.bg.spark = nil
        end
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
        FiveSecondRule:updatePlayerRegen()
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
        FiveSecondRule:updatePlayerRegen()
    end

    if event == "PLAYER_UNGHOST" then
        FiveSecondRule:updatePlayerRegen()
    end

    if event == "UNIT_AURA" and arg1 == "player" then
        FiveSecondRule:updatePlayerRegen()
    end
end

function FiveSecondRuleFrame:onUpdate(sinceLastUpdate)
    if (UnitIsDead("player")) then
      statusbar:Hide()
      tickbar:Hide()
    end

    local now = GetTime()

    local newMana = FiveSecondRule:getPlayerMana()
    local fullmana = newMana >= FiveSecondRule:getPlayerManaMax()
    local tickSize = newMana - currentMana
    local validTick = FiveSecondRule:IsValidTick(tickSize)

    if not (now == nil) then -- time needs to be defined for this to work
        self.sinceLastUpdate = (self.sinceLastUpdate or 0) + sinceLastUpdate;

        if (self.sinceLastUpdate >= updateTimerEverySeconds) then -- in seconds
            self.sinceLastUpdate = 0;

            if (mp5StartTime > 0) then
                local remaining = (mp5StartTime - now)

                if (remaining >= 0) then
                    statusbar:Show()
                    statusbar:SetValue(remaining)

                    if (FiveSecondRule_Options.showText == true) then
                        statusbar.value:SetText(string.format("%.1f", remaining).."s")
                    else
                        statusbar.value:SetText("")
                    end

                    if (FiveSecondRule_Options.showSpark) then
                        local positionLeft = math.min(FiveSecondRule_Options.barWidth * (remaining/mp5delay), FiveSecondRule_Options.barWidth)
                        statusbar.bg.spark:SetPoint("CENTER", statusbar.bg, "LEFT", positionLeft, 0)   
                    end
                else
                    FiveSecondRule:resetManaGain()
                end
            else
                FiveSecondRule:resetManaGain()
            end
        end

        if FiveSecondRule_Options.showTicks then
            if fullmana then
                if not FiveSecondRule_Options.unlocked then
                    tickbar:Hide()
                end
            else
                if gainingMana then

                    if newMana > currentMana then
                        if (validTick) then
                            tickbar:Show() 
                            manaTickTime = now + manaRegenTime
                        end
                    end

                    local val = manaTickTime - now
                    tickbar:SetValue(manaRegenTime - val)

                    if (FiveSecondRule_Options.showText == true) then
                        tickbar.value:SetText(string.format("%.1f", val).."s")
                    else
                        tickbar.value:SetText("")
                    end

                    if (FiveSecondRule_Options.showSpark) then
                        local positionLeft = math.min(FiveSecondRule_Options.barWidth * (1 - (val/manaRegenTime)), FiveSecondRule_Options.barWidth)
                        tickbar.bg.spark:SetPoint("CENTER", tickbar.bg, "LEFT", positionLeft-2, 0)      
                    end
                end
            end
        end
    end

    FiveSecondRule:updatePlayerMana()
end

function FiveSecondRule:IsValidTick(tick) 
    local low = baseRegen * mp5Sensitivty
    local high = baseRegen * (1 + (1 - mp5Sensitivty))

    -- UNDER
    if (tick < low) then
        -- Ticks below our base mana regen is triggered by MP5-regen.
        return false
    end

    -- OVER
    if (tick > high) then
        local sicknessTick = false
        -- Resurrection Sickness lowers regen, but does not seem to be reduced by 75% like stats.
        if (FiveSecondRule:PlayerHasDebuff("Resurrection Sickness")) then
            sicknessTick = tick < high * 3 -- 3 is an arbitrary number selected through trial and error
        end

        -- Larger ticks can be triggered by drinking or by getting Innervate, which both align with the spirit-based regen.
        -- It can also be triggered by consumables, which are spontaneous. Thus, consumables are excluded.
        return FiveSecondRule:PlayerHasBuff("Drink") or FiveSecondRule:PlayerHasBuff("Innervate") or sicknessTick
    end

    return true
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

function FiveSecondRule:updatePlayerRegen()
    baseRegen = FiveSecondRule:GetPlayerBaseRegen()
end

function FiveSecondRule:resetManaGain()
    gainingMana = true
    mp5StartTime = 0

    if not FiveSecondRule_Options.unlocked then
        statusbar:Hide()
    end
end

function FiveSecondRule:GetPlayerBaseRegen()
    local playerClass = UnitClass("player")
    local _, spirit = UnitStat("player", 5)
    spiritArray = spiritConsts[playerClass]
    local regen = spiritArray[1] + spirit/spiritArray[2]

    if (FiveSecondRule:PlayerHasDebuff("Resurrection Sickness")) then
        regen = regen * 0.25
    end

    return regen
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

function FiveSecondRule:PlayerHasBuff(nameString)
    for i=1,40 do
        local name, _, _, _, _, expirationTime = UnitBuff("player",i)
        if name then
            if name == nameString then
                return true, expirationTime
            end
        end
      end
      return false, nil
end

function FiveSecondRule:PlayerHasDebuff(nameString)
    for i=1,40 do
        local name, _, _, _, _, expirationTime = UnitDebuff("player",i)
        if name then
            if name == nameString then
                return true, expirationTime
            end
        end
      end
      return false, nil
end
