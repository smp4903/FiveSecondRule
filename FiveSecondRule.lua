-- NAMESPACE: FiveSecondRule
local ADDON_NAME = "FiveSecondRule"
FiveSecondRule = {} 
FiveSecondRuleTick = {}

local defaults = {
    ["showTicks"] = true,

    ["barWidth"] = 117,
    ["barHeight"] = 11,

    ["barTop"] = -68,
    ["barLeft"] = 90
}

-- CONSTANTS
local manaRegenTime = 2
local updateTimerEverySeconds = 0.05
local mp5delay = 5

-- STATE VARIABLES
local gainingMana = false
local unlocked = false
local fullmana = false
local castCounter = 0
local mp5StartTime = 0
local manaTickTime = 0

-- INTERFACE
local FiveSecondRuleFrame = CreateFrame("Frame") -- Root frame
local statusbar = CreateFrame("StatusBar", "Five Second Rule Statusbar", UIParent) -- StatusBar for the 5SR tracker
local tickbar = CreateFrame("StatusBar", "Five Second Rule Statusbar - Mana Ticks", UIParent) -- StatusBar for tracking mana ticks after 5SR is fulfilled

-- REGISTER EVENTS
FiveSecondRuleFrame:RegisterEvent("ADDON_LOADED")
FiveSecondRuleFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
FiveSecondRuleFrame:RegisterEvent("CURRENT_SPELL_CAST_CHANGED")
FiveSecondRuleFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
FiveSecondRuleFrame:RegisterEvent("PLAYER_LOGIN")

-- REGISTER EVENT LISTENERS
FiveSecondRuleFrame:SetScript("OnUpdate", function(self, sinceLastUpdate) FiveSecondRuleFrame:onUpdate(sinceLastUpdate); end);
FiveSecondRuleFrame:SetScript("OnEvent", function(self, event, arg1, ...) FiveSecondRule:onEvent(self, event, arg1, ...) end);

-- INITIALIZATION
function FiveSecondRule:Init()
    -- Initialize FiveSecondRule_Options
    FiveSecondRule:LoadOptions()

    -- Create UI
    FiveSecondRule:CreateStatusBar()
    FiveSecondRule:CreateTickBar()
end

function FiveSecondRule:LoadOptions()
    FiveSecondRule_Options = FiveSecondRule_Options or FiveSecondRule:deepcopy(defaults)

    for key,value in pairs(defaults) do
        if (FiveSecondRule_Options[key] == nil) then
            FiveSecondRule_Options[key] = value
        end
    end
end

-- UI INFLATION
function FiveSecondRule:CreateStatusBar()
    -- POSITION, SIZE
    statusbar:ClearAllPoints()
    statusbar:SetWidth(FiveSecondRule_Options.barWidth)
    statusbar:SetHeight(FiveSecondRule_Options.barHeight)
    statusbar:SetPoint("TOPLEFT", playerFrame, "TOPLEFT", FiveSecondRule_Options.barLeft, FiveSecondRule_Options.barTop)

    -- DRAGGING
    statusbar:SetScript("OnMouseDown", function(self, button) FiveSecondRule:onMouseDown(button); end)
    statusbar:SetScript("OnMouseUp", function(self, button) FiveSecondRule:onMouseUp(button); end)
    statusbar:SetMovable(true)
    statusbar:SetResizable(true)
    statusbar:EnableMouse(false)
    statusbar:SetClampedToScreen(true)

    -- VALUE
    statusbar:SetMinMaxValues(0, mp5delay)

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

    FiveSecondRule:updateStatusBarFont()

    statusbar:Hide()
end

function FiveSecondRule:CreateTickBar() 
    -- POSITION, SIZE
    tickbar:SetWidth(FiveSecondRule_Options.barWidth)
    tickbar:SetHeight(FiveSecondRule_Options.barHeight)
    tickbar:SetPoint("TOPLEFT", playerFrame, "TOPLEFT", FiveSecondRule_Options.barLeft, FiveSecondRule_Options.barTop)

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
    tickbar:SetStatusBarColor(0.95, 0.95, 0.95)

    -- BACKGROUND
    tickbar.bg = tickbar:CreateTexture(nil, "BACKGROUND")
    tickbar.bg:SetTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
    tickbar.bg:SetAllPoints(true)
    tickbar.bg:SetVertexColor(0.55, 0.55, 0.55)
    tickbar.bg:SetAlpha(0.8)

    -- TEXT
    tickbar.value = tickbar:CreateFontString(nil, "OVERLAY")
    tickbar.value:SetPoint("LEFT", tickbar, "LEFT", 4, 0)
    tickbar.value:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
    tickbar.value:SetJustifyH("LEFT")
    tickbar.value:SetShadowOffset(1, -1)
    tickbar.value:SetTextColor(1, 1, 1, 1)

    FiveSecondRule:updateTickBarFont()

    tickbar:Hide()
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
    FiveSecondRule:updateStatusBarFont()
    statusbar:StopMovingOrSizing();

    tickbar:StopMovingOrSizing()
    tickbar:SetUserPlaced(false)
    tickbar:ClearAllPoints()
    tickbar:SetPoint("TOPLEFT", statusbar, "TOPLEFT", 0, 0)
    tickbar:SetUserPlaced(true)
    tickbar:Hide()
end

function FiveSecondRule:onEvent(self, event, arg1, ...)
    if event == "ADDON_LOADED" then
        if arg1 == "FiveSecondRule" then 
            FiveSecondRule:Init()
        end
    end

    if event == "PLAYER_LOGIN" then
        local loader = CreateFrame('Frame', nil, InterfaceOptionsFrame)
        loader:SetScript('OnShow', function(self)
            self:SetScript('OnShow', nil)

            if not FiveSecondRuleFrame.optionsPanel then
                FiveSecondRuleFrame.optionsPanel = FiveSecondRuleFrame:CreateGUI("FiveSecondRule")
                InterfaceOptions_AddCategory(FiveSecondRuleFrame.optionsPanel);
            end
        end)
    end

    if event == "PLAYER_ENTERING_WORLD" then
        PrintHelp()
        FiveSecondRule:updatePlayerMana()
    end

    if event == "CURRENT_SPELL_CAST_CHANGED"  then
        castCounter = castCounter + 1

        if (castCounter == 1) then
             --print("Starting Cast")
             FiveSecondRule:updatePlayerMana()
        elseif (castCounter == 2) then 
            --print("Casting...")
            FiveSecondRule:updatePlayerMana()
        else
            --print("Stopped Cast")
            castCounter = 0
        end
    end   

    if event == "UNIT_SPELLCAST_SUCCEEDED" then
        if FiveSecondRule:getPlayerMana() < currentMana then
            gainingMana = false
            
            FiveSecondRule:updatePlayerMana()
            mp5StartTime = GetTime() + 5

            --print("SUCCESS - spent mana, start 5s rule")
            
            tickbar:Hide()
            statusbar:Show()
        end
    end
end

function FiveSecondRuleFrame:onUpdate(sinceLastUpdate)
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
                    statusbar:SetValue(remaining)
                    statusbar.value:SetText(string.format("%.1f", remaining).."s")
                else
                    gainingMana = true
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
                if gainingMana then
                    if newMana > currentMana then
                        tickbar:Show() 
        
                        manaTickTime = now + manaRegenTime
        
                        FiveSecondRule:updatePlayerMana()
                    end
        
                    local val = manaTickTime - now
                    tickbar:SetValue(manaRegenTime - val)
                    tickbar.value:SetText(string.format("%.1f", val).."s")
                end
            end
        end
        
    end
end

-- HELPER FUNCTIONS

function FiveSecondRule:updateStatusBarFont()
    local height = statusbar:GetHeight()
    local remainder = FiveSecondRule:modulus(height, 2)
    local px = height - remainder
    statusbar.value:SetFont("Fonts\\FRIZQT__.TTF", px, "OUTLINE")
end

function FiveSecondRule:updateTickBarFont()
    local height = tickbar:GetHeight()
    local remainder = FiveSecondRule:modulus(height, 2)
    local px = height - remainder
    tickbar.value:SetFont("Fonts\\FRIZQT__.TTF", px, "OUTLINE")
end

function FiveSecondRule:updatePlayerMana()
    currentMana = FiveSecondRule:getPlayerMana()
end

function FiveSecondRule:getPlayerMana() 
    return UnitPower("player" , 0); -- 0 is mana
end

function FiveSecondRule:getPlayerManaMax()
    return UnitPowerMax("player", 0) -- 0 is mana
end

function FiveSecondRule:modulus(a,b)
    return a - math.floor(a/b)*b
end

function FiveSecondRule:deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function FiveSecondRule:unlock()
    unlocked = true

    statusbar:Show()
    statusbar:EnableMouse(true)
    statusbar:SetValue(2)

    tickbar:Hide()
end

function FiveSecondRule:lock() 
    unlocked = false

    statusbar:Hide()
    statusbar:EnableMouse(false)
    statusbar:StopMovingOrSizing();
    statusbar.resizing = nil
end

function FiveSecondRule:reset()
    tickbar:SetUserPlaced(false)
    statusbar:SetUserPlaced(false)

    FiveSecondRule_Options = FiveSecondRule:deepcopy(defaults)

    FiveSecondRule:Init()
end

-- COMMANDS
SLASH_FSR1 = '/fsr'; 
function SlashCmdList.FSR(msg, editbox)
     if msg:lower() == "unlock" or msg:lower() == "u" then
         print("Five Second Rule - UNLOCKED.")
         FiveSecondRule:unlock()
      end
     if msg:lower() == "lock" or msg:lower() == "l" then
        print("Five Second Rule - LOCKED.")
        FiveSecondRule:lock()
     end
     if msg:lower() == "reset" then
        print("Five Second Rule - RESET ALL SETTINGS")
        FiveSecondRule:reset()
     end
     if msg:lower() == "" or msg == "help" then
        FiveSecondRule:PrintHelp()  
     end
end

-- HELP
function FiveSecondRule:PrintHelp() 
    print("# Five Second Rule")
    print("#    - /fsr FiveSecondRule:unlock (U)   FiveSecondRule:unlock the frame and enable drag.")
    print("#                         - Hold LEFT mouse button (on the frame) to move.")
    print("#                         - Hold RIGHT mouse button (on the frame) to resize.")
    print("#    - /fsr lock (L)     Lock the frame and disable drag.")
    print("#    - /fsr reset        Resets all settings.")
    print("#    - /fsr help         Print this help message.")
    print("# Source: https://github.com/smp4903/five-second-rule")
end

-- OPTIONS

function FiveSecondRule:UpdateOptionValues(content)
    content.ticks:SetChecked(FiveSecondRule_Options.showTicks)
    
    content.barWidth:SetText(tostring(FiveSecondRule_Options.barWidth))
    content.barHeight:SetText(tostring(FiveSecondRule_Options.barHeight))
    
    content.barWidth:SetText(tostring(FiveSecondRule_Options.barWidth))
    content.barHeight:SetText(tostring(FiveSecondRule_Options.barHeight))
end

function FiveSecondRuleFrame:CreateGUI(name, parent)
    local frame = CreateFrame("Frame", nil, InterfaceOptionsFrame)
    frame:Hide()

    frame.parent = parent
    frame.name = name
 
    -- TITLE
    local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	label:SetPoint("TOPLEFT", 10, -15)
	label:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", 10, -45)
	label:SetJustifyH("LEFT")
    label:SetJustifyV("TOP")
    label:SetText(name)

    -- ROOT
	local content = CreateFrame("Frame", "CADOptionsContent", frame)
	content:SetPoint("TOPLEFT", 10, -10)
    content:SetPoint("BOTTOMRIGHT", -10, 10)

    frame.content = content

    -- WHETHER OR NOT TO SHOW THE MANA TICKS BAR
    local ticks = FiveSecondRule:MakeCheckbox(nil, content, "Check to show when the next mana regen tick will fulfil.")
    ticks.label:SetText("Show Mana Ticks")
    ticks:SetPoint("TOPLEFT", 10, -30)
    content.ticks = ticks
    ticks:SetScript("OnClick",function(self,button)
        FiveSecondRule_Options.showTicks = self:GetChecked()
    end)

    -- BAR
    local barWidth = FiveSecondRule:MakeEditBox(nil, content, "Countdown Width", 75, 25, function(self)
        FiveSecondRule_Options.barWidth = tonumber(self:GetText())
    end)
    barWidth:SetPoint("TOPLEFT", 250, -30)
    barWidth:SetCursorPosition(0)
    content.barWidth = barWidth

    local barHeight = FiveSecondRule:MakeEditBox(nil, content, "Countdown Height", 75, 25, function(self)
        FiveSecondRule_Options.barHeight = tonumber(self:GetText())
    end)
    barHeight:SetPoint("TOPLEFT", 400, -30)
    barHeight:SetCursorPosition(0)
    content.barHeight = barHeight

    -- LOCK / UNLOCK BUTTON
    local function lockToggled(self)
        if (unlocked) then 
            FiveSecondRule:lock() 
            self:SetText("Unlock")
        else 
            FiveSecondRule:unlock() 
            self:SetText("Lock")
        end 
    end

    local toggleLockText = (unlocked and "Lock" or "Unlock")
    local toggleLock = FiveSecondRule:MakeButton("LockButton", content, 60, 20, toggleLockText, 14, FiveSecondRule:MakeColor(1,1,1,1), function(self)
        lockToggled(self)
    end)
    toggleLock:SetPoint("TOPLEFT", 10, -120)
    content.toggleLock = toggleLock

    -- RESET BUTTON
    local resetButton = FiveSecondRule:MakeButton("ResetButton", content, 60, 20, "Reset", 14, FiveSecondRule:MakeColor(1,1,1,1), function(self) 
        FiveSecondRule:reset()
         
        if (unlocked) then
            lockToggled(toggleLock)
        end
    end)
    resetButton:SetPoint("TOPRIGHT", -30, -120)
    content.resetButton = resetButton

    -- UPDATE VALUES ON SHOW
    frame:SetScript("OnShow", function(self) FiveSecondRule:UpdateOptionValues(content) end)

    return frame
end

-- UI CREATORS

function FiveSecondRule:MakeCheckbox(name, parent, tooltip_text)
    local cb = CreateFrame("CheckButton", name, parent, "UICheckButtonTemplate")
    cb:SetWidth(25)
    cb:SetHeight(25)
    cb:Show()

    local cblabel = cb:CreateFontString(nil, "OVERLAY")
    cblabel:SetFontObject("GameFontHighlight")
    cblabel:SetPoint("LEFT", cb,"RIGHT", 5,0)
    cb.label = cblabel

    cb.tooltip = tooltip_text

    return cb
end

function FiveSecondRule:MakeText(parent, text, size)
    local text_obj = parent:CreateFontString(nil, "ARTWORK")
    text_obj:SetFont("Fonts/FRIZQT__.ttf", size)
    text_obj:SetJustifyV("CENTER")
    text_obj:SetJustifyH("CENTER")
    text_obj:SetText(text)
    return text_obj
end

function FiveSecondRule:MakeEditBox(name, parent, title, w, h, enter_func)
    local edit_box_obj = CreateFrame("EditBox", name, parent)
    edit_box_obj.title_text = FiveSecondRule:MakeText(edit_box_obj, title, 12)
    edit_box_obj.title_text:SetPoint("TOP", 0, 12)
    edit_box_obj:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true,
        tileSize = 26,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4}
    })
    edit_box_obj:SetBackdropColor(0,0,0,1)
    edit_box_obj:SetSize(w, h)
    edit_box_obj:SetMultiLine(false)
    edit_box_obj:SetAutoFocus(false)
    edit_box_obj:SetMaxLetters(4)
    edit_box_obj:SetJustifyH("CENTER")
	edit_box_obj:SetJustifyV("CENTER")
    edit_box_obj:SetFontObject(GameFontNormal)
    edit_box_obj:SetScript("OnEnterPressed", function(self)
        enter_func(self)
        self:ClearFocus()
    end)
    edit_box_obj:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)
    return edit_box_obj
end

function FiveSecondRule:MakeButton(name, parent, width, height, text, textSize, color, on_click_func)
    local button = CreateFrame('Button', ADDON_NAME .. name, parent, "UIPanelButtonTemplate")
    button:SetSize(width, height)
    button:SetText(text)
    button:SetScript('OnClick', on_click_func)
    return button
end

function FiveSecondRule:MakeColor(r,g,b,a) 
    return {r = r, g = g, b = b, a = a}
end