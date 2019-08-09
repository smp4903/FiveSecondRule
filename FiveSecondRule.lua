-- NAMESPACE: FiveSecondRule
FiveSecondRule = {} 

-- STATE VARIABLES
local unlocked = false
local mp5delay = 5
local castCounter = 0
local mp5StartTime = 0
local updateTimerEverySeconds = 0.05

-- INTERFACE
local FiveSecondRuleFrame = CreateFrame("Frame") -- Root frame
local statusbar = CreateFrame("StatusBar", "Five Second Rule Statusbar", UIParent) -- The actualy visible StatusBar

-- REGISTER EVENTS
FiveSecondRuleFrame:RegisterEvent("ADDON_LOADED")
FiveSecondRuleFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
FiveSecondRuleFrame:RegisterEvent("CURRENT_SPELL_CAST_CHANGED")
FiveSecondRuleFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
FiveSecondRuleFrame:RegisterEvent("UNIT_MAXPOWER")

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

-- EVENT HANDLERS
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
    local height = statusbar:GetHeight()
    local remainder = modulus(height, 2)
    local px = height - remainder
    
    statusbar:StopMovingOrSizing();
    statusbar.value:SetFont("Fonts\\FRIZQT__.TTF", px, "OUTLINE")
end

function FiveSecondRule:onEvent(self, event, arg1, ...)
    if event == "ADDON_LOADED" then
        if arg1 == "FiveSecondRule" then 
            CreateStatusBar()
        end
    end

    if event == "PLAYER_ENTERING_WORLD" then
        PrintHelp()
        updatePlayerMana()
    end

    if event == "UNIT_MAXPOWER" then
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
    self.sinceLastUpdate = (self.sinceLastUpdate or 0) + sinceLastUpdate;
    
        if ( self.sinceLastUpdate >= updateTimerEverySeconds ) then -- in seconds
            self.sinceLastUpdate = 0;

            if (mp5StartTime > 0) then
                local now = GetTime()
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
end

-- HELPER FUNCTIONS
function updatePlayerMana()
    currentMana = getPlayerMana()
end

function getPlayerMana() 
    return UnitPower("player" , 0); -- 0 is mana
end

function modulus(a,b)
    return a - math.floor(a/b)*b
end

function unlock()
    unlocked = true
    statusbar:Show()
    statusbar:EnableMouse(true)
end

function lock() 
    unlocked = false
    statusbar:Hide()
    statusbar:EnableMouse(false)
    statusbar:StopMovingOrSizing();
	statusbar.resizing = nil
end

function reset()
    statusbar:SetWidth(200)
    statusbar:SetHeight(20)
    statusbar:SetPoint("CENTER", UIParent, "CENTER", 0, 100)

    unlock()
end

-- COMMANDS
SLASH_FSR1 = '/fsr'; 
function SlashCmdList.FSR(msg, editbox)
     if msg == "unlock" or msg == "Unlock" or msg == "UNLOCK" or msg == "u" or msg == "U" then
         print("Five Second Rule - UNLOCKED.");
         unlock()
      end
     if msg == "lock" or msg == "Lock" or msg == "LOCK" or msg == "l" or msg == "L"  then
        print("Five Second Rule - LOCKED.");
        lock()
     end
     if msg == "reset" then
        print("Five Second Rule - RESET SIZE AND POSITION.");
        reset()   
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
    print("#    - /fsr reset        Resets the position and size of the frame.")
    print("#    - /fsr help         Print this help message.")
    print("# Source: https://github.com/smp4903/wow-classic-five-second-rule")
end
