-- CONFIGURE
local ADDON_NAME = "FiveSecondRule"
local NAMESPACE = FiveSecondRule

-- STATE
local frame = nil
local colorPickerStateSet = false

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
    frame.content.showSpark:SetChecked(FiveSecondRule_Options.showSpark == true)
    
    frame.content.barWidth:SetText(tostring(FiveSecondRule_Options.barWidth))
    frame.content.barHeight:SetText(tostring(FiveSecondRule_Options.barHeight))

    frame.content.barLeft:SetText(tostring(FiveSecondRule_Options.barLeft))
    frame.content.barTop:SetText(tostring(FiveSecondRule_Options.barTop))

    local sfgc = FiveSecondRule_Options.statusBarColor
    frame.content.statusBarForegroundColorFrame:SetBackdropColor(sfgc[1], sfgc[2], sfgc[3], sfgc[4])

    local sbgc = FiveSecondRule_Options.statusBarBackgroundColor
    frame.content.statusBarBackgroundColorFrame:SetBackdropColor(sbgc[1], sbgc[2], sbgc[3], sbgc[4])

    local mtfgc = FiveSecondRule_Options.manaTicksColor
    frame.content.manaTicksForegroundColorFrame:SetBackdropColor(mtfgc[1], mtfgc[2], mtfgc[3], mtfgc[4])

    local mtbgc = FiveSecondRule_Options.manaTicksBackgroundColor
    frame.content.manaTicksBackgroundColorFrame:SetBackdropColor(mtbgc[1], mtbgc[2], mtbgc[3], mtbgc[4])

    FiveSecondRule:Update()
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
        local ticks = FiveSecondRule.UIFactory:MakeCheckbox(ADDON_NAME.."Ticks", frame.content, "Check to show when the next mana regen tick will fulfil.")
        ticks.label:SetText("Show Mana Ticks")
        ticks:SetPoint("TOPLEFT", 10, -30)
        ticks:SetScript("OnClick",function(self,button)
            FiveSecondRule_Options.showTicks = self:GetChecked()
        end)
        frame.content.ticks = ticks
    end

    -- FLAT DESIGN
    if (not frame.content.flat) then
        local flat = FiveSecondRule.UIFactory:MakeCheckbox(ADDON_NAME.."flat", frame.content, "Check to make the bar to use a flat color.")
        flat.label:SetText("Flat bars")
        flat:SetPoint("TOPLEFT", 10, -60)
        flat:SetScript("OnClick",function(self,button)
            FiveSecondRule_Options.flat = self:GetChecked()
            FiveSecondRule:Update()
        end)
        frame.content.flat = flat
    end

    -- SHOW TEXT?
    if (not frame.content.showText) then
        local showText = FiveSecondRule.UIFactory:MakeCheckbox(ADDON_NAME.."showText", frame.content, "Check to show text on the bar (seconds left)")
        showText.label:SetText("Show text")
        showText:SetPoint("TOPLEFT", 10, -90)
        showText:SetScript("OnClick",function(self,button)
            FiveSecondRule_Options.showText = self:GetChecked()
            FiveSecondRule:Update()
        end)
        frame.content.showText = showText
    end

    -- SHOW SPARK?
    if (not frame.content.showSpark) then
        local showSpark = FiveSecondRule.UIFactory:MakeCheckbox(ADDON_NAME.."showSpark", frame.content, "Check to show a Spark on the bar")
        showSpark.label:SetText("Show spark")
        showSpark:SetPoint("TOPLEFT", 10, -120)
        showSpark:SetScript("OnClick",function(self,button)
            FiveSecondRule_Options.showSpark = self:GetChecked()
            FiveSecondRule:Update()
        end)
        frame.content.showSpark = showSpark        
    end     

    -- BAR
    local barWidth = FiveSecondRule.UIFactory:MakeEditBox(ADDON_NAME.."CountdownWidth", frame.content, "Width", 75, 25, function(self)
        FiveSecondRule_Options.barWidth = tonumber(self:GetText())
        FiveSecondRule:Update()
    end)
    barWidth:SetPoint("TOPLEFT", 250, -30)
    barWidth:SetCursorPosition(0)
    frame.content.barWidth = barWidth

    local barHeight = FiveSecondRule.UIFactory:MakeEditBox(ADDON_NAME.."CountdownHeight", frame.content, "Height", 75, 25, function(self)
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
    local toggleLock = FiveSecondRule.UIFactory:MakeButton(ADDON_NAME.."LockButton", frame.content, 60, 20, toggleLockText, 14, FiveSecondRule.UIFactory:MakeColor(1,1,1,1), function(self)
        lockToggled(self)
    end)
    toggleLock:SetPoint("BOTTOMLEFT", 12, 12)
    frame.content.toggleLock = toggleLock

    -- RESET BUTTON
    local resetButton = FiveSecondRule.UIFactory:MakeButton(ADDON_NAME.."ResetButton", frame.content, 60, 20, "Reset", 14, FiveSecondRule.UIFactory:MakeColor(1,1,1,1), function(self) 
        if (FiveSecondRule_Options.unlocked) then
            lockToggled(toggleLock)
        end

        FiveSecondRule:reset()
        OptionsPanelFrame:UpdateOptionValues(frame.content)
    end)
    resetButton:SetPoint("TOPRIGHT", -5, 0)
    frame.content.resetButton = resetButton

    -- BAR LEFT
    local barLeft = FiveSecondRule.UIFactory:MakeEditBox(ADDON_NAME.."BarLeft", frame.content, "X (from left)", 75, 25, function(self)
        FiveSecondRule_Options.barLeft = tonumber(self:GetText())
        FiveSecondRule:Update()
    end)
    barLeft:SetPoint("TOPLEFT", 250, -90)
    barLeft:SetCursorPosition(0)
    frame.content.barLeft = barLeft

    -- BAR TOP
    local barTop = FiveSecondRule.UIFactory:MakeEditBox(ADDON_NAME.."BarTop", frame.content, "Y (from top)", 75, 25, function(self)
        FiveSecondRule_Options.barTop = tonumber(self:GetText())
        FiveSecondRule:Update()
    end)
    barTop:SetPoint("TOPLEFT", 400, -90)
    barTop:SetCursorPosition(0)
    frame.content.barTop = barTop

    -- STATUSBAR STYLE TITLE
    frame.content.statusBarTitle = FiveSecondRule.UIFactory:MakeText(frame.content, "Statusbar Style", 16)
    frame.content.statusBarTitle:SetPoint("TOPLEFT", 12, -180)

    -- STATUSBAR COLOR PICKER
    if (not frame.content.statusBarForegroundColorFrame) then
        frame.content.statusBarForegroundColorFrame = FiveSecondRule.UIFactory:MakeColorPicker(ADDON_NAME.."StatusBarColorFrame", frame.content, "Foreground", FiveSecondRule_Options.statusBarColor)
        frame.content.statusBarForegroundColorFrame:SetPoint("TOPLEFT", 12, -220)
        frame.content.statusBarForegroundColorFrame:SetScript("OnMouseDown",  
            function (self, button)
                colorPickerStateSet = false

                local editColor = FiveSecondRule_Options.statusBarColor

                FiveSecondRule.UIFactory:ShowColorPicker(editColor[1], editColor[2], editColor[3], editColor[4], function (restore)
                    if (not colorPickerStateSet) then
                        colorPickerStateSet = true
                        return
                    end

                    FiveSecondRule_Options.statusBarColor = FiveSecondRule.UIFactory:UnpackColor(restore)
                    OptionsPanelFrame:UpdateOptionValues()
                end)
            end
        )
    end

    -- STATUSBAR BACKGROUND COLOR PICKER
    if (not frame.content.statusBarBackgroundColorFrame) then
        frame.content.statusBarBackgroundColorFrame = FiveSecondRule.UIFactory:MakeColorPicker(ADDON_NAME.."StatusBarBackgroundColorFrame",  frame.content, "Background", FiveSecondRule_Options.statusBarBackgroundColor)
        frame.content.statusBarBackgroundColorFrame:SetPoint("TOPLEFT", 100, -220)
        frame.content.statusBarBackgroundColorFrame:SetScript("OnMouseDown",  
            function (self, button)
                colorPickerStateSet = false

                local editColor = FiveSecondRule_Options.statusBarBackgroundColor

                FiveSecondRule.UIFactory:ShowColorPicker(editColor[1], editColor[2], editColor[3], editColor[4], function (restore)
                    if (not colorPickerStateSet) then
                        colorPickerStateSet = true
                        return
                    end

                    FiveSecondRule_Options.statusBarBackgroundColor = FiveSecondRule.UIFactory:UnpackColor(restore)
                    OptionsPanelFrame:UpdateOptionValues()
                end)
            end
        )
    end

    -- MANA TICKS BAR STYLE TITLE
    frame.content.manaTicksTitle = FiveSecondRule.UIFactory:MakeText(frame.content, "Mana Ticks Style", 16)
    frame.content.manaTicksTitle:SetPoint("TOPLEFT", 12, -250)

    -- MANA TICKS BAR COLOR PICKER
    if (not frame.content.manaTicksForegroundColorFrame) then
        frame.content.manaTicksForegroundColorFrame = FiveSecondRule.UIFactory:MakeColorPicker(ADDON_NAME.."ManaTicksColorFrame",  frame.content, "Foreground", FiveSecondRule_Options.manaTicksColor)
        frame.content.manaTicksForegroundColorFrame:SetPoint("TOPLEFT", 12, -320)
        frame.content.manaTicksForegroundColorFrame:SetScript("OnMouseDown",  
            function (self, button)
                colorPickerStateSet = false

                local editColor = FiveSecondRule_Options.manaTicksColor

                FiveSecondRule.UIFactory:ShowColorPicker(editColor[1], editColor[2], editColor[3], editColor[4], function (restore)
                    if (not colorPickerStateSet) then
                        colorPickerStateSet = true
                        return
                    end

                    FiveSecondRule_Options.manaTicksColor = FiveSecondRule.UIFactory:UnpackColor(restore)
                    OptionsPanelFrame:UpdateOptionValues()
                end)
            end
        )
    end

    -- MANA TICKS BAR BACKGROUND COLOR PICKER
    if (not frame.content.manaTicksBackgroundColorFrame) then
        frame.content.manaTicksBackgroundColorFrame = FiveSecondRule.UIFactory:MakeColorPicker(ADDON_NAME.."ManaTicksBackgroundColorFrame", frame.content, "Background",  FiveSecondRule_Options.manaTicksBackgroundColor)
        frame.content.manaTicksBackgroundColorFrame:SetPoint("TOPLEFT", 100, -320)
        frame.content.manaTicksBackgroundColorFrame:SetScript("OnMouseDown",  
            function (self, button)
                colorPickerStateSet = false

                local editColor = FiveSecondRule_Options.manaTicksBackgroundColor

                FiveSecondRule.UIFactory:ShowColorPicker(editColor[1], editColor[2], editColor[3], editColor[4], function (restore)
                    if (not colorPickerStateSet) then
                        colorPickerStateSet = true
                        return
                    end

                    FiveSecondRule_Options.manaTicksBackgroundColor = FiveSecondRule.UIFactory:UnpackColor(restore)
                    OptionsPanelFrame:UpdateOptionValues()
                end)
            end
        )
    end

    -- UPDATE VALUES ON SHOW
    frame:SetScript("OnShow", function(self) OptionsPanelFrame:UpdateOptionValues() end)

    return frame
end

