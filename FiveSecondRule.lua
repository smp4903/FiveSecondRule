-- NAMESPACE: FiveSecondRule
FiveSecondRule = {} 
FiveSecondRuleTick = {}

local defaults = {
    ["showTicks"] = true,
}

-- STATE VARIABLES
local unlocked = false
local fullmana = false
local mp5delay = 5
local castCounter = 0
local mp5StartTime = 0
local updateTimerEverySeconds = 0.05

local manaTickTime = 0
local manaRegenTime = 2

-- INTERFACE
local FiveSecondRuleFrame = CreateFrame("Frame") -- Root frame
local statusbar = CreateFrame("StatusBar", "Five Second Rule Statusbar", UIParent) -- StatusBar for the 5SR tracker
local tickbar = CreateFrame("StatusBar", "Five Second Rule Statusbar - Mana Ticks", UIParent) -- StatusBar for tracking mana ticks after 5SR is fulfilled

-- REGISTER EVENTS
FiveSecondRuleFrame:RegisterEvent("ADDON_LOADED")
FiveSecondRuleFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
FiveSecondRuleFrame:RegisterEvent("CURRENT_SPELL_CAST_CHANGED")
FiveSecondRuleFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")

-- REGISTER EVENT LISTENERS
FiveSecondRuleFrame:SetScript("OnUpdate", function(self, sinceLastUpdate) FiveSecondRuleFrame:onUpdate(sinceLastUpdate); end);
FiveSecondRuleFrame:SetScript("OnEvent", function(self, event, arg1, ...) FiveSecondRule:onEvent(self, event, arg1, ...) end);

-- UI INFLATION
function CreateStatusBar()
    -- VALUE
    statusbar:SetMinMaxValues(0, mp5delay)

    -- POSITION, SIZE
    statusbar:SetWidth(200)
    statusbar:SetHeight(20)
    statusbar:SetMinResize(20, 4)

    if not statusbar:IsUserPlaced() then
        statusbar:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
    end

    -- FOREGROUND
    statusbar:SetStatusBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
    statusbar:GetStatusBarTexture():SetHorizTile(false)
    statusbar:GetStatusBarTexture():SetVertTile(false)
    statusbar:SetStatusBarColor(0, 0, 0.95)

    -- BACKGROUND
    statusbar.bg = statusbar:CreateTexture(nil, "BACKGROUND")
    statusbar.bg:SetTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
    statusbar.bg:SetAllPoints(true)
    statusbar.bg:SetVertexColor(0, 0, 0.55)
    statusbar.bg:SetAlpha(0.5)

    -- TEXT
    statusbar.value = statusbar:CreateFontString(nil, "OVERLAY")
    statusbar.value:SetPoint("LEFT", statusbar, "LEFT", 4, 0)
    statusbar.value:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
    statusbar.value:SetJustifyH("LEFT")
    statusbar.value:SetShadowOffset(1, -1)
    statusbar.value:SetTextColor(1, 1, 1)

    -- DRAGGING
    -- statusbar:RegisterForDrag("LeftButton")
    statusbar:SetScript("OnMouseDown", function(self, button) FiveSecondRule:onMouseDown(button); end)
    statusbar:SetScript("OnMouseUp", function(self, button) FiveSecondRule:onMouseUp(button); end)
    statusbar:SetMovable(true)
    statusbar:SetResizable(true)
    statusbar:EnableMouse(false)
    statusbar:SetClampedToScreen(false)

    statusbar:Hide()
end

function CreateTickBar()
    -- VALUE
    tickbar:SetMinMaxValues(0, 2)

    -- POSITION, SIZE
    tickbar:SetWidth(200)
    tickbar:SetHeight(2)
    tickbar:SetMinResize(20, 2)

    -- FOREGROUND
    tickbar:SetStatusBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
    tickbar:GetStatusBarTexture():SetHorizTile(false)
    tickbar:GetStatusBarTexture():SetVertTile(false)
    tickbar:SetStatusBarColor(0.95, 0.95, 0.95)

    -- BACKGROUND
    tickbar.bg = statusbar:CreateTexture(nil, "BACKGROUND")
    tickbar.bg:SetTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
    tickbar.bg:SetAllPoints(true)
    tickbar.bg:SetVertexColor(0.55, 0.55, 0.55)
    tickbar.bg:SetAlpha(0.5)

    -- TEXT
    tickbar.value = statusbar:CreateFontString(nil, "OVERLAY")
    tickbar.value:SetPoint("LEFT", statusbar, "LEFT", 4, 0)
    tickbar.value:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
    tickbar.value:SetJustifyH("LEFT")
    tickbar.value:SetShadowOffset(1, -1)
    tickbar.value:SetTextColor(1, 1, 1)

    -- DRAGGING
    -- statusbar:RegisterForDrag("LeftButton")
    tickbar:SetScript("OnMouseDown", function(self, button) FiveSecondRuleTick:onMouseDown(button); end)
    tickbar:SetScript("OnMouseUp", function(self, button) FiveSecondRuleTick:onMouseUp(button); end)
    tickbar:SetMovable(true)
    tickbar:SetResizable(true)
    tickbar:EnableMouse(false)
    tickbar:SetClampedToScreen(false)

    tickbar:Hide()
end

-- EVENT HANDLERS
function FiveSecondRuleTick:onMouseDown(button)
    local shiftKey = IsShiftKeyDown()

    if button == "LeftButton" then
        tickbar:StartMoving();
      elseif button == "RightButton" then
        tickbar:StartSizing("BOTTOMRIGHT");
        tickbar.resizing = 1
      end
end

function FiveSecondRuleTick:onMouseUp()    
    tickbar:StopMovingOrSizing();
end

function FiveSecondRule:onMouseDown(button)
    local shiftKey = IsShiftKeyDown()

    if button == "LeftButton" then
        statusbar:StartMoving();
      elseif button == "RightButton" then
        statusbar:StartSizing("BOTTOMRIGHT");
        statusbar.resizing = 1
      end
end

function FiveSecondRule:onMouseUp()
    updateStatusBarFont()
    statusbar:StopMovingOrSizing();
end

function FiveSecondRule:onEvent(self, event, arg1, ...)
    if event == "ADDON_LOADED" then
        if arg1 == "FiveSecondRule" then 
            -- Initialize Settings
            FiveSecondRule_Options = FiveSecondRule_Options or defaults

            CreateStatusBar()
            CreateTickBar()

            if not tickbar:IsUserPlaced() then
                reset()
            end
        end
    end

    if event == "PLAYER_ENTERING_WORLD" then
        PrintHelp()
        updatePlayerMana()
    end

    if event == "CURRENT_SPELL_CAST_CHANGED"  then
        castCounter = castCounter + 1

        if (castCounter == 1) then
             --print("Starting Cast")
             updatePlayerMana()
        elseif (castCounter == 2) then 
            --print("Casting...")
            updatePlayerMana()
        else
            --print("Stopped Cast")
            castCounter = 0
        end
    end   

    if event == "UNIT_SPELLCAST_SUCCEEDED" then
        if getPlayerMana() < currentMana then
            updatePlayerMana()
            mp5StartTime = GetTime() + 5

            --print("SUCCESS - spent mana, start 5s rule")
            statusbar:Show()
        end
    end
end

function FiveSecondRuleFrame:onUpdate(sinceLastUpdate)
    local now = GetTime()
    local newMana = getPlayerMana()

    fullmana = newMana >= getPlayerManaMax()

    if not (now == nil) then 
        self.sinceLastUpdate = (self.sinceLastUpdate or 0) + sinceLastUpdate;
        
        if ( self.sinceLastUpdate >= updateTimerEverySeconds ) then -- in seconds
            self.sinceLastUpdate = 0;

            if (mp5StartTime > 0) then
                local remaining = (mp5StartTime - now)

                if (remaining > 0) then
                    local percentage = remaining/5000*100

                    --print("MP5 in " .. string.format("%.0f", remaining) .. " ms")

                    statusbar:SetValue(remaining)
                    statusbar.value:SetText(string.format("%.1f", remaining).."s")
                else
                    --print("MP5 ACTIVE")
                    mp5StartTime = 0

                    if not unlocked then 
                        statusbar:Hide()
                    end
                end
            end
        end

        if FiveSecondRule_Options.showTicks then
            if fullmana then
                if not unlocked then 
                    tickbar:Hide()  
                end
            else
                if newMana > currentMana then
                    tickbar:Show() 
    
                    manaTickTime = now + manaRegenTime
    
                    updatePlayerMana()
                end
    
                local val = manaTickTime - now
                tickbar:SetValue(val)
            end
        end
        
    end
end

-- HELPER FUNCTIONS
function updatePlayerMana()
    currentMana = getPlayerMana()
end

function getPlayerMana() 
    return UnitPower("player" , 0); -- 0 is mana
end

function getPlayerManaMax()
    return UnitPowerMax("player", 0) -- 0 is mana
end

function modulus(a,b)
    return a - math.floor(a/b)*b
end

function unlock()
    unlocked = true

    statusbar:Show()
    statusbar:EnableMouse(true)

    tickbar:Show()
    tickbar:EnableMouse(true)
    tickbar:SetValue(2)
end

function lock() 
    unlocked = false

    statusbar:Hide()
    statusbar:EnableMouse(false)
    statusbar:StopMovingOrSizing();
    statusbar.resizing = nil
    
    tickbar:Hide()
    tickbar:EnableMouse(false)
    tickbar:StopMovingOrSizing();
    tickbar.resizing = nil
end

function reset()
    resetStatusBar()
    resetTickBar()

    FiveSecondRule_Options.showTicks = true
end

function resetStatusBar()
    local playerFrame = getglobal("PlayerFrame")

    statusbar:SetWidth(117)
    statusbar:SetHeight(11)
    statusbar:SetPoint("TOPLEFT", playerFrame, "TOPLEFT", 107, -68)

    updateStatusBarFont()
end

function resetTickBar()
    local playerFrame = getglobal("PlayerFrame")

    tickbar:SetWidth(117)
    tickbar:SetHeight(2)
    tickbar:SetPoint("TOPLEFT", playerFrame, "TOPLEFT", 107, -63)
end

function updateStatusBarFont()
    local height = statusbar:GetHeight()
    local remainder = modulus(height, 2)
    local px = height - remainder
    statusbar.value:SetFont("Fonts\\FRIZQT__.TTF", px, "OUTLINE")
end

-- COMMANDS
SLASH_FSR1 = '/fsr'; 
function SlashCmdList.FSR(msg, editbox)
     if msg == "unlock" or msg == "Unlock" or msg == "UNLOCK" or msg == "u" or msg == "U" then
         print("Five Second Rule - UNLOCKED.")
         unlock()
      end
     if msg == "lock" or msg == "Lock" or msg == "LOCK" or msg == "l" or msg == "L"  then
        print("Five Second Rule - LOCKED.")
        lock()
     end
     if msg == "reset" then
        print("Five Second Rule - RESET SIZE AND POSITION.")
        reset()
        unlock() 
     end
     if msg == "showticks" then
        print("Five Second Rule - SHOWING TICKS")
        FiveSecondRule_Options.showTicks = true
     end
     if msg == "hideticks" then
        print("Five Second Rule - HIDING TICKS")
        FiveSecondRule_Options.showTicks = false
     end
     if msg == "" or msg == "help" then
        PrintHelp()  
     end
end

-- HELP
function PrintHelp() 
    print("# Five Second Rule")
    print("#    - /fsr unlock (U)   Unlock the frame and enable drag.")
    print("#                                    - Hold LEFT mouse button (on the frame) to move.")
    print("#                                    - Hold RIGHT mouse button (on the frame) to resize.")
    print("#    - /fsr lock (L)     Lock the frame and disable drag.")
    print("#    - /fsr showticks    Show mana regen ticks after the 5-second rule has been fulfilled (until full mana).")
    print("#    - /fsr hideticks    Hide mana regen ticks after the 5-second rule has been fulfilled (until full mana).")
    print("#    - /fsr reset        Resets the position and size of the frame.")
    print("#    - /fsr help         Print this help message.")
    print("# Source: https://github.com/smp4903/wow-classic-five-second-rule")
end