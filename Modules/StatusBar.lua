StatusBar = {}

do -- private scope

    -- Declare Field Variables
    local statusbar = CreateFrame("StatusBar", "Five Second Rule Statusbar", UIParent) -- StatusBar for the 5SR tracker
    local mp5delay = 5

    function Refresh()
        -- This function updates all properties on the statusbar that are dependant on options
        
        -- POSITION, SIZE
        statusbar:ClearAllPoints()

        if FiveSecondRule_Options.integrateIntoPlayerFrame then
            local pframe = PlayerFrameManaBar;
            local point, relativeTo, relativePoint, xOfs, yOfs = PlayerFrameManaBar:GetPoint()
    
            -- POSITION, SIZE
            statusbar:SetWidth(pframe:GetWidth())
            statusbar:SetHeight(pframe:GetHeight())
            statusbar:SetPoint(point, relativeTo, relativePoint, xOfs + 5, yOfs)
        else
            statusbar:SetWidth(FiveSecondRule_Options.barWidth)
            statusbar:SetHeight(FiveSecondRule_Options.barHeight)
            statusbar:SetPoint("TOPLEFT", FiveSecondRule_Options.barLeft, FiveSecondRule_Options.barTop)
        end

        -- DRAGGING
        statusbar:SetScript("OnMouseDown", function(self, button) onMouseDown(button); end)
        statusbar:SetScript("OnMouseUp", function(self, button) onMouseUp(button); end)
        statusbar:SetMovable(true)
        statusbar:SetResizable(true)
        statusbar:EnableMouse(FiveSecondRule_Options.unlocked)
        statusbar:SetClampedToScreen(true)

        -- MIN / MAX
        statusbar:SetMinMaxValues(0, mp5delay)

        -- FOREGROUND
        statusbar:SetStatusBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
        statusbar:GetStatusBarTexture():SetHorizTile(false)
        statusbar:GetStatusBarTexture():SetVertTile(false)
        if FiveSecondRule_Options.integrateIntoPlayerFrame then
            statusbar:SetStatusBarColor(0, 0, 0, 0)
        else
            local sc = FiveSecondRule_Options.statusBarColor
            statusbar:SetStatusBarColor(sc[1], sc[2], sc[3], sc[4])

            if FiveSecondRule_Options.flat then
                statusbar:GetStatusBarTexture():SetColorTexture(sc[1], sc[2], sc[3], sc[4])
            end        
        end

        -- BACKGROUND
        if (not statusbar.bg) then
            statusbar.bg = statusbar:CreateTexture(nil, "BACKGROUND")
        end
        statusbar.bg:SetTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
        statusbar.bg:SetAllPoints(true)

        if FiveSecondRule_Options.integrateIntoPlayerFrame then
            statusbar.bg:SetVertexColor(0, 0, 0)
            statusbar.bg:SetAlpha(0)
        else
            local sbc = FiveSecondRule_Options.statusBarBackgroundColor
            statusbar.bg:SetVertexColor(sbc[1], sbc[2], sbc[3])
            statusbar.bg:SetAlpha(sbc[4])
            if FiveSecondRule_Options.flat then
                statusbar.bg:SetColorTexture(sbc[1], sbc[2], sbc[3], sbc[4])
            end
        end

        -- TEXT
        if (not statusbar.value) then
            statusbar.value = statusbar:CreateFontString(nil, "OVERLAY")
        end
        statusbar.value:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
        statusbar.value:SetJustifyH("LEFT")
        statusbar.value:SetShadowOffset(1, -1)
        statusbar.value:SetTextColor(1, 1, 1)
        statusbar.value:SetPoint("LEFT", statusbar, "LEFT", 4, 0)
        FiveSecondRule.UIFactory:SetDefaultFont(statusbar) 

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

        -- VISIBILITY
        if (not FiveSecondRule_Options.unlocked) then
            statusbar:Hide()
        end
    end

    function Lock()
        statusbar:Hide()
        statusbar:EnableMouse(false)
        statusbar:StopMovingOrSizing();
        statusbar.resizing = nil
    end

    function Unlock()
        statusbar:Show()
        statusbar:EnableMouse(true)
        statusbar:SetValue(2)
    end

    function Reset()
        statusbar:SetUserPlaced(false)
    end

    function OnUpdate()
            local now = GetTime()

            -- Five Second Rule Countdown
            if (FiveSecondRule.mp5StartTime > 0) then
                local remaining = (FiveSecondRule.mp5StartTime - now)

                if (remaining >= 0) then
                    if FiveSecondRule_Options.enableCountdown then
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
                        statusbar:Hide()
                    end
                else
                    resetManaGain()
                end
            else
                resetManaGain()
            end
       
    end

    function onMouseDown(button)
        if button == "LeftButton" then
            statusbar:StartMoving()
        elseif button == "RightButton" then
            statusbar:StartSizing("BOTTOMRIGHT")
            statusbar.resizing = 1
        end
    end

    function onMouseUp()
        statusbar:StopMovingOrSizing();

        FiveSecondRule_Options.barLeft = statusbar:GetLeft()
        FiveSecondRule_Options.barTop = -1 * (GetScreenHeight() - statusbar:GetTop())
        FiveSecondRule_Options.barWidth = statusbar:GetWidth()
        FiveSecondRule_Options.barHeight = statusbar:GetHeight()

        Refresh()

        TickBar:Refresh()

        FiveSecondRule.OptionsPanelFrame:UpdateOptionValues()
    end

    function resetManaGain()
        FiveSecondRule.gainingMana = true
        FiveSecondRule.mp5StartTime = 0
        FiveSecondRule.rapidRegenStartTime = nil

        if not FiveSecondRule_Options.unlocked then
            statusbar:Hide()
        end
    end
    
    -- Expose Field Variables
    StatusBar.statusbar = statusbar
    StatusBar.Refresh = Refresh
    StatusBar.Lock = Lock
    StatusBar.Unlock = Unlock
    StatusBar.Reset = Reset
    StatusBar.OnUpdate = OnUpdate

end

return StatusBar