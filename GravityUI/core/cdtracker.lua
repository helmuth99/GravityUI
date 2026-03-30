local ADDON_NAME, ns = ...
local CDTracker = {}
ns.CDTracker = CDTracker
LibStub("AceEvent-3.0"):Embed(CDTracker)

-- ============================================================================
-- SPELL DATABASE  (specID → list of {id, cd, cat, name})
-- cat: "DEF" = defensive, "OFF" = offensive
-- ============================================================================
local SYNC_SPELLS = {

    -- ── Death Knight ──────────────────────────────────────────────────────
    [250] = { -- Blood
        { id=49028,  cd=90,  cat="OFF", name="Dancing Rune Weapon"  },
        { id=51052,  cd=120, cat="DEF", name="Anti-Magic Zone"      },
        { id=49039,  cd=120, cat="DEF", name="Lichborne"            },
        { id=55233,  cd=180, cat="DEF", name="Vampiric Blood"       },
        { id=48707,  cd=60,  cat="DEF", name="Anti-Magic Shell"     },
        { id=48792,  cd=120, cat="DEF", name="Icebound Fortitude"   },
    },
    [251] = { -- Frost
        { id=51052,  cd=120, cat="DEF", name="Anti-Magic Zone"      },
        { id=49039,  cd=120, cat="DEF", name="Lichborne"            },
        { id=48707,  cd=60,  cat="DEF", name="Anti-Magic Shell"     },
        { id=48792,  cd=120, cat="DEF", name="Icebound Fortitude"   },
    },
    [252] = { -- Unholy
        { id=42650,    cd=90,  cat="OFF", name="Army of the Dead"      },
        { id=1233448,  cd=45,  cat="OFF", name="Dark Transformation"   },
        { id=51052,    cd=120, cat="DEF", name="Anti-Magic Zone"       },
        { id=49039,    cd=120, cat="DEF", name="Lichborne"             },
        { id=48707,    cd=60,  cat="DEF", name="Anti-Magic Shell"      },
        { id=48792,    cd=120, cat="DEF", name="Icebound Fortitude"    },
    },

    -- ── Demon Hunter ──────────────────────────────────────────────────────
    [577] = { -- Havoc
        { id=198589, cd=60,  cat="DEF", name="Blur"                 },
        { id=196555, cd=180, cat="DEF", name="Netherwalk"           },
    },
    [581] = { -- Vengeance
        { id=204021, cd=60,  cat="DEF", name="Fiery Brand"          },
        { id=187827, cd=120, cat="DEF", name="Metamorphosis"        },
        { id=196718, cd=300, cat="DEF", name="Darkness"             },
    },

    -- ── Druid ─────────────────────────────────────────────────────────────
    [102] = { -- Balance
        { id=22812,  cd=60,  cat="DEF", name="Barkskin"             },
        { id=194223, cd=180, cat="OFF", name="Celestial Alignment"  },
    },
    [103] = { -- Feral
        { id=106951, cd=180, cat="OFF", name="Berserk"              },
        { id=61336,  cd=180, cat="DEF", name="Survival Instincts"   },
    },
    [104] = { -- Guardian
        { id=22812,  cd=60,  cat="DEF", name="Barkskin"             },
        { id=102558, cd=180, cat="DEF", name="Incarnation"          },
        { id=61336,  cd=180, cat="DEF", name="Survival Instincts"   },
        { id=22842,  cd=36,  cat="DEF", name="Frenzied Regeneration" },
    },
    [105] = { -- Restoration
        { id=22812,  cd=60,  cat="DEF", name="Barkskin"             },
        { id=102342, cd=90,  cat="DEF", name="Ironbark"             },
    },

    -- ── Evoker ────────────────────────────────────────────────────────────
    [1467] = { -- Devastation
        { id=375087, cd=120, cat="OFF", name="Dragonrage"           },
        { id=363916, cd=90,  cat="DEF", name="Obsidian Scales"      },
        { id=357210, cd=120, cat="OFF", name="Deep Breath"          },
        { id=374227, cd=120, cat="DEF", name="Zephyr"               },
    },
    [1468] = { -- Preservation
        { id=357170, cd=60,  cat="DEF", name="Rewind"               },
        { id=363916, cd=90,  cat="DEF", name="Obsidian Scales"      },
        { id=374227, cd=120, cat="DEF", name="Zephyr"               },
    },
    [1473] = { -- Augmentation
        { id=363916, cd=90,  cat="DEF", name="Obsidian Scales"      },
        { id=403631, cd=120, cat="OFF", name="Breath of Eons"       },
        { id=374227, cd=120, cat="DEF", name="Zephyr"               },
    },

    -- ── Hunter ────────────────────────────────────────────────────────────
    [253] = { -- Beast Mastery
        { id=19574,  cd=90,  cat="OFF", name="Bestial Wrath"        },
        { id=186265, cd=180, cat="DEF", name="Aspect of the Turtle" },
        { id=264735, cd=180, cat="DEF", name="Survival of the Fittest" },
        { id=109304, cd=120, cat="DEF", name="Exhilaration"         },
    },
    [254] = { -- Marksmanship
        { id=288613, cd=120, cat="OFF", name="Trueshot"             },
        { id=186265, cd=180, cat="DEF", name="Aspect of the Turtle" },
        { id=264735, cd=180, cat="DEF", name="Survival of the Fittest" },
        { id=109304, cd=120, cat="DEF", name="Exhilaration"         },
    },
    [255] = { -- Survival
        { id=266779, cd=120, cat="OFF", name="Coordinated Assault"  },
        { id=186265, cd=180, cat="DEF", name="Aspect of the Turtle" },
        { id=264735, cd=180, cat="DEF", name="Survival of the Fittest" },
        { id=109304, cd=120, cat="DEF", name="Exhilaration"         },
    },

    -- ── Mage ──────────────────────────────────────────────────────────────
    [62] = { -- Arcane
        { id=365350, cd=90,  cat="OFF", name="Arcane Surge"         },
        { id=45438,  cd=180, cat="DEF", name="Ice Block"            },
        { id=55342,  cd=120, cat="DEF", name="Mirror Image"         },
        { id=110959, cd=120, cat="DEF", name="Greater Invisibility" },
    },
    [63] = { -- Fire
        { id=190319, cd=120, cat="OFF", name="Combustion"           },
        { id=45438,  cd=180, cat="DEF", name="Ice Block"            },
        { id=55342,  cd=120, cat="DEF", name="Mirror Image"         },
        { id=110959, cd=120, cat="DEF", name="Greater Invisibility" },
    },
    [64] = { -- Frost
        { id=12472,  cd=120, cat="OFF", name="Icy Veins"            },
        { id=45438,  cd=180, cat="DEF", name="Ice Block"            },
        { id=55342,  cd=120, cat="DEF", name="Mirror Image"         },
        { id=110959, cd=120, cat="DEF", name="Greater Invisibility" },
    },

    -- ── Monk ──────────────────────────────────────────────────────────────
    [268] = { -- Brewmaster
        { id=322507, cd=60,  cat="DEF", name="Celestial Brew"       },
        { id=115203, cd=420, cat="DEF", name="Fortifying Brew"      },
    },
    [269] = { -- Windwalker
        { id=116844, cd=45,  cat="DEF", name="Touch of Karma"       },
        { id=137639, cd=90,  cat="OFF", name="Storm, Earth, and Fire" },
        { id=122783, cd=90,  cat="DEF", name="Diffuse Magic"        },
    },
    [270] = { -- Mistweaver
        { id=116844, cd=45,  cat="DEF", name="Touch of Karma"       },
        { id=115310, cd=180, cat="DEF", name="Revival"              },
        { id=122783, cd=90,  cat="DEF", name="Diffuse Magic"        },
        { id=116849, cd=120, cat="DEF", name="Life Cocoon"          },
    },

    -- ── Paladin ───────────────────────────────────────────────────────────
    [65] = { -- Holy
        { id=31821,  cd=180, cat="DEF", name="Aura Mastery"         },
        { id=1022,   cd=300, cat="DEF", name="Blessing of Protection" },
        { id=642,    cd=300, cat="DEF", name="Divine Shield"        },
        { id=633,    cd=600, cat="DEF", name="Lay on Hands"         },
        { id=498,    cd=60,  cat="DEF", name="Divine Protection"    },
    },
    [66] = { -- Protection
        { id=31850,  cd=120, cat="DEF", name="Ardent Defender"      },
        { id=86659,  cd=300, cat="DEF", name="Guardian of Ancient Kings" },
        { id=642,    cd=300, cat="DEF", name="Divine Shield"        },
        { id=633,    cd=600, cat="DEF", name="Lay on Hands"         },
    },
    [70] = { -- Retribution
        { id=1022,   cd=300, cat="DEF", name="Blessing of Protection" },
        { id=642,    cd=300, cat="DEF", name="Divine Shield"        },
        { id=633,    cd=600, cat="DEF", name="Lay on Hands"         },
        { id=184662, cd=120, cat="DEF", name="Shield of Vengeance"  },
    },

    -- ── Priest ────────────────────────────────────────────────────────────
    [256] = { -- Discipline
        { id=10060,  cd=120, cat="OFF", name="Power Infusion"       },
        { id=19236,  cd=90,  cat="DEF", name="Desperate Prayer"     },
        { id=33206,  cd=180, cat="DEF", name="Pain Suppression"     },
    },
    [257] = { -- Holy
        { id=10060,  cd=120, cat="OFF", name="Power Infusion"       },
        { id=19236,  cd=90,  cat="DEF", name="Desperate Prayer"     },
        { id=47788,  cd=180, cat="DEF", name="Guardian Spirit"      },
    },
    [258] = { -- Shadow
        { id=10060,  cd=120, cat="OFF", name="Power Infusion"       },
        { id=19236,  cd=90,  cat="DEF", name="Desperate Prayer"     },
        { id=47585,  cd=120, cat="DEF", name="Dispersion"           },
    },

    -- ── Rogue ─────────────────────────────────────────────────────────────
    [259] = { -- Assassination
        { id=31224,  cd=120, cat="DEF", name="Cloak of Shadows"     },
        { id=5277,   cd=120, cat="DEF", name="Evasion"              },
        { id=1856,   cd=120, cat="DEF", name="Vanish"               },
    },
    [260] = { -- Outlaw
        { id=13750,  cd=180, cat="OFF", name="Adrenaline Rush"      },
        { id=31224,  cd=120, cat="DEF", name="Cloak of Shadows"     },
        { id=5277,   cd=120, cat="DEF", name="Evasion"              },
        { id=1856,   cd=120, cat="DEF", name="Vanish"               },
    },
    [261] = { -- Subtlety
        { id=121471, cd=180, cat="OFF", name="Shadow Blades"        },
        { id=31224,  cd=120, cat="DEF", name="Cloak of Shadows"     },
        { id=5277,   cd=120, cat="DEF", name="Evasion"              },
        { id=1856,   cd=120, cat="DEF", name="Vanish"               },
    },

    -- ── Shaman ────────────────────────────────────────────────────────────
    [262] = { -- Elemental
        { id=191634, cd=60,  cat="OFF", name="Stormkeeper"          },
        { id=114050, cd=180, cat="OFF", name="Ascendance"           },
        { id=108271, cd=90,  cat="DEF", name="Astral Shift"         },
        { id=198103, cd=300, cat="DEF", name="Earth Elemental"      },
        { id=108270, cd=60,  cat="DEF", name="Stone Bulwark Totem"  },
    },
    [263] = { -- Enhancement
        { id=114050, cd=180, cat="OFF", name="Ascendance"           },
        { id=108271, cd=90,  cat="DEF", name="Astral Shift"         },
        { id=198103, cd=300, cat="DEF", name="Earth Elemental"      },
    },
    [264] = { -- Restoration
        { id=108271, cd=90,  cat="DEF", name="Astral Shift"         },
        { id=98008,  cd=180, cat="DEF", name="Spirit Link Totem"    },
        { id=198103, cd=300, cat="DEF", name="Earth Elemental"      },
        { id=108270, cd=60,  cat="DEF", name="Stone Bulwark Totem"  },
    },

    -- ── Warlock ───────────────────────────────────────────────────────────
    [265] = { -- Affliction
        { id=108416, cd=60,  cat="DEF", name="Dark Pact"            },
        { id=104773, cd=180, cat="DEF", name="Unending Resolve"     },
    },
    [266] = { -- Demonology
        { id=108416, cd=60,  cat="DEF", name="Dark Pact"            },
        { id=104773, cd=180, cat="DEF", name="Unending Resolve"     },
    },
    [267] = { -- Destruction
        { id=108416, cd=60,  cat="DEF", name="Dark Pact"            },
        { id=104773, cd=180, cat="DEF", name="Unending Resolve"     },
    },

    -- ── Warrior ───────────────────────────────────────────────────────────
    [71] = { -- Arms
        { id=118038, cd=120, cat="DEF", name="Die by the Sword"     },
        { id=97462,  cd=180, cat="DEF", name="Rallying Cry"         },
        { id=23920,  cd=18,  cat="DEF", name="Spell Reflection"     },
    },
    [72] = { -- Fury
        { id=184364, cd=120, cat="DEF", name="Enraged Regeneration" },
        { id=97462,  cd=180, cat="DEF", name="Rallying Cry"         },
        { id=23920,  cd=18,  cat="DEF", name="Spell Reflection"     },
    },
    [73] = { -- Protection
        { id=871,    cd=168, cat="DEF", name="Shield Wall"          },
        { id=12975,  cd=180, cat="DEF", name="Last Stand"           },
        { id=97462,  cd=180, cat="DEF", name="Rallying Cry"         },
        { id=23920,  cd=18,  cat="DEF", name="Spell Reflection"     },
    },
}

-- Fast reverse lookup: spellID → { cd, cat, name }
local SPELL_LOOKUP = {}
for specID, spells in pairs(SYNC_SPELLS) do
    for _, s in ipairs(spells) do
        if not SPELL_LOOKUP[s.id] then
            SPELL_LOOKUP[s.id] = { cd = s.cd, cat = s.cat, name = s.name }
        end
    end
end
ns.CDTracker.SYNC_SPELLS  = SYNC_SPELLS
ns.CDTracker.SPELL_LOOKUP = SPELL_LOOKUP

-- specID to class mapping (for the settings panel spell list)
local SPEC_TO_CLASS = {
    [250]="DEATHKNIGHT", [251]="DEATHKNIGHT", [252]="DEATHKNIGHT",
    [577]="DEMONHUNTER", [581]="DEMONHUNTER",
    [102]="DRUID",       [103]="DRUID",       [104]="DRUID",   [105]="DRUID",
    [1467]="EVOKER",     [1468]="EVOKER",     [1473]="EVOKER",
    [253]="HUNTER",      [254]="HUNTER",      [255]="HUNTER",
    [62]="MAGE",         [63]="MAGE",         [64]="MAGE",
    [268]="MONK",        [269]="MONK",         [270]="MONK",
    [65]="PALADIN",      [66]="PALADIN",       [70]="PALADIN",
    [256]="PRIEST",      [257]="PRIEST",       [258]="PRIEST",
    [259]="ROGUE",       [260]="ROGUE",        [261]="ROGUE",
    [262]="SHAMAN",      [263]="SHAMAN",       [264]="SHAMAN",
    [265]="WARLOCK",     [266]="WARLOCK",      [267]="WARLOCK",
    [71]="WARRIOR",      [72]="WARRIOR",       [73]="WARRIOR",
}
ns.CDTracker.SPEC_TO_CLASS = SPEC_TO_CLASS

-- ============================================================================
-- CLASS COLORS
-- ============================================================================
local CLASS_COLORS = {
    DEATHKNIGHT = {0.77,0.12,0.23}, DEMONHUNTER = {0.64,0.19,0.79},
    DRUID       = {1.00,0.49,0.04}, EVOKER      = {0.20,0.58,0.50},
    HUNTER      = {0.67,0.83,0.45}, MAGE        = {0.25,0.78,0.92},
    MONK        = {0.00,1.00,0.59}, PALADIN     = {0.96,0.55,0.73},
    PRIEST      = {1.00,1.00,1.00}, ROGUE       = {1.00,0.96,0.41},
    SHAMAN      = {0.00,0.44,0.87}, WARLOCK     = {0.53,0.53,0.93},
    WARRIOR     = {0.78,0.61,0.43},
}

-- ============================================================================
-- DATABASE DEFAULTS
-- ============================================================================
local function GetDB()
    local db = ns.GetDB()
    if not db then return nil end
    return db.cdTracker
end

-- ============================================================================
-- STATE
-- ============================================================================
local cdState      = {}  -- [playerName][spellID] = cdEndTime
local knownUsers   = {}  -- [playerName] = { class, specID, _hasAddon }
local attachedBars = {}  -- [unit] = { frame, icons={spellID→ico} }
local myName       = nil
local myClass      = nil
local mySpecID     = nil
local inspectQueue = {}
local inspectBusy  = false
local testMode     = false

-- Taint-safe unit name extraction
local function SafeUnitName(unit)
    if not unit then return nil end
    local raw = UnitName(unit)
    if not raw then return nil end
    local ok, clean = pcall(string.format, "%s", raw)
    return ok and clean or nil
end

-- ============================================================================
-- NETWORKING  (prefix GRV_CD)
-- ============================================================================
local NET_PREFIX = "GRV_CD"
local NET_HDR    = "G1"
local NET_SEP    = ";"

local function Transmit(payload)
    if not IsInGroup() then return end
    local channel = IsInGroup(LE_PARTY_CATEGORY_INSTANCE) and "INSTANCE_CHAT" or "PARTY"
    local ok, ret = pcall(C_ChatInfo.SendAddonMessage, NET_PREFIX, payload, channel)
    if ok and ret == 0 then return end
    -- fallback PARTY
    if channel ~= "PARTY" then
        pcall(C_ChatInfo.SendAddonMessage, NET_PREFIX, payload, "PARTY")
    end
end

local function NetMsg(...)
    return table.concat({NET_HDR, ...}, NET_SEP)
end

-- Announce we joined (1x per zone/group)
local lastHelloTime = 0
local function AnnounceHello()
    if not myClass then return end
    local now = GetTime()
    if now - lastHelloTime < 5 then return end
    lastHelloTime = now
    Transmit(NetMsg("HELLO", myClass))
end

-- Broadcast own spell cast
local function AnnounceSpellCast(spellID, duration)
    Transmit(NetMsg("CAST", spellID, duration))
end

-- ============================================================================
-- INSPECT QUEUE (spec detection)
-- ============================================================================
local function ProcessInspectQueue()
    if inspectBusy then return end
    while #inspectQueue > 0 do
        local unit = table.remove(inspectQueue, 1)
        if UnitExists(unit) and UnitIsConnected(unit) then
            local name = SafeUnitName(unit)
            if name then
                inspectBusy = true
                NotifyInspect(unit)
                return
            end
        end
    end
end

local function QueueInspect(unit)
    for _, u in ipairs(inspectQueue) do
        if u == unit then return end
    end
    table.insert(inspectQueue, unit)
    ProcessInspectQueue()
end

-- ============================================================================
-- SPELLS FOR PLAYER (spec-filtered, category-filtered)
-- ============================================================================
local function GetSpellsForPlayer(name)
    local user = knownUsers[name]
    if not user then return {} end
    local specID = user.specID
    if not specID or not SYNC_SPELLS[specID] then return {} end
    local db = GetDB()
    if not db then return {} end
    local disabled = db.disabledSpells or {}
    local out = {}
    for _, s in ipairs(SYNC_SPELLS[specID]) do
        if (s.cat == "DEF" and db.showDEF) or (s.cat == "OFF" and db.showOFF) then
            if disabled[s.id] ~= false then   -- false = manually disabled
                table.insert(out, s)
            end
        end
    end
    return out
end

-- ============================================================================
-- PARTY FRAME DETECTION
-- ============================================================================
-- Helper: scan children of a container frame for a unit match
local function ScanChildren(container, unit)
    if not container then return nil end
    local ok, n = pcall(container.GetNumChildren, container)
    if not ok or not n or n == 0 then return nil end
    local ok2, children = pcall(function() return {container:GetChildren()} end)
    if not ok2 or not children then return nil end
    for _, child in ipairs(children) do
        if child then
            local childUnit = child.unit or child.displayedUnit or child.unitId
            if childUnit then
                local uok, isU = pcall(UnitIsUnit, childUnit, unit)
                if uok and isU then return child end
            end
        end
    end
    return nil
end

local function GetPartyUnitFrame(unit)
    local function vis(f) return f and f:IsShown() end

    -- Third-party unit frame addons (ElvUI)
    if _G["ElvUI"] then
        local group = _G["ElvUF_PartyGroup1"]
        if group then
            local f = ScanChildren(group, unit)
            if vis(f) then return f end
        end
        if unit == "player" then
            local pf = _G["ElvUF_Player"]
            if vis(pf) then return pf end
        end
        for i = 1, 5 do
            local f = _G["ElvUF_PartyGroup1UnitButton" .. i]
            if vis(f) and f.unit and UnitIsUnit(f.unit, unit) then return f end
        end
    end

    -- Unit frame addon support (scan known container globals)
    local danContainers = {
        "DandersPartyHeader",
        "DandersPartyHeaderContainer",
        "DandersPartyFrame",
        "DandersGroupFrame",
    }
    for _, cname in ipairs(danContainers) do
        local container = _G[cname]
        if container then
            -- Scan children of the container
            local f = ScanChildren(container, unit)
            if vis(f) then return f end
            -- Also try numbered unit buttons
            for i = 0, 5 do
                local btn = _G[cname .. "UnitButton" .. i]
                if btn then
                    local btnUnit = btn.unit or btn.displayedUnit
                    if btnUnit then
                        local ok, isU = pcall(UnitIsUnit, btnUnit, unit)
                        if ok and isU and vis(btn) then return btn end
                    end
                end
            end
        end
    end
    -- Scan numbered unit buttons
    for i = 0, 5 do
        local btn = _G["DandersPartyHeaderUnitButton" .. i]
        if btn then
            local btnUnit = btn.unit or btn.displayedUnit
            if btnUnit then
                local ok, isU = pcall(UnitIsUnit, btnUnit, unit)
                if ok and isU and vis(btn) then return btn end
            end
        end
    end
    if unit == "player" then
        local pf = _G["DandersPlayerFrame"]
        if vis(pf) then return pf end
    end

    -- Additional unit frame addon globals
    for _, gname in ipairs({"UUF_PartyGroup", "UUFPartyGroup", "UUFPartyHeader"}) do
        local container = _G[gname]
        if container then
            local f = ScanChildren(container, unit)
            if vis(f) then return f end
        end
    end

    -- Blizzard party frames
    local pf = _G["PartyFrame"]
    if pf then
        for i = 1, 4 do
            local f = pf["MemberFrame" .. i]
            if f and f.unit then
                local ok, isU = pcall(UnitIsUnit, f.unit, unit)
                if ok and isU then return f end  -- show even if not visible
            end
        end
        local f2 = ScanChildren(pf, unit)
        if f2 then return f2 end
    end

    -- Blizzard Compact Frames
    for i = 1, 5 do
        local f = _G["CompactPartyFrameMember" .. i]
        if f and f.unit then
            local ok, isU = pcall(UnitIsUnit, f.unit, unit)
            if ok and isU then return f end
        end
    end
    for i = 1, 40 do
        local f = _G["CompactRaidFrame" .. i]
        if f and f.unit then
            local ok, isU = pcall(UnitIsUnit, f.unit, unit)
            if ok and isU then return f end
        end
    end

    -- PlayerFrame fallback
    if unit == "player" then
        local pf2 = _G["PlayerFrame"]
        if pf2 then return pf2 end  -- attach even if hidden
    end

    return nil
end

-- ICON CREATION
-- ============================================================================
local function CreateSpellIcon(parent, spellID, cd)
    local db = GetDB()
    local sz = (db and db.iconSize) or 28

    local f = CreateFrame("Frame", nil, parent)
    f:SetSize(sz, sz)

    -- Spell icon texture
    f.tex = f:CreateTexture(nil, "ARTWORK")
    f.tex:SetAllPoints()
    f.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    local iconFile = C_Spell.GetSpellTexture(spellID)
    if iconFile then f.tex:SetTexture(iconFile) end

    -- 1px black border
    local border = f:CreateTexture(nil, "BORDER")
    border:SetPoint("TOPLEFT",     f, "TOPLEFT",     -1,  1)
    border:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT",  1, -1)
    border:SetColorTexture(0, 0, 0, 1)
    f.border = border

    -- Cooldown swipe (CooldownFrameTemplate)
    f.cd = CreateFrame("Cooldown", nil, f, "CooldownFrameTemplate")
    f.cd:SetAllPoints()
    f.cd:SetDrawEdge(true)
    f.cd:SetReverse(false)
    f.cd:SetHideCountdownNumbers(true)

    -- Text overlay above swipe
    local textHolder = CreateFrame("Frame", nil, f)
    textHolder:SetAllPoints()
    textHolder:SetFrameLevel(f:GetFrameLevel() + 20)

    f.cdText = textHolder:CreateFontString(nil, "OVERLAY")
    f.cdText:SetFont("Fonts\\FRIZQT__.TTF", (db and db.fontSize) or 11, "OUTLINE")
    f.cdText:SetPoint("CENTER")
    f.cdText:Hide()

    -- Tooltip
    f:EnableMouse(true)
    f:SetScript("OnEnter", function()
        GameTooltip:SetOwner(f, "ANCHOR_RIGHT")
        GameTooltip:SetSpellByID(spellID)
        GameTooltip:Show()
    end)
    f:SetScript("OnLeave", function() GameTooltip:Hide() end)

    f.spellID = spellID
    f._cd     = cd or 30
    f._cdRunning = false
    return f
end

-- ============================================================================
-- ICON UPDATE  (called from ticker)
-- ============================================================================
local function FormatCdTime(sec)
    if sec >= 60 then
        return string.format("%d:%02d", math.floor(sec / 60), sec % 60)
    end
    return tostring(sec)
end

local function UpdateIcon(ico, cdEndTime)
    local now = GetTime()
    if cdEndTime > now then
        local rem = cdEndTime - now
        if not ico._cdRunning then
            ico.cd:SetCooldown(cdEndTime - ico._cd, ico._cd)
            ico._cdRunning = true
        end
        local sec = math.floor(rem + 0.5)
        if ico._lastSec ~= sec then
            ico._lastSec = sec
            ico.cdText:SetText(sec > 0 and FormatCdTime(sec) or "")
            ico.cdText:Show()
        end
        ico.tex:SetAlpha(0.35)
    else
        if ico._cdRunning then
            ico.cd:Clear()
            ico._cdRunning = false
            ico._lastSec   = nil
            ico.cdText:Hide()
            ico.tex:SetAlpha(1.0)
        end
    end
end

-- ============================================================================
-- BUILD ATTACHED BAR  (icons parented to party unit frame)
-- ============================================================================
local ATTACH_CFG = {
    LEFT   = { anchor="RIGHT",  relAnchor="LEFT",   ox=-4, oy=0 },
    RIGHT  = { anchor="LEFT",   relAnchor="RIGHT",  ox=4,  oy=0 },
    TOP    = { anchor="BOTTOM", relAnchor="TOP",    ox=0,  oy=4 },
    BOTTOM = { anchor="TOP",    relAnchor="BOTTOM", ox=0,  oy=-4 },
}

local function BuildAttachedBar(unit, name)
    local db = GetDB()
    if not db or not db.enabled then return end

    local parentFrame = GetPartyUnitFrame(unit)
    local user = knownUsers[name]
    local specID = user and user.specID

    -- Clean up old bar
    local existing = attachedBars[unit]
    if existing and existing.frame then
        existing.frame:Hide()
        attachedBars[unit] = nil
    end

    if not parentFrame then return end
    if not user then return end

    local spells = GetSpellsForPlayer(name)
    if #spells == 0 then return end

    local sz  = db.iconSize    or 28
    local pad = db.iconSpacing or 4
    local pos = db.attachPos   or "LEFT"
    local cfg = ATTACH_CFG[pos] or ATTACH_CFG.LEFT
    local oX  = (db.offsetX or 0)
    local oY  = (db.offsetY or 0)

    local bar = { icons = {} }
    bar.frame = CreateFrame("Frame", nil, parentFrame)
    bar.frame:SetFrameLevel(parentFrame:GetFrameLevel() + 10)
    bar.frame:SetPoint(cfg.anchor, parentFrame, cfg.relAnchor, cfg.ox + oX, cfg.oy + oY)

    -- Two rows: DEF (top), OFF (bottom) or single row depending on what's enabled
    local defSpells, offSpells = {}, {}
    for _, s in ipairs(spells) do
        if s.cat == "DEF" then table.insert(defSpells, s)
        else table.insert(offSpells, s) end
    end

    -- Per-position icon anchor so they stay flush to the party frame edge:
    --   LEFT   -> bar.TOPRIGHT, icons grow leftward  (right-flush to frame)
    --   RIGHT  -> bar.TOPLEFT,  icons grow rightward (left-flush to frame)
    --   TOP    -> bar.BOTTOMLEFT, icons grow upward per row
    --   BOTTOM -> bar.TOPLEFT,  icons grow downward
    local function PlaceRow(spellList, rowIndex)
        for i, s in ipairs(spellList) do
            local ico = CreateSpellIcon(bar.frame, s.id, s.cd)
            if pos == "LEFT" then
                local xOff = -(i - 1) * (sz + pad)
                local yOff = -rowIndex * (sz + 2)
                ico:SetPoint("TOPRIGHT", bar.frame, "TOPRIGHT", xOff, yOff)
            elseif pos == "RIGHT" then
                local xOff = (i - 1) * (sz + pad)
                local yOff = -rowIndex * (sz + 2)
                ico:SetPoint("TOPLEFT", bar.frame, "TOPLEFT", xOff, yOff)
            elseif pos == "TOP" then
                local xOff = (i - 1) * (sz + pad)
                local yOff = rowIndex * (sz + 2)
                ico:SetPoint("BOTTOMLEFT", bar.frame, "BOTTOMLEFT", xOff, yOff)
            else
                local xOff = (i - 1) * (sz + pad)
                local yOff = -rowIndex * (sz + 2)
                ico:SetPoint("TOPLEFT", bar.frame, "TOPLEFT", xOff, yOff)
            end
            ico:Show()
            bar.icons[s.id] = ico
        end
    end

    local rowH = sz + 2
    PlaceRow(defSpells, 0)
    PlaceRow(offSpells, #defSpells > 0 and 1 or 0)

    local maxPerRow = math.max(#defSpells, #offSpells, 1)
    local rows = (#defSpells > 0 and 1 or 0) + (#offSpells > 0 and 1 or 0)
    bar.frame:SetSize(maxPerRow * sz + math.max(0, maxPerRow - 1) * pad, rows * rowH)
    bar.frame:Show()


    attachedBars[unit] = bar
end

-- ============================================================================
-- REBUILD ALL BARS
-- ============================================================================
local function RebuildAll()
    -- Hide all existing
    for unit, bar in pairs(attachedBars) do
        if bar.frame then bar.frame:Hide() end
    end
    attachedBars = {}

    local db = GetDB()
    if not db or not db.enabled then return end
    if not IsInGroup() and not testMode then return end
    if IsInRaid() and not testMode then return end  -- M+ only, not raids

    -- Own player
    if myName then
        BuildAttachedBar("player", myName)
    end
    -- Party members
    for i = 1, 4 do
        local unit = "party" .. i
        if UnitExists(unit) then
            local name = SafeUnitName(unit)
            if name and knownUsers[name] then
                BuildAttachedBar(unit, name)
            end
        end
    end
end

-- ============================================================================
-- OWN PLAYER DETECTION  (UNIT_SPELLCAST_SUCCEEDED for "player")
-- No taint — own spell IDs are always clean!
-- ============================================================================
local playerWatcher = CreateFrame("Frame")
playerWatcher:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
playerWatcher:SetScript("OnEvent", function(_, _, _, _, spellId)
    -- spellId from player is clean (no taint on own casts)
    local ok, spellData = pcall(function() return SPELL_LOOKUP[spellId] end)
    if not ok or not spellData then return end

    local db = GetDB()
    if not db or not db.enabled then return end
    if not ((spellData.cat == "DEF" and db.showDEF) or (spellData.cat == "OFF" and db.showOFF)) then return end

    local now = GetTime()
    local cdEnd = now + spellData.cd

    if not cdState[myName] then cdState[myName] = {} end
    cdState[myName][spellId] = cdEnd

    -- Broadcast to party members with GravityUI
    AnnounceSpellCast(spellId, spellData.cd)
end)


-- ============================================================================
-- LIBOPENRAID INTEGRATION
-- Receives CD data from ANY party member running an OpenRaid-enabled addon:
-- BigWigs, WeakAuras, DBM, Details, etc. — no GravityUI required on their side.
-- ============================================================================

-- Resolve a LibOpenRaid unitId to a clean player name for cdState lookup.
-- unitId is either "player" or a full player name (e.g. "Axtn-Ravencrest").
local function OpenRaidUnitToName(unitId)
    if unitId == "player" then
        return myName
    end
    -- unitId may be a full name with realm; strip realm suffix
    local ok, clean = pcall(string.format, "%s", unitId or "")
    if not ok or clean == "" then return nil end
    return (clean:match("^([^%-]+)") or clean)  -- keep short name only
end

-- Shared helper: write a single spell's timeLeft into cdState.
local function ApplyOpenRaidCD(unitId, spellId, cooldownInfo)
    local timeLeft = cooldownInfo and cooldownInfo[1]
    if not timeLeft then return end

    local spellData = SPELL_LOOKUP[spellId]
    if not spellData then return end

    local db = GetDB()
    if not db or not db.enabled then return end
    if not ((spellData.cat == "DEF" and db.showDEF) or (spellData.cat == "OFF" and db.showOFF)) then return end
    if (db.disabledSpells or {})[spellId] == false then return end

    local name = OpenRaidUnitToName(unitId)
    if not name then return end

    if not cdState[name] then cdState[name] = {} end
    if timeLeft <= 0 then
        cdState[name][spellId] = nil  -- spell is ready, clear the entry
    else
        -- Only override if our existing data doesn't already have a longer CD
        -- (GravityUI messages are more precise and may have already set this)
        local existing = cdState[name][spellId] or 0
        local newEnd   = GetTime() + timeLeft
        if newEnd > existing then
            cdState[name][spellId] = newEnd
        end
    end
end

-- Callback: a single cooldown was triggered for a unit (cast detected by OpenRaid)
function CDTracker:OnOpenRaidCooldownUpdate(unitId, spellId, cooldownInfo)
    if IsInRaid() then return end
    ApplyOpenRaidCD(unitId, spellId, cooldownInfo)
end

-- Callback: a full cooldown list was received from a unit (join / reload)
function CDTracker:OnOpenRaidCooldownListUpdate(unitId, unitCooldownTable)
    if IsInRaid() then return end
    if not unitCooldownTable then return end
    for spellId, cooldownInfo in pairs(unitCooldownTable) do
        ApplyOpenRaidCD(unitId, spellId, cooldownInfo)
    end
end

-- ============================================================================
-- NETWORK MESSAGE HANDLER
-- ============================================================================
function CDTracker:CHAT_MSG_ADDON(event, prefix, text, channel, senderFull)
    if prefix ~= NET_PREFIX then return end
    local sender = Ambiguate(senderFull, "short")
    if sender == myName then return end

    local parts = { strsplit(NET_SEP, text) }
    if parts[1] ~= NET_HDR then return end
    local cmd = parts[2]

    if cmd == "HELLO" then
        local cls = parts[3]
        if not cls or not CLASS_COLORS[cls] then return end

        if not knownUsers[sender] then
            knownUsers[sender] = { class = cls, _hasAddon = true }
        else
            knownUsers[sender].class     = cls
            knownUsers[sender]._hasAddon = true
        end

        -- Reply so they know about us
        AnnounceHello()

        -- Queue inspect for specID
        for i = 1, 4 do
            local u = "party" .. i
            if UnitExists(u) and SafeUnitName(u) == sender then
                QueueInspect(u)
                break
            end
        end

        C_Timer.After(0.2, RebuildAll)

    elseif cmd == "CAST" then
        local sid = tonumber(parts[3])
        local dur = tonumber(parts[4])
        if not sid or not dur then return end

        local db = GetDB()
        if not db or not db.enabled then return end

        local ok, spellData = pcall(function() return SPELL_LOOKUP[sid] end)
        if not ok or not spellData then return end
        if not ((spellData.cat == "DEF" and db.showDEF) or (spellData.cat == "OFF" and db.showOFF)) then return end

        local now = GetTime()
        if not cdState[sender] then cdState[sender] = {} end
        cdState[sender][sid] = now + dur
    end
end

-- ============================================================================
-- INSPECT READY
-- ============================================================================
function CDTracker:INSPECT_READY(event, guid)
    inspectBusy = false

    -- Find which unit matches the guid
    for i = 1, 4 do
        local u = "party" .. i
        if UnitExists(u) then
            local ok, uGuid = pcall(UnitGUID, u)
            if ok and uGuid == guid then
                local name = SafeUnitName(u)
                if name then
                    local ok2, specID = pcall(GetInspectSpecialization, u)
                    if ok2 and specID and specID > 0 then
                        if not knownUsers[name] then
                            knownUsers[name] = {}
                        end
                        knownUsers[name].specID = specID
                        -- Fill class if unknown
                        if not knownUsers[name].class then
                            local _, cls = UnitClass(u)
                            if cls then knownUsers[name].class = cls end
                        end
                        -- Rebuild bar for this unit
                        C_Timer.After(0.1, function()
                            BuildAttachedBar(u, name)
                        end)
                    end
                end
                break
            end
        end
    end

    C_Timer.After(0.5, ProcessInspectQueue)
end

-- ============================================================================
-- GROUP ROSTER UPDATE
-- ============================================================================
function CDTracker:GROUP_ROSTER_UPDATE()
    local db = GetDB()
    if not db or not db.enabled then return end
    if IsInRaid() then  -- M+ only, hide/clear all bars in raids
        for _, bar in pairs(attachedBars) do
            if bar.frame then bar.frame:Hide() end
        end
        attachedBars = {}
        return
    end

    -- Update own info
    myName  = SafeUnitName("player") or myName
    local _, cls = UnitClass("player")
    myClass = cls
    local idx = GetSpecialization()
    if idx then
        local specID = GetSpecializationInfo(idx)
        if specID and specID > 0 then
            mySpecID = specID
            if not knownUsers[myName] then knownUsers[myName] = {} end
            knownUsers[myName].class  = myClass
            knownUsers[myName].specID = mySpecID
            knownUsers[myName]._hasAddon = true
        end
    end

    -- Scan party members
    for i = 1, 4 do
        local u = "party" .. i
        if UnitExists(u) then
            local name = SafeUnitName(u)
            if name then
                if not knownUsers[name] then
                    knownUsers[name] = {}
                end
                local _, unitCls = UnitClass(u)
                if unitCls then knownUsers[name].class = unitCls end
                -- Check spec immediately
                local ok, sid = pcall(GetInspectSpecialization, u)
                if ok and sid and sid > 0 then
                    knownUsers[name].specID = sid
                else
                    QueueInspect(u)
                end
            end
        end
    end

    -- Announce to other GravityUI users
    AnnounceHello()

    C_Timer.After(0.3, RebuildAll)
end

-- ============================================================================
-- OnSettingsChanged (called from Settings panel)
-- ============================================================================
function CDTracker:ApplySettings()
    RebuildAll()
end

-- ============================================================================
-- TICKER: update icon timers
-- ============================================================================
local ticker = C_Timer.NewTicker(0.5, function()
    local now = GetTime()
    for unit, bar in pairs(attachedBars) do
        for spellID, ico in pairs(bar.icons) do
            -- Find name for this unit
            local name = (unit == "player") and myName or SafeUnitName(unit)
            local cdEnd = name and cdState[name] and cdState[name][spellID] or 0
            UpdateIcon(ico, cdEnd)
        end
    end
end)

-- ============================================================================
-- INITIALIZATION
-- ============================================================================
function CDTracker:OnInitialize()
    local db = GetDB()
    if not db then
        print("|cFFFF4444GravityUI CDTracker:|r OnInitialize failed — DB not ready")
        return
    end

    C_ChatInfo.RegisterAddonMessagePrefix(NET_PREFIX)

    self:RegisterEvent("GROUP_ROSTER_UPDATE")
    self:RegisterEvent("INSPECT_READY")
    self:RegisterEvent("CHAT_MSG_ADDON")


    -- Own player info
    myName  = SafeUnitName("player")
    local _, cls = UnitClass("player")
    myClass = cls
    local idx = GetSpecialization()
    if idx then
        local specID = GetSpecializationInfo(idx)
        if specID and specID > 0 then
            mySpecID = specID
            if not knownUsers[myName] then knownUsers[myName] = {} end
            knownUsers[myName].class     = myClass
            knownUsers[myName].specID    = mySpecID
            knownUsers[myName]._hasAddon = true
        end
    end

    -- Fire group scan after a short delay to let the game settle
    C_Timer.After(1, function()
        CDTracker:GROUP_ROSTER_UPDATE()
    end)

    -- Register with LibOpenRaid for cross-addon CD tracking
    -- (BigWigs, WeakAuras, DBM, Details, etc. all share via OpenRaid messages)
    C_Timer.After(2, function()
        local openRaid = LibStub and LibStub("LibOpenRaid-1.0", true)
        if openRaid then
            openRaid.RegisterCallback(CDTracker, "CooldownUpdate",     "OnOpenRaidCooldownUpdate")
            openRaid.RegisterCallback(CDTracker, "CooldownListUpdate", "OnOpenRaidCooldownListUpdate")
        end
    end)
end

function CDTracker:Enable()
    self:OnInitialize()
end
