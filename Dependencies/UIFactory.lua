FiveSecondRule.UIFactory = {} 

function FiveSecondRule.UIFactory:MakeCheckbox(name, parent, tooltip_text)
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

function FiveSecondRule.UIFactory:MakeText(parent, text, size)
    local text_obj = parent:CreateFontString(nil, "ARTWORK")
    text_obj:SetFont("Fonts/FRIZQT__.ttf", size)
    text_obj:SetJustifyV("MIDDLE")
    text_obj:SetJustifyH("CENTER")
    text_obj:SetText(text)
    return text_obj
end

function FiveSecondRule.UIFactory:MakeEditBox(name, parent, title, w, h, enter_func)
    local edit_box_obj = CreateFrame("EditBox", name, parent, BackdropTemplateMixin and "BackdropTemplate")
    edit_box_obj.title_text = FiveSecondRule.UIFactory:MakeText(edit_box_obj, title, 12)
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
	edit_box_obj:SetJustifyV("MIDDLE")
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

function FiveSecondRule.UIFactory:MakeButton(name, parent, width, height, text, textSize, color, on_click_func)
    local button = CreateFrame('Button', name, parent, "UIPanelButtonTemplate")
    button:SetSize(width, height)
    button:SetText(text)
    button:SetScript('OnClick', on_click_func)
    return button
end

function FiveSecondRule.UIFactory:MakeColor(r,g,b,a) 
    return {r = r, g = g, b = b, a = a}
end

function FiveSecondRule.UIFactory:MakeColorPicker(name, parent, title, color, OnShow)
    local colorPickerFrame = CreateFrame("Frame", name, parent, BackdropTemplateMixin and "BackdropTemplate")
    colorPickerFrame.title_text = FiveSecondRule.UIFactory:MakeText(colorPickerFrame, title, 12)
    colorPickerFrame.title_text:SetPoint("TOP", 0, 12)
    colorPickerFrame:SetSize(75, 25)
    colorPickerFrame.texture = colorPickerFrame:CreateTexture(nil, "BACKGROUND")
    colorPickerFrame:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true,
        tileSize = 26,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4}
    })
    colorPickerFrame:SetBackdropColor(color[1], color[2], color[3], color[4])
    colorPickerFrame.texture:SetAllPoints(true)
    colorPickerFrame:SetScript("OnMouseDown", OnShow)

    return colorPickerFrame
end

function FiveSecondRule.UIFactory:ShowColorPicker(r, g, b, a, changedCallback)
    local newR = r;
    local newG = g;
    local newB = b;
    local newA = a;
    local previousValues = {r,g,b,a};

    ColorPickerFrame:SetupColorPickerAndShow({
        r = newR,
        g = newG,
        b = newB,
        opacity = newA,
        hasOpacity = true,
        swatchFunc = function()
            newR, newG, newB = ColorPickerFrame:GetColorRGB()
            newA = ColorPickerFrame:GetColorAlpha()
            changedCallback({newR,newG,newB,newA})
        end,
        cancelFunc = function()
            changedCallback(previousValues)
        end
    })
end

function FiveSecondRule.UIFactory:SetDefaultFont(target)
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