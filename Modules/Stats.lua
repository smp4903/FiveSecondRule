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

    local version, build, date, tocversion = GetBuildInfo()
    local isTBC = tocversion >= 20000

    local manaSpringRegen = {
        [1] = 6,
        [2] = 9,
        [3] = 13,
        [4] = 17,
        [5] = 20,
    }

    local bowRegen = {
        [1] = 10,
        [2] = 15,
        [3] = 20,
        [4] = 25,
        [5] = 30,
        [6] = 33,
        [7] = 41,
    }

    local greaterBowRegen = {
        [1] = 30,
        [2] = 33,
        [3] = 41,
    }

    --[[---------------------------------
	:GetNormalManaRegenFromSpi()
    -------------------------------------
    Notes:
        * Formula and BASE_REGEN values derived by Whitetooth (hotdogee [at] gmail [dot] com)
        * Calculates the mana regen per 1 seconds from spirit when out of 5 second rule for given intellect and level.
        * Player class is no longer a parameter
        * ManaRegen(SPI, INT, LEVEL) = (0.001+SPI*BASE_REGEN[LEVEL]*(INT^0.5))
    Returns:
        ; mp1o5sr : number - Mana regen per 1 seconds when out of 5 second rule
    -----------------------------------]]

    -- Numbers reverse engineered by Whitetooth (hotdogee [at] gmail [dot] com)
    local BaseManaRegenPerSpi = {
        [1] = 0.034965,
        [2] = 0.034191,
        [3] = 0.033465,
        [4] = 0.032526,
        [5] = 0.031661,
        [6] = 0.031076,
        [7] = 0.030523,
        [8] = 0.029994,
        [9] = 0.029307,
        [10] = 0.028661,
        [11] = 0.027584,
        [12] = 0.026215,
        [13] = 0.025381,
        [14] = 0.0243,
        [15] = 0.023345,
        [16] = 0.022748,
        [17] = 0.021958,
        [18] = 0.021386,
        [19] = 0.02079,
        [20] = 0.020121,
        [21] = 0.019733,
        [22] = 0.019155,
        [23] = 0.018819,
        [24] = 0.018316,
        [25] = 0.017936,
        [26] = 0.017576,
        [27] = 0.017201,
        [28] = 0.016919,
        [29] = 0.016581,
        [30] = 0.016233,
        [31] = 0.015994,
        [32] = 0.015707,
        [33] = 0.015464,
        [34] = 0.015204,
        [35] = 0.014956,
        [36] = 0.014744,
        [37] = 0.014495,
        [38] = 0.014302,
        [39] = 0.014094,
        [40] = 0.013895,
        [41] = 0.013724,
        [42] = 0.013522,
        [43] = 0.013363,
        [44] = 0.013175,
        [45] = 0.012996,
        [46] = 0.012853,
        [47] = 0.012687,
        [48] = 0.012539,
        [49] = 0.012384,
        [50] = 0.012233,
        [51] = 0.012113,
        [52] = 0.011973,
        [53] = 0.011859,
        [54] = 0.011714,
        [55] = 0.011575,
        [56] = 0.011473,
        [57] = 0.011342,
        [58] = 0.011245,
        [59] = 0.01111,
        [60] = 0.010999,
        [61] = 0.0107,
        [62] = 0.010522,
        [63] = 0.01029,
        [64] = 0.010119,
        [65] = 0.009968,
        [66] = 0.009808,
        [67] = 0.009651,
        [68] = 0.009553,
        [69] = 0.009445,
        [70] = 0.009327,
        [71] = 0.008859,
        [72] = 0.008415,
        [73] = 0.007993,
        [74] = 0.007592,
        [75] = 0.007211,
        [76] = 0.006849,
        [77] = 0.006506,
        [78] = 0.006179,
        [79] = 0.005869,
        [80] = 0.005575,
    }

    local function GetNormalManaRegenFromSpi()
        local level = UnitLevel("player")
        local _, int = UnitStat("player",4)
        local _, spi = UnitStat("player",5)

        return (0.001 + spi * BaseManaRegenPerSpi[level] * (int ^ 0.5))
    end

    local function Round(num, decimalPlaces)
        if not num then
            return 0
        end
        local mult = 10^(decimalPlaces)
        return math.floor(num * mult + 0.5) / mult
    end

    local lastManaReg = 0

    local function MP1FromSpirit()
        local base, _ = GetManaRegen() -- Returns mana reg per 1 second

        if (isTBC) then
            base = GetNormalManaRegenFromSpi()
        end

        if base < 1 then
            base = lastManaReg
        end
        lastManaReg = base
        return Round(base, 0)
    end

    local function MP2FromSpirit()
        return MP1FromSpirit() * 2
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
        local greaterBow, _, greaterBowRank = PlayerHasBuff(SpellIdToName(25918))

        if greaterBow then
            local regen = greaterBowRegen[greaterBowRank]
            if regen then
                return regen
            end
        end

        local bow, _, bowRank = PlayerHasBuff(SpellIdToName(19854))

        if bow then
            local regen = bowRegen[bowRank]
            if regen then
                return regen
            end
        end

        return 0
    end

    local function GetEpiphanyBonus() 
        -- Priest T3 full set bonus buff proc
        local epiphany = PlayerHasBuff(SpellIdToName(28802))
        if (epiphany) then
            return 24
        end
        return 0
    end

    local function GetManaSpringBonus() 
        -- disregards Improved Mana Spring Totem (+3 bonus MP2)
        local spring, _, rank = PlayerHasBuff(SpellIdToName(25569))
        if (spring) then
            local regen = manaSpringRegen[rank]
            if regen then
                return regen
            end
        end
        return 0
    end

    local function MP2FromBuffs()
        local result = 0
        return result 
        + GetEpiphanyBonus() 
        + GetBlessingOfWisdomBonus()
        + GetManaSpringBonus()

    end


    -- Expose Field Variables and Functions
    FSR_STATS.MP2FromSpirit = MP2FromSpirit
    FSR_STATS.MP2FromBuffs = MP2FromBuffs
    FSR_STATS.GetSpellRank = GetSpellRank

end