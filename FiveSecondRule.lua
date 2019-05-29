

-- SetScript("PLAYER_ENTERING_WORLD", FiveSecondRule:GetFrame())
-- RegisterEvent("PLAYER_ENTERING_WORLD")

FiveSecondRule = {} -- Global Functions

local FiveSecondRuleFrame = CreateFrame("Frame")
local mp5delay = 5
local castCounter = 0
local mp5StartTime = 0
local updateTimerEverySeconds = 0.05
local statusbar = CreateFrame("StatusBar", nil, UIParent)

FiveSecondRuleFrame:SetScript("OnUpdate", function(self, sinceLastUpdate) FiveSecondRuleFrame:onUpdate(sinceLastUpdate); end);

FiveSecondRuleFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
FiveSecondRuleFrame:RegisterEvent("CURRENT_SPELL_CAST_CHANGED")
FiveSecondRuleFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")

FiveSecondRuleFrame:SetScript("OnEvent",
    function(self, event, ...)
        if event == "PLAYER_ENTERING_WORLD" then
            CreateStatusBar()
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
)

function updatePlayerMana()
    currentMana = getPlayerMana()
end

function getPlayerMana() 
    return UnitPower("player" , 0); -- 0 is mana
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
                    print("MP5 ACTIVE")
                    message("MP5 Active!")
                    mp5StartTime = 0
                    statusbar:Hide()
                end


            end
        end


end


function CreateStatusBar()
    statusbar:SetWidth(200)
    statusbar:SetHeight(20)
    statusbar:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
    statusbar:SetMinMaxValues(0, mp5delay)

    statusbar:SetStatusBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
    statusbar:GetStatusBarTexture():SetHorizTile(false)
    statusbar:GetStatusBarTexture():SetVertTile(false)
    statusbar:SetStatusBarColor(0, 0, 0.95)

    statusbar.bg = statusbar:CreateTexture(nil, "BACKGROUND")
    statusbar.bg:SetTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
    statusbar.bg:SetAllPoints(true)
    statusbar.bg:SetVertexColor(0, 0, 0.55)
    statusbar.bg:SetAlpha(0.5)

    statusbar.value = statusbar:CreateFontString(nil, "OVERLAY")
    statusbar.value:SetPoint("LEFT", statusbar, "LEFT", 4, 0)
    statusbar.value:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
    statusbar.value:SetJustifyH("LEFT")
    statusbar.value:SetShadowOffset(1, -1)
    statusbar.value:SetTextColor(1, 1, 1)

    statusbar:Hide()
end