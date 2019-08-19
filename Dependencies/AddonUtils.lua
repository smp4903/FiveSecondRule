AddonUtils = {}

function AddonUtils:modulus(a,b)
    return a - math.floor(a/b)*b
end

function AddonUtils:deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[AddonUtils:deepcopy(orig_key)] = AddonUtils:deepcopy(orig_value)
        end
        setmetatable(copy, AddonUtils:deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end