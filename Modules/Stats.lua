FSR_STATS = {}

MP5_BUFF_SPELL_IDS = {
    25918, -- Greater Blessing of Wisdom
    19854, -- Blessing of Wisdom
    25690, -- Well Fed: Smoked Sagefish (Brain Food)
}

SPIRIT_MOD_BUFF_SPELL_IDS = {
    15338, -- Spirit Tap  
    29166, -- Innervate
    12051, -- Evocation
}

do -- private scope

    local function Round(num, decimalPlaces)
        if not num then
            return 0
        end
        local mult = 10^(decimalPlaces)
        return math.floor(num * mult + 0.5) / mult
    end

    local function MP5FromItems()
        local mp5 = 0
        for i = 1, 18 do
            local itemLink = GetInventoryItemLink("player", i)
            if itemLink then
                local stats = GetItemStats(itemLink)
                if stats then
                    local statMP5 = stats["ITEM_MOD_POWER_REGEN0_SHORT"]
                    if statMP5 then
                        mp5 = mp5 + statMP5 + 1
                    end
                end
            end
        end
        return mp5
    end

    local lastManaReg = 0

    local function MP5FromSpirit()
        local base, _ = GetManaRegen() -- Returns mana reg per 1 second
        if base < 1 then
            base = lastManaReg
        end
        lastManaReg = base
        return Round(base, 0) * 5
    end

    local function MP2FromSpirit()
        local base, _ = GetManaRegen() -- Returns mana reg per 1 second
        if base < 1 then
            base = lastManaReg
        end
        lastManaReg = base
        return Round(base, 0) * 2
    end

    local function GetTalentModifierMP5()
        local _, _, classId = UnitClass("player")
        local mod = 0

        if classId == 5 then -- Priest
            local _, _, _, _, points, _, _, _ = GetTalentInfo(1, 8)
            mod = points * 0.05 -- 0-15% from Meditation
        elseif classId == 8 then -- Mage
            local _, _, _, _, points, _, _, _ = GetTalentInfo(1, 12)
            mod = points * 0.05 -- 0-15% Arcane Meditation
        elseif classId == 11 then -- Druid
            local _, _, _, _, points, _, _, _ = GetTalentInfo(3, 6)
            mod = points * 0.05 -- 0-15% from Reflection
        end

        return mod
    end

    local function HasSetBonusModifierMP5()
        local _, _, classId = UnitClass("player")
        local hasSetBonus = false
        local setCounter = 0

        for i = 1, 18 do
            local itemLink = GetInventoryItemLink("player", i)
            if itemLink then
                local itemName = C_Item.GetItemNameByID(GetInventoryItemLink("player", i))

                if itemName then
                    if classId == 5 then -- Priest
                        if string.sub(itemName, -13) == "Transcendence" or string.sub(itemName, -11) == "Erhabenheit" or string.sub(itemName, -13) == "Trascendencia" or string.sub(itemName, -13) == "transcendance" or string.sub(itemName, -14) == "Transcendência" then
                            setCounter = setCounter + 1
                        end
                    elseif classId == 11 then -- Druid
                        if string.sub(itemName, 1, 9) == "Stormrage" or string.sub(itemName, -9) == "Stormrage" or string.sub(itemName, -10) == "Tempestira" or string.sub(itemName, -11) == "Tempesfúria" then
                            setCounter = setCounter + 1
                        end
                    end
                end
            end
        end

        if setCounter >= 3 then
            hasSetBonus = true
        end

        return hasSetBonus
    end

    -- Get manaregen while casting
    local function MP5WhileCasting()
        local _, casting = GetManaRegen() -- Returns mana reg per 1 second
        if casting < 1 then
            casting = lastManaReg
        end
        lastManaReg = casting

        local mod = GetTalentModifierMP5()
        if HasSetBonusModifierMP5() then
            mod = mod + 0.15
        end
        if mod > 0 then
            casting = casting * mod
        end

        local mp5Items = MP5FromItems()
        casting = (casting * 5) + mp5Items

        return Round(casting, 2)
    end

    local function MP5FromBuffs()
        local result = 0

        for i=1,40 do
            local name, _, count, _, _, expirationTime, _, _, _, spellId  = UnitBuff("player",i)
            if spellId then
                local text = GetSpellDescription(spellId)
                print(name, GetSpellSubtext(spellId), text)

            end
        end

        return result    
    end

    local function GetSpellRank(spellId)
        local str = GetSpellSubtext(spellId)
        if str then
            local ENClientFormat = string.sub(str, -1) -- Subtext is "Rank 1"
            if tonumber(ENClientFormat) ~= nil then
                return tonumber(ENClientFormat)
            else
                return tonumber(string.sub(str, 1, 1)) -- RU Client format, subtext is "1-й уровень"
            end
        end
        return 1
    end

    local function GetBlessingOfWisdomBonus()
        -- DOES NOT INCLUDE MODIFIER TALENTS (rank 1 = 10%, rank 2 = 20%)
        local bow, bowExp, bowRank = PlayerHasBuff(SpellIdToName(25918))

        if bow then
            if bowRank < 3 then
                return 27 + bowRank * 3
            else
                return 27 + bowRank * 3 + 5
            end
        end

        bow, bowExp, bowRank = PlayerHasBuff(SpellIdToName(19854))

        if bow then
            if bowRank < 6 then
                return 5 + bowRank * 5
            else
                return 25 + (bowRank-5) * 8 -- Rank 6 = 33, Rank 7 = 41
            end
        end

        return 0
    end

    -- Expose Field Variables and Functions
    FSR_STATS.MP5FromItems = MP5FromItems
    FSR_STATS.MP5FromSpirit = MP5FromSpirit
    FSR_STATS.MP2FromSpirit = MP2FromSpirit
    FSR_STATS.MP5WhileCasting = MP5WhileCasting
    FSR_STATS.MP5FromBuffs = MP5FromBuffs
    FSR_STATS.GetSpellRank = GetSpellRank
    FSR_STATS.GetBlessingOfWisdomBonus = GetBlessingOfWisdomBonus

end