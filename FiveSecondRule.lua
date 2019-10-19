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
    ["manaTicksBackgroundColor"] = {0.35, 0.35, 0.35, 0.8}
}

-- CONSTANTS
local manaRegenTime = 2
local updateTimerEverySeconds = 0.05
local mp5delay = 5
local lowestTickTimePossible = 1.85 -- observed

-- LOCALIZED STRINGS
local SPIRIT_TAP_NAME = "Spirit Tap"
local RESURRECTION_SICKNESS_NAME = "Resurrection Sickness"
local BLESSING_OF_WISDOM_NAME = "Blessing of Wisdom"
local GREATER_BLESSING_OF_WISDOM_NAME = "Greater Blessing of Wisdom"
local INNERVATE_NAME = "Innervate"
local DRINK_NAME = "Drink"
local EVOCATE_NAME = "Evocation"

-- STATE VARIABLES
local gainingMana = false
local mp5StartTime = 0
local manaTickTime = 0
local calibrateMana = {}
local calibrateManaCount = 0
local lastValidTickTime = nil

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

    -- LOCALIZATION
    FiveSecondRule:LoadSpells()

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

function FiveSecondRule:LoadSpells()
    SPIRIT_TAP_NAME = FiveSecondRule:SpellIdToName(15338)
    RESURRECTION_SICKNESS_NAME = FiveSecondRule:SpellIdToName(15007)
    BLESSING_OF_WISDOM_NAME = FiveSecondRule:SpellIdToName(19854) -- Rank doesnt matter
    GREATER_BLESSING_OF_WISDOM_NAME = FiveSecondRule:SpellIdToName(25918) -- Rank doesnt matter
    INNERVATE_NAME = FiveSecondRule:SpellIdToName(29166)
    DRINK_NAME = FiveSecondRule:SpellIdToName(1135)
    EVOCATE_NAME = FiveSecondRule:SpellIdToName(12051)
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
    end

    -- removed cast counter event because it only tracked start/cancel events
    -- and messed up tick timings. all that matters is the finish event

    if event == "UNIT_SPELLCAST_SUCCEEDED" then
        if arg1 == "player" and FiveSecondRule:getPlayerMana() < currentMana then
            gainingMana = false

            FiveSecondRule:updatePlayerMana()
            mp5StartTime = GetTime() + 5

            calibrateMana = {}
            calibrateManaCount = 0
            lastValidTickTime = nil

            tickbar:Hide()
            statusbar:Show()
        end
    end

    if event == "PLAYER_EQUIPMENT_CHANGED" then
        FiveSecondRule:updatePlayerMana()
    end

    if event == "PLAYER_UNGHOST" then
        -- Update mana since players don't rez at full
        FiveSecondRule:updatePlayerMana()
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

    if not (now == nil) then -- time needs to be defined for this to work
        self.sinceLastUpdate = (self.sinceLastUpdate or 0) + sinceLastUpdate;

        if (self.sinceLastUpdate >= updateTimerEverySeconds) then -- in seconds
            self.sinceLastUpdate = 0;

            if (mp5StartTime > 0) then
                local remaining = (mp5StartTime - now)

                if (remaining >= 0) then
                    local isBreakingRegen = false

                    -- Use the 5 seconds to find the 2s interval
                    if tickSize > 0 then
                        FiveSecondRule:calibratePlayerMana(now)

                        if lastValidTickTime ~= nil and now - lastValidTickTime > lowestTickTimePossible then
                            lastValidTickTime = now
                        end

                        isBreakingRegen = FiveSecondRule:PlayerHasBuffs({
                            [DRINK_NAME] = true,
                            [EVOCATE_NAME] = true
                        })

                        if isBreakingRegen then
                            lastValidTickTime = now
                        end

                        FiveSecondRule:updatePlayerMana()
                    end

                    if isBreakingRegen then
                        FiveSecondRule:resetManaGain()
                    else
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
                    -- show it early so we can hold spark at 0
                    tickbar:Show()

                    if tickSize > 0 then
                        if lastValidTickTime ~= nil then -- nil after first load or rez
                            if now - lastValidTickTime > lowestTickTimePossible then
                                lastValidTickTime = now
                                FiveSecondRule:updatePlayerMana()
                            end

                            manaTickTime = lastValidTickTime + manaRegenTime
                        else
                            FiveSecondRule:calibratePlayerMana(now)

                            manaTickTime = now + manaRegenTime
                            FiveSecondRule:updatePlayerMana()
                        end
                    end

                    -- Only relevant after at least one tick has been observed
                    local val = manaTickTime - now
                    tickbar:SetValue(manaRegenTime - val)

                    if (FiveSecondRule_Options.showText == true) then
                        tickbar.value:SetText(string.format("%.1f", val).."s")
                    else
                        tickbar.value:SetText("")
                    end

                    if (FiveSecondRule_Options.showSpark) then
                        local positionLeft = nil
                        if val < 0 then -- hold the spark on the left until good tick data becomes available
                            positionLeft = math.min(FiveSecondRule_Options.barWidth * 0, FiveSecondRule_Options.barWidth)
                        else
                            positionLeft = math.min(FiveSecondRule_Options.barWidth * (1 - (val/manaRegenTime)), FiveSecondRule_Options.barWidth)
                        end
                        tickbar.bg.spark:SetPoint("CENTER", tickbar.bg, "LEFT", positionLeft-2, 0)      
                    end
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

-- NOTE: Only update the player's mana when a tick has occured
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

function FiveSecondRule:calibratePlayerMana(curTime)
    -- 10 is an abitrary unreachable; the max number of ticks that can occur naturally in 5s
    for i=0,9 do
        if calibrateMana[i] then
            if curTime - calibrateMana[i] > lowestTickTimePossible then
                lastValidTickTime = curTime
                break
            end
        else
            break
        end
    end

    calibrateMana[calibrateManaCount] = curTime
    calibrateManaCount = (calibrateManaCount + 1) % 10
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

function FiveSecondRule:PlayerHasBuffs(nameParams)
    if type(nameParams) == "string" then
        nameParams = { 
            [tmp] = true
        }
    end

    for i=1,40 do
        local name, _, _, _, _, expirationTime = UnitBuff("player",i)
        if name then
            if nameParams[name] ~= nil then
                return true, expirationTime
            end
        end
      end
      return false, nil
end

function FiveSecondRule:PlayerHasDebuffs(nameParams)
    if type(nameParams) == "string" then
        nameParams = { 
            [tmp] = true
        }
    end

    for i=1,40 do
        local name, _, _, _, _, expirationTime = UnitDebuff("player",i)
        if name then
            if nameParams[name] ~= nil then
                return true, expirationTime
            end
        end
      end
      return false, nil
end

function FiveSecondRule:SpellIdToName(id)
    local name, _, _, _, _, _ = GetSpellInfo(id)
    return name
end
