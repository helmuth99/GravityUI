local ADDON_NAME, ns = ...
local SoundAlerts = {}
ns.SoundAlerts = SoundAlerts

local LSM = LibStub("LibSharedMedia-3.0", true)

-- ============================================================================
-- SOUND DATA MAPPING
-- ============================================================================
local SOUND_DATA = {
    { key = "BoatHorn",        name = "Boat Horn",          fileId = 7466062, triggerId = 316442 },
    { key = "AirHorn",         name = "Air Horn",           fileId = 7466054, triggerId = 316436 },
    { key = "BikeHorn",        name = "Bike Horn",          fileId = 7466947, triggerId = 316713 },
    { key = "CashRegister",    name = "Cash Register",      fileId = 7466070, triggerId = 316446 },
    { key = "JackpotBell",     name = "Jackpot Bell",       fileId = 7466955, triggerId = 316717 },
    { key = "JackpotCoins",    name = "Jackpot Coins",      fileId = 7466957, triggerId = 316718 },
    { key = "JackpotFail",     name = "Jackpot Fail",       fileId = 7466959, triggerId = 316719 },
    { key = "RotaryPhoneDial", name = "Rotary Phone Dial",  fileId = 7466048, triggerId = 316433 },
    { key = "RotaryPhoneRing", name = "Rotary Phone Ring",  fileId = 7466124, triggerId = 316492 },
    { key = "StovePipe",       name = "Stove Pipe",         fileId = 7466036, triggerId = 316425 },
    { key = "TrashcanLid",     name = "Trashcan Lid",       fileId = 7466046, triggerId = 316430 },
}

SoundAlerts.SOUND_DATA = SOUND_DATA

-- ============================================================================
-- CORE LOGIC
-- ============================================================================

local function GetSettings()
    local db = ns.GetDB()
    if not db then return nil end
    
    if not db.soundAlerts then
        db.soundAlerts = {
            enabled = true,
            sounds = {}
        }
    end
    
    -- Ensure all keys exist
    for _, info in ipairs(SOUND_DATA) do
        if not db.soundAlerts.sounds[info.key] then
            db.soundAlerts.sounds[info.key] = {
                enabled = false,
                sound = nil
            }
        end
    end
    
    return db.soundAlerts
end

function SoundAlerts.ApplySettings()
    local settings = GetSettings()
    if not settings then return end
    
    if not settings.enabled then
        -- Mute everything if module is disabled
        for _, info in ipairs(SOUND_DATA) do
            UnmuteSoundFile(info.fileId)
        end
        return
    end

    -- Process toggles
    for _, info in ipairs(SOUND_DATA) do
        local sndConfig = settings.sounds[info.key]
        if sndConfig and sndConfig.enabled then
             MuteSoundFile(info.fileId)
        else
             UnmuteSoundFile(info.fileId)
        end
    end
end

local DEBUG_SOUNDS = false
local lastPlayed = {}
local SOUND_THROTTLE = 3.0 -- Increased to 3s to debounce rapid double-fires from BCDM

-- Hook PlaySound
hooksecurefunc("PlaySound", function(soundID, channel)
    local id = tonumber(soundID)
    if not id then return end
    
    local settings = GetSettings()
    if not settings or not settings.enabled then return end

    for _, info in ipairs(SOUND_DATA) do
        if info.triggerId == id then
            local sndConfig = settings.sounds[info.key]
            if sndConfig and sndConfig.enabled and sndConfig.sound and sndConfig.sound ~= "None" then
                local now = GetTime()
                
                if DEBUG_SOUNDS then
                    ns.Print("PlaySound Blocked: " .. info.name .. " Channel: " .. tostring(channel))
                    -- Print exactly who is calling this
                    print(debugstack(2, 2, 0)) 
                end

                if not lastPlayed[info.key] or (now - lastPlayed[info.key] > SOUND_THROTTLE) then
                    if LSM then
                        local soundFile = LSM:Fetch("sound", sndConfig.sound)
                        if soundFile then
                            lastPlayed[info.key] = now
                            PlaySoundFile(soundFile, channel or "Master")
                        end
                    end
                end
            end
            break -- Found the sound, stop checking
        end
    end
end)

-- Hook PlaySoundFile
hooksecurefunc("PlaySoundFile", function(fileID, channel)
    if SoundAlerts._previewing then return end -- Avoid infinite loop when clicking the UI dropdown
    if SoundAlerts._playingCustom then return end -- Avoid re-triggering our own PlaySoundFile call
    
    local id = tonumber(fileID)
    if not id then return end
    
    local settings = GetSettings()
    if not settings or not settings.enabled then return end
    
    for _, info in ipairs(SOUND_DATA) do
        if info.fileId == id then
            local sndConfig = settings.sounds[info.key]
            if sndConfig and sndConfig.enabled and sndConfig.sound and sndConfig.sound ~= "None" then
                local now = GetTime()

                if DEBUG_SOUNDS then
                    ns.Print("PlaySoundFile Blocked: " .. info.name .. " Channel: " .. tostring(channel))
                    print(debugstack(2, 2, 0)) 
                end

                if not lastPlayed[info.key] or (now - lastPlayed[info.key] > SOUND_THROTTLE) then
                    if LSM then
                        local soundFile = LSM:Fetch("sound", sndConfig.sound)
                        if soundFile then
                            lastPlayed[info.key] = now
                            SoundAlerts._playingCustom = true
                            PlaySoundFile(soundFile, channel or "Master")
                            SoundAlerts._playingCustom = false
                        end
                    end
                end
            end
            break -- Found the sound, stop checking
        end
    end
end)

-- ============================================================================
-- INITIALIZER
-- ============================================================================

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_ENTERING_WORLD" then
        SoundAlerts.ApplySettings()
    end
end)
