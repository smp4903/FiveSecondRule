-- NAMESPACE / CLASS: FiveSecondRule   
-- OPTIONS: FiveSecondRule_Options      

FiveSecondRule = CreateFrame("Frame")

do -- Private Scope
    local ADDON_NAME = "FiveSecondRule"

    local defaults = {
        ["enabled"] = true,
        ["unlocked"] = false,
        ["integrateIntoPlayerFrame"] = false,
        ["showTicks"] = true,
        ["barWidth"] = 117,
        ["barHeight"] = 11,
        ["barLeft"] = 90,
        ["barTop"] = -68,
        ["flat"] = false,
        ["showText"] = true,
        ["showSpark"] = true,
        ["alwaysShowTicks"] = false,
        ["enableCountdown"] = true,
        ["forceTrackDruidEnergy"] = false,
        ["statusBarColor"] = {0,0,1,0.95},
        ["statusBarBackgroundColor"] = {0,0,0,0.55},
        ["manaTicksColor"] = {0.95, 0.95, 0.95, 1},
        ["manaTicksBackgroundColor"] = {0.35, 0.35, 0.35, 0.8},
    }

    -- STATE VARIABLES
    FiveSecondRule.gainingMana = false
    FiveSecondRule.mp5StartTime = 0
    FiveSecondRule.rapidRegenStartTime = nil
    FiveSecondRule.previousPower = 0

    -- REGISTER EVENTS
    FiveSecondRule:RegisterEvent("ADDON_LOADED")
    FiveSecondRule:RegisterEvent("PLAYER_ENTERING_WORLD")
    FiveSecondRule:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    FiveSecondRule:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    FiveSecondRule:RegisterEvent("PLAYER_UNGHOST")

    FiveSecondRule:SetScript("OnEvent", function(self, event, arg1, ...) onEvent(self, event, arg1, ...) end);

    -- INITIALIZATION
    function Init()
        LoadOptions()

        if (select(2, UnitClass("player")) == "WARRIOR") then
            -- Disable the addon for warriors, since there is no reliable power or life to track in order to show power ticks.
            DisableAddon()
            return
        else
            EnableAddon()
        end

        TickBar:LoadSpells() -- LOCALIZATION
        FiveSecondRule:Refresh()
    end

    function IsWOTLK()
        local _, _, _, tocversion = GetBuildInfo()
        return tocversion >= 30400
    end

    function DisableAddon()
        StatusBar.statusbar:Hide()
        TickBar.tickbar:Hide()
        FiveSecondRule:SetScript("OnUpdate", nil)
    end

    function EnableAddon()
        FiveSecondRule:SetScript("OnUpdate", function(self, sinceLastUpdate) onUpdate(sinceLastUpdate); end);
    end

    function LoadOptions()
        FiveSecondRule_Options = FiveSecondRule_Options or AddonUtils:deepcopy(defaults)

        for key,value in pairs(defaults) do
            if (FiveSecondRule_Options[key] == nil) then
                FiveSecondRule_Options[key] = value
            end
        end

        if (IsWOTLK()) then
            FiveSecondRule_Options["alwaysShowTicks"] = false
            FiveSecondRule_Options["showTicks"] = false
        end

        FiveSecondRule_Options.unlocked = false
    end

    function onEvent(self, event, arg1, ...)
        if event == "ADDON_LOADED" then
            if arg1 == ADDON_NAME then
                Init()
            end
        end

        if not FiveSecondRule_Options.enabled then
            return
        end

        if event == "PLAYER_ENTERING_WORLD" then
            savePlayerPower()
        end

        if event == "PLAYER_EQUIPMENT_CHANGED" then
            savePlayerPower()
        end

        if event == "UNIT_SPELLCAST_SUCCEEDED" then
            -- Make sure we spent mana, as free casts do not trigger FSR.
            if arg1 == "player" and GetPower() < FiveSecondRule.previousPower then
                -- Only show the FSR for classes using mana
                -- Subsequently, this also means that the tick bar won't be hidden for classes not using mana (rogue)
                if (FiveSecondRule.GetPowerType() == 0) then
                    FiveSecondRule.gainingMana = false

                    savePlayerPower()

                    FiveSecondRule.mp5StartTime = GetTime() + 5

                    TickBar.tickbar:Hide()
                    StatusBar.statusbar:Show()
                end
            end
        end
    end

    function onUpdate(sinceLastUpdate)
        if (not FiveSecondRule_Options.enabled) or UnitIsDead("player") then
            StatusBar.statusbar:Hide()
            TickBar.tickbar:Hide()
            return
        end

        -- time needs to be defined for this to work
        if (GetTime() == nil) then
            savePlayerPower()
            return
        end

        StatusBar:OnUpdate()
        TickBar:OnUpdate()

        savePlayerPower()
    end

    function GetPower()
        return UnitPower("player", GetPowerType())
    end

    function GetPowerMax()
        return UnitPowerMax("player", GetPowerType())
    end

    function GetPowerType()
        local class = select(2, UnitClass("player"))

        if class == "DRUID" and FiveSecondRule_Options.forceTrackDruidEnergy then
            return 3
        end

        if class == "ROGUE" then
            return 3
        else 
            return 0
        end
    end

    function savePlayerPower()
        FiveSecondRule.previousPower = GetPower()
    end

    function SpellIdToName(id)
        local name, _, _, _, _, _ = GetSpellInfo(id)
        return name
    end

    function Refresh()
        StatusBar:Refresh()
        TickBar:Refresh()
    end

    function Unlock()
        FiveSecondRule_Options.unlocked = true

        StatusBar:Unlock()
        TickBar:Unlock()
    end

    function Lock()
        FiveSecondRule_Options.unlocked = false

        StatusBar:Lock()
        TickBar:Lock()
    end

    function Reset() 
        StatusBar:Reset()
        TickBar:Reset()

        FiveSecondRule_Options = AddonUtils:deepcopy(defaults)

        Init()
    end

    function PrintNotSupported()
        local colorHex = "ed2d2d"
        print("|cff"..colorHex.."FiveSecondRule is not supported in this game version.")
        print("|cff"..colorHex.."The addon has been automatically disable with effect from your next UI reload.")
    end
    

    -- Expose Field Variables and Functions
    FiveSecondRule.Unlock = Unlock
    FiveSecondRule.Lock = Lock
    FiveSecondRule.Reset = Reset
    FiveSecondRule.Refresh = Refresh
    FiveSecondRule.GetPower = GetPower
    FiveSecondRule.GetPowerMax = GetPowerMax
    FiveSecondRule.GetPowerType = GetPowerType
    FiveSecondRule.IsWOTLK = IsWOTLK
    
end