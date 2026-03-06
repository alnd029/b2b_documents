Config = {}

Config.Locale = "en"               -- Locale: "fr" or "en"
Config.UseAnimation = false         -- Enable ped animation on document open
Config.Framework = "auto"           -- auto, esx, qbox, or qbcore
Config.PaperCooldown = 30           -- Cooldown in seconds between paper pickups at distribution points

Config.DistributionPoints = {
    {
        name = "City Hall",
        coords = vector3(-544.7, -204.1, 40),   -- Coordinates
        heading = 210.5,                          -- Heading (important if ped is enabled)
        usePed = true,                            -- Spawn a NPC ped at this location
        pedModel = "s_m_m_postal_01",             -- Ped model name
        targetLabel = "Take a blank sheet",
        targetIcon = "fas fa-file-signature"
    },
    {
        name = "Police Station",
        coords = vector3(440.953857, -980.228577, 31.925293),
        heading = 170.0,
        usePed = false,                           -- No ped, interaction zone only
        pedModel = "",
        targetLabel = "Take a blank sheet",
        targetIcon = "fas fa-clipboard"
    },
    -- Add more points following the model above
}

-- Translation helper — do not edit
function T(key)
    return (Locale and Locale[key]) or ("[" .. tostring(key) .. "]")
end
