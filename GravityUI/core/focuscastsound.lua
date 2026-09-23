-- GravityUI - Focus Castbar Sound Alert
-- Plays a configurable sound when the focus target starts casting.
-- Settings live under db.uiimprovements.focusCastSound.
local ADDON_NAME, ns = ...

local LSM = LibStub("LibSharedMedia-3.0", true)

local function GetConfig()
    local db = ns.GetDB()
    return db and db.uiimprovements and db.uiimprovements.focusCastSound
end

local function PlayFocusSound()
    local cfg = GetConfig()
    if not cfg or not cfg.enabled then return end
    local soundName = cfg.soundFile or "Focus"
    local channel = cfg.soundChannel or "Master"
    local soundPath = LSM and LSM:Fetch("sound", soundName)
    if soundPath then
        PlaySoundFile(soundPath, channel)
    else
        PlaySound(SOUNDKIT.RAID_WARNING or 8959, channel)
    end
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:SetScript("OnEvent", function(self, event, unit)
    if event == "PLAYER_LOGIN" then
        local cfg = GetConfig()
        if cfg and cfg.enabled then
            ev:RegisterEvent("UNIT_SPELLCAST_START")
            ev:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
        end
        return
    end
    if unit ~= "focus" then return end
    PlayFocusSound()
end)

-------------------------------------------------------------------------------
--  Public API (for settings page live-toggle)
-------------------------------------------------------------------------------
ns.FocusCastSound = {
    ApplySettings = function()
        local cfg = GetConfig()
        if cfg and cfg.enabled then
            ev:RegisterEvent("UNIT_SPELLCAST_START")
            ev:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
        else
            ev:UnregisterEvent("UNIT_SPELLCAST_START")
            ev:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_START")
        end
    end,
    TestSound = function()
        PlayFocusSound()
    end,
}
