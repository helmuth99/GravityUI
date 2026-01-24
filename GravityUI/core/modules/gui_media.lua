-- GravityUI Media-Registrierung
-- Diese Datei verwaltet die Registrierung von Schriftarten und Texturen bei LibSharedMedia

local LSM = LibStub("LibSharedMedia-3.0")

-- Media-Typen von LibSharedMedia
local MediaType = LSM.MediaType
local FONT = MediaType.FONT
local STATUSBAR = MediaType.STATUSBAR
local BACKGROUND = MediaType.BACKGROUND
local BORDER = MediaType.BORDER

-- Registriere Medien synchron (LSM:Register ist leichtgewichtig - nur Tabelleneinträge)
-- Registriere die Gravity-Schriftart (verwendet als Haupt-UI-Schriftart)
    local GravityFontPath = "Interface\\AddOns\\GravityUI\\assets\\Gravity.ttf"
    LSM:Register(FONT, "Gravity", GravityFontPath)

    -- Registriere Gravity-Schriftarten
    LSM:Register(FONT, "Gravity Big", "Interface\\AddOns\\GravityUI\\assets\\Gravity-Big.ttf")
    LSM:Register(FONT, "Gravity Bold", "Interface\\AddOns\\GravityUI\\assets\\Gravity-Bold.ttf")
    LSM:Register(FONT, "Gravity Light", "Interface\\AddOns\\GravityUI\\assets\\Gravity-Light.ttf")
    LSM:Register(FONT, "Gravity Thin", "Interface\\AddOns\\GravityUI\\assets\\Gravity-Thin.ttf")	
    LSM:Register(FONT, "Gravity Regular", "Interface\\AddOns\\GravityUI\\assets\\Gravity-Regular.ttf")

    -- Register Gravity-Expressway font
    LSM:Register(FONT, "Gravity Expressway", "Interface\\AddOns\\GravityUI\\assets\\Gravity-Expressway.TTF")

    -- Register the Gravity Logo texture
    local logoTexturePath = "Interface\\AddOns\\GravityUI\\assets\\GravityLogo.tga"
    LSM:Register(BACKGROUND, "GravityLogo", logoTexturePath)

    -- Register the Gravity texture
    local GravityTexturePath = "Interface\\AddOns\\GravityUI\\assets\\Gravity.tga"
    LSM:Register(BACKGROUND, "Gravity", GravityTexturePath)
    LSM:Register(STATUSBAR, "Gravity", GravityTexturePath)
    LSM:Register(BORDER, "Gravity", GravityTexturePath)

    -- Register the Gravity6px texture
    local GravityTexturePath = "Interface\\AddOns\\GravityUI\\assets\\Gravity6px.tga"
    LSM:Register(BACKGROUND, "Gravity6px", GravityTexturePath)
    LSM:Register(STATUSBAR, "Gravity6px", GravityTexturePath)
    LSM:Register(BORDER, "Gravity6px", GravityTexturePath)

    -- Register the Gravity Reverse texture
    local GravityReverseTexturePath = "Interface\\AddOns\\GravityUI\\assets\\Gravity_reverse.tga"
    LSM:Register(BACKGROUND, "Gravity Reverse", GravityReverseTexturePath)
    LSM:Register(STATUSBAR, "Gravity Reverse", GravityReverseTexturePath)
    LSM:Register(BORDER, "Gravity Reverse", GravityReverseTexturePath)

    -- Register Square texture
    local squareTexturePath = "Interface\\AddOns\\GravityUI\\assets\\Square.tga"
    LSM:Register(BACKGROUND, "Square", squareTexturePath)
    LSM:Register(STATUSBAR, "Square", squareTexturePath)
    LSM:Register(BORDER, "Square", squareTexturePath)

    -- Register Gravity v2 texture
    local GravityV2TexturePath = "Interface\\AddOns\\GravityUI\\assets\\Gravity_v2.tga"
    LSM:Register(BACKGROUND, "Gravity v2", GravityV2TexturePath)
    LSM:Register(STATUSBAR, "Gravity v2", GravityV2TexturePath)
    LSM:Register(BORDER, "Gravity v2", GravityV2TexturePath)

    -- Register Gravity v2 Reverse texture
    local GravityV2ReverseTexturePath = "Interface\\AddOns\\GravityUI\\assets\\Gravity_v2reverse.tga"
    LSM:Register(BACKGROUND, "Gravity v2 Reverse", GravityV2ReverseTexturePath)
    LSM:Register(STATUSBAR, "Gravity v2 Reverse", GravityV2ReverseTexturePath)
    LSM:Register(BORDER, "Gravity v2 Reverse", GravityV2ReverseTexturePath)

    -- Register Gravity v3 texture
    local GravityV3TexturePath = "Interface\\AddOns\\GravityUI\\assets\\Gravity_v3.tga"
    LSM:Register(BACKGROUND, "Gravity v3", GravityV3TexturePath)
    LSM:Register(STATUSBAR, "Gravity v3", GravityV3TexturePath)
    LSM:Register(BORDER, "Gravity v3", GravityV3TexturePath)

    -- Register Gravity v3 Inverse texture
    local GravityV3InverseTexturePath = "Interface\\AddOns\\GravityUI\\assets\\Gravity_v3inverse.tga"
    LSM:Register(BACKGROUND, "Gravity v3 Inverse", GravityV3InverseTexturePath)
    LSM:Register(STATUSBAR, "Gravity v3 Inverse", GravityV3InverseTexturePath)
    LSM:Register(BORDER, "Gravity v3 Inverse", GravityV3InverseTexturePath)

    -- Register Gravity v4 texture
    local GravityV4TexturePath = "Interface\\AddOns\\GravityUI\\assets\\Gravity_v4.tga"
    LSM:Register(BACKGROUND, "Gravity v4", GravityV4TexturePath)
    LSM:Register(STATUSBAR, "Gravity v4", GravityV4TexturePath)
    LSM:Register(BORDER, "Gravity v4", GravityV4TexturePath)

    -- Register Gravity v4 Inverse texture
    local GravityV4InverseTexturePath = "Interface\\AddOns\\GravityUI\\assets\\Gravity_v4inverse.tga"
    LSM:Register(BACKGROUND, "Gravity v4 Inverse", GravityV4InverseTexturePath)
    LSM:Register(STATUSBAR, "Gravity v4 Inverse", GravityV4InverseTexturePath)
    LSM:Register(BORDER, "Gravity v4 Inverse", GravityV4InverseTexturePath)

    -- Register Gravity v5 texture
    local GravityV5TexturePath = "Interface\\AddOns\\GravityUI\\assets\\Gravity_v5.tga"
    LSM:Register(BACKGROUND, "Gravity v5", GravityV5TexturePath)
    LSM:Register(STATUSBAR, "Gravity v5", GravityV5TexturePath)
    LSM:Register(BORDER, "Gravity v5", GravityV5TexturePath)

    -- Register Gravity v5 Inverse texture
    local GravityV5InverseTexturePath = "Interface\\AddOns\\GravityUI\\assets\\Gravity_v5_inverse.tga"
    LSM:Register(BACKGROUND, "Gravity v5 Inverse", GravityV5InverseTexturePath)
    LSM:Register(STATUSBAR, "Gravity v5 Inverse", GravityV5InverseTexturePath)
    LSM:Register(BORDER, "Gravity v5 Inverse", GravityV5InverseTexturePath)

    -- Register Gravity v6 texture
    local GravityV6TexturePath = "Interface\\AddOns\\GravityUI\\assets\\Gravity_v6.tga"
    LSM:Register(BACKGROUND, "Gravity v6", GravityV6TexturePath)
    LSM:Register(STATUSBAR, "Gravity v6", GravityV6TexturePath)
    LSM:Register(BORDER, "Gravity v6", GravityV6TexturePath)

    -- Register Gravity v6 Inverse texture
    local GravityV6InverseTexturePath = "Interface\\AddOns\\GravityUI\\assets\\Gravity_v6inverse.tga"
    LSM:Register(BACKGROUND, "Gravity v6 Inverse", GravityV6InverseTexturePath)
    LSM:Register(STATUSBAR, "Gravity v6 Inverse", GravityV6InverseTexturePath)
    LSM:Register(BORDER, "Gravity v6 Inverse", GravityV6InverseTexturePath)
	
	-- Register Gravity Normal texture
    local GravityNormalTexturePath = "Interface\\AddOns\\GravityUI\\assets\\Gravity_Normal.tga"
    LSM:Register(BACKGROUND, "Gravity Normal", GravityNormalTexturePath)
    LSM:Register(STATUSBAR, "Gravity Normal", GravityNormalTexturePath)
    LSM:Register(BORDER, "Gravity Normal", GravityNormalTexturePath)

    -- Register GUI Stripes texture (for absorb shield overlays)
    local absorbStripeTexturePath = "Interface\\AddOns\\GravityUI\\assets\\absorb_stripe"
    LSM:Register(STATUSBAR, "GUI Stripes", absorbStripeTexturePath)																   

-- Function to check if our media is registered
function GravityUI:CheckMediaRegistration()
    local GravityFontRegistered = LSM:IsValid(FONT, "Gravity")
    local logoTextureRegistered = LSM:IsValid(BACKGROUND, "GravityLogo")
    local GravityTextureRegistered = LSM:IsValid(BACKGROUND, "Gravity")
    local GravityReverseTextureRegistered = LSM:IsValid(BACKGROUND, "Gravity Normal")
    
    -- Stille Prüfung - nur ausgeben falls ein Fehler vorliegt
    if not (GravityFontRegistered and logoTextureRegistered and GravityTextureRegistered and GravityReverseTextureRegistered) then
        GravityUI:Print("Media registration failed:")
        if not GravityFontRegistered then GravityUI:Print("- Gravity font not registered") end
        if not logoTextureRegistered then GravityUI:Print("- GravityLogo texture not registered") end
        if not GravityTextureRegistered then GravityUI:Print("- Gravity texture not registered") end
        if not GravityReverseTextureRegistered then GravityUI:Print("- Gravity Reverse texture not registered") end
    end
end

-- Registriere zusätzliche Schriftarten oder Texturen hier
-- Beispiel:
-- LSM:Register(FONT, "MyCustomFont", "Interface\\AddOns\\GravityUI\\assets\\mycustomfont.ttf")
-- LSM:Register(STATUSBAR, "MyCustomTexture", "Interface\\AddOns\\GravityUI\\assets\\mycustomtexture.tga") 