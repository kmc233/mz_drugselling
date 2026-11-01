Locales = Locales or {}

local function copy_with_fallback(fallback, selected)
    local result = {}
    for key, value in pairs(fallback or {}) do
        result[key] = type(value) == 'table' and copy_with_fallback(value, nil) or value
    end
    for key, value in pairs(selected or {}) do
        result[key] = type(value) == 'table'
            and copy_with_fallback(result[key], value)
            or value
    end
    return result
end

local requested_locale = string.lower(config.locale or 'en')
local selected_locale = Locales[requested_locale] and requested_locale or 'en'
lang = copy_with_fallback(Locales.en, Locales[selected_locale])
