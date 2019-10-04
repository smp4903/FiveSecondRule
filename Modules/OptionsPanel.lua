-- CONFIGURE
local ADDON_NAME = "FiveSecondRule"
local NAMESPACE = FiveSecondRule

-- STATE
local frame = nil

-- LOADER
local OptionsPanelFrame = CreateFrame("Frame", ADDON_NAME.."OptionsPanelFrame")

-- EXPOSE OPTIONS PANEL TO NAMESPACE
NAMESPACE.OptionsPanelFrame = OptionsPanelFrame

OptionsPanelFrame:RegisterEvent("PLAYER_LOGIN")
OptionsPanelFrame:SetScript("OnEvent", 
    function(self, event, arg1, ...)
        if event == "PLAYER_LOGIN" then
            local loader = CreateFrame('Frame', nil, InterfaceOptionsFrame)
            loader:SetScript('OnShow', function(self)
                self:SetScript('OnShow', nil)

                if not OptionsPanelFrame.optionsPanel then
                    OptionsPanelFrame.optionsPanel = OptionsPanelFrame:CreateGUI(ADDON_NAME)
                    InterfaceOptions_AddCategory(OptionsPanelFrame.optionsPanel);
                end
            end)
        end
    end
);

-- LOADING VALUES

function OptionsPanelFrame:UpdateOptionValues()
    frame.content.ticks:SetChecked(FiveSecondRule_Options.showTicks == true)
    frame.content.flat:SetChecked(FiveSecondRule_Options.flat == true)
    frame.content.showText:SetChecked(FiveSecondRule_Options.showText == true)
    
    frame.content.barWidth:SetText(tostring(FiveSecondRule_Options.barWidth))
    frame.content.barHeight:SetText(tostring(FiveSecondRule_Options.barHeight))
    
    frame.content.barLeft:SetText(tostring(FiveSecondRule_Options.barLeft))
    frame.content.barTop:SetText(tostring(FiveSecondRule_Options.barTop))
end

-- GUI
function OptionsPanelFrame:CreateGUI(name, parent)
    if (not frame) then
        frame = CreateFrame("Frame", nil, InterfaceOptionsFrame)
    end

    frame:Hide()
    frame.parent = parent
    frame.name = name
 
    -- TITLE
    if (not frame.title) then
        local title = frame:CreateFontString(ADDON_NAME.."Title", "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOPLEFT", 10, -15)
        title:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", 10, -45)
        title:SetJustifyH("LEFT")
        title:SetJustifyV("TOP")
        title:SetText(name)
        frame.title = title
    end

    -- ROOT
    if (not frame.content) then
        local content = CreateFrame("Frame", "CADOptionsContent", frame)
        content:SetPoint("TOPLEFT", 10, -10)
        content:SetPoint("BOTTOMRIGHT", -10, 10)
        frame.content = content
    end

    -- WHETHER OR NOT TO SHOW THE MANA TICKS BAR
    if (not frame.content.ticks) then
        local ticks = UIFactory:MakeCheckbox(ADDON_NAME.."Ticks", frame.content, "Check to show when the next mana regen tick will fulfil.")
        ticks.label:SetText("Show Mana Ticks")
        ticks:SetPoint("TOPLEFT", 10, -30)
        ticks:SetScript("OnClick",function(self,button)
            FiveSecondRule_Options.showTicks = self:GetChecked()
        end)
        frame.content.ticks = ticks
    end 

    -- FLAT DESIGN
    if (not frame.content.flat) then
        local flat = UIFactory:MakeCheckbox(ADDON_NAME.."flat", frame.content, "Check to make the bar to use a flat color.")
        flat.label:SetText("Flat bar")
        flat:SetPoint("TOPLEFT", 10, -60)
        flat:SetScript("OnClick",function(self,button)
            FiveSecondRule_Options.flat = self:GetChecked()
            FiveSecondRule:Update()
        end)
        frame.content.flat = flat        
    end     

    -- SHOW TEXT?
    if (not frame.content.showText) then
        local showText = UIFactory:MakeCheckbox(ADDON_NAME.."showText", frame.content, "Check to show text on the bar (seconds left)")
        showText.label:SetText("Show text")
        showText:SetPoint("TOPLEFT", 10, -90)
        showText:SetScript("OnClick",function(self,button)
            FiveSecondRule_Options.showText = self:GetChecked()
            FiveSecondRule:Update()
        end)
        frame.content.showText = showText        
    end     

    -- BAR
    local barWidth = UIFactory:MakeEditBox(ADDON_NAME.."CountdownWidth", frame.content, "Width", 75, 25, function(self)
        FiveSecondRule_Options.barWidth = tonumber(self:GetText())
        FiveSecondRule:Update()
    end)
    barWidth:SetPoint("TOPLEFT", 250, -30)
    barWidth:SetCursorPosition(0)
    frame.content.barWidth = barWidth

    local barHeight = UIFactory:MakeEditBox(ADDON_NAME.."CountdownHeight", frame.content, "Height", 75, 25, function(self)
        FiveSecondRule_Options.barHeight = tonumber(self:GetText())
        FiveSecondRule:Update()
    end)
    barHeight:SetPoint("TOPLEFT", 400, -30)
    barHeight:SetCursorPosition(0)
    frame.content.barHeight = barHeight

    -- LOCK / UNLOCK BUTTON
    local function lockToggled(self)
        if (FiveSecondRule_Options.unlocked) then 
            FiveSecondRule:lock() 
            self:SetText("Unlock")
        else 
            FiveSecondRule:unlock() 
            self:SetText("Lock")
        end 
    end

    local toggleLockText = (FiveSecondRule_Options.unlocked and "Lock" or "Unlock")
    local toggleLock = UIFactory:MakeButton(ADDON_NAME.."LockButton", frame.content, 60, 20, toggleLockText, 14, UIFactory:MakeColor(1,1,1,1), function(self)
        lockToggled(self)
    end)
    toggleLock:SetPoint("TOPLEFT", 10, -150)
    frame.content.toggleLock = toggleLock

    -- RESET BUTTON
    local resetButton = UIFactory:MakeButton(ADDON_NAME.."ResetButton", frame.content, 60, 20, "Reset", 14, UIFactory:MakeColor(1,1,1,1), function(self) 
        if (FiveSecondRule_Options.unlocked) then
            lockToggled(toggleLock)
        end

        FiveSecondRule:reset()
        OptionsPanelFrame:UpdateOptionValues(frame.content)
    end)
    resetButton:SetPoint("TOPRIGHT", -15, -150)
    frame.content.resetButton = resetButton

    -- BAR LEFT
    local barLeft = UIFactory:MakeEditBox(ADDON_NAME.."BarLeft", frame.content, "X (from left)", 75, 25, function(self)
        FiveSecondRule_Options.barLeft = tonumber(self:GetText())
        FiveSecondRule:Update()
    end)
    barLeft:SetPoint("TOPLEFT", 250, -90)
    barLeft:SetCursorPosition(0)
    frame.content.barLeft = barLeft

    -- BAR TOP
    local barTop = UIFactory:MakeEditBox(ADDON_NAME.."BarTop", frame.content, "Y (from top)", 75, 25, function(self)
        FiveSecondRule_Options.barTop = tonumber(self:GetText())
        FiveSecondRule:Update()
    end)
    barTop:SetPoint("TOPLEFT", 400, -90)
    barTop:SetCursorPosition(0)
    frame.content.barTop = barTop


    -- UPDATE VALUES ON SHOW
    frame:SetScript("OnShow", function(self) OptionsPanelFrame:UpdateOptionValues() end)

    return frame
end
