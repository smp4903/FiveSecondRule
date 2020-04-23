-- NAMESPACE / CLASS: FiveSecondRule   
-- OPTIONS: FiveSecondRule_Options      

FiveSecondRule = CreateFrame("Frame")

do -- Private Scope
    local ADDON_NAME = "FiveSecondRule"

    local defaults = {
        ["unlocked"] = false,
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
        ["statusBarColor"] = {0,0,1,0.95},
        ["statusBarBackgroundColor"] = {0,0,0,0.55},
        ["manaTicksColor"] = {0.95, 0.95, 0.95, 1},
        ["manaTicksBackgroundColor"] = {0.35, 0.35, 0.35, 0.8},
        ["tickSizeRunningWindow"] = {},
        ["averageManaTick"] = 0
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
    FiveSecondRule:SetScript("OnUpdate", function(self, sinceLastUpdate) onUpdate(sinceLastUpdate); end);

    -- INITIALIZATION
    function Init()  
        TickBar:LoadSpells() -- LOCALIZATION
        LoadOptions()
        FiveSecondRule_Options.unlocked = false

        FiveSecondRule:Refresh()
    end

    function LoadOptions()
        FiveSecondRule_Options = FiveSecondRule_Options or AddonUtils:deepcopy(defaults)

        for key,value in pairs(defaults) do
            if (FiveSecondRule_Options[key] == nil) then
                FiveSecondRule_Options[key] = value
            end
        end
    end

    function onEvent(self, event, arg1, ...)
        if event == "ADDON_LOADED" then
            if arg1 == ADDON_NAME then
                Init()
                PrintHelp()
            end
        end

        if event == "PLAYER_ENTERING_WORLD" then
            savePlayerPower()
        end

        if event == "UNIT_SPELLCAST_SUCCEEDED" then
            if UnitPower("player") < FiveSecondRule.previousPower then
                if UnitPowerType("player") == 0 then -- 0 is mana
                    FiveSecondRule.gainingMana = false

                    savePlayerPower()

                    FiveSecondRule.mp5StartTime = GetTime() + 5

                    TickBar.tickbar:Hide()
                    StatusBar.statusbar:Show()
                end
            end
        end

        if event == "PLAYER_EQUIPMENT_CHANGED" then
            savePlayerPower()
            TickBar:ResetRunningAverage()
        end

        if event == "PLAYER_UNGHOST" then
            TickBar:ResetRunningAverage()
        end
    end

    function onUpdate(sinceLastUpdate)
        if UnitIsDead("player") or (not IsValidClass()) then
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

    function savePlayerPower()
        FiveSecondRule.previousPower = UnitPower("player")
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

    function PrintHelp()
        local colorHex = "2979ff"
        print("|cff"..colorHex.."FiveSecondRule loaded - /fsr")
    end

    function IsValidClass()
        local localizedClass, englishClass, classIndex = UnitClass("player")
        return classIndex > 1 -- 1 is warrior, the rest have energy or mana
    end

    -- Expose Field Variables and Functions
    FiveSecondRule.Unlock = Unlock
    FiveSecondRule.Lock = Lock
    FiveSecondRule.Reset = Reset
    FiveSecondRule.PrintHelp = PrintHelp
    FiveSecondRule.Refresh = Refresh
    
end

return FiveSecondRule