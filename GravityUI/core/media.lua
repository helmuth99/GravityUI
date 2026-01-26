local ADDON_NAME, ns = ...
local LSM = LibStub("LibSharedMedia-3.0")
if not LSM then return end

local MediaType = LSM.MediaType
local FONT = MediaType.FONT
local STATUSBAR = MediaType.STATUSBAR
local BACKGROUND = MediaType.BACKGROUND
local BORDER = MediaType.BORDER

-- Dynamic path based on folder name to avoid mismatches
local assetPath = "Interface/AddOns/" .. ADDON_NAME .. "/assets/"

-- ═══════════════════════════════════════════════════════════════
-- FONTS REGISTRATION
-- ═══════════════════════════════════════════════════════════════
LSM:Register(FONT, "Gravity", assetPath .. "Gravity.ttf")
LSM:Register(FONT, "Gravity Big", assetPath .. "Gravity-Big.ttf")
LSM:Register(FONT, "Gravity Bold", assetPath .. "Gravity-Bold.ttf")
LSM:Register(FONT, "Gravity Expressway", assetPath .. "Gravity-Expressway.TTF")
LSM:Register(FONT, "Gravity Light", assetPath .. "Gravity-Light.ttf")
LSM:Register(FONT, "Gravity Regular", assetPath .. "Gravity-Regular.ttf")
LSM:Register(FONT, "Gravity Thin", assetPath .. "Gravity-Thin.ttf")

-- ═══════════════════════════════════════════════════════════════
-- TEXTURES REGISTRATION
-- ═══════════════════════════════════════════════════════════════
-- Each texture is registered as Background, Statusbar, and Border for maximum flexibility

local function RegisterTexture(name, file)
    local fullPath = assetPath .. file
    LSM:Register(BACKGROUND, name, fullPath)
    LSM:Register(STATUSBAR, name, fullPath)
    LSM:Register(BORDER, name, fullPath)
end

RegisterTexture("Gravity", "Gravity.tga")
RegisterTexture("Gravity 6px", "Gravity6px.tga")
RegisterTexture("Gravity Normal", "Gravity_Normal.tga")
RegisterTexture("Gravity Reverse", "Gravity_reverse.tga")
RegisterTexture("Gravity v2", "Gravity_v2.tga")
RegisterTexture("Gravity v2 Reverse", "Gravity_v2reverse.tga")
RegisterTexture("Gravity v3", "Gravity_v3.tga")
RegisterTexture("Gravity v3 Inverse", "Gravity_v3inverse.tga")
RegisterTexture("Gravity v4", "Gravity_v4.tga")
RegisterTexture("Gravity v4 Inverse", "Gravity_v4inverse.tga")
RegisterTexture("Gravity v5", "Gravity_v5.tga")
RegisterTexture("Gravity v5 Inverse", "Gravity_v5_inverse.tga")
RegisterTexture("Gravity v6", "Gravity_v6.tga")
RegisterTexture("Gravity v6 Inverse", "Gravity_v6inverse.tga")
RegisterTexture("Square", "Square.tga")

-- Special Assets
LSM:Register(BACKGROUND, "Gravity Logo", assetPath .. "GravityLogo.png")
LSM:Register(STATUSBAR, "GUI Stripes", assetPath .. "absorb_stripe.tga")
