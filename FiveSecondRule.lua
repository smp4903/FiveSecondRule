-- NAMESPACE: FiveSecondRule
FiveSecondRule = {} 
FiveSecondRuleTick = {}

local defaults = {
    ["showTicks"] = true,

    ["statusBarWidth"] = 117,
    ["statusBarHeight"] = 11,
    ["statusBarTop"] = -68,
    ["statusBarLeft"] = 90,

    ["manaTickWidth"] = 117,
    ["manaTickHeight"] = 11,
    ["manaTickTop"] = -68,
    ["manaTickLeft"] = 90,
}

-- STATE VARIABLES
local gainingMana = false
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
FiveSecondRuleFrame:RegisterEvent("PLAYER_LOGIN")

-- REGISTER EVENT LISTENERS
FiveSecondRuleFrame:SetScript("OnUpdate", function(self, sinceLastUpdate) FiveSecondRuleFrame:onUpdate(sinceLastUpdate); end);
FiveSecondRuleFrame:SetScript("OnEvent", function(self, event, arg1, ...) FiveSecondRule:onEvent(self, event, arg1, ...) end);

-- UI INFLATION
function CreateStatusBar()
    -- POSITION, SIZE
    statusbar:SetWidth(FiveSecondRule_Options.statusBarWidth)
    statusbar:SetHeight(FiveSecondRule_Options.statusBarHeight)
    statusbar:SetPoint("TOPLEFT", playerFrame, "TOPLEFT", FiveSecondRule_Options.statusBarLeft, FiveSecondRule_Options.statusBarTop)

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

    updateStatusBarFont()

    statusbar:Hide()
end

function CreateTickBar() 
    -- POSITION, SIZE
    tickbar:SetWidth(FiveSecondRule_Options.manaTickWidth)
    tickbar:SetHeight(FiveSecondRule_Options.manaTickHeight)
    tickbar:SetPoint("TOPLEFT", playerFrame, "TOPLEFT", FiveSecondRule_Options.manaTickLeft, FiveSecondRule_Options.manaTickTop)

    -- DRAGGING
    tickbar:SetScript("OnMouseDown", function(self, button) FiveSecondRuleTick:onMouseDown(button); end)
    tickbar:SetScript("OnMouseUp", function(self, button) FiveSecondRuleTick:onMouseUp(button); end)
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

    updateTickBarFont()

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
            -- Initialize FiveSecondRule_Options
            FiveSecondRule_Options = FiveSecondRule_Options or defaults
            FiveSecondRule_Options.manaTickHeight = 11

            CreateStatusBar()
            CreateTickBar()
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
            gainingMana = false
            
            updatePlayerMana()
            mp5StartTime = GetTime() + 5

            --print("SUCCESS - spent mana, start 5s rule")
            
            tickbar:Hide()
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
        
                        updatePlayerMana()
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
    statusbar:SetValue(2)

    tickbar:Show()
    tickbar:EnableMouse(true)
    tickbar:SetValue(1)
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
    FiveSecondRule_Options = defaults

    resetStatusBar()
    resetTickBar()
end

function resetStatusBar()
    local playerFrame = getglobal("PlayerFrame")

    statusbar:SetUserPlaced(false)
    statusbar:SetWidth(FiveSecondRule_Options.statusBarWidth)
    statusbar:SetHeight(FiveSecondRule_Options.statusBarHeight)
    statusbar:SetPoint("TOPLEFT", playerFrame, "TOPLEFT", FiveSecondRule_Options.statusBarLeft, FiveSecondRule_Options.statusBarTop)

    updateStatusBarFont()

end

function resetTickBar()
    local playerFrame = getglobal("PlayerFrame")

    tickbar:SetUserPlaced(false)
    tickbar:SetWidth(FiveSecondRule_Options.manaTickWidth)
    tickbar:SetHeight(FiveSecondRule_Options.manaTickHeight)
    tickbar:SetPoint("TOPLEFT", playerFrame, "TOPLEFT", FiveSecondRule_Options.manaTickLeft, FiveSecondRule_Options.manaTickTop)

    updateTickBarFont()
end

function updateStatusBarFont()
    local height = statusbar:GetHeight()
    local remainder = modulus(height, 2)
    local px = height - remainder
    statusbar.value:SetFont("Fonts\\FRIZQT__.TTF", px, "OUTLINE")
end


function updateTickBarFont()
    local height = tickbar:GetHeight()
    local remainder = modulus(height, 2)
    local px = height - remainder
    tickbar.value:SetFont("Fonts\\FRIZQT__.TTF", px, "OUTLINE")
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
        print("Five Second Rule - RESET ALL SETTINGS")
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
    print("#                         - Hold LEFT mouse button (on the frame) to move.")
    print("#                         - Hold RIGHT mouse button (on the frame) to resize.")
    print("#    - /fsr lock (L)     Lock the frame and disable drag.")
    print("#    - /fsr reset        Resets all settings.")
    print("#    - /fsr help         Print this help message.")
    print("# Source: https://github.com/smp4903/wow-classic-five-second-rule")
end

-- OPTIONS

function UpdateOptionValues(content)
    content.ticks:SetChecked(FiveSecondRule_Options.showTicks)
    
    content.statusBarWidth:SetText(tostring(FiveSecondRule_Options.statusBarWidth))
    content.statusBarHeight:SetText(tostring(FiveSecondRule_Options.statusBarHeight))
    
    content.manaTickWidth:SetText(tostring(FiveSecondRule_Options.manaTickWidth))
    content.manaTickHeight:SetText(tostring(FiveSecondRule_Options.manaTickHeight))
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
    local ticks = MakeCheckbox(nil, content, "Check to show when the next mana regen tick will fulfil.")
    ticks.label:SetText("Show Mana Ticks")
    ticks:SetPoint("TOPLEFT", 10, -30)
    content.ticks = ticks
    ticks:SetScript("OnClick",function(self,button)
        FiveSecondRule_Options.showTicks = not FiveSecondRule_Options.showTicks
    end)

    -- STATUS BAR
    local statusBarWidth = MakeEditBox(nil, content, "Countdown Width", 75, 25, StatusBarWidthOnEnter)
    statusBarWidth:SetPoint("TOPLEFT", 250, -30)
    statusBarWidth:SetCursorPosition(0)
    content.statusBarWidth = statusBarWidth

    local statusBarHeight = MakeEditBox(nil, content, "Countdown Height", 75, 25, StatusBarHeightOnEnter)
    statusBarHeight:SetPoint("TOPLEFT", 400, -30)
    statusBarHeight:SetCursorPosition(0)
    content.statusBarHeight = statusBarHeight

    -- MANA TICK BAR
    local manaTickWidth = MakeEditBox(nil, content, "Mana Ticks Width", 75, 25, ManaTickBarWidthOnEnter)
    manaTickWidth:SetPoint("TOPLEFT", 250, -90)
    manaTickWidth:SetCursorPosition(0)
    content.manaTickWidth = manaTickWidth

    local manaTickHeight = MakeEditBox(nil, content, "Mana Ticks Height", 75, 25, ManaTickBarHeightOnEnter)
    manaTickHeight:SetPoint("TOPLEFT", 400, -90)
    manaTickHeight:SetCursorPosition(0)
    content.manaTickHeight = manaTickHeight

    -- UPDATE VALUES ON SHOW
    frame:SetScript("OnShow", function(self) UpdateOptionValues(content) end)

    return frame
end

function StatusBarWidthOnEnter(self)
    FiveSecondRule_Options.statusBarWidth = tonumber(self:GetText())
end

function StatusBarHeightOnEnter(self)
    FiveSecondRule_Options.statusBarHeight = tonumber(self:GetText())
end

function ManaTickBarWidthOnEnter(self)
    FiveSecondRule_Options.manaTickWidth = tonumber(self:GetText())
end

function ManaTickBarHeightOnEnter(self)
    FiveSecondRule_Options.manaTickHeight = tonumber(self:GetText())
end

-- UTILITIES

function MakeCheckbox(name, parent, tooltip_text)
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

function MakeText(parent, text, size)
    local text_obj = parent:CreateFontString(nil, "ARTWORK")
    text_obj:SetFont("Fonts/FRIZQT__.ttf", size)
    text_obj:SetJustifyV("CENTER")
    text_obj:SetJustifyH("CENTER")
    text_obj:SetText(text)
    return text_obj
end

function MakeEditBox(name, parent, title, w, h, enter_func)
    local edit_box_obj = CreateFrame("EditBox", name, parent)
    edit_box_obj.title_text = MakeText(edit_box_obj, title, 12)
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

function MakeColorPicker(g_name, parent, r, g, b, a, text, on_click_func)
    local color_picker = CreateFrame('Button', addon_name .. g_name, parent)
    color_picker:SetSize(15, 15)
    color_picker.normal = color_picker:CreateTexture(nil, 'BACKGROUND')
    color_picker.normal:SetColorTexture(1, 1, 1, 1)
    color_picker.normal:SetPoint('TOPLEFT', -1, 1)
    color_picker.normal:SetPoint('BOTTOMRIGHT', 1, -1)
    color_picker.foreground = color_picker:CreateTexture(nil, 'ARTWORK')
    color_picker.foreground:SetColorTexture(r, g, b, a)
    color_picker.foreground:SetAllPoints()
    color_picker:SetNormalTexture(color_picker.normal)
    color_picker:SetScript('OnClick', on_click_func)
    color_picker.text = addon_data.config.TextFactory(color_picker, text, 12)
    color_picker.text:SetPoint('LEFT', 25, 0)
    return color_picker
end