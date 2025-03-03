TickBar = {}

do -- private scope

    -- Declare Field Variables
    local tickbar = CreateFrame("StatusBar", "Five Second Rule Statusbar - Mana Ticks", UIParent) -- StatusBar for tracking mana ticks after 5SR is fulfilled
    local manaTickTime = 0
    local powerRegenTime = 2

    function HandleTick(_, unitTarget, powerType)                
        if (unitTarget == "player") then

            local powerToTrack = FiveSecondRule.GetPowerType()
            if ((powerToTrack == 0 and powerType == "MANA") or (powerToTrack == 3 and powerType == "ENERGY")) then 

                local now = GetTime()
                if (GetPower() > FiveSecondRule.previousPower) then
                    manaTickTime = now + powerRegenTime
                    savePlayerPower()
                end
                
            end
        end

    end

    function Refresh()
        -- This function updates all properties on the tickbar that are dependant on options
        
        -- POSITION, SIZE
        tickbar:ClearAllPoints()
        if FiveSecondRule_Options.integrateIntoPlayerFrame then
            local pframe = PlayerFrameManaBar;
            local point, relativeTo, relativePoint, xOfs, yOfs = PlayerFrameManaBar:GetPoint()
    
            -- POSITION, SIZE
            tickbar:SetWidth(pframe:GetWidth())
            tickbar:SetHeight(pframe:GetHeight())
            tickbar:SetPoint(point, relativeTo, relativePoint, xOfs + 5, yOfs)
        else
            tickbar:SetWidth(FiveSecondRule_Options.barWidth)
            tickbar:SetHeight(FiveSecondRule_Options.barHeight)
            tickbar:SetPoint("TOPLEFT", StatusBar.statusbar, 0, 0)    
        end

        -- VALUE
        tickbar:SetMinMaxValues(0, 2)

        -- DRAGGING
        tickbar:SetMovable(true)
        tickbar:SetResizable(true)
        tickbar:EnableMouse(false)
        tickbar:SetClampedToScreen(true)

        -- FOREGROUND
        tickbar:SetStatusBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
        tickbar:GetStatusBarTexture():SetHorizTile(false)
        tickbar:GetStatusBarTexture():SetVertTile(false)

        if FiveSecondRule_Options.integrateIntoPlayerFrame then
            tickbar:SetStatusBarColor(0, 0, 0, 0)
        else
            local fgc = FiveSecondRule_Options.manaTicksColor
            tickbar:SetStatusBarColor(fgc[1], fgc[2], fgc[3], fgc[4])

            if FiveSecondRule_Options.flat then
                tickbar:GetStatusBarTexture():SetColorTexture(fgc[1], fgc[2], fgc[3], fgc[4])
            end   
        end


        -- BACKGROUND
        if (not tickbar.bg) then
            tickbar.bg = tickbar:CreateTexture(nil, "BACKGROUND")
        end
        tickbar.bg:SetTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
        tickbar.bg:SetAllPoints(true)

        if FiveSecondRule_Options.integrateIntoPlayerFrame then
            tickbar.bg:SetVertexColor(0, 0, 0)
            tickbar.bg:SetAlpha(0)
        else
            local bgc = FiveSecondRule_Options.manaTicksBackgroundColor
            tickbar.bg:SetVertexColor(bgc[1], bgc[2], bgc[3])
            tickbar.bg:SetAlpha(bgc[4])

            if FiveSecondRule_Options.flat then
                tickbar.bg:SetColorTexture(bgc[1], bgc[2], bgc[3], bgc[4])
            end
        end

        -- TEXT
        if (not tickbar.value) then
            tickbar.value = tickbar:CreateFontString(nil, "OVERLAY")
        end
        tickbar.value:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
        tickbar.value:SetJustifyH("LEFT")
        tickbar.value:SetShadowOffset(1, -1)
        tickbar.value:SetTextColor(1, 1, 1, 1)
        tickbar.value:SetPoint("LEFT", tickbar, "LEFT", 4, 0)
        FiveSecondRule.UIFactory:SetDefaultFont(tickbar)

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
    end

    function Lock()
        tickbar:EnableMouse(false)
        tickbar:SetValue(0)
        tickbar:Hide()
    end

    function Unlock()
        tickbar:EnableMouse(true)
        tickbar:SetValue(1)
        tickbar:Show()
    end

    function Reset()
        tickbar:SetUserPlaced(false)
    end
    
    function OnUpdate()       
        if (FiveSecondRule.IsWOTLK()) then
            tickbar:Hide()
            return
        end
        
        if FiveSecondRule_Options.showTicks then

            local power = FiveSecondRule.GetPower()
            local powerMax = FiveSecondRule.GetPowerMax()
            local hasFullPower = power >= powerMax
            
            if hasFullPower then
                if (FiveSecondRule_Options.alwaysShowTicks) then
                    tickbar:Show()
                    UpdateProgress()
                else
                    if not FiveSecondRule_Options.unlocked then
                        tickbar:Hide()
                    end
                end
            else
                if FiveSecondRule.gainingMana then
                    tickbar:Show()
                    UpdateProgress()
                else
                    tickbar:Hide()
                end
            end
        else
            tickbar:Hide()
        end
    end

    function UpdateProgress()
        local now = GetTime()

        if (now >= manaTickTime) then
            manaTickTime = now + powerRegenTime
        end

        local val = manaTickTime - now
        tickbar:SetValue(powerRegenTime - val)

        if (FiveSecondRule_Options.showText == true) then
            tickbar.value:SetText(string.format("%.1f", val).."s")
        else
            tickbar.value:SetText("")
        end

        if (FiveSecondRule_Options.showSpark) then
            local positionLeft = math.min(FiveSecondRule_Options.barWidth * (1 - (val/powerRegenTime)), FiveSecondRule_Options.barWidth)
            tickbar.bg.spark:SetPoint("CENTER", tickbar.bg, "LEFT", positionLeft-2, 0)      
        end
    end
    
    -- Expose Field Variables and Functions
    TickBar.tickbar = tickbar
    TickBar.Refresh = Refresh
    TickBar.Lock = Lock
    TickBar.Unlock = Unlock
    TickBar.OnUpdate = OnUpdate
    TickBar.Reset = Reset
    TickBar.HandleTick = HandleTick

end

return TickBar