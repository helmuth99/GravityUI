-- Migriere veraltete Datatext-Toggles zu Slot-basierter Konfiguration
local function MigrateDatatextSlots(dt)
    if not dt then return end
    if dt.slots then return end  -- Bereits migriert

    -- Baue Slots aus Legacy-Flags auf
    dt.slots = {}

    -- Prioritätsreihenfolge: time, friends, guild (entspricht alter Komposit-Reihenfolge)
    if dt.showTime then table.insert(dt.slots, "time") end
    if dt.showFriends then table.insert(dt.slots, "friends") end
    if dt.showGuild then table.insert(dt.slots, "guild") end

    -- Fülle auf 3 Slots mit leeren Strings auf
    while #dt.slots < 3 do
        table.insert(dt.slots, "")
    end
end

-- Migriere globale shortLabels zu Per-Slot-Konfiguration
local function MigratePerSlotSettings(dt)
    if not dt then return end
    if dt.slot1 then return end  -- Bereits migriert

    -- Hole globalen shortLabels-Wert (aus vorheriger Implementierung)
    local globalShortLabels = dt.shortLabels or false

    -- Erstelle Per-Slot-Configs mit geerbter globaler Einstellung
    dt.slot1 = { shortLabel = globalShortLabels, xOffset = 0, yOffset = 0 }
    dt.slot2 = { shortLabel = globalShortLabels, xOffset = 0, yOffset = 0 }
    dt.slot3 = { shortLabel = globalShortLabels, xOffset = 0, yOffset = 0 }
end

-- Migriere veraltetes classColorText zu neuen Master-Text-Color-Toggles
local function MigrateMasterTextColors(general)
    if not general then return end

    -- Falls veraltetes classColorText aktiviert war, migriere zu neuen Master-Toggles
    if general.classColorText == true and general.masterColorNameText == nil then
        general.masterColorNameText = true
        general.masterColorHealthText = true
        -- Lasse power/castbar/ToT als false (neue Features nicht von Legacy-Toggle abgedeckt)
    end

    -- Initialisiere nil-Werte zu false (für frische Profile oder Profile ohne Legacy-Toggle)
    if general.masterColorNameText == nil then general.masterColorNameText = false end
    if general.masterColorHealthText == nil then general.masterColorHealthText = false end
    if general.masterColorPowerText == nil then general.masterColorPowerText = false end
    if general.masterColorCastbarText == nil then general.masterColorCastbarText = false end
    if general.masterColorToTText == nil then general.masterColorToTText = false end
end

-- Migriere chat.styleEditBox Boolean zu chat.editBox Tabelle
local function MigrateChatEditBox(chat)
    if not chat then return end
    if chat.editBox then return end  -- Bereits migriert

    -- Erstelle editBox-Tabelle aus veralteten styleEditBox Boolean
    chat.editBox = {
        enabled = chat.styleEditBox ~= false,  -- Standard true falls nil oder true
        bgAlpha = 0.25,
        bgColor = {0, 0, 0},
    }

    -- Entferne veralteten Schlüssel
    chat.styleEditBox = nil
end

-- Migriere veraltetes cooldownSwipe (hideEssential/hideUtility) zu neuem 3-Toggle-System
local function MigrateCooldownSwipeV2(profile)
    if not profile then return end
    if not profile.cooldownSwipe then profile.cooldownSwipe = {} end

    local cs = profile.cooldownSwipe
    if cs.migratedToV2 then return end  -- Bereits migriert

    -- Prüfe alte Einstellungen
    local hadHideEssential = cs.hideEssential == true
    local hadHideUtility = cs.hideUtility == true
    local hadHideBuffSwipe = profile.cooldownManager and profile.cooldownManager.hideSwipe == true

    -- Migration: Falls User Swipes versteckt hatte, wollte er wahrscheinlich GCD-Clutter verstecken
    -- Gebe ihm Spell-Cooldowns zurück, aber behalte GCD versteckt
    if hadHideEssential or hadHideUtility or hadHideBuffSwipe then
        cs.showBuffSwipe = true
        cs.showGCDSwipe = false       -- Verstecke GCD (was die meisten User wollten)
        cs.showCooldownSwipe = true   -- Zeige echte Cooldowns
    else
        -- Frisch oder nie versteckt: zeige alles
        cs.showBuffSwipe = true
        cs.showGCDSwipe = true
        cs.showCooldownSwipe = true
    end

    -- Bereinige veraltete Schlüssel
    cs.hideEssential = nil
    cs.hideUtility = nil
    if profile.cooldownManager then
        profile.cooldownManager.hideSwipe = nil
    end

    cs.migratedToV2 = true
end

function GravityUI:BackwardsCompat()
    -- Vor 20241104: Letzte Versionsdaten wurden in char-spezifischen und Standard-Profilen gespeichert

    -- Migriere Datatext-Einstellungen zu Slot-basierter Architektur
    if self.db and self.db.profile and self.db.profile.datatext then
        MigrateDatatextSlots(self.db.profile.datatext)
        MigratePerSlotSettings(self.db.profile.datatext)
    end

    -- Migriere Master-Text-Color-Toggles (Legacy classColorText → neues System)
    if self.db and self.db.profile and self.db.profile.guiUnitFrames and self.db.profile.guiUnitFrames.general then
        MigrateMasterTextColors(self.db.profile.guiUnitFrames.general)
    end

    -- Migriere chat styleEditBox Boolean zu editBox-Tabelle
    if self.db and self.db.profile and self.db.profile.chat then
        MigrateChatEditBox(self.db.profile.chat)
    end

    -- Migriere cooldownSwipe zu v2 (3-Toggle-System)
    if self.db and self.db.profile then
        MigrateCooldownSwipeV2(self.db.profile)
    end

    -- Stelle sicher dass db.global existiert und benötigte Felder hat
    if not self.db.global then
        self:DebugPrint("DB Global not found")
        self.db.global = {
            isDone = false,
            lastVersion = 0,
            imports = {}
        }
    end
    
    -- Stelle sicher dass db.global alle benötigten Felder hat
    if not self.db.global.isDone then
        self.db.global.isDone = false
    end
    if not self.db.global.lastVersion then
        self.db.global.lastVersion = 0
    end
    if not self.db.global.imports then
        self.db.global.imports = {}
    end
    
    -- Initialisiere Spezifikations-spezifische Tracker-Spell-Speicherung
    if not self.db.global.specTrackerSpells then
        self.db.global.specTrackerSpells = {}
    end
    -- Stelle sicher dass db.char existiert und Debug-Tabelle hat
    if self.db.char then
        if not self.db.char.debug then
            self.db.char.debug = { reload = false }
        end
        
        -- Falls lastVersion in self.db.char angegeben ist, aber nicht in db.global - verschiebe zu db.global und entferne aus char
        if self.db.char.lastVersion and not self.db.global.lastVersion then
            self:DebugPrint("Last version found in char profile, but not global.")
            self.db.global.lastVersion = self.db.char.lastVersion
            self.db.char.lastVersion = nil
        end
    end
    
    -- Prüfe ob alte Profil-basierte Imports existieren
    if GravityUI_DB and GravityUI_DB.profiles and GravityUI_DB.profiles.Default then
        self:DebugPrint("Profiles.Default.imports Exists: " .. tostring(not (not GravityUI_DB.profiles.Default.imports)))
        self:DebugPrint("global.imports Exists: " .. tostring(not (not self.db.global.imports)))
        self:DebugPrint("global.imports is {}: " .. tostring(self.db.global.imports == {}))
        -- Falls imports in Default-Profil-DB sind, aber nicht in global, verschiebe sie
        if GravityUI_DB.profiles.Default.imports and (not self.db.global.imports or next(self.db.global.imports) == nil) then
            self:DebugPrint("Import Data found in profile imports but not global imports.")
            self.db.global.imports = GravityUI_DB.profiles.Default.imports
        end
    end
end
