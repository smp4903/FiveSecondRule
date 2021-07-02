TickBar = {}

do -- private scope

    -- Declare Field Variables
    local tickbar = CreateFrame("StatusBar", "Five Second Rule Statusbar - Mana Ticks", UIParent) -- StatusBar for tracking mana ticks after 5SR is fulfilled
    local manaTickTime = 0
    local powerRegenTime = 2
    local mp5Sensitivty = 0.80
    local runningAverageSize = 5
    local rapidRegenLeeway = 500

    -- LOCALIZED STRINGS
    local SPIRIT_TAP_NAME = "Spirit Tap"
    local BLESSING_OF_WISDOM_NAME = "Blessing of Wisdom"
    local GREATER_BLESSING_OF_WISDOM_NAME = "Greater Blessing of Wisdom"
    local INNERVATE_NAME = "Innervate"
    local DRINK_NAME = "Drink"
    local EVOCATION_NAME = "Evocation"

    function LoadSpells()
        SPIRIT_TAP_NAME = SpellIdToName(15338)
        RESURRECTION_SICKNESS_NAME = SpellIdToName(15007)
        BLESSING_OF_WISDOM_NAME = SpellIdToName(19854) -- Rank doesnt matter
        GREATER_BLESSING_OF_WISDOM_NAME = SpellIdToName(25918) -- Rank doesnt matter
        INNERVATE_NAME = SpellIdToName(29166)
        DRINK_NAME = SpellIdToName(1135)
        EVOCATION_NAME = SpellIdToName(12051)
    end

    function Refresh()
        -- This function updates all properties on the tickbar that are dependant on options

        -- POSITION, SIZE
        tickbar:SetWidth(FiveSecondRule_Options.barWidth)
        tickbar:SetHeight(FiveSecondRule_Options.barHeight)
        tickbar:SetPoint("TOPLEFT", StatusBar.statusbar, 0, 0)

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
        local fgc = FiveSecondRule_Options.manaTicksColor
        tickbar:SetStatusBarColor(fgc[1], fgc[2], fgc[3], fgc[4])
        if FiveSecondRule_Options.flat then
            tickbar:GetStatusBarTexture():SetColorTexture(fgc[1], fgc[2], fgc[3], fgc[4])
        end     

        -- BACKGROUND
        if (not tickbar.bg) then
            tickbar.bg = tickbar:CreateTexture(nil, "BACKGROUND")
        end
        tickbar.bg:SetTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
        tickbar.bg:SetAllPoints(true)
        local bgc = FiveSecondRule_Options.manaTicksBackgroundColor
        tickbar.bg:SetVertexColor(bgc[1], bgc[2], bgc[3])
        tickbar.bg:SetAlpha(bgc[4])

        if FiveSecondRule_Options.flat then
            tickbar.bg:SetColorTexture(bgc[1], bgc[2], bgc[3], bgc[4])
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
        if FiveSecondRule_Options.showTicks then

            rapidRegenLeeway = 500 + GetLatency()

            local power = FiveSecondRule.GetPower()
            local powerMax = FiveSecondRule.GetPowerMax()
            local hasFullPower = power >= powerMax
            local tickSize = power - FiveSecondRule.previousPower
            local validTick = IsValidTick(tickSize)

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
                    if power > FiveSecondRule.previousPower then
                        if (PlayerHasBuff(SPIRIT_TAP_NAME)) then
                            tickSize = tickSize / 2
                        end

                        TrackTick(tickSize)

                        if validTick then
                            manaTickTime = GetTime() + powerRegenTime
                        end
                        
                        tickbar:Show()
                    end

                    UpdateProgress()
                else
                    tickbar:Hide()
                end
            end
        else
            tickbar:Hide()
        end

        if FiveSecondRule.gainingMana and validTick then
            tickbar:Show()
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

    function IsValidTick(tick) 
        if (tick == nil or tick == 0) then
            return false
        end

        local mid = FSR_STATS.MP2FromSpirit() -- FiveSecondRule_Options.averageManaTick
        if (mid <= 0) then
            mid = FiveSecondRule_Options.averageManaTick
        end

        local low = mid * mp5Sensitivty
        local high = mid * (1 + (1 - mp5Sensitivty))
        high = high + FSR_STATS.GetBlessingOfWisdomBonus()

        if (tick <= low and tick >= FiveSecondRule.GetPowerMax() - FiveSecondRule.GetPower()) then
            return true -- last tick
        end

        if (tick >= high) then
            return IsRapidRegening()
        end

        return tick > low
    end

    function TrackTick(tick)    
        local now = GetTime()

        local isDrinking = PlayerHasBuff(DRINK_NAME)
        local hasInervate = PlayerHasBuff(INNERVATE_NAME)

        local rapidRegen = FiveSecondRule.rapidRegenStartTime and (FiveSecondRule.rapidRegenStartTime + rapidRegenLeeway) >= now

        if (isDrinking or hasInervate or rapidRegen) then
            return
        end

        table.insert(FiveSecondRule_Options.tickSizeRunningWindow, tick)

        if (table.getn(FiveSecondRule_Options.tickSizeRunningWindow) > runningAverageSize) then
            table.remove(FiveSecondRule_Options.tickSizeRunningWindow, 1)
        end

        local sum = 0
        local ave = 0
        local elements = #FiveSecondRule_Options.tickSizeRunningWindow
        
        for i = 1, elements do
            sum = sum + FiveSecondRule_Options.tickSizeRunningWindow[i]
        end
        
        ave = sum / elements

        FiveSecondRule_Options.averageManaTick = ave
    end
    
    function ResetRunningAverage()
        FiveSecondRule_Options.tickSizeRunningWindow = {}
        FiveSecondRule_Options.averageManaTick = 0
    end

    function PlayerHasBuff(nameString)
        for i=1,40 do
            local name, _, _, _, _, expirationTime, _, _, _, spellId = UnitBuff("player",i)
            if name then
                if name == nameString then
                    return true, expirationTime, FSR_STATS.GetSpellRank(spellId)
                end
            end
        end
        return false, nil, nil
    end

    function PlayerHasDebuff(nameString)
        for i=1,40 do
            local name, _, _, _, _, expirationTime = UnitDebuff("player",i)
            if name then
                if name == nameString then
                    return true, expirationTime
                end
            end
        end
        return false, nil
    end

    function IsRapidRegening()
        local now = GetTime()

        local isDrinking = PlayerHasBuff(DRINK_NAME)
        local hasInervate = PlayerHasBuff(INNERVATE_NAME)
        local hasEvocation = PlayerHasBuff(EVOCATION_NAME)

        if (isDrinking or hasInervate or hasEvocation) then
            if (not FiveSecondRule.rapidRegenStartTime) then
                FiveSecondRule.rapidRegenStartTime = now
            end
        else
            if FiveSecondRule.rapidRegenStartTime and (now >= (FiveSecondRule.rapidRegenStartTime + rapidRegenLeeway)) then
                FiveSecondRule.rapidRegenStartTime = nil
            end
        end

        return FiveSecondRule.rapidRegenStartTime and (FiveSecondRule.rapidRegenStartTime + rapidRegenLeeway) >= now
    end

    function GetLatency() 
        local down, up, lagHome, lagWorld = GetNetStats();
        return lagHome
    end
    
    -- Expose Field Variables and Functions
    TickBar.tickbar = tickbar
    TickBar.Refresh = Refresh
    TickBar.Lock = Lock
    TickBar.Unlock = Unlock
    TickBar.OnUpdate = OnUpdate
    TickBar.Reset = Reset
    TickBar.LoadSpells = LoadSpells
    TickBar.ResetRunningAverage = ResetRunningAverage

end

return TickBar