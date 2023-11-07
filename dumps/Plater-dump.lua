Addon, private = ...

PlaterDump = {
  ["focus_as_target_alpha"] = true,
  ["extra_icon_use_blizzard_border_color"] = false,
  ["script_data"] = {
    {
      ["ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    --flash duration\n    local CONFIG_FLASH_DURATION = scriptTable.config.flashDuration\n    \n    --manually create a new texture for the flash animation\n    if (not envTable.SmallFlashTexture) then\n        envTable.SmallFlashTexture = envTable.SmallFlashTexture or Plater:CreateImage (unitFrame.castBar)\n        envTable.SmallFlashTexture:SetColorTexture (1, 1, 1)\n        envTable.SmallFlashTexture:SetAllPoints()\n    end\n    \n    --manually create a flash animation using the framework\n    if (not envTable.SmallFlashAnimationHub) then \n        \n        local onPlay = function()\n            envTable.SmallFlashTexture:Show()\n        end\n        \n        local onFinished = function()\n            envTable.SmallFlashTexture:Hide()\n        end\n        \n        local animationHub = Plater:CreateAnimationHub (envTable.SmallFlashTexture, onPlay, onFinished)\n        envTable.flashIn = Plater:CreateAnimation (animationHub, \"Alpha\", 1, CONFIG_FLASH_DURATION/2, 0, .6)\n        envTable.flashOut = Plater:CreateAnimation (animationHub, \"Alpha\", 2, CONFIG_FLASH_DURATION/2, 1, 0)\n        \n        envTable.SmallFlashAnimationHub = animationHub\n    end\n    \n    envTable.flashIn:SetDuration(scriptTable.config.flashDuration / 2)\n    envTable.flashOut:SetDuration(scriptTable.config.flashDuration / 2)\n    envTable.SmallFlashTexture:SetColorTexture (Plater:ParseColors(scriptTable.config.flashColor))\n    \nend\n\n\n\n\n\n\n\n",
      ["OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    envTable.SmallFlashAnimationHub:Stop()\n    \nend\n\n\n",
      ["OptionsValues"] = {
        ["flashColor"] = {
          0, -- [1]
          0.7137255072593689, -- [2]
          1, -- [3]
          1, -- [4]
        },
      },
      ["Temp_OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    envTable.SmallFlashAnimationHub:Play()\n    \nend\n\n\n",
      ["ScriptType"] = 2,
      ["UpdateCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    \n    \nend\n\n\n",
      ["Time"] = 1699197245,
      ["Temp_OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    envTable.SmallFlashAnimationHub:Stop()\n    \nend\n\n\n",
      ["url"] = "https://wago.io/GqYRu4scK/11",
      ["Icon"] = "Interface\\AddOns\\Plater\\images\\cast_bar",
      ["OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    envTable.SmallFlashAnimationHub:Play()\n    \nend\n\n\n",
      ["Enabled"] = false,
      ["Revision"] = 720,
      ["Options"] = {
        {
          ["Type"] = 6,
          ["Key"] = "option1",
          ["Value"] = 0,
          ["Name"] = "Option 1",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [1]
        {
          ["Type"] = 5,
          ["Key"] = "option2",
          ["Value"] = "Plays a small animation when the cast start.",
          ["Name"] = "Option 2",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_label",
          ["Desc"] = "",
        }, -- [2]
        {
          ["Type"] = 5,
          ["Key"] = "option2",
          ["Value"] = "Enter the spell name or spellID of the Spell in the Add Trigger box and hit \"Add\".",
          ["Name"] = "Option 2",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_label",
          ["Desc"] = "",
        }, -- [3]
        {
          ["Type"] = 6,
          ["Key"] = "option3",
          ["Value"] = 0,
          ["Name"] = "Option 3",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [4]
        {
          ["Type"] = 2,
          ["Max"] = 1.2,
          ["Desc"] = "How long is the flash played when the cast starts.",
          ["Min"] = 0.1,
          ["Key"] = "flashDuration",
          ["Value"] = 0.6,
          ["Fraction"] = true,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Flash Duration",
        }, -- [5]
        {
          ["Type"] = 1,
          ["Key"] = "flashColor",
          ["Value"] = {
            1, -- [1]
            0, -- [2]
            1, -- [3]
            1, -- [4]
          },
          ["Name"] = "Flash Color",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
          ["Desc"] = "Color of the Flash",
        }, -- [6]
      },
      ["Name"] = "Cast - Small Alert [Plater]",
      ["Prio"] = 99,
      ["Author"] = "Tercioo-Sylvanas",
      ["Initialization"] = "function (scriptTable)\n    --insert code here\n    \nend\n\n\n",
      ["Desc"] = "Flashes the Cast Bar when a spell in the trigger list is Cast. Add spell in the Add Trigger field.",
      ["SpellIds"] = {
        86331, -- [1]
        88959, -- [2]
        156722, -- [3]
        186269, -- [4]
        198595, -- [5]
        198750, -- [6]
        198934, -- [7]
        198962, -- [8]
        208165, -- [9]
        209033, -- [10]
        209413, -- [11]
        211299, -- [12]
        211406, -- [13]
        259092, -- [14]
        260879, -- [15]
        265084, -- [16]
        272180, -- [17]
        274383, -- [18]
        281420, -- [19]
        367521, -- [20]
        369399, -- [21]
        369674, -- [22]
        371875, -- [23]
        372225, -- [24]
        372538, -- [25]
        373698, -- [26]
        373932, -- [27]
        374544, -- [28]
        376851, -- [29]
        377503, -- [30]
        378155, -- [31]
        378818, -- [32]
        381517, -- [33]
        382249, -- [34]
        382474, -- [35]
        385039, -- [36]
        387564, -- [37]
        387843, -- [38]
        392576, -- [39]
        396044, -- [40]
        396925, -- [41]
        397386, -- [42]
        397801, -- [43]
        410760, -- [44]
        415435, -- [45]
      },
      ["Temp_UpdateCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    \n    \nend\n\n\n",
      ["version"] = 11,
      ["PlaterCore"] = 1,
      ["NpcNames"] = {
      },
      ["Temp_ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    --flash duration\n    local CONFIG_FLASH_DURATION = scriptTable.config.flashDuration\n    \n    --manually create a new texture for the flash animation\n    if (not envTable.SmallFlashTexture) then\n        envTable.SmallFlashTexture = envTable.SmallFlashTexture or Plater:CreateImage (unitFrame.castBar)\n        envTable.SmallFlashTexture:SetColorTexture (1, 1, 1)\n        envTable.SmallFlashTexture:SetAllPoints()\n    end\n    \n    --manually create a flash animation using the framework\n    if (not envTable.SmallFlashAnimationHub) then \n        \n        local onPlay = function()\n            envTable.SmallFlashTexture:Show()\n        end\n        \n        local onFinished = function()\n            envTable.SmallFlashTexture:Hide()\n        end\n        \n        local animationHub = Plater:CreateAnimationHub (envTable.SmallFlashTexture, onPlay, onFinished)\n        envTable.flashIn = Plater:CreateAnimation (animationHub, \"Alpha\", 1, CONFIG_FLASH_DURATION/2, 0, .6)\n        envTable.flashOut = Plater:CreateAnimation (animationHub, \"Alpha\", 2, CONFIG_FLASH_DURATION/2, 1, 0)\n        \n        envTable.SmallFlashAnimationHub = animationHub\n    end\n    \n    envTable.flashIn:SetDuration(scriptTable.config.flashDuration / 2)\n    envTable.flashOut:SetDuration(scriptTable.config.flashDuration / 2)\n    envTable.SmallFlashTexture:SetColorTexture (Plater:ParseColors(scriptTable.config.flashColor))\n    \nend\n\n\n\n\n\n\n\n",
      ["semver"] = "1.1.9",
      ["Temp_Initialization"] = "function (scriptTable)\n    --insert code here\n    \nend\n\n\n",
    }, -- [1]
    {
      ["ConstructorCode"] = "function (self, unitId, unitFrame, envTable)\n    \n    --color to set the nameplate\n    envTable.NameplateColor = \"gray\"\n    \nend\n\n\n",
      ["OnHideCode"] = "function (self, unitId, unitFrame, envTable)\n    \nend\n\n\n",
      ["OptionsValues"] = {
      },
      ["Temp_OnShowCode"] = "function (self, unitId, unitFrame, envTable)\n    \nend\n\n\n",
      ["ScriptType"] = 1,
      ["UpdateCode"] = "function (self, unitId, unitFrame, envTable)\n    \n    --only change the nameplate color in combat\n    if (InCombatLockdown()) then\n        Plater.SetNameplateColor (unitFrame, envTable.NameplateColor)\n    end\n    \nend\n\n\n\n\n\n\n",
      ["Time"] = 1699197387,
      ["Temp_ConstructorCode"] = "function (self, unitId, unitFrame, envTable)\n    \n    --color to set the nameplate\n    envTable.NameplateColor = \"gray\"\n    \nend\n\n\n",
      ["Icon"] = "Interface\\AddOns\\Plater\\images\\icon_invalid",
      ["Temp_OnHideCode"] = "function (self, unitId, unitFrame, envTable)\n    \nend\n\n\n",
      ["Revision"] = 116,
      ["Options"] = {
      },
      ["Author"] = "Izimode-Azralon",
      ["OnShowCode"] = "function (self, unitId, unitFrame, envTable)\n    \nend\n\n\n",
      ["Enabled"] = true,
      ["Temp_UpdateCode"] = "function (self, unitId, unitFrame, envTable)\n    \n    --only change the nameplate color in combat\n    if (InCombatLockdown()) then\n        Plater.SetNameplateColor (unitFrame, envTable.NameplateColor)\n    end\n    \nend\n\n\n\n\n\n\n",
      ["Name"] = "Aura - Invalidate Unit [Plater]",
      ["PlaterCore"] = 1,
      ["Prio"] = 99,
      ["SpellIds"] = {
        261265, -- [1]
        261266, -- [2]
        271590, -- [3]
      },
      ["Desc"] = "When an aura makes the unit invulnarable and you don't want to attack it. Add spell in the Add Trigger field.",
      ["NpcNames"] = {
      },
    }, -- [2]
    {
      ["ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    --creates a glow around the icon\n    envTable.buffIconGlow = envTable.buffIconGlow or Plater.CreateIconGlow (self, scriptTable.config.glowColor)\n    \nend",
      ["OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    if (scriptTable.config.glowEnabled) then\n        envTable.buffIconGlow:Hide()\n    end\n    \n    if (scriptTable.config.dotsEnabled) then\n        Plater.StopDotAnimation(self, envTable.dotAnimation)\n    end\n    \n    \nend",
      ["OptionsValues"] = {
      },
      ["Temp_OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    if (scriptTable.config.glowEnabled) then\n        envTable.buffIconGlow:Show()\n    end\n    \n    if (scriptTable.config.dotsEnabled) then\n        envTable.dotAnimation = Plater.PlayDotAnimation(self, 6, scriptTable.config.dotsColor, 6, 3) \n    end\n    \nend\n\n\n\n\n",
      ["ScriptType"] = 1,
      ["UpdateCode"] = "function (self, unitId, unitFrame, envTable)\n    \n    \n    \n    \nend",
      ["Time"] = 1699196974,
      ["NpcNames"] = {
      },
      ["url"] = "",
      ["Icon"] = "Interface\\AddOns\\Plater\\images\\icon_aura",
      ["Options"] = {
        {
          ["Type"] = 6,
          ["Key"] = "option1",
          ["Value"] = 0,
          ["Name"] = "Blank Space",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [1]
        {
          ["Type"] = 5,
          ["Key"] = "option2",
          ["Value"] = "Enter the spell name or spellID of the Buff in the Add Trigger box and hit \"Add\".",
          ["Name"] = "Option 2",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_label",
          ["Desc"] = "",
        }, -- [2]
        {
          ["Type"] = 6,
          ["Key"] = "option3",
          ["Value"] = 0,
          ["Name"] = "Blank Space",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [3]
        {
          ["Type"] = 4,
          ["Key"] = "glowEnabled",
          ["Value"] = false,
          ["Name"] = "Glow Enabled",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_bool",
          ["Desc"] = "",
        }, -- [4]
        {
          ["Type"] = 1,
          ["Key"] = "glowColor",
          ["Value"] = {
            0.403921568627451, -- [1]
            0.00392156862745098, -- [2]
            0, -- [3]
            1, -- [4]
          },
          ["Name"] = "Glow Color",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
          ["Desc"] = "",
        }, -- [5]
        {
          ["Type"] = 6,
          ["Name"] = "Blank Space",
          ["Value"] = 0,
          ["Key"] = "option3",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [6]
        {
          ["Type"] = 4,
          ["Key"] = "dotsEnabled",
          ["Value"] = true,
          ["Name"] = "Dots Enabled",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_bool",
          ["Desc"] = "",
        }, -- [7]
        {
          ["Type"] = 1,
          ["Name"] = "Dots Color",
          ["Value"] = {
            1, -- [1]
            0.3215686274509804, -- [2]
            0, -- [3]
            1, -- [4]
          },
          ["Key"] = "dotsColor",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
          ["Desc"] = "",
        }, -- [8]
      },
      ["Enabled"] = true,
      ["Revision"] = 636,
      ["semver"] = "",
      ["Name"] = "Aura - Buff Alert [Plater]",
      ["Temp_UpdateCode"] = "function (self, unitId, unitFrame, envTable)\n    \n    \n    \n    \nend",
      ["Author"] = "Tercioo-Sylvanas",
      ["Initialization"] = "function (scriptTable)\n    --insert code here\n    \nend\n\n\n",
      ["Desc"] = "Add the buff name in the trigger box.",
      ["version"] = -1,
      ["Prio"] = 99,
      ["SpellIds"] = {
        398151, -- [1]
        375596, -- [2]
        377738, -- [3]
        378149, -- [4]
      },
      ["PlaterCore"] = 1,
      ["OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    if (scriptTable.config.glowEnabled) then\n        envTable.buffIconGlow:Show()\n    end\n    \n    if (scriptTable.config.dotsEnabled) then\n        envTable.dotAnimation = Plater.PlayDotAnimation(self, 6, scriptTable.config.dotsColor, 6, 3) \n    end\n    \nend\n\n\n\n\n",
      ["Temp_ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    --creates a glow around the icon\n    envTable.buffIconGlow = envTable.buffIconGlow or Plater.CreateIconGlow (self, scriptTable.config.glowColor)\n    \nend",
      ["Temp_OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    if (scriptTable.config.glowEnabled) then\n        envTable.buffIconGlow:Hide()\n    end\n    \n    if (scriptTable.config.dotsEnabled) then\n        Plater.StopDotAnimation(self, envTable.dotAnimation)\n    end\n    \n    \nend",
      ["Temp_Initialization"] = "function (scriptTable)\n    --insert code here\n    \nend\n\n\n",
    }, -- [3]
    {
      ["ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    --create a texture to use for a flash behind the cast bar\n    local backGroundFlashTexture = Plater:CreateImage (self, [[Interface\\ACHIEVEMENTFRAME\\UI-Achievement-Alert-Glow]], self:GetWidth()+40, self:GetHeight()+20, \"background\", {0, 400/512, 0, 170/256})\n    backGroundFlashTexture:SetBlendMode (\"ADD\")\n    backGroundFlashTexture:SetDrawLayer(\"OVERLAY\", 7)\n    backGroundFlashTexture:SetPoint (\"center\", self, \"center\")\n    backGroundFlashTexture:SetVertexColor(Plater:ParseColors(scriptTable.config.flashColor))\n    backGroundFlashTexture:Hide()\n    \n    --create the animation hub to hold the flash animation sequence\n    envTable.BackgroundFlash = envTable.BackgroundFlash or Plater:CreateAnimationHub (backGroundFlashTexture, \n        function()\n            backGroundFlashTexture:Show()\n        end,\n        function()\n            backGroundFlashTexture:Hide()\n        end\n    )\n    \n    --create the flash animation sequence\n    local fadeIn = Plater:CreateAnimation (envTable.BackgroundFlash, \"ALPHA\", 1, scriptTable.config.flashDuration/2, 0, 1)\n    local fadeOut = Plater:CreateAnimation (envTable.BackgroundFlash, \"ALPHA\", 2, scriptTable.config.flashDuration/2, 1, 0)\n    \n    --create a camera shake for the nameplate\n    envTable.FrameShake = Plater:CreateFrameShake (unitFrame, scriptTable.config.shakeDuration, scriptTable.config.shakeAmplitude, scriptTable.config.shakeFrequency, false, false, 0, 1, 0.05, 0.1, Plater.GetPoints (unitFrame))\n    \n    --update the config for the flash here so it wont need a /reload\n    fadeIn:SetDuration (scriptTable.config.flashDuration/2)\n    fadeOut:SetDuration (scriptTable.config.flashDuration/2)\n    \n    --update the config for the skake here so it wont need a /reload\n    envTable.FrameShake.OriginalAmplitude = scriptTable.config.shakeAmplitude\n    envTable.FrameShake.OriginalDuration = scriptTable.config.shakeDuration\n    envTable.FrameShake.OriginalFrequency = scriptTable.config.shakeFrequency\nend",
      ["OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    Plater.StopDotAnimation(unitFrame.castBar, envTable.dotAnimation)    \n    \n    envTable.BackgroundFlash:Stop()\n    \n    unitFrame:StopFrameShake (envTable.FrameShake)    \n    \nend\n\n\n",
      ["OptionsValues"] = {
        ["dotColor"] = {
          0.5647059082984924, -- [1]
          0.5647059082984924, -- [2]
          0.5647059082984924, -- [3]
          1, -- [4]
        },
      },
      ["Temp_OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    envTable.dotAnimation = Plater.PlayDotAnimation(unitFrame.castBar, 5, scriptTable.config.dotColor, scriptTable.config.xOffset, scriptTable.config.yOffset)\n    \n    envTable.BackgroundFlash:Play()\n    \n    Plater.FlashNameplateBorder (unitFrame, 0.05)   \n    Plater.FlashNameplateBody (unitFrame, \"\", 0.075)\n    \n    unitFrame:PlayFrameShake (envTable.FrameShake)\n    \n    Plater.SetCastBarColorForScript(self, scriptTable.config.useCastbarColor, scriptTable.config.castBarColor, envTable)\n    \n    --Dominator on Shadowmoon Burial Grounds\n    if (envTable._SpellID == 154327) then\n        if (UnitHealth(unitId) == UnitHealthMax(unitId)) then\n            if (envTable._Duration == 604800) then\n                Plater.SetCastBarColorForScript(self, scriptTable.config.useCastbarColor, {1, 0, 0, 1}, envTable)\n            end\n        end\n    end\nend",
      ["ScriptType"] = 2,
      ["UpdateCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \nend\n\n\n",
      ["Time"] = 1699197251,
      ["NpcNames"] = {
      },
      ["url"] = "https://wago.io/Now2_IBi2/1",
      ["Icon"] = "Interface\\AddOns\\Plater\\images\\cast_bar_darkorange",
      ["Options"] = {
        {
          ["Type"] = 6,
          ["Name"] = "Option 1",
          ["Value"] = 0,
          ["Key"] = "option1",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [1]
        {
          ["Type"] = 5,
          ["Name"] = "Option 2",
          ["Value"] = "Plays a big animation when the cast start.",
          ["Key"] = "option2",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_label",
          ["Desc"] = "",
        }, -- [2]
        {
          ["Type"] = 5,
          ["Name"] = "Option 2",
          ["Value"] = "Enter the spell name or spellID of the Spell in the Add Trigger box and hit \"Add\".",
          ["Key"] = "option2",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_label",
          ["Desc"] = "",
        }, -- [3]
        {
          ["Type"] = 6,
          ["Name"] = "Option 4",
          ["Value"] = 0,
          ["Key"] = "option4",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [4]
        {
          ["Type"] = 5,
          ["Name"] = "Flash",
          ["Value"] = "Flash:",
          ["Key"] = "option2",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_label",
          ["Desc"] = "",
        }, -- [5]
        {
          ["Type"] = 2,
          ["Max"] = 1.2,
          ["Desc"] = "How long is the flash played when the cast starts.",
          ["Min"] = 0.1,
          ["Fraction"] = true,
          ["Value"] = 0.8,
          ["Name"] = "Flash Duration",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Key"] = "flashDuration",
        }, -- [6]
        {
          ["Type"] = 1,
          ["Name"] = "Flash Color",
          ["Value"] = {
            1, -- [1]
            1, -- [2]
            1, -- [3]
            1, -- [4]
          },
          ["Key"] = "flashColor",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
          ["Desc"] = "Color of the Flash",
        }, -- [7]
        {
          ["Type"] = 6,
          ["Name"] = "Option 7",
          ["Value"] = 0,
          ["Key"] = "option7",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [8]
        {
          ["Type"] = 5,
          ["Name"] = "Shake",
          ["Value"] = "Shake:",
          ["Key"] = "option2",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_label",
          ["Desc"] = "",
        }, -- [9]
        {
          ["Type"] = 2,
          ["Max"] = 0.5,
          ["Desc"] = "When the cast starts, there's a small shake in the nameplate, this settings controls how long it takes.",
          ["Min"] = 0.1,
          ["Fraction"] = true,
          ["Value"] = 0.2,
          ["Name"] = "Shake Duration",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Key"] = "shakeDuration",
        }, -- [10]
        {
          ["Type"] = 2,
          ["Max"] = 10,
          ["Desc"] = "How strong is the shake.",
          ["Min"] = 1,
          ["Fraction"] = false,
          ["Value"] = 5,
          ["Name"] = "Shake Amplitude",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Key"] = "shakeAmplitude",
        }, -- [11]
        {
          ["Type"] = 2,
          ["Max"] = 80,
          ["Desc"] = "How fast the shake moves.",
          ["Min"] = 1,
          ["Fraction"] = false,
          ["Value"] = 40,
          ["Name"] = "Shake Frequency",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Key"] = "shakeFrequency",
        }, -- [12]
        {
          ["Type"] = 6,
          ["Name"] = "Option 13",
          ["Value"] = 0,
          ["Key"] = "option13",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [13]
        {
          ["Type"] = 5,
          ["Name"] = "Dot Animation",
          ["Value"] = "Dot Animation:",
          ["Key"] = "option14",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_label",
          ["Desc"] = "",
        }, -- [14]
        {
          ["Type"] = 1,
          ["Name"] = "Dot Color",
          ["Value"] = {
            0.56470588235294, -- [1]
            0.56470588235294, -- [2]
            0.56470588235294, -- [3]
            1, -- [4]
          },
          ["Key"] = "dotColor",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
          ["Desc"] = "Adjust the color of the dots around the nameplate",
        }, -- [15]
        {
          ["Type"] = 2,
          ["Max"] = 20,
          ["Desc"] = "Adjust the width of the dots to better fit in your nameplate.",
          ["Min"] = -10,
          ["Fraction"] = false,
          ["Value"] = 8,
          ["Name"] = "Dot X Offset",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Key"] = "xOffset",
        }, -- [16]
        {
          ["Type"] = 2,
          ["Max"] = 10,
          ["Desc"] = "Adjust the height of the dots to better fit in your nameplate.",
          ["Min"] = -10,
          ["Fraction"] = false,
          ["Value"] = 3,
          ["Name"] = "Dot Y Offset",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Key"] = "yOffset",
        }, -- [17]
        {
          ["Type"] = 6,
          ["Name"] = "blank",
          ["Value"] = 0,
          ["Key"] = "option18",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [18]
        {
          ["Type"] = 6,
          ["Name"] = "blank",
          ["Value"] = 0,
          ["Key"] = "option18",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [19]
        {
          ["Type"] = 6,
          ["Name"] = "blank",
          ["Value"] = 0,
          ["Key"] = "option18",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [20]
        {
          ["Type"] = 6,
          ["Name"] = "blank",
          ["Value"] = 0,
          ["Key"] = "option18",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [21]
        {
          ["Type"] = 6,
          ["Name"] = "blank",
          ["Value"] = 0,
          ["Key"] = "option18",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [22]
        {
          ["Type"] = 6,
          ["Name"] = "blank",
          ["Value"] = 0,
          ["Key"] = "option18",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [23]
        {
          ["Type"] = 5,
          ["Name"] = "Option 19",
          ["Value"] = "Cast Bar",
          ["Key"] = "option19",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_label",
          ["Desc"] = "",
        }, -- [24]
        {
          ["Type"] = 4,
          ["Name"] = "Use Cast Bar Color",
          ["Value"] = true,
          ["Key"] = "useCastbarColor",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_bool",
          ["Desc"] = "Use cast bar color.",
        }, -- [25]
        {
          ["Type"] = 1,
          ["Name"] = "Cast Bar Color",
          ["Value"] = {
            0.41176470588235, -- [1]
            1, -- [2]
            0, -- [3]
            1, -- [4]
          },
          ["Key"] = "castBarColor",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
          ["Desc"] = "Cast bar color.",
        }, -- [26]
      },
      ["Enabled"] = false,
      ["Revision"] = 870,
      ["semver"] = "1.0.0",
      ["Name"] = "Cast - Very Important [Plater]",
      ["Temp_UpdateCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \nend\n\n\n",
      ["Author"] = "Bombad�o-Azralon",
      ["Initialization"] = "function (scriptTable)\n    --insert code here\n    \nend\n\n\n",
      ["Desc"] = "Highlight a very important cast applying several effects into the Cast Bar. Add spell in the Add Trigger field.",
      ["version"] = 1,
      ["Prio"] = 99,
      ["SpellIds"] = {
      },
      ["PlaterCore"] = 1,
      ["OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    envTable.dotAnimation = Plater.PlayDotAnimation(unitFrame.castBar, 5, scriptTable.config.dotColor, scriptTable.config.xOffset, scriptTable.config.yOffset)\n    \n    envTable.BackgroundFlash:Play()\n    \n    Plater.FlashNameplateBorder (unitFrame, 0.05)   \n    Plater.FlashNameplateBody (unitFrame, \"\", 0.075)\n    \n    unitFrame:PlayFrameShake (envTable.FrameShake)\n    \n    Plater.SetCastBarColorForScript(self, scriptTable.config.useCastbarColor, scriptTable.config.castBarColor, envTable)\n    \n    --Dominator on Shadowmoon Burial Grounds\n    if (envTable._SpellID == 154327) then\n        if (UnitHealth(unitId) == UnitHealthMax(unitId)) then\n            if (envTable._Duration == 604800) then\n                Plater.SetCastBarColorForScript(self, scriptTable.config.useCastbarColor, {1, 0, 0, 1}, envTable)\n            end\n        end\n    end\nend",
      ["Temp_ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    --create a texture to use for a flash behind the cast bar\n    local backGroundFlashTexture = Plater:CreateImage (self, [[Interface\\ACHIEVEMENTFRAME\\UI-Achievement-Alert-Glow]], self:GetWidth()+40, self:GetHeight()+20, \"background\", {0, 400/512, 0, 170/256})\n    backGroundFlashTexture:SetBlendMode (\"ADD\")\n    backGroundFlashTexture:SetDrawLayer(\"OVERLAY\", 7)\n    backGroundFlashTexture:SetPoint (\"center\", self, \"center\")\n    backGroundFlashTexture:SetVertexColor(Plater:ParseColors(scriptTable.config.flashColor))\n    backGroundFlashTexture:Hide()\n    \n    --create the animation hub to hold the flash animation sequence\n    envTable.BackgroundFlash = envTable.BackgroundFlash or Plater:CreateAnimationHub (backGroundFlashTexture, \n        function()\n            backGroundFlashTexture:Show()\n        end,\n        function()\n            backGroundFlashTexture:Hide()\n        end\n    )\n    \n    --create the flash animation sequence\n    local fadeIn = Plater:CreateAnimation (envTable.BackgroundFlash, \"ALPHA\", 1, scriptTable.config.flashDuration/2, 0, 1)\n    local fadeOut = Plater:CreateAnimation (envTable.BackgroundFlash, \"ALPHA\", 2, scriptTable.config.flashDuration/2, 1, 0)\n    \n    --create a camera shake for the nameplate\n    envTable.FrameShake = Plater:CreateFrameShake (unitFrame, scriptTable.config.shakeDuration, scriptTable.config.shakeAmplitude, scriptTable.config.shakeFrequency, false, false, 0, 1, 0.05, 0.1, Plater.GetPoints (unitFrame))\n    \n    --update the config for the flash here so it wont need a /reload\n    fadeIn:SetDuration (scriptTable.config.flashDuration/2)\n    fadeOut:SetDuration (scriptTable.config.flashDuration/2)\n    \n    --update the config for the skake here so it wont need a /reload\n    envTable.FrameShake.OriginalAmplitude = scriptTable.config.shakeAmplitude\n    envTable.FrameShake.OriginalDuration = scriptTable.config.shakeDuration\n    envTable.FrameShake.OriginalFrequency = scriptTable.config.shakeFrequency\nend",
      ["Temp_OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    Plater.StopDotAnimation(unitFrame.castBar, envTable.dotAnimation)    \n    \n    envTable.BackgroundFlash:Stop()\n    \n    unitFrame:StopFrameShake (envTable.FrameShake)    \n    \nend\n\n\n",
      ["Temp_Initialization"] = "function (scriptTable)\n    --insert code here\n    \nend\n\n\n",
    }, -- [4]
    {
      ["ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    --creates a glow around the icon\n    envTable.buffIconGlow = envTable.buffIconGlow or Plater.CreateIconGlow (self, scriptTable.config.glowColor)\n    \nend\n\n\n",
      ["OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    if (scriptTable.config.glowEnabled) then\n        envTable.buffIconGlow:Hide()\n    end\n    \n    if (scriptTable.config.dotsEnabled) then\n        Plater.StopDotAnimation(self, envTable.dotAnimation)\n    end\n    \n    \nend\n\n\n",
      ["OptionsValues"] = {
      },
      ["Temp_OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    if (scriptTable.config.glowEnabled) then\n        envTable.buffIconGlow:Show()\n    end\n    \n    if (scriptTable.config.dotsEnabled) then\n        envTable.dotAnimation = Plater.PlayDotAnimation(self, 6, scriptTable.config.dotsColor, 6, 3) \n    end\nend\n\n\n",
      ["ScriptType"] = 1,
      ["UpdateCode"] = "function (self, unitId, unitFrame, envTable)\n    \nend\n\n\n",
      ["Time"] = 1699196964,
      ["url"] = "",
      ["Icon"] = "Interface\\AddOns\\Plater\\images\\icon_aura",
      ["NpcNames"] = {
      },
      ["Enabled"] = true,
      ["Revision"] = 370,
      ["semver"] = "",
      ["Options"] = {
        {
          ["Type"] = 6,
          ["Key"] = "option1",
          ["Value"] = 0,
          ["Name"] = "Blank Space",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [1]
        {
          ["Type"] = 5,
          ["Key"] = "option2",
          ["Value"] = "Enter the spell name or spellID of the Buff in the Add Trigger box and hit \"Add\".",
          ["Name"] = "Option 2",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_label",
          ["Desc"] = "",
        }, -- [2]
        {
          ["Type"] = 6,
          ["Key"] = "option3",
          ["Value"] = 0,
          ["Name"] = "Blank Space",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [3]
        {
          ["Type"] = 4,
          ["Key"] = "glowEnabled",
          ["Value"] = false,
          ["Name"] = "Glow Enabled",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_bool",
          ["Desc"] = "",
        }, -- [4]
        {
          ["Type"] = 1,
          ["Key"] = "glowColor",
          ["Value"] = {
            0.403921568627451, -- [1]
            0.00392156862745098, -- [2]
            0, -- [3]
            1, -- [4]
          },
          ["Name"] = "Glow Color",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
          ["Desc"] = "",
        }, -- [5]
        {
          ["Type"] = 6,
          ["Name"] = "Blank Space",
          ["Value"] = 0,
          ["Key"] = "option3",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [6]
        {
          ["Type"] = 4,
          ["Key"] = "dotsEnabled",
          ["Value"] = true,
          ["Name"] = "Dots Enabled",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_bool",
          ["Desc"] = "",
        }, -- [7]
        {
          ["Type"] = 1,
          ["Name"] = "Dots Color",
          ["Value"] = {
            1, -- [1]
            0.3215686274509804, -- [2]
            0, -- [3]
            1, -- [4]
          },
          ["Key"] = "dotsColor",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
          ["Desc"] = "",
        }, -- [8]
      },
      ["Name"] = "Aura - Debuff Alert [Plater]",
      ["Author"] = "Tercioo-Sylvanas",
      ["Initialization"] = "					function (scriptTable)\n						--insert code here\n						\n					end\n				",
      ["Desc"] = "Add the debuff name in the trigger box.",
      ["version"] = -1,
      ["Prio"] = 99,
      ["SpellIds"] = {
      },
      ["PlaterCore"] = 1,
      ["Temp_UpdateCode"] = "function (self, unitId, unitFrame, envTable)\n    \nend\n\n\n",
      ["OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    if (scriptTable.config.glowEnabled) then\n        envTable.buffIconGlow:Show()\n    end\n    \n    if (scriptTable.config.dotsEnabled) then\n        envTable.dotAnimation = Plater.PlayDotAnimation(self, 6, scriptTable.config.dotsColor, 6, 3) \n    end\nend\n\n\n",
      ["Temp_ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    --creates a glow around the icon\n    envTable.buffIconGlow = envTable.buffIconGlow or Plater.CreateIconGlow (self, scriptTable.config.glowColor)\n    \nend\n\n\n",
      ["Temp_OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    if (scriptTable.config.glowEnabled) then\n        envTable.buffIconGlow:Hide()\n    end\n    \n    if (scriptTable.config.dotsEnabled) then\n        Plater.StopDotAnimation(self, envTable.dotAnimation)\n    end\n    \n    \nend\n\n\n",
    }, -- [5]
    {
      ["ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    local movingArrowTexture = unitFrame._movingArrowTexture\n    if (not movingArrowTexture) then\n        movingArrowTexture = self:CreateTexture(nil, \"artwork\", nil, 6)\n        unitFrame._movingArrowTexture = movingArrowTexture\n    end\n    \n    envTable.movingAnimation = envTable.movingAnimation or Plater:CreateAnimationHub (unitFrame._movingArrowTexture, \n        function() \n            unitFrame._movingArrowTexture:Show() \n            unitFrame._movingArrowTexture:SetPoint(\"left\", 0, 0)\n        end, \n        function() unitFrame._movingArrowTexture:Hide() end)\n    \n    envTable.movingAnimation:SetLooping (\"REPEAT\")\n    \n    envTable.arrowAnimation = envTable.arrowAnimation or Plater:CreateAnimation (envTable.movingAnimation, \"translation\", 1, 0.20, self:GetWidth()-16, 0)\n    \n    envTable.arrowAnimation:SetDuration(scriptTable.config.animSpeed)\nend\n\n\n\n\n\n\n",
      ["OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    envTable.movingAnimation:Stop()\nend\n\n\n",
      ["OptionsValues"] = {
      },
      ["Temp_OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    unitFrame._movingArrowTexture:SetTexture([[Interface\\PETBATTLES\\PetBattle-StatIcons]])\n    unitFrame._movingArrowTexture:SetSize(16, self:GetHeight() - 2)\n    unitFrame._movingArrowTexture:SetTexCoord(unpack({0, 15/32, 18/32, 30/32}))\n    unitFrame._movingArrowTexture:SetAlpha(scriptTable.config.arrowAlpha)\n    unitFrame._movingArrowTexture:SetDesaturated(scriptTable.config.desaturateArrow)    \n    \n    unitFrame._movingArrowTexture:SetParent(self.FrameOverlay)\n    unitFrame._movingArrowTexture:SetDrawLayer(\"overlay\",  7)\n    \n    envTable.arrowAnimation:SetDuration(scriptTable.config.animSpeed)\n    envTable.movingAnimation:Play()\nend\n\n\n",
      ["ScriptType"] = 2,
      ["UpdateCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    unitFrame._movingArrowTexture:SetAlpha(scriptTable.config.arrowAlpha)\n    \n    local percent = envTable.movingAnimation:GetProgress()\n    \n    if (percent < 0.4) then\n        local value = Lerp(0.01, scriptTable.config.arrowAlpha, percent) or 0\n        unitFrame._movingArrowTexture:SetAlpha(Saturate(value))\n        \n    elseif (percent > 0.6) then\n        local value = Lerp(scriptTable.config.arrowAlpha, 0.01, percent) or 0\n        unitFrame._movingArrowTexture:SetAlpha(Saturate(value))\n    end\n    \n    --unitFrame._movingArrowTexture:SetAlpha(1)\n    \n    self.ThrottleUpdate = 0\nend",
      ["Time"] = 1699197234,
      ["NpcNames"] = {
      },
      ["url"] = "",
      ["Icon"] = "Interface\\AddOns\\Plater\\images\\cast_bar_frontal",
      ["Options"] = {
        {
          ["Type"] = 6,
          ["Key"] = "option1",
          ["Value"] = 0,
          ["Name"] = "Option 1",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [1]
        {
          ["Type"] = 5,
          ["Key"] = "option2",
          ["Value"] = "Produces an effect to indicate the spell will hit players in front of the enemy.",
          ["Name"] = "Option 2",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_label",
          ["Desc"] = "",
        }, -- [2]
        {
          ["Type"] = 5,
          ["Key"] = "option4",
          ["Value"] = "Enter the spell name or spellID of the Spell in the Add Trigger box and hit \"Add\".",
          ["Name"] = "Option 4",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_label",
          ["Desc"] = "",
        }, -- [3]
        {
          ["Type"] = 6,
          ["Key"] = "option3",
          ["Value"] = 0,
          ["Name"] = "Option 3",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [4]
        {
          ["Type"] = 2,
          ["Max"] = 1,
          ["Desc"] = "Set the alpha of the moving arrow",
          ["Min"] = 0,
          ["Fraction"] = true,
          ["Value"] = 0.73,
          ["Key"] = "arrowAlpha",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Arrow Alpha",
        }, -- [5]
        {
          ["Type"] = 2,
          ["Max"] = 1,
          ["Desc"] = "Time that takes for an arrow to travel from the to right.",
          ["Min"] = 0,
          ["Fraction"] = true,
          ["Value"] = 0.2,
          ["Key"] = "animSpeed",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Animation Speed",
        }, -- [6]
        {
          ["Type"] = 4,
          ["Key"] = "desaturateArrow",
          ["Value"] = false,
          ["Name"] = "Use White Arrow",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_bool",
          ["Desc"] = "If enabled, the arrow color will be desaturated.",
        }, -- [7]
      },
      ["Enabled"] = true,
      ["Revision"] = 716,
      ["semver"] = "",
      ["Name"] = "Cast - Frontal Cone [Plater]",
      ["Temp_UpdateCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    unitFrame._movingArrowTexture:SetAlpha(scriptTable.config.arrowAlpha)\n    \n    local percent = envTable.movingAnimation:GetProgress()\n    \n    if (percent < 0.4) then\n        local value = Lerp(0.01, scriptTable.config.arrowAlpha, percent) or 0\n        unitFrame._movingArrowTexture:SetAlpha(Saturate(value))\n        \n    elseif (percent > 0.6) then\n        local value = Lerp(scriptTable.config.arrowAlpha, 0.01, percent) or 0\n        unitFrame._movingArrowTexture:SetAlpha(Saturate(value))\n    end\n    \n    --unitFrame._movingArrowTexture:SetAlpha(1)\n    \n    self.ThrottleUpdate = 0\nend",
      ["Author"] = "Izimode-Azralon",
      ["Initialization"] = "function (scriptTable)\n    --insert code here\n    \nend\n\n\n",
      ["Desc"] = "Does an animation for casts that affect the frontal area of the enemy. Add spell in the Add Trigger field.",
      ["version"] = -1,
      ["Prio"] = 99,
      ["SpellIds"] = {
        375943, -- [1]
        385958, -- [2]
        388623, -- [3]
        377034, -- [4]
        374361, -- [5]
        381525, -- [6]
        386660, -- [7]
        384699, -- [8]
        153501, -- [9]
        153686, -- [10]
        154442, -- [11]
        192018, -- [12]
        219488, -- [13]
        372087, -- [14]
        391726, -- [15]
        391723, -- [16]
        377383, -- [17]
        388976, -- [18]
        370764, -- [19]
        387067, -- [20]
        391118, -- [21]
        391136, -- [22]
        382233, -- [23]
        209027, -- [24]
        212031, -- [25]
        207261, -- [26]
        207979, -- [27]
        198888, -- [28]
        199805, -- [29]
        199050, -- [30]
        191508, -- [31]
        152792, -- [32]
        265540, -- [33]
        226304, -- [34]
        393432, -- [35]
        375327, -- [36]
        372202, -- [37]
        209495, -- [38]
        369409, -- [39]
        260894, -- [40]
        226406, -- [41]
        193505, -- [42]
        375348, -- [43]
        257426, -- [44]
        255952, -- [45]
        257870, -- [46]
        413147, -- [47]
        383107, -- [48]
        377559, -- [49]
        388060, -- [50]
        376170, -- [51]
        384524, -- [52]
        375351, -- [53]
        390111, -- [54]
        369791, -- [55]
        369573, -- [56]
        369563, -- [57]
        369335, -- [58]
        369061, -- [59]
        375727, -- [60]
        265016, -- [61]
        265019, -- [62]
        260793, -- [63]
        260292, -- [64]
        272457, -- [65]
        272609, -- [66]
        269843, -- [67]
        183465, -- [68]
        226296, -- [69]
        188169, -- [70]
        183088, -- [71]
        410873, -- [72]
        411012, -- [73]
        88308, -- [74]
        382708, -- [75]
        375251, -- [76]
        375439, -- [77]
        372311, -- [78]
        373742, -- [79]
        372201, -- [80]
        374533, -- [81]
        377204, -- [82]
        204667, -- [83]
        255567, -- [84]
        201226, -- [85]
        200768, -- [86]
        265372, -- [87]
        413529, -- [88]
        408141, -- [89]
        412215, -- [90]
        412129, -- [91]
        412505, -- [92]
        419351, -- [93]
        200261, -- [94]
        200345, -- [95]
        197974, -- [96]
        200913, -- [97]
        164357, -- [98]
        169179, -- [99]
        426645, -- [100]
        428293, -- [101]
        169929, -- [102]
      },
      ["PlaterCore"] = 1,
      ["OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    unitFrame._movingArrowTexture:SetTexture([[Interface\\PETBATTLES\\PetBattle-StatIcons]])\n    unitFrame._movingArrowTexture:SetSize(16, self:GetHeight() - 2)\n    unitFrame._movingArrowTexture:SetTexCoord(unpack({0, 15/32, 18/32, 30/32}))\n    unitFrame._movingArrowTexture:SetAlpha(scriptTable.config.arrowAlpha)\n    unitFrame._movingArrowTexture:SetDesaturated(scriptTable.config.desaturateArrow)    \n    \n    unitFrame._movingArrowTexture:SetParent(self.FrameOverlay)\n    unitFrame._movingArrowTexture:SetDrawLayer(\"overlay\",  7)\n    \n    envTable.arrowAnimation:SetDuration(scriptTable.config.animSpeed)\n    envTable.movingAnimation:Play()\nend\n\n\n",
      ["Temp_ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    local movingArrowTexture = unitFrame._movingArrowTexture\n    if (not movingArrowTexture) then\n        movingArrowTexture = self:CreateTexture(nil, \"artwork\", nil, 6)\n        unitFrame._movingArrowTexture = movingArrowTexture\n    end\n    \n    envTable.movingAnimation = envTable.movingAnimation or Plater:CreateAnimationHub (unitFrame._movingArrowTexture, \n        function() \n            unitFrame._movingArrowTexture:Show() \n            unitFrame._movingArrowTexture:SetPoint(\"left\", 0, 0)\n        end, \n        function() unitFrame._movingArrowTexture:Hide() end)\n    \n    envTable.movingAnimation:SetLooping (\"REPEAT\")\n    \n    envTable.arrowAnimation = envTable.arrowAnimation or Plater:CreateAnimation (envTable.movingAnimation, \"translation\", 1, 0.20, self:GetWidth()-16, 0)\n    \n    envTable.arrowAnimation:SetDuration(scriptTable.config.animSpeed)\nend\n\n\n\n\n\n\n",
      ["Temp_OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    envTable.movingAnimation:Stop()\nend\n\n\n",
      ["Temp_Initialization"] = "function (scriptTable)\n    --insert code here\n    \nend\n\n\n",
    }, -- [6]
    {
      ["ConstructorCode"] = "function (self, unitId, unitFrame, envTable)\n    \n    envTable.FixateTarget = Plater:CreateLabel (unitFrame);\n    envTable.FixateTarget:SetPoint (\"bottom\", unitFrame.BuffFrame, \"top\", 0, 10);    \n    \n    envTable.FixateIcon = Plater:CreateImage (unitFrame, 236188, 16, 16, \"overlay\");\n    envTable.FixateIcon:SetPoint (\"bottom\", envTable.FixateTarget, \"top\", 0, 4);    \n    \n    envTable.FixateTarget:Hide()\n    envTable.FixateIcon:Hide()\nend\n\n--165560 = Gormling Larva - MTS\n\n\n\n\n\n\n",
      ["OnHideCode"] = "function (self, unitId, unitFrame, envTable)\n    envTable.FixateTarget:Hide()\n    envTable.FixateIcon:Hide()\nend\n\n\n",
      ["OptionsValues"] = {
      },
      ["Temp_OnShowCode"] = "function (self, unitId, unitFrame, envTable)\n    \nend\n\n\n",
      ["ScriptType"] = 3,
      ["UpdateCode"] = "function (self, unitId, unitFrame, envTable)\n    local targetName = UnitName (unitId .. \"target\");\n    if (targetName) then\n        local _, class = UnitClass (unitId .. \"target\");\n        targetName = Plater.SetTextColorByClass (unitId .. \"target\", targetName);\n        envTable.FixateTarget.text = targetName;\n        \n        envTable.FixateTarget:Show();\n        envTable.FixateIcon:Show();\n    end    \nend\n\n\n",
      ["Time"] = 1675185051,
      ["Temp_OnHideCode"] = "function (self, unitId, unitFrame, envTable)\n    envTable.FixateTarget:Hide()\n    envTable.FixateIcon:Hide()\nend\n\n\n",
      ["url"] = "",
      ["Icon"] = 1029718,
      ["OnShowCode"] = "function (self, unitId, unitFrame, envTable)\n    \nend\n\n\n",
      ["Enabled"] = false,
      ["Revision"] = 281,
      ["Options"] = {
      },
      ["Name"] = "Fixate [Plater]",
      ["Prio"] = 99,
      ["Author"] = "Celian-Sylvanas",
      ["Initialization"] = "function (scriptTable)\n    --insert code here\n    \nend\n\n\n\n\n\n\n",
      ["Desc"] = "Show above the nameplate who is the player fixated",
      ["SpellIds"] = {
      },
      ["Temp_UpdateCode"] = "function (self, unitId, unitFrame, envTable)\n    local targetName = UnitName (unitId .. \"target\");\n    if (targetName) then\n        local _, class = UnitClass (unitId .. \"target\");\n        targetName = Plater.SetTextColorByClass (unitId .. \"target\", targetName);\n        envTable.FixateTarget.text = targetName;\n        \n        envTable.FixateTarget:Show();\n        envTable.FixateIcon:Show();\n    end    \nend\n\n\n",
      ["version"] = -1,
      ["PlaterCore"] = 1,
      ["NpcNames"] = {
      },
      ["Temp_ConstructorCode"] = "function (self, unitId, unitFrame, envTable)\n    \n    envTable.FixateTarget = Plater:CreateLabel (unitFrame);\n    envTable.FixateTarget:SetPoint (\"bottom\", unitFrame.BuffFrame, \"top\", 0, 10);    \n    \n    envTable.FixateIcon = Plater:CreateImage (unitFrame, 236188, 16, 16, \"overlay\");\n    envTable.FixateIcon:SetPoint (\"bottom\", envTable.FixateTarget, \"top\", 0, 4);    \n    \n    envTable.FixateTarget:Hide()\n    envTable.FixateIcon:Hide()\nend\n\n--165560 = Gormling Larva - MTS\n\n\n\n\n\n\n",
      ["semver"] = "",
      ["Temp_Initialization"] = "function (scriptTable)\n    --insert code here\n    \nend\n\n\n\n\n\n\n",
    }, -- [7]
    {
      ["ConstructorCode"] = "function (self, unitId, unitFrame, envTable)\n    envTable.EnergyAmount = Plater:CreateLabel (unitFrame, \"\", 16, \"silver\");\n    envTable.EnergyAmount:SetPoint (\"bottom\", unitFrame, \"top\", 0, 18);\nend\n\n--[=[\n\n\n--]=]",
      ["OnHideCode"] = "function (self, unitId, unitFrame, envTable)\n    envTable.EnergyAmount:Hide()\nend\n\n\n",
      ["OptionsValues"] = {
      },
      ["Temp_OnShowCode"] = "function (self, unitId, unitFrame, envTable)\n    envTable.EnergyAmount:Show()\nend\n\n\n",
      ["ScriptType"] = 3,
      ["UpdateCode"] = "function (self, unitId, unitFrame, envTable)\n    envTable.EnergyAmount.text = \"\" .. UnitPower (unitId);\nend\n\n\n",
      ["Time"] = 1674875571,
      ["Temp_ConstructorCode"] = "function (self, unitId, unitFrame, envTable)\n    envTable.EnergyAmount = Plater:CreateLabel (unitFrame, \"\", 16, \"silver\");\n    envTable.EnergyAmount:SetPoint (\"bottom\", unitFrame, \"top\", 0, 18);\nend\n\n--[=[\n\n\n--]=]",
      ["Icon"] = 136048,
      ["Temp_OnHideCode"] = "function (self, unitId, unitFrame, envTable)\n    envTable.EnergyAmount:Hide()\nend\n\n\n",
      ["Revision"] = 145,
      ["Options"] = {
      },
      ["Author"] = "Celian-Sylvanas",
      ["OnShowCode"] = "function (self, unitId, unitFrame, envTable)\n    envTable.EnergyAmount:Show()\nend\n\n\n",
      ["Enabled"] = true,
      ["Temp_UpdateCode"] = "function (self, unitId, unitFrame, envTable)\n    envTable.EnergyAmount.text = \"\" .. UnitPower (unitId);\nend\n\n\n",
      ["Name"] = "UnitPower [Plater]",
      ["PlaterCore"] = 1,
      ["Prio"] = 99,
      ["SpellIds"] = {
      },
      ["Desc"] = "Show the energy amount above the nameplate",
      ["NpcNames"] = {
        "Guardian of Yogg-Saron", -- [1]
      },
    }, -- [8]
    {
      ["ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    --castbar color (when can be interrupted)\n    envTable.CastbarColor = scriptTable.config.castbarColor\n    \n    --flash duration\n    local CONFIG_BACKGROUND_FLASH_DURATION = scriptTable.config.flashDuration\n    \n    --add this value to the cast bar height\n    envTable.CastBarHeightAdd = scriptTable.config.castBarHeight\n    \n    --create a fast flash above the cast bar\n    envTable.FullBarFlash = envTable.FullBarFlash or Plater.CreateFlash (self, 0.05, 1, \"white\")\n    \n    --create a camera shake for the nameplate\n    envTable.FrameShake = Plater:CreateFrameShake (unitFrame, scriptTable.config.shakeDuration, scriptTable.config.shakeAmplitude, scriptTable.config.shakeFrequency, false, false, 0, 1, 0.05, 0.1, Plater.GetPoints (unitFrame))\n    \n    --create a texture to use for a flash behind the cast bar\n    local backGroundFlashTexture = Plater:CreateImage (self, [[Interface\\ACHIEVEMENTFRAME\\UI-Achievement-Alert-Glow]], self:GetWidth()+60, self:GetHeight()+50, \"background\", {0, 400/512, 0, 170/256})\n    backGroundFlashTexture:SetBlendMode (\"ADD\", 7)\n    backGroundFlashTexture:SetDrawLayer(\"OVERLAY\", 7)\n    backGroundFlashTexture:SetPoint (\"center\", self, \"center\")\n    backGroundFlashTexture:Hide()\n    \n    --create the animation hub to hold the flash animation sequence\n    envTable.BackgroundFlash = envTable.BackgroundFlash or Plater:CreateAnimationHub (backGroundFlashTexture, \n        function()\n            backGroundFlashTexture:Show()\n        end,\n        function()\n            backGroundFlashTexture:Hide()\n        end\n    )\n    \n    --create the flash animation sequence\n    envTable.BackgroundFlash.fadeIn = envTable.BackgroundFlash.fadeIn or Plater:CreateAnimation (envTable.BackgroundFlash, \"ALPHA\", 1, CONFIG_BACKGROUND_FLASH_DURATION/2, 0, .75)\n    envTable.BackgroundFlash.fadeIn:SetDuration(CONFIG_BACKGROUND_FLASH_DURATION/2)\n    \n    envTable.BackgroundFlash.fadeOut = envTable.BackgroundFlash.fadeOut or Plater:CreateAnimation (envTable.BackgroundFlash, \"ALPHA\", 2, CONFIG_BACKGROUND_FLASH_DURATION/2, 1, 0)    \n    envTable.BackgroundFlash.fadeOut:SetDuration(CONFIG_BACKGROUND_FLASH_DURATION/2)\n    \n    --envTable.BackgroundFlash:Play() --envTable.BackgroundFlash:Stop()    \n    \n    \n    \n    \n    \nend\n\n\n\n\n",
      ["OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    if (not Plater.IsShowingCastBarTest) then\n        --don't execute on battlegrounds and arenas\n        if (Plater.ZoneInstanceType == \"arena\" or Plater.ZoneInstanceType == \"pvp\" or Plater.ZoneInstanceType == \"none\") then\n            return\n        end    \n    end\n    \n    unitFrame.castBar:SetHeight (envTable._DefaultHeight)\n    \n    --stop the camera shake\n    unitFrame:StopFrameShake (envTable.FrameShake)\n    \n    envTable.FullBarFlash:Stop()\n    envTable.BackgroundFlash:Stop()\n    \n    unitFrame.castBar.Spark:SetHeight(unitFrame.castBar:GetHeight())\n    \nend\n\n\n\n\n\n\n\n",
      ["OptionsValues"] = {
        ["castbarColor"] = {
          1, -- [1]
          0.43137258291245, -- [2]
          0, -- [3]
          1, -- [4]
        },
      },
      ["Temp_OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    --don't execute on battlegrounds and arenas\n    if (not Plater.IsShowingCastBarTest) then\n        if (Plater.ZoneInstanceType == \"arena\" or Plater.ZoneInstanceType == \"pvp\" or Plater.ZoneInstanceType == \"none\") then\n            return\n        end\n    end\n    \n    --play flash animations\n    envTable.FullBarFlash:Play()\n    \n    --envTable.currentHeight = unitFrame.castBar:GetHeight()\n    \n    --restoring the default size (not required since it already restore in the hide script)\n    if (envTable.OriginalHeight) then\n        self:SetHeight (envTable.OriginalHeight)\n    end\n    \n    --increase the cast bar size\n    local height = self:GetHeight()\n    envTable.OriginalHeight = height\n    \n    self:SetHeight (height + envTable.CastBarHeightAdd)\n    \n    Plater.SetCastBarBorderColor (self, 1, .2, .2, 0.4)\n    \n    unitFrame:PlayFrameShake (envTable.FrameShake)\n    \n    --set the color of the cast bar to dark orange (only if can be interrupted)\n    --Plater auto set this color to default when a new cast starts, no need to reset this value at OnHide.    \n    if (envTable._CanInterrupt) then\n        if (scriptTable.config.useCastbarColor) then\n            self:SetStatusBarColor (Plater:ParseColors (envTable.CastbarColor))\n        end\n    end\n    \n    Plater.SetCastBarColorForScript(self, scriptTable.config.useCastbarColor, scriptTable.config.castbarColor, envTable)\n    \n    envTable.BackgroundFlash:Play()\n    \n    unitFrame.castBar.Spark:SetHeight(unitFrame.castBar:GetHeight())\n    \nend\n\n\n\n\n\n\n\n\n\n\n\n\n",
      ["ScriptType"] = 2,
      ["UpdateCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \nend\n\n\n",
      ["Time"] = 1699196942,
      ["NpcNames"] = {
      },
      ["url"] = "",
      ["Icon"] = "Interface\\AddOns\\Plater\\images\\cast_bar_orange",
      ["Options"] = {
        {
          ["Type"] = 6,
          ["Key"] = "option1",
          ["Value"] = 0,
          ["Name"] = "Blank Line",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [1]
        {
          ["Type"] = 5,
          ["Key"] = "option2",
          ["Value"] = "Produces a notable effect in the cast bar when a spell from the 'Triggers' starts to cast.",
          ["Name"] = "Option 2",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_label",
          ["Desc"] = "",
        }, -- [2]
        {
          ["Type"] = 5,
          ["Key"] = "option3",
          ["Value"] = "Enter the spell name or spellID of the Spell in the Add Trigger box and hit \"Add\".",
          ["Name"] = "Option 3",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_label",
          ["Desc"] = "",
        }, -- [3]
        {
          ["Type"] = 6,
          ["Key"] = "option4",
          ["Value"] = 0,
          ["Name"] = "Blank Space",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [4]
        {
          ["Type"] = 4,
          ["Key"] = "useCastbarColor",
          ["Value"] = true,
          ["Name"] = "Cast Bar Color Enabled",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_bool",
          ["Desc"] = "When enabled, changes the cast bar color,",
        }, -- [5]
        {
          ["Type"] = 1,
          ["Key"] = "castbarColor",
          ["Value"] = {
            1, -- [1]
            0.4313725490196079, -- [2]
            0, -- [3]
            1, -- [4]
          },
          ["Name"] = "Cast Bar Color",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
          ["Desc"] = "Color of the cast bar.",
        }, -- [6]
        {
          ["Type"] = 6,
          ["Key"] = "option7",
          ["Value"] = 0,
          ["Name"] = "Blank Line",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [7]
        {
          ["Type"] = 2,
          ["Max"] = 1,
          ["Desc"] = "When the cast starts it flash rapidly, adjust how fast it flashes. Value is milliseconds.",
          ["Min"] = 0.05,
          ["Name"] = "Flash Duration",
          ["Value"] = 0.4,
          ["Fraction"] = true,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Key"] = "flashDuration",
        }, -- [8]
        {
          ["Type"] = 2,
          ["Max"] = 10,
          ["Desc"] = "Increases the cast bar height by this value",
          ["Min"] = 0,
          ["Name"] = "Cast Bar Height Mod",
          ["Value"] = 5,
          ["Fraction"] = false,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Key"] = "castBarHeight",
        }, -- [9]
        {
          ["Type"] = 2,
          ["Max"] = 1,
          ["Desc"] = "When the cast starts, there's a small shake in the nameplate, this settings controls how long it takes.",
          ["Min"] = 0.1,
          ["Name"] = "Shake Duration",
          ["Value"] = 0.2,
          ["Fraction"] = true,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Key"] = "shakeDuration",
        }, -- [10]
        {
          ["Type"] = 2,
          ["Max"] = 100,
          ["Desc"] = "How strong is the shake.",
          ["Min"] = 2,
          ["Fraction"] = false,
          ["Value"] = 8,
          ["Name"] = "Shake Amplitude",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Key"] = "shakeAmplitude",
        }, -- [11]
        {
          ["Type"] = 2,
          ["Max"] = 80,
          ["Desc"] = "How fast the shake moves.",
          ["Min"] = 1,
          ["Fraction"] = false,
          ["Value"] = 40,
          ["Name"] = "Shake Frequency",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Key"] = "shakeFrequency",
        }, -- [12]
      },
      ["Enabled"] = true,
      ["Revision"] = 1419,
      ["semver"] = "",
      ["Name"] = "Cast - Big Alert [Plater]",
      ["Temp_UpdateCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \nend\n\n\n",
      ["Author"] = "Tercioo-Sylvanas",
      ["Initialization"] = "function (scriptTable)\n    --insert code here\n    \nend",
      ["Desc"] = "Flash, Bounce and Red Color the CastBar border when when an important cast is happening. Add spell in the Add Trigger field.",
      ["version"] = -1,
      ["Prio"] = 99,
      ["SpellIds"] = {
        396640, -- [1]
        372743, -- [2]
        377389, -- [3]
        387955, -- [4]
        386546, -- [5]
        384808, -- [6]
        386024, -- [7]
        387615, -- [8]
        387606, -- [9]
        225100, -- [10]
        211401, -- [11]
        211470, -- [12]
        192563, -- [13]
        152818, -- [14]
        156776, -- [15]
        398206, -- [16]
        153524, -- [17]
        396073, -- [18]
        396018, -- [19]
        345202, -- [20]
        377950, -- [21]
        385578, -- [22]
        377488, -- [23]
        375596, -- [24]
        263365, -- [25]
        388392, -- [26]
        395859, -- [27]
        395872, -- [28]
        397914, -- [29]
        209410, -- [30]
        215433, -- [31]
        384194, -- [32]
        392451, -- [33]
        392924, -- [34]
        397889, -- [35]
        153395, -- [36]
        396812, -- [37]
        387975, -- [38]
        265089, -- [39]
        278755, -- [40]
        266106, -- [41]
        272183, -- [42]
        265523, -- [43]
        202181, -- [44]
        374080, -- [45]
        374045, -- [46]
        372223, -- [47]
        400386, -- [48]
        367500, -- [49]
        372711, -- [50]
        209413, -- [51]
        207980, -- [52]
        257397, -- [53]
        257736, -- [54]
        382787, -- [55]
        374699, -- [56]
        377402, -- [57]
        369602, -- [58]
        369465, -- [59]
        369400, -- [60]
        381593, -- [61]
        265091, -- [62]
        265433, -- [63]
        382791, -- [64]
        376780, -- [65]
        369365, -- [66]
        257784, -- [67]
        88010, -- [68]
        410870, -- [69]
        266209, -- [70]
        342797, -- [71]
        413044, -- [72]
        204243, -- [73]
        253517, -- [74]
        253544, -- [75]
        279118, -- [76]
        255041, -- [77]
        259572, -- [78]
        250096, -- [79]
        200630, -- [80]
        225562, -- [81]
        201399, -- [82]
        264390, -- [83]
        265346, -- [84]
        263959, -- [85]
        278444, -- [86]
        265876, -- [87]
        264407, -- [88]
        266225, -- [89]
        415770, -- [90]
        415437, -- [91]
        412922, -- [92]
        417481, -- [93]
        418200, -- [94]
        411300, -- [95]
        412378, -- [96]
        412233, -- [97]
        407891, -- [98]
        416139, -- [99]
        227913, -- [100]
        164965, -- [101]
        164887, -- [102]
        168082, -- [103]
        427460, -- [104]
        429176, -- [105]
        271174, -- [106]
        165213, -- [107]
        169839, -- [108]
      },
      ["PlaterCore"] = 1,
      ["OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    --don't execute on battlegrounds and arenas\n    if (not Plater.IsShowingCastBarTest) then\n        if (Plater.ZoneInstanceType == \"arena\" or Plater.ZoneInstanceType == \"pvp\" or Plater.ZoneInstanceType == \"none\") then\n            return\n        end\n    end\n    \n    --play flash animations\n    envTable.FullBarFlash:Play()\n    \n    --envTable.currentHeight = unitFrame.castBar:GetHeight()\n    \n    --restoring the default size (not required since it already restore in the hide script)\n    if (envTable.OriginalHeight) then\n        self:SetHeight (envTable.OriginalHeight)\n    end\n    \n    --increase the cast bar size\n    local height = self:GetHeight()\n    envTable.OriginalHeight = height\n    \n    self:SetHeight (height + envTable.CastBarHeightAdd)\n    \n    Plater.SetCastBarBorderColor (self, 1, .2, .2, 0.4)\n    \n    unitFrame:PlayFrameShake (envTable.FrameShake)\n    \n    --set the color of the cast bar to dark orange (only if can be interrupted)\n    --Plater auto set this color to default when a new cast starts, no need to reset this value at OnHide.    \n    if (envTable._CanInterrupt) then\n        if (scriptTable.config.useCastbarColor) then\n            self:SetStatusBarColor (Plater:ParseColors (envTable.CastbarColor))\n        end\n    end\n    \n    Plater.SetCastBarColorForScript(self, scriptTable.config.useCastbarColor, scriptTable.config.castbarColor, envTable)\n    \n    envTable.BackgroundFlash:Play()\n    \n    unitFrame.castBar.Spark:SetHeight(unitFrame.castBar:GetHeight())\n    \nend\n\n\n\n\n\n\n\n\n\n\n\n\n",
      ["Temp_ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    --castbar color (when can be interrupted)\n    envTable.CastbarColor = scriptTable.config.castbarColor\n    \n    --flash duration\n    local CONFIG_BACKGROUND_FLASH_DURATION = scriptTable.config.flashDuration\n    \n    --add this value to the cast bar height\n    envTable.CastBarHeightAdd = scriptTable.config.castBarHeight\n    \n    --create a fast flash above the cast bar\n    envTable.FullBarFlash = envTable.FullBarFlash or Plater.CreateFlash (self, 0.05, 1, \"white\")\n    \n    --create a camera shake for the nameplate\n    envTable.FrameShake = Plater:CreateFrameShake (unitFrame, scriptTable.config.shakeDuration, scriptTable.config.shakeAmplitude, scriptTable.config.shakeFrequency, false, false, 0, 1, 0.05, 0.1, Plater.GetPoints (unitFrame))\n    \n    --create a texture to use for a flash behind the cast bar\n    local backGroundFlashTexture = Plater:CreateImage (self, [[Interface\\ACHIEVEMENTFRAME\\UI-Achievement-Alert-Glow]], self:GetWidth()+60, self:GetHeight()+50, \"background\", {0, 400/512, 0, 170/256})\n    backGroundFlashTexture:SetBlendMode (\"ADD\", 7)\n    backGroundFlashTexture:SetDrawLayer(\"OVERLAY\", 7)\n    backGroundFlashTexture:SetPoint (\"center\", self, \"center\")\n    backGroundFlashTexture:Hide()\n    \n    --create the animation hub to hold the flash animation sequence\n    envTable.BackgroundFlash = envTable.BackgroundFlash or Plater:CreateAnimationHub (backGroundFlashTexture, \n        function()\n            backGroundFlashTexture:Show()\n        end,\n        function()\n            backGroundFlashTexture:Hide()\n        end\n    )\n    \n    --create the flash animation sequence\n    envTable.BackgroundFlash.fadeIn = envTable.BackgroundFlash.fadeIn or Plater:CreateAnimation (envTable.BackgroundFlash, \"ALPHA\", 1, CONFIG_BACKGROUND_FLASH_DURATION/2, 0, .75)\n    envTable.BackgroundFlash.fadeIn:SetDuration(CONFIG_BACKGROUND_FLASH_DURATION/2)\n    \n    envTable.BackgroundFlash.fadeOut = envTable.BackgroundFlash.fadeOut or Plater:CreateAnimation (envTable.BackgroundFlash, \"ALPHA\", 2, CONFIG_BACKGROUND_FLASH_DURATION/2, 1, 0)    \n    envTable.BackgroundFlash.fadeOut:SetDuration(CONFIG_BACKGROUND_FLASH_DURATION/2)\n    \n    --envTable.BackgroundFlash:Play() --envTable.BackgroundFlash:Stop()    \n    \n    \n    \n    \n    \nend\n\n\n\n\n",
      ["Temp_OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    if (not Plater.IsShowingCastBarTest) then\n        --don't execute on battlegrounds and arenas\n        if (Plater.ZoneInstanceType == \"arena\" or Plater.ZoneInstanceType == \"pvp\" or Plater.ZoneInstanceType == \"none\") then\n            return\n        end    \n    end\n    \n    unitFrame.castBar:SetHeight (envTable._DefaultHeight)\n    \n    --stop the camera shake\n    unitFrame:StopFrameShake (envTable.FrameShake)\n    \n    envTable.FullBarFlash:Stop()\n    envTable.BackgroundFlash:Stop()\n    \n    unitFrame.castBar.Spark:SetHeight(unitFrame.castBar:GetHeight())\n    \nend\n\n\n\n\n\n\n\n",
      ["Temp_Initialization"] = "function (scriptTable)\n    --insert code here\n    \nend",
    }, -- [9]
    {
      ["ConstructorCode"] = "--todo: add npc ids for multilanguage support\n\nfunction (self, unitId, unitFrame, envTable)\n    \n    --settings\n    envTable.TextAboveNameplate = \"** On You **\"\n    envTable.NameplateColor = \"green\"\n    \n    --label to show the text above the nameplate\n    envTable.FixateTarget = Plater:CreateLabel (unitFrame);\n    envTable.FixateTarget:SetPoint (\"bottom\", unitFrame.healthBar, \"top\", 0, 30);\n    \n    --the spell casted by the npc in the trigger list needs to be in the list below as well\n    local spellList = {\n        [321891] = \"Freeze Tag Fixation\", --Illusionary Vulpin - MTS\n        \n    }\n    \n    --build the list with localized spell names\n    envTable.FixateDebuffs = {}\n    for spellID, enUSSpellName in pairs (spellList) do\n        local localizedSpellName = GetSpellInfo (spellID)\n        envTable.FixateDebuffs [localizedSpellName or enUSSpellName] = true\n    end\n    \n    --debug - smuggled crawg\n    envTable.FixateDebuffs [\"Jagged Maw\"] = true\n    \nend\n\n--[=[\nNpcIDs:\n136461: Spawn of G'huun (mythic uldir G'huun)\n\n--]=]\n\n\n\n\n",
      ["OnHideCode"] = "function (self, unitId, unitFrame, envTable)\n    envTable.FixateTarget:SetText (\"\")\n    envTable.FixateTarget:Hide()\n    \n    envTable.IsFixated = false\n    \n    Plater.RefreshNameplateColor (unitFrame)\nend\n\n\n",
      ["OptionsValues"] = {
        ["targetingColor"] = {
          1, -- [1]
          0.8666667342186, -- [2]
          0.090196080505848, -- [3]
          1, -- [4]
        },
        ["option1"] = {
          1, -- [1]
          1, -- [2]
          1, -- [3]
          1, -- [4]
        },
      },
      ["Temp_OnShowCode"] = "function (self, unitId, unitFrame, envTable)\n    \nend\n\n\n",
      ["ScriptType"] = 3,
      ["UpdateCode"] = "function (self, unitId, unitFrame, envTable)\n    \n    --swap this to true when it is fixated\n    local isFixated = false\n    \n    --check the debuffs the player has and see if any of these debuffs has been placed by this unit\n    for debuffId = 1, 40 do\n        local name, texture, count, debuffType, duration, expirationTime, caster = UnitDebuff (\"player\", debuffId)\n        \n        --cancel the loop if there's no more debuffs on the player\n        if (not name) then \n            break \n        end\n        \n        --check if the owner of the debuff is this unit\n        if (envTable.FixateDebuffs [name] and caster and UnitIsUnit (caster, unitId)) then\n            --the debuff the player has, has been placed by this unit, set the name above the unit name\n            envTable.FixateTarget:SetText (envTable.TextAboveNameplate)\n            envTable.FixateTarget:Show()\n            Plater.SetNameplateColor (unitFrame,  envTable.NameplateColor)\n            isFixated = true\n            \n            if (not envTable.IsFixated) then\n                envTable.IsFixated = true\n                Plater.FlashNameplateBody (unitFrame, \"fixate\", .2)\n            end\n        end\n        \n    end\n    \n    --check if the nameplate color is changed but isn't fixated any more\n    if (not isFixated and envTable.IsFixated) then\n        --refresh the nameplate color\n        Plater.RefreshNameplateColor (unitFrame)\n        --reset the text\n        envTable.FixateTarget:SetText (\"\")\n        \n        envTable.IsFixated = false\n    end\n    \nend\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n",
      ["Time"] = 1698536663,
      ["Temp_OnHideCode"] = "function (self, unitId, unitFrame, envTable)\n    envTable.FixateTarget:SetText (\"\")\n    envTable.FixateTarget:Hide()\n    \n    envTable.IsFixated = false\n    \n    Plater.RefreshNameplateColor (unitFrame)\nend\n\n\n",
      ["url"] = "",
      ["Icon"] = 841383,
      ["OnShowCode"] = "function (self, unitId, unitFrame, envTable)\n    \nend\n\n\n",
      ["Enabled"] = false,
      ["Revision"] = 290,
      ["Options"] = {
        {
          ["Type"] = 1,
          ["Key"] = "targetingColor",
          ["Value"] = {
            1, -- [1]
            1, -- [2]
            1, -- [3]
            1, -- [4]
          },
          ["Name"] = "Fixate Nameplate Color",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
          ["Desc"] = "Fixate Nameplate Color",
        }, -- [1]
      },
      ["Name"] = "Fixate On You [Plater]",
      ["Prio"] = 99,
      ["Author"] = "Tecno-Azralon",
      ["Initialization"] = "function (scriptTable)\n    --insert code here\n    \nend\n\n\n",
      ["Desc"] = "When an enemy places a debuff and starts to chase you. This script changes the nameplate color and place your name above the nameplate as well.",
      ["SpellIds"] = {
        "spawn of g'huun", -- [1]
        "smuggled crawg", -- [2]
        "sergeant bainbridge", -- [3]
        "blacktooth scrapper", -- [4]
        "irontide grenadier", -- [5]
        "feral bloodswarmer", -- [6]
        "earthrager", -- [7]
        "crawler mine", -- [8]
        "rezan", -- [9]
      },
      ["Temp_UpdateCode"] = "function (self, unitId, unitFrame, envTable)\n    \n    --swap this to true when it is fixated\n    local isFixated = false\n    \n    --check the debuffs the player has and see if any of these debuffs has been placed by this unit\n    for debuffId = 1, 40 do\n        local name, texture, count, debuffType, duration, expirationTime, caster = UnitDebuff (\"player\", debuffId)\n        \n        --cancel the loop if there's no more debuffs on the player\n        if (not name) then \n            break \n        end\n        \n        --check if the owner of the debuff is this unit\n        if (envTable.FixateDebuffs [name] and caster and UnitIsUnit (caster, unitId)) then\n            --the debuff the player has, has been placed by this unit, set the name above the unit name\n            envTable.FixateTarget:SetText (envTable.TextAboveNameplate)\n            envTable.FixateTarget:Show()\n            Plater.SetNameplateColor (unitFrame,  envTable.NameplateColor)\n            isFixated = true\n            \n            if (not envTable.IsFixated) then\n                envTable.IsFixated = true\n                Plater.FlashNameplateBody (unitFrame, \"fixate\", .2)\n            end\n        end\n        \n    end\n    \n    --check if the nameplate color is changed but isn't fixated any more\n    if (not isFixated and envTable.IsFixated) then\n        --refresh the nameplate color\n        Plater.RefreshNameplateColor (unitFrame)\n        --reset the text\n        envTable.FixateTarget:SetText (\"\")\n        \n        envTable.IsFixated = false\n    end\n    \nend\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n",
      ["version"] = -1,
      ["PlaterCore"] = 1,
      ["NpcNames"] = {
        "187638", -- [1]
      },
      ["Temp_ConstructorCode"] = "--todo: add npc ids for multilanguage support\n\nfunction (self, unitId, unitFrame, envTable)\n    \n    --settings\n    envTable.TextAboveNameplate = \"** On You **\"\n    envTable.NameplateColor = \"green\"\n    \n    --label to show the text above the nameplate\n    envTable.FixateTarget = Plater:CreateLabel (unitFrame);\n    envTable.FixateTarget:SetPoint (\"bottom\", unitFrame.healthBar, \"top\", 0, 30);\n    \n    --the spell casted by the npc in the trigger list needs to be in the list below as well\n    local spellList = {\n        [321891] = \"Freeze Tag Fixation\", --Illusionary Vulpin - MTS\n        \n    }\n    \n    --build the list with localized spell names\n    envTable.FixateDebuffs = {}\n    for spellID, enUSSpellName in pairs (spellList) do\n        local localizedSpellName = GetSpellInfo (spellID)\n        envTable.FixateDebuffs [localizedSpellName or enUSSpellName] = true\n    end\n    \n    --debug - smuggled crawg\n    envTable.FixateDebuffs [\"Jagged Maw\"] = true\n    \nend\n\n--[=[\nNpcIDs:\n136461: Spawn of G'huun (mythic uldir G'huun)\n\n--]=]\n\n\n\n\n",
      ["semver"] = "",
      ["Temp_Initialization"] = "function (scriptTable)\n    --insert code here\n    \nend\n\n\n",
    }, -- [10]
    {
      ["ConstructorCode"] = "function (self, unitId, unitFrame, envTable)\n    \n    --color to set the nameplate\n    envTable.NameplateColor = \"pink\" \n    \nend\n\n\n",
      ["OnHideCode"] = "function (self, unitId, unitFrame, envTable)\n    \nend\n\n\n",
      ["OptionsValues"] = {
      },
      ["Temp_OnShowCode"] = "function (self, unitId, unitFrame, envTable)\n    \nend\n\n\n",
      ["ScriptType"] = 1,
      ["UpdateCode"] = "function (self, unitId, unitFrame, envTable)\n    \n    Plater.SetNameplateColor (unitFrame, envTable.NameplateColor)\n    \nend\n\n\n",
      ["Time"] = 1675185050,
      ["Temp_ConstructorCode"] = "function (self, unitId, unitFrame, envTable)\n    \n    --color to set the nameplate\n    envTable.NameplateColor = \"pink\" \n    \nend\n\n\n",
      ["Icon"] = "INTERFACE\\ICONS\\Achievement_PVP_P_01",
      ["Temp_OnHideCode"] = "function (self, unitId, unitFrame, envTable)\n    \nend\n\n\n",
      ["Revision"] = 48,
      ["Options"] = {
      },
      ["Author"] = "抹了油的大叔-白银之手",
      ["OnShowCode"] = "function (self, unitId, unitFrame, envTable)\n    \nend\n\n\n",
      ["Enabled"] = false,
      ["Temp_UpdateCode"] = "function (self, unitId, unitFrame, envTable)\n    \n    Plater.SetNameplateColor (unitFrame, envTable.NameplateColor)\n    \nend\n\n\n",
      ["Name"] = "NameplaterColor with Special Buff ID",
      ["PlaterCore"] = 1,
      ["Prio"] = 99,
      ["SpellIds"] = {
        277242, -- [1]
      },
      ["Desc"] = "NameplaterColor with Special Buff ID",
      ["NpcNames"] = {
      },
    }, -- [11]
    {
      ["ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    --settings\n    envTable.NameplateSizeOffset = scriptTable.config.castBarHeight\n    envTable.ShowArrow = scriptTable.config.showArrow\n    envTable.ArrowAlpha = scriptTable.config.arrowAlpha\n    \n    --creates the spark to show the cast progress inside the health bar\n    envTable.overlaySpark = envTable.overlaySpark or Plater:CreateImage (unitFrame.healthBar)\n    envTable.overlaySpark:SetBlendMode (\"ADD\")\n    envTable.overlaySpark.width = 16\n    envTable.overlaySpark.height = 36\n    envTable.overlaySpark.alpha = .9\n    envTable.overlaySpark.texture = [[Interface\\AddOns\\Plater\\images\\spark3]]\n    \n    envTable.topArrow = envTable.topArrow or Plater:CreateImage (unitFrame.healthBar)\n    envTable.topArrow:SetBlendMode (\"ADD\")\n    envTable.topArrow.width = scriptTable.config.arrowWidth\n    envTable.topArrow.height = scriptTable.config.arrowHeight\n    envTable.topArrow.alpha = envTable.ArrowAlpha\n    envTable.topArrow.texture = [[Interface\\BUTTONS\\Arrow-Down-Up]]\n    \n    --scale animation\n    envTable.smallScaleAnimation = envTable.smallScaleAnimation or Plater:CreateAnimationHub (unitFrame.healthBar)\n    Plater:CreateAnimation (envTable.smallScaleAnimation, \"SCALE\", 1, 0.075, 1, 1, 1.08, 1.08)\n    Plater:CreateAnimation (envTable.smallScaleAnimation, \"SCALE\", 2, 0.075, 1, 1, 0.95, 0.95)    \n    --envTable.smallScaleAnimation:Play() --envTable.smallScaleAnimation:Stop()\n    \nend\n\n\n\n\n\n\n\n",
      ["OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    Plater.StopDotAnimation(unitFrame.healthBar, envTable.dotAnimation)\n    \n    envTable.overlaySpark:Hide()\n    envTable.topArrow:Hide()\n    \n    Plater.RefreshNameplateColor (unitFrame)\n    \n    envTable.smallScaleAnimation:Stop()\n    \n    --increase the nameplate size\n    local nameplateHeight = Plater.db.profile.plate_config.enemynpc.health_incombat [2]\n    unitFrame.healthBar:SetHeight (nameplateHeight)\n    \n    Plater.DenyColorChange(unitFrame, false)\nend\n\n\n",
      ["OptionsValues"] = {
      },
      ["Temp_OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    envTable.overlaySpark:Show()\n    \n    if (envTable.ShowArrow) then\n        envTable.topArrow:Show()\n    end\n    \n    Plater.FlashNameplateBorder (unitFrame, 0.05)   \n    Plater.FlashNameplateBody (unitFrame, \"\", 0.075)\n    \n    envTable.smallScaleAnimation:Play()\n    \n    --increase the nameplate size\n    local nameplateHeight = Plater.db.profile.plate_config.enemynpc.health_incombat [2]\n    unitFrame.healthBar:SetHeight (nameplateHeight + envTable.NameplateSizeOffset)\n    \n    envTable.overlaySpark.height = nameplateHeight + 5\n    \n    envTable.dotAnimation = Plater.PlayDotAnimation(unitFrame.healthBar, 2, scriptTable.config.dotColor, scriptTable.config.xOffset, scriptTable.config.yOffset)\n    \n    Plater.SetCastBarColorForScript(self, true, scriptTable.config.castBarColor, envTable)\n    \n    if (scriptTable.config.useNameplateColor) then\n        envTable.NameplateColor = Plater.GetColorByPriority(unitFrame, scriptTable.config.healthBarColor)\n        Plater.DenyColorChange(unitFrame, true)\n    end       \nend\n\n\n\n\n\n\n",
      ["ScriptType"] = 2,
      ["UpdateCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    --update the percent\n    envTable.overlaySpark:SetPoint (\"left\", unitFrame.healthBar:GetWidth() * (envTable._CastPercent / 100)-9, 0)\n    \n    envTable.topArrow:SetPoint (\"bottomleft\", unitFrame.healthBar, \"topleft\", unitFrame.healthBar:GetWidth() * (envTable._CastPercent / 100) - 4, 2 )\n    \n    --forces the script to run the update as fast as the game framerate\n    self.ThrottleUpdate = 0\n    \n    if (scriptTable.config.useNameplateColor) then\n        Plater.SetNameplateColor(unitFrame, envTable.NameplateColor)\n    end\n    \n    local dotSpeed = abs(envTable._Duration - envTable._RemainingTime) + 1.5\n    envTable.dotAnimation.textureInfo.speedMultiplier = dotSpeed\nend\n\n\n\n\n",
      ["Time"] = 1685320204,
      ["Temp_OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    Plater.StopDotAnimation(unitFrame.healthBar, envTable.dotAnimation)\n    \n    envTable.overlaySpark:Hide()\n    envTable.topArrow:Hide()\n    \n    Plater.RefreshNameplateColor (unitFrame)\n    \n    envTable.smallScaleAnimation:Stop()\n    \n    --increase the nameplate size\n    local nameplateHeight = Plater.db.profile.plate_config.enemynpc.health_incombat [2]\n    unitFrame.healthBar:SetHeight (nameplateHeight)\n    \n    Plater.DenyColorChange(unitFrame, false)\nend\n\n\n",
      ["url"] = "",
      ["Icon"] = 2175503,
      ["OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    envTable.overlaySpark:Show()\n    \n    if (envTable.ShowArrow) then\n        envTable.topArrow:Show()\n    end\n    \n    Plater.FlashNameplateBorder (unitFrame, 0.05)   \n    Plater.FlashNameplateBody (unitFrame, \"\", 0.075)\n    \n    envTable.smallScaleAnimation:Play()\n    \n    --increase the nameplate size\n    local nameplateHeight = Plater.db.profile.plate_config.enemynpc.health_incombat [2]\n    unitFrame.healthBar:SetHeight (nameplateHeight + envTable.NameplateSizeOffset)\n    \n    envTable.overlaySpark.height = nameplateHeight + 5\n    \n    envTable.dotAnimation = Plater.PlayDotAnimation(unitFrame.healthBar, 2, scriptTable.config.dotColor, scriptTable.config.xOffset, scriptTable.config.yOffset)\n    \n    Plater.SetCastBarColorForScript(self, true, scriptTable.config.castBarColor, envTable)\n    \n    if (scriptTable.config.useNameplateColor) then\n        envTable.NameplateColor = Plater.GetColorByPriority(unitFrame, scriptTable.config.healthBarColor)\n        Plater.DenyColorChange(unitFrame, true)\n    end       \nend\n\n\n\n\n\n\n",
      ["Enabled"] = true,
      ["Revision"] = 543,
      ["Options"] = {
        {
          ["Type"] = 2,
          ["Max"] = 6,
          ["Desc"] = "Increases the cast bar height by this value",
          ["Min"] = 0,
          ["Key"] = "castBarHeight",
          ["Value"] = 3,
          ["Fraction"] = false,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Cast Bar Height Mod",
        }, -- [1]
        {
          ["Type"] = 1,
          ["Key"] = "castBarColor",
          ["Value"] = {
            1, -- [1]
            0.5843137254902, -- [2]
            0, -- [3]
            1, -- [4]
          },
          ["Name"] = "Cast Bar Color",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
          ["Desc"] = "Changes the cast bar color to this one.",
        }, -- [2]
        {
          ["Type"] = 6,
          ["Key"] = "option7",
          ["Value"] = 0,
          ["Name"] = "Option 7",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [3]
        {
          ["Type"] = 5,
          ["Key"] = "option6",
          ["Value"] = "Arrow:",
          ["Name"] = "Arrow:",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_label",
          ["Desc"] = "",
        }, -- [4]
        {
          ["Type"] = 4,
          ["Key"] = "showArrow",
          ["Value"] = true,
          ["Name"] = "Show Arrow",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_bool",
          ["Desc"] = "Show an arrow above the nameplate showing the cast bar progress.",
        }, -- [5]
        {
          ["Type"] = 2,
          ["Max"] = 1,
          ["Desc"] = "Arrow alpha.",
          ["Min"] = 0,
          ["Key"] = "arrowAlpha",
          ["Value"] = 1,
          ["Fraction"] = true,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Arrow Alpha",
        }, -- [6]
        {
          ["Type"] = 2,
          ["Max"] = 12,
          ["Desc"] = "Arrow Width.",
          ["Min"] = 4,
          ["Key"] = "arrowWidth",
          ["Value"] = 8,
          ["Fraction"] = false,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Arrow Width",
        }, -- [7]
        {
          ["Type"] = 2,
          ["Max"] = 12,
          ["Desc"] = "Arrow Height.",
          ["Min"] = 4,
          ["Key"] = "arrowHeight",
          ["Value"] = 8,
          ["Fraction"] = false,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Arrow Height",
        }, -- [8]
        {
          ["Type"] = 6,
          ["Key"] = "option13",
          ["Value"] = 0,
          ["Name"] = "Option 13",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [9]
        {
          ["Type"] = 5,
          ["Key"] = "option12",
          ["Value"] = "Dot Animation:",
          ["Name"] = "Dot Animation:",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_label",
          ["Desc"] = "",
        }, -- [10]
        {
          ["Type"] = 1,
          ["Key"] = "dotColor",
          ["Value"] = {
            1, -- [1]
            0.6156862745098, -- [2]
            0, -- [3]
            1, -- [4]
          },
          ["Name"] = "Dot Color",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
          ["Desc"] = "Adjust the color of the dot animation.",
        }, -- [11]
        {
          ["Type"] = 2,
          ["Max"] = 10,
          ["Desc"] = "Dot X Offset",
          ["Min"] = -10,
          ["Key"] = "xOffset",
          ["Value"] = 4,
          ["Fraction"] = false,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Dot X Offset",
        }, -- [12]
        {
          ["Type"] = 2,
          ["Max"] = 10,
          ["Desc"] = "Dot Y Offset",
          ["Min"] = -10,
          ["Key"] = "yOffset",
          ["Value"] = 3,
          ["Fraction"] = false,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Dot Y Offset",
        }, -- [13]
        {
          ["Type"] = 6,
          ["Key"] = "option18",
          ["Value"] = 0,
          ["Name"] = "Option 18",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [14]
        {
          ["Type"] = 5,
          ["Key"] = "option17",
          ["Value"] = "Nameplate Color",
          ["Name"] = "Nameplate Color",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_label",
          ["Desc"] = "",
        }, -- [15]
        {
          ["Type"] = 4,
          ["Key"] = "useNameplateColor",
          ["Value"] = false,
          ["Name"] = "Change Nameplate Color",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_bool",
          ["Desc"] = "Change Nameplate Color",
        }, -- [16]
        {
          ["Type"] = 1,
          ["Key"] = "healthBarColor",
          ["Value"] = {
            1, -- [1]
            0.1843137294054, -- [2]
            0, -- [3]
            1, -- [4]
          },
          ["Name"] = "Nameplate Color",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
          ["Desc"] = "Health Bar Color",
        }, -- [17]
      },
      ["Name"] = "Explosion Affix M+ [Plater]",
      ["Prio"] = 99,
      ["Author"] = "Bombad o-Azralon",
      ["Initialization"] = "function (scriptTable)\n    --insert code here\n    \nend\n\n\n",
      ["Desc"] = "Apply several animations when the explosion orb cast starts on a Mythic Dungeon with Explosion Affix",
      ["SpellIds"] = {
        240446, -- [1]
        385339, -- [2]
        198077, -- [3]
        210261, -- [4]
        360857, -- [5]
        273577, -- [6]
      },
      ["Temp_UpdateCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    --update the percent\n    envTable.overlaySpark:SetPoint (\"left\", unitFrame.healthBar:GetWidth() * (envTable._CastPercent / 100)-9, 0)\n    \n    envTable.topArrow:SetPoint (\"bottomleft\", unitFrame.healthBar, \"topleft\", unitFrame.healthBar:GetWidth() * (envTable._CastPercent / 100) - 4, 2 )\n    \n    --forces the script to run the update as fast as the game framerate\n    self.ThrottleUpdate = 0\n    \n    if (scriptTable.config.useNameplateColor) then\n        Plater.SetNameplateColor(unitFrame, envTable.NameplateColor)\n    end\n    \n    local dotSpeed = abs(envTable._Duration - envTable._RemainingTime) + 1.5\n    envTable.dotAnimation.textureInfo.speedMultiplier = dotSpeed\nend\n\n\n\n\n",
      ["version"] = -1,
      ["PlaterCore"] = 1,
      ["NpcNames"] = {
      },
      ["Temp_ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    --settings\n    envTable.NameplateSizeOffset = scriptTable.config.castBarHeight\n    envTable.ShowArrow = scriptTable.config.showArrow\n    envTable.ArrowAlpha = scriptTable.config.arrowAlpha\n    \n    --creates the spark to show the cast progress inside the health bar\n    envTable.overlaySpark = envTable.overlaySpark or Plater:CreateImage (unitFrame.healthBar)\n    envTable.overlaySpark:SetBlendMode (\"ADD\")\n    envTable.overlaySpark.width = 16\n    envTable.overlaySpark.height = 36\n    envTable.overlaySpark.alpha = .9\n    envTable.overlaySpark.texture = [[Interface\\AddOns\\Plater\\images\\spark3]]\n    \n    envTable.topArrow = envTable.topArrow or Plater:CreateImage (unitFrame.healthBar)\n    envTable.topArrow:SetBlendMode (\"ADD\")\n    envTable.topArrow.width = scriptTable.config.arrowWidth\n    envTable.topArrow.height = scriptTable.config.arrowHeight\n    envTable.topArrow.alpha = envTable.ArrowAlpha\n    envTable.topArrow.texture = [[Interface\\BUTTONS\\Arrow-Down-Up]]\n    \n    --scale animation\n    envTable.smallScaleAnimation = envTable.smallScaleAnimation or Plater:CreateAnimationHub (unitFrame.healthBar)\n    Plater:CreateAnimation (envTable.smallScaleAnimation, \"SCALE\", 1, 0.075, 1, 1, 1.08, 1.08)\n    Plater:CreateAnimation (envTable.smallScaleAnimation, \"SCALE\", 2, 0.075, 1, 1, 0.95, 0.95)    \n    --envTable.smallScaleAnimation:Play() --envTable.smallScaleAnimation:Stop()\n    \nend\n\n\n\n\n\n\n\n",
      ["semver"] = "",
      ["Temp_Initialization"] = "function (scriptTable)\n    --insert code here\n    \nend\n\n\n",
    }, -- [12]
    {
      ["ConstructorCode"] = "function (self, unitId, unitFrame, envTable)\n    \n    --settings:\n    do\n        \n        --change the nameplate color to this color\n        --can use color names: \"red\", \"yellow\"\n        --can use color hex: \"#FF0000\", \"#FFFF00\"\n        --con use color table: {1, 0, 0}, {1, 1, 0}\n        \n        envTable.Color = \"green\"\n        \n        --if true, it'll replace the health info with the unit name\n        envTable.ReplaceHealthWithName = false\n        \n        --use flash when the unit is shown in the screen\n        envTable.FlashNameplate = true\n        \n    end\n    \n    --private:\n    do\n        --create a flash for when the unit if shown\n        envTable.smallFlash = envTable.smallFlash or Plater.CreateFlash (unitFrame.healthBar, 0.15, 1, envTable.Color)\n        \n    end\n    \nend\n\n--[=[\n\nNpc IDS:\n\n141851: Spawn of G'Huun on Mythic Dungeons\n\n\n--]=]\n\n\n\n\n",
      ["OnHideCode"] = "function (self, unitId, unitFrame, envTable)\n    \n    --make plater refresh the nameplate color\n    Plater.RefreshNameplateColor (unitFrame)\n    \n        envTable.smallFlash:Stop()\n    \nend\n\n\n",
      ["OptionsValues"] = {
      },
      ["Temp_OnShowCode"] = "function (self, unitId, unitFrame, envTable)\n    \n    --check if can flash the nameplate\n    if (envTable.FlashNameplate) then\n        envTable.smallFlash:Play()\n    end\n    \nend\n\n\n\n\n\n\n\n\n",
      ["ScriptType"] = 3,
      ["UpdateCode"] = "function (self, unitId, unitFrame, envTable)\n    \n    --adjust the nameplate color\n    Plater.SetNameplateColor (unitFrame, envTable.Color)\n    \n    --check if can replace the health amount with the unit name\n    if (envTable.ReplaceHealthWithName) then\n        \n        local healthPercent = format (\"%.1f\", unitFrame.healthBar.CurrentHealth / unitFrame.healthBar.CurrentHealthMax *100)\n        \n        unitFrame.healthBar.lifePercent:SetText (unitFrame.namePlateUnitName .. \"  (\" .. healthPercent  .. \"%)\")\n        \n    end\n    \nend\n\n\n",
      ["Time"] = 1674873417,
      ["Temp_ConstructorCode"] = "function (self, unitId, unitFrame, envTable)\n    \n    --settings:\n    do\n        \n        --change the nameplate color to this color\n        --can use color names: \"red\", \"yellow\"\n        --can use color hex: \"#FF0000\", \"#FFFF00\"\n        --con use color table: {1, 0, 0}, {1, 1, 0}\n        \n        envTable.Color = \"green\"\n        \n        --if true, it'll replace the health info with the unit name\n        envTable.ReplaceHealthWithName = false\n        \n        --use flash when the unit is shown in the screen\n        envTable.FlashNameplate = true\n        \n    end\n    \n    --private:\n    do\n        --create a flash for when the unit if shown\n        envTable.smallFlash = envTable.smallFlash or Plater.CreateFlash (unitFrame.healthBar, 0.15, 1, envTable.Color)\n        \n    end\n    \nend\n\n--[=[\n\nNpc IDS:\n\n141851: Spawn of G'Huun on Mythic Dungeons\n\n\n--]=]\n\n\n\n\n",
      ["Icon"] = 135024,
      ["Temp_OnHideCode"] = "function (self, unitId, unitFrame, envTable)\n    \n    --make plater refresh the nameplate color\n    Plater.RefreshNameplateColor (unitFrame)\n    \n        envTable.smallFlash:Stop()\n    \nend\n\n\n",
      ["Revision"] = 77,
      ["Options"] = {
      },
      ["Author"] = "Izimode-Azralon",
      ["OnShowCode"] = "function (self, unitId, unitFrame, envTable)\n    \n    --check if can flash the nameplate\n    if (envTable.FlashNameplate) then\n        envTable.smallFlash:Play()\n    end\n    \nend\n\n\n\n\n\n\n\n\n",
      ["Enabled"] = true,
      ["Temp_UpdateCode"] = "function (self, unitId, unitFrame, envTable)\n    \n    --adjust the nameplate color\n    Plater.SetNameplateColor (unitFrame, envTable.Color)\n    \n    --check if can replace the health amount with the unit name\n    if (envTable.ReplaceHealthWithName) then\n        \n        local healthPercent = format (\"%.1f\", unitFrame.healthBar.CurrentHealth / unitFrame.healthBar.CurrentHealthMax *100)\n        \n        unitFrame.healthBar.lifePercent:SetText (unitFrame.namePlateUnitName .. \"  (\" .. healthPercent  .. \"%)\")\n        \n    end\n    \nend\n\n\n",
      ["Name"] = "Color Change [Plater]",
      ["PlaterCore"] = 1,
      ["Prio"] = 99,
      ["SpellIds"] = {
      },
      ["Desc"] = "Add a unitID or unit name in 'Add Trigger' entry. See the constructor script for options.",
      ["NpcNames"] = {
        "141851", -- [1]
      },
    }, -- [13]
    {
      ["ConstructorCode"] = "--gray lines are comments and doesn't affect the code\n\n--1) add the aura you want by typing its name or spellID into the \"Add Trigger\" and click the \"Add\" button.\n--2) the border will use the default color set below, to a custom color type aura name and the color you want in the BorderColorByAura table.\n\nfunction (self, unitId, unitFrame, envTable)\n    \n    --default color if the aura name isn't found in the Color By Aura table below\n    envTable.DefaultBorderColor = \"orange\"\n    \n    --transparency, affect all borders\n    envTable.BorderAlpha = 1.0\n    \n    --add the aura name and the color, \n    envTable.BorderColorByAura = {\n        \n        --examples:\n        --[\"Aura Name\"] = \"yellow\", --using regular aura name | using the name of the color\n        --[\"aura name\"] = \"#FFFF00\", --using lower case in the aura name |using html #hex for the color\n        --[54214] = {1, 1, 0}, --using the spellID instead of the name | using rgb table (0 to 1) for the color\n        --color table uses zero to one values: 255 = 1.0, 127 = 0.5, orange color = {1, 0.7, 0}\n        \n        --add your custom border colors below:\n        \n        [\"Aura Name\"] = {1, .5, 0}, --example to copy/paste\n        \n    }\n    \n    \nend\n\n\n\n\n",
      ["OnHideCode"] = "function (self, unitId, unitFrame, envTable)\n    \n    --reset the border color\n    self:SetBackdropBorderColor (0, 0, 0, 0)\n    \nend\n\n\n",
      ["OptionsValues"] = {
      },
      ["Temp_OnShowCode"] = "function (self, unitId, unitFrame, envTable)\n    \n    --get the aura name in lower case\n    local auraLowerName = string.lower (envTable._SpellName)\n    \n    --attempt to get a custom color added by the user in the constructor script\n    local hasCustomBorderColor = envTable.BorderColorByAura [auraLowerName] or envTable.BorderColorByAura [envTable._SpellName] or envTable.BorderColorByAura [envTable._SpellID]\n    \n    --save the custom color\n    envTable.CustomBorderColor = hasCustomBorderColor\n    \nend\n\n\n",
      ["ScriptType"] = 1,
      ["UpdateCode"] = "function (self, unitId, unitFrame, envTable)\n    \n    --get the custom color added by the user or the default color\n    local color = envTable.CustomBorderColor or envTable.DefaultBorderColor\n    --parse the color since it can be a color name, hex or color table\n    local r, g, b = DetailsFramework:ParseColors (color)\n    \n    --set the border color\n    self:SetBackdropBorderColor (r, g, b, envTable.BorderAlpha)\n    \nend\n\n\n\n\n",
      ["Time"] = 1699197386,
      ["Temp_ConstructorCode"] = "--gray lines are comments and doesn't affect the code\n\n--1) add the aura you want by typing its name or spellID into the \"Add Trigger\" and click the \"Add\" button.\n--2) the border will use the default color set below, to a custom color type aura name and the color you want in the BorderColorByAura table.\n\nfunction (self, unitId, unitFrame, envTable)\n    \n    --default color if the aura name isn't found in the Color By Aura table below\n    envTable.DefaultBorderColor = \"orange\"\n    \n    --transparency, affect all borders\n    envTable.BorderAlpha = 1.0\n    \n    --add the aura name and the color, \n    envTable.BorderColorByAura = {\n        \n        --examples:\n        --[\"Aura Name\"] = \"yellow\", --using regular aura name | using the name of the color\n        --[\"aura name\"] = \"#FFFF00\", --using lower case in the aura name |using html #hex for the color\n        --[54214] = {1, 1, 0}, --using the spellID instead of the name | using rgb table (0 to 1) for the color\n        --color table uses zero to one values: 255 = 1.0, 127 = 0.5, orange color = {1, 0.7, 0}\n        \n        --add your custom border colors below:\n        \n        [\"Aura Name\"] = {1, .5, 0}, --example to copy/paste\n        \n    }\n    \n    \nend\n\n\n\n\n",
      ["Icon"] = 133006,
      ["Temp_OnHideCode"] = "function (self, unitId, unitFrame, envTable)\n    \n    --reset the border color\n    self:SetBackdropBorderColor (0, 0, 0, 0)\n    \nend\n\n\n",
      ["Revision"] = 57,
      ["Options"] = {
      },
      ["Author"] = "Izimode-Azralon",
      ["OnShowCode"] = "function (self, unitId, unitFrame, envTable)\n    \n    --get the aura name in lower case\n    local auraLowerName = string.lower (envTable._SpellName)\n    \n    --attempt to get a custom color added by the user in the constructor script\n    local hasCustomBorderColor = envTable.BorderColorByAura [auraLowerName] or envTable.BorderColorByAura [envTable._SpellName] or envTable.BorderColorByAura [envTable._SpellID]\n    \n    --save the custom color\n    envTable.CustomBorderColor = hasCustomBorderColor\n    \nend\n\n\n",
      ["Enabled"] = true,
      ["Temp_UpdateCode"] = "function (self, unitId, unitFrame, envTable)\n    \n    --get the custom color added by the user or the default color\n    local color = envTable.CustomBorderColor or envTable.DefaultBorderColor\n    --parse the color since it can be a color name, hex or color table\n    local r, g, b = DetailsFramework:ParseColors (color)\n    \n    --set the border color\n    self:SetBackdropBorderColor (r, g, b, envTable.BorderAlpha)\n    \nend\n\n\n\n\n",
      ["Name"] = "Aura - Border Color [Plater]",
      ["PlaterCore"] = 1,
      ["Prio"] = 99,
      ["SpellIds"] = {
      },
      ["Desc"] = "Add a border to an aura icon. Add the aura into the Add Trigger entry. You can customize the icon color at the constructor script.",
      ["NpcNames"] = {
      },
    }, -- [14]
    {
      ["ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    --settings (require a /reload after editing any setting)\n    do\n        --blink and glow\n        envTable.BlinkEnabled = scriptTable.config.blinkEnabled\n        envTable.GlowEnabled = scriptTable.config.glowEnabled \n        envTable.ChangeNameplateColor = scriptTable.config.changeNameplateColor;\n        envTable.TimeLeftToBlink = scriptTable.config.timeleftToBlink;\n        envTable.BlinkSpeed = scriptTable.config.blinkSpeed; \n        envTable.BlinkColor = scriptTable.config.blinkColor; \n        envTable.BlinkMaxAlpha = scriptTable.config.blinkMaxAlpha; \n        envTable.NameplateColor = scriptTable.config.nameplateColor; \n        \n        --text color\n        envTable.TimerColorEnabled = scriptTable.config.timerColorEnabled \n        envTable.TimeLeftWarning = scriptTable.config.timeLeftWarning;\n        envTable.TimeLeftCritical = scriptTable.config.timeLeftCritical;\n        envTable.TextColor_Warning = scriptTable.config.warningColor; \n        envTable.TextColor_Critical = scriptTable.config.criticalColor; \n        \n        --list of spellIDs to ignore\n        envTable.IgnoredSpellID = {\n            [12] = true, --use a simple comma here\n            [13] = true,\n        }\n    end\n    \n    \n    --private\n    do\n        --if not envTable.blinkTexture then\n        envTable.blinkTexture = Plater:CreateImage (self, \"\", 1, 1, \"overlay\")\n        envTable.blinkTexture:SetPoint ('center', 0, 0)\n        envTable.blinkTexture:Hide()\n        \n        local onPlay = function()\n            envTable.blinkTexture:Show() \n            envTable.blinkTexture.color = envTable.BlinkColor\n        end\n        local onStop = function()\n            envTable.blinkTexture:Hide()  \n        end\n        envTable.blinkAnimation = Plater:CreateAnimationHub (envTable.blinkTexture, onPlay, onStop)\n        Plater:CreateAnimation (envTable.blinkAnimation, \"ALPHA\", 1, envTable.BlinkSpeed / 2, 0, envTable.BlinkMaxAlpha)\n        Plater:CreateAnimation (envTable.blinkAnimation, \"ALPHA\", 2, envTable.BlinkSpeed / 2, envTable.BlinkMaxAlpha, 0)\n        --end\n        \n        envTable.glowEffect = envTable.glowEffect or self.overlay or Plater.CreateIconGlow (self)\n        --envTable.glowEffect = envTable.glowEffect or Plater.CreateIconGlow (self)\n        --envTable.glowEffect:Show() --envTable.glowEffect:Hide()\n        \n    end\n    \nend\n\n\n\n\n",
      ["OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    envTable.blinkAnimation:Stop()\n    envTable.blinkTexture:Hide()\n    envTable.blinkAnimation:Stop()\n    envTable.glowEffect:Stop()\n    Plater:SetFontColor (self.Cooldown.Timer, Plater.db.profile.aura_timer_text_color)\nend\n\n\n",
      ["OptionsValues"] = {
      },
      ["Temp_OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    envTable.blinkTexture:SetSize (self:GetSize())\n    \nend\n\n\n",
      ["ScriptType"] = 1,
      ["UpdateCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    local timeLeft = envTable._RemainingTime\n    \n    --check if the spellID isn't being ignored\n    if (envTable.IgnoredSpellID [envTable._SpellID]) then\n        return\n    end\n    \n    --check the time left and start or stop the blink animation and also check if the time left is > zero\n    if ((envTable.BlinkEnabled or envTable.GlowEnabled) and timeLeft > 0) then\n        if (timeLeft < envTable.TimeLeftToBlink) then\n            --blink effect\n            if (envTable.BlinkEnabled) then\n                if (not envTable.blinkAnimation:IsPlaying()) then\n                    envTable.blinkAnimation:Play()\n                end\n            end\n            --glow effect\n            if (envTable.GlowEnabled) then\n                envTable.glowEffect:Show()\n            end\n            --nameplate color\n            if (envTable.ChangeNameplateColor) then\n                Plater.SetNameplateColor (unitFrame, envTable.NameplateColor)\n            end\n        else\n            --blink effect\n            if (envTable.blinkAnimation:IsPlaying()) then\n                envTable.blinkAnimation:Stop()\n            end\n            --glow effect\n            if (envTable.GlowEnabled and envTable.glowEffect:IsShown()) then\n                envTable.glowEffect:Hide()\n            end\n        end\n    end\n    \n    --timer color\n    if (envTable.TimerColorEnabled and timeLeft > 0) then\n        if (timeLeft < envTable.TimeLeftCritical) then\n            Plater:SetFontColor (self.Cooldown.Timer, envTable.TextColor_Critical)\n        elseif (timeLeft < envTable.TimeLeftWarning) then\n            Plater:SetFontColor (self.Cooldown.Timer, envTable.TextColor_Warning)        \n        else\n            Plater:SetFontColor (self.Cooldown.Timer, Plater.db.profile.aura_timer_text_color)\n        end\n    end\n    \nend",
      ["Time"] = 1671594005,
      ["Temp_OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    envTable.blinkAnimation:Stop()\n    envTable.blinkTexture:Hide()\n    envTable.blinkAnimation:Stop()\n    envTable.glowEffect:Stop()\n    Plater:SetFontColor (self.Cooldown.Timer, Plater.db.profile.aura_timer_text_color)\nend\n\n\n",
      ["url"] = "",
      ["Icon"] = "Interface\\AddOns\\Plater\\images\\icon_aura_blink",
      ["OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    envTable.blinkTexture:SetSize (self:GetSize())\n    \nend\n\n\n",
      ["Enabled"] = false,
      ["Revision"] = 376,
      ["Options"] = {
        {
          ["Type"] = 6,
          ["Key"] = "option10",
          ["Value"] = 0,
          ["Name"] = "Blank Space",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [1]
        {
          ["Type"] = 5,
          ["Key"] = "option17",
          ["Value"] = "Enter the spell name or spellID in the Add Trigger box and hit \"Add\".",
          ["Name"] = "Option 17",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_label",
          ["Desc"] = "",
        }, -- [2]
        {
          ["Type"] = 6,
          ["Key"] = "option10",
          ["Value"] = 0,
          ["Name"] = "Blank Space",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [3]
        {
          ["Type"] = 4,
          ["Key"] = "blinkEnabled",
          ["Value"] = true,
          ["Name"] = "Blink Enabled",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_bool",
          ["Desc"] = "set to 'false' to disable blink",
        }, -- [4]
        {
          ["Type"] = 4,
          ["Key"] = "glowEnabled",
          ["Value"] = true,
          ["Name"] = "Glow Enabled",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_bool",
          ["Desc"] = "set to 'false' to disable glows",
        }, -- [5]
        {
          ["Type"] = 4,
          ["Key"] = "changeNameplateColor",
          ["Value"] = false,
          ["Name"] = "Change NamePlate Color",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_bool",
          ["Desc"] = "set to 'true' to enable nameplate color change",
        }, -- [6]
        {
          ["Type"] = 2,
          ["Max"] = 20,
          ["Desc"] = "in seconds, affects the blink effect only",
          ["Min"] = 1,
          ["Key"] = "timeleftToBlink",
          ["Value"] = 3,
          ["Fraction"] = true,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Timeleft to Blink",
        }, -- [7]
        {
          ["Type"] = 2,
          ["Max"] = 3,
          ["Desc"] = "time to complete a blink loop",
          ["Min"] = 0.5,
          ["Key"] = "blinkSpeed",
          ["Value"] = 1,
          ["Fraction"] = true,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Blink Speed",
        }, -- [8]
        {
          ["Type"] = 2,
          ["Max"] = 1,
          ["Desc"] = "max transparency in the animation loop (1.0 is full opaque)",
          ["Min"] = 0.1,
          ["Key"] = "blinkMaxAlpha",
          ["Value"] = 0.6,
          ["Fraction"] = true,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Blink Max Alpha",
        }, -- [9]
        {
          ["Type"] = 1,
          ["Key"] = "blinkColor",
          ["Value"] = {
            1, -- [1]
            1, -- [2]
            1, -- [3]
            1, -- [4]
          },
          ["Name"] = "Blink Color",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
          ["Desc"] = "color of the blink",
        }, -- [10]
        {
          ["Type"] = 1,
          ["Key"] = "nameplateColor",
          ["Value"] = {
            0.28627450980392, -- [1]
            0.003921568627451, -- [2]
            0, -- [3]
            1, -- [4]
          },
          ["Name"] = "Nameplate Color",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
          ["Desc"] = "nameplate color if ChangeNameplateColor is true",
        }, -- [11]
        {
          ["Type"] = 6,
          ["Key"] = "option10",
          ["Value"] = 0,
          ["Name"] = "Blank Space",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [12]
        {
          ["Type"] = 4,
          ["Key"] = "timerColorEnabled",
          ["Value"] = true,
          ["Name"] = "Timer Color Enabled",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_bool",
          ["Desc"] = "set to 'false' to disable changes in the color of the time left text",
        }, -- [13]
        {
          ["Type"] = 2,
          ["Max"] = 20,
          ["Desc"] = "in seconds, affects the color of the text",
          ["Min"] = 1,
          ["Key"] = "timeLeftWarning",
          ["Value"] = 8,
          ["Fraction"] = true,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Time Left Warning",
        }, -- [14]
        {
          ["Type"] = 2,
          ["Max"] = 10,
          ["Desc"] = "in seconds, affects the color of the text",
          ["Min"] = 1,
          ["Key"] = "timeLeftCritical",
          ["Value"] = 3,
          ["Fraction"] = true,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Time Left Critical",
        }, -- [15]
        {
          ["Type"] = 1,
          ["Key"] = "warningColor",
          ["Value"] = {
            1, -- [1]
            0.87058823529412, -- [2]
            0, -- [3]
            1, -- [4]
          },
          ["Name"] = "Warning Color",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
          ["Desc"] = "color when the time left entered in a warning zone",
        }, -- [16]
        {
          ["Type"] = 1,
          ["Key"] = "criticalColor",
          ["Value"] = {
            1, -- [1]
            0.074509803921569, -- [2]
            0, -- [3]
            1, -- [4]
          },
          ["Name"] = "Critical Color",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
          ["Desc"] = "color when the time left is critical",
        }, -- [17]
      },
      ["Name"] = "Aura - Blink by Time Left [Plater]",
      ["Prio"] = 99,
      ["Author"] = "Izimode-Azralon",
      ["Initialization"] = "function (scriptTable)\n    --insert code here\n    \nend\n\n\n",
      ["Desc"] = "Blink, change the number and nameplate color. Add the debuffs int he trigger box. Set settings on constructor script.",
      ["SpellIds"] = {
      },
      ["Temp_UpdateCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    local timeLeft = envTable._RemainingTime\n    \n    --check if the spellID isn't being ignored\n    if (envTable.IgnoredSpellID [envTable._SpellID]) then\n        return\n    end\n    \n    --check the time left and start or stop the blink animation and also check if the time left is > zero\n    if ((envTable.BlinkEnabled or envTable.GlowEnabled) and timeLeft > 0) then\n        if (timeLeft < envTable.TimeLeftToBlink) then\n            --blink effect\n            if (envTable.BlinkEnabled) then\n                if (not envTable.blinkAnimation:IsPlaying()) then\n                    envTable.blinkAnimation:Play()\n                end\n            end\n            --glow effect\n            if (envTable.GlowEnabled) then\n                envTable.glowEffect:Show()\n            end\n            --nameplate color\n            if (envTable.ChangeNameplateColor) then\n                Plater.SetNameplateColor (unitFrame, envTable.NameplateColor)\n            end\n        else\n            --blink effect\n            if (envTable.blinkAnimation:IsPlaying()) then\n                envTable.blinkAnimation:Stop()\n            end\n            --glow effect\n            if (envTable.GlowEnabled and envTable.glowEffect:IsShown()) then\n                envTable.glowEffect:Hide()\n            end\n        end\n    end\n    \n    --timer color\n    if (envTable.TimerColorEnabled and timeLeft > 0) then\n        if (timeLeft < envTable.TimeLeftCritical) then\n            Plater:SetFontColor (self.Cooldown.Timer, envTable.TextColor_Critical)\n        elseif (timeLeft < envTable.TimeLeftWarning) then\n            Plater:SetFontColor (self.Cooldown.Timer, envTable.TextColor_Warning)        \n        else\n            Plater:SetFontColor (self.Cooldown.Timer, Plater.db.profile.aura_timer_text_color)\n        end\n    end\n    \nend",
      ["version"] = -1,
      ["PlaterCore"] = 1,
      ["NpcNames"] = {
      },
      ["Temp_ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    --settings (require a /reload after editing any setting)\n    do\n        --blink and glow\n        envTable.BlinkEnabled = scriptTable.config.blinkEnabled\n        envTable.GlowEnabled = scriptTable.config.glowEnabled \n        envTable.ChangeNameplateColor = scriptTable.config.changeNameplateColor;\n        envTable.TimeLeftToBlink = scriptTable.config.timeleftToBlink;\n        envTable.BlinkSpeed = scriptTable.config.blinkSpeed; \n        envTable.BlinkColor = scriptTable.config.blinkColor; \n        envTable.BlinkMaxAlpha = scriptTable.config.blinkMaxAlpha; \n        envTable.NameplateColor = scriptTable.config.nameplateColor; \n        \n        --text color\n        envTable.TimerColorEnabled = scriptTable.config.timerColorEnabled \n        envTable.TimeLeftWarning = scriptTable.config.timeLeftWarning;\n        envTable.TimeLeftCritical = scriptTable.config.timeLeftCritical;\n        envTable.TextColor_Warning = scriptTable.config.warningColor; \n        envTable.TextColor_Critical = scriptTable.config.criticalColor; \n        \n        --list of spellIDs to ignore\n        envTable.IgnoredSpellID = {\n            [12] = true, --use a simple comma here\n            [13] = true,\n        }\n    end\n    \n    \n    --private\n    do\n        --if not envTable.blinkTexture then\n        envTable.blinkTexture = Plater:CreateImage (self, \"\", 1, 1, \"overlay\")\n        envTable.blinkTexture:SetPoint ('center', 0, 0)\n        envTable.blinkTexture:Hide()\n        \n        local onPlay = function()\n            envTable.blinkTexture:Show() \n            envTable.blinkTexture.color = envTable.BlinkColor\n        end\n        local onStop = function()\n            envTable.blinkTexture:Hide()  \n        end\n        envTable.blinkAnimation = Plater:CreateAnimationHub (envTable.blinkTexture, onPlay, onStop)\n        Plater:CreateAnimation (envTable.blinkAnimation, \"ALPHA\", 1, envTable.BlinkSpeed / 2, 0, envTable.BlinkMaxAlpha)\n        Plater:CreateAnimation (envTable.blinkAnimation, \"ALPHA\", 2, envTable.BlinkSpeed / 2, envTable.BlinkMaxAlpha, 0)\n        --end\n        \n        envTable.glowEffect = envTable.glowEffect or self.overlay or Plater.CreateIconGlow (self)\n        --envTable.glowEffect = envTable.glowEffect or Plater.CreateIconGlow (self)\n        --envTable.glowEffect:Show() --envTable.glowEffect:Hide()\n        \n    end\n    \nend\n\n\n\n\n",
      ["semver"] = "",
      ["Temp_Initialization"] = "function (scriptTable)\n    --insert code here\n    \nend\n\n\n",
    }, -- [15]
    {
      ["ConstructorCode"] = "function (self, unitId, unitFrame, envTable)\n    \n    envTable.CastbarColor = \"orangered\"\n    \n    --settings (you may need /reload if some configs isn't applied immediately)\n    local CONFIG_BACKGROUND_FLASH_DURATION = 0.8 --0.8\n    local CONFIG_BORDER_GLOW_ALPHA = 0 --0.3\n    local CONFIG_SHAKE_DURATION = 0.2 --0.2\n    local CONFIG_SHAKE_AMPLITUDE = 5 --5\n    \n    envTable.CastBarHeightAdd = 1.5\n    \n    --create a glow effect in the border of the cast bar\n    envTable.glowEffect = envTable.glowEffect or Plater.CreateNameplateGlow (self)\n    envTable.glowEffect:SetOffset (-22, 20, 8, -11)\n    envTable.glowEffect:SetAlpha (CONFIG_BORDER_GLOW_ALPHA)\n    --envTable.glowEffect:Show() --envTable.glowEffect:Hide() \n    \n    --create a texture to use for a flash behind the cast bar\n    local backGroundFlashTexture = Plater:CreateImage (self, [[Interface\\ACHIEVEMENTFRAME\\UI-Achievement-Alert-Glow]], self:GetWidth()+20, self:GetHeight()+30, \"background\", {0, 400/512, 0, 170/256})\n    backGroundFlashTexture:SetBlendMode (\"ADD\")\n    backGroundFlashTexture:SetPoint (\"center\", self, \"center\")\n    backGroundFlashTexture:Hide()\n    \n    --create the animation hub to hold the flash animation sequence\n    envTable.BackgroundFlash = envTable.BackgroundFlash or Plater:CreateAnimationHub (backGroundFlashTexture, \n        function()\n            backGroundFlashTexture:Show()\n        end,\n        function()\n            backGroundFlashTexture:Hide()\n        end\n    )\n    \n    --create the flash animation sequence\n    local fadeIn = Plater:CreateAnimation (envTable.BackgroundFlash, \"ALPHA\", 1, CONFIG_BACKGROUND_FLASH_DURATION/2, 0, 1)\n    local fadeOut = Plater:CreateAnimation (envTable.BackgroundFlash, \"ALPHA\", 2, CONFIG_BACKGROUND_FLASH_DURATION/2, 1, 0)    \n    --envTable.BackgroundFlash:Play() --envTable.BackgroundFlash:Stop()\n    \n    --create a camera shake for the nameplate\n    envTable.FrameShake = Plater:CreateFrameShake (self, CONFIG_SHAKE_DURATION, CONFIG_SHAKE_AMPLITUDE, 35, false, false, 0, 1, 0.05, 0.1, true)    \n    \n    \n    --update the config for the flash here so it wont need a /reload\n    fadeIn:SetDuration (CONFIG_BACKGROUND_FLASH_DURATION/2)\n    fadeOut:SetDuration (CONFIG_BACKGROUND_FLASH_DURATION/2)    \n    \n    --update the config for the skake here so it wont need a /reload\n    envTable.FrameShake.OriginalAmplitude = CONFIG_SHAKE_AMPLITUDE\n    envTable.FrameShake.OriginalDuration = CONFIG_SHAKE_DURATION  \n    \nend",
      ["OnHideCode"] = "function (self, unitId, unitFrame, envTable)\n    \n    if (Plater.ZoneInstanceType == \"arena\" or Plater.ZoneInstanceType == \"pvp\") then\n        return\n    end    \n    \n    envTable.glowEffect:Hide()\n    \n    envTable.BackgroundFlash:Stop()\n    \n    self:StopFrameShake (envTable.FrameShake)    \n    \n    --restore the cast bar to its original height\n    if (envTable.OriginalHeight) then\n        self:SetWidth (envTable.OriginalWidth)\n        self:SetHeight (envTable.OriginalHeight)\n        envTable.OriginalHeight = nil\n        envTable.OriginalWidth = nil\n    end\n    \nend\n\n\n\n\n\n\n\n\n\n\n\n",
      ["OptionsValues"] = {
      },
      ["Temp_OnShowCode"] = "function (self, unitId, unitFrame, envTable)\n    \n    if (Plater.ZoneInstanceType == \"arena\" or Plater.ZoneInstanceType == \"pvp\") then\n        return\n    end\n    \n    envTable.glowEffect:Show()\n    \n    envTable.BackgroundFlash:Play()\n    \n    Plater.FlashNameplateBorder (unitFrame, 0.05)   \n    Plater.FlashNameplateBody (unitFrame, \"\", 0.075)\n    \n    self:PlayFrameShake (envTable.FrameShake)\n    \n    if (envTable._CanInterrupt) then\n        self:SetStatusBarColor (Plater:ParseColors (envTable.CastbarColor))\n    end\n    \n    Plater.SetCastBarBorderColor (self, 1, 0, 0, 0.4)\n    \n    --restoring the default size (not required since it already restore in the hide script)\n    if (envTable.OriginalHeight) then\n        self:SetWidth (envTable.OriginalWidth)\n        self:SetHeight (envTable.OriginalHeight)\n    end\n    \n    \n    --increase the cast bar size\n    envTable.OriginalHeight = self:GetHeight()\n    envTable.OriginalWidth = self:GetWidth()\n    local width = Plater.db.profile.plate_config.enemynpc.cast_incombat[1]\n    local height = Plater.db.profile.plate_config.enemynpc.cast_incombat[2]\n    \n    self:SetWidth (width)\n    self:SetHeight (height * envTable.CastBarHeightAdd)\n    \n    print (envTable.glowEffect:GetAlpha())\n    \nend",
      ["ScriptType"] = 2,
      ["UpdateCode"] = "function (self, unitId, unitFrame, envTable)\n    \nend\n\n\n",
      ["Time"] = 1675185048,
      ["Temp_ConstructorCode"] = "function (self, unitId, unitFrame, envTable)\n    \n    envTable.CastbarColor = \"orangered\"\n    \n    --settings (you may need /reload if some configs isn't applied immediately)\n    local CONFIG_BACKGROUND_FLASH_DURATION = 0.8 --0.8\n    local CONFIG_BORDER_GLOW_ALPHA = 0 --0.3\n    local CONFIG_SHAKE_DURATION = 0.2 --0.2\n    local CONFIG_SHAKE_AMPLITUDE = 5 --5\n    \n    envTable.CastBarHeightAdd = 1.5\n    \n    --create a glow effect in the border of the cast bar\n    envTable.glowEffect = envTable.glowEffect or Plater.CreateNameplateGlow (self)\n    envTable.glowEffect:SetOffset (-22, 20, 8, -11)\n    envTable.glowEffect:SetAlpha (CONFIG_BORDER_GLOW_ALPHA)\n    --envTable.glowEffect:Show() --envTable.glowEffect:Hide() \n    \n    --create a texture to use for a flash behind the cast bar\n    local backGroundFlashTexture = Plater:CreateImage (self, [[Interface\\ACHIEVEMENTFRAME\\UI-Achievement-Alert-Glow]], self:GetWidth()+20, self:GetHeight()+30, \"background\", {0, 400/512, 0, 170/256})\n    backGroundFlashTexture:SetBlendMode (\"ADD\")\n    backGroundFlashTexture:SetPoint (\"center\", self, \"center\")\n    backGroundFlashTexture:Hide()\n    \n    --create the animation hub to hold the flash animation sequence\n    envTable.BackgroundFlash = envTable.BackgroundFlash or Plater:CreateAnimationHub (backGroundFlashTexture, \n        function()\n            backGroundFlashTexture:Show()\n        end,\n        function()\n            backGroundFlashTexture:Hide()\n        end\n    )\n    \n    --create the flash animation sequence\n    local fadeIn = Plater:CreateAnimation (envTable.BackgroundFlash, \"ALPHA\", 1, CONFIG_BACKGROUND_FLASH_DURATION/2, 0, 1)\n    local fadeOut = Plater:CreateAnimation (envTable.BackgroundFlash, \"ALPHA\", 2, CONFIG_BACKGROUND_FLASH_DURATION/2, 1, 0)    \n    --envTable.BackgroundFlash:Play() --envTable.BackgroundFlash:Stop()\n    \n    --create a camera shake for the nameplate\n    envTable.FrameShake = Plater:CreateFrameShake (self, CONFIG_SHAKE_DURATION, CONFIG_SHAKE_AMPLITUDE, 35, false, false, 0, 1, 0.05, 0.1, true)    \n    \n    \n    --update the config for the flash here so it wont need a /reload\n    fadeIn:SetDuration (CONFIG_BACKGROUND_FLASH_DURATION/2)\n    fadeOut:SetDuration (CONFIG_BACKGROUND_FLASH_DURATION/2)    \n    \n    --update the config for the skake here so it wont need a /reload\n    envTable.FrameShake.OriginalAmplitude = CONFIG_SHAKE_AMPLITUDE\n    envTable.FrameShake.OriginalDuration = CONFIG_SHAKE_DURATION  \n    \nend",
      ["Icon"] = "INTERFACE\\ICONS\\Spell_Fire_FelFlameStrike",
      ["Temp_OnHideCode"] = "function (self, unitId, unitFrame, envTable)\n    \n    if (Plater.ZoneInstanceType == \"arena\" or Plater.ZoneInstanceType == \"pvp\") then\n        return\n    end    \n    \n    envTable.glowEffect:Hide()\n    \n    envTable.BackgroundFlash:Stop()\n    \n    self:StopFrameShake (envTable.FrameShake)    \n    \n    --restore the cast bar to its original height\n    if (envTable.OriginalHeight) then\n        self:SetWidth (envTable.OriginalWidth)\n        self:SetHeight (envTable.OriginalHeight)\n        envTable.OriginalHeight = nil\n        envTable.OriginalWidth = nil\n    end\n    \nend\n\n\n\n\n\n\n\n\n\n\n\n",
      ["Revision"] = 1391,
      ["Options"] = {
      },
      ["Enabled"] = false,
      ["Author"] = "Tercioo-Sylvanas",
      ["Initialization"] = "function (scriptTable)\n    --insert code here\n    \nend\n\n\n",
      ["Desc"] = "Flash, Bounce and Red Color the CastBar border when when an important cast is happening. Add spell in the Add Trigger field.",
      ["Temp_UpdateCode"] = "function (self, unitId, unitFrame, envTable)\n    \nend\n\n\n",
      ["Prio"] = 99,
      ["Name"] = "M+ Important Spells [Plater]",
      ["PlaterCore"] = 1,
      ["Temp_Initialization"] = "function (scriptTable)\n    --insert code here\n    \nend\n\n\n",
      ["SpellIds"] = {
        258153, -- [1]
        258313, -- [2]
        274569, -- [3]
        278020, -- [4]
        261635, -- [5]
        272700, -- [6]
        268030, -- [7]
        265368, -- [8]
        264520, -- [9]
        265407, -- [10]
        278567, -- [11]
        278602, -- [12]
        258128, -- [13]
        257791, -- [14]
        258938, -- [15]
        265089, -- [16]
        272183, -- [17]
        269972, -- [18]
        270901, -- [19]
        270492, -- [20]
        263215, -- [21]
        268797, -- [22]
        262554, -- [23]
        253517, -- [24]
        255041, -- [25]
        252781, -- [26]
        250368, -- [27]
        278504, -- [28]
        266106, -- [29]
        268309, -- [30]
        269302, -- [31]
        263202, -- [32]
        278755, -- [33]
        272180, -- [34]
        263066, -- [35]
        267273, -- [36]
        265912, -- [37]
        274438, -- [38]
        268317, -- [39]
        268375, -- [40]
        276767, -- [41]
        264105, -- [42]
        265876, -- [43]
        270464, -- [44]
        265468, -- [45]
        256897, -- [46]
        280604, -- [47]
        268702, -- [48]
        255824, -- [49]
        253583, -- [50]
        250096, -- [51]
        278456, -- [52]
        262092, -- [53]
        257270, -- [54]
        267818, -- [55]
        262540, -- [56]
        263318, -- [57]
        263959, -- [58]
        257069, -- [59]
        256849, -- [60]
        267459, -- [61]
        253544, -- [62]
        268008, -- [63]
        267981, -- [64]
        272659, -- [65]
        264396, -- [66]
        264390, -- [67]
        274400, -- [68]
        269029, -- [69]
        272827, -- [70]
        269266, -- [71]
        263912, -- [72]
        264923, -- [73]
        258864, -- [74]
        256955, -- [75]
        265540, -- [76]
        270003, -- [77]
        270507, -- [78]
        257337, -- [79]
        268415, -- [80]
        275907, -- [81]
        268865, -- [82]
        260669, -- [83]
        260280, -- [84]
        253239, -- [85]
        265541, -- [86]
        250258, -- [87]
        256709, -- [88]
        277596, -- [89]
        276268, -- [90]
        265372, -- [91]
        263905, -- [92]
        265781, -- [93]
        257170, -- [94]
        268846, -- [95]
        270514, -- [96]
        258622, -- [97]
        258199, -- [98]
        256627, -- [99]
        259711, -- [100]
        258917, -- [101]
        263891, -- [102]
        268027, -- [103]
        268348, -- [104]
        269313, -- [105]
        272711, -- [106]
        271174, -- [107]
        268260, -- [108]
        269399, -- [109]
        268239, -- [110]
        264574, -- [111]
        261563, -- [112]
        257288, -- [113]
        257757, -- [114]
        267899, -- [115]
        255741, -- [116]
        264757, -- [117]
        260894, -- [118]
        263583, -- [119]
        276292, -- [120]
        272874, -- [121]
        264101, -- [122]
        264407, -- [123]
        271456, -- [124]
        262515, -- [125]
        275192, -- [126]
        270084, -- [127]
        257785, -- [128]
        267237, -- [129]
        266951, -- [130]
        267433, -- [131]
        255577, -- [132]
        255371, -- [133]
        270891, -- [134]
        267357, -- [135]
        258338, -- [136]
        257169, -- [137]
        270927, -- [138]
        273995, -- [139]
        260926, -- [140]
        264027, -- [141]
        267257, -- [142]
        253721, -- [143]
        260924, -- [144]
        263309, -- [145]
        266206, -- [146]
        268187, -- [147]
        260067, -- [148]
        274507, -- [149]
        276068, -- [150]
        263278, -- [151]
        258317, -- [152]
        256594, -- [153]
        268391, -- [154]
        268230, -- [155]
        260852, -- [156]
        267763, -- [157]
        268706, -- [158]
        264734, -- [159]
        288693, -- [160]
        288694, -- [161]
        270590, -- [162]
        290787, -- [163]
        72286, -- [164]
      },
      ["NpcNames"] = {
      },
      ["OnShowCode"] = "function (self, unitId, unitFrame, envTable)\n    \n    if (Plater.ZoneInstanceType == \"arena\" or Plater.ZoneInstanceType == \"pvp\") then\n        return\n    end\n    \n    envTable.glowEffect:Show()\n    \n    envTable.BackgroundFlash:Play()\n    \n    Plater.FlashNameplateBorder (unitFrame, 0.05)   \n    Plater.FlashNameplateBody (unitFrame, \"\", 0.075)\n    \n    self:PlayFrameShake (envTable.FrameShake)\n    \n    if (envTable._CanInterrupt) then\n        self:SetStatusBarColor (Plater:ParseColors (envTable.CastbarColor))\n    end\n    \n    Plater.SetCastBarBorderColor (self, 1, 0, 0, 0.4)\n    \n    --restoring the default size (not required since it already restore in the hide script)\n    if (envTable.OriginalHeight) then\n        self:SetWidth (envTable.OriginalWidth)\n        self:SetHeight (envTable.OriginalHeight)\n    end\n    \n    \n    --increase the cast bar size\n    envTable.OriginalHeight = self:GetHeight()\n    envTable.OriginalWidth = self:GetWidth()\n    local width = Plater.db.profile.plate_config.enemynpc.cast_incombat[1]\n    local height = Plater.db.profile.plate_config.enemynpc.cast_incombat[2]\n    \n    self:SetWidth (width)\n    self:SetHeight (height * envTable.CastBarHeightAdd)\n    \n    print (envTable.glowEffect:GetAlpha())\n    \nend",
    }, -- [16]
    {
      ["ConstructorCode"] = "function (self, unitId, unitFrame, envTable)\n    \n    --custom frames\n    unitFrame.JadeFireGlowEffect = unitFrame.JadeFireGlowEffect or Plater.CreateNameplateGlow (unitFrame.healthBar)\n    unitFrame.JadeFireGlowEffect:SetOffset (-27, 25, 6, -8)\n    unitFrame.JadeFireGlowEffect:Hide()\n    \nend\n\n\n",
      ["OnHideCode"] = "function (self, unitId, unitFrame, envTable)\n    unitFrame.JadeFireGlowEffect:Hide() \nend\n\n\n",
      ["OptionsValues"] = {
      },
      ["Temp_OnShowCode"] = "function (self, unitId, unitFrame, envTable)\n    unitFrame.JadeFireGlowEffect:Show() \nend\n\n\n",
      ["ScriptType"] = 1,
      ["UpdateCode"] = "function (self, unitId, unitFrame, envTable)\n    unitFrame.JadeFireGlowEffect:SetAlpha (.5)\nend\n\n\n",
      ["Time"] = 1681735065,
      ["Temp_ConstructorCode"] = "function (self, unitId, unitFrame, envTable)\n    \n    --custom frames\n    unitFrame.JadeFireGlowEffect = unitFrame.JadeFireGlowEffect or Plater.CreateNameplateGlow (unitFrame.healthBar)\n    unitFrame.JadeFireGlowEffect:SetOffset (-27, 25, 6, -8)\n    unitFrame.JadeFireGlowEffect:Hide()\n    \nend\n\n\n",
      ["Icon"] = 132221,
      ["Temp_OnHideCode"] = "function (self, unitId, unitFrame, envTable)\n    unitFrame.JadeFireGlowEffect:Hide() \nend\n\n\n",
      ["Revision"] = 39,
      ["Options"] = {
      },
      ["Author"] = "Kastfall-Azralon",
      ["OnShowCode"] = "function (self, unitId, unitFrame, envTable)\n    unitFrame.JadeFireGlowEffect:Show() \nend\n\n\n",
      ["Enabled"] = true,
      ["Temp_UpdateCode"] = "function (self, unitId, unitFrame, envTable)\n    unitFrame.JadeFireGlowEffect:SetAlpha (.5)\nend\n\n\n",
      ["Name"] = "Jadefire [BOD] - Fire Shield",
      ["PlaterCore"] = 1,
      ["Prio"] = 99,
      ["SpellIds"] = {
        286425, -- [1]
      },
      ["Desc"] = "Alert when the unit has the Fire Shield to be broken.",
      ["NpcNames"] = {
      },
    }, -- [17]
    {
      ["ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    --settings\n    envTable.NameplateSizeOffset = scriptTable.config.castBarHeight\n    envTable.ShowArrow = scriptTable.config.showArrow\n    envTable.ArrowAlpha = scriptTable.config.arrowAlpha\n    \n    --creates the spark to show the cast progress inside the health bar\n    envTable.overlaySpark = envTable.overlaySpark or Plater:CreateImage (unitFrame.healthBar)\n    envTable.overlaySpark:SetBlendMode (\"ADD\")\n    envTable.overlaySpark.width = 16\n    envTable.overlaySpark.height = 36\n    envTable.overlaySpark.alpha = .9\n    envTable.overlaySpark.texture = [[Interface\\AddOns\\Plater\\images\\spark3]]\n    \n    envTable.topArrow = envTable.topArrow or Plater:CreateImage (unitFrame.healthBar)\n    envTable.topArrow:SetBlendMode (\"ADD\")\n    envTable.topArrow.width = scriptTable.config.arrowWidth\n    envTable.topArrow.height = scriptTable.config.arrowHeight\n    envTable.topArrow.alpha = envTable.ArrowAlpha\n    envTable.topArrow.texture = [[Interface\\BUTTONS\\Arrow-Down-Up]]\n    \n    --scale animation\n    envTable.smallScaleAnimation = envTable.smallScaleAnimation or Plater:CreateAnimationHub (unitFrame.healthBar)\n    Plater:CreateAnimation (envTable.smallScaleAnimation, \"SCALE\", 1, 0.075, 1, 1, 1.08, 1.08)\n    Plater:CreateAnimation (envTable.smallScaleAnimation, \"SCALE\", 2, 0.075, 1, 1, 0.95, 0.95)    \n    --envTable.smallScaleAnimation:Play() --envTable.smallScaleAnimation:Stop()\n    \n    --create a camera shake for the nameplate\n    envTable.FrameShake = Plater:CreateFrameShake (unitFrame, scriptTable.config.shakeDuration, scriptTable.config.shakeAmplitude, scriptTable.config.shakeFrequency, false, false, 0, 1, 0.05, 0.1, Plater.GetPoints (unitFrame))    \n    \n    --update the config for the skake here so it wont need a /reload\n    envTable.FrameShake.OriginalAmplitude = scriptTable.config.shakeAmplitude\n    envTable.FrameShake.OriginalDuration = scriptTable.config.shakeDuration\n    envTable.FrameShake.OriginalFrequency = scriptTable.config.shakeFrequency\nend\n\n\n\n\n\n\n\n",
      ["OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    Plater.StopDotAnimation(unitFrame.healthBar, envTable.dotAnimation)\n    \n    envTable.overlaySpark:Hide()\n    envTable.topArrow:Hide()\n    \n    Plater.RefreshNameplateColor (unitFrame)\n    \n    envTable.smallScaleAnimation:Stop()\n    \n    --increase the nameplate size\n    local nameplateHeight = Plater.db.profile.plate_config.enemynpc.health_incombat [2]\n    unitFrame.healthBar:SetHeight (nameplateHeight)\n    \n    Plater.DenyColorChange(unitFrame, false)\nend\n\n\n",
      ["OptionsValues"] = {
        ["castColor"] = {
          {
            "200682", -- [1]
            "darkslateblue", -- [2]
          }, -- [1]
          {
            "192307", -- [1]
            "goldenrod", -- [2]
          }, -- [2]
          {
            "196838", -- [1]
            "maroon", -- [2]
          }, -- [3]
          {
            "193827", -- [1]
            "darkgreen", -- [2]
          }, -- [4]
          {
            "194043", -- [1]
            "darkgreen", -- [2]
          }, -- [5]
          {
            "156718", -- [1]
            "DRUID", -- [2]
          }, -- [6]
          {
            "395859", -- [1]
            "ROGUE", -- [2]
          }, -- [7]
        },
        ["castBarColor"] = {
          1, -- [1]
          0.9058824181556702, -- [2]
          0.02745098248124123, -- [3]
          1, -- [4]
        },
      },
      ["Temp_OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    envTable.overlaySpark:Show()\n    \n    if (envTable.ShowArrow) then\n        envTable.topArrow:Show()\n    else\n        envTable.topArrow:Hide()\n    end\n    \n    Plater.FlashNameplateBorder (unitFrame, 0.05)   \n    Plater.FlashNameplateBody (unitFrame, \"\", 0.075)\n    \n    envTable.smallScaleAnimation:Play()\n    \n    --increase the nameplate size\n    local nameplateHeight = Plater.db.profile.plate_config.enemynpc.health_incombat [2]\n    unitFrame.healthBar:SetHeight (nameplateHeight + envTable.NameplateSizeOffset)\n    \n    envTable.overlaySpark.height = nameplateHeight + 5\n    \n    envTable.dotAnimation = Plater.PlayDotAnimation(unitFrame.healthBar, 2, scriptTable.config.dotColor, scriptTable.config.xOffset, scriptTable.config.yOffset)\n    \n    local customColor = scriptTable.config.castColor[tostring(envTable._SpellID)]\n    \n    Plater.SetCastBarColorForScript(self, scriptTable.config.useCastbarColor, customColor or scriptTable.config.castBarColor, envTable)\n    \n    if (scriptTable.config.useNameplateColor) then\n        local npcIdString = tostring(envTable._NpcID)\n        envTable.NameplateColor = Plater.GetColorByPriority(unitFrame, scriptTable.config.healthBarColor)        \n        Plater.DenyColorChange(unitFrame, true)            \n    end\n    \nend",
      ["ScriptType"] = 2,
      ["UpdateCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    --update the percent\n    envTable.overlaySpark:SetPoint (\"left\", unitFrame.healthBar:GetWidth() * (envTable._CastPercent / 100)-9, 0)\n    \n    envTable.topArrow:SetPoint (\"bottomleft\", unitFrame.healthBar, \"topleft\", unitFrame.healthBar:GetWidth() * (envTable._CastPercent / 100) - 4, 2 )\n    \n    --forces the script to update on a 60Hz base\n    self.ThrottleUpdate = 0\n    \n    if (scriptTable.config.useNameplateColor) then\n        Plater.SetNameplateColor(unitFrame, envTable.NameplateColor)\n    end\n    \nend\n\n\n\n\n",
      ["Time"] = 1689713915,
      ["Temp_OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    Plater.StopDotAnimation(unitFrame.healthBar, envTable.dotAnimation)\n    \n    envTable.overlaySpark:Hide()\n    envTable.topArrow:Hide()\n    \n    Plater.RefreshNameplateColor (unitFrame)\n    \n    envTable.smallScaleAnimation:Stop()\n    \n    --increase the nameplate size\n    local nameplateHeight = Plater.db.profile.plate_config.enemynpc.health_incombat [2]\n    unitFrame.healthBar:SetHeight (nameplateHeight)\n    \n    Plater.DenyColorChange(unitFrame, false)\nend\n\n\n",
      ["url"] = "",
      ["Icon"] = "Interface\\AddOns\\Plater\\images\\cast_bar_red",
      ["OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    envTable.overlaySpark:Show()\n    \n    if (envTable.ShowArrow) then\n        envTable.topArrow:Show()\n    else\n        envTable.topArrow:Hide()\n    end\n    \n    Plater.FlashNameplateBorder (unitFrame, 0.05)   \n    Plater.FlashNameplateBody (unitFrame, \"\", 0.075)\n    \n    envTable.smallScaleAnimation:Play()\n    \n    --increase the nameplate size\n    local nameplateHeight = Plater.db.profile.plate_config.enemynpc.health_incombat [2]\n    unitFrame.healthBar:SetHeight (nameplateHeight + envTable.NameplateSizeOffset)\n    \n    envTable.overlaySpark.height = nameplateHeight + 5\n    \n    envTable.dotAnimation = Plater.PlayDotAnimation(unitFrame.healthBar, 2, scriptTable.config.dotColor, scriptTable.config.xOffset, scriptTable.config.yOffset)\n    \n    local customColor = scriptTable.config.castColor[tostring(envTable._SpellID)]\n    \n    Plater.SetCastBarColorForScript(self, scriptTable.config.useCastbarColor, customColor or scriptTable.config.castBarColor, envTable)\n    \n    if (scriptTable.config.useNameplateColor) then\n        local npcIdString = tostring(envTable._NpcID)\n        envTable.NameplateColor = Plater.GetColorByPriority(unitFrame, scriptTable.config.healthBarColor)        \n        Plater.DenyColorChange(unitFrame, true)            \n    end\n    \nend",
      ["Enabled"] = false,
      ["Revision"] = 723,
      ["Options"] = {
        {
          ["Type"] = 6,
          ["Key"] = "option1",
          ["Value"] = 0,
          ["Name"] = "Option 1",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [1]
        {
          ["Type"] = 5,
          ["Key"] = "option2",
          ["Value"] = "Plays a special animation showing the explosion time.",
          ["Name"] = "Option 2",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_label",
          ["Desc"] = "",
        }, -- [2]
        {
          ["Type"] = 6,
          ["Key"] = "option3",
          ["Value"] = 0,
          ["Name"] = "Option 3",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [3]
        {
          ["Type"] = 2,
          ["Max"] = 6,
          ["Desc"] = "Increases the health bar height by this value",
          ["Min"] = 0,
          ["Key"] = "castBarHeight",
          ["Value"] = 3,
          ["Fraction"] = false,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Health Bar Height Mod",
        }, -- [4]
        {
          ["Type"] = 4,
          ["Key"] = "useNameplateColor",
          ["Value"] = true,
          ["Name"] = "Change Nameplate Color",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_bool",
          ["Desc"] = "Change Nameplate Color",
        }, -- [5]
        {
          ["Type"] = 1,
          ["Key"] = "healthBarColor",
          ["Value"] = {
            1, -- [1]
            0.5843137254902, -- [2]
            0, -- [3]
            1, -- [4]
          },
          ["Name"] = "Nameplate Color",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
          ["Desc"] = "Nameplate Color",
        }, -- [6]
        {
          ["Type"] = 6,
          ["Key"] = "option7",
          ["Value"] = 0,
          ["Name"] = "Option 7",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [7]
        {
          ["Type"] = 4,
          ["Key"] = "useCastbarColor",
          ["Value"] = true,
          ["Name"] = "Use Cast Bar Color",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_bool",
          ["Desc"] = "Show an arrow above Use Cast Bar Color",
        }, -- [8]
        {
          ["Type"] = 1,
          ["Key"] = "castBarColor",
          ["Value"] = {
            1, -- [1]
            0.431372, -- [2]
            0, -- [3]
            1, -- [4]
          },
          ["Name"] = "Cast Bar Color",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
          ["Desc"] = "Cast Bar Color",
        }, -- [9]
        {
          ["Type"] = 6,
          ["Key"] = "option7",
          ["Value"] = 0,
          ["Name"] = "Option 7",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [10]
        {
          ["Type"] = 5,
          ["Key"] = "option6",
          ["Value"] = "Arrow:",
          ["Name"] = "Arrow:",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_label",
          ["Desc"] = "",
        }, -- [11]
        {
          ["Type"] = 4,
          ["Key"] = "showArrow",
          ["Value"] = true,
          ["Name"] = "Show Arrow",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_bool",
          ["Desc"] = "Show an arrow above the nameplate showing the cast bar progress.",
        }, -- [12]
        {
          ["Type"] = 2,
          ["Max"] = 1,
          ["Desc"] = "Arrow alpha.",
          ["Min"] = 0,
          ["Key"] = "arrowAlpha",
          ["Value"] = 0.5,
          ["Fraction"] = true,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Arrow Alpha",
        }, -- [13]
        {
          ["Type"] = 2,
          ["Max"] = 12,
          ["Desc"] = "Arrow Width.",
          ["Min"] = 4,
          ["Key"] = "arrowWidth",
          ["Value"] = 8,
          ["Fraction"] = false,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Arrow Width",
        }, -- [14]
        {
          ["Type"] = 2,
          ["Max"] = 12,
          ["Desc"] = "Arrow Height.",
          ["Min"] = 4,
          ["Key"] = "arrowHeight",
          ["Value"] = 8,
          ["Fraction"] = false,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Arrow Height",
        }, -- [15]
        {
          ["Type"] = 6,
          ["Key"] = "option13",
          ["Value"] = 0,
          ["Name"] = "Option 13",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [16]
        {
          ["Type"] = 5,
          ["Key"] = "option12",
          ["Value"] = "Dot Animation:",
          ["Name"] = "Dot Animation:",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_label",
          ["Desc"] = "",
        }, -- [17]
        {
          ["Type"] = 1,
          ["Key"] = "dotColor",
          ["Value"] = {
            1, -- [1]
            0.6156862745098, -- [2]
            0, -- [3]
            1, -- [4]
          },
          ["Name"] = "Dot Color",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
          ["Desc"] = "Adjust the color of the dot animation.",
        }, -- [18]
        {
          ["Type"] = 2,
          ["Max"] = 10,
          ["Desc"] = "Dot X Offset",
          ["Min"] = -10,
          ["Key"] = "xOffset",
          ["Value"] = 4,
          ["Fraction"] = false,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Dot X Offset",
        }, -- [19]
        {
          ["Type"] = 2,
          ["Max"] = 10,
          ["Desc"] = "Dot Y Offset",
          ["Min"] = -10,
          ["Key"] = "yOffset",
          ["Value"] = 3,
          ["Fraction"] = false,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Dot Y Offset",
        }, -- [20]
        {
          ["Type"] = 7,
          ["Key"] = "castColor",
          ["Value"] = {
            {
              "200682", -- [1]
              "darkslateblue", -- [2]
            }, -- [1]
            {
              "192307", -- [1]
              "goldenrod", -- [2]
            }, -- [2]
            {
              "196838", -- [1]
              "maroon", -- [2]
            }, -- [3]
            {
              "193827", -- [1]
              "darkgreen", -- [2]
            }, -- [4]
            {
              "194043", -- [1]
              "darkgreen", -- [2]
            }, -- [5]
            {
              "156718", -- [1]
              "DRUID", -- [2]
            }, -- [6]
            {
              "395859", -- [1]
              "ROGUE", -- [2]
            }, -- [7]
          },
          ["Name"] = "Color List by SpellId",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_list",
          ["Desc"] = "Insert the spellId in the Key, and the color name in the Value",
        }, -- [21]
      },
      ["Name"] = "Cast - Ultra Important [P]",
      ["Prio"] = 99,
      ["Author"] = "Bombad o-Azralon",
      ["Initialization"] = "function (scriptTable)\n    --insert code here\n    \nend\n\n\n",
      ["Desc"] = "Used on casts that make the mob explode or transform if the cast passes.",
      ["SpellIds"] = {
        383823, -- [1]
        382670, -- [2]
        388537, -- [3]
        372851, -- [4]
        200682, -- [5]
        192307, -- [6]
        196838, -- [7]
        193827, -- [8]
        194043, -- [9]
        209410, -- [10]
        211464, -- [11]
        361180, -- [12]
        156718, -- [13]
        395859, -- [14]
        358320, -- [15]
        374045, -- [16]
        386757, -- [17]
        367500, -- [18]
        370225, -- [19]
        376200, -- [20]
        372107, -- [21]
        388923, -- [22]
        376934, -- [23]
        384899, -- [24]
        373960, -- [25]
        374724, -- [26]
        385551, -- [27]
        259732, -- [28]
        373424, -- [29]
        373084, -- [30]
        87618, -- [31]
      },
      ["Temp_UpdateCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    --update the percent\n    envTable.overlaySpark:SetPoint (\"left\", unitFrame.healthBar:GetWidth() * (envTable._CastPercent / 100)-9, 0)\n    \n    envTable.topArrow:SetPoint (\"bottomleft\", unitFrame.healthBar, \"topleft\", unitFrame.healthBar:GetWidth() * (envTable._CastPercent / 100) - 4, 2 )\n    \n    --forces the script to update on a 60Hz base\n    self.ThrottleUpdate = 0\n    \n    if (scriptTable.config.useNameplateColor) then\n        Plater.SetNameplateColor(unitFrame, envTable.NameplateColor)\n    end\n    \nend\n\n\n\n\n",
      ["version"] = -1,
      ["PlaterCore"] = 1,
      ["NpcNames"] = {
      },
      ["Temp_ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    --settings\n    envTable.NameplateSizeOffset = scriptTable.config.castBarHeight\n    envTable.ShowArrow = scriptTable.config.showArrow\n    envTable.ArrowAlpha = scriptTable.config.arrowAlpha\n    \n    --creates the spark to show the cast progress inside the health bar\n    envTable.overlaySpark = envTable.overlaySpark or Plater:CreateImage (unitFrame.healthBar)\n    envTable.overlaySpark:SetBlendMode (\"ADD\")\n    envTable.overlaySpark.width = 16\n    envTable.overlaySpark.height = 36\n    envTable.overlaySpark.alpha = .9\n    envTable.overlaySpark.texture = [[Interface\\AddOns\\Plater\\images\\spark3]]\n    \n    envTable.topArrow = envTable.topArrow or Plater:CreateImage (unitFrame.healthBar)\n    envTable.topArrow:SetBlendMode (\"ADD\")\n    envTable.topArrow.width = scriptTable.config.arrowWidth\n    envTable.topArrow.height = scriptTable.config.arrowHeight\n    envTable.topArrow.alpha = envTable.ArrowAlpha\n    envTable.topArrow.texture = [[Interface\\BUTTONS\\Arrow-Down-Up]]\n    \n    --scale animation\n    envTable.smallScaleAnimation = envTable.smallScaleAnimation or Plater:CreateAnimationHub (unitFrame.healthBar)\n    Plater:CreateAnimation (envTable.smallScaleAnimation, \"SCALE\", 1, 0.075, 1, 1, 1.08, 1.08)\n    Plater:CreateAnimation (envTable.smallScaleAnimation, \"SCALE\", 2, 0.075, 1, 1, 0.95, 0.95)    \n    --envTable.smallScaleAnimation:Play() --envTable.smallScaleAnimation:Stop()\n    \n    --create a camera shake for the nameplate\n    envTable.FrameShake = Plater:CreateFrameShake (unitFrame, scriptTable.config.shakeDuration, scriptTable.config.shakeAmplitude, scriptTable.config.shakeFrequency, false, false, 0, 1, 0.05, 0.1, Plater.GetPoints (unitFrame))    \n    \n    --update the config for the skake here so it wont need a /reload\n    envTable.FrameShake.OriginalAmplitude = scriptTable.config.shakeAmplitude\n    envTable.FrameShake.OriginalDuration = scriptTable.config.shakeDuration\n    envTable.FrameShake.OriginalFrequency = scriptTable.config.shakeFrequency\nend\n\n\n\n\n\n\n\n",
      ["semver"] = "",
      ["Temp_Initialization"] = "function (scriptTable)\n    --insert code here\n    \nend\n\n\n",
    }, -- [18]
    {
      ["ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    --insert code here\n    \n    --check for marks\n    function  envTable.CheckMark (unitId, unitFrame)\n        if (not GetRaidTargetIndex(unitId)) then\n            if (scriptTable.config.onlyInCombat) then\n                if (not UnitAffectingCombat(unitId)) then\n                    return\n                end                \n            end\n            \n            SetRaidTarget(unitId, 8)\n        end       \n    end\nend\n\n\n--163520 - forsworn squad-leader\n--163618 - zolramus necromancer - The Necrotic Wake\n--164506 - anciet captain - theater of pain\n\n\n",
      ["OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    --insert code here\n    \nend\n\n\n",
      ["OptionsValues"] = {
      },
      ["Temp_OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    --insert code here\n    envTable.CheckMark (unitId, unitFrame)\nend\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n",
      ["ScriptType"] = 3,
      ["UpdateCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    --insert code here\n    envTable.CheckMark (unitId, unitFrame)\nend\n\n\n",
      ["Time"] = 1699197397,
      ["Temp_OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    --insert code here\n    \nend\n\n\n",
      ["url"] = "",
      ["Icon"] = "Interface\\Worldmap\\GlowSkull_64Grey",
      ["OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    --insert code here\n    envTable.CheckMark (unitId, unitFrame)\nend\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n",
      ["Enabled"] = false,
      ["Revision"] = 73,
      ["Options"] = {
        {
          ["Type"] = 5,
          ["Key"] = "option1",
          ["Value"] = "Auto set a raid target Skull on the unit.",
          ["Name"] = "Option 1",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_label",
          ["Desc"] = "",
        }, -- [1]
        {
          ["Type"] = 6,
          ["Key"] = "option2",
          ["Value"] = 0,
          ["Name"] = "Option 2",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [2]
        {
          ["Type"] = 4,
          ["Key"] = "onlyInCombat",
          ["Value"] = false,
          ["Name"] = "Only in Combat",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_bool",
          ["Desc"] = "Set the mark only if the unit is in combat.",
        }, -- [3]
      },
      ["Name"] = "Auto Set Skull",
      ["Prio"] = 99,
      ["Author"] = "Aelerolor-Torghast",
      ["Initialization"] = "function (scriptTable)\n    --insert code here\n    \nend\n\n\n",
      ["Desc"] = "Auto set skull marker",
      ["SpellIds"] = {
      },
      ["Temp_UpdateCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    --insert code here\n    envTable.CheckMark (unitId, unitFrame)\nend\n\n\n",
      ["version"] = -1,
      ["PlaterCore"] = 1,
      ["NpcNames"] = {
      },
      ["Temp_ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    --insert code here\n    \n    --check for marks\n    function  envTable.CheckMark (unitId, unitFrame)\n        if (not GetRaidTargetIndex(unitId)) then\n            if (scriptTable.config.onlyInCombat) then\n                if (not UnitAffectingCombat(unitId)) then\n                    return\n                end                \n            end\n            \n            SetRaidTarget(unitId, 8)\n        end       \n    end\nend\n\n\n--163520 - forsworn squad-leader\n--163618 - zolramus necromancer - The Necrotic Wake\n--164506 - anciet captain - theater of pain\n\n\n",
      ["semver"] = "",
      ["Temp_Initialization"] = "function (scriptTable)\n    --insert code here\n    \nend\n\n\n",
    }, -- [19]
    {
      ["ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    --insert code here\n    \n    envTable.npcInfo = {\n        [164427] = {secondCastBar = true, timer = 20, timerId = 321247, altCastId = \"1\", name = \"Boom!\"}, --reanimated warrior - plaguefall\n        \n        [164414] = {secondCastBar = true, timer = 20, timerId = 321247, altCastId = \"2\", name = \"Boom!\"}, --reanimated mage - plaguefall\n        \n        [164185] = {secondCastBar = true, timer = 20, timerId = 319941, altCastId = \"3\", remaining = 5, name = GetSpellInfo(319941)}, --Echelon - Halls of Atonement\n        \n        [164567] = {secondCastBar = true, altCastId = \"dromanswrath\", debuffTimer = 323059, name = GetSpellInfo(323059), spellIcon = 323059}, --Ingra Maloch -- tirna scythe\n        \n        [165408] = {secondCastBar = true, timer = 20, timerId = 322711, altCastId = \"4\", remaining = 5, name = GetSpellInfo(322711)}, --Halkias - Refracted Sinlight - Halls of Atonement\n        \n        \n        --[154564] = {secondCastBar = true, timerId = \"Test Bar\", altCastId = \"debugcast\", remaining = 5, name = GetSpellInfo(319941), spellIcon = 319941}, --debug \"Test (1)\" BW \"Test Bar\" DBM --DEBUG\n        --[154580] = {secondCastBar = true, altCastId = \"debugcast\", debuffTimer = 204242, name = GetSpellInfo(81297), spellIcon = 81297}, --debug \"Test (1)\" BW \"Test Bar\" DBM --DEBUG\n    }\n    \n    --set the castbar config\n    local config = {\n        iconTexture = \"\",\n        iconTexcoord = {0.1, 0.9, 0.1, 0.9},\n        iconAlpha = 1,\n        iconSize = 14,\n        \n        text = \"Boom!\",\n        textSize = 9,\n        \n        texture = [[Interface\\AddOns\\Plater\\images\\bar_background]],\n        color = \"silver\",\n        \n        isChanneling = false,\n        canInterrupt = false,\n        \n        height = 2,\n        width = Plater.db.profile.plate_config.enemynpc.health_incombat[1],\n        \n        spellNameAnchor = {side = 3, x = 0, y = -2},\n        timerAnchor = {side = 5, x = 0, y = -2},\n    }    \n    \n    function envTable.ShowAltCastBar(npcInfo, unitFrame, unitId, customTime, customStart)\n        --show the cast bar\n        if (npcInfo.timerId) then\n            local barObject = Plater.GetBossTimer(npcInfo.timerId)\n            if (barObject) then\n                if (npcInfo.remaining) then\n                    local timeLeft = barObject.timer + barObject.start - GetTime()\n                    if (timeLeft > npcInfo.remaining) then\n                        return\n                    end\n                end\n                \n                config.text = npcInfo.name\n                \n                if (npcInfo.spellIcon) then\n                    local _, _, iconTexture = GetSpellInfo(npcInfo.spellIcon)\n                    config.iconTexture = iconTexture\n                else\n                    config.iconTexture = \"\"\n                end\n                \n                Plater.SetAltCastBar(unitFrame.PlateFrame, config, barObject.timer, customStart or barObject.start, npcInfo.altCastId)\n            end\n        else\n            Plater.SetAltCastBar(unitFrame.PlateFrame, config, customTime or npcInfo.timer, customStart, npcInfo.altCastId)            \n        end\n        \n        DetailsFramework:TruncateText(unitFrame.castBar2.Text, unitFrame.castBar2:GetWidth() - 16)\n    end\nend",
      ["OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    --insert code here\n    Plater.ClearAltCastBar(unitFrame.PlateFrame)\nend",
      ["OptionsValues"] = {
      },
      ["Temp_OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    local npcInfo = envTable.npcInfo[envTable._NpcID]\n    \n    if (npcInfo and npcInfo.secondCastBar) then\n        if (npcInfo.debuffTimer) then\n            if (Plater.NameplateHasAura (unitFrame, npcInfo.debuffTimer)) then\n                \n                local name = npcInfo.name\n                local _, _, _, _, duration, expirationTime = AuraUtil.FindAuraByName(name, unitId, \"DEBUFF\")\n                \n                envTable.ShowAltCastBar(npcInfo, unitFrame, unitId, duration, expirationTime-duration)\n            else\n                if (unitFrame.castBar2:IsShown()) then\n                    local altCastId = Plater.GetAltCastBarAltId(unitFrame.PlateFrame)\n                    if (altCastId == npcInfo.altCastId) then\n                        Plater.ClearAltCastBar(unitFrame.PlateFrame)\n                    end                   \n                end                              \n            end\n        else\n            envTable.ShowAltCastBar(npcInfo, unitFrame, unitId)\n        end\n    end\nend\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n",
      ["ScriptType"] = 3,
      ["UpdateCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    local npcInfo = envTable.npcInfo[envTable._NpcID]\n    \n    if (npcInfo and npcInfo.secondCastBar) then\n        if (npcInfo.timerId) then\n            local barObject = Plater.GetBossTimer(npcInfo.timerId)\n            if (barObject) then\n                local altCastId = Plater.GetAltCastBarAltId(unitFrame.PlateFrame)\n                if (altCastId ~= npcInfo.altCastId or not unitFrame.castBar2:IsShown()) then\n                    envTable.ShowAltCastBar(npcInfo, unitFrame, unitId)\n                end\n            end \n            \n        elseif (npcInfo.debuffTimer) then\n            if (Plater.NameplateHasAura (unitFrame, npcInfo.debuffTimer)) then\n                \n                --get the debuff timeleft\n                local name = npcInfo.name\n                local _, _, _, _, duration, expirationTime = AuraUtil.FindAuraByName(name, unitId, \"DEBUFF\")\n                local startTime = expirationTime - duration\n                \n                if (not unitFrame.castBar2:IsShown() or unitFrame.castBar2.spellStartTime < startTime) then\n                    envTable.ShowAltCastBar(npcInfo, unitFrame, unitId, duration, startTime)\n                end\n                \n            else \n                if (unitFrame.castBar2:IsShown()) then\n                    local altCastId = Plater.GetAltCastBarAltId(unitFrame.PlateFrame)\n                    if (altCastId == npcInfo.altCastId) then\n                        Plater.ClearAltCastBar(unitFrame.PlateFrame)\n                    end                   \n                end                              \n            end\n        end\n    end\nend\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n",
      ["Time"] = 1674873417,
      ["Temp_OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    --insert code here\n    Plater.ClearAltCastBar(unitFrame.PlateFrame)\nend",
      ["url"] = "",
      ["Icon"] = "Interface\\AddOns\\Plater\\Images\\countdown_bar_icon",
      ["OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    local npcInfo = envTable.npcInfo[envTable._NpcID]\n    \n    if (npcInfo and npcInfo.secondCastBar) then\n        if (npcInfo.debuffTimer) then\n            if (Plater.NameplateHasAura (unitFrame, npcInfo.debuffTimer)) then\n                \n                local name = npcInfo.name\n                local _, _, _, _, duration, expirationTime = AuraUtil.FindAuraByName(name, unitId, \"DEBUFF\")\n                \n                envTable.ShowAltCastBar(npcInfo, unitFrame, unitId, duration, expirationTime-duration)\n            else\n                if (unitFrame.castBar2:IsShown()) then\n                    local altCastId = Plater.GetAltCastBarAltId(unitFrame.PlateFrame)\n                    if (altCastId == npcInfo.altCastId) then\n                        Plater.ClearAltCastBar(unitFrame.PlateFrame)\n                    end                   \n                end                              \n            end\n        else\n            envTable.ShowAltCastBar(npcInfo, unitFrame, unitId)\n        end\n    end\nend\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n",
      ["Enabled"] = true,
      ["Revision"] = 217,
      ["Options"] = {
      },
      ["Name"] = "Countdown",
      ["Prio"] = 99,
      ["Author"] = "Aelerolor-Torghast",
      ["Initialization"] = "function (scriptTable)\n    --insert code here\n    \nend\n\n\n",
      ["Desc"] = "Some units has special events without a clear way to show. This script adds a second cast bar to inform the user about it.",
      ["SpellIds"] = {
      },
      ["Temp_UpdateCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    local npcInfo = envTable.npcInfo[envTable._NpcID]\n    \n    if (npcInfo and npcInfo.secondCastBar) then\n        if (npcInfo.timerId) then\n            local barObject = Plater.GetBossTimer(npcInfo.timerId)\n            if (barObject) then\n                local altCastId = Plater.GetAltCastBarAltId(unitFrame.PlateFrame)\n                if (altCastId ~= npcInfo.altCastId or not unitFrame.castBar2:IsShown()) then\n                    envTable.ShowAltCastBar(npcInfo, unitFrame, unitId)\n                end\n            end \n            \n        elseif (npcInfo.debuffTimer) then\n            if (Plater.NameplateHasAura (unitFrame, npcInfo.debuffTimer)) then\n                \n                --get the debuff timeleft\n                local name = npcInfo.name\n                local _, _, _, _, duration, expirationTime = AuraUtil.FindAuraByName(name, unitId, \"DEBUFF\")\n                local startTime = expirationTime - duration\n                \n                if (not unitFrame.castBar2:IsShown() or unitFrame.castBar2.spellStartTime < startTime) then\n                    envTable.ShowAltCastBar(npcInfo, unitFrame, unitId, duration, startTime)\n                end\n                \n            else \n                if (unitFrame.castBar2:IsShown()) then\n                    local altCastId = Plater.GetAltCastBarAltId(unitFrame.PlateFrame)\n                    if (altCastId == npcInfo.altCastId) then\n                        Plater.ClearAltCastBar(unitFrame.PlateFrame)\n                    end                   \n                end                              \n            end\n        end\n    end\nend\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n",
      ["version"] = -1,
      ["PlaterCore"] = 1,
      ["NpcNames"] = {
      },
      ["Temp_ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    --insert code here\n    \n    envTable.npcInfo = {\n        [164427] = {secondCastBar = true, timer = 20, timerId = 321247, altCastId = \"1\", name = \"Boom!\"}, --reanimated warrior - plaguefall\n        \n        [164414] = {secondCastBar = true, timer = 20, timerId = 321247, altCastId = \"2\", name = \"Boom!\"}, --reanimated mage - plaguefall\n        \n        [164185] = {secondCastBar = true, timer = 20, timerId = 319941, altCastId = \"3\", remaining = 5, name = GetSpellInfo(319941)}, --Echelon - Halls of Atonement\n        \n        [164567] = {secondCastBar = true, altCastId = \"dromanswrath\", debuffTimer = 323059, name = GetSpellInfo(323059), spellIcon = 323059}, --Ingra Maloch -- tirna scythe\n        \n        [165408] = {secondCastBar = true, timer = 20, timerId = 322711, altCastId = \"4\", remaining = 5, name = GetSpellInfo(322711)}, --Halkias - Refracted Sinlight - Halls of Atonement\n        \n        \n        --[154564] = {secondCastBar = true, timerId = \"Test Bar\", altCastId = \"debugcast\", remaining = 5, name = GetSpellInfo(319941), spellIcon = 319941}, --debug \"Test (1)\" BW \"Test Bar\" DBM --DEBUG\n        --[154580] = {secondCastBar = true, altCastId = \"debugcast\", debuffTimer = 204242, name = GetSpellInfo(81297), spellIcon = 81297}, --debug \"Test (1)\" BW \"Test Bar\" DBM --DEBUG\n    }\n    \n    --set the castbar config\n    local config = {\n        iconTexture = \"\",\n        iconTexcoord = {0.1, 0.9, 0.1, 0.9},\n        iconAlpha = 1,\n        iconSize = 14,\n        \n        text = \"Boom!\",\n        textSize = 9,\n        \n        texture = [[Interface\\AddOns\\Plater\\images\\bar_background]],\n        color = \"silver\",\n        \n        isChanneling = false,\n        canInterrupt = false,\n        \n        height = 2,\n        width = Plater.db.profile.plate_config.enemynpc.health_incombat[1],\n        \n        spellNameAnchor = {side = 3, x = 0, y = -2},\n        timerAnchor = {side = 5, x = 0, y = -2},\n    }    \n    \n    function envTable.ShowAltCastBar(npcInfo, unitFrame, unitId, customTime, customStart)\n        --show the cast bar\n        if (npcInfo.timerId) then\n            local barObject = Plater.GetBossTimer(npcInfo.timerId)\n            if (barObject) then\n                if (npcInfo.remaining) then\n                    local timeLeft = barObject.timer + barObject.start - GetTime()\n                    if (timeLeft > npcInfo.remaining) then\n                        return\n                    end\n                end\n                \n                config.text = npcInfo.name\n                \n                if (npcInfo.spellIcon) then\n                    local _, _, iconTexture = GetSpellInfo(npcInfo.spellIcon)\n                    config.iconTexture = iconTexture\n                else\n                    config.iconTexture = \"\"\n                end\n                \n                Plater.SetAltCastBar(unitFrame.PlateFrame, config, barObject.timer, customStart or barObject.start, npcInfo.altCastId)\n            end\n        else\n            Plater.SetAltCastBar(unitFrame.PlateFrame, config, customTime or npcInfo.timer, customStart, npcInfo.altCastId)            \n        end\n        \n        DetailsFramework:TruncateText(unitFrame.castBar2.Text, unitFrame.castBar2:GetWidth() - 16)\n    end\nend",
      ["semver"] = "",
      ["Temp_Initialization"] = "function (scriptTable)\n    --insert code here\n    \nend\n\n\n",
    }, -- [20]
    {
      ["ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    envTable.EnergyAmount = Plater:CreateLabel (unitFrame, \"\", 16, \"silver\");\n    envTable.EnergyAmount:SetPoint (\"bottom\", unitFrame, \"top\", 0, 18);    \n    \n    envTable.EnergyAmount.fontsize = scriptTable.config.fontSize\n    envTable.EnergyAmount.fontcolor = scriptTable.config.fontColor\n    envTable.EnergyAmount.outline = scriptTable.config.outline\n    \n    \nend\n\n--[=[\n\n164406 = Shriekwing\n164407 = Sludgefist\n162100 = kryxis the voracious\n162099 = general kaal - sanguine depths\n162329 = Xav the Unfallen - threater of pain\n--]=]",
      ["OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    envTable.EnergyAmount:Hide()\nend\n\n\n",
      ["OptionsValues"] = {
      },
      ["Temp_OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    envTable.EnergyAmount:Show()\nend\n\n\n",
      ["ScriptType"] = 3,
      ["UpdateCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    local currentPower = UnitPower(unitId)\n    \n    if (currentPower and currentPower > 0) then\n        local maxPower = UnitPowerMax (unitId)\n        local percent = floor (currentPower / maxPower * 100)\n        \n        envTable.EnergyAmount.text = \"\" .. percent;\n        \n        if (scriptTable.config.showLater) then\n            local alpha = (percent -80) * 5\n            alpha = alpha / 100\n            alpha = max(0, alpha)\n            envTable.EnergyAmount:SetAlpha(alpha)\n            \n        else\n            envTable.EnergyAmount:SetAlpha(1.0)\n        end\n        \n        \n    else\n        envTable.EnergyAmount.text = \"\"\n    end\nend\n\n\n\n\n\n\n\n\n",
      ["Time"] = 1674875573,
      ["Temp_OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    envTable.EnergyAmount:Hide()\nend\n\n\n",
      ["url"] = "",
      ["Icon"] = 136048,
      ["OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    envTable.EnergyAmount:Show()\nend\n\n\n",
      ["Enabled"] = true,
      ["Revision"] = 238,
      ["Options"] = {
        {
          ["Type"] = 6,
          ["Key"] = "option1",
          ["Value"] = 0,
          ["Name"] = "Option 1",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [1]
        {
          ["Type"] = 5,
          ["Key"] = "option3",
          ["Value"] = "Show the power of the unit above the nameplate.",
          ["Name"] = "script desc",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_label",
          ["Desc"] = "",
        }, -- [2]
        {
          ["Type"] = 5,
          ["Key"] = "option3",
          ["Value"] = "Add the unit name or unitId in the \"Add Trigger\" field and press \"Add\".",
          ["Name"] = "add trigger",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_label",
          ["Desc"] = "",
        }, -- [3]
        {
          ["Type"] = 6,
          ["Key"] = "option2",
          ["Value"] = 0,
          ["Name"] = "Option 2",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [4]
        {
          ["Type"] = 4,
          ["Key"] = "showLater",
          ["Value"] = true,
          ["Name"] = "Show at 80% of Energy",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_bool",
          ["Desc"] = "If enabled, the energy won't start showing until the unit has 80% energy.",
        }, -- [5]
        {
          ["Type"] = 6,
          ["Key"] = "option2",
          ["Value"] = 0,
          ["Name"] = "Option 2",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [6]
        {
          ["Type"] = 2,
          ["Max"] = 32,
          ["Desc"] = "Text size.",
          ["Min"] = 8,
          ["Key"] = "fontSize",
          ["Value"] = 16,
          ["Fraction"] = false,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Text Size",
        }, -- [7]
        {
          ["Type"] = 1,
          ["Key"] = "fontColor",
          ["Value"] = {
            0.80392156862745, -- [1]
            0.80392156862745, -- [2]
            0.80392156862745, -- [3]
            1, -- [4]
          },
          ["Name"] = "Font Color",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
          ["Desc"] = "Color of the text.",
        }, -- [8]
        {
          ["Type"] = 4,
          ["Key"] = "outline",
          ["Value"] = true,
          ["Name"] = "Enable Text Outline",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_bool",
          ["Desc"] = "If enabled, the text uses outline.",
        }, -- [9]
      },
      ["Name"] = "Unit - Show Energy [Plater]",
      ["Prio"] = 99,
      ["Author"] = "Celian-Sylvanas",
      ["Initialization"] = "function (scriptTable)\n    --insert code here\n    \nend\n\n\n",
      ["Desc"] = "Show the energy amount above the nameplate.",
      ["SpellIds"] = {
      },
      ["Temp_UpdateCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    local currentPower = UnitPower(unitId)\n    \n    if (currentPower and currentPower > 0) then\n        local maxPower = UnitPowerMax (unitId)\n        local percent = floor (currentPower / maxPower * 100)\n        \n        envTable.EnergyAmount.text = \"\" .. percent;\n        \n        if (scriptTable.config.showLater) then\n            local alpha = (percent -80) * 5\n            alpha = alpha / 100\n            alpha = max(0, alpha)\n            envTable.EnergyAmount:SetAlpha(alpha)\n            \n        else\n            envTable.EnergyAmount:SetAlpha(1.0)\n        end\n        \n        \n    else\n        envTable.EnergyAmount.text = \"\"\n    end\nend\n\n\n\n\n\n\n\n\n",
      ["version"] = -1,
      ["PlaterCore"] = 1,
      ["NpcNames"] = {
      },
      ["Temp_ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    envTable.EnergyAmount = Plater:CreateLabel (unitFrame, \"\", 16, \"silver\");\n    envTable.EnergyAmount:SetPoint (\"bottom\", unitFrame, \"top\", 0, 18);    \n    \n    envTable.EnergyAmount.fontsize = scriptTable.config.fontSize\n    envTable.EnergyAmount.fontcolor = scriptTable.config.fontColor\n    envTable.EnergyAmount.outline = scriptTable.config.outline\n    \n    \nend\n\n--[=[\n\n164406 = Shriekwing\n164407 = Sludgefist\n162100 = kryxis the voracious\n162099 = general kaal - sanguine depths\n162329 = Xav the Unfallen - threater of pain\n--]=]",
      ["semver"] = "",
      ["Temp_Initialization"] = "function (scriptTable)\n    --insert code here\n    \nend\n\n\n",
    }, -- [21]
    {
      ["ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    --insert code here\n    \n    if (not unitFrame.spitefulTexture) then\n        unitFrame.spitefulTexture = unitFrame.healthBar:CreateTexture(nil, \"overlay\", nil, 6)\n        unitFrame.spitefulTexture:SetPoint('right', 0, 0)\n        unitFrame.spitefulTexture:SetSize(27, 14)\n        unitFrame.spitefulTexture:SetColorTexture(.3, .3, 1, .7)\n        \n        unitFrame.spitefulText = unitFrame.healthBar:CreateFontString(nil, \"overlay\", \"GameFontNormal\", 6)\n        DetailsFramework:SetFontFace (unitFrame.spitefulText, \"2002\")\n        unitFrame.spitefulText:SetPoint(\"right\", unitFrame.spitefulTexture, \"right\", -2, 0)\n        unitFrame.spitefulText:SetJustifyH(\"right\")\n        \n        unitFrame.roleIcon = unitFrame:CreateTexture(nil, \"overlay\")\n        unitFrame.roleIcon:SetPoint(\"left\", unitFrame.healthBar, \"left\", 2, 0)\n        unitFrame.targetName = unitFrame:CreateFontString(nil, \"overlay\", \"GameFontNormal\")\n        unitFrame.targetName:SetPoint(\"left\", unitFrame.roleIcon, \"right\", 2, 0)\n        \n        unitFrame.spitefulTexture:Hide()\n        unitFrame.spitefulText:Hide()\n    end\n    \n    function envTable.UpdateSpitefulWidget(unitFrame)\n        \n        local r, g, b, a = Plater:ParseColors(scriptTable.config.bgColor)\n        unitFrame.spitefulTexture:SetColorTexture(r, g, b, a)\n        unitFrame.spitefulTexture:SetSize(scriptTable.config.bgWidth, unitFrame.healthBar:GetHeight())   \n        Plater:SetFontSize(unitFrame.spitefulText, scriptTable.config.textSize)\n        Plater:SetFontColor(unitFrame.spitefulText, scriptTable.config.textColor)\n        \n        local currentHealth = unitFrame.healthBar.CurrentHealth\n        local maxHealth = unitFrame.healthBar.CurrentHealthMax\n        \n        local healthPercent = currentHealth / maxHealth * 100\n        local timeToDie = format(\"%.1fs\", healthPercent / 8)\n        unitFrame.spitefulText:SetText(timeToDie)\n        \n        unitFrame.spitefulText:Show()\n        unitFrame.spitefulTexture:Show()\n        \n        if scriptTable.config.switchTargetName then\n            local plateFrame = unitFrame.PlateFrame\n            \n            local target = UnitName(unitFrame.namePlateUnitToken .. \"target\") or UnitName(unitFrame.namePlateUnitToken)\n            \n            if (target and target ~= \"\") then\n                local _, class = UnitClass(unitFrame.namePlateUnitToken .. \"target\")\n                if (class) then\n                    target = DetailsFramework:AddClassColorToText(target, class)\n                end\n                \n                local role = UnitGroupRolesAssigned(unitFrame.namePlateUnitToken .. \"target\")\n                if (role and role ~= \"NONE\") then\n                    target = DetailsFramework:AddRoleIconToText(target, role)\n                end\n                \n                plateFrame.namePlateUnitName = target\n                Plater.UpdateUnitName(plateFrame)\n            end\n        end\n        \n        if scriptTable.config.useTargetingColor then\n            local targeted = UnitIsUnit(unitFrame.namePlateUnitToken .. \"target\", \"player\")\n            if targeted then\n                Plater.SetNameplateColor (unitFrame, scriptTable.config.targetingColor)\n            else\n                Plater.RefreshNameplateColor(unitFrame)\n            end\n        end\n    end\nend",
      ["OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    --insert code here\n    if (unitFrame.spitefulTexture) then\n        unitFrame.spitefulText:Hide()\n        unitFrame.spitefulTexture:Hide()    \n        unitFrame.roleIcon:Hide()\n        unitFrame.targetName:Hide()\n    end\nend\n\n\n\n\n\n",
      ["OptionsValues"] = {
        ["targetingColor"] = {
          1, -- [1]
          0.8666667342186, -- [2]
          0.090196080505848, -- [3]
          1, -- [4]
        },
      },
      ["Temp_OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    --insert code here\n    envTable.UpdateSpitefulWidget(unitFrame)\nend\n\n\n",
      ["ScriptType"] = 3,
      ["UpdateCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    --insert code here\n    envTable.UpdateSpitefulWidget(unitFrame)\nend\n\n\n",
      ["Time"] = 1681735064,
      ["Temp_OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    --insert code here\n    if (unitFrame.spitefulTexture) then\n        unitFrame.spitefulText:Hide()\n        unitFrame.spitefulTexture:Hide()    \n        unitFrame.roleIcon:Hide()\n        unitFrame.targetName:Hide()\n    end\nend\n\n\n\n\n\n",
      ["url"] = "",
      ["Icon"] = 135945,
      ["OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    --insert code here\n    envTable.UpdateSpitefulWidget(unitFrame)\nend\n\n\n",
      ["Enabled"] = true,
      ["Revision"] = 204,
      ["Options"] = {
        {
          ["Type"] = 5,
          ["Key"] = "option12",
          ["Value"] = "Time to Die",
          ["Name"] = "Time to Die",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_label",
          ["Desc"] = "",
        }, -- [1]
        {
          ["Type"] = 2,
          ["Max"] = 50,
          ["Desc"] = "",
          ["Min"] = 10,
          ["Key"] = "bgWidth",
          ["Value"] = 27,
          ["Fraction"] = false,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Width",
        }, -- [2]
        {
          ["Type"] = 1,
          ["Key"] = "bgColor",
          ["Value"] = {
            0.50588235294118, -- [1]
            0.070588235294118, -- [2]
            1, -- [3]
            1, -- [4]
          },
          ["Name"] = "Background Color",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
          ["Desc"] = "",
        }, -- [3]
        {
          ["Type"] = 2,
          ["Max"] = 24,
          ["Desc"] = "",
          ["Min"] = 7,
          ["Key"] = "textSize",
          ["Value"] = 8,
          ["Fraction"] = false,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Text Size",
        }, -- [4]
        {
          ["Type"] = 1,
          ["Key"] = "textColor",
          ["Value"] = {
            1, -- [1]
            0.5843137254902, -- [2]
            0, -- [3]
            1, -- [4]
          },
          ["Name"] = "Text Color",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
          ["Desc"] = "",
        }, -- [5]
        {
          ["Type"] = 6,
          ["Key"] = "option7",
          ["Value"] = 0,
          ["Name"] = "Option 7",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [6]
        {
          ["Type"] = 5,
          ["Key"] = "option11",
          ["Value"] = "Targeting",
          ["Name"] = "Targeting",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_label",
          ["Desc"] = "",
        }, -- [7]
        {
          ["Type"] = 4,
          ["Key"] = "switchTargetName",
          ["Value"] = true,
          ["Name"] = "Show Target instead of Name",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_bool",
          ["Desc"] = "",
        }, -- [8]
        {
          ["Type"] = 4,
          ["Key"] = "useTargetingColor",
          ["Value"] = true,
          ["Name"] = "Change Color if targeting You",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_bool",
          ["Desc"] = "",
        }, -- [9]
        {
          ["Type"] = 1,
          ["Key"] = "targetingColor",
          ["Value"] = {
            0.070588235294118, -- [1]
            0.61960784313725, -- [2]
            0, -- [3]
            1, -- [4]
          },
          ["Name"] = "Color if targeting You",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
          ["Desc"] = "",
        }, -- [10]
        {
          ["Type"] = 6,
          ["Key"] = "option11",
          ["Value"] = 0,
          ["Name"] = "Option 11",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [11]
      },
      ["Name"] = "M+ Spiteful",
      ["Prio"] = 99,
      ["Author"] = "Symantec-Azralon",
      ["Initialization"] = "function (scriptTable)\n    --insert code here\n    \nend\n\n\n",
      ["Desc"] = "Time to die Spiteful affix",
      ["SpellIds"] = {
      },
      ["Temp_UpdateCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    --insert code here\n    envTable.UpdateSpitefulWidget(unitFrame)\nend\n\n\n",
      ["version"] = -1,
      ["PlaterCore"] = 1,
      ["NpcNames"] = {
        "174773", -- [1]
      },
      ["Temp_ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    --insert code here\n    \n    if (not unitFrame.spitefulTexture) then\n        unitFrame.spitefulTexture = unitFrame.healthBar:CreateTexture(nil, \"overlay\", nil, 6)\n        unitFrame.spitefulTexture:SetPoint('right', 0, 0)\n        unitFrame.spitefulTexture:SetSize(27, 14)\n        unitFrame.spitefulTexture:SetColorTexture(.3, .3, 1, .7)\n        \n        unitFrame.spitefulText = unitFrame.healthBar:CreateFontString(nil, \"overlay\", \"GameFontNormal\", 6)\n        DetailsFramework:SetFontFace (unitFrame.spitefulText, \"2002\")\n        unitFrame.spitefulText:SetPoint(\"right\", unitFrame.spitefulTexture, \"right\", -2, 0)\n        unitFrame.spitefulText:SetJustifyH(\"right\")\n        \n        unitFrame.roleIcon = unitFrame:CreateTexture(nil, \"overlay\")\n        unitFrame.roleIcon:SetPoint(\"left\", unitFrame.healthBar, \"left\", 2, 0)\n        unitFrame.targetName = unitFrame:CreateFontString(nil, \"overlay\", \"GameFontNormal\")\n        unitFrame.targetName:SetPoint(\"left\", unitFrame.roleIcon, \"right\", 2, 0)\n        \n        unitFrame.spitefulTexture:Hide()\n        unitFrame.spitefulText:Hide()\n    end\n    \n    function envTable.UpdateSpitefulWidget(unitFrame)\n        \n        local r, g, b, a = Plater:ParseColors(scriptTable.config.bgColor)\n        unitFrame.spitefulTexture:SetColorTexture(r, g, b, a)\n        unitFrame.spitefulTexture:SetSize(scriptTable.config.bgWidth, unitFrame.healthBar:GetHeight())   \n        Plater:SetFontSize(unitFrame.spitefulText, scriptTable.config.textSize)\n        Plater:SetFontColor(unitFrame.spitefulText, scriptTable.config.textColor)\n        \n        local currentHealth = unitFrame.healthBar.CurrentHealth\n        local maxHealth = unitFrame.healthBar.CurrentHealthMax\n        \n        local healthPercent = currentHealth / maxHealth * 100\n        local timeToDie = format(\"%.1fs\", healthPercent / 8)\n        unitFrame.spitefulText:SetText(timeToDie)\n        \n        unitFrame.spitefulText:Show()\n        unitFrame.spitefulTexture:Show()\n        \n        if scriptTable.config.switchTargetName then\n            local plateFrame = unitFrame.PlateFrame\n            \n            local target = UnitName(unitFrame.namePlateUnitToken .. \"target\") or UnitName(unitFrame.namePlateUnitToken)\n            \n            if (target and target ~= \"\") then\n                local _, class = UnitClass(unitFrame.namePlateUnitToken .. \"target\")\n                if (class) then\n                    target = DetailsFramework:AddClassColorToText(target, class)\n                end\n                \n                local role = UnitGroupRolesAssigned(unitFrame.namePlateUnitToken .. \"target\")\n                if (role and role ~= \"NONE\") then\n                    target = DetailsFramework:AddRoleIconToText(target, role)\n                end\n                \n                plateFrame.namePlateUnitName = target\n                Plater.UpdateUnitName(plateFrame)\n            end\n        end\n        \n        if scriptTable.config.useTargetingColor then\n            local targeted = UnitIsUnit(unitFrame.namePlateUnitToken .. \"target\", \"player\")\n            if targeted then\n                Plater.SetNameplateColor (unitFrame, scriptTable.config.targetingColor)\n            else\n                Plater.RefreshNameplateColor(unitFrame)\n            end\n        end\n    end\nend",
      ["semver"] = "",
      ["Temp_Initialization"] = "function (scriptTable)\n    --insert code here\n    \nend\n\n\n",
    }, -- [22]
    {
      ["ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    --castbar color (when can be interrupted)\n    envTable.CastbarColor = scriptTable.config.castbarColor\n    \n    --flash duration\n    local CONFIG_BACKGROUND_FLASH_DURATION = scriptTable.config.flashDuration\n    \n    --add this value to the cast bar height\n    envTable.CastBarHeightAdd = scriptTable.config.castBarHeight\n    \n    --create a fast flash above the cast bar\n    envTable.FullBarFlash = envTable.FullBarFlash or Plater.CreateFlash (self, 0.05, 1, \"white\")\n    \n    --create a camera shake for the nameplate\n    envTable.FrameShake = Plater:CreateFrameShake (unitFrame, scriptTable.config.shakeDuration, scriptTable.config.shakeAmplitude, scriptTable.config.shakeFrequency, false, false, 0, 1, 0.05, 0.1, Plater.GetPoints (unitFrame))\n    \n    --create a texture to use for a flash behind the cast bar\n    local backGroundFlashTexture = Plater:CreateImage (self, [[Interface\\ACHIEVEMENTFRAME\\UI-Achievement-Alert-Glow]], self:GetWidth()+60, self:GetHeight()+50, \"background\", {0, 400/512, 0, 170/256})\n    backGroundFlashTexture:SetBlendMode (\"ADD\", 7)\n    backGroundFlashTexture:SetDrawLayer(\"OVERLAY\", 7)\n    backGroundFlashTexture:SetPoint (\"center\", self, \"center\")\n    backGroundFlashTexture:Hide()\n    \n    --create the animation hub to hold the flash animation sequence\n    envTable.BackgroundFlash = envTable.BackgroundFlash or Plater:CreateAnimationHub (backGroundFlashTexture, \n        function()\n            backGroundFlashTexture:Show()\n        end,\n        function()\n            backGroundFlashTexture:Hide()\n        end\n    )\n    \n    --create the flash animation sequence\n    envTable.BackgroundFlash.fadeIn = envTable.BackgroundFlash.fadeIn or Plater:CreateAnimation (envTable.BackgroundFlash, \"ALPHA\", 1, CONFIG_BACKGROUND_FLASH_DURATION/2, 0, .75)\n    envTable.BackgroundFlash.fadeIn:SetDuration(CONFIG_BACKGROUND_FLASH_DURATION/2)\n    \n    envTable.BackgroundFlash.fadeOut = envTable.BackgroundFlash.fadeOut or Plater:CreateAnimation (envTable.BackgroundFlash, \"ALPHA\", 2, CONFIG_BACKGROUND_FLASH_DURATION/2, 1, 0)    \n    envTable.BackgroundFlash.fadeOut:SetDuration(CONFIG_BACKGROUND_FLASH_DURATION/2)\n    \n    --envTable.BackgroundFlash:Play() --envTable.BackgroundFlash:Stop()    \n    \n    \n    \n    \n    \nend\n\n\n\n\n",
      ["OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    unitFrame.castBar:SetHeight (envTable._DefaultHeight)\n    \n    --stop the camera shake\n    unitFrame:StopFrameShake (envTable.FrameShake)\n    \n    envTable.FullBarFlash:Stop()\n    envTable.BackgroundFlash:Stop()\n    \n    unitFrame.castBar.Spark:SetHeight(unitFrame.castBar:GetHeight())\n    \n    --check if there's a timer for this spell\n    local timer = scriptTable.config.timerList[tostring(envTable._SpellID)]\n    \n    if (timer) then\n        --insert code here\n        \n        --set the castbar config\n        local config = {\n            iconTexture = \"\",\n            iconTexcoord = {0.1, 0.9, 0.1, 0.9},\n            iconAlpha = 1,\n            iconSize = 14,\n            \n            text = \"Spikes Incoming!\",\n            textSize = 8,\n            \n            texture = [[Interface\\AddOns\\Plater\\images\\bar_background]],\n            color = {.6, .6, .6, 0.8},\n            \n            isChanneling = false,\n            canInterrupt = false,\n            \n            height = 5,\n            width = Plater.db.profile.plate_config.enemynpc.health_incombat[1],\n            \n            spellNameAnchor = {side = 3, x = 0, y = -2},\n            timerAnchor = {side = 5, x = 0, y = -2},\n        }\n        \n        Plater.SetAltCastBar(unitFrame.PlateFrame, config, timer, nil, nil)\n        local castBar2 = unitFrame.castBar2\n        castBar2.Text:ClearAllPoints()\n        castBar2.Text:SetPoint (\"topleft\", castBar2, \"bottomleft\", 0, 0)\n        castBar2.percentText:ClearAllPoints()\n        castBar2.percentText:SetPoint (\"topright\", castBar2, \"bottomright\", 0, 0)\n        Plater:SetFontSize(castBar2.percentText, 8)\n    end\n    \nend\n\n\n\n\n\n\n\n",
      ["OptionsValues"] = {
        ["timerList"] = {
        },
      },
      ["Temp_OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    --play flash animations\n    envTable.FullBarFlash:Play()\n    \n    --envTable.currentHeight = unitFrame.castBar:GetHeight()\n    \n    --restoring the default size (not required since it already restore in the hide script)\n    if (envTable.OriginalHeight) then\n        self:SetHeight (envTable.OriginalHeight)\n    end\n    \n    --increase the cast bar size\n    local height = self:GetHeight()\n    envTable.OriginalHeight = height\n    \n    self:SetHeight (height + envTable.CastBarHeightAdd)\n    \n    Plater.SetCastBarBorderColor (self, 1, .2, .2, 0.4)\n    \n    unitFrame:PlayFrameShake (envTable.FrameShake)\n    \n    Plater.SetCastBarColorForScript(self, scriptTable.config.useCastbarColor, scriptTable.config.castbarColor, envTable)\n    \n    envTable.BackgroundFlash:Play()\n    \n    unitFrame.castBar.Spark:SetHeight(unitFrame.castBar:GetHeight())\n    \nend\n\n\n\n\n\n\n\n\n\n\n",
      ["ScriptType"] = 2,
      ["UpdateCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \nend\n\n\n",
      ["Time"] = 1699197459,
      ["Temp_OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    unitFrame.castBar:SetHeight (envTable._DefaultHeight)\n    \n    --stop the camera shake\n    unitFrame:StopFrameShake (envTable.FrameShake)\n    \n    envTable.FullBarFlash:Stop()\n    envTable.BackgroundFlash:Stop()\n    \n    unitFrame.castBar.Spark:SetHeight(unitFrame.castBar:GetHeight())\n    \n    --check if there's a timer for this spell\n    local timer = scriptTable.config.timerList[tostring(envTable._SpellID)]\n    \n    if (timer) then\n        --insert code here\n        \n        --set the castbar config\n        local config = {\n            iconTexture = \"\",\n            iconTexcoord = {0.1, 0.9, 0.1, 0.9},\n            iconAlpha = 1,\n            iconSize = 14,\n            \n            text = \"Spikes Incoming!\",\n            textSize = 8,\n            \n            texture = [[Interface\\AddOns\\Plater\\images\\bar_background]],\n            color = {.6, .6, .6, 0.8},\n            \n            isChanneling = false,\n            canInterrupt = false,\n            \n            height = 5,\n            width = Plater.db.profile.plate_config.enemynpc.health_incombat[1],\n            \n            spellNameAnchor = {side = 3, x = 0, y = -2},\n            timerAnchor = {side = 5, x = 0, y = -2},\n        }\n        \n        Plater.SetAltCastBar(unitFrame.PlateFrame, config, timer, nil, nil)\n        local castBar2 = unitFrame.castBar2\n        castBar2.Text:ClearAllPoints()\n        castBar2.Text:SetPoint (\"topleft\", castBar2, \"bottomleft\", 0, 0)\n        castBar2.percentText:ClearAllPoints()\n        castBar2.percentText:SetPoint (\"topright\", castBar2, \"bottomright\", 0, 0)\n        Plater:SetFontSize(castBar2.percentText, 8)\n    end\n    \nend\n\n\n\n\n\n\n\n",
      ["url"] = "",
      ["Icon"] = "Interface\\AddOns\\Plater\\images\\cast_bar_orange",
      ["OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    --play flash animations\n    envTable.FullBarFlash:Play()\n    \n    --envTable.currentHeight = unitFrame.castBar:GetHeight()\n    \n    --restoring the default size (not required since it already restore in the hide script)\n    if (envTable.OriginalHeight) then\n        self:SetHeight (envTable.OriginalHeight)\n    end\n    \n    --increase the cast bar size\n    local height = self:GetHeight()\n    envTable.OriginalHeight = height\n    \n    self:SetHeight (height + envTable.CastBarHeightAdd)\n    \n    Plater.SetCastBarBorderColor (self, 1, .2, .2, 0.4)\n    \n    unitFrame:PlayFrameShake (envTable.FrameShake)\n    \n    Plater.SetCastBarColorForScript(self, scriptTable.config.useCastbarColor, scriptTable.config.castbarColor, envTable)\n    \n    envTable.BackgroundFlash:Play()\n    \n    unitFrame.castBar.Spark:SetHeight(unitFrame.castBar:GetHeight())\n    \nend\n\n\n\n\n\n\n\n\n\n\n",
      ["Enabled"] = false,
      ["Revision"] = 1220,
      ["Options"] = {
        {
          ["Type"] = 6,
          ["Key"] = "option1",
          ["Value"] = 0,
          ["Name"] = "Blank Line",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [1]
        {
          ["Type"] = 5,
          ["Key"] = "option2",
          ["Value"] = "Cast start animation settings",
          ["Name"] = "Option 2",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_label",
          ["Desc"] = "",
        }, -- [2]
        {
          ["Type"] = 6,
          ["Key"] = "option4",
          ["Value"] = 0,
          ["Name"] = "Blank Space",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [3]
        {
          ["Type"] = 4,
          ["Key"] = "useCastbarColor",
          ["Value"] = true,
          ["Name"] = "Cast Bar Color Enabled",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_bool",
          ["Desc"] = "When enabled, changes the cast bar color,",
        }, -- [4]
        {
          ["Type"] = 1,
          ["Key"] = "castbarColor",
          ["Value"] = {
            1, -- [1]
            0.43137254901961, -- [2]
            0, -- [3]
            1, -- [4]
          },
          ["Name"] = "Cast Bar Color",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
          ["Desc"] = "Color of the cast bar.",
        }, -- [5]
        {
          ["Type"] = 6,
          ["Key"] = "option7",
          ["Value"] = 0,
          ["Name"] = "Blank Line",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [6]
        {
          ["Type"] = 2,
          ["Max"] = 1,
          ["Desc"] = "When the cast starts it flash rapidly, adjust how fast it flashes. Value is milliseconds.",
          ["Min"] = 0.05,
          ["Key"] = "flashDuration",
          ["Value"] = 0.4,
          ["Fraction"] = true,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Flash Duration",
        }, -- [7]
        {
          ["Type"] = 2,
          ["Max"] = 10,
          ["Desc"] = "Increases the cast bar height by this value",
          ["Min"] = 0,
          ["Key"] = "castBarHeight",
          ["Value"] = 5,
          ["Fraction"] = false,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Cast Bar Height Mod",
        }, -- [8]
        {
          ["Type"] = 2,
          ["Max"] = 1,
          ["Desc"] = "When the cast starts, there's a small shake in the nameplate, this settings controls how long it takes.",
          ["Min"] = 0.1,
          ["Key"] = "shakeDuration",
          ["Value"] = 0.2,
          ["Fraction"] = true,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Shake Duration",
        }, -- [9]
        {
          ["Type"] = 2,
          ["Max"] = 100,
          ["Desc"] = "How strong is the shake.",
          ["Min"] = 2,
          ["Key"] = "shakeAmplitude",
          ["Value"] = 8,
          ["Fraction"] = false,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Shake Amplitude",
        }, -- [10]
        {
          ["Type"] = 2,
          ["Max"] = 80,
          ["Desc"] = "How fast the shake moves.",
          ["Min"] = 1,
          ["Key"] = "shakeFrequency",
          ["Value"] = 40,
          ["Fraction"] = false,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Shake Frequency",
        }, -- [11]
        {
          ["Type"] = 7,
          ["Key"] = "timerList",
          ["Value"] = {
          },
          ["Name"] = "Timer (Key is SpellId and Value is Time)",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_list",
          ["Desc"] = "Key is the spellId and value is the amount of time of the Timer",
        }, -- [12]
      },
      ["Name"] = "Cast - Alert + Timer [P]",
      ["Prio"] = 99,
      ["Author"] = "Tercioo-Sylvanas",
      ["Initialization"] = "function (scriptTable)\n    --insert code here\n    \nend",
      ["Desc"] = "Player an animation when the cast start. Start a timer when the cast finishes. Set the time in the options.",
      ["SpellIds"] = {
      },
      ["Temp_UpdateCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \nend\n\n\n",
      ["version"] = -1,
      ["PlaterCore"] = 1,
      ["NpcNames"] = {
      },
      ["Temp_ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    --castbar color (when can be interrupted)\n    envTable.CastbarColor = scriptTable.config.castbarColor\n    \n    --flash duration\n    local CONFIG_BACKGROUND_FLASH_DURATION = scriptTable.config.flashDuration\n    \n    --add this value to the cast bar height\n    envTable.CastBarHeightAdd = scriptTable.config.castBarHeight\n    \n    --create a fast flash above the cast bar\n    envTable.FullBarFlash = envTable.FullBarFlash or Plater.CreateFlash (self, 0.05, 1, \"white\")\n    \n    --create a camera shake for the nameplate\n    envTable.FrameShake = Plater:CreateFrameShake (unitFrame, scriptTable.config.shakeDuration, scriptTable.config.shakeAmplitude, scriptTable.config.shakeFrequency, false, false, 0, 1, 0.05, 0.1, Plater.GetPoints (unitFrame))\n    \n    --create a texture to use for a flash behind the cast bar\n    local backGroundFlashTexture = Plater:CreateImage (self, [[Interface\\ACHIEVEMENTFRAME\\UI-Achievement-Alert-Glow]], self:GetWidth()+60, self:GetHeight()+50, \"background\", {0, 400/512, 0, 170/256})\n    backGroundFlashTexture:SetBlendMode (\"ADD\", 7)\n    backGroundFlashTexture:SetDrawLayer(\"OVERLAY\", 7)\n    backGroundFlashTexture:SetPoint (\"center\", self, \"center\")\n    backGroundFlashTexture:Hide()\n    \n    --create the animation hub to hold the flash animation sequence\n    envTable.BackgroundFlash = envTable.BackgroundFlash or Plater:CreateAnimationHub (backGroundFlashTexture, \n        function()\n            backGroundFlashTexture:Show()\n        end,\n        function()\n            backGroundFlashTexture:Hide()\n        end\n    )\n    \n    --create the flash animation sequence\n    envTable.BackgroundFlash.fadeIn = envTable.BackgroundFlash.fadeIn or Plater:CreateAnimation (envTable.BackgroundFlash, \"ALPHA\", 1, CONFIG_BACKGROUND_FLASH_DURATION/2, 0, .75)\n    envTable.BackgroundFlash.fadeIn:SetDuration(CONFIG_BACKGROUND_FLASH_DURATION/2)\n    \n    envTable.BackgroundFlash.fadeOut = envTable.BackgroundFlash.fadeOut or Plater:CreateAnimation (envTable.BackgroundFlash, \"ALPHA\", 2, CONFIG_BACKGROUND_FLASH_DURATION/2, 1, 0)    \n    envTable.BackgroundFlash.fadeOut:SetDuration(CONFIG_BACKGROUND_FLASH_DURATION/2)\n    \n    --envTable.BackgroundFlash:Play() --envTable.BackgroundFlash:Stop()    \n    \n    \n    \n    \n    \nend\n\n\n\n\n",
      ["semver"] = "",
      ["Temp_Initialization"] = "function (scriptTable)\n    --insert code here\n    \nend",
    }, -- [23]
    {
      ["ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    --create a texture to use for a flash behind the cast bar\n    \n    if (not unitFrame.backGroundFlashTextureImpTarget) then\n        unitFrame.backGroundFlashTextureImpTarget =  Plater:CreateImage (self, [[Interface\\ACHIEVEMENTFRAME\\UI-Achievement-Alert-Glow]], self:GetWidth()+40, self:GetHeight()+20, \"background\", {0, 400/512, 0, 170/256})\n    end\n    \n    local backGroundFlashTexture = unitFrame.backGroundFlashTextureImpTarget\n    backGroundFlashTexture:SetBlendMode (\"ADD\")\n    backGroundFlashTexture:SetDrawLayer(\"OVERLAY\", 7)\n    backGroundFlashTexture:SetPoint (\"center\", self, \"center\")\n    backGroundFlashTexture:Hide()\n    \n    --create the animation hub to hold the flash animation sequence\n    envTable.BackgroundFlash = envTable.BackgroundFlash or Plater:CreateAnimationHub (backGroundFlashTexture, \n        function()\n            backGroundFlashTexture:Show()\n        end,\n        function()\n            backGroundFlashTexture:Hide()\n        end\n    )\n    \n    --create the flash animation sequence\n    local fadeIn = Plater:CreateAnimation (envTable.BackgroundFlash, \"ALPHA\", 1, scriptTable.config.flashDuration/2, 0, 1)\n    local fadeOut = Plater:CreateAnimation (envTable.BackgroundFlash, \"ALPHA\", 2, scriptTable.config.flashDuration/2, 1, 0)\n    \n    --create a camera shake for the nameplate\n    envTable.FrameShake = Plater:CreateFrameShake (unitFrame, scriptTable.config.shakeDuration, scriptTable.config.shakeAmplitude, scriptTable.config.shakeFrequency, false, false, 0, 1, 0.05, 0.1, Plater.GetPoints (unitFrame))\n    \n    --update the config for the flash here so it wont need a /reload\n    fadeIn:SetDuration (scriptTable.config.flashDuration/2)\n    fadeOut:SetDuration (scriptTable.config.flashDuration/2)\n    \n    --update the config for the skake here so it wont need a /reload\n    envTable.FrameShake.OriginalAmplitude = scriptTable.config.shakeAmplitude\n    envTable.FrameShake.OriginalDuration = scriptTable.config.shakeDuration\n    envTable.FrameShake.OriginalFrequency = scriptTable.config.shakeFrequency\n    \n    --create the target unit name box\n    if (not unitFrame.targetBox) then\n        unitFrame.targetBox = CreateFrame(\"frame\", unitFrame:GetName() .. \"ScriptImportantTarget\", unitFrame, \"BackdropTemplate\")\n        unitFrame.targetBox:SetSize(80, 20)\n        unitFrame.targetBox:SetFrameStrata(\"TOOLTIP\")\n        unitFrame.targetBox:Hide()\n        unitFrame.targetBox:SetPoint(\"left\", unitFrame, \"right\", 0, 0)\n        \n        unitFrame.targetBox:SetBackdrop({edgeFile = [[Interface\\Buttons\\WHITE8X8]], edgeSize = 1, bgFile = [[Interface\\AddOns\\Details\\images\\background]], tile = true, tileSize = 16})\n        unitFrame.targetBox:SetBackdropColor(.2, .2, .2, .8)\n        unitFrame.targetBox:SetBackdropBorderColor(0, 0, 0, 1)\n        \n        unitFrame.targetBoxName = unitFrame.targetBox:CreateFontString(nil, \"artwork\", \"GameFontNormal\")\n        unitFrame.targetBoxName:SetPoint(\"center\")\n    end\n    \n    function envTable.UpdateTargetBox(unitFrame, unitId)\n        local targetUnitId = unitId .. \"target\"\n        local unitName = UnitName(targetUnitId)\n        \n        if (unitName) then\n            if (scriptTable.config.colorByClass) then\n                Plater:SetFontColor(unitFrame.targetBoxName, \"white\")\n                unitName = Plater.SetTextColorByClass(targetUnitId, unitName)\n            else\n                Plater:SetFontColor(unitFrame.targetBoxName, scriptTable.config.textColor)\n            end\n            \n            unitFrame.targetBoxName:SetText(unitName)\n            Plater:SetFontSize(unitFrame.targetBoxName, scriptTable.config.targetNameSize)\n            unitFrame.targetBox:SetBackdropColor(Plater:ParseColors(scriptTable.config.targetBgColor))\n            unitFrame.targetBox:SetBackdropBorderColor(Plater:ParseColors(scriptTable.config.targetBgBorderColor))\n            unitFrame.targetBox:Show()\n            \n            unitFrame.targetBox:SetWidth(scriptTable.config.targetFrameWidth)\n            unitFrame.targetBox:SetHeight(scriptTable.config.targetFrameHeight)\n            \n            if (not Plater.HasDotAnimationPlaying(unitFrame.targetBox)) then\n                envTable.dotAnimation = Plater.PlayDotAnimation(unitFrame.targetBox, 5, scriptTable.config.dotColor, scriptTable.config.xOffset, scriptTable.config.yOffset)\n            end\n            \n            unitFrame.backGroundFlashTextureImpTarget:SetVertexColor(Plater:ParseColors(scriptTable.config.flashColor))\n            \n            return true\n            \n        end\n    end\n    \nend",
      ["OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    Plater.StopDotAnimation(unitFrame.targetBox, envTable.dotAnimation)    \n    \n    envTable.BackgroundFlash:Stop()\n    \n    unitFrame:StopFrameShake (envTable.FrameShake)    \n    \n    unitFrame.targetBox:Hide()\nend\n\n\n",
      ["OptionsValues"] = {
      },
      ["Temp_OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    if (envTable.UpdateTargetBox(unitFrame, unitId)) then\n        \n        envTable.BackgroundFlash:Play()\n        \n        Plater.FlashNameplateBorder (unitFrame, 0.05)   \n        Plater.FlashNameplateBody (unitFrame, \"\", 0.075)\n        \n        unitFrame:PlayFrameShake (envTable.FrameShake)\n        \n        if (envTable._CanInterrupt) then\n            if (scriptTable.config.useCastbarColor) then\n                self:SetStatusBarColor (Plater:ParseColors (scriptTable.config.castBarColor))\n            end\n        end\n        \n    end\n    \nend\n\n\n\n\n\n\n",
      ["ScriptType"] = 2,
      ["UpdateCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    envTable.UpdateTargetBox(unitFrame, unitId) \n    \nend\n\n\n",
      ["Time"] = 1672802480,
      ["Temp_OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    Plater.StopDotAnimation(unitFrame.targetBox, envTable.dotAnimation)    \n    \n    envTable.BackgroundFlash:Stop()\n    \n    unitFrame:StopFrameShake (envTable.FrameShake)    \n    \n    unitFrame.targetBox:Hide()\nend\n\n\n",
      ["url"] = "",
      ["Icon"] = "Interface\\AddOns\\Plater\\images\\cast_bar_target",
      ["OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    if (envTable.UpdateTargetBox(unitFrame, unitId)) then\n        \n        envTable.BackgroundFlash:Play()\n        \n        Plater.FlashNameplateBorder (unitFrame, 0.05)   \n        Plater.FlashNameplateBody (unitFrame, \"\", 0.075)\n        \n        unitFrame:PlayFrameShake (envTable.FrameShake)\n        \n        if (envTable._CanInterrupt) then\n            if (scriptTable.config.useCastbarColor) then\n                self:SetStatusBarColor (Plater:ParseColors (scriptTable.config.castBarColor))\n            end\n        end\n        \n    end\n    \nend\n\n\n\n\n\n\n",
      ["Enabled"] = false,
      ["Revision"] = 883,
      ["Options"] = {
        {
          ["Type"] = 6,
          ["Key"] = "option1",
          ["Value"] = 0,
          ["Name"] = "Option 1",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [1]
        {
          ["Type"] = 5,
          ["Key"] = "option2",
          ["Value"] = "Shows the target name in a separate box",
          ["Name"] = "Option 2",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_label",
          ["Desc"] = "",
        }, -- [2]
        {
          ["Type"] = 5,
          ["Key"] = "option2",
          ["Value"] = "Enter the spell name or spellID of the Spell in the Add Trigger box and hit \"Add\".",
          ["Name"] = "Option 2",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_label",
          ["Desc"] = "",
        }, -- [3]
        {
          ["Type"] = 6,
          ["Key"] = "option4",
          ["Value"] = 0,
          ["Name"] = "Option 4",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [4]
        {
          ["Type"] = 5,
          ["Key"] = "option2",
          ["Value"] = "Flash:",
          ["Name"] = "Flash",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_label",
          ["Desc"] = "",
        }, -- [5]
        {
          ["Type"] = 2,
          ["Max"] = 1.2,
          ["Desc"] = "How long is the flash played when the cast starts.",
          ["Min"] = 0.1,
          ["Key"] = "flashDuration",
          ["Value"] = 0.8,
          ["Fraction"] = true,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Flash Duration",
        }, -- [6]
        {
          ["Type"] = 1,
          ["Key"] = "flashColor",
          ["Value"] = {
            1, -- [1]
            1, -- [2]
            1, -- [3]
            1, -- [4]
          },
          ["Name"] = "Flash Color",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
          ["Desc"] = "Color of the Flash",
        }, -- [7]
        {
          ["Type"] = 6,
          ["Key"] = "option7",
          ["Value"] = 0,
          ["Name"] = "Option 7",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [8]
        {
          ["Type"] = 5,
          ["Key"] = "option2",
          ["Value"] = "Shake:",
          ["Name"] = "Shake",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_label",
          ["Desc"] = "",
        }, -- [9]
        {
          ["Type"] = 2,
          ["Max"] = 0.5,
          ["Desc"] = "When the cast starts, there's a small shake in the nameplate, this settings controls how long it takes.",
          ["Min"] = 0.1,
          ["Key"] = "shakeDuration",
          ["Value"] = 0.2,
          ["Fraction"] = true,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Shake Duration",
        }, -- [10]
        {
          ["Type"] = 2,
          ["Max"] = 10,
          ["Desc"] = "How strong is the shake.",
          ["Min"] = 1,
          ["Key"] = "shakeAmplitude",
          ["Value"] = 5,
          ["Fraction"] = false,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Shake Amplitude",
        }, -- [11]
        {
          ["Type"] = 2,
          ["Max"] = 80,
          ["Desc"] = "How fast the shake moves.",
          ["Min"] = 1,
          ["Key"] = "shakeFrequency",
          ["Value"] = 40,
          ["Fraction"] = false,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Shake Frequency",
        }, -- [12]
        {
          ["Type"] = 6,
          ["Key"] = "option13",
          ["Value"] = 0,
          ["Name"] = "Option 13",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [13]
        {
          ["Type"] = 5,
          ["Key"] = "option14",
          ["Value"] = "Dot Animation:",
          ["Name"] = "Dot Animation",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_label",
          ["Desc"] = "",
        }, -- [14]
        {
          ["Type"] = 1,
          ["Key"] = "dotColor",
          ["Value"] = {
            0.56470588235294, -- [1]
            0.56470588235294, -- [2]
            0.56470588235294, -- [3]
            1, -- [4]
          },
          ["Name"] = "Dot Color",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
          ["Desc"] = "Adjust the color of the dots around the nameplate",
        }, -- [15]
        {
          ["Type"] = 2,
          ["Max"] = 20,
          ["Desc"] = "Adjust the width of the dots to better fit in your nameplate.",
          ["Min"] = -10,
          ["Key"] = "xOffset",
          ["Value"] = 8,
          ["Fraction"] = false,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Dot X Offset",
        }, -- [16]
        {
          ["Type"] = 2,
          ["Max"] = 10,
          ["Desc"] = "Adjust the height of the dots to better fit in your nameplate.",
          ["Min"] = -10,
          ["Key"] = "yOffset",
          ["Value"] = 3,
          ["Fraction"] = false,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Dot Y Offset",
        }, -- [17]
        {
          ["Type"] = 6,
          ["Key"] = "option18",
          ["Value"] = 0,
          ["Name"] = "blank",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [18]
        {
          ["Type"] = 6,
          ["Key"] = "option18",
          ["Value"] = 0,
          ["Name"] = "blank",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [19]
        {
          ["Type"] = 6,
          ["Key"] = "option18",
          ["Value"] = 0,
          ["Name"] = "blank",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [20]
        {
          ["Type"] = 6,
          ["Key"] = "option18",
          ["Value"] = 0,
          ["Name"] = "blank",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [21]
        {
          ["Type"] = 6,
          ["Key"] = "option18",
          ["Value"] = 0,
          ["Name"] = "blank",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [22]
        {
          ["Type"] = 6,
          ["Key"] = "option18",
          ["Value"] = 0,
          ["Name"] = "blank",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [23]
        {
          ["Type"] = 5,
          ["Key"] = "option19",
          ["Value"] = "Cast Bar",
          ["Name"] = "Option 19",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_label",
          ["Desc"] = "",
        }, -- [24]
        {
          ["Type"] = 4,
          ["Key"] = "useCastbarColor",
          ["Value"] = true,
          ["Name"] = "Use Cast Bar Color",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_bool",
          ["Desc"] = "Use cast bar color.",
        }, -- [25]
        {
          ["Type"] = 1,
          ["Key"] = "castBarColor",
          ["Value"] = {
            0.41176470588235, -- [1]
            1, -- [2]
            0, -- [3]
            1, -- [4]
          },
          ["Name"] = "Cast Bar Color",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
          ["Desc"] = "Cast bar color.",
        }, -- [26]
        {
          ["Type"] = 6,
          ["Key"] = "option27",
          ["Value"] = 0,
          ["Name"] = "Option 27",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [27]
        {
          ["Type"] = 5,
          ["Key"] = "option28",
          ["Value"] = "Target Options",
          ["Name"] = "Option 28",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_label",
          ["Desc"] = "",
        }, -- [28]
        {
          ["Type"] = 2,
          ["Max"] = 32,
          ["Desc"] = "",
          ["Min"] = 8,
          ["Key"] = "targetNameSize",
          ["Value"] = 14,
          ["Fraction"] = false,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Text Size",
        }, -- [29]
        {
          ["Type"] = 4,
          ["Key"] = "colorByClass",
          ["Value"] = true,
          ["Name"] = "Use Class Color",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_bool",
          ["Desc"] = "",
        }, -- [30]
        {
          ["Type"] = 1,
          ["Key"] = "textColor",
          ["Value"] = {
            1, -- [1]
            1, -- [2]
            1, -- [3]
            1, -- [4]
          },
          ["Name"] = "Text Color",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
          ["Desc"] = "",
        }, -- [31]
        {
          ["Type"] = 1,
          ["Key"] = "targetBgColor",
          ["Value"] = {
            0, -- [1]
            0, -- [2]
            0, -- [3]
            0.98467203229666, -- [4]
          },
          ["Name"] = "Background Color",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
          ["Desc"] = "",
        }, -- [32]
        {
          ["Type"] = 1,
          ["Key"] = "targetBgBorderColor",
          ["Value"] = {
            0, -- [1]
            0, -- [2]
            0, -- [3]
            1, -- [4]
          },
          ["Name"] = "Border Color",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
          ["Desc"] = "",
        }, -- [33]
        {
          ["Type"] = 2,
          ["Max"] = 160,
          ["Desc"] = "",
          ["Min"] = 30,
          ["Key"] = "targetFrameWidth",
          ["Value"] = 90,
          ["Fraction"] = false,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Frame Width",
        }, -- [34]
        {
          ["Type"] = 2,
          ["Max"] = 32,
          ["Desc"] = "",
          ["Min"] = 8,
          ["Key"] = "targetFrameHeight",
          ["Value"] = 20,
          ["Fraction"] = false,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Frame Height",
        }, -- [35]
      },
      ["Name"] = "Cast - Important Target [P]",
      ["Prio"] = 99,
      ["Author"] = "Bombad o-Azralon",
      ["Initialization"] = "function (scriptTable)\n    --insert code here\n    \nend\n\n\n",
      ["Desc"] = "Highlight the target name",
      ["SpellIds"] = {
      },
      ["Temp_UpdateCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    envTable.UpdateTargetBox(unitFrame, unitId) \n    \nend\n\n\n",
      ["version"] = -1,
      ["PlaterCore"] = 1,
      ["NpcNames"] = {
      },
      ["Temp_ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    --create a texture to use for a flash behind the cast bar\n    \n    if (not unitFrame.backGroundFlashTextureImpTarget) then\n        unitFrame.backGroundFlashTextureImpTarget =  Plater:CreateImage (self, [[Interface\\ACHIEVEMENTFRAME\\UI-Achievement-Alert-Glow]], self:GetWidth()+40, self:GetHeight()+20, \"background\", {0, 400/512, 0, 170/256})\n    end\n    \n    local backGroundFlashTexture = unitFrame.backGroundFlashTextureImpTarget\n    backGroundFlashTexture:SetBlendMode (\"ADD\")\n    backGroundFlashTexture:SetDrawLayer(\"OVERLAY\", 7)\n    backGroundFlashTexture:SetPoint (\"center\", self, \"center\")\n    backGroundFlashTexture:Hide()\n    \n    --create the animation hub to hold the flash animation sequence\n    envTable.BackgroundFlash = envTable.BackgroundFlash or Plater:CreateAnimationHub (backGroundFlashTexture, \n        function()\n            backGroundFlashTexture:Show()\n        end,\n        function()\n            backGroundFlashTexture:Hide()\n        end\n    )\n    \n    --create the flash animation sequence\n    local fadeIn = Plater:CreateAnimation (envTable.BackgroundFlash, \"ALPHA\", 1, scriptTable.config.flashDuration/2, 0, 1)\n    local fadeOut = Plater:CreateAnimation (envTable.BackgroundFlash, \"ALPHA\", 2, scriptTable.config.flashDuration/2, 1, 0)\n    \n    --create a camera shake for the nameplate\n    envTable.FrameShake = Plater:CreateFrameShake (unitFrame, scriptTable.config.shakeDuration, scriptTable.config.shakeAmplitude, scriptTable.config.shakeFrequency, false, false, 0, 1, 0.05, 0.1, Plater.GetPoints (unitFrame))\n    \n    --update the config for the flash here so it wont need a /reload\n    fadeIn:SetDuration (scriptTable.config.flashDuration/2)\n    fadeOut:SetDuration (scriptTable.config.flashDuration/2)\n    \n    --update the config for the skake here so it wont need a /reload\n    envTable.FrameShake.OriginalAmplitude = scriptTable.config.shakeAmplitude\n    envTable.FrameShake.OriginalDuration = scriptTable.config.shakeDuration\n    envTable.FrameShake.OriginalFrequency = scriptTable.config.shakeFrequency\n    \n    --create the target unit name box\n    if (not unitFrame.targetBox) then\n        unitFrame.targetBox = CreateFrame(\"frame\", unitFrame:GetName() .. \"ScriptImportantTarget\", unitFrame, \"BackdropTemplate\")\n        unitFrame.targetBox:SetSize(80, 20)\n        unitFrame.targetBox:SetFrameStrata(\"TOOLTIP\")\n        unitFrame.targetBox:Hide()\n        unitFrame.targetBox:SetPoint(\"left\", unitFrame, \"right\", 0, 0)\n        \n        unitFrame.targetBox:SetBackdrop({edgeFile = [[Interface\\Buttons\\WHITE8X8]], edgeSize = 1, bgFile = [[Interface\\AddOns\\Details\\images\\background]], tile = true, tileSize = 16})\n        unitFrame.targetBox:SetBackdropColor(.2, .2, .2, .8)\n        unitFrame.targetBox:SetBackdropBorderColor(0, 0, 0, 1)\n        \n        unitFrame.targetBoxName = unitFrame.targetBox:CreateFontString(nil, \"artwork\", \"GameFontNormal\")\n        unitFrame.targetBoxName:SetPoint(\"center\")\n    end\n    \n    function envTable.UpdateTargetBox(unitFrame, unitId)\n        local targetUnitId = unitId .. \"target\"\n        local unitName = UnitName(targetUnitId)\n        \n        if (unitName) then\n            if (scriptTable.config.colorByClass) then\n                Plater:SetFontColor(unitFrame.targetBoxName, \"white\")\n                unitName = Plater.SetTextColorByClass(targetUnitId, unitName)\n            else\n                Plater:SetFontColor(unitFrame.targetBoxName, scriptTable.config.textColor)\n            end\n            \n            unitFrame.targetBoxName:SetText(unitName)\n            Plater:SetFontSize(unitFrame.targetBoxName, scriptTable.config.targetNameSize)\n            unitFrame.targetBox:SetBackdropColor(Plater:ParseColors(scriptTable.config.targetBgColor))\n            unitFrame.targetBox:SetBackdropBorderColor(Plater:ParseColors(scriptTable.config.targetBgBorderColor))\n            unitFrame.targetBox:Show()\n            \n            unitFrame.targetBox:SetWidth(scriptTable.config.targetFrameWidth)\n            unitFrame.targetBox:SetHeight(scriptTable.config.targetFrameHeight)\n            \n            if (not Plater.HasDotAnimationPlaying(unitFrame.targetBox)) then\n                envTable.dotAnimation = Plater.PlayDotAnimation(unitFrame.targetBox, 5, scriptTable.config.dotColor, scriptTable.config.xOffset, scriptTable.config.yOffset)\n            end\n            \n            unitFrame.backGroundFlashTextureImpTarget:SetVertexColor(Plater:ParseColors(scriptTable.config.flashColor))\n            \n            return true\n            \n        end\n    end\n    \nend",
      ["semver"] = "",
      ["Temp_Initialization"] = "function (scriptTable)\n    --insert code here\n    \nend\n\n\n",
    }, -- [24]
    {
      ["ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    --insert code here\n    \nend\n\n\n",
      ["OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    --insert code here\n    local unitPowerBar = unitFrame.powerBar\n    unitPowerBar:Hide()\nend\n\n\n",
      ["OptionsValues"] = {
      },
      ["Temp_OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    --insert code here\n    \nend\n\n\n",
      ["ScriptType"] = 1,
      ["UpdateCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    if (WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE) then\n        return \n    end\n    \n    local continuationToken\n    local slots\n    local foundAura = false\n    \n    repeat    \n        slots = { UnitAuraSlots(unitId, \"HELPFUL\", BUFF_MAX_DISPLAY, continuationToken) }\n        continuationToken = slots[1]\n        numSlots = #slots\n        \n        for i = 2, numSlots do\n            local slot = slots[i]\n            local name, texture, count, actualAuraType, duration, expirationTime, caster, canStealOrPurge, nameplateShowPersonal, spellId, canApplyAura, isBossDebuff, isCastByPlayer, nameplateShowAll, timeMod, auraAmount = UnitAuraBySlot(unitId, slot) \n            \n            if (spellId == envTable._SpellID) then --need to get the trigger spellId\n                --Ablative Shield\n                local unitPowerBar = unitFrame.powerBar\n                if (not unitPowerBar:IsShown()) then\n                    unitPowerBar:SetUnit(unitId)\n                end\n                \n                foundAura = true\n                return\n            end\n        end\n        \n    until continuationToken == nil\n    \n    if (not foundAura) then\n        local unitPowerBar = unitFrame.powerBar\n        if (unitPowerBar:IsShown()) then\n            unitPowerBar:Hide()\n        end\n    end\nend",
      ["Time"] = 1699197391,
      ["Temp_OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    --insert code here\n    local unitPowerBar = unitFrame.powerBar\n    unitPowerBar:Hide()\nend\n\n\n",
      ["url"] = "",
      ["Icon"] = 610472,
      ["OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    --insert code here\n    \nend\n\n\n",
      ["Enabled"] = true,
      ["Revision"] = 68,
      ["Options"] = {
      },
      ["Name"] = "Aura is Shield [P]",
      ["Prio"] = 99,
      ["Author"] = "Keyspell-Azralon",
      ["Initialization"] = "		function (scriptTable)\n			--insert code here\n			\n		end\n	",
      ["Desc"] = "Show power bar where its value is the buff value (usualy shown in the buff tooltip)",
      ["SpellIds"] = {
      },
      ["Temp_UpdateCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    if (WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE) then\n        return \n    end\n    \n    local continuationToken\n    local slots\n    local foundAura = false\n    \n    repeat    \n        slots = { UnitAuraSlots(unitId, \"HELPFUL\", BUFF_MAX_DISPLAY, continuationToken) }\n        continuationToken = slots[1]\n        numSlots = #slots\n        \n        for i = 2, numSlots do\n            local slot = slots[i]\n            local name, texture, count, actualAuraType, duration, expirationTime, caster, canStealOrPurge, nameplateShowPersonal, spellId, canApplyAura, isBossDebuff, isCastByPlayer, nameplateShowAll, timeMod, auraAmount = UnitAuraBySlot(unitId, slot) \n            \n            if (spellId == envTable._SpellID) then --need to get the trigger spellId\n                --Ablative Shield\n                local unitPowerBar = unitFrame.powerBar\n                if (not unitPowerBar:IsShown()) then\n                    unitPowerBar:SetUnit(unitId)\n                end\n                \n                foundAura = true\n                return\n            end\n        end\n        \n    until continuationToken == nil\n    \n    if (not foundAura) then\n        local unitPowerBar = unitFrame.powerBar\n        if (unitPowerBar:IsShown()) then\n            unitPowerBar:Hide()\n        end\n    end\nend",
      ["version"] = -1,
      ["PlaterCore"] = 1,
      ["NpcNames"] = {
      },
      ["Temp_ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    --insert code here\n    \nend\n\n\n",
      ["semver"] = "",
      ["Temp_Initialization"] = "		function (scriptTable)\n			--insert code here\n			\n		end\n	",
    }, -- [25]
    {
      ["ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    --insert code here\n    \nend\n\n\n",
      ["OnHideCode"] = "		function (self, unitId, unitFrame, envTable, scriptTable)\n			--insert code here\n			\n		end\n	",
      ["OptionsValues"] = {
      },
      ["Temp_OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    --insert code here\n    \nend\n\n\n",
      ["ScriptType"] = 1,
      ["UpdateCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    if (UnitIsUnit(unitId .. \"target\", \"player\")) then\n        Plater.SetNameplateColor(unitFrame, scriptTable.config.nameplateColor)\n    else\n        Plater.RefreshNameplateColor(unitFrame)\n    end\nend\n\n\n\n\n\n\n\n\n\n\n\n",
      ["Time"] = 1698536662,
      ["Temp_OnHideCode"] = "		function (self, unitId, unitFrame, envTable, scriptTable)\n			--insert code here\n			\n		end\n	",
      ["url"] = "",
      ["Icon"] = "Interface\\ICONS\\Ability_Fixated_State_Red",
      ["OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    --insert code here\n    \nend\n\n\n",
      ["Enabled"] = false,
      ["Revision"] = 39,
      ["Options"] = {
        {
          ["Type"] = 1,
          ["Key"] = "nameplateColor",
          ["Value"] = {
            0, -- [1]
            0.55686274509804, -- [2]
            0.035294117647059, -- [3]
            1, -- [4]
          },
          ["Name"] = "Nameplate Color",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
          ["Desc"] = "Change the enemy nameplate color to this color when fixating you!",
        }, -- [1]
      },
      ["Name"] = "Fixate by Unit Buff [P]",
      ["Prio"] = 99,
      ["Author"] = "Ditador-Azralon",
      ["Initialization"] = "		function (scriptTable)\n			--insert code here\n			\n		end\n	",
      ["Desc"] = "Alert about a unit fixated on the player by using a buff on the enemy unit.",
      ["SpellIds"] = {
      },
      ["Temp_UpdateCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    if (UnitIsUnit(unitId .. \"target\", \"player\")) then\n        Plater.SetNameplateColor(unitFrame, scriptTable.config.nameplateColor)\n    else\n        Plater.RefreshNameplateColor(unitFrame)\n    end\nend\n\n\n\n\n\n\n\n\n\n\n\n",
      ["version"] = -1,
      ["PlaterCore"] = 1,
      ["NpcNames"] = {
      },
      ["Temp_ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    --insert code here\n    \nend\n\n\n",
      ["semver"] = "",
      ["Temp_Initialization"] = "		function (scriptTable)\n			--insert code here\n			\n		end\n	",
    }, -- [26]
    {
      ["ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    local castBar = unitFrame.castBar\n    local castBarPortion = castBar:GetWidth()/scriptTable.config.segmentsAmount\n    local castBarHeight = castBar:GetHeight()\n    \n    unitFrame.felAnimation = unitFrame.felAnimation or {}\n    \n    if (not unitFrame.felAnimation.textureStretched) then\n        unitFrame.felAnimation.textureStretched = castBar:CreateTexture(nil, \"overlay\", nil, 5)\n    end\n    \n    if (not unitFrame.felAnimation.Textures) then\n        unitFrame.felAnimation.Textures = {}\n        \n        for i = 1, 20 do --max amount of segments is 20\n            local texture = castBar:CreateTexture(nil, \"overlay\", nil, 6)\n            unitFrame.felAnimation.Textures[i] = texture            \n            \n            texture.animGroup = texture.animGroup or texture:CreateAnimationGroup()\n            local animationGroup = texture.animGroup\n            animationGroup:SetToFinalAlpha(true)            \n            animationGroup:SetLooping(\"NONE\")\n            \n            texture:SetTexture([[Interface\\COMMON\\XPBarAnim]])\n            texture:SetTexCoord(0.2990, 0.0010, 0.0010, 0.4159)\n            texture:SetBlendMode(\"ADD\")\n            \n            texture.scale = animationGroup:CreateAnimation(\"SCALE\")\n            texture.scale:SetTarget(texture)\n            \n            texture.alpha = animationGroup:CreateAnimation(\"ALPHA\")\n            texture.alpha:SetTarget(texture)\n            \n            texture.alpha2 = animationGroup:CreateAnimation(\"ALPHA\")\n            texture.alpha2:SetTarget(texture)\n        end\n    end\n    \n    \n    \nend\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n",
      ["OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    if (unitFrame.felAnimation and unitFrame.felAnimation.Textures) then\n        for i = 1, scriptTable.config.segmentsAmount  do\n            local texture = unitFrame.felAnimation.Textures[i]\n            if (texture) then\n                texture:Hide()\n            end\n        end\n    end\n    \n    if (unitFrame.felAnimation and unitFrame.felAnimation.textureStretched) then\n        local textureStretched = unitFrame.felAnimation.textureStretched\n        if (textureStretched) then\n            textureStretched:Hide()\n        end\n    end\nend\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n",
      ["OptionsValues"] = {
        ["castColor"] = {
          {
            "385536", -- [1]
            "maroon", -- [2]
          }, -- [1]
          {
            "198750", -- [1]
            "midnightblue", -- [2]
          }, -- [2]
          {
            "360850", -- [1]
            "lime", -- [2]
          }, -- [3]
          {
            "212784", -- [1]
            "deepskyblue", -- [2]
          }, -- [4]
          {
            "207980", -- [1]
            "midnightblue", -- [2]
          }, -- [5]
          {
            "199033", -- [1]
            "gold", -- [2]
          }, -- [6]
          {
            "199034", -- [1]
            "gold", -- [2]
          }, -- [7]
          {
            "200969", -- [1]
            "orange", -- [2]
          }, -- [8]
          {
            "394512", -- [1]
            "indigo", -- [2]
          }, -- [9]
          {
            "397881", -- [1]
            "deepskyblue", -- [2]
          }, -- [10]
          {
            "396020", -- [1]
            "khaki", -- [2]
          }, -- [11]
        },
      },
      ["ScriptType"] = 2,
      ["UpdateCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    if (self.channeling) then\n        return \n    end\n    \n    if (not envTable.NextPercent) then\n        return\n    end\n    \n    local castBar = unitFrame.castBar\n    \n    local textures = unitFrame.felAnimation.Textures\n    \n    if (envTable._CastPercent > envTable.NextPercent) then --eeror here, compare with nil\n        local nextPercent = 100  / scriptTable.config.segmentsAmount\n        \n        textures[envTable.CurrentTexture]:Show()\n        textures[envTable.CurrentTexture].animGroup:Play()\n        envTable.NextPercent = envTable.NextPercent + nextPercent \n        envTable.CurrentTexture = envTable.CurrentTexture + 1\n        \n        if (envTable.CurrentTexture == #textures) then\n            envTable.NextPercent = 98\n        elseif (envTable.CurrentTexture > #textures) then\n            envTable.NextPercent = 999\n        end\n    end\n    \n    local normalizedPercent = envTable._CastPercent / 100\n    local textureStretched = unitFrame.felAnimation.textureStretched\n    local point = DetailsFramework:GetBezierPoint(normalizedPercent, 0, 0.001, 1)\n    textureStretched:SetPoint(\"left\", castBar, \"left\", point * envTable.castBarWidth, 0)\n    \n    self.ThrottleUpdate = 0\nend",
      ["Time"] = 1672514190,
      ["url"] = "",
      ["Icon"] = "Interface\\AddOns\\Plater\\images\\cast_bar_glow",
      ["Enabled"] = false,
      ["Revision"] = 547,
      ["semver"] = "",
      ["Author"] = "Terciob",
      ["Initialization"] = "function (scriptTable)\n    --insert code here\n    \nend\n\n\n",
      ["OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    if (self.channeling) then\n        return \n    end\n    \n    local castBar = unitFrame.castBar\n    envTable.castBarWidth = castBar:GetWidth()\n    castBar.Spark:SetVertexColor(DetailsFramework:ParseColors(scriptTable.config.sparkColor))\n    \n    local textureStretched = unitFrame.felAnimation.textureStretched\n    textureStretched:Show()\n    textureStretched:SetVertexColor(DetailsFramework:ParseColors(scriptTable.config.glowColor))\n    textureStretched:SetAtlas(\"XPBarAnim-OrangeTrail\")\n    textureStretched:ClearAllPoints()\n    textureStretched:SetPoint(\"right\", castBar.Spark, \"center\", 0, 0)\n    textureStretched:SetHeight(castBar:GetHeight())\n    textureStretched:SetBlendMode(\"ADD\") \n    textureStretched:SetAlpha(0.5)\n    textureStretched:SetDrawLayer(\"overlay\", 7)\n    \n    for i = 1, scriptTable.config.segmentsAmount  do\n        local texture = unitFrame.felAnimation.Textures[i]\n        --texture:SetVertexColor(DetailsFramework:ParseColors(scriptTable.config.trailColor))\n        texture:SetVertexColor(1, 1, 1, 1)\n        texture:SetDesaturated(true)\n        \n        local castBarPortion = castBar:GetWidth()/scriptTable.config.segmentsAmount\n        \n        texture:SetSize(castBarPortion+5, castBar:GetHeight())\n        texture:SetDrawLayer(\"overlay\", 6)\n        \n        texture:ClearAllPoints()\n        if (i == scriptTable.config.segmentsAmount) then\n            texture:SetPoint(\"right\", castBar, \"right\", 0, 0)\n        else\n            texture:SetPoint(\"left\", castBar, \"left\", (i-1)*castBarPortion, 2)\n        end\n        \n        texture:SetAlpha(0)\n        texture:Hide()\n        \n        texture.scale:SetOrder(1)\n        texture.scale:SetDuration(0.5)\n        texture.scale:SetScaleFrom(0.2, 1)\n        texture.scale:SetScaleTo(1, 1.5)\n        texture.scale:SetOrigin(\"right\", 0, 0)\n        \n        local durationTime = DetailsFramework:GetBezierPoint(i / scriptTable.config.segmentsAmount, 0.2, 0.01, 0.6)\n        local duration = abs(durationTime-0.6)\n        \n        texture.alpha:SetOrder(1)\n        texture.alpha:SetDuration(0.05)\n        texture.alpha:SetFromAlpha(0)\n        texture.alpha:SetToAlpha(0.4)\n        \n        texture.alpha2:SetOrder(1)\n        texture.alpha2:SetDuration(duration) --0.6\n        texture.alpha2:SetStartDelay(duration)\n        texture.alpha2:SetFromAlpha(0.5)\n        texture.alpha2:SetToAlpha(0)\n    end\n    \n    envTable.CurrentTexture = 1\n    envTable.NextPercent  = 100  / scriptTable.config.segmentsAmount\n    \n    local customColor = scriptTable.config.castColor[tostring(envTable._SpellID)]\n    Plater.SetCastBarColorForScript(self, true, customColor or scriptTable.config.castBarColor, envTable)\nend\n\n\n\n\n\n\n\n\n\n\n\n\n",
      ["Options"] = {
        {
          ["Type"] = 2,
          ["Max"] = 20,
          ["Desc"] = "Need a /reload",
          ["Min"] = 5,
          ["Key"] = "segmentsAmount",
          ["Value"] = 7,
          ["Fraction"] = false,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Amount of Segments",
        }, -- [1]
        {
          ["Type"] = 1,
          ["Key"] = "sparkColor",
          ["Value"] = {
            0.95686274509804, -- [1]
            1, -- [2]
            0.98823529411765, -- [3]
            1, -- [4]
          },
          ["Name"] = "Spark Color",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
          ["Desc"] = "",
        }, -- [2]
        {
          ["Type"] = 1,
          ["Key"] = "glowColor",
          ["Value"] = {
            0.85882352941176, -- [1]
            0.43137254901961, -- [2]
            1, -- [3]
            1, -- [4]
          },
          ["Name"] = "Glow Color",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
          ["Desc"] = "",
        }, -- [3]
        {
          ["Type"] = 7,
          ["Key"] = "castColor",
          ["Value"] = {
            {
              "385536", -- [1]
              "maroon", -- [2]
            }, -- [1]
            {
              "198750", -- [1]
              "midnightblue", -- [2]
            }, -- [2]
            {
              "360850", -- [1]
              "lime", -- [2]
            }, -- [3]
            {
              "212784", -- [1]
              "deepskyblue", -- [2]
            }, -- [4]
            {
              "207980", -- [1]
              "midnightblue", -- [2]
            }, -- [5]
            {
              "199033", -- [1]
              "gold", -- [2]
            }, -- [6]
            {
              "199034", -- [1]
              "gold", -- [2]
            }, -- [7]
            {
              "200969", -- [1]
              "orange", -- [2]
            }, -- [8]
            {
              "394512", -- [1]
              "indigo", -- [2]
            }, -- [9]
            {
              "397881", -- [1]
              "deepskyblue", -- [2]
            }, -- [10]
            {
              "396020", -- [1]
              "khaki", -- [2]
            }, -- [11]
          },
          ["Name"] = "Cast Color by SpellID",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_list",
          ["Desc"] = "Insert the Spell ID in the to Key and a color name into the Value",
        }, -- [4]
      },
      ["version"] = -1,
      ["PlaterCore"] = 1,
      ["Desc"] = "Show a different animation for the cast bar.",
      ["SpellIds"] = {
        376644, -- [1]
        373017, -- [2]
        386781, -- [3]
        384823, -- [4]
        372735, -- [5]
        385536, -- [6]
        392398, -- [7]
        375596, -- [8]
        387135, -- [9]
        360850, -- [10]
        212784, -- [11]
        199033, -- [12]
        199034, -- [13]
        200969, -- [14]
        394512, -- [15]
        397881, -- [16]
        396020, -- [17]
        374430, -- [18]
        373201, -- [19]
        384353, -- [20]
        265376, -- [21]
        193941, -- [22]
        411002, -- [23]
      },
      ["Name"] = "Cast - Glowing [P]",
      ["NpcNames"] = {
      },
    }, -- [27]
    {
      ["ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    \n    --set the castbar config\n    envTable.configAltCastBar = {\n        iconTexture = \"\",\n        iconTexcoord = {0.1, 0.9, 0.1, 0.9},\n        iconAlpha = 1,\n        iconSize = 14,\n        \n        text = \"Boom!\",\n        textSize = 9,\n        \n        texture = [[Interface\\AddOns\\Plater\\images\\bar_background]],\n        color = \"silver\",\n        \n        isChanneling = false,\n        canInterrupt = false,\n        \n        height = 2,\n        width = Plater.db.profile.plate_config.enemynpc.health_incombat[1],\n        \n        spellNameAnchor = {side = 3, x = 0, y = -2},\n        timerAnchor = {side = 5, x = 0, y = -2},\n    }    \n    \n    function envTable.ShowAltCastBar(npcInfo, unitFrame, unitId, customTime, customStart)\n        --show the cast bar\n        if (npcInfo.timerId) then\n            local barObject = Plater.GetBossTimer(npcInfo.timerId)\n            if (barObject) then\n                if (npcInfo.remaining) then\n                    local timeLeft = barObject.timer + barObject.start - GetTime()\n                    if (timeLeft > npcInfo.remaining) then\n                        return\n                    end\n                end\n                \n                config.text = npcInfo.name\n                \n                if (npcInfo.spellIcon) then\n                    local _, _, iconTexture = GetSpellInfo(npcInfo.spellIcon)\n                    config.iconTexture = iconTexture\n                else\n                    config.iconTexture = \"\"\n                end\n                \n                Plater.SetAltCastBar(unitFrame.PlateFrame, config, barObject.timer, customStart or barObject.start, npcInfo.altCastId)\n            end\n        else\n            Plater.SetAltCastBar(unitFrame.PlateFrame, config, customTime or npcInfo.timer, customStart, npcInfo.altCastId)            \n        end    \n        \n        \n    end\nend\n\n\n\n\n",
      ["OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    if (envTable._SpellID == 191284) then\n        Plater.SetAltCastBar(unitFrame.PlateFrame, envTable.configAltCastBar, 4.70, GetTime(), 191284)\n        \n        C_Timer.After(4.75, function()\n                Plater.SetAltCastBar(unitFrame.PlateFrame, envTable.configAltCastBar, 5.30, GetTime(), 191284)\n        end)\n        \n        C_Timer.After(4.75 + 5.30, function()\n                Plater.SetAltCastBar(unitFrame.PlateFrame, envTable.configAltCastBar, 4.30, GetTime(), 191284)\n                C_Timer.After(4.50, function() unitFrame.castBar2:Hide() end)\n        end)\n    end\n    \nend",
      ["OptionsValues"] = {
      },
      ["Temp_OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    --insert code here\n    \nend\n\n\n",
      ["ScriptType"] = 2,
      ["UpdateCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    --insert code here\n    \nend\n\n\n",
      ["Time"] = 1672801678,
      ["Temp_OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    if (envTable._SpellID == 191284) then\n        Plater.SetAltCastBar(unitFrame.PlateFrame, envTable.configAltCastBar, 4.70, GetTime(), 191284)\n        \n        C_Timer.After(4.75, function()\n                Plater.SetAltCastBar(unitFrame.PlateFrame, envTable.configAltCastBar, 5.30, GetTime(), 191284)\n        end)\n        \n        C_Timer.After(4.75 + 5.30, function()\n                Plater.SetAltCastBar(unitFrame.PlateFrame, envTable.configAltCastBar, 4.30, GetTime(), 191284)\n                C_Timer.After(4.50, function() unitFrame.castBar2:Hide() end)\n        end)\n    end\n    \nend",
      ["url"] = "",
      ["Icon"] = 134229,
      ["OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    --insert code here\n    \nend\n\n\n",
      ["Enabled"] = false,
      ["Revision"] = 39,
      ["Options"] = {
      },
      ["Name"] = "Cast - Effect After Cast [P]",
      ["Prio"] = 99,
      ["Author"] = "Huugg-Valdrakken",
      ["Initialization"] = "		function (scriptTable)\n			--insert code here\n			\n		end\n	",
      ["Desc"] = "Start extra cast bars for effects after the cast is done. Setup the effect on On Hide script.",
      ["SpellIds"] = {
        191284, -- [1]
      },
      ["Temp_UpdateCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    --insert code here\n    \nend\n\n\n",
      ["version"] = -1,
      ["PlaterCore"] = 1,
      ["NpcNames"] = {
      },
      ["Temp_ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    \n    --set the castbar config\n    envTable.configAltCastBar = {\n        iconTexture = \"\",\n        iconTexcoord = {0.1, 0.9, 0.1, 0.9},\n        iconAlpha = 1,\n        iconSize = 14,\n        \n        text = \"Boom!\",\n        textSize = 9,\n        \n        texture = [[Interface\\AddOns\\Plater\\images\\bar_background]],\n        color = \"silver\",\n        \n        isChanneling = false,\n        canInterrupt = false,\n        \n        height = 2,\n        width = Plater.db.profile.plate_config.enemynpc.health_incombat[1],\n        \n        spellNameAnchor = {side = 3, x = 0, y = -2},\n        timerAnchor = {side = 5, x = 0, y = -2},\n    }    \n    \n    function envTable.ShowAltCastBar(npcInfo, unitFrame, unitId, customTime, customStart)\n        --show the cast bar\n        if (npcInfo.timerId) then\n            local barObject = Plater.GetBossTimer(npcInfo.timerId)\n            if (barObject) then\n                if (npcInfo.remaining) then\n                    local timeLeft = barObject.timer + barObject.start - GetTime()\n                    if (timeLeft > npcInfo.remaining) then\n                        return\n                    end\n                end\n                \n                config.text = npcInfo.name\n                \n                if (npcInfo.spellIcon) then\n                    local _, _, iconTexture = GetSpellInfo(npcInfo.spellIcon)\n                    config.iconTexture = iconTexture\n                else\n                    config.iconTexture = \"\"\n                end\n                \n                Plater.SetAltCastBar(unitFrame.PlateFrame, config, barObject.timer, customStart or barObject.start, npcInfo.altCastId)\n            end\n        else\n            Plater.SetAltCastBar(unitFrame.PlateFrame, config, customTime or npcInfo.timer, customStart, npcInfo.altCastId)            \n        end    \n        \n        \n    end\nend\n\n\n\n\n",
      ["semver"] = "",
      ["Temp_Initialization"] = "		function (scriptTable)\n			--insert code here\n			\n		end\n	",
    }, -- [28]
    {
      ["ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    function envTable.PlaySwipeAnimation(unitFrame)\n        unitFrame.CastSwipeTexture:Show()\n        unitFrame.CastSwipeAnimation:Play()\n        unitFrame.StartSwipeAnimation:Play()\n    end\n    \n    function envTable.StopSwipeAnimation(unitFrame)\n        unitFrame.EndSwipeAnimation:Play()\n        C_Timer.After(0.21, function()\n                unitFrame.CastSwipeAnimation:Stop()\n                unitFrame.CastSwipeTexture:Hide()\n        end)\n    end\n    \n    function envTable.CreateSwipeTextureAndAnimations(unitFrame)\n        if (unitFrame.CastSwipeTexture) then\n            return\n        end\n        \n        local swipeTexture = unitFrame:CreateTexture(nil, \"overlay\")\n        swipeTexture:SetTexture([[Interface\\AddOns\\Plater\\images\\circular_swipe]])\n        swipeTexture:SetPoint(\"center\", 0, 0)\n        swipeTexture:SetSize(64, 64)\n        swipeTexture:Hide()\n        \n        unitFrame.CastSwipeTexture = swipeTexture\n        \n        --rotation animation\n        unitFrame.CastSwipeAnimation = Plater:CreateAnimationHub(swipeTexture)\n        unitFrame.CastSwipeAnimation:SetLooping(\"repeat\")\n        unitFrame.CastSwipeAnimation.Rotation = Plater:CreateAnimation(unitFrame.CastSwipeAnimation, \"rotation\", 1, 1, 360)\n        \n        --starting animation\n        unitFrame.StartSwipeAnimation = Plater:CreateAnimationHub(swipeTexture, function()swipeTexture:Show() end)\n        unitFrame.StartSwipeAnimation.Alpha = Plater:CreateAnimation(unitFrame.StartSwipeAnimation, \"alpha\", 1, 0.2, 0, 1)\n        unitFrame.StartSwipeAnimation.Scale = Plater:CreateAnimation(unitFrame.StartSwipeAnimation, \"scale\", 1, 0.2, 1.3, 1.3, 1, 1)        \n        \n        --finished animation\n        unitFrame.EndSwipeAnimation = Plater:CreateAnimationHub(swipeTexture, nil, function()swipeTexture:Hide() end)\n        unitFrame.EndSwipeAnimation.Alpha = Plater:CreateAnimation(unitFrame.EndSwipeAnimation, \"alpha\", 1, 0.2, 1, 0)\n        unitFrame.EndSwipeAnimation.Scale = Plater:CreateAnimation(unitFrame.EndSwipeAnimation, \"scale\", 1, 0.2, 1, 1, 1.3, 1.3)\n    end\n    \nend\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n",
      ["OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    envTable.StopSwipeAnimation(unitFrame)\nend\n\n\n",
      ["OptionsValues"] = {
      },
      ["Temp_OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    envTable.CreateSwipeTextureAndAnimations(unitFrame)\n    \n    local options = scriptTable.config\n    \n    local targetScale = scriptTable.config.textureScale\n    \n    --swipe rotation duration    \n    unitFrame.CastSwipeAnimation.Rotation:SetDuration(scriptTable.config.rotationDuration)\n    \n    --swipe texture settings\n    unitFrame.CastSwipeTexture:SetVertexColor(Plater:ParseColors(scriptTable.config.textureColor))\n    unitFrame.CastSwipeTexture:SetScale(targetScale)\n    unitFrame.CastSwipeTexture:SetAlpha(scriptTable.config.textureAlpha)  \n    \n    unitFrame.StartSwipeAnimation.Alpha:SetDuration(scriptTable.config.animStartDuration)\n    unitFrame.StartSwipeAnimation.Alpha:SetFromAlpha(scriptTable.config.textureStartAlpha)\n    unitFrame.StartSwipeAnimation.Alpha:SetToAlpha(scriptTable.config.textureAlpha)\n    \n    unitFrame.StartSwipeAnimation.Scale:SetDuration(scriptTable.config.animStartDuration)\n    unitFrame.StartSwipeAnimation.Scale:SetScaleTo(targetScale, targetScale)\n    \n    unitFrame.EndSwipeAnimation.Scale:SetDuration(0.1)\n    unitFrame.EndSwipeAnimation.Alpha:SetDuration(0.1)\n    \n    --start playing\n    envTable.PlaySwipeAnimation(unitFrame)    \n    \nend\n\n\n",
      ["ScriptType"] = 2,
      ["UpdateCode"] = "		function (self, unitId, unitFrame, envTable, scriptTable)\n			--insert code here\n			\n		end\n	",
      ["Time"] = 1671676185,
      ["Temp_OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    envTable.StopSwipeAnimation(unitFrame)\nend\n\n\n",
      ["url"] = "",
      ["Icon"] = "Interface\\AddOns\\Plater\\images\\circular_swipe",
      ["OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    envTable.CreateSwipeTextureAndAnimations(unitFrame)\n    \n    local options = scriptTable.config\n    \n    local targetScale = scriptTable.config.textureScale\n    \n    --swipe rotation duration    \n    unitFrame.CastSwipeAnimation.Rotation:SetDuration(scriptTable.config.rotationDuration)\n    \n    --swipe texture settings\n    unitFrame.CastSwipeTexture:SetVertexColor(Plater:ParseColors(scriptTable.config.textureColor))\n    unitFrame.CastSwipeTexture:SetScale(targetScale)\n    unitFrame.CastSwipeTexture:SetAlpha(scriptTable.config.textureAlpha)  \n    \n    unitFrame.StartSwipeAnimation.Alpha:SetDuration(scriptTable.config.animStartDuration)\n    unitFrame.StartSwipeAnimation.Alpha:SetFromAlpha(scriptTable.config.textureStartAlpha)\n    unitFrame.StartSwipeAnimation.Alpha:SetToAlpha(scriptTable.config.textureAlpha)\n    \n    unitFrame.StartSwipeAnimation.Scale:SetDuration(scriptTable.config.animStartDuration)\n    unitFrame.StartSwipeAnimation.Scale:SetScaleTo(targetScale, targetScale)\n    \n    unitFrame.EndSwipeAnimation.Scale:SetDuration(0.1)\n    unitFrame.EndSwipeAnimation.Alpha:SetDuration(0.1)\n    \n    --start playing\n    envTable.PlaySwipeAnimation(unitFrame)    \n    \nend\n\n\n",
      ["Enabled"] = false,
      ["Revision"] = 163,
      ["Options"] = {
        {
          ["Type"] = 2,
          ["Max"] = 0.3,
          ["Desc"] = "Rotation Duration",
          ["Min"] = 0.1,
          ["Key"] = "rotationDuration",
          ["Value"] = 0.15,
          ["Fraction"] = true,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Rotation Duration",
        }, -- [1]
        {
          ["Type"] = 6,
          ["Key"] = "option5",
          ["Value"] = 0,
          ["Name"] = "Option 5",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [2]
        {
          ["Type"] = 2,
          ["Max"] = 1.5,
          ["Desc"] = "Animation Start Duration",
          ["Min"] = 0,
          ["Key"] = "animStartDuration",
          ["Value"] = 0.3,
          ["Fraction"] = true,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Animation Start Duration",
        }, -- [3]
        {
          ["Type"] = 2,
          ["Max"] = 1,
          ["Desc"] = "Texture Alpha when the animation start playing, this effect in intended to catch the player attention",
          ["Min"] = 0,
          ["Key"] = "textureStartAlpha",
          ["Value"] = 1,
          ["Fraction"] = true,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Texture Start Alpha",
        }, -- [4]
        {
          ["Type"] = 6,
          ["Key"] = "option5",
          ["Value"] = 0,
          ["Name"] = "Option 5",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [5]
        {
          ["Type"] = 2,
          ["Max"] = 1.2,
          ["Desc"] = "Texture Scale",
          ["Min"] = 0.6,
          ["Key"] = "textureScale",
          ["Value"] = 0.8,
          ["Fraction"] = true,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Texture Scale",
        }, -- [6]
        {
          ["Type"] = 2,
          ["Max"] = 1,
          ["Desc"] = "Texture Alpha",
          ["Min"] = 0,
          ["Key"] = "textureAlpha",
          ["Value"] = 1,
          ["Fraction"] = true,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Texture Alpha",
        }, -- [7]
        {
          ["Type"] = 1,
          ["Key"] = "textureColor",
          ["Value"] = {
            1, -- [1]
            1, -- [2]
            1, -- [3]
            1, -- [4]
          },
          ["Name"] = "Texture Color",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
          ["Desc"] = "Texture Color",
        }, -- [8]
      },
      ["Name"] = "Cast - Circle AoE [P]",
      ["Prio"] = 99,
      ["Author"] = "Butazzul-Valdrakken",
      ["Initialization"] = "		function (scriptTable)\n			--insert code here\n			\n		end\n	",
      ["Desc"] = "Play a animation when the spell effect is an circular AoE around the caster.",
      ["SpellIds"] = {
        385916, -- [1]
        386063, -- [2]
        388822, -- [3]
        373087, -- [4]
        397785, -- [5]
        106864, -- [6]
        193660, -- [7]
        198263, -- [8]
        387910, -- [9]
        370766, -- [10]
        375591, -- [11]
        384336, -- [12]
        209404, -- [13]
        209378, -- [14]
        210875, -- [15]
        396001, -- [16]
        397899, -- [17]
        386559, -- [18]
        382555, -- [19]
        258672, -- [20]
        258777, -- [21]
        257756, -- [22]
        257784, -- [23]
        256405, -- [24]
        256589, -- [25]
        393793, -- [26]
        388046, -- [27]
        375079, -- [28]
        390290, -- [29]
        369811, -- [30]
        369703, -- [31]
        226287, -- [32]
        410999, -- [33]
        372561, -- [34]
      },
      ["Temp_UpdateCode"] = "		function (self, unitId, unitFrame, envTable, scriptTable)\n			--insert code here\n			\n		end\n	",
      ["version"] = -1,
      ["PlaterCore"] = 1,
      ["NpcNames"] = {
      },
      ["Temp_ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    function envTable.PlaySwipeAnimation(unitFrame)\n        unitFrame.CastSwipeTexture:Show()\n        unitFrame.CastSwipeAnimation:Play()\n        unitFrame.StartSwipeAnimation:Play()\n    end\n    \n    function envTable.StopSwipeAnimation(unitFrame)\n        unitFrame.EndSwipeAnimation:Play()\n        C_Timer.After(0.21, function()\n                unitFrame.CastSwipeAnimation:Stop()\n                unitFrame.CastSwipeTexture:Hide()\n        end)\n    end\n    \n    function envTable.CreateSwipeTextureAndAnimations(unitFrame)\n        if (unitFrame.CastSwipeTexture) then\n            return\n        end\n        \n        local swipeTexture = unitFrame:CreateTexture(nil, \"overlay\")\n        swipeTexture:SetTexture([[Interface\\AddOns\\Plater\\images\\circular_swipe]])\n        swipeTexture:SetPoint(\"center\", 0, 0)\n        swipeTexture:SetSize(64, 64)\n        swipeTexture:Hide()\n        \n        unitFrame.CastSwipeTexture = swipeTexture\n        \n        --rotation animation\n        unitFrame.CastSwipeAnimation = Plater:CreateAnimationHub(swipeTexture)\n        unitFrame.CastSwipeAnimation:SetLooping(\"repeat\")\n        unitFrame.CastSwipeAnimation.Rotation = Plater:CreateAnimation(unitFrame.CastSwipeAnimation, \"rotation\", 1, 1, 360)\n        \n        --starting animation\n        unitFrame.StartSwipeAnimation = Plater:CreateAnimationHub(swipeTexture, function()swipeTexture:Show() end)\n        unitFrame.StartSwipeAnimation.Alpha = Plater:CreateAnimation(unitFrame.StartSwipeAnimation, \"alpha\", 1, 0.2, 0, 1)\n        unitFrame.StartSwipeAnimation.Scale = Plater:CreateAnimation(unitFrame.StartSwipeAnimation, \"scale\", 1, 0.2, 1.3, 1.3, 1, 1)        \n        \n        --finished animation\n        unitFrame.EndSwipeAnimation = Plater:CreateAnimationHub(swipeTexture, nil, function()swipeTexture:Hide() end)\n        unitFrame.EndSwipeAnimation.Alpha = Plater:CreateAnimation(unitFrame.EndSwipeAnimation, \"alpha\", 1, 0.2, 1, 0)\n        unitFrame.EndSwipeAnimation.Scale = Plater:CreateAnimation(unitFrame.EndSwipeAnimation, \"scale\", 1, 0.2, 1, 1, 1.3, 1.3)\n    end\n    \nend\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n",
      ["semver"] = "",
      ["Temp_Initialization"] = "		function (scriptTable)\n			--insert code here\n			\n		end\n	",
    }, -- [29]
    {
      ["ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    envTable.lifePercent = { --dragonflight\n        [197697] = {50}, --Flamegullet\n        [59544] = {50}, --The Nodding Tiger\n        [186227] = {20}, --Monstrous Decay\n        [184020] = {40}, -- Hulking Berserker\n        [91005] = {20}, --Naraxas\n    }\n    \n    \n    function envTable.CreateMarker(unitFrame)\n        unitFrame.healthMarker = unitFrame.healthBar:CreateTexture(nil, \"overlay\")\n        unitFrame.healthMarker:SetColorTexture(1, 1, 1)\n        unitFrame.healthMarker:SetSize(1, unitFrame.healthBar:GetHeight())\n        \n        unitFrame.healthOverlay = unitFrame.healthBar:CreateTexture(nil, \"overlay\")\n        unitFrame.healthOverlay:SetColorTexture(1, 1, 1)\n        unitFrame.healthOverlay:SetSize(1, unitFrame.healthBar:GetHeight())\n    end\n    \n    function envTable.UpdateMarkers(unitFrame)\n        local markersTable = envTable.lifePercent[envTable._NpcID]\n        if (markersTable) then\n            local unitLifePercent = envTable._HealthPercent / 100\n            for i, percent in ipairs(markersTable) do\n                percent = percent / 100\n                if (unitLifePercent > percent) then\n                    if (not unitFrame.healthMarker) then\n                        envTable.CreateMarker(unitFrame)\n                    end\n                    \n                    unitFrame.healthMarker:Show()\n                    local width = unitFrame.healthBar:GetWidth()\n                    unitFrame.healthMarker:SetPoint(\"left\", unitFrame.healthBar, \"left\", width*percent, 0)\n                    \n                    local overlaySize = width * (unitLifePercent - percent)\n                    unitFrame.healthOverlay:SetWidth(overlaySize)\n                    unitFrame.healthOverlay:SetPoint(\"left\", unitFrame.healthMarker, \"right\", 0, 0)\n                    \n                    unitFrame.healthMarker:SetVertexColor(Plater:ParseColors(scriptTable.config.indicatorColor))\n                    unitFrame.healthMarker:SetAlpha(scriptTable.config.indicatorAlpha)\n                    \n                    unitFrame.healthOverlay:SetVertexColor(Plater:ParseColors(scriptTable.config.fillColor))\n                    unitFrame.healthOverlay:SetAlpha(scriptTable.config.fillAlpha)\n                    \n                    return\n                end\n            end --end for\n            \n            if (unitFrame.healthMarker and unitFrame.healthMarker:IsShown()) then\n                unitFrame.healthMarker:Hide()\n                unitFrame.healthOverlay:Hide()\n            end\n        end\n    end\nend      \n\n\n\n\n\n\n\n\n\n",
      ["OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    if (unitFrame.healthMarker) then\n        unitFrame.healthMarker:Hide()\n        unitFrame.healthOverlay:Hide()\n    end\nend\n\n\n\n\n",
      ["OptionsValues"] = {
        ["indicatorColor"] = {
          1, -- [1]
          1, -- [2]
          1, -- [3]
          1, -- [4]
        },
        ["indicatorAlpha"] = 0.798833966255188,
        ["fillColor"] = {
          1, -- [1]
          1, -- [2]
          1, -- [3]
          1, -- [4]
        },
      },
      ["Temp_OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    --insert code here\n    envTable.UpdateMarkers(unitFrame)\nend\n\n\n",
      ["ScriptType"] = 3,
      ["UpdateCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    --insert code here\n    envTable.UpdateMarkers(unitFrame)\nend\n\n\n",
      ["Time"] = 1699197034,
      ["NpcNames"] = {
        "197697", -- [1]
        "59544", -- [2]
        "186227", -- [3]
        "184020", -- [4]
        "91005", -- [5]
      },
      ["url"] = "",
      ["Icon"] = "Interface\\AddOns\\Plater\\images\\health_indicator",
      ["Options"] = {
        {
          ["Type"] = 5,
          ["Key"] = "option1",
          ["Value"] = "Add markers into the health bar to remind you about boss abilities at life percent.",
          ["Name"] = "Option 1",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_label",
          ["Desc"] = "",
        }, -- [1]
        {
          ["Type"] = 6,
          ["Key"] = "",
          ["Value"] = 0,
          ["Name"] = "blank line",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [2]
        {
          ["Type"] = 1,
          ["Key"] = "indicatorColor",
          ["Value"] = {
            1, -- [1]
            1, -- [2]
            1, -- [3]
            1, -- [4]
          },
          ["Name"] = "Vertical Line Color",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
          ["Desc"] = "Indicator color.",
        }, -- [3]
        {
          ["Type"] = 2,
          ["Max"] = 1,
          ["Desc"] = "Indicator alpha.",
          ["Min"] = 0.1,
          ["Fraction"] = true,
          ["Value"] = 0.79,
          ["Key"] = "indicatorAlpha",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Vertical Line Alpha",
        }, -- [4]
        {
          ["Type"] = 6,
          ["Name"] = "blank line",
          ["Value"] = 0,
          ["Key"] = "",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [5]
        {
          ["Type"] = 1,
          ["Name"] = "Fill Color",
          ["Value"] = {
            1, -- [1]
            1, -- [2]
            1, -- [3]
            1, -- [4]
          },
          ["Key"] = "fillColor",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
          ["Desc"] = "Fill color.",
        }, -- [6]
        {
          ["Type"] = 2,
          ["Max"] = 1,
          ["Desc"] = "Fill alpha.",
          ["Min"] = 0,
          ["Key"] = "fillAlpha",
          ["Value"] = 0.2,
          ["Name"] = "Fill Alpha",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Fraction"] = true,
        }, -- [7]
      },
      ["Enabled"] = true,
      ["Revision"] = 151,
      ["semver"] = "",
      ["Name"] = "Add - Health Markers [P]",
      ["Temp_UpdateCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    --insert code here\n    envTable.UpdateMarkers(unitFrame)\nend\n\n\n",
      ["Author"] = "Aelerolor-Torghast",
      ["Initialization"] = "function (scriptTable)\n    --insert code here\n    \nend\n\n\n",
      ["Desc"] = "Place a marker into the health bar to indicate when the unit will change phase or cast an important spell.",
      ["version"] = -1,
      ["Prio"] = 99,
      ["SpellIds"] = {
      },
      ["PlaterCore"] = 1,
      ["OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    --insert code here\n    envTable.UpdateMarkers(unitFrame)\nend\n\n\n",
      ["Temp_ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    envTable.lifePercent = { --dragonflight\n        [197697] = {50}, --Flamegullet\n        [59544] = {50}, --The Nodding Tiger\n        [186227] = {20}, --Monstrous Decay\n        [184020] = {40}, -- Hulking Berserker\n        [91005] = {20}, --Naraxas\n    }\n    \n    \n    function envTable.CreateMarker(unitFrame)\n        unitFrame.healthMarker = unitFrame.healthBar:CreateTexture(nil, \"overlay\")\n        unitFrame.healthMarker:SetColorTexture(1, 1, 1)\n        unitFrame.healthMarker:SetSize(1, unitFrame.healthBar:GetHeight())\n        \n        unitFrame.healthOverlay = unitFrame.healthBar:CreateTexture(nil, \"overlay\")\n        unitFrame.healthOverlay:SetColorTexture(1, 1, 1)\n        unitFrame.healthOverlay:SetSize(1, unitFrame.healthBar:GetHeight())\n    end\n    \n    function envTable.UpdateMarkers(unitFrame)\n        local markersTable = envTable.lifePercent[envTable._NpcID]\n        if (markersTable) then\n            local unitLifePercent = envTable._HealthPercent / 100\n            for i, percent in ipairs(markersTable) do\n                percent = percent / 100\n                if (unitLifePercent > percent) then\n                    if (not unitFrame.healthMarker) then\n                        envTable.CreateMarker(unitFrame)\n                    end\n                    \n                    unitFrame.healthMarker:Show()\n                    local width = unitFrame.healthBar:GetWidth()\n                    unitFrame.healthMarker:SetPoint(\"left\", unitFrame.healthBar, \"left\", width*percent, 0)\n                    \n                    local overlaySize = width * (unitLifePercent - percent)\n                    unitFrame.healthOverlay:SetWidth(overlaySize)\n                    unitFrame.healthOverlay:SetPoint(\"left\", unitFrame.healthMarker, \"right\", 0, 0)\n                    \n                    unitFrame.healthMarker:SetVertexColor(Plater:ParseColors(scriptTable.config.indicatorColor))\n                    unitFrame.healthMarker:SetAlpha(scriptTable.config.indicatorAlpha)\n                    \n                    unitFrame.healthOverlay:SetVertexColor(Plater:ParseColors(scriptTable.config.fillColor))\n                    unitFrame.healthOverlay:SetAlpha(scriptTable.config.fillAlpha)\n                    \n                    return\n                end\n            end --end for\n            \n            if (unitFrame.healthMarker and unitFrame.healthMarker:IsShown()) then\n                unitFrame.healthMarker:Hide()\n                unitFrame.healthOverlay:Hide()\n            end\n        end\n    end\nend      \n\n\n\n\n\n\n\n\n\n",
      ["Temp_OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    if (unitFrame.healthMarker) then\n        unitFrame.healthMarker:Hide()\n        unitFrame.healthOverlay:Hide()\n    end\nend\n\n\n\n\n",
      ["Temp_Initialization"] = "function (scriptTable)\n    --insert code here\n    \nend\n\n\n",
    }, -- [30]
    {
      ["ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    envTable.NameplateColor = scriptTable.config.nameplateColor\n    envTable.NameplateSizeOffset = scriptTable.config.nameplateSizeOffset\n    \n    unitFrame.UnitImportantSkullTexture = unitFrame.UnitImportantSkullTexture or unitFrame:CreateTexture(nil, \"background\")\n    \n    unitFrame.UnitImportantSkullTexture:Hide()\nend\n\n--[=[\n\n154564 - debug\n\nUsing spellIDs for multi-language support\n\n196548 = ancient branch (academy dungeon)\n195580, 195821, 195820 = nokhub saboteur\n189886 = blazebound firestorm\n75966 = Defiled Spirit\n102019 = Stormforged Obliterator\n    187159 = Shrieking Whelp\n194897 = stormsurge totem\n104251 = duskwatch sentry\n101326 = honored ancestor\n189669 = binding speakl netharius\n192464 = raging ember neltharius\n--]=]\n\n\n",
      ["OnHideCode"] = "function (self, unitId, unitFrame, envTable)\n    Plater.StopDotAnimation(unitFrame.healthBar, envTable.dotAnimation)   \n    \n    --restore the nameplate size\n    local nameplateHeight = Plater.db.profile.plate_config.enemynpc.health_incombat [2]\n    unitFrame.healthBar:SetHeight (nameplateHeight)    \n    \n    unitFrame.UnitImportantSkullTexture:Hide()\n    Plater.DenyColorChange(unitFrame, false)\nend\n\n\n",
      ["OptionsValues"] = {
        ["npcColor"] = {
          {
            "196548", -- [1]
            "forestgreen", -- [2]
          }, -- [1]
          {
            "195580", -- [1]
            "forestgreen", -- [2]
          }, -- [2]
          {
            "195820", -- [1]
            "forestgreen", -- [2]
          }, -- [3]
          {
            "195821", -- [1]
            "forestgreen", -- [2]
          }, -- [4]
          {
            "189886", -- [1]
            "forestgreen", -- [2]
          }, -- [5]
          {
            "75966", -- [1]
            "forestgreen", -- [2]
          }, -- [6]
          {
            "102019 ", -- [1]
            "forestgreen", -- [2]
          }, -- [7]
          {
            "187159", -- [1]
            "forestgreen", -- [2]
          }, -- [8]
          {
            "194897", -- [1]
            "forestgreen", -- [2]
          }, -- [9]
          {
            "104251", -- [1]
            "forestgreen", -- [2]
          }, -- [10]
        },
      },
      ["Temp_OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    if (envTable.dotAnimation) then\n        Plater.StopDotAnimation(unitFrame.healthBar, envTable.dotAnimation)\n    end\n    \n    envTable.dotAnimation = Plater.PlayDotAnimation(unitFrame.healthBar, 2, scriptTable.config.dotsColor, 3, 4) \n    \n    --increase the nameplate size\n    local nameplateHeight = Plater.db.profile.plate_config.enemynpc.health_incombat [2]\n    unitFrame.healthBar:SetHeight (nameplateHeight + envTable.NameplateSizeOffset)\n    \n    unitFrame.UnitImportantSkullTexture:Show()\n    \n    --color priority:\n    local npcIdString = tostring(envTable._NpcID)\n    envTable.NameplateColor = Plater.GetColorByPriority(unitFrame, scriptTable.config.npcColor[npcIdString], scriptTable.config.nameplateColor)    \n    \n    if (scriptTable.config.showExtraTexture) then\n        unitFrame.UnitImportantSkullTexture:SetVertexColor(Plater:ParseColors(scriptTable.config.skullColor))\n        unitFrame.UnitImportantSkullTexture:SetAlpha(scriptTable.config.skullAlpha)\n        unitFrame.UnitImportantSkullTexture:SetScale(scriptTable.config.skullScale)\n        unitFrame.UnitImportantSkullTexture:SetTexture([[Interface/AddOns/Plater/media/x_64]])\n        unitFrame.UnitImportantSkullTexture:ClearAllPoints()\n        unitFrame.UnitImportantSkullTexture:SetPoint(\"right\", unitFrame.healthBar, \"left\", -2, 0)\n        unitFrame.UnitImportantSkullTexture:SetSize(28, 28)\n        unitFrame.UnitImportantSkullTexture:Show()\n    else\n        unitFrame.UnitImportantSkullTexture:Hide()\n    end\n    \n    --rules for some npcs\n    if (envTable._NpcID == 194895) then --unstable squall (explode at dying\n        unitFrame.UnitImportantSkullTexture:Hide()\n        Plater.StopDotAnimation(unitFrame.healthBar, envTable.dotAnimation) \n    end\n    \n    if (scriptTable.config.changeNameplateColor) then\n        local npcIdString = tostring(envTable._NpcID)\n        \n        envTable.NameplateColor = Plater.GetColorByPriority(unitFrame, scriptTable.config.npcColor[npcIdString], scriptTable.config.nameplateColor)        \n        \n        Plater.DenyColorChange(unitFrame, true)\n    end\n    \nend\n\n\n\n\n",
      ["ScriptType"] = 3,
      ["UpdateCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    --check if can change the nameplate color\n    if (scriptTable.config.changeNameplateColor) then\n        Plater.SetNameplateColor(unitFrame, envTable.NameplateColor)\n    end\n    \nend\n\n\n\n\n",
      ["Time"] = 1699197363,
      ["Temp_OnHideCode"] = "function (self, unitId, unitFrame, envTable)\n    Plater.StopDotAnimation(unitFrame.healthBar, envTable.dotAnimation)   \n    \n    --restore the nameplate size\n    local nameplateHeight = Plater.db.profile.plate_config.enemynpc.health_incombat [2]\n    unitFrame.healthBar:SetHeight (nameplateHeight)    \n    \n    unitFrame.UnitImportantSkullTexture:Hide()\n    Plater.DenyColorChange(unitFrame, false)\nend\n\n\n",
      ["url"] = "",
      ["Icon"] = "Interface\\AddOns\\Plater\\media\\skullbones_64",
      ["OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    if (envTable.dotAnimation) then\n        Plater.StopDotAnimation(unitFrame.healthBar, envTable.dotAnimation)\n    end\n    \n    envTable.dotAnimation = Plater.PlayDotAnimation(unitFrame.healthBar, 2, scriptTable.config.dotsColor, 3, 4) \n    \n    --increase the nameplate size\n    local nameplateHeight = Plater.db.profile.plate_config.enemynpc.health_incombat [2]\n    unitFrame.healthBar:SetHeight (nameplateHeight + envTable.NameplateSizeOffset)\n    \n    unitFrame.UnitImportantSkullTexture:Show()\n    \n    --color priority:\n    local npcIdString = tostring(envTable._NpcID)\n    envTable.NameplateColor = Plater.GetColorByPriority(unitFrame, scriptTable.config.npcColor[npcIdString], scriptTable.config.nameplateColor)    \n    \n    if (scriptTable.config.showExtraTexture) then\n        unitFrame.UnitImportantSkullTexture:SetVertexColor(Plater:ParseColors(scriptTable.config.skullColor))\n        unitFrame.UnitImportantSkullTexture:SetAlpha(scriptTable.config.skullAlpha)\n        unitFrame.UnitImportantSkullTexture:SetScale(scriptTable.config.skullScale)\n        unitFrame.UnitImportantSkullTexture:SetTexture([[Interface/AddOns/Plater/media/x_64]])\n        unitFrame.UnitImportantSkullTexture:ClearAllPoints()\n        unitFrame.UnitImportantSkullTexture:SetPoint(\"right\", unitFrame.healthBar, \"left\", -2, 0)\n        unitFrame.UnitImportantSkullTexture:SetSize(28, 28)\n        unitFrame.UnitImportantSkullTexture:Show()\n    else\n        unitFrame.UnitImportantSkullTexture:Hide()\n    end\n    \n    --rules for some npcs\n    if (envTable._NpcID == 194895) then --unstable squall (explode at dying\n        unitFrame.UnitImportantSkullTexture:Hide()\n        Plater.StopDotAnimation(unitFrame.healthBar, envTable.dotAnimation) \n    end\n    \n    if (scriptTable.config.changeNameplateColor) then\n        local npcIdString = tostring(envTable._NpcID)\n        \n        envTable.NameplateColor = Plater.GetColorByPriority(unitFrame, scriptTable.config.npcColor[npcIdString], scriptTable.config.nameplateColor)        \n        \n        Plater.DenyColorChange(unitFrame, true)\n    end\n    \nend\n\n\n\n\n",
      ["Enabled"] = false,
      ["Revision"] = 577,
      ["Options"] = {
        {
          ["Type"] = 6,
          ["Key"] = "option4",
          ["Value"] = 0,
          ["Name"] = "Blank Space",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [1]
        {
          ["Type"] = 5,
          ["Key"] = "option6",
          ["Value"] = "Enter the npc name or npcId in the \"Add Trigger\" box and hit \"Add\".",
          ["Name"] = "Option 6",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_label",
          ["Desc"] = "",
        }, -- [2]
        {
          ["Type"] = 6,
          ["Key"] = "option4",
          ["Value"] = 0,
          ["Name"] = "Blank Space",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [3]
        {
          ["Type"] = 4,
          ["Key"] = "changeNameplateColor",
          ["Value"] = true,
          ["Name"] = "Change Nameplate Color",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_bool",
          ["Desc"] = "change to true to change the color",
        }, -- [4]
        {
          ["Type"] = 1,
          ["Key"] = "nameplateColor",
          ["Value"] = {
            1, -- [1]
            0, -- [2]
            0.52549019607843, -- [3]
            1, -- [4]
          },
          ["Name"] = "Nameplate Color",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
          ["Desc"] = "Nameplate Color",
        }, -- [5]
        {
          ["Type"] = 2,
          ["Max"] = 6,
          ["Desc"] = "increase the nameplate height by this value",
          ["Min"] = 0,
          ["Key"] = "nameplateSizeOffset",
          ["Value"] = 3,
          ["Fraction"] = false,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Nameplate Size Offset",
        }, -- [6]
        {
          ["Type"] = 6,
          ["Key"] = "option4",
          ["Value"] = 0,
          ["Name"] = "Blank Space",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [7]
        {
          ["Type"] = 1,
          ["Key"] = "dotsColor",
          ["Value"] = {
            1, -- [1]
            0.71372550725937, -- [2]
            0, -- [3]
            0.56313106417656, -- [4]
          },
          ["Name"] = "Dot Color",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
          ["Desc"] = "Dot Color",
        }, -- [8]
        {
          ["Type"] = 6,
          ["Key"] = "option4",
          ["Value"] = 0,
          ["Name"] = "Blank Space",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [9]
        {
          ["Type"] = 5,
          ["Key"] = "option10",
          ["Value"] = "Extra Texture",
          ["Name"] = "Extra Texture",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_label",
          ["Desc"] = "Extra Texture",
        }, -- [10]
        {
          ["Type"] = 4,
          ["Key"] = "showExtraTexture",
          ["Value"] = false,
          ["Name"] = "Show Extra Texture",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_bool",
          ["Desc"] = "Show Extra Texture",
        }, -- [11]
        {
          ["Type"] = 1,
          ["Key"] = "skullColor",
          ["Value"] = {
            1, -- [1]
            0.46274509803922, -- [2]
            0, -- [3]
            1, -- [4]
          },
          ["Name"] = "Texture Color",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
          ["Desc"] = "Texture Color",
        }, -- [12]
        {
          ["Type"] = 2,
          ["Max"] = 1,
          ["Desc"] = "Alpha",
          ["Min"] = 0,
          ["Key"] = "skullAlpha",
          ["Value"] = 0.2,
          ["Fraction"] = true,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Alpha",
        }, -- [13]
        {
          ["Type"] = 2,
          ["Max"] = 2,
          ["Desc"] = "Scale",
          ["Min"] = 0.4,
          ["Key"] = "skullScale",
          ["Value"] = 0.6,
          ["Fraction"] = true,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Scale",
        }, -- [14]
        {
          ["Type"] = 7,
          ["Key"] = "npcColor",
          ["Value"] = {
            {
              "196548", -- [1]
              "forestgreen", -- [2]
            }, -- [1]
            {
              "195580", -- [1]
              "forestgreen", -- [2]
            }, -- [2]
            {
              "195820", -- [1]
              "forestgreen", -- [2]
            }, -- [3]
            {
              "195821", -- [1]
              "forestgreen", -- [2]
            }, -- [4]
            {
              "189886", -- [1]
              "forestgreen", -- [2]
            }, -- [5]
            {
              "75966", -- [1]
              "forestgreen", -- [2]
            }, -- [6]
            {
              "102019 ", -- [1]
              "forestgreen", -- [2]
            }, -- [7]
            {
              "187159", -- [1]
              "forestgreen", -- [2]
            }, -- [8]
            {
              "194897", -- [1]
              "forestgreen", -- [2]
            }, -- [9]
            {
              "104251", -- [1]
              "forestgreen", -- [2]
            }, -- [10]
          },
          ["Name"] = "Npc Color By NpcID",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_list",
          ["Desc"] = "Key is the npcID, value is the color name",
        }, -- [15]
      },
      ["Name"] = "Add - Important [P]",
      ["Prio"] = 99,
      ["Author"] = "Izimode-Azralon",
      ["Initialization"] = "function (scriptTable)\n    --insert code here\n    \nend\n\n\n",
      ["Desc"] = "Change the color and highlight a nameplate of an important Add. Add the unit name or NpcID into the trigger box to add more.",
      ["SpellIds"] = {
      },
      ["Temp_UpdateCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    --check if can change the nameplate color\n    if (scriptTable.config.changeNameplateColor) then\n        Plater.SetNameplateColor(unitFrame, envTable.NameplateColor)\n    end\n    \nend\n\n\n\n\n",
      ["version"] = -1,
      ["PlaterCore"] = 1,
      ["NpcNames"] = {
        "196548", -- [1]
        "195580", -- [2]
        "195820", -- [3]
        "195821", -- [4]
        "189886", -- [5]
        "75966", -- [6]
        "102019", -- [7]
        "187159", -- [8]
        "194897", -- [9]
        "104251", -- [10]
        "101326", -- [11]
        "189669", -- [12]
        "192464", -- [13]
        190381, -- [14]
        92538, -- [15]
        192464, -- [16]
      },
      ["Temp_ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    envTable.NameplateColor = scriptTable.config.nameplateColor\n    envTable.NameplateSizeOffset = scriptTable.config.nameplateSizeOffset\n    \n    unitFrame.UnitImportantSkullTexture = unitFrame.UnitImportantSkullTexture or unitFrame:CreateTexture(nil, \"background\")\n    \n    unitFrame.UnitImportantSkullTexture:Hide()\nend\n\n--[=[\n\n154564 - debug\n\nUsing spellIDs for multi-language support\n\n196548 = ancient branch (academy dungeon)\n195580, 195821, 195820 = nokhub saboteur\n189886 = blazebound firestorm\n75966 = Defiled Spirit\n102019 = Stormforged Obliterator\n    187159 = Shrieking Whelp\n194897 = stormsurge totem\n104251 = duskwatch sentry\n101326 = honored ancestor\n189669 = binding speakl netharius\n192464 = raging ember neltharius\n--]=]\n\n\n",
      ["semver"] = "",
      ["Temp_Initialization"] = "function (scriptTable)\n    --insert code here\n    \nend\n\n\n",
    }, -- [31]
    {
      ["ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    --insert code here\n    \nend\n\n\n",
      ["OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    if (unitFrame.AddSpawnIDTexture) then\n        unitFrame.AddSpawnIDTexture:Hide()\n        unitFrame.AddIcon:Hide()\n        unitFrame.AddNumber:Hide()\n    end\n    \nend\n\n\n\n\n",
      ["OptionsValues"] = {
      },
      ["ScriptType"] = 3,
      ["UpdateCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    --insert code here\n    \nend\n\n\n",
      ["Time"] = 1669340442,
      ["url"] = "",
      ["Icon"] = "interface/addons/plater/images/add_id_icon",
      ["Enabled"] = false,
      ["Revision"] = 161,
      ["semver"] = "",
      ["Author"] = "Huugg-Valdrakken",
      ["Initialization"] = "function (scriptTable)\n    \n    scriptTable.allAdds = {} \n    scriptTable.nextAddWave = 0\n    scriptTable.waveTime = 20\n    \n    function scriptTable.ArrangeNpcNumbers(GUID)\n        local spawnId = select(7, strsplit (\"-\", GUID))\n        spawnId = tonumber(spawnId, 16)\n        \n        if (spawnId) then\n            --check if this is a new wave of adds\n            if (GetTime() > scriptTable.nextAddWave) then\n                scriptTable.nextAddWave = GetTime() + scriptTable.waveTime\n                scriptTable.allAdds = {}\n            end\n            \n            local bIsAlreadyOnTheList = false\n            \n            for o = 1, #scriptTable.allAdds do\n                if (scriptTable.allAdds[o][1] == GUID) then\n                    bIsAlreadyOnTheList = true\n                end\n            end\n            \n            if (not bIsAlreadyOnTheList) then\n                scriptTable.allAdds[#scriptTable.allAdds+1] = {GUID, spawnId}\n            end\n        end\n        \n        table.sort(scriptTable.allAdds, function(t1, t2) return t1[2] < t2[2] end)\n        \n        --this is a \"loop\" because this is running each time a nameplate is added!\n        \n        for namePlateIndex, plateFrame in ipairs(Plater.GetAllShownPlates()) do\n            local unitFrame = plateFrame.unitFrame\n            \n            --get the unit GUID\n            local unitGUID = unitFrame.namePlateUnitGUID\n            \n            for addId = 1, #scriptTable.allAdds do\n                local addTable = scriptTable.allAdds[addId]\n                local addGUID = addTable[1]\n                \n                if (unitGUID == addGUID) then\n                    scriptTable.TagNameplate(unitFrame, unitGUID, addId)\n                    break\n                end\n            end\n            \n        end\n    end\n    \n    function scriptTable.TagNameplate(unitFrame, GUID, addId)\n        scriptTable.CreateAddWidgetsForNameplate(unitFrame, GUID, addId)\n        \n        if (addId and addId >= 1 and addId <= 8) then\n            unitFrame.AddSpawnIDTexture:Show()\n            unitFrame.AddIcon:Show()\n            unitFrame.AddNumber:Show()\n            \n            local addTexture = \"Interface\\\\TargetingFrame\\\\UI-RaidTargetingIcon_\" .. addId\n            \n            unitFrame.AddIcon:SetTexture(addTexture)\n            unitFrame.AddNumber:SetText(addId)\n        end\n    end\n    \n    function scriptTable.CreateAddWidgetsForNameplate(unitFrame, GUID, addId)\n        if (not unitFrame.AddSpawnIDTexture) then\n            local healthBar = unitFrame.healthBar\n            \n            local textureBackground = healthBar.FrameOverlay:CreateTexture(nil, \"overlay\", nil, 5)\n            local addIcon = healthBar.FrameOverlay:CreateTexture(nil, \"overlay\", nil, 6)\n            local addNumber = healthBar.FrameOverlay:CreateFontString(nil, \"overlay\", \"GameFontNormal\", 6)           \n            \n            unitFrame.AddSpawnIDTexture = textureBackground\n            unitFrame.AddIcon = addIcon\n            unitFrame.AddNumber = addNumber\n        end\n    end    \nend\n\n--Creature-0-2085-1-11042-153285-0002F8DB2B --training dummy for testing\n--195138 Detonating Crystal\n--192955 dracomoc illusion\n--190294 nokhub stormcaster\n--76518 ritual of bones\n\n\n\n\n",
      ["OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    if (unitFrame.AddSpawnIDTexture) then\n        unitFrame.AddSpawnIDTexture:Hide()\n        unitFrame.AddIcon:Hide()\n        unitFrame.AddNumber:Hide()\n    end\n    \n    scriptTable.ArrangeNpcNumbers(unitFrame.namePlateUnitGUID)\n    \n    local textureBackground = unitFrame.AddSpawnIDTexture\n    textureBackground:SetSize(22, 10)\n    textureBackground:ClearAllPoints()\n    textureBackground:SetPoint(\"bottomright\", unitFrame.healthBar, \"topright\", 0, 1)\n    \n    textureBackground:SetMask([[Interface\\AddOns\\Plater\\masks\\mask_smallrectangle_rounded1]])\n    textureBackground:SetTexture([[Interface\\AddOns\\Plater\\masks\\mask_smallrectangle_rounded1]])\n    textureBackground:SetVertexColor(0.1215, 0.1176, 0.1294, 1)\n    \n    \n    --textureBackground:SetMask([[Interface/ChatFrame/UI-ChatIcon-HotS]])\n    --    \"Interface/ChatFrame/UI-ChatIcon-HotS\"\n    \n    local addIcon = unitFrame.AddIcon\n    addIcon:ClearAllPoints()\n    addIcon:SetPoint(\"left\", textureBackground, \"left\", 2, 0)\n    addIcon:SetSize(10, 10)\n    \n    local addNumber = unitFrame.AddNumber\n    addNumber:ClearAllPoints()\n    addNumber:SetPoint(\"right\", textureBackground, \"right\", -2, 0)\n    DetailsFramework:SetFontSize(addNumber, 10)\n    \nend\n\n\n",
      ["Options"] = {
      },
      ["version"] = -1,
      ["PlaterCore"] = 1,
      ["Desc"] = "Put a number above multiples adds, numbers follow their respawn id.",
      ["SpellIds"] = {
      },
      ["Name"] = "Add - Tag Number [P]",
      ["NpcNames"] = {
        "195138", -- [1]
        "192955", -- [2]
        "190294", -- [3]
        "76518", -- [4]
      },
    }, -- [32]
    {
      ["ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    --castbar color (when can be interrupted)\n    envTable.CastbarColor = scriptTable.config.castbarColor\n    \n    --flash duration\n    local CONFIG_BACKGROUND_FLASH_DURATION = scriptTable.config.flashDuration\n    \n    --add this value to the cast bar height\n    envTable.CastBarHeightAdd = scriptTable.config.castBarHeight\n    \n    --create a fast flash above the cast bar\n    envTable.FullBarFlash = envTable.FullBarFlash or Plater.CreateFlash (self, 0.05, 1, \"white\")\n    \n    --create a camera shake for the nameplate\n    envTable.FrameShake = Plater:CreateFrameShake (unitFrame, scriptTable.config.shakeDuration, scriptTable.config.shakeAmplitude, scriptTable.config.shakeFrequency, false, false, 0, 1, 0.05, 0.1, Plater.GetPoints (unitFrame))\n    \n    --create a texture to use for a flash behind the cast bar\n    local backGroundFlashTexture = Plater:CreateImage (self, [[Interface\\ACHIEVEMENTFRAME\\UI-Achievement-Alert-Glow]], self:GetWidth()+60, self:GetHeight()+50, \"background\", {0, 400/512, 0, 170/256})\n    backGroundFlashTexture:SetBlendMode (\"ADD\")\n    backGroundFlashTexture:SetDrawLayer(\"OVERLAY\", 7)\n    backGroundFlashTexture:SetPoint (\"center\", self, \"center\")\n    backGroundFlashTexture:Hide()\n    \n    --create the animation hub to hold the flash animation sequence\n    envTable.BackgroundFlash = envTable.BackgroundFlash or Plater:CreateAnimationHub (backGroundFlashTexture, \n        function()\n            backGroundFlashTexture:Show()\n        end,\n        function()\n            backGroundFlashTexture:Hide()\n        end\n    )\n    \n    --create the flash animation sequence\n    envTable.BackgroundFlash.fadeIn = envTable.BackgroundFlash.fadeIn or Plater:CreateAnimation (envTable.BackgroundFlash, \"ALPHA\", 1, CONFIG_BACKGROUND_FLASH_DURATION/2, 0, .75)\n    envTable.BackgroundFlash.fadeIn:SetDuration(CONFIG_BACKGROUND_FLASH_DURATION/2)\n    \n    envTable.BackgroundFlash.fadeOut = envTable.BackgroundFlash.fadeOut or Plater:CreateAnimation (envTable.BackgroundFlash, \"ALPHA\", 2, CONFIG_BACKGROUND_FLASH_DURATION/2, 1, 0)    \n    envTable.BackgroundFlash.fadeOut:SetDuration(CONFIG_BACKGROUND_FLASH_DURATION/2)\n    \n    --envTable.BackgroundFlash:Play() --envTable.BackgroundFlash:Stop()    \n    \n    \n    \n    \n    \nend\n\n\n",
      ["OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    --don't execute on battlegrounds and arenas\n    if (Plater.ZoneInstanceType == \"arena\" or Plater.ZoneInstanceType == \"pvp\") then\n        return\n    end    \n    \n    unitFrame.castBar:SetHeight (envTable._DefaultHeight)\n    \n    --stop the camera shake\n    unitFrame:StopFrameShake (envTable.FrameShake)\n    \n    envTable.FullBarFlash:Stop()\n    envTable.BackgroundFlash:Stop()\n    \n    unitFrame.castBar.Spark:SetHeight(unitFrame.castBar:GetHeight())\n    \nend\n\n\n\n\n\n",
      ["OptionsValues"] = {
      },
      ["Temp_OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    --don't execute on battlegrounds and arenas\n    if (Plater.ZoneInstanceType == \"arena\" or Plater.ZoneInstanceType == \"pvp\") then\n        return\n    end\n    \n    --play flash animations\n    envTable.FullBarFlash:Play()\n    \n    --envTable.currentHeight = unitFrame.castBar:GetHeight()\n    \n    --restoring the default size (not required since it already restore in the hide script)\n    if (envTable.OriginalHeight) then\n        self:SetHeight (envTable.OriginalHeight)\n    end\n    \n    --increase the cast bar size\n    local height = self:GetHeight()\n    envTable.OriginalHeight = height\n    \n    self:SetHeight (height + envTable.CastBarHeightAdd)\n    \n    Plater.SetCastBarBorderColor (self, 1, .2, .2, 0.4)\n    \n    unitFrame:PlayFrameShake (envTable.FrameShake)\n    \n    Plater.SetCastBarColorForScript(self, scriptTable.config.useCastbarColor, scriptTable.config.castBarColor, envTable)\n    \n    envTable.BackgroundFlash:Play()\n    \n    unitFrame.castBar.Spark:SetHeight(unitFrame.castBar:GetHeight())\n    \nend\n\n\n\n\n\n\n\n\n\n\n",
      ["ScriptType"] = 2,
      ["UpdateCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \nend\n\n\n",
      ["Time"] = 1699197242,
      ["Temp_OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    --don't execute on battlegrounds and arenas\n    if (Plater.ZoneInstanceType == \"arena\" or Plater.ZoneInstanceType == \"pvp\") then\n        return\n    end    \n    \n    unitFrame.castBar:SetHeight (envTable._DefaultHeight)\n    \n    --stop the camera shake\n    unitFrame:StopFrameShake (envTable.FrameShake)\n    \n    envTable.FullBarFlash:Stop()\n    envTable.BackgroundFlash:Stop()\n    \n    unitFrame.castBar.Spark:SetHeight(unitFrame.castBar:GetHeight())\n    \nend\n\n\n\n\n\n",
      ["url"] = "",
      ["Icon"] = "Interface\\AddOns\\Plater\\images\\cast_bar_quickflash.tga",
      ["OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    --don't execute on battlegrounds and arenas\n    if (Plater.ZoneInstanceType == \"arena\" or Plater.ZoneInstanceType == \"pvp\") then\n        return\n    end\n    \n    --play flash animations\n    envTable.FullBarFlash:Play()\n    \n    --envTable.currentHeight = unitFrame.castBar:GetHeight()\n    \n    --restoring the default size (not required since it already restore in the hide script)\n    if (envTable.OriginalHeight) then\n        self:SetHeight (envTable.OriginalHeight)\n    end\n    \n    --increase the cast bar size\n    local height = self:GetHeight()\n    envTable.OriginalHeight = height\n    \n    self:SetHeight (height + envTable.CastBarHeightAdd)\n    \n    Plater.SetCastBarBorderColor (self, 1, .2, .2, 0.4)\n    \n    unitFrame:PlayFrameShake (envTable.FrameShake)\n    \n    Plater.SetCastBarColorForScript(self, scriptTable.config.useCastbarColor, scriptTable.config.castBarColor, envTable)\n    \n    envTable.BackgroundFlash:Play()\n    \n    unitFrame.castBar.Spark:SetHeight(unitFrame.castBar:GetHeight())\n    \nend\n\n\n\n\n\n\n\n\n\n\n",
      ["Enabled"] = false,
      ["Revision"] = 893,
      ["Options"] = {
        {
          ["Type"] = 6,
          ["Key"] = "option1",
          ["Value"] = 0,
          ["Name"] = "Blank Line",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [1]
        {
          ["Type"] = 5,
          ["Key"] = "option2",
          ["Value"] = "Produces a notable but fast effect in the cast bar when a spell from the 'Triggers' starts to cast.",
          ["Name"] = "Option 2",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_label",
          ["Desc"] = "",
        }, -- [2]
        {
          ["Type"] = 5,
          ["Key"] = "option3",
          ["Value"] = "Enter the spell name or spellID of the Spell in the Add Trigger box and hit \"Add\".",
          ["Name"] = "Option 3",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_label",
          ["Desc"] = "",
        }, -- [3]
        {
          ["Type"] = 6,
          ["Key"] = "option4",
          ["Value"] = 0,
          ["Name"] = "Blank Space",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [4]
        {
          ["Type"] = 4,
          ["Key"] = "useCastbarColor",
          ["Value"] = true,
          ["Name"] = "Cast Bar Color Enabled",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_bool",
          ["Desc"] = "When enabled, changes the cast bar color,",
        }, -- [5]
        {
          ["Type"] = 1,
          ["Key"] = "castBarColor",
          ["Value"] = {
            1, -- [1]
            0.43137254901961, -- [2]
            0, -- [3]
            1, -- [4]
          },
          ["Name"] = "Cast Bar Color",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
          ["Desc"] = "Color of the cast bar.",
        }, -- [6]
        {
          ["Type"] = 6,
          ["Key"] = "option7",
          ["Value"] = 0,
          ["Name"] = "Blank Line",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [7]
        {
          ["Type"] = 2,
          ["Max"] = 1,
          ["Desc"] = "When the cast starts it flash rapidly, adjust how fast it flashes. Value is milliseconds.",
          ["Min"] = 0.05,
          ["Key"] = "flashDuration",
          ["Value"] = 0.2,
          ["Fraction"] = true,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Flash Duration",
        }, -- [8]
        {
          ["Type"] = 2,
          ["Max"] = 10,
          ["Desc"] = "Increases the cast bar height by this value",
          ["Min"] = 0,
          ["Key"] = "castBarHeight",
          ["Value"] = 0,
          ["Fraction"] = false,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Cast Bar Height Mod",
        }, -- [9]
        {
          ["Type"] = 2,
          ["Max"] = 1,
          ["Desc"] = "When the cast starts, there's a small shake in the nameplate, this settings controls how long it takes.",
          ["Min"] = 0.1,
          ["Key"] = "shakeDuration",
          ["Value"] = 0.1,
          ["Fraction"] = true,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Shake Duration",
        }, -- [10]
        {
          ["Type"] = 2,
          ["Max"] = 200,
          ["Desc"] = "How strong is the shake.",
          ["Min"] = 10,
          ["Key"] = "shakeAmplitude",
          ["Value"] = 25,
          ["Fraction"] = false,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Shake Amplitude",
        }, -- [11]
        {
          ["Type"] = 2,
          ["Max"] = 80,
          ["Desc"] = "How fast the shake moves.",
          ["Min"] = 1,
          ["Key"] = "shakeFrequency",
          ["Value"] = 30,
          ["Fraction"] = false,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Shake Frequency",
        }, -- [12]
      },
      ["Name"] = "Cast - Quick Flash [P]",
      ["Prio"] = 99,
      ["Author"] = "Tercioo-Sylvanas",
      ["Initialization"] = "function (scriptTable)\n    --insert code here\n    \nend",
      ["Desc"] = "Play a very fast flash when the cast start",
      ["SpellIds"] = {
        392640, -- [1]
        397888, -- [2]
        381517, -- [3]
        385568, -- [4]
        209033, -- [5]
        385029, -- [6]
        374563, -- [7]
        377341, -- [8]
        369675, -- [9]
        369365, -- [10]
        369411, -- [11]
        278961, -- [12]
        202108, -- [13]
        88186, -- [14]
      },
      ["Temp_UpdateCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \nend\n\n\n",
      ["version"] = -1,
      ["PlaterCore"] = 1,
      ["NpcNames"] = {
      },
      ["Temp_ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    --castbar color (when can be interrupted)\n    envTable.CastbarColor = scriptTable.config.castbarColor\n    \n    --flash duration\n    local CONFIG_BACKGROUND_FLASH_DURATION = scriptTable.config.flashDuration\n    \n    --add this value to the cast bar height\n    envTable.CastBarHeightAdd = scriptTable.config.castBarHeight\n    \n    --create a fast flash above the cast bar\n    envTable.FullBarFlash = envTable.FullBarFlash or Plater.CreateFlash (self, 0.05, 1, \"white\")\n    \n    --create a camera shake for the nameplate\n    envTable.FrameShake = Plater:CreateFrameShake (unitFrame, scriptTable.config.shakeDuration, scriptTable.config.shakeAmplitude, scriptTable.config.shakeFrequency, false, false, 0, 1, 0.05, 0.1, Plater.GetPoints (unitFrame))\n    \n    --create a texture to use for a flash behind the cast bar\n    local backGroundFlashTexture = Plater:CreateImage (self, [[Interface\\ACHIEVEMENTFRAME\\UI-Achievement-Alert-Glow]], self:GetWidth()+60, self:GetHeight()+50, \"background\", {0, 400/512, 0, 170/256})\n    backGroundFlashTexture:SetBlendMode (\"ADD\")\n    backGroundFlashTexture:SetDrawLayer(\"OVERLAY\", 7)\n    backGroundFlashTexture:SetPoint (\"center\", self, \"center\")\n    backGroundFlashTexture:Hide()\n    \n    --create the animation hub to hold the flash animation sequence\n    envTable.BackgroundFlash = envTable.BackgroundFlash or Plater:CreateAnimationHub (backGroundFlashTexture, \n        function()\n            backGroundFlashTexture:Show()\n        end,\n        function()\n            backGroundFlashTexture:Hide()\n        end\n    )\n    \n    --create the flash animation sequence\n    envTable.BackgroundFlash.fadeIn = envTable.BackgroundFlash.fadeIn or Plater:CreateAnimation (envTable.BackgroundFlash, \"ALPHA\", 1, CONFIG_BACKGROUND_FLASH_DURATION/2, 0, .75)\n    envTable.BackgroundFlash.fadeIn:SetDuration(CONFIG_BACKGROUND_FLASH_DURATION/2)\n    \n    envTable.BackgroundFlash.fadeOut = envTable.BackgroundFlash.fadeOut or Plater:CreateAnimation (envTable.BackgroundFlash, \"ALPHA\", 2, CONFIG_BACKGROUND_FLASH_DURATION/2, 1, 0)    \n    envTable.BackgroundFlash.fadeOut:SetDuration(CONFIG_BACKGROUND_FLASH_DURATION/2)\n    \n    --envTable.BackgroundFlash:Play() --envTable.BackgroundFlash:Stop()    \n    \n    \n    \n    \n    \nend\n\n\n",
      ["semver"] = "",
      ["Temp_Initialization"] = "function (scriptTable)\n    --insert code here\n    \nend",
    }, -- [33]
    {
      ["ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    --insert code here\n    \nend\n\n\n--190187 draconic image\n--189893 infused whelp\n--99922 Ebonclaw Packmate\n--104822 flames of woe",
      ["OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    Plater.DenyColorChange(unitFrame, false)\n    unitFrame.onShowAddToKillFlash:Stop()\n    \nend\n\n\n",
      ["OptionsValues"] = {
        ["npcColor"] = {
          {
            "189893", -- [1]
            "olivedrab", -- [2]
          }, -- [1]
          {
            "190187", -- [1]
            "olivedrab", -- [2]
          }, -- [2]
          {
            "99922", -- [1]
            "olivedrab", -- [2]
          }, -- [3]
          {
            "153285", -- [1]
            "olivedrab", -- [2]
          }, -- [4]
          {
            "104822", -- [1]
            "olivedrab", -- [2]
          }, -- [5]
        },
      },
      ["Temp_OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    unitFrame.onShowAddToKillFlash = unitFrame.onShowAddToKillFlash or Plater.CreateFlash (unitFrame.healthBar, 0.25, 1, \"white\")\n    \n    if (scriptTable.config.useFlash) then\n        unitFrame.onShowAddToKillFlash:Play()\n    end\n    \n    if (scriptTable.config.useNameplateColor) then\n        local npcIdString = tostring(envTable._NpcID)\n        envTable.NameplateColor = Plater.GetColorByPriority(unitFrame, scriptTable.config.npcColor[npcIdString], scriptTable.config.healthBarColor)\n        Plater.DenyColorChange(unitFrame, true)\n    end\nend\n\n\n\n\n\n\n\n\n\n",
      ["ScriptType"] = 3,
      ["UpdateCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    if (scriptTable.config.useNameplateColor) then\n        Plater.SetNameplateColor(unitFrame, envTable.NameplateColor)\n    end\nend\n\n\n\n\n",
      ["Time"] = 1699197379,
      ["Temp_OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    Plater.DenyColorChange(unitFrame, false)\n    unitFrame.onShowAddToKillFlash:Stop()\n    \nend\n\n\n",
      ["url"] = "",
      ["Icon"] = "interface/addons/plater/media/exclamation_64",
      ["OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    unitFrame.onShowAddToKillFlash = unitFrame.onShowAddToKillFlash or Plater.CreateFlash (unitFrame.healthBar, 0.25, 1, \"white\")\n    \n    if (scriptTable.config.useFlash) then\n        unitFrame.onShowAddToKillFlash:Play()\n    end\n    \n    if (scriptTable.config.useNameplateColor) then\n        local npcIdString = tostring(envTable._NpcID)\n        envTable.NameplateColor = Plater.GetColorByPriority(unitFrame, scriptTable.config.npcColor[npcIdString], scriptTable.config.healthBarColor)\n        Plater.DenyColorChange(unitFrame, true)\n    end\nend\n\n\n\n\n\n\n\n\n\n",
      ["Enabled"] = false,
      ["Revision"] = 169,
      ["Options"] = {
        {
          ["Type"] = 4,
          ["Key"] = "useNameplateColor",
          ["Value"] = true,
          ["Name"] = "Change Nameplate Color",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_bool",
          ["Desc"] = "Change Nameplate Color",
        }, -- [1]
        {
          ["Type"] = 1,
          ["Key"] = "healthBarColor",
          ["Value"] = {
            1, -- [1]
            0.43921571969986, -- [2]
            0.4588235616684, -- [3]
            1, -- [4]
          },
          ["Name"] = "Nameplate Color",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
          ["Desc"] = "Nameplate Color",
        }, -- [2]
        {
          ["Type"] = 6,
          ["Key"] = "option5",
          ["Value"] = 0,
          ["Name"] = "Blank Space",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [3]
        {
          ["Type"] = 4,
          ["Key"] = "useFlash",
          ["Value"] = true,
          ["Name"] = "Flash Nameplate",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_bool",
          ["Desc"] = "Flash Nameplate",
        }, -- [4]
        {
          ["Type"] = 7,
          ["Key"] = "npcColor",
          ["Value"] = {
            {
              "189893", -- [1]
              "olivedrab", -- [2]
            }, -- [1]
            {
              "190187", -- [1]
              "olivedrab", -- [2]
            }, -- [2]
            {
              "99922", -- [1]
              "olivedrab", -- [2]
            }, -- [3]
            {
              "153285", -- [1]
              "olivedrab", -- [2]
            }, -- [4]
            {
              "104822", -- [1]
              "olivedrab", -- [2]
            }, -- [5]
          },
          ["Name"] = "NpcID to Color",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_list",
          ["Desc"] = "If the npc isn't on this list, use the default color set in the Health Bar Color",
        }, -- [5]
      },
      ["Name"] = "Add - Warning [P]",
      ["Prio"] = 99,
      ["Author"] = "Huugg-Valdrakken",
      ["Initialization"] = "function (scriptTable)\n    --insert code here\n    \nend\n\n\n",
      ["Desc"] = "Change the color of  add",
      ["SpellIds"] = {
      },
      ["Temp_UpdateCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    if (scriptTable.config.useNameplateColor) then\n        Plater.SetNameplateColor(unitFrame, envTable.NameplateColor)\n    end\nend\n\n\n\n\n",
      ["version"] = -1,
      ["PlaterCore"] = 1,
      ["NpcNames"] = {
        "190187", -- [1]
        "189893", -- [2]
        "99922", -- [3]
        "104822", -- [4]
        129758, -- [5]
        190426, -- [6]
        186696, -- [7]
        101075, -- [8]
        100818, -- [9]
        98081, -- [10]
        52019, -- [11]
      },
      ["Temp_ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    --insert code here\n    \nend\n\n\n--190187 draconic image\n--189893 infused whelp\n--99922 Ebonclaw Packmate\n--104822 flames of woe",
      ["semver"] = "",
      ["Temp_Initialization"] = "function (scriptTable)\n    --insert code here\n    \nend\n\n\n",
    }, -- [34]
    {
      ["ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    --insert code here\n    \nend\n\n\n\n--Scorchling 194622\n--Scorchling 190205\n--197398  Hungry Lasher\n--77006 corpse skitterling\n\n\n\n\n\n\n\n\n",
      ["OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    --restoring and color state and scale even if disabled, maybe the player disabled during the combat\n    Plater.DenyColorChange(unitFrame, false)\n    unitFrame.healthBar:SetScale(unitFrame.healthBar._savedOriginalScale)\n    \nend\n\n\n\n\n",
      ["OptionsValues"] = {
        ["useNameplateColor"] = false,
        ["nameplateColor"] = {
          1, -- [1]
          0, -- [2]
          0.2666666805744171, -- [3]
          1, -- [4]
        },
        ["useNameplateScale"] = true,
      },
      ["Temp_OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    if (scriptTable.config.useNameplateColor) then\n        envTable.NameplateColor = Plater.GetColorByPriority(unitFrame, scriptTable.config.nameplateColor)\n        Plater.DenyColorChange(unitFrame, true)\n    end    \n    \n    unitFrame.healthBar._savedOriginalScale = unitFrame.healthBar:GetScale()\n    \n    if (scriptTable.config.useNameplateScale) then\n        unitFrame.healthBar:SetScale(scriptTable.config.scale)\n    end\n    \nend\n\n\n\n\n",
      ["ScriptType"] = 3,
      ["UpdateCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    if (scriptTable.config.useNameplateColor) then\n        Plater.SetNameplateColor (unitFrame, envTable.NameplateColor)\n    end\n    \nend\n\n\n",
      ["Time"] = 1699197371,
      ["Temp_OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    --restoring and color state and scale even if disabled, maybe the player disabled during the combat\n    Plater.DenyColorChange(unitFrame, false)\n    unitFrame.healthBar:SetScale(unitFrame.healthBar._savedOriginalScale)\n    \nend\n\n\n\n\n",
      ["url"] = "",
      ["Icon"] = "interface/addons/plater/media/duck_64",
      ["OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    if (scriptTable.config.useNameplateColor) then\n        envTable.NameplateColor = Plater.GetColorByPriority(unitFrame, scriptTable.config.nameplateColor)\n        Plater.DenyColorChange(unitFrame, true)\n    end    \n    \n    unitFrame.healthBar._savedOriginalScale = unitFrame.healthBar:GetScale()\n    \n    if (scriptTable.config.useNameplateScale) then\n        unitFrame.healthBar:SetScale(scriptTable.config.scale)\n    end\n    \nend\n\n\n\n\n",
      ["Enabled"] = false,
      ["Revision"] = 128,
      ["Options"] = {
        {
          ["Type"] = 4,
          ["Key"] = "useNameplateColor",
          ["Value"] = false,
          ["Name"] = "Change Nameplate Color",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_bool",
          ["Desc"] = "Change Nameplate Color",
        }, -- [1]
        {
          ["Type"] = 1,
          ["Key"] = "nameplateColor",
          ["Value"] = {
            0.062745101749897, -- [1]
            0.062745101749897, -- [2]
            0.094117656350136, -- [3]
            1, -- [4]
          },
          ["Name"] = "Nameplate Color",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
          ["Desc"] = "Nameplate Color",
        }, -- [2]
        {
          ["Type"] = 6,
          ["Key"] = "option4",
          ["Value"] = 0,
          ["Name"] = "Option 4",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [3]
        {
          ["Type"] = 4,
          ["Key"] = "useNameplateScale",
          ["Value"] = true,
          ["Name"] = "Change Nameplate Scale",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_bool",
          ["Desc"] = "Change Nameplate Scale",
        }, -- [4]
        {
          ["Type"] = 2,
          ["Max"] = 1,
          ["Desc"] = "Nameplate Scale",
          ["Min"] = 0,
          ["Key"] = "scale",
          ["Value"] = 0.8,
          ["Fraction"] = true,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Nameplate Scale",
        }, -- [5]
      },
      ["Name"] = "Add - Non Elite Trash [P]",
      ["Prio"] = 99,
      ["Author"] = "Huugg-Valdrakken",
      ["Initialization"] = "function (scriptTable)\n    --insert code here\n    \nend\n\n\n",
      ["Desc"] = "",
      ["SpellIds"] = {
      },
      ["Temp_UpdateCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    if (scriptTable.config.useNameplateColor) then\n        Plater.SetNameplateColor (unitFrame, envTable.NameplateColor)\n    end\n    \nend\n\n\n",
      ["version"] = -1,
      ["PlaterCore"] = 1,
      ["NpcNames"] = {
        "194622", -- [1]
        "190205", -- [2]
        "197398", -- [3]
        "77006", -- [4]
      },
      ["Temp_ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    --insert code here\n    \nend\n\n\n\n--Scorchling 194622\n--Scorchling 190205\n--197398  Hungry Lasher\n--77006 corpse skitterling\n\n\n\n\n\n\n\n\n",
      ["semver"] = "",
      ["Temp_Initialization"] = "function (scriptTable)\n    --insert code here\n    \nend\n\n\n",
    }, -- [35]
    {
      ["ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    --insert code here\n    \n    local healthBar = unitFrame.healthBar\n    \n    if (not healthBar.absorbBar) then\n        healthBar.absorbBar = healthBar.FrameOverlay:CreateTexture(nil, \"overlay\")\n        healthBar.absorbBar:SetTexture([[Interface\\RaidFrame\\Shield-Fill]])\n        healthBar.absorbBar:Hide()\n    end\n    \n    if (not healthBar.absorbSpark) then\n        healthBar.absorbSpark = healthBar.FrameOverlay:CreateTexture(nil, \"overlay\")\n        healthBar.absorbSpark:SetTexture([[Interface\\CastingBar\\UI-CastingBar-Spark]])\n        healthBar.absorbSpark:SetBlendMode(\"ADD\")\n        healthBar.absorbSpark:Hide()\n    end\n    \nend\n\n\n\n\n",
      ["OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    if (not UnitGetTotalAbsorbs) then\n        return\n    end\n    \n    local healthBar = unitFrame.healthBar\n    \n    healthBar.absorbBar:Hide()    \n    healthBar.absorbSpark:Hide()\n    \nend\n\n\n",
      ["OptionsValues"] = {
      },
      ["Temp_OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    if (not UnitGetTotalAbsorbs) then\n        return\n    end\n    \n    local healthBar = unitFrame.healthBar\n    \n    healthBar.absorbBar:Show()\n    healthBar.absorbSpark:Show()\n    \n    healthBar.absorbBar:SetTexture([[Interface\\RaidFrame\\Shield-Fill]])\n    \n    healthBar.absorbBar:ClearAllPoints()    \n    healthBar.absorbBar:SetPoint(\"topleft\", healthBar, \"topleft\", 0, 0)\n    healthBar.absorbBar:SetPoint(\"bottomleft\", healthBar, \"bottomleft\", 0, 0)\n    \n    healthBar.absorbBar:SetAlpha(1)\n    \n    healthBar.absorbBar.MaxValue = UnitGetTotalAbsorbs(unitId) or 0\n    healthBar.absorbBar.MinValue = 0\nend\n\n\n",
      ["ScriptType"] = 2,
      ["UpdateCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    if (not UnitGetTotalAbsorbs) then\n        return\n    end\n    \n    local healthBar = unitFrame.healthBar\n    \n    healthBar.absorbBar:Show()\n    healthBar.absorbSpark:Show()\n    \n    local maxValue = healthBar.absorbBar.MaxValue\n    local currentValue = UnitGetTotalAbsorbs(unitId) or 0\n    \n    if (currentValue > 0) then\n        local minValue = 0\n        \n        local percent = currentValue / maxValue\n        healthBar.absorbBar:SetTexCoord(0, percent, 0, 1)\n        healthBar.absorbBar:SetWidth(percent * healthBar:GetWidth())\n        \n        healthBar.absorbSpark:SetPoint(\"left\", healthBar, \"left\", percent * healthBar:GetWidth() - 16, 0)\n        \n    else\n        healthBar.absorbBar:Hide()    \n        healthBar.absorbSpark:Hide()\n    end\n    \n    self.ThrottleUpdate = 0\n    \nend\n\n\n\n\n\n\n\n\n\n\n",
      ["Time"] = 1699197243,
      ["Temp_OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    if (not UnitGetTotalAbsorbs) then\n        return\n    end\n    \n    local healthBar = unitFrame.healthBar\n    \n    healthBar.absorbBar:Hide()    \n    healthBar.absorbSpark:Hide()\n    \nend\n\n\n",
      ["url"] = "",
      ["Icon"] = "interface/addons/plater/images/cast_bar - absorb",
      ["OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    if (not UnitGetTotalAbsorbs) then\n        return\n    end\n    \n    local healthBar = unitFrame.healthBar\n    \n    healthBar.absorbBar:Show()\n    healthBar.absorbSpark:Show()\n    \n    healthBar.absorbBar:SetTexture([[Interface\\RaidFrame\\Shield-Fill]])\n    \n    healthBar.absorbBar:ClearAllPoints()    \n    healthBar.absorbBar:SetPoint(\"topleft\", healthBar, \"topleft\", 0, 0)\n    healthBar.absorbBar:SetPoint(\"bottomleft\", healthBar, \"bottomleft\", 0, 0)\n    \n    healthBar.absorbBar:SetAlpha(1)\n    \n    healthBar.absorbBar.MaxValue = UnitGetTotalAbsorbs(unitId) or 0\n    healthBar.absorbBar.MinValue = 0\nend\n\n\n",
      ["Enabled"] = false,
      ["Revision"] = 109,
      ["Options"] = {
      },
      ["Name"] = "Cast - Shield Interrupt [P]",
      ["Prio"] = 99,
      ["Author"] = "Huugg-Valdrakken",
      ["Initialization"] = "function (scriptTable)\n    --insert code here\n    \nend\n\n\n",
      ["Desc"] = "When the caster has a shield and only when the shield is removed the cast can be interrupted",
      ["SpellIds"] = {
        373688, -- [1]
        391050, -- [2]
      },
      ["Temp_UpdateCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    if (not UnitGetTotalAbsorbs) then\n        return\n    end\n    \n    local healthBar = unitFrame.healthBar\n    \n    healthBar.absorbBar:Show()\n    healthBar.absorbSpark:Show()\n    \n    local maxValue = healthBar.absorbBar.MaxValue\n    local currentValue = UnitGetTotalAbsorbs(unitId) or 0\n    \n    if (currentValue > 0) then\n        local minValue = 0\n        \n        local percent = currentValue / maxValue\n        healthBar.absorbBar:SetTexCoord(0, percent, 0, 1)\n        healthBar.absorbBar:SetWidth(percent * healthBar:GetWidth())\n        \n        healthBar.absorbSpark:SetPoint(\"left\", healthBar, \"left\", percent * healthBar:GetWidth() - 16, 0)\n        \n    else\n        healthBar.absorbBar:Hide()    \n        healthBar.absorbSpark:Hide()\n    end\n    \n    self.ThrottleUpdate = 0\n    \nend\n\n\n\n\n\n\n\n\n\n\n",
      ["version"] = -1,
      ["PlaterCore"] = 1,
      ["NpcNames"] = {
      },
      ["Temp_ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    --insert code here\n    \n    local healthBar = unitFrame.healthBar\n    \n    if (not healthBar.absorbBar) then\n        healthBar.absorbBar = healthBar.FrameOverlay:CreateTexture(nil, \"overlay\")\n        healthBar.absorbBar:SetTexture([[Interface\\RaidFrame\\Shield-Fill]])\n        healthBar.absorbBar:Hide()\n    end\n    \n    if (not healthBar.absorbSpark) then\n        healthBar.absorbSpark = healthBar.FrameOverlay:CreateTexture(nil, \"overlay\")\n        healthBar.absorbSpark:SetTexture([[Interface\\CastingBar\\UI-CastingBar-Spark]])\n        healthBar.absorbSpark:SetBlendMode(\"ADD\")\n        healthBar.absorbSpark:Hide()\n    end\n    \nend\n\n\n\n\n",
      ["semver"] = "",
      ["Temp_Initialization"] = "function (scriptTable)\n    --insert code here\n    \nend\n\n\n",
    }, -- [36]
    {
      ["ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    local castBar = unitFrame.castBar\n    local castBarPortion = castBar:GetWidth()/scriptTable.config.segmentsAmount\n    local castBarHeight = castBar:GetHeight()\n    \n    unitFrame.felAnimation = unitFrame.felAnimation or {}\n    \n    if (not unitFrame.felAnimation.textureStretched) then\n        unitFrame.felAnimation.textureStretched = castBar:CreateTexture(nil, \"overlay\", nil, 5)\n    end\n    \n    if (not unitFrame.stopCastingX) then\n        unitFrame.stopCastingX = castBar.FrameOverlay:CreateTexture(nil, \"overlay\", nil, 7)\n        unitFrame.stopCastingX:SetPoint(\"center\", unitFrame.castBar.Spark, \"center\", 0, 0)\n        unitFrame.stopCastingX:SetTexture([[Interface\\AddOns\\Plater\\Media\\stop_64]])\n        unitFrame.stopCastingX:SetSize(16, 16)\n        unitFrame.stopCastingX:Hide()\n    end\n    \n    if (not unitFrame.felAnimation.Textures) then\n        unitFrame.felAnimation.Textures = {}\n        \n        for i = 1, 20 do\n            local texture = castBar:CreateTexture(nil, \"overlay\", nil, 6)\n            unitFrame.felAnimation.Textures[i] = texture            \n            \n            texture.animGroup = texture.animGroup or texture:CreateAnimationGroup()\n            local animationGroup = texture.animGroup\n            animationGroup:SetToFinalAlpha(true)            \n            animationGroup:SetLooping(\"NONE\")\n            \n            texture:SetTexture([[Interface\\COMMON\\XPBarAnim]])\n            texture:SetTexCoord(0.2990, 0.0010, 0.0010, 0.4159)\n            texture:SetBlendMode(\"ADD\")\n            \n            texture.scale = animationGroup:CreateAnimation(\"SCALE\")\n            texture.scale:SetTarget(texture)\n            \n            texture.alpha = animationGroup:CreateAnimation(\"ALPHA\")\n            texture.alpha:SetTarget(texture)\n            \n            texture.alpha2 = animationGroup:CreateAnimation(\"ALPHA\")\n            texture.alpha2:SetTarget(texture)\n        end\n    end\n    \n    \n    \nend\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n",
      ["OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    for i = 1, scriptTable.config.segmentsAmount  do\n        local texture = unitFrame.felAnimation.Textures[i]\n        texture:Hide()\n    end\n    \n    local textureStretched = unitFrame.felAnimation.textureStretched\n    textureStretched:Hide()    \n    unitFrame.stopCastingX:Hide()\n    \n    self.Text:SetDrawLayer(\"overlay\", 0)\n    self.Spark:SetDrawLayer(\"overlay\", 3)\n    self.Spark:Show()\n    \nend\n\n\n\n\n\n\n",
      ["OptionsValues"] = {
      },
      ["Temp_OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    local castBar = unitFrame.castBar\n    envTable.castBarWidth = castBar:GetWidth()\n    castBar.Spark:SetVertexColor(DetailsFramework:ParseColors(scriptTable.config.sparkColor))\n    \n    local textureStretched = unitFrame.felAnimation.textureStretched\n    textureStretched:Show()\n    textureStretched:SetVertexColor(DetailsFramework:ParseColors(scriptTable.config.glowColor))\n    textureStretched:SetAtlas(\"XPBarAnim-OrangeTrail\")\n    textureStretched:ClearAllPoints()\n    textureStretched:SetPoint(\"right\", castBar.Spark, \"center\", 0, 0)\n    textureStretched:SetHeight(castBar:GetHeight())\n    textureStretched:SetBlendMode(\"ADD\") \n    textureStretched:SetAlpha(0.5)\n    textureStretched:SetDrawLayer(\"overlay\", 7)\n    \n    for i = 1, scriptTable.config.segmentsAmount  do\n        local texture = unitFrame.felAnimation.Textures[i]\n        texture:SetVertexColor(1, 1, 1, 1)\n        texture:SetDesaturated(true)\n        \n        local castBarPortion = castBar:GetWidth()/scriptTable.config.segmentsAmount\n        \n        texture:SetSize(castBarPortion+5, castBar:GetHeight())\n        texture:SetDrawLayer(\"overlay\", 6)\n        \n        texture:ClearAllPoints()\n        if (i == scriptTable.config.segmentsAmount) then\n            texture:SetPoint(\"right\", castBar, \"right\", 0, 0)\n        else\n            texture:SetPoint(\"left\", castBar, \"left\", (i-1)*castBarPortion, 2)\n        end\n        \n        texture:SetAlpha(0)\n        texture:Hide()\n        \n        texture.scale:SetOrder(1)\n        texture.scale:SetDuration(0.5)\n        texture.scale:SetScaleFrom(0.2, 1)\n        texture.scale:SetScaleTo(1, 1.5)\n        texture.scale:SetOrigin(\"right\", 0, 0)\n        \n        local durationTime = DetailsFramework:GetBezierPoint(i / scriptTable.config.segmentsAmount, 0.2, 0.01, 0.6)\n        local duration = abs(durationTime-0.6)\n        --local duration = 0.6 --debug\n        \n        texture.alpha:SetOrder(1)\n        texture.alpha:SetDuration(0.05)\n        texture.alpha:SetFromAlpha(0)\n        texture.alpha:SetToAlpha(0.4)\n        \n        texture.alpha2:SetOrder(1)\n        texture.alpha2:SetDuration(duration) --0.6\n        texture.alpha2:SetStartDelay(duration)\n        texture.alpha2:SetFromAlpha(0.5)\n        texture.alpha2:SetToAlpha(0)\n    end\n    \n    unitFrame.stopCastingX:Show()\n    \n    envTable.CurrentTexture = 1\n    envTable.NextPercent  = 100  / scriptTable.config.segmentsAmount\n    \n    self.Text:SetDrawLayer(\"artwork\", 7)\n    self.Spark:SetDrawLayer(\"artwork\", 7)\n    self.Spark:Hide()\nend\n\n\n\n\n\n\n\n\n",
      ["ScriptType"] = 2,
      ["UpdateCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    local castBar = unitFrame.castBar\n    local textures = unitFrame.felAnimation.Textures\n    \n    if (envTable._CastPercent > envTable.NextPercent) then\n        local nextPercent = 100 / scriptTable.config.segmentsAmount\n        \n        textures[envTable.CurrentTexture]:Show()\n        textures[envTable.CurrentTexture].animGroup:Play()\n        \n        envTable.NextPercent = envTable.NextPercent + nextPercent \n        envTable.CurrentTexture = envTable.CurrentTexture + 1\n        \n        --print(envTable.NextPercent, envTable.CurrentTexture)\n        \n        if (envTable.CurrentTexture == #textures) then\n            envTable.NextPercent = 98\n        elseif (envTable.CurrentTexture > #textures) then\n            envTable.NextPercent = 999\n        end\n    end\n    \n    local normalizedPercent = envTable._CastPercent / 100\n    local textureStretched = unitFrame.felAnimation.textureStretched\n    local point = DetailsFramework:GetBezierPoint(normalizedPercent, 0, 0.001, 1)\n    textureStretched:SetPoint(\"left\", castBar, \"left\", point * envTable.castBarWidth, 0)\n    \n    self.ThrottleUpdate = 0\nend",
      ["Time"] = 1699197248,
      ["Temp_OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    for i = 1, scriptTable.config.segmentsAmount  do\n        local texture = unitFrame.felAnimation.Textures[i]\n        texture:Hide()\n    end\n    \n    local textureStretched = unitFrame.felAnimation.textureStretched\n    textureStretched:Hide()    \n    unitFrame.stopCastingX:Hide()\n    \n    self.Text:SetDrawLayer(\"overlay\", 0)\n    self.Spark:SetDrawLayer(\"overlay\", 3)\n    self.Spark:Show()\n    \nend\n\n\n\n\n\n\n",
      ["url"] = "",
      ["Icon"] = "Interface\\AddOns\\Plater\\media\\stop_64",
      ["OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    local castBar = unitFrame.castBar\n    envTable.castBarWidth = castBar:GetWidth()\n    castBar.Spark:SetVertexColor(DetailsFramework:ParseColors(scriptTable.config.sparkColor))\n    \n    local textureStretched = unitFrame.felAnimation.textureStretched\n    textureStretched:Show()\n    textureStretched:SetVertexColor(DetailsFramework:ParseColors(scriptTable.config.glowColor))\n    textureStretched:SetAtlas(\"XPBarAnim-OrangeTrail\")\n    textureStretched:ClearAllPoints()\n    textureStretched:SetPoint(\"right\", castBar.Spark, \"center\", 0, 0)\n    textureStretched:SetHeight(castBar:GetHeight())\n    textureStretched:SetBlendMode(\"ADD\") \n    textureStretched:SetAlpha(0.5)\n    textureStretched:SetDrawLayer(\"overlay\", 7)\n    \n    for i = 1, scriptTable.config.segmentsAmount  do\n        local texture = unitFrame.felAnimation.Textures[i]\n        texture:SetVertexColor(1, 1, 1, 1)\n        texture:SetDesaturated(true)\n        \n        local castBarPortion = castBar:GetWidth()/scriptTable.config.segmentsAmount\n        \n        texture:SetSize(castBarPortion+5, castBar:GetHeight())\n        texture:SetDrawLayer(\"overlay\", 6)\n        \n        texture:ClearAllPoints()\n        if (i == scriptTable.config.segmentsAmount) then\n            texture:SetPoint(\"right\", castBar, \"right\", 0, 0)\n        else\n            texture:SetPoint(\"left\", castBar, \"left\", (i-1)*castBarPortion, 2)\n        end\n        \n        texture:SetAlpha(0)\n        texture:Hide()\n        \n        texture.scale:SetOrder(1)\n        texture.scale:SetDuration(0.5)\n        texture.scale:SetScaleFrom(0.2, 1)\n        texture.scale:SetScaleTo(1, 1.5)\n        texture.scale:SetOrigin(\"right\", 0, 0)\n        \n        local durationTime = DetailsFramework:GetBezierPoint(i / scriptTable.config.segmentsAmount, 0.2, 0.01, 0.6)\n        local duration = abs(durationTime-0.6)\n        --local duration = 0.6 --debug\n        \n        texture.alpha:SetOrder(1)\n        texture.alpha:SetDuration(0.05)\n        texture.alpha:SetFromAlpha(0)\n        texture.alpha:SetToAlpha(0.4)\n        \n        texture.alpha2:SetOrder(1)\n        texture.alpha2:SetDuration(duration) --0.6\n        texture.alpha2:SetStartDelay(duration)\n        texture.alpha2:SetFromAlpha(0.5)\n        texture.alpha2:SetToAlpha(0)\n    end\n    \n    unitFrame.stopCastingX:Show()\n    \n    envTable.CurrentTexture = 1\n    envTable.NextPercent  = 100  / scriptTable.config.segmentsAmount\n    \n    self.Text:SetDrawLayer(\"artwork\", 7)\n    self.Spark:SetDrawLayer(\"artwork\", 7)\n    self.Spark:Hide()\nend\n\n\n\n\n\n\n\n\n",
      ["Enabled"] = false,
      ["Revision"] = 509,
      ["Options"] = {
        {
          ["Type"] = 2,
          ["Max"] = 20,
          ["Desc"] = "Need a /reload",
          ["Min"] = 5,
          ["Key"] = "segmentsAmount",
          ["Value"] = 20,
          ["Fraction"] = false,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Amount of Segments",
        }, -- [1]
        {
          ["Type"] = 1,
          ["Key"] = "sparkColor",
          ["Value"] = {
            0.95686274509804, -- [1]
            1, -- [2]
            0.98823529411765, -- [3]
            1, -- [4]
          },
          ["Name"] = "Spark Color",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
          ["Desc"] = "",
        }, -- [2]
        {
          ["Type"] = 1,
          ["Key"] = "glowColor",
          ["Value"] = {
            0.85882352941176, -- [1]
            0.43137254901961, -- [2]
            1, -- [3]
            1, -- [4]
          },
          ["Name"] = "Glow Color",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
          ["Desc"] = "",
        }, -- [3]
      },
      ["Name"] = "Cast - Stop Casting [P]",
      ["Prio"] = 99,
      ["Author"] = "Terciob",
      ["Initialization"] = "function (scriptTable)\n    --insert code here\n    \nend\n\n\n",
      ["Desc"] = "Just stop casting",
      ["SpellIds"] = {
        377004, -- [1]
        381516, -- [2]
        196543, -- [3]
        199726, -- [4]
      },
      ["Temp_UpdateCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    local castBar = unitFrame.castBar\n    local textures = unitFrame.felAnimation.Textures\n    \n    if (envTable._CastPercent > envTable.NextPercent) then\n        local nextPercent = 100 / scriptTable.config.segmentsAmount\n        \n        textures[envTable.CurrentTexture]:Show()\n        textures[envTable.CurrentTexture].animGroup:Play()\n        \n        envTable.NextPercent = envTable.NextPercent + nextPercent \n        envTable.CurrentTexture = envTable.CurrentTexture + 1\n        \n        --print(envTable.NextPercent, envTable.CurrentTexture)\n        \n        if (envTable.CurrentTexture == #textures) then\n            envTable.NextPercent = 98\n        elseif (envTable.CurrentTexture > #textures) then\n            envTable.NextPercent = 999\n        end\n    end\n    \n    local normalizedPercent = envTable._CastPercent / 100\n    local textureStretched = unitFrame.felAnimation.textureStretched\n    local point = DetailsFramework:GetBezierPoint(normalizedPercent, 0, 0.001, 1)\n    textureStretched:SetPoint(\"left\", castBar, \"left\", point * envTable.castBarWidth, 0)\n    \n    self.ThrottleUpdate = 0\nend",
      ["version"] = -1,
      ["PlaterCore"] = 1,
      ["NpcNames"] = {
      },
      ["Temp_ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    local castBar = unitFrame.castBar\n    local castBarPortion = castBar:GetWidth()/scriptTable.config.segmentsAmount\n    local castBarHeight = castBar:GetHeight()\n    \n    unitFrame.felAnimation = unitFrame.felAnimation or {}\n    \n    if (not unitFrame.felAnimation.textureStretched) then\n        unitFrame.felAnimation.textureStretched = castBar:CreateTexture(nil, \"overlay\", nil, 5)\n    end\n    \n    if (not unitFrame.stopCastingX) then\n        unitFrame.stopCastingX = castBar.FrameOverlay:CreateTexture(nil, \"overlay\", nil, 7)\n        unitFrame.stopCastingX:SetPoint(\"center\", unitFrame.castBar.Spark, \"center\", 0, 0)\n        unitFrame.stopCastingX:SetTexture([[Interface\\AddOns\\Plater\\Media\\stop_64]])\n        unitFrame.stopCastingX:SetSize(16, 16)\n        unitFrame.stopCastingX:Hide()\n    end\n    \n    if (not unitFrame.felAnimation.Textures) then\n        unitFrame.felAnimation.Textures = {}\n        \n        for i = 1, 20 do\n            local texture = castBar:CreateTexture(nil, \"overlay\", nil, 6)\n            unitFrame.felAnimation.Textures[i] = texture            \n            \n            texture.animGroup = texture.animGroup or texture:CreateAnimationGroup()\n            local animationGroup = texture.animGroup\n            animationGroup:SetToFinalAlpha(true)            \n            animationGroup:SetLooping(\"NONE\")\n            \n            texture:SetTexture([[Interface\\COMMON\\XPBarAnim]])\n            texture:SetTexCoord(0.2990, 0.0010, 0.0010, 0.4159)\n            texture:SetBlendMode(\"ADD\")\n            \n            texture.scale = animationGroup:CreateAnimation(\"SCALE\")\n            texture.scale:SetTarget(texture)\n            \n            texture.alpha = animationGroup:CreateAnimation(\"ALPHA\")\n            texture.alpha:SetTarget(texture)\n            \n            texture.alpha2 = animationGroup:CreateAnimation(\"ALPHA\")\n            texture.alpha2:SetTarget(texture)\n        end\n    end\n    \n    \n    \nend\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n",
      ["semver"] = "",
      ["Temp_Initialization"] = "function (scriptTable)\n    --insert code here\n    \nend\n\n\n",
    }, -- [37]
    {
      ["ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    function envTable.CreateWidgets()\n        --create a camera shake for the nameplate\n        if (not unitFrame.AddExplosionOnDieShake) then\n            unitFrame.AddExplosionOnDieShake = Plater:CreateFrameShake (unitFrame, scriptTable.config.shakeDuration, scriptTable.config.shakeAmplitude, scriptTable.config.shakeFrequency, false, false, 0, 1, 0.05, 0.1, Plater.GetPoints (unitFrame))\n        end\n        \n        if (not unitFrame.AddExplosionOnDieBackground) then\n            unitFrame.AddExplosionOnDieBackground = unitFrame.healthBar:CreateTexture(nil, \"background\")\n            unitFrame.AddExplosionOnDieBackground:SetAllPoints(unitFrame.healthBar)\n            unitFrame.AddExplosionOnDieBackground:SetColorTexture(1, 0, 0, 1)\n        end\n    end\n    \nend\n\n--194895 = unstable squall\n--105703 = mana wyrm\n--59598 = lesser sha\n--58319 = lesser sha\n\n\n\n\n\n\n\n\n\n\n\n",
      ["OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    --insert code here\n    \n    local healthBar = unitFrame.healthBar\n    healthBar:SetReverseFill(false)\n    \n    if (unitFrame.AddExplosionOnDieShake) then\n        unitFrame:StopFrameShake (unitFrame.AddExplosionOnDieShake)    \n    end\n    \n    if (unitFrame.AddExplosionOnDieBackground) then\n        unitFrame.AddExplosionOnDieBackground:Hide()\n    end\nend\n\n\n\n\n\n\n\n\n",
      ["OptionsValues"] = {
        ["useBackground"] = false,
      },
      ["Temp_OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    --insert code here\n    \n    local healthBar = unitFrame.healthBar\n    \n    if (scriptTable.config.useReverse) then\n        healthBar:SetReverseFill(true)\n    end\n    \n    --unitFrame.AddExplosionOnDieShake\n    \n    envTable.CreateWidgets()\n    \n    unitFrame.AddExplosionOnDieShake.OriginalAmplitude = scriptTable.config.shakeAmplitude\n    unitFrame.AddExplosionOnDieShake.OriginalDuration = 0.120\n    unitFrame.AddExplosionOnDieShake.OriginalFrequency = scriptTable.config.shakeFrequency\n    \n    if (scriptTable.config.useBackground) then\n        unitFrame.AddExplosionOnDieBackground:Show()\n        unitFrame.AddExplosionOnDieBackground:SetAlpha(0)\n    else\n        unitFrame.AddExplosionOnDieBackground:Hide()\n    end\nend\n\n\n\n\n\n\n",
      ["ScriptType"] = 3,
      ["UpdateCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    if (envTable._HealthPercent < 50) then\n        local alpha = DetailsFramework:MapRangeClamped(0, 50, 0.5, 0, envTable._HealthPercent)\n        \n        unitFrame.AddExplosionOnDieBackground:SetAlpha(alpha)\n    else\n        unitFrame.AddExplosionOnDieBackground:SetAlpha(0)\n    end\n    \n    if (envTable._HealthPercent < 15 and scriptTable.config.useShake) then\n        local shakeAmpliture = DetailsFramework:MapRangeClamped(0.001, 15, 10, 1, envTable._HealthPercent)\n        \n        unitFrame.AddExplosionOnDieShake.OriginalAmplitude = scriptTable.config.shakeAmplitude * shakeAmpliture\n        unitFrame.AddExplosionOnDieShake.OriginalFrequency = scriptTable.config.shakeFrequency\n        \n        unitFrame:PlayFrameShake (unitFrame.AddExplosionOnDieShake)\n    end\n    \n    \nend\n\n\n\n\n\n\n\n\n\n\n\n\n",
      ["Time"] = 1699197024,
      ["Temp_OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    --insert code here\n    \n    local healthBar = unitFrame.healthBar\n    healthBar:SetReverseFill(false)\n    \n    if (unitFrame.AddExplosionOnDieShake) then\n        unitFrame:StopFrameShake (unitFrame.AddExplosionOnDieShake)    \n    end\n    \n    if (unitFrame.AddExplosionOnDieBackground) then\n        unitFrame.AddExplosionOnDieBackground:Hide()\n    end\nend\n\n\n\n\n\n\n\n\n",
      ["url"] = "",
      ["Icon"] = "interface/addons/plater/media/radio_64",
      ["OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    --insert code here\n    \n    local healthBar = unitFrame.healthBar\n    \n    if (scriptTable.config.useReverse) then\n        healthBar:SetReverseFill(true)\n    end\n    \n    --unitFrame.AddExplosionOnDieShake\n    \n    envTable.CreateWidgets()\n    \n    unitFrame.AddExplosionOnDieShake.OriginalAmplitude = scriptTable.config.shakeAmplitude\n    unitFrame.AddExplosionOnDieShake.OriginalDuration = 0.120\n    unitFrame.AddExplosionOnDieShake.OriginalFrequency = scriptTable.config.shakeFrequency\n    \n    if (scriptTable.config.useBackground) then\n        unitFrame.AddExplosionOnDieBackground:Show()\n        unitFrame.AddExplosionOnDieBackground:SetAlpha(0)\n    else\n        unitFrame.AddExplosionOnDieBackground:Hide()\n    end\nend\n\n\n\n\n\n\n",
      ["Enabled"] = true,
      ["Revision"] = 112,
      ["Options"] = {
        {
          ["Type"] = 4,
          ["Key"] = "useReverse",
          ["Value"] = false,
          ["Name"] = "Reverse Health Bar",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_bool",
          ["Desc"] = "",
        }, -- [1]
        {
          ["Type"] = 6,
          ["Key"] = "option6",
          ["Value"] = 0,
          ["Name"] = "Option 6",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [2]
        {
          ["Type"] = 4,
          ["Key"] = "useShake",
          ["Value"] = false,
          ["Name"] = "Enable Shake",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_bool",
          ["Desc"] = "",
        }, -- [3]
        {
          ["Type"] = 2,
          ["Max"] = 1,
          ["Desc"] = "How strong is the shake.",
          ["Min"] = 0.05,
          ["Key"] = "shakeAmplitude",
          ["Value"] = 0.2,
          ["Fraction"] = true,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Shake Amplitude",
        }, -- [4]
        {
          ["Type"] = 2,
          ["Max"] = 80,
          ["Desc"] = "How fast the shake moves.",
          ["Min"] = 1,
          ["Key"] = "shakeFrequency",
          ["Value"] = 70,
          ["Fraction"] = true,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Shake Frequency",
        }, -- [5]
        {
          ["Type"] = 6,
          ["Key"] = "option7",
          ["Value"] = 0,
          ["Name"] = "Option 7",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [6]
        {
          ["Type"] = 4,
          ["Key"] = "useBackground",
          ["Value"] = true,
          ["Name"] = "Show Red Background",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_bool",
          ["Desc"] = "Show Red Background",
        }, -- [7]
      },
      ["Name"] = "Add - Explode on Die [P]",
      ["Prio"] = 99,
      ["Author"] = "Huugg-Valdrakken",
      ["Initialization"] = "function (scriptTable)\n    --insert code here\n    \nend\n\n\n",
      ["Desc"] = "",
      ["SpellIds"] = {
      },
      ["Temp_UpdateCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    if (envTable._HealthPercent < 50) then\n        local alpha = DetailsFramework:MapRangeClamped(0, 50, 0.5, 0, envTable._HealthPercent)\n        \n        unitFrame.AddExplosionOnDieBackground:SetAlpha(alpha)\n    else\n        unitFrame.AddExplosionOnDieBackground:SetAlpha(0)\n    end\n    \n    if (envTable._HealthPercent < 15 and scriptTable.config.useShake) then\n        local shakeAmpliture = DetailsFramework:MapRangeClamped(0.001, 15, 10, 1, envTable._HealthPercent)\n        \n        unitFrame.AddExplosionOnDieShake.OriginalAmplitude = scriptTable.config.shakeAmplitude * shakeAmpliture\n        unitFrame.AddExplosionOnDieShake.OriginalFrequency = scriptTable.config.shakeFrequency\n        \n        unitFrame:PlayFrameShake (unitFrame.AddExplosionOnDieShake)\n    end\n    \n    \nend\n\n\n\n\n\n\n\n\n\n\n\n\n",
      ["version"] = -1,
      ["PlaterCore"] = 1,
      ["NpcNames"] = {
        "194895", -- [1]
        "105703", -- [2]
        "59598", -- [3]
        "58319", -- [4]
        200388, -- [5]
        189299, -- [6]
        131402, -- [7]
      },
      ["Temp_ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    function envTable.CreateWidgets()\n        --create a camera shake for the nameplate\n        if (not unitFrame.AddExplosionOnDieShake) then\n            unitFrame.AddExplosionOnDieShake = Plater:CreateFrameShake (unitFrame, scriptTable.config.shakeDuration, scriptTable.config.shakeAmplitude, scriptTable.config.shakeFrequency, false, false, 0, 1, 0.05, 0.1, Plater.GetPoints (unitFrame))\n        end\n        \n        if (not unitFrame.AddExplosionOnDieBackground) then\n            unitFrame.AddExplosionOnDieBackground = unitFrame.healthBar:CreateTexture(nil, \"background\")\n            unitFrame.AddExplosionOnDieBackground:SetAllPoints(unitFrame.healthBar)\n            unitFrame.AddExplosionOnDieBackground:SetColorTexture(1, 0, 0, 1)\n        end\n    end\n    \nend\n\n--194895 = unstable squall\n--105703 = mana wyrm\n--59598 = lesser sha\n--58319 = lesser sha\n\n\n\n\n\n\n\n\n\n\n\n",
      ["semver"] = "",
      ["Temp_Initialization"] = "function (scriptTable)\n    --insert code here\n    \nend\n\n\n",
    }, -- [38]
    {
      ["ConstructorCode"] = "--todo: add npc ids for multilanguage support\n\nfunction (self, unitId, unitFrame, envTable, modTable)\n    \n    --settings\n    envTable.TextAboveNameplate = modTable.config[\"textAboveNameplate\"]\n    envTable.NameplateColor = modTable.config[\"nameplateColor\"]\n    \n    --label to show the text above the nameplate\n    envTable.FixateTarget = Plater:CreateLabel (unitFrame);\n    envTable.FixateTarget:SetPoint (\"bottom\", unitFrame.healthBar, \"top\", 0, 30);\n    \n    -- local spellList = {\n    --     [321891] = \"Freeze Tag Fixation\", --Illusionary Vulpin - MTS\n    --     [355389] = \"Relentless Haunt\",\n    --     [338610] = \"Morbid Fixation\",\n    --     [338606] = \"Morbid Fixation\",\n    --     [358711] = \"Rage\"\n    -- }\n    \n    local spellList = modTable.config[\"spellList\"];\n    \n    --build the list with localized spell names\n    envTable.FixateDebuffs = {}\n    for spellID, enUSSpellName in pairs (spellList) do\n        local localizedSpellName = GetSpellInfo (spellID)\n        envTable.FixateDebuffs [localizedSpellName or enUSSpellName] = true\n    end\n    \n    --debug - smuggled crawg\n    envTable.FixateDebuffs [\"Jagged Maw\"] = true\n    \nend\n\n--[=[\nNpcIDs:\n136461: Spawn of G'huun (mythic uldir G'huun)\n\n--]=]\n\n\n\n\n",
      ["OnHideCode"] = "function (self, unitId, unitFrame, envTable)\n    envTable.FixateTarget:SetText (\"\")\n    envTable.FixateTarget:Hide()\n    \n    envTable.IsFixated = false\n    \n    Plater.RefreshNameplateColor (unitFrame)\nend\n\n\n",
      ["OptionsValues"] = {
        ["spellList"] = {
          {
            "358711", -- [1]
            "Rage", -- [2]
          }, -- [1]
          {
            "338606", -- [1]
            "Morbid Fixation", -- [2]
          }, -- [2]
          {
            "338610", -- [1]
            "Morbid Fixation", -- [2]
          }, -- [3]
          {
            "355389", -- [1]
            "Relentless Haunt", -- [2]
          }, -- [4]
          {
            "321891", -- [1]
            "Freeze Tag Fixation", -- [2]
          }, -- [5]
        },
      },
      ["Temp_OnShowCode"] = "function (self, unitId, unitFrame, envTable, modTable)\n    \nend\n\n\n",
      ["ScriptType"] = 3,
      ["UpdateCode"] = "function (self, unitId, unitFrame, envTable)\n    \n    --swap this to true when it is fixated\n    local isFixated = false\n    \n    --check the debuffs the player has and see if any of these debuffs has been placed by this unit\n    for debuffId = 1, 40 do\n        local name, texture, count, debuffType, duration, expirationTime, caster = UnitDebuff (\"player\", debuffId)\n        \n        --cancel the loop if there's no more debuffs on the player\n        if (not name) then \n            break \n        end\n        \n        --check if the owner of the debuff is this unit\n        if (envTable.FixateDebuffs [name] and caster and UnitIsUnit (caster, unitId)) then\n            --the debuff the player has, has been placed by this unit, set the name above the unit name\n            envTable.FixateTarget:SetText (envTable.TextAboveNameplate)\n            envTable.FixateTarget:Show()\n            Plater.SetNameplateColor (unitFrame,  envTable.NameplateColor)\n            \n            isFixated = true\n            \n            if (not envTable.IsFixated) then\n                envTable.IsFixated = true\n                Plater.FlashNameplateBody (unitFrame, \"fixate\", .2)\n            end\n        end\n        \n    end\n    \n    --check if the nameplate color is changed but isn't fixated any more\n    if (not isFixated and envTable.IsFixated) then\n        --refresh the nameplate color\n        Plater.RefreshNameplateColor (unitFrame)\n        --reset the text\n        envTable.FixateTarget:SetText (\"\")\n        \n        envTable.IsFixated = false\n    end\n    \nend\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n",
      ["Time"] = 1674875766,
      ["Temp_OnHideCode"] = "function (self, unitId, unitFrame, envTable)\n    envTable.FixateTarget:SetText (\"\")\n    envTable.FixateTarget:Hide()\n    \n    envTable.IsFixated = false\n    \n    Plater.RefreshNameplateColor (unitFrame)\nend\n\n\n",
      ["url"] = "https://wago.io/6KIY-sN-q/1",
      ["Icon"] = 841383,
      ["OnShowCode"] = "function (self, unitId, unitFrame, envTable, modTable)\n    \nend\n\n\n",
      ["Enabled"] = true,
      ["Revision"] = 384,
      ["Options"] = {
        {
          ["Type"] = 1,
          ["Key"] = "nameplateColor",
          ["Value"] = {
            1, -- [1]
            0, -- [2]
            1, -- [3]
            1, -- [4]
          },
          ["Name"] = "Nameplate Color",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
          ["Desc"] = "The color you want to turn the nameplate.",
        }, -- [1]
        {
          ["Type"] = 3,
          ["Key"] = "textAboveNameplate",
          ["Value"] = "\"** On You **\"",
          ["Name"] = "Text Above Nameplate",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_text",
          ["Desc"] = "The text to be displayed above the nameplate.",
        }, -- [2]
        {
          ["Type"] = 7,
          ["Key"] = "spellList",
          ["Value"] = {
            {
              "358711", -- [1]
              "Rage", -- [2]
            }, -- [1]
            {
              "338606", -- [1]
              "Morbid Fixation", -- [2]
            }, -- [2]
            {
              "338610", -- [1]
              "Morbid Fixation", -- [2]
            }, -- [3]
            {
              "355389", -- [1]
              "Relentless Haunt", -- [2]
            }, -- [4]
            {
              "321891", -- [1]
              "Freeze Tag Fixation", -- [2]
            }, -- [5]
            {
              "370597", -- [1]
              "Kill Order", -- [2]
            }, -- [6]
          },
          ["Name"] = "Spell List",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_list",
          ["Desc"] = "The list of spells that will trigger the script. The key is the spell id and the value is the en-US name of the spell.",
        }, -- [3]
      },
      ["Name"] = "Fixate On You [Plater]",
      ["Prio"] = 99,
      ["Author"] = "Tecno-Azralon",
      ["Initialization"] = "function (scriptTable)\n    --insert code here\n    \nend\n\n\n",
      ["Desc"] = "When an enemy places a debuff and starts to chase you. This script changes the nameplate color and place your name above the nameplate as well.",
      ["SpellIds"] = {
        "spawn of g'huun", -- [1]
        "smuggled crawg", -- [2]
        "sergeant bainbridge", -- [3]
        "blacktooth scrapper", -- [4]
        "irontide grenadier", -- [5]
        "feral bloodswarmer", -- [6]
        "earthrager", -- [7]
        "crawler mine", -- [8]
        "rezan", -- [9]
      },
      ["Temp_UpdateCode"] = "function (self, unitId, unitFrame, envTable)\n    \n    --swap this to true when it is fixated\n    local isFixated = false\n    \n    --check the debuffs the player has and see if any of these debuffs has been placed by this unit\n    for debuffId = 1, 40 do\n        local name, texture, count, debuffType, duration, expirationTime, caster = UnitDebuff (\"player\", debuffId)\n        \n        --cancel the loop if there's no more debuffs on the player\n        if (not name) then \n            break \n        end\n        \n        --check if the owner of the debuff is this unit\n        if (envTable.FixateDebuffs [name] and caster and UnitIsUnit (caster, unitId)) then\n            --the debuff the player has, has been placed by this unit, set the name above the unit name\n            envTable.FixateTarget:SetText (envTable.TextAboveNameplate)\n            envTable.FixateTarget:Show()\n            Plater.SetNameplateColor (unitFrame,  envTable.NameplateColor)\n            \n            isFixated = true\n            \n            if (not envTable.IsFixated) then\n                envTable.IsFixated = true\n                Plater.FlashNameplateBody (unitFrame, \"fixate\", .2)\n            end\n        end\n        \n    end\n    \n    --check if the nameplate color is changed but isn't fixated any more\n    if (not isFixated and envTable.IsFixated) then\n        --refresh the nameplate color\n        Plater.RefreshNameplateColor (unitFrame)\n        --reset the text\n        envTable.FixateTarget:SetText (\"\")\n        \n        envTable.IsFixated = false\n    end\n    \nend\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n",
      ["version"] = 1,
      ["PlaterCore"] = 1,
      ["NpcNames"] = {
        "Frostbound Devoted", -- [1]
        "Illusionary Vulpin", -- [2]
        "Separation Assistant", -- [3]
        "Dark Sentinel", -- [4]
        "187638", -- [5]
        "Flamescale Tarasek", -- [6]
      },
      ["Temp_ConstructorCode"] = "--todo: add npc ids for multilanguage support\n\nfunction (self, unitId, unitFrame, envTable, modTable)\n    \n    --settings\n    envTable.TextAboveNameplate = modTable.config[\"textAboveNameplate\"]\n    envTable.NameplateColor = modTable.config[\"nameplateColor\"]\n    \n    --label to show the text above the nameplate\n    envTable.FixateTarget = Plater:CreateLabel (unitFrame);\n    envTable.FixateTarget:SetPoint (\"bottom\", unitFrame.healthBar, \"top\", 0, 30);\n    \n    -- local spellList = {\n    --     [321891] = \"Freeze Tag Fixation\", --Illusionary Vulpin - MTS\n    --     [355389] = \"Relentless Haunt\",\n    --     [338610] = \"Morbid Fixation\",\n    --     [338606] = \"Morbid Fixation\",\n    --     [358711] = \"Rage\"\n    -- }\n    \n    local spellList = modTable.config[\"spellList\"];\n    \n    --build the list with localized spell names\n    envTable.FixateDebuffs = {}\n    for spellID, enUSSpellName in pairs (spellList) do\n        local localizedSpellName = GetSpellInfo (spellID)\n        envTable.FixateDebuffs [localizedSpellName or enUSSpellName] = true\n    end\n    \n    --debug - smuggled crawg\n    envTable.FixateDebuffs [\"Jagged Maw\"] = true\n    \nend\n\n--[=[\nNpcIDs:\n136461: Spawn of G'huun (mythic uldir G'huun)\n\n--]=]\n\n\n\n\n",
      ["semver"] = "1.0.0",
      ["Temp_Initialization"] = "function (scriptTable)\n    --insert code here\n    \nend\n\n\n",
    }, -- [39]
    {
      ["ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    --insert code here\n    \n    local plateFrame = unitFrame.PlateFrame\n    \n    if (not plateFrame.BWC_RedBackground) then\n        plateFrame.BWC_RedBackground = plateFrame:CreateTexture(nil, \"background\")\n        plateFrame.BWC_RedBackground:SetAllPoints()\n    end\n    \n    plateFrame.BWC_RedBackground:SetTexture([[Interface/AddOns/Plater/masks/mask1]])\n    plateFrame.BWC_RedBackground:Hide()\n    \n    function envTable.ShowBackground(unitFrame)\n        local plateFrame = unitFrame.PlateFrame\n        plateFrame.BWC_RedBackground:SetVertexColor(1, 0, 0, 0.4)\n        plateFrame.BWC_RedBackground:Show()\n    end\n    \n    function envTable.HideBackground(unitFrame)\n        plateFrame.BWC_RedBackground:Hide()\n    end\nend\n\n\n\n\n\n\n",
      ["OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    --insert code here\n    envTable.HideBackground(unitFrame)\nend\n\n\n",
      ["OptionsValues"] = {
      },
      ["Temp_OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    --insert code here\n    \nend\n\n\n",
      ["ScriptType"] = 1,
      ["UpdateCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    if (Plater.UnitIsCasting(unitId)) then\n        envTable.ShowBackground(unitFrame)\n    else\n        envTable.HideBackground(unitFrame)\n    end\n    \nend",
      ["Time"] = 1699197389,
      ["NpcNames"] = {
      },
      ["url"] = "",
      ["Icon"] = 236209,
      ["Options"] = {
      },
      ["Enabled"] = true,
      ["Revision"] = 23,
      ["semver"] = "",
      ["Name"] = "Aura While Casting [P]",
      ["Temp_UpdateCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    if (Plater.UnitIsCasting(unitId)) then\n        envTable.ShowBackground(unitFrame)\n    else\n        envTable.HideBackground(unitFrame)\n    end\n    \nend",
      ["Author"] = "Tiranaa-Azralon",
      ["Initialization"] = "		function (scriptTable)\n			--insert code here\n			\n		end\n	",
      ["Desc"] = "Highlight the nameplate of a unit when has a certain Buff (trigger) and start to cast a spell",
      ["version"] = -1,
      ["Prio"] = 99,
      ["SpellIds"] = {
        372743, -- [1]
        372749, -- [2]
        384933, -- [3]
      },
      ["PlaterCore"] = 1,
      ["OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    --insert code here\n    \nend\n\n\n",
      ["Temp_ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    --insert code here\n    \n    local plateFrame = unitFrame.PlateFrame\n    \n    if (not plateFrame.BWC_RedBackground) then\n        plateFrame.BWC_RedBackground = plateFrame:CreateTexture(nil, \"background\")\n        plateFrame.BWC_RedBackground:SetAllPoints()\n    end\n    \n    plateFrame.BWC_RedBackground:SetTexture([[Interface/AddOns/Plater/masks/mask1]])\n    plateFrame.BWC_RedBackground:Hide()\n    \n    function envTable.ShowBackground(unitFrame)\n        local plateFrame = unitFrame.PlateFrame\n        plateFrame.BWC_RedBackground:SetVertexColor(1, 0, 0, 0.4)\n        plateFrame.BWC_RedBackground:Show()\n    end\n    \n    function envTable.HideBackground(unitFrame)\n        plateFrame.BWC_RedBackground:Hide()\n    end\nend\n\n\n\n\n\n\n",
      ["Temp_OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    --insert code here\n    envTable.HideBackground(unitFrame)\nend\n\n\n",
      ["Temp_Initialization"] = "		function (scriptTable)\n			--insert code here\n			\n		end\n	",
    }, -- [40]
    {
      ["ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    --create a flash texture which keep blinking while the cast in going on\n    self.OGC_BlinkTexture = self.OGC_BlinkTexture or self:CreateTexture(nil, \"overlay\")\n    self.OGC_BlinkTexture:SetColorTexture(1, 1, 1)\n    self.OGC_BlinkTexture:SetAlpha(0)\n    \n    --create the animation group for the blinking texture\n    self.OGC_BlinkAnimation = self.OGC_BlinkAnimation or Plater:CreateAnimationHub(self.OGC_BlinkTexture, function() self.OGC_BlinkTexture:Show() end, function() self.OGC_BlinkTexture:Hide() end)\n    \n    self.OGC_BlinkAnimation.In = self.OGC_BlinkAnimation.In or Plater:CreateAnimation(self.OGC_BlinkAnimation, \"alpha\", 1, 0.5, 0.3, 1)\n    \n    self.OGC_BlinkAnimation.Out = self.OGC_BlinkAnimation.Out or Plater:CreateAnimation(self.OGC_BlinkAnimation, \"alpha\", 2, 0.5, 1, 0.2)    \n    \n    \nend\n\n\n",
      ["OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    self.OGC_BlinkAnimation:Stop()\n    \n    Plater.StopDotAnimation(self, envTable.dotAnimation1)    \n    Plater.StopDotAnimation(self, envTable.dotAnimation2)   \n    \nend\n\n\n",
      ["OptionsValues"] = {
      },
      ["Temp_OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    self.OGC_BlinkTexture:ClearAllPoints()\n    self.OGC_BlinkTexture:SetPoint(\"topleft\", self, \"topleft\", 0, 0)\n    self.OGC_BlinkTexture:SetPoint(\"bottomright\", self, \"bottomright\", 0, 0)\n    \n    local red, green, blue = Plater:ParseColors(scriptTable.config.blinkColor)\n    self.OGC_BlinkTexture:SetVertexColor(red, green, blue)\n    \n    local blinkSpeed = scriptTable.config.speed\n    \n    self.OGC_BlinkAnimation.In:SetDuration(blinkSpeed)\n    self.OGC_BlinkAnimation.Out:SetDuration(blinkSpeed)\n    \n    local minBlinkAlpha = scriptTable.config.minAlpha\n    local maxBlinkAlpha = scriptTable.config.maxAlpha\n    \n    self.OGC_BlinkAnimation.In:SetFromAlpha(minBlinkAlpha)\n    self.OGC_BlinkAnimation.In:SetToAlpha(maxBlinkAlpha)\n    self.OGC_BlinkAnimation.Out:SetFromAlpha(maxBlinkAlpha)    \n    self.OGC_BlinkAnimation.Out:SetToAlpha(minBlinkAlpha)\n    \n    self.OGC_BlinkAnimation:SetLooping(\"repeat\")\n    self.OGC_BlinkAnimation:Play()\n    \n    envTable.dotAnimation1 = Plater.PlayDotAnimation(self, 2, scriptTable.config.dotColor, scriptTable.config.xOffset, scriptTable.config.yOffset)\n    envTable.dotAnimation1.textureInfo.speedMultiplier = 0.3\n    \n    envTable.dotAnimation2 = Plater.PlayDotAnimation(self, 2, scriptTable.config.dotColor, scriptTable.config.xOffset, scriptTable.config.yOffset)\n    envTable.dotAnimation2.textureInfo.speedMultiplier = 1\n    \nend",
      ["ScriptType"] = 2,
      ["Temp_Initialization"] = "		function (scriptTable)\n			--insert code here\n			\n		end\n	",
      ["Time"] = 1699197241,
      ["Options"] = {
        {
          ["Type"] = 1,
          ["Key"] = "dotColor",
          ["Value"] = {
            1, -- [1]
            1, -- [2]
            1, -- [3]
            0.41662168502808, -- [4]
          },
          ["Name"] = "Dots Color",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
          ["Desc"] = "Dots Color",
        }, -- [1]
        {
          ["Type"] = 2,
          ["Max"] = 10,
          ["Desc"] = "Dots X Offset",
          ["Min"] = -10,
          ["Key"] = "xOffset",
          ["Value"] = 0,
          ["Fraction"] = false,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Dots X Offset",
        }, -- [2]
        {
          ["Type"] = 2,
          ["Max"] = 10,
          ["Desc"] = "Dots Y Offset",
          ["Min"] = -10,
          ["Key"] = "yOffset",
          ["Value"] = 0,
          ["Fraction"] = false,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Dots Y Offset",
        }, -- [3]
        {
          ["Type"] = 6,
          ["Key"] = "option4",
          ["Value"] = 0,
          ["Name"] = "Option 4",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [4]
        {
          ["Type"] = 2,
          ["Max"] = 1,
          ["Desc"] = "Adjust how fast the blinking occurs",
          ["Min"] = 0.2,
          ["Key"] = "speed",
          ["Value"] = 0.4,
          ["Fraction"] = true,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Blink Speed",
        }, -- [5]
        {
          ["Type"] = 2,
          ["Max"] = 1,
          ["Desc"] = "Min amount of transparency the blink can have",
          ["Min"] = 0,
          ["Key"] = "minAlpha",
          ["Value"] = 0,
          ["Fraction"] = true,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Blink Min Alpha",
        }, -- [6]
        {
          ["Type"] = 2,
          ["Max"] = 1,
          ["Desc"] = "Max amount of transparency the blink can have",
          ["Min"] = 0,
          ["Key"] = "maxAlpha",
          ["Value"] = 0.5,
          ["Fraction"] = true,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Blink Max Alpha",
        }, -- [7]
        {
          ["Type"] = 1,
          ["Key"] = "blinkColor",
          ["Value"] = {
            1, -- [1]
            0.019607843831182, -- [2]
            0, -- [3]
            1, -- [4]
          },
          ["Name"] = "Blink Color",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
          ["Desc"] = "Color of the blinking texture",
        }, -- [8]
      },
      ["Temp_ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    --create a flash texture which keep blinking while the cast in going on\n    self.OGC_BlinkTexture = self.OGC_BlinkTexture or self:CreateTexture(nil, \"overlay\")\n    self.OGC_BlinkTexture:SetColorTexture(1, 1, 1)\n    self.OGC_BlinkTexture:SetAlpha(0)\n    \n    --create the animation group for the blinking texture\n    self.OGC_BlinkAnimation = self.OGC_BlinkAnimation or Plater:CreateAnimationHub(self.OGC_BlinkTexture, function() self.OGC_BlinkTexture:Show() end, function() self.OGC_BlinkTexture:Hide() end)\n    \n    self.OGC_BlinkAnimation.In = self.OGC_BlinkAnimation.In or Plater:CreateAnimation(self.OGC_BlinkAnimation, \"alpha\", 1, 0.5, 0.3, 1)\n    \n    self.OGC_BlinkAnimation.Out = self.OGC_BlinkAnimation.Out or Plater:CreateAnimation(self.OGC_BlinkAnimation, \"alpha\", 2, 0.5, 1, 0.2)    \n    \n    \nend\n\n\n",
      ["NpcNames"] = {
      },
      ["Desc"] = "The background of the nameplate blinks a red color indicating the cast is being performed. Useful to indicate channeling spells doing damage overtime.",
      ["Temp_OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    self.OGC_BlinkAnimation:Stop()\n    \n    Plater.StopDotAnimation(self, envTable.dotAnimation1)    \n    Plater.StopDotAnimation(self, envTable.dotAnimation2)   \n    \nend\n\n\n",
      ["Revision"] = 74,
      ["semver"] = "",
      ["SpellIds"] = {
        388886, -- [1]
        209676, -- [2]
        377912, -- [3]
      },
      ["Temp_UpdateCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    --insert code here\n    \nend\n\n\n",
      ["Author"] = "Ditador-Azralon",
      ["Initialization"] = "		function (scriptTable)\n			--insert code here\n			\n		end\n	",
      ["OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    self.OGC_BlinkTexture:ClearAllPoints()\n    self.OGC_BlinkTexture:SetPoint(\"topleft\", self, \"topleft\", 0, 0)\n    self.OGC_BlinkTexture:SetPoint(\"bottomright\", self, \"bottomright\", 0, 0)\n    \n    local red, green, blue = Plater:ParseColors(scriptTable.config.blinkColor)\n    self.OGC_BlinkTexture:SetVertexColor(red, green, blue)\n    \n    local blinkSpeed = scriptTable.config.speed\n    \n    self.OGC_BlinkAnimation.In:SetDuration(blinkSpeed)\n    self.OGC_BlinkAnimation.Out:SetDuration(blinkSpeed)\n    \n    local minBlinkAlpha = scriptTable.config.minAlpha\n    local maxBlinkAlpha = scriptTable.config.maxAlpha\n    \n    self.OGC_BlinkAnimation.In:SetFromAlpha(minBlinkAlpha)\n    self.OGC_BlinkAnimation.In:SetToAlpha(maxBlinkAlpha)\n    self.OGC_BlinkAnimation.Out:SetFromAlpha(maxBlinkAlpha)    \n    self.OGC_BlinkAnimation.Out:SetToAlpha(minBlinkAlpha)\n    \n    self.OGC_BlinkAnimation:SetLooping(\"repeat\")\n    self.OGC_BlinkAnimation:Play()\n    \n    envTable.dotAnimation1 = Plater.PlayDotAnimation(self, 2, scriptTable.config.dotColor, scriptTable.config.xOffset, scriptTable.config.yOffset)\n    envTable.dotAnimation1.textureInfo.speedMultiplier = 0.3\n    \n    envTable.dotAnimation2 = Plater.PlayDotAnimation(self, 2, scriptTable.config.dotColor, scriptTable.config.xOffset, scriptTable.config.yOffset)\n    envTable.dotAnimation2.textureInfo.speedMultiplier = 1\n    \nend",
      ["Name"] = "Cast - On Going Cast [P]",
      ["Prio"] = 99,
      ["version"] = -1,
      ["PlaterCore"] = 1,
      ["Enabled"] = false,
      ["Icon"] = 4038101,
      ["url"] = "",
      ["UpdateCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    --insert code here\n    \nend\n\n\n",
    }, -- [41]
  },
  ["saved_cvars_last_change"] = {
    ["nameplateShowOnlyNames"] = "[string \"=[C]\"]: in function `SetCVar'\n[string \"@Interface/AddOns/Plater/Plater.lua\"]:2314: in function `RestoreProfileCVars'\n[string \"@Interface/AddOns/Plater/Plater_OptionsPanel.lua\"]:908: in function `DoProfileImport'\n[string \"@Interface/AddOns/Plater/Plater_OptionsPanel.lua\"]:769: in function <Interface/AddOns/Plater/Plater_OptionsPanel.lua:769>\n[string \"=[C]\"]: in function `pcall'\n[string \"@Interface/AddOns/Details/Libs/DF/panel.lua\"]:2364: in function <Interface/AddOns/Details/Libs/DF/panel.lua:2361>\n[string \"=[C]\"]: in function `xpcall'\n[string \"@Interface/AddOns/Details/Libs/DF/fw.lua\"]:4590: in function `CoreDispatch'\n[string \"@Interface/AddOns/Details/Libs/DF/button.lua\"]:719: in function <Interface/AddOns/Details/Libs/DF/button.lua:655>\n",
    ["nameplateOverlapV"] = "[string \"=[C]\"]: in function `SetCVar'\n[string \"@Interface/AddOns/Plater/Plater.lua\"]:2314: in function `RestoreProfileCVars'\n[string \"@Interface/AddOns/Plater/Plater_OptionsPanel.lua\"]:908: in function `DoProfileImport'\n[string \"@Interface/AddOns/Plater/Plater_OptionsPanel.lua\"]:769: in function <Interface/AddOns/Plater/Plater_OptionsPanel.lua:769>\n[string \"=[C]\"]: in function `pcall'\n[string \"@Interface/AddOns/Details/Libs/DF/panel.lua\"]:2364: in function <Interface/AddOns/Details/Libs/DF/panel.lua:2361>\n[string \"=[C]\"]: in function `xpcall'\n[string \"@Interface/AddOns/Details/Libs/DF/fw.lua\"]:4590: in function `CoreDispatch'\n[string \"@Interface/AddOns/Details/Libs/DF/button.lua\"]:719: in function <Interface/AddOns/Details/Libs/DF/button.lua:655>\n",
    ["nameplateLargeTopInset"] = "[string \"=[C]\"]: in function `SetCVar'\n[string \"@Interface/AddOns/Plater/Plater.lua\"]:2314: in function `RestoreProfileCVars'\n[string \"@Interface/AddOns/Plater/Plater_OptionsPanel.lua\"]:908: in function `DoProfileImport'\n[string \"@Interface/AddOns/Plater/Plater_OptionsPanel.lua\"]:769: in function <Interface/AddOns/Plater/Plater_OptionsPanel.lua:769>\n[string \"=[C]\"]: in function `pcall'\n[string \"@Interface/AddOns/Details/Libs/DF/panel.lua\"]:2364: in function <Interface/AddOns/Details/Libs/DF/panel.lua:2361>\n[string \"=[C]\"]: in function `xpcall'\n[string \"@Interface/AddOns/Details/Libs/DF/fw.lua\"]:4590: in function `CoreDispatch'\n[string \"@Interface/AddOns/Details/Libs/DF/button.lua\"]:719: in function <Interface/AddOns/Details/Libs/DF/button.lua:655>\n",
    ["nameplateShowEnemyMinus"] = "[string \"=[C]\"]: in function `SetCVar'\n[string \"@Interface/AddOns/Plater/Plater.lua\"]:2314: in function `RestoreProfileCVars'\n[string \"@Interface/AddOns/Plater/Plater_OptionsPanel.lua\"]:908: in function `DoProfileImport'\n[string \"@Interface/AddOns/Plater/Plater_OptionsPanel.lua\"]:769: in function <Interface/AddOns/Plater/Plater_OptionsPanel.lua:769>\n[string \"=[C]\"]: in function `pcall'\n[string \"@Interface/AddOns/Details/Libs/DF/panel.lua\"]:2364: in function <Interface/AddOns/Details/Libs/DF/panel.lua:2361>\n[string \"=[C]\"]: in function `xpcall'\n[string \"@Interface/AddOns/Details/Libs/DF/fw.lua\"]:4590: in function `CoreDispatch'\n[string \"@Interface/AddOns/Details/Libs/DF/button.lua\"]:719: in function <Interface/AddOns/Details/Libs/DF/button.lua:655>\n",
    ["NamePlateClassificationScale"] = "[string \"=[C]\"]: in function `SetCVar'\n[string \"@Interface/AddOns/Plater/Plater.lua\"]:2314: in function `RestoreProfileCVars'\n[string \"@Interface/AddOns/Plater/Plater_OptionsPanel.lua\"]:908: in function `DoProfileImport'\n[string \"@Interface/AddOns/Plater/Plater_OptionsPanel.lua\"]:769: in function <Interface/AddOns/Plater/Plater_OptionsPanel.lua:769>\n[string \"=[C]\"]: in function `pcall'\n[string \"@Interface/AddOns/Details/Libs/DF/panel.lua\"]:2364: in function <Interface/AddOns/Details/Libs/DF/panel.lua:2361>\n[string \"=[C]\"]: in function `xpcall'\n[string \"@Interface/AddOns/Details/Libs/DF/fw.lua\"]:4590: in function `CoreDispatch'\n[string \"@Interface/AddOns/Details/Libs/DF/button.lua\"]:719: in function <Interface/AddOns/Details/Libs/DF/button.lua:655>\n",
    ["nameplateShowFriendlyTotems"] = "[string \"=[C]\"]: in function `SetCVar'\n[string \"@Interface/AddOns/Plater/Plater.lua\"]:2314: in function `RestoreProfileCVars'\n[string \"@Interface/AddOns/Plater/Plater_OptionsPanel.lua\"]:908: in function `DoProfileImport'\n[string \"@Interface/AddOns/Plater/Plater_OptionsPanel.lua\"]:769: in function <Interface/AddOns/Plater/Plater_OptionsPanel.lua:769>\n[string \"=[C]\"]: in function `pcall'\n[string \"@Interface/AddOns/Details/Libs/DF/panel.lua\"]:2364: in function <Interface/AddOns/Details/Libs/DF/panel.lua:2361>\n[string \"=[C]\"]: in function `xpcall'\n[string \"@Interface/AddOns/Details/Libs/DF/fw.lua\"]:4590: in function `CoreDispatch'\n[string \"@Interface/AddOns/Details/Libs/DF/button.lua\"]:719: in function <Interface/AddOns/Details/Libs/DF/button.lua:655>\n",
    ["nameplatePersonalHideDelaySeconds"] = "[string \"=[C]\"]: in function `SetCVar'\n[string \"@Interface/AddOns/Plater/Plater.lua\"]:2314: in function `RestoreProfileCVars'\n[string \"@Interface/AddOns/Plater/Plater_OptionsPanel.lua\"]:908: in function `DoProfileImport'\n[string \"@Interface/AddOns/Plater/Plater_OptionsPanel.lua\"]:769: in function <Interface/AddOns/Plater/Plater_OptionsPanel.lua:769>\n[string \"=[C]\"]: in function `pcall'\n[string \"@Interface/AddOns/Details/Libs/DF/panel.lua\"]:2364: in function <Interface/AddOns/Details/Libs/DF/panel.lua:2361>\n[string \"=[C]\"]: in function `xpcall'\n[string \"@Interface/AddOns/Details/Libs/DF/fw.lua\"]:4590: in function `CoreDispatch'\n[string \"@Interface/AddOns/Details/Libs/DF/button.lua\"]:719: in function <Interface/AddOns/Details/Libs/DF/button.lua:655>\n",
    ["nameplateShowFriendlyPets"] = "[string \"=[C]\"]: in function `SetCVar'\n[string \"@Interface/AddOns/Plater/Plater.lua\"]:2314: in function `RestoreProfileCVars'\n[string \"@Interface/AddOns/Plater/Plater_OptionsPanel.lua\"]:908: in function `DoProfileImport'\n[string \"@Interface/AddOns/Plater/Plater_OptionsPanel.lua\"]:769: in function <Interface/AddOns/Plater/Plater_OptionsPanel.lua:769>\n[string \"=[C]\"]: in function `pcall'\n[string \"@Interface/AddOns/Details/Libs/DF/panel.lua\"]:2364: in function <Interface/AddOns/Details/Libs/DF/panel.lua:2361>\n[string \"=[C]\"]: in function `xpcall'\n[string \"@Interface/AddOns/Details/Libs/DF/fw.lua\"]:4590: in function `CoreDispatch'\n[string \"@Interface/AddOns/Details/Libs/DF/button.lua\"]:719: in function <Interface/AddOns/Details/Libs/DF/button.lua:655>\n",
    ["nameplatePersonalShowInCombat"] = "[string \"=[C]\"]: in function `SetCVar'\n[string \"@Interface/AddOns/Plater/Plater.lua\"]:2314: in function `RestoreProfileCVars'\n[string \"@Interface/AddOns/Plater/Plater_OptionsPanel.lua\"]:908: in function `DoProfileImport'\n[string \"@Interface/AddOns/Plater/Plater_OptionsPanel.lua\"]:769: in function <Interface/AddOns/Plater/Plater_OptionsPanel.lua:769>\n[string \"=[C]\"]: in function `pcall'\n[string \"@Interface/AddOns/Details/Libs/DF/panel.lua\"]:2364: in function <Interface/AddOns/Details/Libs/DF/panel.lua:2361>\n[string \"=[C]\"]: in function `xpcall'\n[string \"@Interface/AddOns/Details/Libs/DF/fw.lua\"]:4590: in function `CoreDispatch'\n[string \"@Interface/AddOns/Details/Libs/DF/button.lua\"]:719: in function <Interface/AddOns/Details/Libs/DF/button.lua:655>\n",
    ["nameplatePersonalShowWithTarget"] = "[string \"=[C]\"]: in function `SetCVar'\n[string \"@Interface/AddOns/Plater/Plater.lua\"]:2314: in function `RestoreProfileCVars'\n[string \"@Interface/AddOns/Plater/Plater_OptionsPanel.lua\"]:908: in function `DoProfileImport'\n[string \"@Interface/AddOns/Plater/Plater_OptionsPanel.lua\"]:769: in function <Interface/AddOns/Plater/Plater_OptionsPanel.lua:769>\n[string \"=[C]\"]: in function `pcall'\n[string \"@Interface/AddOns/Details/Libs/DF/panel.lua\"]:2364: in function <Interface/AddOns/Details/Libs/DF/panel.lua:2361>\n[string \"=[C]\"]: in function `xpcall'\n[string \"@Interface/AddOns/Details/Libs/DF/fw.lua\"]:4590: in function `CoreDispatch'\n[string \"@Interface/AddOns/Details/Libs/DF/button.lua\"]:719: in function <Interface/AddOns/Details/Libs/DF/button.lua:655>\n",
    ["nameplateMinAlpha"] = "[string \"=[C]\"]: in function `SetCVar'\n[string \"@Interface/AddOns/Plater/Plater.lua\"]:2314: in function `RestoreProfileCVars'\n[string \"@Interface/AddOns/Plater/Plater_OptionsPanel.lua\"]:908: in function `DoProfileImport'\n[string \"@Interface/AddOns/Plater/Plater_OptionsPanel.lua\"]:769: in function <Interface/AddOns/Plater/Plater_OptionsPanel.lua:769>\n[string \"=[C]\"]: in function `pcall'\n[string \"@Interface/AddOns/Details/Libs/DF/panel.lua\"]:2364: in function <Interface/AddOns/Details/Libs/DF/panel.lua:2361>\n[string \"=[C]\"]: in function `xpcall'\n[string \"@Interface/AddOns/Details/Libs/DF/fw.lua\"]:4590: in function `CoreDispatch'\n[string \"@Interface/AddOns/Details/Libs/DF/button.lua\"]:719: in function <Interface/AddOns/Details/Libs/DF/button.lua:655>\n",
    ["nameplateResourceOnTarget"] = "[string \"=[C]\"]: in function `SetCVar'\n[string \"@Interface/AddOns/Plater/Plater.lua\"]:2314: in function `RestoreProfileCVars'\n[string \"@Interface/AddOns/Plater/Plater_OptionsPanel.lua\"]:908: in function `DoProfileImport'\n[string \"@Interface/AddOns/Plater/Plater_OptionsPanel.lua\"]:769: in function <Interface/AddOns/Plater/Plater_OptionsPanel.lua:769>\n[string \"=[C]\"]: in function `pcall'\n[string \"@Interface/AddOns/Details/Libs/DF/panel.lua\"]:2364: in function <Interface/AddOns/Details/Libs/DF/panel.lua:2361>\n[string \"=[C]\"]: in function `xpcall'\n[string \"@Interface/AddOns/Details/Libs/DF/fw.lua\"]:4590: in function `CoreDispatch'\n[string \"@Interface/AddOns/Details/Libs/DF/button.lua\"]:719: in function <Interface/AddOns/Details/Libs/DF/button.lua:655>\n",
    ["nameplateShowAll"] = "[string \"=[C]\"]: in function `SetCVar'\n[string \"@Interface/AddOns/Plater/Plater.lua\"]:2314: in function `RestoreProfileCVars'\n[string \"@Interface/AddOns/Plater/Plater_OptionsPanel.lua\"]:908: in function `DoProfileImport'\n[string \"@Interface/AddOns/Plater/Plater_OptionsPanel.lua\"]:769: in function <Interface/AddOns/Plater/Plater_OptionsPanel.lua:769>\n[string \"=[C]\"]: in function `pcall'\n[string \"@Interface/AddOns/Details/Libs/DF/panel.lua\"]:2364: in function <Interface/AddOns/Details/Libs/DF/panel.lua:2361>\n[string \"=[C]\"]: in function `xpcall'\n[string \"@Interface/AddOns/Details/Libs/DF/fw.lua\"]:4590: in function `CoreDispatch'\n[string \"@Interface/AddOns/Details/Libs/DF/button.lua\"]:719: in function <Interface/AddOns/Details/Libs/DF/button.lua:655>\n",
    ["nameplateMaxDistance"] = "[string \"=[C]\"]: in function `SetCVar'\n[string \"@Interface/AddOns/Plater/Plater.lua\"]:2314: in function `RestoreProfileCVars'\n[string \"@Interface/AddOns/Plater/Plater_OptionsPanel.lua\"]:908: in function `DoProfileImport'\n[string \"@Interface/AddOns/Plater/Plater_OptionsPanel.lua\"]:769: in function <Interface/AddOns/Plater/Plater_OptionsPanel.lua:769>\n[string \"=[C]\"]: in function `pcall'\n[string \"@Interface/AddOns/Details/Libs/DF/panel.lua\"]:2364: in function <Interface/AddOns/Details/Libs/DF/panel.lua:2361>\n[string \"=[C]\"]: in function `xpcall'\n[string \"@Interface/AddOns/Details/Libs/DF/fw.lua\"]:4590: in function `CoreDispatch'\n[string \"@Interface/AddOns/Details/Libs/DF/button.lua\"]:719: in function <Interface/AddOns/Details/Libs/DF/button.lua:655>\n",
    ["nameplateShowFriendlyMinions"] = "[string \"=[C]\"]: in function `SetCVar'\n[string \"@Interface/AddOns/Plater/Plater.lua\"]:2314: in function `RestoreProfileCVars'\n[string \"@Interface/AddOns/Plater/Plater_OptionsPanel.lua\"]:908: in function `DoProfileImport'\n[string \"@Interface/AddOns/Plater/Plater_OptionsPanel.lua\"]:769: in function <Interface/AddOns/Plater/Plater_OptionsPanel.lua:769>\n[string \"=[C]\"]: in function `pcall'\n[string \"@Interface/AddOns/Details/Libs/DF/panel.lua\"]:2364: in function <Interface/AddOns/Details/Libs/DF/panel.lua:2361>\n[string \"=[C]\"]: in function `xpcall'\n[string \"@Interface/AddOns/Details/Libs/DF/fw.lua\"]:4590: in function `CoreDispatch'\n[string \"@Interface/AddOns/Details/Libs/DF/button.lua\"]:719: in function <Interface/AddOns/Details/Libs/DF/button.lua:655>\n",
    ["nameplateSelfScale"] = "[string \"=[C]\"]: in function `SetCVar'\n[string \"@Interface/AddOns/Plater/Plater.lua\"]:2314: in function `RestoreProfileCVars'\n[string \"@Interface/AddOns/Plater/Plater_OptionsPanel.lua\"]:908: in function `DoProfileImport'\n[string \"@Interface/AddOns/Plater/Plater_OptionsPanel.lua\"]:769: in function <Interface/AddOns/Plater/Plater_OptionsPanel.lua:769>\n[string \"=[C]\"]: in function `pcall'\n[string \"@Interface/AddOns/Details/Libs/DF/panel.lua\"]:2364: in function <Interface/AddOns/Details/Libs/DF/panel.lua:2361>\n[string \"=[C]\"]: in function `xpcall'\n[string \"@Interface/AddOns/Details/Libs/DF/fw.lua\"]:4590: in function `CoreDispatch'\n[string \"@Interface/AddOns/Details/Libs/DF/button.lua\"]:719: in function <Interface/AddOns/Details/Libs/DF/button.lua:655>\n",
    ["nameplateTargetBehindMaxDistance"] = "[string \"=[C]\"]: in function `SetCVar'\n[string \"@Interface/AddOns/Plater/Plater.lua\"]:2314: in function `RestoreProfileCVars'\n[string \"@Interface/AddOns/Plater/Plater_OptionsPanel.lua\"]:908: in function `DoProfileImport'\n[string \"@Interface/AddOns/Plater/Plater_OptionsPanel.lua\"]:769: in function <Interface/AddOns/Plater/Plater_OptionsPanel.lua:769>\n[string \"=[C]\"]: in function `pcall'\n[string \"@Interface/AddOns/Details/Libs/DF/panel.lua\"]:2364: in function <Interface/AddOns/Details/Libs/DF/panel.lua:2361>\n[string \"=[C]\"]: in function `xpcall'\n[string \"@Interface/AddOns/Details/Libs/DF/fw.lua\"]:4590: in function `CoreDispatch'\n[string \"@Interface/AddOns/Details/Libs/DF/button.lua\"]:719: in function <Interface/AddOns/Details/Libs/DF/button.lua:655>\n",
    ["nameplateShowEnemies"] = "[string \"=[C]\"]: in function `SetCVar'\n[string \"@Interface/SharedXML/CvarUtil.lua\"]:72: in function `SetValue'\n[string \"@Interface/SharedXML/Settings/Blizzard_Setting.lua\"]:187: in function `SetValueInternal'\n[string \"@Interface/SharedXML/Settings/Blizzard_Setting.lua\"]:67: in function `SetValue'\n[string \"@Interface/SharedXML/Settings/Blizzard_Settings.lua\"]:229: in function `SetValue'\n[string \"NAMEPLATES\"]:6: in function <[string \"NAMEPLATES\"]:1>\n",
    ["NamePlateVerticalScale"] = "[string \"=[C]\"]: in function `SetCVar'\n[string \"@Interface/AddOns/Plater/Plater.lua\"]:2314: in function `RestoreProfileCVars'\n[string \"@Interface/AddOns/Plater/Plater_OptionsPanel.lua\"]:908: in function `DoProfileImport'\n[string \"@Interface/AddOns/Plater/Plater_OptionsPanel.lua\"]:769: in function <Interface/AddOns/Plater/Plater_OptionsPanel.lua:769>\n[string \"=[C]\"]: in function `pcall'\n[string \"@Interface/AddOns/Details/Libs/DF/panel.lua\"]:2364: in function <Interface/AddOns/Details/Libs/DF/panel.lua:2361>\n[string \"=[C]\"]: in function `xpcall'\n[string \"@Interface/AddOns/Details/Libs/DF/fw.lua\"]:4590: in function `CoreDispatch'\n[string \"@Interface/AddOns/Details/Libs/DF/button.lua\"]:719: in function <Interface/AddOns/Details/Libs/DF/button.lua:655>\n",
    ["nameplateSelectedAlpha"] = "[string \"=[C]\"]: in function `SetCVar'\n[string \"@Interface/AddOns/Plater/Plater.lua\"]:2314: in function `RestoreProfileCVars'\n[string \"@Interface/AddOns/Plater/Plater_OptionsPanel.lua\"]:908: in function `DoProfileImport'\n[string \"@Interface/AddOns/Plater/Plater_OptionsPanel.lua\"]:769: in function <Interface/AddOns/Plater/Plater_OptionsPanel.lua:769>\n[string \"=[C]\"]: in function `pcall'\n[string \"@Interface/AddOns/Details/Libs/DF/panel.lua\"]:2364: in function <Interface/AddOns/Details/Libs/DF/panel.lua:2361>\n[string \"=[C]\"]: in function `xpcall'\n[string \"@Interface/AddOns/Details/Libs/DF/fw.lua\"]:4590: in function `CoreDispatch'\n[string \"@Interface/AddOns/Details/Libs/DF/button.lua\"]:719: in function <Interface/AddOns/Details/Libs/DF/button.lua:655>\n",
    ["nameplateShowSelf"] = "[string \"=[C]\"]: in function `SetCVar'\n[string \"@Interface/AddOns/Plater/Plater.lua\"]:2314: in function `RestoreProfileCVars'\n[string \"@Interface/AddOns/Plater/Plater_OptionsPanel.lua\"]:908: in function `DoProfileImport'\n[string \"@Interface/AddOns/Plater/Plater_OptionsPanel.lua\"]:769: in function <Interface/AddOns/Plater/Plater_OptionsPanel.lua:769>\n[string \"=[C]\"]: in function `pcall'\n[string \"@Interface/AddOns/Details/Libs/DF/panel.lua\"]:2364: in function <Interface/AddOns/Details/Libs/DF/panel.lua:2361>\n[string \"=[C]\"]: in function `xpcall'\n[string \"@Interface/AddOns/Details/Libs/DF/fw.lua\"]:4590: in function `CoreDispatch'\n[string \"@Interface/AddOns/Details/Libs/DF/button.lua\"]:719: in function <Interface/AddOns/Details/Libs/DF/button.lua:655>\n",
    ["nameplateSelfTopInset"] = "[string \"=[C]\"]: in function `SetCVar'\n[string \"@Interface/AddOns/Plater/Plater.lua\"]:2314: in function `RestoreProfileCVars'\n[string \"@Interface/AddOns/Plater/Plater_OptionsPanel.lua\"]:908: in function `DoProfileImport'\n[string \"@Interface/AddOns/Plater/Plater_OptionsPanel.lua\"]:769: in function <Interface/AddOns/Plater/Plater_OptionsPanel.lua:769>\n[string \"=[C]\"]: in function `pcall'\n[string \"@Interface/AddOns/Details/Libs/DF/panel.lua\"]:2364: in function <Interface/AddOns/Details/Libs/DF/panel.lua:2361>\n[string \"=[C]\"]: in function `xpcall'\n[string \"@Interface/AddOns/Details/Libs/DF/fw.lua\"]:4590: in function `CoreDispatch'\n[string \"@Interface/AddOns/Details/Libs/DF/button.lua\"]:719: in function <Interface/AddOns/Details/Libs/DF/button.lua:655>\n",
    ["nameplateMotionSpeed"] = "[string \"=[C]\"]: in function `SetCVar'\n[string \"@Interface/AddOns/Plater/Plater.lua\"]:2314: in function `RestoreProfileCVars'\n[string \"@Interface/AddOns/Plater/Plater_OptionsPanel.lua\"]:908: in function `DoProfileImport'\n[string \"@Interface/AddOns/Plater/Plater_OptionsPanel.lua\"]:769: in function <Interface/AddOns/Plater/Plater_OptionsPanel.lua:769>\n[string \"=[C]\"]: in function `pcall'\n[string \"@Interface/AddOns/Details/Libs/DF/panel.lua\"]:2364: in function <Interface/AddOns/Details/Libs/DF/panel.lua:2361>\n[string \"=[C]\"]: in function `xpcall'\n[string \"@Interface/AddOns/Details/Libs/DF/fw.lua\"]:4590: in function `CoreDispatch'\n[string \"@Interface/AddOns/Details/Libs/DF/button.lua\"]:719: in function <Interface/AddOns/Details/Libs/DF/button.lua:655>\n",
    ["nameplateGlobalScale"] = "[string \"=[C]\"]: in function `SetCVar'\n[string \"@Interface/AddOns/Plater/Plater.lua\"]:2314: in function `RestoreProfileCVars'\n[string \"@Interface/AddOns/Plater/Plater_OptionsPanel.lua\"]:908: in function `DoProfileImport'\n[string \"@Interface/AddOns/Plater/Plater_OptionsPanel.lua\"]:769: in function <Interface/AddOns/Plater/Plater_OptionsPanel.lua:769>\n[string \"=[C]\"]: in function `pcall'\n[string \"@Interface/AddOns/Details/Libs/DF/panel.lua\"]:2364: in function <Interface/AddOns/Details/Libs/DF/panel.lua:2361>\n[string \"=[C]\"]: in function `xpcall'\n[string \"@Interface/AddOns/Details/Libs/DF/fw.lua\"]:4590: in function `CoreDispatch'\n[string \"@Interface/AddOns/Details/Libs/DF/button.lua\"]:719: in function <Interface/AddOns/Details/Libs/DF/button.lua:655>\n",
    ["nameplateShowEnemyMinions"] = "[string \"=[C]\"]: in function `SetCVar'\n[string \"@Interface/AddOns/Plater/Plater.lua\"]:2314: in function `RestoreProfileCVars'\n[string \"@Interface/AddOns/Plater/Plater_OptionsPanel.lua\"]:908: in function `DoProfileImport'\n[string \"@Interface/AddOns/Plater/Plater_OptionsPanel.lua\"]:769: in function <Interface/AddOns/Plater/Plater_OptionsPanel.lua:769>\n[string \"=[C]\"]: in function `pcall'\n[string \"@Interface/AddOns/Details/Libs/DF/panel.lua\"]:2364: in function <Interface/AddOns/Details/Libs/DF/panel.lua:2361>\n[string \"=[C]\"]: in function `xpcall'\n[string \"@Interface/AddOns/Details/Libs/DF/fw.lua\"]:4590: in function `CoreDispatch'\n[string \"@Interface/AddOns/Details/Libs/DF/button.lua\"]:719: in function <Interface/AddOns/Details/Libs/DF/button.lua:655>\n",
    ["nameplateShowFriendlyNPCs"] = "[string \"=[C]\"]: in function `SetCVar'\n[string \"@Interface/AddOns/Plater/Plater.lua\"]:2314: in function `RestoreProfileCVars'\n[string \"@Interface/AddOns/Plater/Plater_OptionsPanel.lua\"]:908: in function `DoProfileImport'\n[string \"@Interface/AddOns/Plater/Plater_OptionsPanel.lua\"]:769: in function <Interface/AddOns/Plater/Plater_OptionsPanel.lua:769>\n[string \"=[C]\"]: in function `pcall'\n[string \"@Interface/AddOns/Details/Libs/DF/panel.lua\"]:2364: in function <Interface/AddOns/Details/Libs/DF/panel.lua:2361>\n[string \"=[C]\"]: in function `xpcall'\n[string \"@Interface/AddOns/Details/Libs/DF/fw.lua\"]:4590: in function `CoreDispatch'\n[string \"@Interface/AddOns/Details/Libs/DF/button.lua\"]:719: in function <Interface/AddOns/Details/Libs/DF/button.lua:655>\n",
    ["nameplateSelectedScale"] = "[string \"=[C]\"]: in function `SetCVar'\n[string \"@Interface/AddOns/Plater/Plater.lua\"]:2314: in function `RestoreProfileCVars'\n[string \"@Interface/AddOns/Plater/Plater_OptionsPanel.lua\"]:908: in function `DoProfileImport'\n[string \"@Interface/AddOns/Plater/Plater_OptionsPanel.lua\"]:769: in function <Interface/AddOns/Plater/Plater_OptionsPanel.lua:769>\n[string \"=[C]\"]: in function `pcall'\n[string \"@Interface/AddOns/Details/Libs/DF/panel.lua\"]:2364: in function <Interface/AddOns/Details/Libs/DF/panel.lua:2361>\n[string \"=[C]\"]: in function `xpcall'\n[string \"@Interface/AddOns/Details/Libs/DF/fw.lua\"]:4590: in function `CoreDispatch'\n[string \"@Interface/AddOns/Details/Libs/DF/button.lua\"]:719: in function <Interface/AddOns/Details/Libs/DF/button.lua:655>\n",
    ["nameplateMinAlphaDistance"] = "[string \"=[C]\"]: in function `SetCVar'\n[string \"@Interface/AddOns/Plater/Plater.lua\"]:2314: in function `RestoreProfileCVars'\n[string \"@Interface/AddOns/Plater/Plater_OptionsPanel.lua\"]:908: in function `DoProfileImport'\n[string \"@Interface/AddOns/Plater/Plater_OptionsPanel.lua\"]:769: in function <Interface/AddOns/Plater/Plater_OptionsPanel.lua:769>\n[string \"=[C]\"]: in function `pcall'\n[string \"@Interface/AddOns/Details/Libs/DF/panel.lua\"]:2364: in function <Interface/AddOns/Details/Libs/DF/panel.lua:2361>\n[string \"=[C]\"]: in function `xpcall'\n[string \"@Interface/AddOns/Details/Libs/DF/fw.lua\"]:4590: in function `CoreDispatch'\n[string \"@Interface/AddOns/Details/Libs/DF/button.lua\"]:719: in function <Interface/AddOns/Details/Libs/DF/button.lua:655>\n",
    ["nameplateMotion"] = "[string \"=[C]\"]: in function `SetCVar'\n[string \"@Interface/AddOns/Plater/Plater.lua\"]:2314: in function `RestoreProfileCVars'\n[string \"@Interface/AddOns/Plater/Plater_OptionsPanel.lua\"]:908: in function `DoProfileImport'\n[string \"@Interface/AddOns/Plater/Plater_OptionsPanel.lua\"]:769: in function <Interface/AddOns/Plater/Plater_OptionsPanel.lua:769>\n[string \"=[C]\"]: in function `pcall'\n[string \"@Interface/AddOns/Details/Libs/DF/panel.lua\"]:2364: in function <Interface/AddOns/Details/Libs/DF/panel.lua:2361>\n[string \"=[C]\"]: in function `xpcall'\n[string \"@Interface/AddOns/Details/Libs/DF/fw.lua\"]:4590: in function `CoreDispatch'\n[string \"@Interface/AddOns/Details/Libs/DF/button.lua\"]:719: in function <Interface/AddOns/Details/Libs/DF/button.lua:655>\n",
    ["nameplatePersonalShowAlways"] = "[string \"=[C]\"]: in function `SetCVar'\n[string \"@Interface/AddOns/Plater/Plater.lua\"]:2314: in function `RestoreProfileCVars'\n[string \"@Interface/AddOns/Plater/Plater_OptionsPanel.lua\"]:908: in function `DoProfileImport'\n[string \"@Interface/AddOns/Plater/Plater_OptionsPanel.lua\"]:769: in function <Interface/AddOns/Plater/Plater_OptionsPanel.lua:769>\n[string \"=[C]\"]: in function `pcall'\n[string \"@Interface/AddOns/Details/Libs/DF/panel.lua\"]:2364: in function <Interface/AddOns/Details/Libs/DF/panel.lua:2361>\n[string \"=[C]\"]: in function `xpcall'\n[string \"@Interface/AddOns/Details/Libs/DF/fw.lua\"]:4590: in function `CoreDispatch'\n[string \"@Interface/AddOns/Details/Libs/DF/button.lua\"]:719: in function <Interface/AddOns/Details/Libs/DF/button.lua:655>\n",
    ["nameplateMinScale"] = "[string \"=[C]\"]: in function `SetCVar'\n[string \"@Interface/AddOns/Plater/Plater.lua\"]:2314: in function `RestoreProfileCVars'\n[string \"@Interface/AddOns/Plater/Plater_OptionsPanel.lua\"]:908: in function `DoProfileImport'\n[string \"@Interface/AddOns/Plater/Plater_OptionsPanel.lua\"]:769: in function <Interface/AddOns/Plater/Plater_OptionsPanel.lua:769>\n[string \"=[C]\"]: in function `pcall'\n[string \"@Interface/AddOns/Details/Libs/DF/panel.lua\"]:2364: in function <Interface/AddOns/Details/Libs/DF/panel.lua:2361>\n[string \"=[C]\"]: in function `xpcall'\n[string \"@Interface/AddOns/Details/Libs/DF/fw.lua\"]:4590: in function `CoreDispatch'\n[string \"@Interface/AddOns/Details/Libs/DF/button.lua\"]:719: in function <Interface/AddOns/Details/Libs/DF/button.lua:655>\n",
    ["nameplateSelfAlpha"] = "[string \"=[C]\"]: in function `SetCVar'\n[string \"@Interface/AddOns/Plater/Plater.lua\"]:2314: in function `RestoreProfileCVars'\n[string \"@Interface/AddOns/Plater/Plater_OptionsPanel.lua\"]:908: in function `DoProfileImport'\n[string \"@Interface/AddOns/Plater/Plater_OptionsPanel.lua\"]:769: in function <Interface/AddOns/Plater/Plater_OptionsPanel.lua:769>\n[string \"=[C]\"]: in function `pcall'\n[string \"@Interface/AddOns/Details/Libs/DF/panel.lua\"]:2364: in function <Interface/AddOns/Details/Libs/DF/panel.lua:2361>\n[string \"=[C]\"]: in function `xpcall'\n[string \"@Interface/AddOns/Details/Libs/DF/fw.lua\"]:4590: in function `CoreDispatch'\n[string \"@Interface/AddOns/Details/Libs/DF/button.lua\"]:719: in function <Interface/AddOns/Details/Libs/DF/button.lua:655>\n",
    ["nameplateOtherTopInset"] = "[string \"=[C]\"]: in function `SetCVar'\n[string \"@Interface/AddOns/Plater/Plater.lua\"]:2314: in function `RestoreProfileCVars'\n[string \"@Interface/AddOns/Plater/Plater_OptionsPanel.lua\"]:908: in function `DoProfileImport'\n[string \"@Interface/AddOns/Plater/Plater_OptionsPanel.lua\"]:769: in function <Interface/AddOns/Plater/Plater_OptionsPanel.lua:769>\n[string \"=[C]\"]: in function `pcall'\n[string \"@Interface/AddOns/Details/Libs/DF/panel.lua\"]:2364: in function <Interface/AddOns/Details/Libs/DF/panel.lua:2361>\n[string \"=[C]\"]: in function `xpcall'\n[string \"@Interface/AddOns/Details/Libs/DF/fw.lua\"]:4590: in function `CoreDispatch'\n[string \"@Interface/AddOns/Details/Libs/DF/button.lua\"]:719: in function <Interface/AddOns/Details/Libs/DF/button.lua:655>\n",
    ["nameplateOtherAtBase"] = "[string \"=[C]\"]: in function `SetCVar'\n[string \"@Interface/AddOns/Plater/Plater.lua\"]:2314: in function `RestoreProfileCVars'\n[string \"@Interface/AddOns/Plater/Plater_OptionsPanel.lua\"]:908: in function `DoProfileImport'\n[string \"@Interface/AddOns/Plater/Plater_OptionsPanel.lua\"]:769: in function <Interface/AddOns/Plater/Plater_OptionsPanel.lua:769>\n[string \"=[C]\"]: in function `pcall'\n[string \"@Interface/AddOns/Details/Libs/DF/panel.lua\"]:2364: in function <Interface/AddOns/Details/Libs/DF/panel.lua:2361>\n[string \"=[C]\"]: in function `xpcall'\n[string \"@Interface/AddOns/Details/Libs/DF/fw.lua\"]:4590: in function `CoreDispatch'\n[string \"@Interface/AddOns/Details/Libs/DF/button.lua\"]:719: in function <Interface/AddOns/Details/Libs/DF/button.lua:655>\n",
    ["nameplateSelfBottomInset"] = "[string \"=[C]\"]: in function `SetCVar'\n[string \"@Interface/AddOns/Plater/Plater.lua\"]:2314: in function `RestoreProfileCVars'\n[string \"@Interface/AddOns/Plater/Plater_OptionsPanel.lua\"]:908: in function `DoProfileImport'\n[string \"@Interface/AddOns/Plater/Plater_OptionsPanel.lua\"]:769: in function <Interface/AddOns/Plater/Plater_OptionsPanel.lua:769>\n[string \"=[C]\"]: in function `pcall'\n[string \"@Interface/AddOns/Details/Libs/DF/panel.lua\"]:2364: in function <Interface/AddOns/Details/Libs/DF/panel.lua:2361>\n[string \"=[C]\"]: in function `xpcall'\n[string \"@Interface/AddOns/Details/Libs/DF/fw.lua\"]:4590: in function `CoreDispatch'\n[string \"@Interface/AddOns/Details/Libs/DF/button.lua\"]:719: in function <Interface/AddOns/Details/Libs/DF/button.lua:655>\n",
    ["NamePlateHorizontalScale"] = "[string \"=[C]\"]: in function `SetCVar'\n[string \"@Interface/AddOns/Plater/Plater.lua\"]:2314: in function `RestoreProfileCVars'\n[string \"@Interface/AddOns/Plater/Plater_OptionsPanel.lua\"]:908: in function `DoProfileImport'\n[string \"@Interface/AddOns/Plater/Plater_OptionsPanel.lua\"]:769: in function <Interface/AddOns/Plater/Plater_OptionsPanel.lua:769>\n[string \"=[C]\"]: in function `pcall'\n[string \"@Interface/AddOns/Details/Libs/DF/panel.lua\"]:2364: in function <Interface/AddOns/Details/Libs/DF/panel.lua:2361>\n[string \"=[C]\"]: in function `xpcall'\n[string \"@Interface/AddOns/Details/Libs/DF/fw.lua\"]:4590: in function `CoreDispatch'\n[string \"@Interface/AddOns/Details/Libs/DF/button.lua\"]:719: in function <Interface/AddOns/Details/Libs/DF/button.lua:655>\n",
    ["nameplateShowFriendlyGuardians"] = "[string \"=[C]\"]: in function `SetCVar'\n[string \"@Interface/AddOns/Plater/Plater.lua\"]:2314: in function `RestoreProfileCVars'\n[string \"@Interface/AddOns/Plater/Plater_OptionsPanel.lua\"]:908: in function `DoProfileImport'\n[string \"@Interface/AddOns/Plater/Plater_OptionsPanel.lua\"]:769: in function <Interface/AddOns/Plater/Plater_OptionsPanel.lua:769>\n[string \"=[C]\"]: in function `pcall'\n[string \"@Interface/AddOns/Details/Libs/DF/panel.lua\"]:2364: in function <Interface/AddOns/Details/Libs/DF/panel.lua:2361>\n[string \"=[C]\"]: in function `xpcall'\n[string \"@Interface/AddOns/Details/Libs/DF/fw.lua\"]:4590: in function `CoreDispatch'\n[string \"@Interface/AddOns/Details/Libs/DF/button.lua\"]:719: in function <Interface/AddOns/Details/Libs/DF/button.lua:655>\n",
    ["nameplateOccludedAlphaMult"] = "[string \"=[C]\"]: in function `SetCVar'\n[string \"@Interface/AddOns/Plater/Plater.lua\"]:2314: in function `RestoreProfileCVars'\n[string \"@Interface/AddOns/Plater/Plater_OptionsPanel.lua\"]:908: in function `DoProfileImport'\n[string \"@Interface/AddOns/Plater/Plater_OptionsPanel.lua\"]:769: in function <Interface/AddOns/Plater/Plater_OptionsPanel.lua:769>\n[string \"=[C]\"]: in function `pcall'\n[string \"@Interface/AddOns/Details/Libs/DF/panel.lua\"]:2364: in function <Interface/AddOns/Details/Libs/DF/panel.lua:2361>\n[string \"=[C]\"]: in function `xpcall'\n[string \"@Interface/AddOns/Details/Libs/DF/fw.lua\"]:4590: in function `CoreDispatch'\n[string \"@Interface/AddOns/Details/Libs/DF/button.lua\"]:719: in function <Interface/AddOns/Details/Libs/DF/button.lua:655>\n",
    ["ShowNamePlateLoseAggroFlash"] = "[string \"=[C]\"]: in function `SetCVar'\n[string \"@Interface/AddOns/Plater/Plater.lua\"]:2314: in function `RestoreProfileCVars'\n[string \"@Interface/AddOns/Plater/Plater_OptionsPanel.lua\"]:908: in function `DoProfileImport'\n[string \"@Interface/AddOns/Plater/Plater_OptionsPanel.lua\"]:769: in function <Interface/AddOns/Plater/Plater_OptionsPanel.lua:769>\n[string \"=[C]\"]: in function `pcall'\n[string \"@Interface/AddOns/Details/Libs/DF/panel.lua\"]:2364: in function <Interface/AddOns/Details/Libs/DF/panel.lua:2361>\n[string \"=[C]\"]: in function `xpcall'\n[string \"@Interface/AddOns/Details/Libs/DF/fw.lua\"]:4590: in function `CoreDispatch'\n[string \"@Interface/AddOns/Details/Libs/DF/button.lua\"]:719: in function <Interface/AddOns/Details/Libs/DF/button.lua:655>\n",
    ["nameplateTargetRadialPosition"] = "[string \"=[C]\"]: in function `SetCVar'\n[string \"@Interface/AddOns/Plater/Plater.lua\"]:2314: in function `RestoreProfileCVars'\n[string \"@Interface/AddOns/Plater/Plater_OptionsPanel.lua\"]:908: in function `DoProfileImport'\n[string \"@Interface/AddOns/Plater/Plater_OptionsPanel.lua\"]:769: in function <Interface/AddOns/Plater/Plater_OptionsPanel.lua:769>\n[string \"=[C]\"]: in function `pcall'\n[string \"@Interface/AddOns/Details/Libs/DF/panel.lua\"]:2364: in function <Interface/AddOns/Details/Libs/DF/panel.lua:2361>\n[string \"=[C]\"]: in function `xpcall'\n[string \"@Interface/AddOns/Details/Libs/DF/fw.lua\"]:4590: in function `CoreDispatch'\n[string \"@Interface/AddOns/Details/Libs/DF/button.lua\"]:719: in function <Interface/AddOns/Details/Libs/DF/button.lua:655>\n",
    ["nameplateShowFriends"] = "[string \"=[C]\"]: in function `SetCVar'\n[string \"@Interface/SharedXML/CvarUtil.lua\"]:72: in function `SetValue'\n[string \"@Interface/SharedXML/Settings/Blizzard_Setting.lua\"]:187: in function `SetValueInternal'\n[string \"@Interface/SharedXML/Settings/Blizzard_Setting.lua\"]:67: in function `SetValue'\n[string \"@Interface/SharedXML/Settings/Blizzard_Settings.lua\"]:229: in function `SetValue'\n[string \"ALLNAMEPLATES\"]:13: in function <[string \"ALLNAMEPLATES\"]:1>\n",
    ["ShowClassColorInNameplate"] = "[string \"=[C]\"]: in function `SetCVar'\n[string \"@Interface/AddOns/Plater/Plater.lua\"]:2314: in function `RestoreProfileCVars'\n[string \"@Interface/AddOns/Plater/Plater_OptionsPanel.lua\"]:908: in function `DoProfileImport'\n[string \"@Interface/AddOns/Plater/Plater_OptionsPanel.lua\"]:769: in function <Interface/AddOns/Plater/Plater_OptionsPanel.lua:769>\n[string \"=[C]\"]: in function `pcall'\n[string \"@Interface/AddOns/Details/Libs/DF/panel.lua\"]:2364: in function <Interface/AddOns/Details/Libs/DF/panel.lua:2361>\n[string \"=[C]\"]: in function `xpcall'\n[string \"@Interface/AddOns/Details/Libs/DF/fw.lua\"]:4590: in function `CoreDispatch'\n[string \"@Interface/AddOns/Details/Libs/DF/button.lua\"]:719: in function <Interface/AddOns/Details/Libs/DF/button.lua:655>\n",
  },
  ["url"] = "https://wago.io/xlCdA3th7/24",
  ["cast_statusbar_fadein_time"] = 0.019999999552965,
  ["indicator_raidmark_scale"] = 0.3999999761581421,
  ["aura2_y_offset"] = 0,
  ["buffs_on_aura2"] = true,
  ["health_selection_overlay"] = "Melli",
  ["expansion_triggerwipe"] = {
    [9] = true,
  },
  ["cast_statusbar_color_nointerrupt"] = {
    0.49411767721176, -- [1]
    0.49803924560547, -- [2]
    0.50196081399918, -- [3]
    0.96000000089407, -- [4]
  },
  ["npc_cache"] = {
    [169421] = {
      "Felguard", -- [1]
      "Brackenhide Hollow", -- [2]
    },
    [194241] = {
      "Vile Rothexer", -- [1]
      "Brackenhide Hollow", -- [2]
    },
    [190403] = {
      "Glacial Proto-Dragon", -- [1]
      "Halls of Infusion", -- [2]
    },
    [195265] = {
      "Stormcaller Arynga", -- [1]
      "The Nokhud Offensive", -- [2]
    },
    [183495] = {
      "Twisted Worldeater", -- [1]
      "Sepulcher of the First Ones", -- [2]
    },
    [190404] = {
      "Subterranean Proto-Dragon", -- [1]
      "Halls of Infusion", -- [2]
    },
    [190405] = {
      "Infuser Sariya", -- [1]
      "Halls of Infusion", -- [2]
    },
    [133345] = {
      "Feckless Assistant", -- [1]
      "The MOTHERLODE!!", -- [2]
    },
    [185032] = {
      "Taskmaster Xy'pro", -- [1]
      "Sepulcher of the First Ones", -- [2]
    },
    [183497] = {
      "Foul Controller", -- [1]
      "Sepulcher of the First Ones", -- [2]
    },
    [164563] = {
      "Vicious Gargon", -- [1]
      "Halls of Atonement", -- [2]
    },
    [169425] = {
      "Felhound", -- [1]
      "Brackenhide Hollow", -- [2]
    },
    [190407] = {
      "Aqua Rager", -- [1]
      "Halls of Infusion", -- [2]
    },
    [168658] = {
      "Forsworn Devastator", -- [1]
      "Spires of Ascension", -- [2]
    },
    [165076] = {
      "Gluttonous Tick", -- [1]
      "Sanguine Depths", -- [2]
    },
    [200131] = {
      "Sha-Touched Guardian", -- [1]
      "Temple of the Jade Serpent", -- [2]
    },
    [200387] = {
      "Shambling Infester", -- [1]
      "Temple of the Jade Serpent", -- [2]
    },
    [180429] = {
      "Adorned Starseer", -- [1]
      "Tazavesh, the Veiled Market", -- [2]
    },
    [201668] = {
      "Neltharion", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [169428] = {
      "Wrathguard", -- [1]
      "Brackenhide Hollow", -- [2]
    },
    [151773] = {
      "Junkyard D.0.G.", -- [1]
      "Operation: Mechagon", -- [2]
    },
    [164567] = {
      "Ingra Maloch", -- [1]
      "Mists of Tirna Scithe", -- [2]
    },
    [169429] = {
      "Shivarra", -- [1]
      "Brackenhide Hollow", -- [2]
    },
    [141283] = {
      "Kul Tiran Halberd", -- [1]
      "Siege of Boralus", -- [2]
    },
    [180432] = {
      "Devoted Accomplice", -- [1]
      "Tazavesh, the Veiled Market", -- [2]
    },
    [169430] = {
      "Ur'zul", -- [1]
      "Brackenhide Hollow", -- [2]
    },
    [136934] = {
      "Weapons Tester", -- [1]
      "The MOTHERLODE!!", -- [2]
    },
    [97285] = {
      "Wind Rush Totem", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [180433] = {
      "Wandering Pulsar", -- [1]
      "Tazavesh, the Veiled Market", -- [2]
    },
    [131817] = {
      "Cragmaw the Infested", -- [1]
      "The Underrot", -- [2]
    },
    [102019] = {
      "Stormforged Obliterator", -- [1]
      "Halls of Valor", -- [2]
    },
    [189901] = {
      "Warlord Sargha", -- [1]
      "Neltharus", -- [2]
    },
    [141285] = {
      "Kul Tiran Marksman", -- [1]
      "Siege of Boralus", -- [2]
    },
    [131818] = {
      "Marked Sister", -- [1]
      "Waycrest Manor", -- [2]
    },
    [129526] = {
      "Bilge Rat Swabby", -- [1]
      "Freehold", -- [2]
      "enUS", -- [3]
    },
    [200137] = {
      "Depraved Mistweaver", -- [1]
      "Temple of the Jade Serpent", -- [2]
    },
    [168153] = {
      "Plagueroc", -- [1]
      "Plaguefall", -- [2]
    },
    [131819] = {
      "Coven Diviner", -- [1]
      "Waycrest Manor", -- [2]
    },
    [196044] = {
      "Unruly Textbook", -- [1]
      "Algeth'ar Academy", -- [2]
    },
    [184018] = {
      "Bromach", -- [1]
      "Uldaman: Legacy of Tyr", -- [2]
    },
    [102404] = {
      "Stoneclaw Grubmaster", -- [1]
      "Neltharion's Lair", -- [2]
      "enUS", -- [3]
    },
    [100485] = {
      "Soul-torn Vanguard", -- [1]
      "Black Rook Hold", -- [2]
    },
    [176598] = {
      "Torment Golem", -- [1]
      "Torghast, Tower of the Damned", -- [2]
    },
    [59598] = {
      "Lesser Sha", -- [1]
      "Temple of the Jade Serpent", -- [2]
    },
    [129527] = {
      "Bilge Rat Buccaneer", -- [1]
      "Freehold", -- [2]
    },
    [196045] = {
      "Corrupted Manafiend", -- [1]
      "Algeth'ar Academy", -- [2]
    },
    [184019] = {
      "Burly Rock-Thrower", -- [1]
      "Uldaman: Legacy of Tyr", -- [2]
      "enUS", -- [3]
    },
    [101637] = {
      "Valarjar Aspirant", -- [1]
      "Halls of Valor", -- [2]
    },
    [131821] = {
      "Faceless Maiden", -- [1]
      "Waycrest Manor", -- [2]
    },
    [187602] = {
      "Qalashi Scaleripper", -- [1]
      "10.0 Dragon Isles", -- [2]
    },
    [175576] = {
      "Containment Cell", -- [1]
      "Tazavesh, the Veiled Market", -- [2]
    },
    [58319] = {
      "Lesser Sha", -- [1]
      "Temple of the Jade Serpent", -- [2]
    },
    [192464] = {
      "Raging Ember", -- [1]
      "Neltharus", -- [2]
    },
    [168156] = {
      "Remornia", -- [1]
      "Castle Nathria", -- [2]
    },
    [113536] = {
      "Emberhusk Dominator", -- [1]
      "Neltharion's Lair", -- [2]
      "enUS", -- [3]
    },
    [178392] = {
      "Gatewarden Zo'mazz", -- [1]
      "Tazavesh, the Veiled Market", -- [2]
    },
    [133870] = {
      "Diseased Lasher", -- [1]
      "The Underrot", -- [2]
    },
    [184022] = {
      "Stonevault Geomancer", -- [1]
      "10.0 Dragon Isles", -- [2]
    },
    [129529] = {
      "Blacktooth Scrapper", -- [1]
      "Freehold", -- [2]
    },
    [201934] = {
      "Shadowflame Amalgamation", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [113537] = {
      "Emberhusk Dominator", -- [1]
      "Neltharion's Lair", -- [2]
    },
    [81297] = {
      "Dreadfang", -- [1]
      "Iron Docks", -- [2]
    },
    [178139] = {
      "Murkbrine Shellcrusher", -- [1]
      "Tazavesh, the Veiled Market", -- [2]
    },
    [200912] = {
      "Neldris", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [164578] = {
      "Stitchflesh's Creation", -- [1]
      "The Necrotic Wake", -- [2]
    },
    [200913] = {
      "Thadrion", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [150250] = {
      "Pistonhead Blaster", -- [1]
      "Operation: Mechagon", -- [2]
    },
    [178141] = {
      "Murkbrine Scalebinder", -- [1]
      "Tazavesh, the Veiled Market", -- [2]
    },
    [137713] = {
      "Big Money Crab", -- [1]
      "The MOTHERLODE!!", -- [2]
    },
    [150251] = {
      "Pistonhead Mechanic", -- [1]
      "Operation: Mechagon", -- [2]
    },
    [178142] = {
      "Murkbrine Fishmancer", -- [1]
      "Tazavesh, the Veiled Market", -- [2]
    },
    [137458] = {
      "Rotting Spore", -- [1]
      "The Underrot", -- [2]
    },
    [199124] = {
      "Primalist Chillblaster", -- [1]
      "Vault of the Incarnates", -- [2]
    },
    [126845] = {
      "Captain Jolly", -- [1]
      "Freehold", -- [2]
    },
    [131318] = {
      "Elder Leaxa", -- [1]
      "The Underrot", -- [2]
    },
    [168420] = {
      "Forsworn Champion", -- [1]
      "Spires of Ascension", -- [2]
    },
    [150253] = {
      "Weaponized Crawler", -- [1]
      "Operation: Mechagon", -- [2]
    },
    [168932] = {
      "Doomguard", -- [1]
      "Brackenhide Hollow", -- [2]
    },
    [82579] = {
      "Grom'kar Far Seer", -- [1]
      "Grimrail Depot", -- [2]
    },
    [129788] = {
      "Irontide Bonesaw", -- [1]
      "Freehold", -- [2]
    },
    [190426] = {
      "Decay Totem", -- [1]
      "Brackenhide Hollow", -- [2]
    },
    [198870] = {
      "Sundered Preserver", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [137716] = {
      "Bottom Feeder", -- [1]
      "The MOTHERLODE!!", -- [2]
    },
    [197847] = {
      "Gnawbone Splintershield", -- [1]
      "10.0 Dragon Isles", -- [2]
    },
    [177889] = {
      "Mawforged Souljudge", -- [1]
      "Sanctum of Domination", -- [2]
    },
    [198871] = {
      "Sundered Scaleguard", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [168934] = {
      "Enraged Spirit", -- [1]
      "De Other Side", -- [2]
    },
    [198872] = {
      "Sundered Manaweaver", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [45912] = {
      "Wild Vortex", -- [1]
      "The Vortex Pinnacle", -- [2]
    },
    [126847] = {
      "Captain Raoul", -- [1]
      "Freehold", -- [2]
      "enUS", -- [3]
    },
    [198873] = {
      "Sundered Edgelord", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [134137] = {
      "Temple Attendant", -- [1]
      "Shrine of the Storm", -- [2]
    },
    [190174] = {
      "Hypnosis Bat", -- [1]
      "Operation: Mechagon", -- [2]
    },
    [198874] = {
      "Sundered Siegemaster", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [168425] = {
      "Forsworn Annihilator", -- [1]
      "Spires of Ascension", -- [2]
    },
    [168681] = {
      "Forsworn Helion", -- [1]
      "Spires of Ascension", -- [2]
    },
    [197595] = {
      "Earthwrought Smasher", -- [1]
      "Vault of the Incarnates", -- [2]
    },
    [126848] = {
      "Captain Eudora", -- [1]
      "Freehold", -- [2]
    },
    [94224] = {
      "Petrifying Totem", -- [1]
      "Neltharion's Lair", -- [2]
    },
    [202969] = {
      "Empty Recollection", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [136186] = {
      "Tidesage Spiritualist", -- [1]
      "Shrine of the Storm", -- [2]
    },
    [172265] = {
      "Remnant of Fury", -- [1]
      "Sanguine Depths", -- [2]
    },
    [160495] = {
      "Maniacal Soulbinder", -- [1]
      "Theater of Pain", -- [2]
    },
    [186339] = {
      "Teera", -- [1]
      "The Nokhud Offensive", -- [2]
    },
    [202971] = {
      "Null Glimmer", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [193760] = {
      "Surging Ruiner", -- [1]
      "Vault of the Incarnates", -- [2]
    },
    [192481] = {
      "Decaying Slime", -- [1]
      "Brackenhide Hollow", -- [2]
    },
    [81432] = {
      "Grom'kar Technician", -- [1]
      "Iron Docks", -- [2]
    },
    [114312] = {
      "Moroes", -- [1]
      "Return to Karazhan", -- [2]
    },
    [196576] = {
      "Spellbound Scepter", -- [1]
      "Algeth'ar Academy", -- [2]
    },
    [127106] = {
      "Irontide Officer", -- [1]
      "Freehold", -- [2]
    },
    [168942] = {
      "Death Speaker", -- [1]
      "De Other Side", -- [2]
    },
    [165872] = {
      "Flesh Crafter", -- [1]
      "The Necrotic Wake", -- [2]
    },
    [131585] = {
      "Enthralled Guard", -- [1]
      "Waycrest Manor", -- [2]
    },
    [134144] = {
      "Living Current", -- [1]
      "Shrine of the Storm", -- [2]
    },
    [197857] = {
      "Gutstabber", -- [1]
      "Brackenhide Hollow", -- [2]
    },
    [102287] = {
      "Emberhusk Dominator", -- [1]
      "Neltharion's Lair", -- [2]
    },
    [131586] = {
      "Banquet Steward", -- [1]
      "Waycrest Manor", -- [2]
    },
    [135169] = {
      "Spirit Drain Totem", -- [1]
      "The Underrot", -- [2]
    },
    [170480] = {
      "Atal'ai Deathwalker", -- [1]
      "De Other Side", -- [2]
    },
    [191206] = {
      "Primalist Mage", -- [1]
      "Vault of the Incarnates", -- [2]
    },
    [98706] = {
      "Commander Shemdah'sohn", -- [1]
      "Black Rook Hold", -- [2]
    },
    [196581] = {
      "White Tiger Statue", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [162038] = {
      "Regal Mistdancer", -- [1]
      "Sanguine Depths", -- [2]
    },
    [130435] = {
      "Addled Thug", -- [1]
      "The MOTHERLODE!!", -- [2]
    },
    [45915] = {
      "Armored Mistral", -- [1]
      "The Vortex Pinnacle", -- [2]
    },
    [81819] = {
      "Everbloom Naturalist", -- [1]
      "The Everbloom", -- [2]
    },
    [184300] = {
      "Ebonstone Golem", -- [1]
      "Uldaman: Legacy of Tyr", -- [2]
    },
    [162039] = {
      "Wicked Oppressor", -- [1]
      "Sanguine Depths", -- [2]
    },
    [170483] = {
      "Atal'ai Deathwalker's Spirit", -- [1]
      "De Other Side", -- [2]
    },
    [76446] = {
      "Shadowmoon Dominator", -- [1]
      "Shadowmoon Burial Grounds", -- [2]
    },
    [184301] = {
      "Cavern Seeker", -- [1]
      "Uldaman: Legacy of Tyr", -- [2]
    },
    [162040] = {
      "Grand Overseer", -- [1]
      "Sanguine Depths", -- [2]
    },
    [130436] = {
      "Off-Duty Laborer", -- [1]
      "The MOTHERLODE!!", -- [2]
    },
    [134150] = {
      "Runecarver Sorn", -- [1]
      "Shrine of the Storm", -- [2]
    },
    [114316] = {
      "Baroness Dorothea Millstipe", -- [1]
      "Return to Karazhan", -- [2]
    },
    [81820] = {
      "Everbloom Mender", -- [1]
      "The Everbloom", -- [2]
    },
    [173044] = {
      "Stitching Assistant", -- [1]
      "The Necrotic Wake", -- [2]
    },
    [184303] = {
      "Skittering Crawler", -- [1]
      "Uldaman: Legacy of Tyr", -- [2]
      "enUS", -- [3]
    },
    [137478] = {
      "Queen Wasi", -- [1]
      "Kings' Rest", -- [2]
    },
    [156157] = {
      "Coldheart Ascendant", -- [1]
      "Torghast, Tower of the Damned", -- [2]
    },
    [95766] = {
      "Crazed Razorbeak", -- [1]
      "Darkheart Thicket", -- [2]
    },
    [114317] = {
      "Lady Catriona Von'Indi", -- [1]
      "Return to Karazhan", -- [2]
    },
    [126983] = {
      "Harlan Sweete", -- [1]
      "Freehold", -- [2]
      "enUS", -- [3]
    },
    [127111] = {
      "Irontide Oarsman", -- [1]
      "Freehold", -- [2]
    },
    [191469] = {
      "Streamside Scythid", -- [1]
      "10.0 Dragon Isles", -- [2]
    },
    [175861] = {
      "Glacial Spike", -- [1]
      "Sanctum of Domination", -- [2]
    },
    [83613] = {
      "Koramar", -- [1]
      "Iron Docks", -- [2]
    },
    [63508] = {
      "Xuen", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [143622] = {
      "Wild Imp", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [199659] = {
      "Warlord Kagni", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
    },
    [82590] = {
      "Grimrail Scout", -- [1]
      "Grimrail Depot", -- [2]
    },
    [170490] = {
      "Atal'ai High Priest", -- [1]
      "De Other Side", -- [2]
    },
    [150276] = {
      "Heavy Scrapbot", -- [1]
      "Operation: Mechagon", -- [2]
    },
    [164861] = {
      "Spriggan Barkbinder", -- [1]
      "De Other Side", -- [2]
    },
    [45917] = {
      "Cloud Prince", -- [1]
      "The Vortex Pinnacle", -- [2]
    },
    [162047] = {
      "Insatiable Brute", -- [1]
      "Sanguine Depths", -- [2]
    },
    [96664] = {
      "Valarjar Runecarver", -- [1]
      "Halls of Valor", -- [2]
    },
    [134157] = {
      "Shadow-Borne Warrior", -- [1]
      "Kings' Rest", -- [2]
    },
    [56792] = {
      "Figment of Doubt", -- [1]
      "Temple of the Jade Serpent", -- [2]
    },
    [137484] = {
      "King A'akul", -- [1]
      "Kings' Rest", -- [2]
    },
    [134158] = {
      "Shadow-Borne Champion", -- [1]
      "Kings' Rest", -- [2]
    },
    [162049] = {
      "Vestige of Doubt", -- [1]
      "Sanguine Depths", -- [2]
    },
    [168446] = {
      "Skeletal Monstrosity", -- [1]
      "The Necrotic Wake", -- [2]
    },
    [174843] = {
      "Stoneborn Maitre D'", -- [1]
      "Castle Nathria", -- [2]
    },
    [205804] = {
      "Risen Dragon", -- [1]
      "Dawn of the Infinite", -- [2]
      "enUS", -- [3]
    },
    [180473] = {
      "Unstoppable Abomination", -- [1]
      "Sanctum of Domination", -- [2]
    },
    [178171] = {
      "Stormforged Guardian", -- [1]
      "Tazavesh, the Veiled Market", -- [2]
    },
    [180474] = {
      "Soul Reaver", -- [1]
      "Sanctum of Domination", -- [2]
    },
    [183033] = {
      "Grim Reflection", -- [1]
      "Sepulcher of the First Ones", -- [2]
    },
    [138255] = {
      "Ashvane Spotter", -- [1]
      "Siege of Boralus", -- [2]
    },
    [134417] = {
      "Deepsea Ritualist", -- [1]
      "Shrine of the Storm", -- [2]
    },
    [182778] = {
      "Collapsing Quasar", -- [1]
      "Sepulcher of the First Ones", -- [2]
    },
    [95771] = {
      "Dreadsoul Ruiner", -- [1]
      "Darkheart Thicket", -- [2]
    },
    [134418] = {
      "Drowned Depthbringer", -- [1]
      "Shrine of the Storm", -- [2]
    },
    [59544] = {
      "The Nodding Tiger", -- [1]
      "Temple of the Jade Serpent", -- [2]
    },
    [129547] = {
      "Blacktooth Knuckleduster", -- [1]
      "Freehold", -- [2]
    },
    [27829] = {
      "Ebon Gargoyle", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [187897] = {
      "Defier Draghar", -- [1]
      "Ruby Life Pools", -- [2]
    },
    [45919] = {
      "Young Storm Dragon", -- [1]
      "The Vortex Pinnacle", -- [2]
    },
    [186107] = {
      "Vault Keeper", -- [1]
      "Uldaman: Legacy of Tyr", -- [2]
    },
    [129548] = {
      "Blacktooth Brute", -- [1]
      "Freehold", -- [2]
    },
    [206066] = {
      "Timestream Leech", -- [1]
      "Dawn of the Infinite", -- [2]
      "enUS", -- [3]
    },
    [127757] = {
      "Reanimated Honor Guard", -- [1]
      "Atal'Dazar", -- [2]
    },
    [104217] = {
      "Talixae Flamewreath", -- [1]
      "Court of Stars", -- [2]
    },
    [162057] = {
      "Chamber Sentinel", -- [1]
      "Sanguine Depths", -- [2]
    },
    [59545] = {
      "The Golden Beetle", -- [1]
      "Temple of the Jade Serpent", -- [2]
    },
    [131864] = {
      "Gorak Tul", -- [1]
      "Waycrest Manor", -- [2]
    },
    [136214] = {
      "Windspeaker Heldis", -- [1]
      "Shrine of the Storm", -- [2]
    },
    [136470] = {
      "Refreshment Vendor", -- [1]
      "The MOTHERLODE!!", -- [2]
    },
    [80805] = {
      "Makogg Emberblade", -- [1]
      "Iron Docks", -- [2]
    },
    [184319] = {
      "Refti Custodian", -- [1]
      "Uldaman: Legacy of Tyr", -- [2]
    },
    [133912] = {
      "Bloodsworn Defiler", -- [1]
      "The Underrot", -- [2]
    },
    [164873] = {
      "Runestag Elderhorn", -- [1]
      "De Other Side", -- [2]
    },
    [43873] = {
      "Altairus", -- [1]
      "The Vortex Pinnacle", -- [2]
    },
    [127119] = {
      "Freehold Deckhand", -- [1]
      "Freehold", -- [2]
      "enUS", -- [3]
    },
    [129550] = {
      "Bilge Rat Padfoot", -- [1]
      "Freehold", -- [2]
      "enUS", -- [3]
    },
    [82597] = {
      "Grom'kar Captain", -- [1]
      "Grimrail Depot", -- [2]
    },
    [190206] = {
      "Primalist Flamedancer", -- [1]
      "Ruby Life Pools", -- [2]
    },
    [191230] = {
      "Dragonspawn Flamebender", -- [1]
      "Vault of the Incarnates", -- [2]
    },
    [190207] = {
      "Primalist Cinderweaver", -- [1]
      "Ruby Life Pools", -- [2]
    },
    [59546] = {
      "The Talking Fish", -- [1]
      "Temple of the Jade Serpent", -- [2]
    },
    [80935] = {
      "Grom'kar Boomer", -- [1]
      "Grimrail Depot", -- [2]
    },
    [192767] = {
      "Primal Icebulk", -- [1]
      "Vault of the Incarnates", -- [2]
    },
    [191232] = {
      "Drakonid Stormbringer", -- [1]
      "Vault of the Incarnates", -- [2]
    },
    [163086] = {
      "Rancid Gasbag", -- [1]
      "Theater of Pain", -- [2]
    },
    [184580] = {
      "Olaf", -- [1]
      "Uldaman: Legacy of Tyr", -- [2]
    },
    [132126] = {
      "Gilded Priestess", -- [1]
      "Atal'Dazar", -- [2]
    },
    [206074] = {
      "Pendule", -- [1]
      "Dawn of the Infinite", -- [2]
      "enUS", -- [3]
    },
    [80808] = {
      "Neesa Nox", -- [1]
      "Iron Docks", -- [2]
    },
    [80936] = {
      "Grom'kar Grenadier", -- [1]
      "Grimrail Depot", -- [2]
    },
    [194816] = {
      "Forgewrought Monstrosity", -- [1]
      "Neltharus", -- [2]
    },
    [168717] = {
      "Forsworn Justicar", -- [1]
      "Spires of Ascension", -- [2]
    },
    [134174] = {
      "Shadow-Borne Witch Doctor", -- [1]
      "Kings' Rest", -- [2]
    },
    [114584] = {
      "Phantom Crew", -- [1]
      "Return to Karazhan", -- [2]
    },
    [102430] = {
      "Tarspitter Slug", -- [1]
      "Neltharion's Lair", -- [2]
      "enUS", -- [3]
    },
    [184582] = {
      "Eric \"The Swift\"", -- [1]
      "Uldaman: Legacy of Tyr", -- [2]
    },
    [59547] = {
      "Jiang", -- [1]
      "Temple of the Jade Serpent", -- [2]
    },
    [168718] = {
      "Forsworn Warden", -- [1]
      "Spires of Ascension", -- [2]
    },
    [205820] = {
      "Crawling Goo", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [80937] = {
      "Grom'kar Gunner", -- [1]
      "Grimrail Depot", -- [2]
    },
    [176395] = {
      "Overloaded Mailemental", -- [1]
      "Tazavesh, the Veiled Market", -- [2]
    },
    [195842] = {
      "Ukhel Corruptor", -- [1]
      "The Nokhud Offensive", -- [2]
    },
    [98081] = {
      "Bellowing Idol", -- [1]
      "Neltharion's Lair", -- [2]
      "enUS", -- [3]
    },
    [176396] = {
      "Defective Sorter", -- [1]
      "Tazavesh, the Veiled Market", -- [2]
    },
    [150297] = {
      "Mechagon Renormalizer", -- [1]
      "Operation: Mechagon", -- [2]
    },
    [84520] = {
      "Pitwarden Gwarnok", -- [1]
      "Iron Docks", -- [2]
    },
    [80938] = {
      "Grom'kar Hulk", -- [1]
      "Grimrail Depot", -- [2]
    },
    [186121] = {
      "Decatriarch Wratheye", -- [1]
      "Brackenhide Hollow", -- [2]
    },
    [127124] = {
      "Freehold Barhand", -- [1]
      "Freehold", -- [2]
      "enUS", -- [3]
    },
    [186122] = {
      "Rira Hackclaw", -- [1]
      "Brackenhide Hollow", -- [2]
    },
    [184331] = {
      "Infinite Timereaver", -- [1]
      "Uldaman: Legacy of Tyr", -- [2]
    },
    [153882] = {
      "Deadsoul Spirit", -- [1]
      "Torghast, Tower of the Damned", -- [2]
    },
    [193799] = {
      "Rotchanting Totem", -- [1]
      "Brackenhide Hollow", -- [2]
    },
    [196102] = {
      "Conjured Lasher", -- [1]
      "The Azure Vault", -- [2]
    },
    [167956] = {
      "Dark Acolyte", -- [1]
      "Sanguine Depths", -- [2]
    },
    [189706] = {
      "Chaotic Essence", -- [1]
      "Castle Nathria", -- [2]
    },
    [186124] = {
      "Gashtooth", -- [1]
      "Brackenhide Hollow", -- [2]
    },
    [180495] = {
      "Enraged Direhorn", -- [1]
      "Tazavesh, the Veiled Market", -- [2]
    },
    [186125] = {
      "Tricktotem", -- [1]
      "Brackenhide Hollow", -- [2]
    },
    [165911] = {
      "Loyal Creation", -- [1]
      "The Necrotic Wake", -- [2]
    },
    [201222] = {
      "Valow, Timesworn Keeper", -- [1]
      "Dawn of the Infinite", -- [2]
      "enUS", -- [3]
    },
    [184335] = {
      "Infinite Agent", -- [1]
      "Uldaman: Legacy of Tyr", -- [2]
    },
    [201223] = {
      "Infinite Twilight Magus", -- [1]
      "Dawn of the Infinite", -- [2]
      "enUS", -- [3]
    },
    [193291] = {
      "Apex Blazewing", -- [1]
      "Neltharus", -- [2]
    },
    [45924] = {
      "Turbulent Squall", -- [1]
      "The Vortex Pinnacle", -- [2]
    },
    [194315] = {
      "Stormcaller Solongo", -- [1]
      "The Nokhud Offensive", -- [2]
    },
    [165913] = {
      "Ghastly Parishioner", -- [1]
      "Halls of Atonement", -- [2]
    },
    [137511] = {
      "Bilge Rat Cutthroat", -- [1]
      "Siege of Boralus", -- [2]
    },
    [201736] = {
      "Sundered Arcanist", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [195851] = {
      "Ukhel Deathspeaker", -- [1]
      "The Nokhud Offensive", -- [2]
    },
    [194316] = {
      "Stormcaller Zarii", -- [1]
      "The Nokhud Offensive", -- [2]
    },
    [193293] = {
      "Qalashi Warden", -- [1]
      "Neltharus", -- [2]
    },
    [114334] = {
      "Damaged Golem", -- [1]
      "Return to Karazhan", -- [2]
    },
    [194317] = {
      "Stormcaller Boroo", -- [1]
      "The Nokhud Offensive", -- [2]
    },
    [201738] = {
      "Renewed Hatchling", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [45477] = {
      "Gust Soldier", -- [1]
      "The Vortex Pinnacle", -- [2]
    },
    [167963] = {
      "Headless Client", -- [1]
      "De Other Side", -- [2]
    },
    [187154] = {
      "Arcane Curator", -- [1]
      "The Azure Vault", -- [2]
    },
    [167964] = {
      "4.RF-4.RF", -- [1]
      "De Other Side", -- [2]
    },
    [78001] = {
      "Cloudburst Totem", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [187155] = {
      "Rune Seal Keeper", -- [1]
      "The Azure Vault", -- [2]
    },
    [196111] = {
      "Pit Lord", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [80816] = {
      "Ahri'ok Dugru", -- [1]
      "Iron Docks", -- [2]
    },
    [167965] = {
      "Lubricator", -- [1]
      "De Other Side", -- [2]
    },
    [186644] = {
      "Leymor", -- [1]
      "The Azure Vault", -- [2]
    },
    [165919] = {
      "Skeletal Marauder", -- [1]
      "The Necrotic Wake", -- [2]
    },
    [192786] = {
      "Qalashi Plunderer", -- [1]
      "Neltharus", -- [2]
    },
    [115488] = {
      "Infused Pyromancer", -- [1]
      "Return to Karazhan", -- [2]
    },
    [171805] = {
      "Research Scribe", -- [1]
      "Sanguine Depths", -- [2]
    },
    [167967] = {
      "Sentient Oil", -- [1]
      "De Other Side", -- [2]
    },
    [197905] = {
      "Spellbound Scepter", -- [1]
      "Algeth'ar Academy", -- [2]
    },
    [163618] = {
      "Zolramus Necromancer", -- [1]
      "The Necrotic Wake", -- [2]
    },
    [192788] = {
      "Qalashi Thaumaturge", -- [1]
      "Neltharus", -- [2]
    },
    [168992] = {
      "Risen Cultist", -- [1]
      "De Other Side", -- [2]
    },
    [202256] = {
      "Djaradin Lavamancer", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [192789] = {
      "Nokhud Longbow", -- [1]
      "The Nokhud Offensive", -- [2]
    },
    [187160] = {
      "Crystal Fury", -- [1]
      "The Azure Vault", -- [2]
    },
    [114338] = {
      "Mana Confluence", -- [1]
      "Return to Karazhan", -- [2]
    },
    [202257] = {
      "Djaradin Magmashaper", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [204560] = {
      "Incorporeal Being", -- [1]
      "Freehold", -- [2]
      "enUS", -- [3]
    },
    [135474] = {
      "Thistle Acolyte", -- [1]
      "Waycrest Manor", -- [2]
    },
    [59552] = {
      "The Crybaby Hozen", -- [1]
      "Temple of the Jade Serpent", -- [2]
    },
    [201746] = {
      "Sundered Naturalist", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [202258] = {
      "Djaradin Skullcrusher", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [163621] = {
      "Goregrind", -- [1]
      "The Necrotic Wake", -- [2]
    },
    [202259] = {
      "Djaradin Wallclimber", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [182045] = {
      "Necrotic Ritualist", -- [1]
      "Sepulcher of the First Ones", -- [2]
    },
    [133685] = {
      "Befouled Spirit", -- [1]
      "The Underrot", -- [2]
    },
    [189466] = {
      "Irontorch Commander", -- [1]
      "Neltharus", -- [2]
    },
    [189722] = {
      "Gulping Goliath", -- [1]
      "Halls of Infusion", -- [2]
    },
    [165414] = {
      "Depraved Obliterator", -- [1]
      "Halls of Atonement", -- [2]
    },
    [133430] = {
      "Venture Co. Mastermind", -- [1]
      "The MOTHERLODE!!", -- [2]
    },
    [189467] = {
      "Qalashi Bonesplitter", -- [1]
      "Neltharus", -- [2]
    },
    [83763] = {
      "Grom'kar Technician", -- [1]
      "Iron Docks", -- [2]
    },
    [59553] = {
      "The Songbird Queen", -- [1]
      "Temple of the Jade Serpent", -- [2]
    },
    [199703] = {
      "Magma Mystic", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
    },
    [202262] = {
      "Blazing Dreadsquall", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [59873] = {
      "Corrupt Living Water", -- [1]
      "Temple of the Jade Serpent", -- [2]
    },
    [133432] = {
      "Venture Co. Alchemist", -- [1]
      "The MOTHERLODE!!", -- [2]
    },
    [45928] = {
      "Executor of the Caliph", -- [1]
      "The Vortex Pinnacle", -- [2]
    },
    [83892] = {
      "Life Warden Gola", -- [1]
      "The Everbloom", -- [2]
    },
    [163882] = {
      "Decaying Flesh Giant", -- [1]
      "Plaguefall", -- [2]
    },
    [192796] = {
      "Nokhud Hornsounder", -- [1]
      "The Nokhud Offensive", -- [2]
    },
    [189470] = {
      "Lava Flare", -- [1]
      "Neltharus", -- [2]
    },
    [202264] = {
      "Primal Lava Elemental", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [188703] = {
      "Protoform Barrier", -- [1]
      "Castle Nathria", -- [2]
    },
    [201753] = {
      "Sundered Destroyer", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [189727] = {
      "Khajin the Unyielding", -- [1]
      "Halls of Infusion", -- [2]
    },
    [83765] = {
      "Grom'kar Footsoldier", -- [1]
      "Iron Docks", -- [2]
    },
    [83893] = {
      "Earthshaper Telu", -- [1]
      "The Everbloom", -- [2]
    },
    [201754] = {
      "Sarkareth", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
    },
    [89011] = {
      "Rylak Skyterror", -- [1]
      "Iron Docks", -- [2]
    },
    [186658] = {
      "Stonevault Geomancer", -- [1]
      "Uldaman: Legacy of Tyr", -- [2]
    },
    [205337] = {
      "Infinite Timebender", -- [1]
      "Dawn of the Infinite", -- [2]
    },
    [168747] = {
      "Venomfang", -- [1]
      "Plaguefall", -- [2]
    },
    [192800] = {
      "Nokhud Lancemaster", -- [1]
      "The Nokhud Offensive", -- [2]
    },
    [197406] = {
      "Aggravated Skitterfly", -- [1]
      "Algeth'ar Academy", -- [2]
    },
    [75451] = {
      "Defiled Spirit", -- [1]
      "Shadowmoon Burial Grounds", -- [2]
    },
    [100527] = {
      "Dreadfire Imp", -- [1]
      "Darkheart Thicket", -- [2]
    },
    [156212] = {
      "Coldheart Agent", -- [1]
      "Torghast, Tower of the Damned", -- [2]
    },
    [163121] = {
      "Stitched Vanguard", -- [1]
      "The Necrotic Wake", -- [2]
    },
    [189988] = {
      "Thing From Beyond", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [203806] = {
      "Whisper in the Dark", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [45930] = {
      "Minister of Air", -- [1]
      "The Vortex Pinnacle", -- [2]
    },
    [186151] = {
      "Balakar Khan", -- [1]
      "The Nokhud Offensive", -- [2]
    },
    [162099] = {
      "General Kaal", -- [1]
      "Sanguine Depths", -- [2]
    },
    [189478] = {
      "Forgemaster Gorek", -- [1]
      "Neltharus", -- [2]
    },
    [97202] = {
      "Olmyr the Enlightened", -- [1]
      "Halls of Valor", -- [2]
    },
    [163891] = {
      "Rotmarrow Slime", -- [1]
      "Plaguefall", -- [2]
    },
    [186664] = {
      "Stonevault Ambusher", -- [1]
      "Uldaman: Legacy of Tyr", -- [2]
    },
    [203809] = {
      "Entropic Hatred", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [129699] = {
      "Ludwig Von Tortollan", -- [1]
      "Freehold", -- [2]
    },
    [184107] = {
      "Runic Protector", -- [1]
      "Uldaman: Legacy of Tyr", -- [2]
    },
    [135235] = {
      "Spectral Beastmaster", -- [1]
      "Kings' Rest", -- [2]
    },
    [195878] = {
      "Ukhel Beastcaller", -- [1]
      "The Nokhud Offensive", -- [2]
    },
    [163894] = {
      "Blighted Spinebreaker", -- [1]
      "Plaguefall", -- [2]
    },
    [162103] = {
      "Executor Tarvold", -- [1]
      "Sanguine Depths", -- [2]
    },
    [199717] = {
      "Nokhud Defender", -- [1]
      "The Nokhud Offensive", -- [2]
    },
    [165430] = {
      "Malignant Spawn", -- [1]
      "Plaguefall", -- [2]
    },
    [180015] = {
      "Burly Deckhand", -- [1]
      "Tazavesh, the Veiled Market", -- [2]
    },
    [81212] = {
      "Grimrail Overseer", -- [1]
      "Grimrail Depot", -- [2]
    },
    [136005] = {
      "Rowdy Reveler", -- [1]
      "The MOTHERLODE!!", -- [2]
    },
    [197671] = {
      "Volatile Infuser", -- [1]
      "Vault of the Incarnates", -- [2]
    },
    [163128] = {
      "Zolramus Sorcerer", -- [1]
      "The Necrotic Wake", -- [2]
    },
    [100531] = {
      "Bloodtainted Fury", -- [1]
      "Darkheart Thicket", -- [2]
    },
    [136006] = {
      "Rowdy Reveler", -- [1]
      "The MOTHERLODE!!", -- [2]
    },
    [113197] = {
      "Understone Drudge", -- [1]
      "Neltharion's Lair", -- [2]
      "enUS", -- [3]
    },
    [135239] = {
      "Spectral Witch Doctor", -- [1]
      "Kings' Rest", -- [2]
    },
    [164921] = {
      "Drust Harvester", -- [1]
      "Mists of Tirna Scithe", -- [2]
    },
    [45932] = {
      "Skyfall Star", -- [1]
      "The Vortex Pinnacle", -- [2]
    },
    [135240] = {
      "Soul Essence", -- [1]
      "UNKNOWN", -- [2]
    },
    [131402] = {
      "Underrot Tick", -- [1]
      "The Underrot", -- [2]
      "enUS", -- [3]
    },
    [166969] = {
      "Baroness Frieda", -- [1]
      "Castle Nathria", -- [2]
    },
    [208165] = {
      "Alliance Knight", -- [1]
      "Dawn of the Infinite", -- [2]
    },
    [177716] = {
      "So' Cartel Assassin", -- [1]
      "Tazavesh, the Veiled Market", -- [2]
    },
    [165946] = {
      "Mordretha, the Endless Empress", -- [1]
      "Theater of Pain", -- [2]
    },
    [83389] = {
      "Ironwing Flamespitter", -- [1]
      "Iron Docks", -- [2]
    },
    [166970] = {
      "Lord Stavros", -- [1]
      "Castle Nathria", -- [2]
    },
    [40943] = {
      "Gilgoblin Aquamage", -- [1]
      "Throne of the Tides", -- [2]
    },
    [189232] = {
      "Kokia Blazehoof", -- [1]
      "Ruby Life Pools", -- [2]
    },
    [166971] = {
      "Castellan Niklaus", -- [1]
      "Castle Nathria", -- [2]
    },
    [152898] = {
      "Deadsoul Chorus", -- [1]
      "Torghast, Tower of the Damned", -- [2]
    },
    [83390] = {
      "Thunderlord Wrangler", -- [1]
      "Iron Docks", -- [2]
    },
    [164414] = {
      "Reanimated Mage", -- [1]
      "The Necrotic Wake", -- [2]
    },
    [189234] = {
      "Frostbreath Arachnid", -- [1]
      "Vault of the Incarnates", -- [2]
    },
    [164926] = {
      "Drust Boughbreaker", -- [1]
      "Mists of Tirna Scithe", -- [2]
    },
    [212775] = {
      "Faceless Seer", -- [1]
      "Throne of the Tides", -- [2]
    },
    [186420] = {
      "Earthen Weaver", -- [1]
      "Uldaman: Legacy of Tyr", -- [2]
    },
    [201261] = {
      "Kazzara, the Hellforged", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [205611] = {
      "Molten Hound", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [201773] = {
      "Eternal Blaze", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [75459] = {
      "Plagued Bat", -- [1]
      "Shadowmoon Burial Grounds", -- [2]
    },
    [134990] = {
      "Charged Dust Devil", -- [1]
      "Temple of Sethraliss", -- [2]
    },
    [167998] = {
      "Portal Guardian", -- [1]
      "Theater of Pain", -- [2]
    },
    [138061] = {
      "Venture Co. Longshoreman", -- [1]
      "The MOTHERLODE!!", -- [2]
    },
    [201774] = {
      "Essence of Shadow", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [95674] = {
      "Fenryr", -- [1]
      "Halls of Valor", -- [2]
    },
    [164929] = {
      "Tirnenn Villager", -- [1]
      "Mists of Tirna Scithe", -- [2]
    },
    [104246] = {
      "Duskwatch Guard", -- [1]
      "Court of Stars", -- [2]
    },
    [127019] = {
      "Training Dummy", -- [1]
      "Freehold", -- [2]
      "enUS", -- [3]
    },
    [131666] = {
      "Coven Thornshaper", -- [1]
      "Waycrest Manor", -- [2]
    },
    [138063] = {
      "Posh Vacationer", -- [1]
      "The MOTHERLODE!!", -- [2]
    },
    [185656] = {
      "Filth Caller", -- [1]
      "Brackenhide Hollow", -- [2]
    },
    [187192] = {
      "Rageclaw", -- [1]
      "Brackenhide Hollow", -- [2]
    },
    [65317] = {
      "Xiang", -- [1]
      "Temple of the Jade Serpent", -- [2]
    },
    [152905] = {
      "Tower Sentinel", -- [1]
      "Torghast, Tower of the Damned", -- [2]
    },
    [104247] = {
      "Duskwatch Arcanist", -- [1]
      "Court of Stars", -- [2]
    },
    [203825] = {
      "Voracious Magma Worm", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [199220] = {
      "Violetwing Stagbeetle", -- [1]
      "10.0 Dragon Isles", -- [2]
    },
    [176959] = {
      "Mawsworn Soulmage", -- [1]
      "Sanctum of Domination", -- [2]
    },
    [203826] = {
      "Colossal Draconic Golem", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [45935] = {
      "Temple Adept", -- [1]
      "The Vortex Pinnacle", -- [2]
    },
    [184124] = {
      "Sentinel Talondras", -- [1]
      "Uldaman: Legacy of Tyr", -- [2]
      "enUS", -- [3]
    },
    [92350] = {
      "Understone Drudge", -- [1]
      "Neltharion's Lair", -- [2]
      "enUS", -- [3]
    },
    [131670] = {
      "Heartsbane Vinetwister", -- [1]
      "Waycrest Manor", -- [2]
    },
    [205618] = {
      "Thorak Greenscale", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [167493] = {
      "Venomous Sniper", -- [1]
      "Plaguefall", -- [2]
    },
    [184125] = {
      "Chrono-Lord Deios", -- [1]
      "Uldaman: Legacy of Tyr", -- [2]
      "enUS", -- [3]
    },
    [205363] = {
      "Time-Lost Waveshaper", -- [1]
      "Dawn of the Infinite", -- [2]
    },
    [205619] = {
      "Sarek Cinderbreath", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [205620] = {
      "Malgosa Spellbinder", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [55659] = {
      "Wild Imp", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [168007] = {
      "Empowered Mawsworn Soulbinder", -- [1]
      "Torghast, Tower of the Damned", -- [2]
    },
    [179010] = {
      "Fatespawn Anomaly", -- [1]
      "Sanctum of Domination", -- [2]
    },
    [134232] = {
      "Hired Assassin", -- [1]
      "The MOTHERLODE!!", -- [2]
    },
    [96574] = {
      "Stormforged Sentinel", -- [1]
      "Halls of Valor", -- [2]
    },
    [205622] = {
      "Krono Sandtongue", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [203831] = {
      "Crystalline Guardian", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [115765] = {
      "Abstract Nullifier", -- [1]
      "Return to Karazhan", -- [2]
    },
    [189247] = {
      "Tamed Phoenix", -- [1]
      "Neltharus", -- [2]
    },
    [104251] = {
      "Duskwatch Sentry", -- [1]
      "Court of Stars", -- [2]
    },
    [184130] = {
      "Earthen Custodian", -- [1]
      "Uldaman: Legacy of Tyr", -- [2]
    },
    [135258] = {
      "Irontide Marauder", -- [1]
      "Siege of Boralus", -- [2]
    },
    [41139] = {
      "Naz'jar Oracle", -- [1]
      "Throne of the Tides", -- [2]
    },
    [179269] = {
      "Oasis Security", -- [1]
      "Tazavesh, the Veiled Market", -- [2]
    },
    [187969] = {
      "Flashfrost Earthshaper", -- [1]
      "Ruby Life Pools", -- [2]
    },
    [184131] = {
      "Earthen Guardian", -- [1]
      "Uldaman: Legacy of Tyr", -- [2]
    },
    [101437] = {
      "Burning Geode", -- [1]
      "UNKNOWN", -- [2]
    },
    [131677] = {
      "Heartsbane Runeweaver", -- [1]
      "Waycrest Manor", -- [2]
    },
    [165197] = {
      "Skeletal Monstrosity", -- [1]
      "The Necrotic Wake", -- [2]
    },
    [184132] = {
      "Earthen Warder", -- [1]
      "Uldaman: Legacy of Tyr", -- [2]
    },
    [195135] = {
      "Bracken Warscourge", -- [1]
      "Brackenhide Hollow", -- [2]
    },
    [92610] = {
      "Understone Drummer", -- [1]
      "Neltharion's Lair", -- [2]
    },
    [208441] = {
      "Water Elemental", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [101438] = {
      "Vileshard Chunk", -- [1]
      "Neltharion's Lair", -- [2]
    },
    [170572] = {
      "Atal'ai Hoodoo Hexxer", -- [1]
      "De Other Side", -- [2]
    },
    [184134] = {
      "Scavenging Leaper", -- [1]
      "Uldaman: Legacy of Tyr", -- [2]
      "enUS", -- [3]
    },
    [75979] = {
      "Exhumed Spirit", -- [1]
      "Shadowmoon Burial Grounds", -- [2]
    },
    [156244] = {
      "Winged Automaton", -- [1]
      "Torghast, Tower of the Damned", -- [2]
    },
    [205628] = {
      "Twisted Elementium", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [201790] = {
      "Loszkeleth", -- [1]
      "Dawn of the Infinite", -- [2]
      "enUS", -- [3]
    },
    [171341] = {
      "Bladebeak Hatchling", -- [1]
      "De Other Side", -- [2]
    },
    [155221] = {
      "Faeleaf Tender", -- [1]
      "Torghast, Tower of the Damned", -- [2]
    },
    [135007] = {
      "Orb Guardian", -- [1]
      "Temple of Sethraliss", -- [2]
    },
    [135263] = {
      "Ashvane Spotter", -- [1]
      "Siege of Boralus", -- [2]
    },
    [91332] = {
      "Stoneclaw Hunter", -- [1]
      "Neltharion's Lair", -- [2]
      "enUS", -- [3]
    },
    [156245] = {
      "Grand Automaton", -- [1]
      "Torghast, Tower of the Damned", -- [2]
    },
    [128434] = {
      "Feasting Skyscreamer", -- [1]
      "Atal'Dazar", -- [2]
    },
    [197697] = {
      "Flamegullet", -- [1]
      "Ruby Life Pools", -- [2]
    },
    [199233] = {
      "Flamescale Captain", -- [1]
      "Vault of the Incarnates", -- [2]
    },
    [92612] = {
      "Mightstone Breaker", -- [1]
      "Neltharion's Lair", -- [2]
    },
    [197698] = {
      "Thunderhead", -- [1]
      "Ruby Life Pools", -- [2]
    },
    [171343] = {
      "Bladebeak Matriarch", -- [1]
      "De Other Side", -- [2]
    },
    [186696] = {
      "Quaking Totem", -- [1]
      "Uldaman: Legacy of Tyr", -- [2]
    },
    [17252] = {
      "VeeZekeel", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [128435] = {
      "Toxic Saurid", -- [1]
      "Atal'Dazar", -- [2]
    },
    [98370] = {
      "Ghostly Councilor", -- [1]
      "Black Rook Hold", -- [2]
    },
    [162133] = {
      "General Kaal", -- [1]
      "Sanguine Depths", -- [2]
    },
    [176974] = {
      "Soul Reaver", -- [1]
      "Sanctum of Domination", -- [2]
    },
    [163157] = {
      "Amarth", -- [1]
      "The Necrotic Wake", -- [2]
    },
    [97219] = {
      "Solsten", -- [1]
      "Halls of Valor", -- [2]
    },
    [131685] = {
      "Runic Disciple", -- [1]
      "Waycrest Manor", -- [2]
    },
    [138338] = {
      "Reanimated Guardian", -- [1]
      "The Underrot", -- [2]
    },
    [157017] = {
      "Lithic Watcher", -- [1]
      "Torghast, Tower of the Damned", -- [2]
    },
    [184140] = {
      "Xy Acolyte", -- [1]
      "Sepulcher of the First Ones", -- [2]
    },
    [184908] = {
      "Vy Interceptor", -- [1]
      "The Necrotic Wake", -- [2]
    },
    [195399] = {
      "Curious Swoglet", -- [1]
      "Halls of Infusion", -- [2]
    },
    [199749] = {
      "Timestream Anomaly", -- [1]
      "Dawn of the Infinite", -- [2]
    },
    [208193] = {
      "Paladin of the Silver Hand", -- [1]
      "Dawn of the Infinite", -- [2]
    },
    [136549] = {
      "Ashvane Cannoneer", -- [1]
      "Siege of Boralus", -- [2]
    },
    [184910] = {
      "Wo Drifter", -- [1]
      "The Necrotic Wake", -- [2]
    },
    [115388] = {
      "King", -- [1]
      "Return to Karazhan", -- [2]
    },
    [164185] = {
      "Echelon", -- [1]
      "Halls of Atonement", -- [2]
    },
    [137830] = {
      "Pallid Gorger", -- [1]
      "Waycrest Manor", -- [2]
    },
    [130485] = {
      "Mechanized Peacekeeper", -- [1]
      "The MOTHERLODE!!", -- [2]
    },
    [136295] = {
      "Sunken Denizen", -- [1]
      "Shrine of the Storm", -- [2]
    },
    [186191] = {
      "Decay Speaker", -- [1]
      "Brackenhide Hollow", -- [2]
    },
    [201288] = {
      "Sundered Champion", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [205638] = {
      "Sundered Flame Banner", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [185680] = {
      "Vy Relic", -- [1]
      "The Necrotic Wake", -- [2]
    },
    [192333] = {
      "Alpha Eagle", -- [1]
      "Algeth'ar Academy", -- [2]
    },
    [202824] = {
      "Erratic Remnant", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [133482] = {
      "Crawler Mine", -- [1]
      "The MOTHERLODE!!", -- [2]
    },
    [208198] = {
      "Cronîx", -- [1]
      "Scarlet Monastery", -- [2]
      "enUS", -- [3]
    },
    [131436] = {
      "Chosen Blood Matron", -- [1]
      "The Underrot", -- [2]
    },
    [205384] = {
      "Infinite Chronoweaver", -- [1]
      "Dawn of the Infinite", -- [2]
      "enUS", -- [3]
    },
    [191311] = {
      "Infinite Whelp", -- [1]
      "Uldaman: Legacy of Tyr", -- [2]
      "enUS", -- [3]
    },
    [134251] = {
      "Seneschal M'bara", -- [1]
      "Kings' Rest", -- [2]
    },
    [194894] = {
      "Primalist Stormspeaker", -- [1]
      "The Nokhud Offensive", -- [2]
    },
    [189265] = {
      "Qalashi Bonetender", -- [1]
      "Neltharus", -- [2]
    },
    [185683] = {
      "Wo Relic", -- [1]
      "The Necrotic Wake", -- [2]
    },
    [194895] = {
      "Unstable Squall", -- [1]
      "The Nokhud Offensive", -- [2]
    },
    [189266] = {
      "Qalashi Trainee", -- [1]
      "Neltharus", -- [2]
    },
    [190034] = {
      "Blazebound Destroyer", -- [1]
      "Ruby Life Pools", -- [2]
    },
    [178008] = {
      "Decrepit Orb", -- [1]
      "Sanctum of Domination", -- [2]
    },
    [194896] = {
      "Primal Stormshield", -- [1]
      "The Nokhud Offensive", -- [2]
    },
    [130488] = {
      "Mech Jockey", -- [1]
      "The MOTHERLODE!!", -- [2]
    },
    [185685] = {
      "Urh Relic", -- [1]
      "The Necrotic Wake", -- [2]
    },
    [165471] = {
      "Nathrian Duelist", -- [1]
      "Castle Nathria", -- [2]
    },
    [114624] = {
      "Arcane Warden", -- [1]
      "Return to Karazhan", -- [2]
    },
    [194897] = {
      "Stormsurge Totem", -- [1]
      "The Nokhud Offensive", -- [2]
    },
    [205644] = {
      "Oozing Sludge", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [194898] = {
      "Primalist Arcblade", -- [1]
      "The Nokhud Offensive", -- [2]
    },
    [52019] = {
      "Skyfall Star", -- [1]
      "The Vortex Pinnacle", -- [2]
    },
    [83025] = {
      "Grom'kar Battlemaster", -- [1]
      "Iron Docks", -- [2]
    },
    [207438] = {
      "Headless Horseman", -- [1]
      "Scarlet Monastery", -- [2]
      "enUS", -- [3]
    },
    [164707] = {
      "Congealed Slime", -- [1]
      "Plaguefall", -- [2]
    },
    [134514] = {
      "Abyssal Cultist", -- [1]
      "Shrine of the Storm", -- [2]
    },
    [114626] = {
      "Forlorn Spirit", -- [1]
      "Return to Karazhan", -- [2]
    },
    [174175] = {
      "Loyal Stoneborn", -- [1]
      "Halls of Atonement", -- [2]
    },
    [96587] = {
      "Felsworn Infester", -- [1]
      "Vault of the Wardens", -- [2]
    },
    [203857] = {
      "Horde Warlock", -- [1]
      "Dawn of the Infinite", -- [2]
    },
    [83026] = {
      "Siegemaster Olugar", -- [1]
      "Iron Docks", -- [2]
    },
    [170850] = {
      "Raging Bloodhorn", -- [1]
      "Theater of Pain", -- [2]
    },
    [114627] = {
      "Shrieking Terror", -- [1]
      "Return to Karazhan", -- [2]
    },
    [161895] = {
      "Thing From Beyond", -- [1]
      "Horrific Vision of Orgrimmar", -- [2]
    },
    [115395] = {
      "Queen", -- [1]
      "Return to Karazhan", -- [2]
    },
    [81236] = {
      "Grimrail Technician", -- [1]
      "Grimrail Depot", -- [2]
    },
    [205651] = {
      "Bubbling Slime", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [189531] = {
      "Decayed Elder", -- [1]
      "Brackenhide Hollow", -- [2]
    },
    [195928] = {
      "Soulharvester Duuren", -- [1]
      "The Nokhud Offensive", -- [2]
    },
    [165479] = {
      "Court Enforcer", -- [1]
      "Castle Nathria", -- [2]
    },
    [114628] = {
      "Skeletal Waiter", -- [1]
      "Return to Karazhan", -- [2]
    },
    [195929] = {
      "Soulharvester Tumen", -- [1]
      "The Nokhud Offensive", -- [2]
    },
    [195930] = {
      "Soulharvester Mandakh", -- [1]
      "The Nokhud Offensive", -- [2]
    },
    [114629] = {
      "Spectral Retainer", -- [1]
      "Return to Karazhan", -- [2]
    },
    [129598] = {
      "Freehold Pack Mule", -- [1]
      "Freehold", -- [2]
      "enUS", -- [3]
    },
    [186208] = {
      "Rotbow Stalker", -- [1]
      "Brackenhide Hollow", -- [2]
    },
    [180323] = {
      "Fatespawn Monstrosity", -- [1]
      "Sanctum of Domination", -- [2]
    },
    [193373] = {
      "Nokhud Thunderfist", -- [1]
      "The Nokhud Offensive", -- [2]
    },
    [116549] = {
      "Backup Singer", -- [1]
      "Return to Karazhan", -- [2]
    },
    [205656] = {
      "Sundered Chemist", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [129599] = {
      "Cutwater Knife Juggler", -- [1]
      "Freehold", -- [2]
      "enUS", -- [3]
    },
    [87252] = {
      "Unruly Ogron", -- [1]
      "Iron Docks", -- [2]
    },
    [164461] = {
      "Sathel the Accursed", -- [1]
      "Theater of Pain", -- [2]
    },
    [134012] = {
      "Taskmaster Askari", -- [1]
      "The MOTHERLODE!!", -- [2]
    },
    [181861] = {
      "Magmatusk", -- [1]
      "Neltharus", -- [2]
    },
    [180070] = {
      "Mawsworn Scryer", -- [1]
      "Sanctum of Domination", -- [2]
    },
    [129600] = {
      "Bilge Rat Brinescale", -- [1]
      "Freehold", -- [2]
    },
    [167533] = {
      "Advent Nevermore", -- [1]
      "Theater of Pain", -- [2]
    },
    [101326] = {
      "Honored Ancestor", -- [1]
      "Halls of Valor", -- [2]
    },
    [157810] = {
      "Mawsworn Endbringer", -- [1]
      "Torghast, Tower of the Damned", -- [2]
    },
    [164463] = {
      "Paceran the Virulent", -- [1]
      "Theater of Pain", -- [2]
    },
    [114632] = {
      "Spectral Attendant", -- [1]
      "Return to Karazhan", -- [2]
    },
    [98384] = {
      "Razormouth", -- [1]
      "Neltharion's Lair", -- [2]
      "enUS", -- [3]
    },
    [100943] = {
      "Earthen Wall Totem", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [197985] = {
      "Flame Channeler", -- [1]
      "Ruby Life Pools", -- [2]
    },
    [104270] = {
      "Guardian Construct", -- [1]
      "Court of Stars", -- [2]
    },
    [114633] = {
      "Spectral Valet", -- [1]
      "Return to Karazhan", -- [2]
    },
    [129602] = {
      "Irontide Enforcer", -- [1]
      "Freehold", -- [2]
    },
    [111563] = {
      "Duskwatch Guard", -- [1]
      "Court of Stars", -- [2]
    },
    [205151] = {
      "Tyr's Vanguard", -- [1]
      "Dawn of the Infinite", -- [2]
    },
    [197219] = {
      "Vile Lasher", -- [1]
      "Algeth'ar Academy", -- [2]
    },
    [187240] = {
      "Drakonid Breaker", -- [1]
      "The Azure Vault", -- [2]
    },
    [154744] = {
      "Toxic Monstrosity", -- [1]
      "Operation: Mechagon", -- [2]
    },
    [171376] = {
      "Head Custodian Javlin", -- [1]
      "Sanguine Depths", -- [2]
    },
    [114634] = {
      "Undying Servant", -- [1]
      "Return to Karazhan", -- [2]
    },
    [205152] = {
      "Lerai, Timesworn Maiden", -- [1]
      "Dawn of the Infinite", -- [2]
      "enUS", -- [3]
    },
    [205408] = {
      "Infinite Timeslicer", -- [1]
      "Dawn of the Infinite", -- [2]
      "enUS", -- [3]
    },
    [59764] = {
      "Healing Tide Totem", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [179821] = {
      "Commander Zo'far", -- [1]
      "Tazavesh, the Veiled Market", -- [2]
    },
    [196198] = {
      "Algeth'ar Security", -- [1]
      "Algeth'ar Academy", -- [2]
    },
    [198757] = {
      "Void Lasher", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [115019] = {
      "Coldmist Widow", -- [1]
      "Return to Karazhan", -- [2]
    },
    [100818] = {
      "Bellowing Idol", -- [1]
      "Neltharion's Lair", -- [2]
      "enUS", -- [3]
    },
    [207969] = {
      "Horde Raider", -- [1]
      "Dawn of the Infinite", -- [2]
    },
    [188011] = {
      "Primal Terrasentry", -- [1]
      "Ruby Life Pools", -- [2]
    },
    [186220] = {
      "Brackenhide Shaper", -- [1]
      "Brackenhide Hollow", -- [2]
    },
    [180335] = {
      "Cartel Smuggler", -- [1]
      "Tazavesh, the Veiled Market", -- [2]
    },
    [150142] = {
      "Scrapbone Trashtosser", -- [1]
      "Operation: Mechagon", -- [2]
    },
    [104273] = {
      "Jazshariu", -- [1]
      "Court of Stars", -- [2]
    },
    [114636] = {
      "Phantom Guardsman", -- [1]
      "Return to Karazhan", -- [2]
    },
    [196712] = {
      "Nullification Device", -- [1]
      "Halls of Infusion", -- [2]
    },
    [168310] = {
      "Plagueroc", -- [1]
      "Plaguefall", -- [2]
    },
    [150143] = {
      "Scrapbone Grinder", -- [1]
      "Operation: Mechagon", -- [2]
    },
    [101075] = {
      "Wormspeaker Devout", -- [1]
      "Neltharion's Lair", -- [2]
    },
    [134024] = {
      "Devouring Maggot", -- [1]
      "Waycrest Manor", -- [2]
    },
    [104274] = {
      "Baalgar the Watchful", -- [1]
      "Court of Stars", -- [2]
    },
    [126919] = {
      "Irontide Stormcaller", -- [1]
      "Freehold", -- [2]
    },
    [174197] = {
      "Battlefield Ritualist", -- [1]
      "Theater of Pain", -- [2]
    },
    [205158] = {
      "Spurlok, Timesworn Sentinel", -- [1]
      "Dawn of the Infinite", -- [2]
      "enUS", -- [3]
    },
    [201320] = {
      "Rashok", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [187503] = {
      "Ambitious Underboss", -- [1]
      "10.0 Dragon Isles", -- [2]
    },
    [196203] = {
      "Algeth'ar Nurse", -- [1]
      "Algeth'ar Academy", -- [2]
    },
    [135049] = {
      "Dreadwing Raven", -- [1]
      "Waycrest Manor", -- [2]
    },
    [113998] = {
      "Mightstone Breaker", -- [1]
      "Neltharion's Lair", -- [2]
    },
    [205671] = {
      "Shadow Additive", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [132491] = {
      "Kul Tiran Marksman", -- [1]
      "Siege of Boralus", -- [2]
    },
    [104275] = {
      "Imacu'tya", -- [1]
      "Court of Stars", -- [2]
    },
    [128967] = {
      "Ashvane Sniper", -- [1]
      "Siege of Boralus", -- [2]
    },
    [168058] = {
      "Infused Quill-feather", -- [1]
      "Sanguine Depths", -- [2]
    },
    [205672] = {
      "Flame Additive", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [115406] = {
      "Knight", -- [1]
      "Return to Karazhan", -- [2]
    },
    [186226] = {
      "Fetid Rotsinger", -- [1]
      "Brackenhide Hollow", -- [2]
    },
    [62005] = {
      "Beast", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [186738] = {
      "Umbrelskul", -- [1]
      "The Azure Vault", -- [2]
    },
    [205673] = {
      "Sundered Devourer", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [134284] = {
      "Fallen Deathspeaker", -- [1]
      "The Underrot", -- [2]
    },
    [175992] = {
      "Dutiful Attendant", -- [1]
      "Castle Nathria", -- [2]
    },
    [186739] = {
      "Azureblade", -- [1]
      "The Azure Vault", -- [2]
    },
    [168572] = {
      "Fungi Stormer", -- [1]
      "Plaguefall", -- [2]
    },
    [136076] = {
      "Agitated Nimbus", -- [1]
      "Temple of Sethraliss", -- [2]
    },
    [115407] = {
      "Rook", -- [1]
      "Return to Karazhan", -- [2]
    },
    [195696] = {
      "Primalist Thunderbeast", -- [1]
      "The Nokhud Offensive", -- [2]
    },
    [157571] = {
      "Mawsworn Flametender", -- [1]
      "Torghast, Tower of the Damned", -- [2]
    },
    [186741] = {
      "Arcane Elemental", -- [1]
      "The Azure Vault", -- [2]
    },
    [162689] = {
      "Surgeon Stitchflesh", -- [1]
      "The Necrotic Wake", -- [2]
    },
    [183671] = {
      "Monstrous Soul", -- [1]
      "Sepulcher of the First Ones", -- [2]
    },
    [157572] = {
      "Mawsworn Firecaller", -- [1]
      "Torghast, Tower of the Damned", -- [2]
    },
    [164737] = {
      "Brood Ambusher", -- [1]
      "Plaguefall", -- [2]
    },
    [95834] = {
      "Valarjar Mystic", -- [1]
      "Halls of Valor", -- [2]
    },
    [104278] = {
      "Felbound Enforcer", -- [1]
      "Court of Stars", -- [2]
    },
    [137103] = {
      "Blood Visage", -- [1]
      "The Underrot", -- [2]
    },
    [98521] = {
      "Lord Etheldrin Ravencrest", -- [1]
      "Black Rook Hold", -- [2]
    },
    [162691] = {
      "Blightbone", -- [1]
      "The Necrotic Wake", -- [2]
    },
    [163459] = {
      "Forsworn Mender", -- [1]
      "Spires of Ascension", -- [2]
    },
    [165762] = {
      "Soul Infuser", -- [1]
      "Castle Nathria", -- [2]
    },
    [162692] = {
      "Amarth", -- [1]
      "The Necrotic Wake", -- [2]
    },
    [187768] = {
      "Dathea Stormlash", -- [1]
      "Vault of the Incarnates", -- [2]
    },
    [102232] = {
      "Rockbound Trapper", -- [1]
      "Neltharion's Lair", -- [2]
    },
    [165763] = {
      "Vile Occultist", -- [1]
      "Castle Nathria", -- [2]
    },
    [180348] = {
      "Cartel Muscle", -- [1]
      "Tazavesh, the Veiled Market", -- [2]
    },
    [166275] = {
      "Mistveil Shaper", -- [1]
      "Mists of Tirna Scithe", -- [2]
    },
    [168578] = {
      "Fungalmancer", -- [1]
      "Plaguefall", -- [2]
    },
    [189816] = {
      "Dathea Stormlash", -- [1]
      "Vault of the Incarnates", -- [2]
    },
    [165764] = {
      "Rockbound Vanquisher", -- [1]
      "Castle Nathria", -- [2]
    },
    [166276] = {
      "Mistveil Guardian", -- [1]
      "Mists of Tirna Scithe", -- [2]
    },
    [170882] = {
      "Bone Magus", -- [1]
      "Theater of Pain", -- [2]
    },
    [188026] = {
      "Frost Tomb", -- [1]
      "Vault of the Incarnates", -- [2]
    },
    [76518] = {
      "Ritual of Bones", -- [1]
      "Shadowmoon Burial Grounds", -- [2]
    },
    [174210] = {
      "Blighted Sludge-Spewer", -- [1]
      "Theater of Pain", -- [2]
    },
    [169861] = {
      "Ickor Bileflesh", -- [1]
      "Plaguefall", -- [2]
    },
    [180864] = {
      "High Torturer", -- [1]
      "Sanctum of Domination", -- [2]
    },
    [183423] = {
      "Reformed Bachelor", -- [1]
      "Return to Karazhan", -- [2]
    },
    [179841] = {
      "Veteran Sparkcaster", -- [1]
      "Tazavesh, the Veiled Market", -- [2]
    },
    [150160] = {
      "Scrapbone Bully", -- [1]
      "Operation: Mechagon", -- [2]
    },
    [183424] = {
      "Virtuous Gentleman", -- [1]
      "Return to Karazhan", -- [2]
    },
    [179842] = {
      "Commerce Enforcer", -- [1]
      "Tazavesh, the Veiled Market", -- [2]
    },
    [204918] = {
      "Iridikron's Creation", -- [1]
      "Dawn of the Infinite", -- [2]
    },
    [183425] = {
      "Wholesome Host", -- [1]
      "Return to Karazhan", -- [2]
    },
    [171656] = {
      "Venomous Sniper Captain", -- [1]
      "Plaguefall", -- [2]
    },
    [126928] = {
      "Irontide Corsair", -- [1]
      "Freehold", -- [2]
    },
    [88163] = {
      "Grom'kar Cinderseer", -- [1]
      "Grimrail Depot", -- [2]
    },
    [199547] = {
      "Frostforged Zealot", -- [1]
      "Vault of the Incarnates", -- [2]
    },
    [186242] = {
      "Skulking Gutstabber", -- [1]
      "Brackenhide Hollow", -- [2]
    },
    [179334] = {
      "Portalmancer Zo'dahh", -- [1]
      "Tazavesh, the Veiled Market", -- [2]
    },
    [79720] = {
      "Grom'kar Boomer", -- [1]
      "Grimrail Depot", -- [2]
    },
    [199037] = {
      "Primalist Shocktrooper", -- [1]
      "Halls of Infusion", -- [2]
    },
    [150165] = {
      "Slime Elemental", -- [1]
      "Operation: Mechagon", -- [2]
    },
    [199549] = {
      "Flamesworn Herald", -- [1]
      "Vault of the Incarnates", -- [2]
    },
    [187523] = {
      "Duskpaw Stalker", -- [1]
      "10.0 Dragon Isles", -- [2]
    },
    [202108] = {
      "Djaradin Dragonhunter", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [179847] = {
      "Shadowsteel Horror", -- [1]
      "Sanctum of Domination", -- [2]
    },
    [176521] = {
      "Stygian Abductor", -- [1]
      "Sanctum of Domination", -- [2]
    },
    [205691] = {
      "Iridikron's Creation", -- [1]
      "Dawn of the Infinite", -- [2]
      "enUS", -- [3]
    },
    [202109] = {
      "Djaradin Commander", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [130896] = {
      "Blackout Barrel", -- [1]
      "Freehold", -- [2]
      "enUS", -- [3]
    },
    [180104] = {
      "Tangling Bloom", -- [1]
      "The Shadowlands", -- [2]
    },
    [92387] = {
      "Drums of War", -- [1]
      "Neltharion's Lair", -- [2]
      "enUS", -- [3]
    },
    [190340] = {
      "Refti Defender", -- [1]
      "Halls of Infusion", -- [2]
    },
    [176523] = {
      "Painsmith Raznal", -- [1]
      "Sanctum of Domination", -- [2]
    },
    [150168] = {
      "Toxic Monstrosity", -- [1]
      "Operation: Mechagon", -- [2]
    },
    [95842] = {
      "Valarjar Thundercaller", -- [1]
      "Halls of Valor", -- [2]
    },
    [77803] = {
      "Railmaster Rocketspark", -- [1]
      "Grimrail Depot", -- [2]
    },
    [139422] = {
      "Scaled Krolusk Tamer", -- [1]
      "Temple of Sethraliss", -- [2]
    },
    [150169] = {
      "Toxic Lurker", -- [1]
      "Operation: Mechagon", -- [2]
    },
    [165010] = {
      "Congealed Slime", -- [1]
      "Plaguefall", -- [2]
    },
    [190342] = {
      "Containment Apparatus", -- [1]
      "Halls of Infusion", -- [2]
    },
    [135329] = {
      "Matron Bryndle", -- [1]
      "Waycrest Manor", -- [2]
    },
    [136353] = {
      "Colossal Tentacle", -- [1]
      "Shrine of the Storm", -- [2]
    },
    [179852] = {
      "Soulless Vengeance", -- [1]
      "The Shadowlands", -- [2]
    },
    [131492] = {
      "Devout Blood Priest", -- [1]
      "The Underrot", -- [2]
    },
    [168594] = {
      "Chamber Sentinel", -- [1]
      "Sanguine Depths", -- [2]
    },
    [115418] = {
      "Spider", -- [1]
      "Return to Karazhan", -- [2]
    },
    [139425] = {
      "Crazed Incubator", -- [1]
      "Temple of Sethraliss", -- [2]
    },
    [199812] = {
      "Zaqali Wallclimber", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [204162] = {
      "Sanatio", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [190345] = {
      "Primalist Geomancer", -- [1]
      "Halls of Infusion", -- [2]
    },
    [200836] = {
      "Obsidian Guard", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
    },
    [73967] = {
      "Niuzao", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [115419] = {
      "Ancient Tome", -- [1]
      "Return to Karazhan", -- [2]
    },
    [177808] = {
      "Armored Overseer", -- [1]
      "Tazavesh, the Veiled Market", -- [2]
    },
    [190348] = {
      "Primalist Ravager", -- [1]
      "Halls of Infusion", -- [2]
    },
    [154014] = {
      "Imprisoned Cabalist", -- [1]
      "Torghast, Tower of the Damned", -- [2]
    },
    [118491] = {
      "Corrupted Risen Mage", -- [1]
      "Black Rook Hold - Artifact Challenge", -- [2]
    },
    [202375] = {
      "Zskarn", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [188302] = {
      "Reconfiguration Emitter", -- [1]
      "Castle Nathria", -- [2]
    },
    [200840] = {
      "Flamebound Huntsman", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
    },
    [164506] = {
      "Ancient Captain", -- [1]
      "Theater of Pain", -- [2]
    },
    [101476] = {
      "Molten Charskin", -- [1]
      "Neltharion's Lair", -- [2]
    },
    [144293] = {
      "Waste Processing Unit", -- [1]
      "Operation: Mechagon", -- [2]
    },
    [114526] = {
      "Ghostly Understudy", -- [1]
      "Return to Karazhan", -- [2]
    },
    [98406] = {
      "Embershard Scorpion", -- [1]
      "Neltharion's Lair", -- [2]
    },
    [166299] = {
      "Mistveil Tender", -- [1]
      "Mists of Tirna Scithe", -- [2]
    },
    [129367] = {
      "Bilge Rat Tempest", -- [1]
      "Siege of Boralus", -- [2]
    },
    [144294] = {
      "Mechagon Tinkerer", -- [1]
      "Operation: Mechagon", -- [2]
    },
    [144295] = {
      "Mechagon Mechanic", -- [1]
      "Operation: Mechagon", -- [2]
    },
    [75506] = {
      "Shadowmoon Loyalist", -- [1]
      "Shadowmoon Burial Grounds", -- [2]
    },
    [114783] = {
      "Reformed Maiden", -- [1]
      "Return to Karazhan", -- [2]
    },
    [166301] = {
      "Mistveil Stalker", -- [1]
      "Mists of Tirna Scithe", -- [2]
    },
    [164510] = {
      "Shambling Arbalest", -- [1]
      "Theater of Pain", -- [2]
    },
    [144296] = {
      "Spider Tank", -- [1]
      "Operation: Mechagon", -- [2]
    },
    [208521] = {
      "Pumpkin Soldier", -- [1]
      "Scarlet Monastery", -- [2]
      "enUS", -- [3]
    },
    [166302] = {
      "Corpse Harvester", -- [1]
      "The Necrotic Wake", -- [2]
    },
    [177817] = {
      "Support Officer", -- [1]
      "Tazavesh, the Veiled Market", -- [2]
    },
    [98280] = {
      "Risen Arcanist", -- [1]
      "Black Rook Hold", -- [2]
    },
    [155812] = {
      "Mawsworn Ritualist", -- [1]
      "Torghast, Tower of the Damned", -- [2]
    },
    [41096] = {
      "Naz'jar Oracle", -- [1]
      "Throne of the Tides", -- [2]
    },
    [129369] = {
      "Irontide Raider", -- [1]
      "Siege of Boralus", -- [2]
    },
    [144298] = {
      "Defense Bot Mk III", -- [1]
      "Operation: Mechagon", -- [2]
    },
    [139949] = {
      "Plague Doctor", -- [1]
      "Temple of Sethraliss", -- [2]
    },
    [130521] = {
      "Freehold Deckhand", -- [1]
      "Freehold", -- [2]
      "enUS", -- [3]
    },
    [101991] = {
      "Nightmare Dweller", -- [1]
      "Darkheart Thicket", -- [2]
    },
    [169426] = {
      "Infernal", -- [1]
      "Brackenhide Hollow", -- [2]
    },
    [151649] = {
      "Defense Bot Mk I", -- [1]
      "Operation: Mechagon", -- [2]
    },
    [122973] = {
      "Dazar'ai Confessor", -- [1]
      "Atal'Dazar", -- [2]
    },
    [31216] = {
      "Morpheusmage", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [129370] = {
      "Irontide Waveshaper", -- [1]
      "Siege of Boralus", -- [2]
    },
    [164562] = {
      "Depraved Houndmaster", -- [1]
      "Halls of Atonement", -- [2]
    },
    [122971] = {
      "Dazar'ai Juggernaut", -- [1]
      "Atal'Dazar", -- [2]
    },
    [175517] = {
      "Symbiotic Faerie", -- [1]
      "9.0 Bastion Arena - Path of Ascension", -- [2]
    },
    [180091] = {
      "Ancient Core Hound", -- [1]
      "Tazavesh, the Veiled Market", -- [2]
    },
    [151127] = {
      "Lord of Torment", -- [1]
      "Torghast, Tower of the Damned", -- [2]
    },
    [131812] = {
      "Heartsbane Soulcharmer", -- [1]
      "Waycrest Manor", -- [2]
    },
    [134629] = {
      "Scaled Krolusk Rider", -- [1]
      "Temple of Sethraliss", -- [2]
    },
    [214209] = {
      "Naz'jar Tempest Witch", -- [1]
      "Throne of the Tides", -- [2]
    },
    [130522] = {
      "Freehold Shipmate", -- [1]
      "Freehold", -- [2]
      "enUS", -- [3]
    },
    [206351] = {
      "Alliance Conjuror", -- [1]
      "Dawn of the Infinite", -- [2]
    },
    [212673] = {
      "Naz'jar Ravager", -- [1]
      "Throne of the Tides", -- [2]
    },
    [104295] = {
      "Blazing Imp", -- [1]
      "Court of Stars", -- [2]
    },
    [190359] = {
      "Skulking Zealot", -- [1]
      "Halls of Infusion", -- [2]
    },
    [165189] = {
      "Maxîî", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [47238] = {
      "Whipping Wind", -- [1]
      "The Vortex Pinnacle", -- [2]
    },
    [187033] = {
      "Stinkbreath", -- [1]
      "Brackenhide Hollow", -- [2]
    },
    [98275] = {
      "Risen Archer", -- [1]
      "Black Rook Hold", -- [2]
    },
    [205968] = {
      "Fragment of Shadow", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [183707] = {
      "Xy Spellslinger", -- [1]
      "Sepulcher of the First Ones", -- [2]
    },
    [102788] = {
      "Felspite Dominator", -- [1]
      "Black Rook Hold", -- [2]
    },
    [130011] = {
      "Irontide Buccaneer", -- [1]
      "Freehold", -- [2]
    },
    [98792] = {
      "Wyrmtongue Scavenger", -- [1]
      "Black Rook Hold", -- [2]
    },
    [213806] = {
      "Splotch", -- [1]
      "Throne of the Tides", -- [2]
    },
    [164557] = {
      "Shard of Halkias", -- [1]
      "Halls of Atonement", -- [2]
    },
    [135002] = {
      "Demonic Tyrant", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [156226] = {
      "Coldheart Binder", -- [1]
      "Torghast, Tower of the Damned", -- [2]
    },
    [189472] = {
      "Qalashi Lavabearer", -- [1]
      "Neltharus", -- [2]
    },
    [173729] = {
      "Manifestation of Pride", -- [1]
      "Halls of Atonement", -- [2]
    },
    [189471] = {
      "Qalashi Blacksmith", -- [1]
      "Neltharus", -- [2]
    },
    [138064] = {
      "Posh Vacationer", -- [1]
      "The MOTHERLODE!!", -- [2]
    },
    [120651] = {
      "Explosives", -- [1]
      "Court of Stars", -- [2]
    },
    [135167] = {
      "Spectral Berserker", -- [1]
      "Kings' Rest", -- [2]
    },
    [163126] = {
      "Brittlebone Mage", -- [1]
      "The Necrotic Wake", -- [2]
    },
    [114319] = {
      "Lady Keira Berrybuck", -- [1]
      "Return to Karazhan", -- [2]
    },
    [193944] = {
      "Qalashi Lavamancer", -- [1]
      "Neltharus", -- [2]
    },
    [196117] = {
      "Crystal Construct", -- [1]
      "The Azure Vault", -- [2]
    },
    [190362] = {
      "Dazzling Dragonfly", -- [1]
      "Halls of Infusion", -- [2]
    },
    [151657] = {
      "Bomb Tonk", -- [1]
      "Operation: Mechagon", -- [2]
    },
    [168357] = {
      "Zolramus Sorcerer", -- [1]
      "The Necrotic Wake", -- [2]
    },
    [135204] = {
      "Spectral Hex Priest", -- [1]
      "Kings' Rest", -- [2]
    },
    [196115] = {
      "Arcane Tender", -- [1]
      "The Azure Vault", -- [2]
    },
    [205971] = {
      "Fragment of Fire", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [131587] = {
      "Bewitched Captain", -- [1]
      "Waycrest Manor", -- [2]
    },
    [168418] = {
      "Forsworn Inquisitor", -- [1]
      "Spires of Ascension", -- [2]
    },
    [169893] = {
      "Nefarious Darkspeaker", -- [1]
      "Theater of Pain", -- [2]
    },
    [189464] = {
      "Qalashi Irontorch", -- [1]
      "Neltharus", -- [2]
    },
    [126918] = {
      "Irontide Crackshot", -- [1]
      "Freehold", -- [2]
    },
    [96934] = {
      "Valarjar Trapper", -- [1]
      "Halls of Valor", -- [2]
    },
    [189340] = {
      "Chargath, Bane of Scales", -- [1]
      "Neltharus", -- [2]
    },
    [76407] = {
      "Ner'zhul", -- [1]
      "Shadowmoon Burial Grounds", -- [2]
    },
    [189227] = {
      "Qalashi Hunter", -- [1]
      "Neltharus", -- [2]
    },
    [128551] = {
      "Irontide Mastiff", -- [1]
      "Freehold", -- [2]
      "enUS", -- [3]
    },
    [205629] = {
      "Crazed Experiment", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [136408] = {
      "Darkhound", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [45704] = {
      "Lurking Tempest", -- [1]
      "The Vortex Pinnacle", -- [2]
    },
    [98813] = {
      "Bloodscent Felhound", -- [1]
      "Black Rook Hold", -- [2]
    },
    [208438] = {
      "Infinite Saboteur", -- [1]
      "Dawn of the Infinite", -- [2]
      "enUS", -- [3]
    },
    [177816] = {
      "Interrogation Specialist", -- [1]
      "Tazavesh, the Veiled Market", -- [2]
    },
    [199748] = {
      "Timeline Marauder", -- [1]
      "Dawn of the Infinite", -- [2]
    },
    [130909] = {
      "Fetid Maggot", -- [1]
      "Zandalar", -- [2]
    },
    [179733] = {
      "Invigorating Fish Stick", -- [1]
      "Tazavesh, the Veiled Market", -- [2]
    },
    [163620] = {
      "Rotspew", -- [1]
      "The Necrotic Wake", -- [2]
    },
    [164266] = {
      "Domina Venomblade", -- [1]
      "Plaguefall", -- [2]
    },
    [165410] = {
      "High Adjudicator Aleez", -- [1]
      "Halls of Atonement", -- [2]
    },
    [136407] = {
      "Wrathguard", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [203927] = {
      "Failed Prototype", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [129758] = {
      "Irontide Grenadier", -- [1]
      "Freehold", -- [2]
    },
    [184023] = {
      "Vicious Basilisk", -- [1]
      "10.0 Dragon Isles", -- [2]
    },
    [133007] = {
      "Unbound Abomination", -- [1]
      "The Underrot", -- [2]
    },
    [192955] = {
      "Draconic Illusion", -- [1]
      "The Azure Vault", -- [2]
    },
    [165483] = {
      "Court Hierarch", -- [1]
      "Castle Nathria", -- [2]
    },
    [129227] = {
      "Azerokk", -- [1]
      "The MOTHERLODE!!", -- [2]
    },
    [45572] = {
      "Howling Gale", -- [1]
      "The Vortex Pinnacle", -- [2]
    },
    [187552] = {
      "Stormfang Shaman", -- [1]
      "10.0 Dragon Isles", -- [2]
    },
    [187224] = {
      "Vile Rothexer", -- [1]
      "Brackenhide Hollow", -- [2]
    },
    [136406] = {
      "Shivarra", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [155824] = {
      "Lumbering Creation", -- [1]
      "Torghast, Tower of the Damned", -- [2]
    },
    [114790] = {
      "Viz'aduum the Watcher", -- [1]
      "Return to Karazhan", -- [2]
    },
    [195877] = {
      "Risen Mystic", -- [1]
      "The Nokhud Offensive", -- [2]
    },
    [105636] = {
      "Understone Drudge", -- [1]
      "Neltharion's Lair", -- [2]
      "enUS", -- [3]
    },
    [194745] = {
      "Rotfang Hyena", -- [1]
      "Brackenhide Hollow", -- [2]
    },
    [134331] = {
      "King Rahu'ai", -- [1]
      "Kings' Rest", -- [2]
    },
    [206070] = {
      "Chronaxie", -- [1]
      "Dawn of the Infinite", -- [2]
      "enUS", -- [3]
    },
    [195927] = {
      "Soulharvester Galtmaa", -- [1]
      "The Nokhud Offensive", -- [2]
    },
    [190368] = {
      "Flamecaller Aymi", -- [1]
      "Halls of Infusion", -- [2]
    },
    [133436] = {
      "Venture Co. Skyscorcher", -- [1]
      "The MOTHERLODE!!", -- [2]
    },
    [176551] = {
      "Vault Purifier", -- [1]
      "Tazavesh, the Veiled Market", -- [2]
    },
    [177892] = {
      "Mawforged Goliath", -- [1]
      "Sanctum of Domination", -- [2]
    },
    [136249] = {
      "Guardian Elemental", -- [1]
      "Shrine of the Storm", -- [2]
    },
    [196116] = {
      "Crystal Fury", -- [1]
      "The Azure Vault", -- [2]
    },
    [151476] = {
      "Blastatron X-80", -- [1]
      "Operation: Mechagon", -- [2]
    },
    [104300] = {
      "Shadow Mistress", -- [1]
      "Court of Stars", -- [2]
    },
    [165805] = {
      "Shade of Kael'thas", -- [1]
      "Castle Nathria", -- [2]
    },
    [155908] = {
      "Deathspeaker", -- [1]
      "Torghast, Tower of the Damned", -- [2]
    },
    [186246] = {
      "Fleshripper Vulture", -- [1]
      "Brackenhide Hollow", -- [2]
    },
    [199325] = {
      "Nokhud Stormcaller", -- [1]
      "The Nokhud Offensive", -- [2]
    },
    [153292] = {
      "Training Dummy", -- [1]
      "Eastern Kingdoms", -- [2]
    },
    [167536] = {
      "Harugia the Bloodthirsty", -- [1]
      "Theater of Pain", -- [2]
    },
    [163503] = {
      "Etherdiver", -- [1]
      "Spires of Ascension", -- [2]
    },
    [188067] = {
      "Flashfrost Chillweaver", -- [1]
      "Ruby Life Pools", -- [2]
    },
    [190370] = {
      "Squallbringer Cyraz", -- [1]
      "Halls of Infusion", -- [2]
    },
    [168109] = {
      "Empowered Mawsworn Ritualist", -- [1]
      "Torghast, Tower of the Damned", -- [2]
    },
    [200918] = {
      "Rionthus", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [130400] = {
      "Irontide Crusher", -- [1]
      "Freehold", -- [2]
    },
    [197535] = {
      "High Channeler Ryvati", -- [1]
      "Ruby Life Pools", -- [2]
    },
    [97068] = {
      "Storm Drake", -- [1]
      "Halls of Valor", -- [2]
    },
    [198047] = {
      "Tempest Channeler", -- [1]
      "Ruby Life Pools", -- [2]
    },
    [114792] = {
      "Virtuous Lady", -- [1]
      "Return to Karazhan", -- [2]
    },
    [190371] = {
      "Primalist Earthshaker", -- [1]
      "Halls of Infusion", -- [2]
    },
    [75899] = {
      "Possessed Soul", -- [1]
      "Shadowmoon Burial Grounds", -- [2]
    },
    [115642] = {
      "Umbral Imp", -- [1]
      "Faronaar", -- [2]
    },
    [167876] = {
      "Inquisitor Sigar", -- [1]
      "Halls of Atonement", -- [2]
    },
    [165529] = {
      "Depraved Collector", -- [1]
      "Halls of Atonement", -- [2]
    },
    [100713] = {
      "Rockbait Fisher", -- [1]
      "Neltharion's Lair", -- [2]
      "enUS", -- [3]
    },
    [105704] = {
      "Arcane Manifestation", -- [1]
      "Court of Stars", -- [2]
    },
    [97197] = {
      "Valarjar Purifier", -- [1]
      "Halls of Valor", -- [2]
    },
    [170690] = {
      "Diseased Horror", -- [1]
      "Theater of Pain", -- [2]
    },
    [127315] = {
      "Reanimation Totem", -- [1]
      "Atal'Dazar", -- [2]
    },
    [118489] = {
      "Corrupted Risen Soldier", -- [1]
      "Black Rook Hold - Artifact Challenge", -- [2]
    },
    [150146] = {
      "Scrapbone Shaman", -- [1]
      "Operation: Mechagon", -- [2]
    },
    [188244] = {
      "Primal Juggernaut", -- [1]
      "Ruby Life Pools", -- [2]
    },
    [150712] = {
      "Trixie Tazer", -- [1]
      "Operation: Mechagon", -- [2]
    },
    [105705] = {
      "Bound Energy", -- [1]
      "Court of Stars", -- [2]
    },
    [190373] = {
      "Primalist Galesinger", -- [1]
      "Halls of Infusion", -- [2]
    },
    [194467] = {
      "Disease Slasher", -- [1]
      "Brackenhide Hollow", -- [2]
    },
    [155830] = {
      "Mawsworn Disciple", -- [1]
      "Torghast, Tower of the Damned", -- [2]
    },
    [59555] = {
      "Haunting Sha", -- [1]
      "Temple of the Jade Serpent", -- [2]
    },
    [191847] = {
      "Nokhud Plainstomper", -- [1]
      "The Nokhud Offensive", -- [2]
    },
    [206064] = {
      "Coalesced Moment", -- [1]
      "Dawn of the Infinite", -- [2]
      "enUS", -- [3]
    },
    [171384] = {
      "Research Scribe", -- [1]
      "Sanguine Depths", -- [2]
    },
    [168443] = {
      "Zolramus Necromancer", -- [1]
      "The Necrotic Wake", -- [2]
    },
    [90997] = {
      "Mightstone Breaker", -- [1]
      "Neltharion's Lair", -- [2]
    },
    [163524] = {
      "Kyrian Dark-Praetor", -- [1]
      "Spires of Ascension", -- [2]
    },
    [155831] = {
      "Mawsworn Soulbinder", -- [1]
      "Torghast, Tower of the Damned", -- [2]
    },
    [134338] = {
      "Tidesage Enforcer", -- [1]
      "Shrine of the Storm", -- [2]
    },
    [185529] = {
      "Bracken Warscourge", -- [1]
      "Brackenhide Hollow", -- [2]
    },
    [205727] = {
      "Time-Lost Rocketeer", -- [1]
      "Dawn of the Infinite", -- [2]
    },
    [171184] = {
      "Mythresh, Sky's Talons", -- [1]
      "De Other Side", -- [2]
    },
    [122969] = {
      "Zanchuli Witch-Doctor", -- [1]
      "Atal'Dazar", -- [2]
    },
    [194469] = {
      "Wither Slasher", -- [1]
      "Brackenhide Hollow", -- [2]
    },
    [169905] = {
      "Risen Warlord", -- [1]
      "De Other Side", -- [2]
    },
    [152009] = {
      "Malfunctioning Scrapbot", -- [1]
      "Operation: Mechagon", -- [2]
    },
    [192934] = {
      "Volatile Infuser", -- [1]
      "Vault of the Incarnates", -- [2]
    },
    [137521] = {
      "Irontide Powdershot", -- [1]
      "Siege of Boralus", -- [2]
    },
    [168882] = {
      "Fleeting Manifestation", -- [1]
      "Sanguine Depths", -- [2]
    },
    [203230] = {
      "Dragonfire Golem", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [198308] = {
      "Frostwrought Dominator", -- [1]
      "Vault of the Incarnates", -- [2]
    },
    [90998] = {
      "Blightshard Shaper", -- [1]
      "Neltharion's Lair", -- [2]
    },
    [76104] = {
      "Monstrous Corpse Spider", -- [1]
      "Shadowmoon Burial Grounds", -- [2]
    },
    [102253] = {
      "Understone Demolisher", -- [1]
      "Neltharion's Lair", -- [2]
    },
    [191739] = {
      "Scalebane Lieutenant", -- [1]
      "The Azure Vault", -- [2]
    },
    [168627] = {
      "Plaguebinder", -- [1]
      "Plaguefall", -- [2]
    },
    [163862] = {
      "Defender of Many Eyes", -- [1]
      "Plaguefall", -- [2]
    },
    [83578] = {
      "Ogron Laborer", -- [1]
      "Iron Docks", -- [2]
    },
    [98035] = {
      "Dreadstalker", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [168318] = {
      "Forsworn Goliath", -- [1]
      "Spires of Ascension", -- [2]
    },
    [190377] = {
      "Primalist Icecaller", -- [1]
      "Halls of Infusion", -- [2]
    },
    [192680] = {
      "Guardian Sentry", -- [1]
      "Algeth'ar Academy", -- [2]
    },
    [131383] = {
      "Sporecaller Zancha", -- [1]
      "The Underrot", -- [2]
      "enUS", -- [3]
    },
    [77483] = {
      "Grom'kar Gunner", -- [1]
      "Grimrail Depot", -- [2]
    },
    [178165] = {
      "Coastwalker Goliath", -- [1]
      "Tazavesh, the Veiled Market", -- [2]
    },
    [203939] = {
      "Animation Fluid", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [126969] = {
      "Trothak", -- [1]
      "Freehold", -- [2]
    },
    [196263] = {
      "Nokhud Neophyte", -- [1]
      "The Nokhud Offensive", -- [2]
    },
    [186284] = {
      "Gutchewer Bear", -- [1]
      "Brackenhide Hollow", -- [2]
    },
    [135365] = {
      "Matron Alma", -- [1]
      "Waycrest Manor", -- [2]
    },
    [136399] = {
      "Vicious Hellhound", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [54983] = {
      "Treant", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [162744] = {
      "Nekthara the Mangler", -- [1]
      "Theater of Pain", -- [2]
    },
    [122972] = {
      "Dazar'ai Augur", -- [1]
      "Atal'Dazar", -- [2]
    },
    [129366] = {
      "Bilge Rat Buccaneer", -- [1]
      "Siege of Boralus", -- [2]
    },
    [198311] = {
      "Flamewrought Eradicator", -- [1]
      "Vault of the Incarnates", -- [2]
    },
    [114796] = {
      "Wholesome Hostess", -- [1]
      "Return to Karazhan", -- [2]
    },
    [122984] = {
      "Dazar'ai Colossus", -- [1]
      "Atal'Dazar", -- [2]
    },
    [137517] = {
      "Ashvane Destroyer", -- [1]
      "Siege of Boralus", -- [2]
    },
    [99891] = {
      "Storm Drake", -- [1]
      "Halls of Valor", -- [2]
    },
    [168886] = {
      "Virulax Blightweaver", -- [1]
      "Plaguefall", -- [2]
    },
    [167607] = {
      "Stoneborn Slasher", -- [1]
      "Halls of Atonement", -- [2]
    },
    [134599] = {
      "Imbued Stormcaller", -- [1]
      "Temple of Sethraliss", -- [2]
    },
    [91000] = {
      "Vileshard Hulk", -- [1]
      "Neltharion's Lair", -- [2]
    },
    [129601] = {
      "Cutwater Harpooner", -- [1]
      "Freehold", -- [2]
    },
    [162317] = {
      "Gorechop", -- [1]
      "Theater of Pain", -- [2]
    },
    [186116] = {
      "Gutshot", -- [1]
      "Brackenhide Hollow", -- [2]
    },
    [186229] = {
      "Wilted Oak", -- [1]
      "Brackenhide Hollow", -- [2]
    },
    [172981] = {
      "Kyrian Stitchwerk", -- [1]
      "The Necrotic Wake", -- [2]
    },
    [130661] = {
      "Venture Co. Earthshaper", -- [1]
      "The MOTHERLODE!!", -- [2]
    },
    [134600] = {
      "Sandswept Marksman", -- [1]
      "Temple of Sethraliss", -- [2]
    },
    [187771] = {
      "Kadros Icewrath", -- [1]
      "Vault of the Incarnates", -- [2]
    },
    [190381] = {
      "Rotburst Totem", -- [1]
      "Brackenhide Hollow", -- [2]
    },
    [165137] = {
      "Zolramus Gatekeeper", -- [1]
      "The Necrotic Wake", -- [2]
    },
    [130404] = {
      "Vermin Trapper", -- [1]
      "Freehold", -- [2]
    },
    [174773] = {
      "Spiteful Shade", -- [1]
      "Sanguine Depths", -- [2]
    },
    [205734] = {
      "Sundered Edgelord", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [114544] = {
      "Skeletal Usher", -- [1]
      "Return to Karazhan", -- [2]
    },
    [115640] = {
      "Fuming Imp", -- [1]
      "Faronaar", -- [2]
    },
    [91001] = {
      "Tarspitter Lurker", -- [1]
      "Neltharion's Lair", -- [2]
    },
    [128969] = {
      "Ashvane Commander", -- [1]
      "Siege of Boralus", -- [2]
    },
    [173189] = {
      "Nathrian Hawkeye", -- [1]
      "Castle Nathria", -- [2]
    },
    [176565] = {
      "Disruptive Patron", -- [1]
      "Tazavesh, the Veiled Market", -- [2]
    },
    [151325] = {
      "Alarm-o-Bot", -- [1]
      "Operation: Mechagon", -- [2]
    },
    [205735] = {
      "Sundered Preserver", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [138281] = {
      "Faceless Corruptor", -- [1]
      "The Underrot", -- [2]
    },
    [199595] = {
      "Nokhud Defender", -- [1]
      "The Nokhud Offensive", -- [2]
    },
    [114542] = {
      "Ghostly Philanthropist", -- [1]
      "Return to Karazhan", -- [2]
    },
    [96247] = {
      "Vileshard Crawler", -- [1]
      "Neltharion's Lair", -- [2]
      "enUS", -- [3]
    },
    [130024] = {
      "Soggy Shiprat", -- [1]
      "Freehold", -- [2]
      "enUS", -- [3]
    },
    [190128] = {
      "Zul'gamux", -- [1]
      "Operation: Mechagon", -- [2]
    },
    [133835] = {
      "Feral Bloodswarmer", -- [1]
      "The Underrot", -- [2]
    },
    [205736] = {
      "Sundered Siegemaster", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [194990] = {
      "Stormseeker Acolyte", -- [1]
      "Vault of the Incarnates", -- [2]
    },
    [205737] = {
      "Sundered Manaweaver", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [91002] = {
      "Rotdrool Grabber", -- [1]
      "UNKNOWN", -- [2]
    },
    [84989] = {
      "Infested Icecaller", -- [1]
      "The Everbloom", -- [2]
    },
    [138187] = {
      "Grotesque Horror", -- [1]
      "The Underrot", -- [2]
    },
    [105715] = {
      "Watchful Inquisitor", -- [1]
      "Court of Stars", -- [2]
    },
    [133836] = {
      "Reanimated Guardian", -- [1]
      "The Underrot", -- [2]
    },
    [81407] = {
      "Grimrail Bombardier", -- [1]
      "Grimrail Depot", -- [2]
    },
    [166589] = {
      "Animated Weapon", -- [1]
      "Sanguine Depths", -- [2]
    },
    [91007] = {
      "Dargrul", -- [1]
      "Neltharion's Lair", -- [2]
      "enUS", -- [3]
    },
    [167612] = {
      "Stoneborn Reaver", -- [1]
      "Halls of Atonement", -- [2]
    },
    [26125] = {
      "Rippenwurm", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [189555] = {
      "Arcane Attendant", -- [1]
      "The Azure Vault", -- [2]
    },
    [141284] = {
      "Kul Tiran Wavetender", -- [1]
      "Siege of Boralus", -- [2]
    },
    [92538] = {
      "Tarspitter Grub", -- [1]
      "Neltharion's Lair", -- [2]
    },
    [187315] = {
      "Disease Slasher", -- [1]
      "Brackenhide Hollow", -- [2]
    },
    [136139] = {
      "Mechanized Peacekeeper", -- [1]
      "The MOTHERLODE!!", -- [2]
    },
    [144071] = {
      "Irontide Waveshaper", -- [1]
      "Siege of Boralus", -- [2]
    },
    [91003] = {
      "Rokmora", -- [1]
      "Neltharion's Lair", -- [2]
      "enUS", -- [3]
    },
    [84990] = {
      "Addled Arcanomancer", -- [1]
      "The Everbloom", -- [2]
    },
    [157634] = {
      "Flameforge Enforcer", -- [1]
      "Torghast, Tower of the Damned", -- [2]
    },
    [173190] = {
      "Court Hawkeye", -- [1]
      "Castle Nathria", -- [2]
    },
    [201579] = {
      "Magmorax", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [193457] = {
      "Balara", -- [1]
      "The Nokhud Offensive", -- [2]
    },
    [134701] = {
      "Blood Effigy", -- [1]
      "The Underrot", -- [2]
    },
    [137516] = {
      "Ashvane Invader", -- [1]
      "Siege of Boralus", -- [2]
    },
    [163520] = {
      "Forsworn Squad-Leader", -- [1]
      "Spires of Ascension", -- [2]
    },
    [205478] = {
      "Conduit Guardian", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [187510] = {
      "Duskpaw Trapper", -- [1]
      "10.0 Dragon Isles", -- [2]
    },
    [129559] = {
      "Cutwater Duelist", -- [1]
      "Freehold", -- [2]
    },
    [187566] = {
      "Hyena Matriarch", -- [1]
      "10.0 Dragon Isles", -- [2]
    },
    [86526] = {
      "Grom'kar Chainmaster", -- [1]
      "Iron Docks", -- [2]
    },
    [136398] = {
      "Illidari Satyr", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [150295] = {
      "Tank Buster MK1", -- [1]
      "Operation: Mechagon", -- [2]
    },
    [91004] = {
      "Ularogg Cragshaper", -- [1]
      "Neltharion's Lair", -- [2]
      "enUS", -- [3]
    },
    [165824] = {
      "Nar'zudah", -- [1]
      "The Necrotic Wake", -- [2]
    },
    [125977] = {
      "Reanimation Totem", -- [1]
      "Atal'Dazar", -- [2]
    },
    [132532] = {
      "Kul Tiran Marksman", -- [1]
      "Siege of Boralus", -- [2]
    },
    [81603] = {
      "Champion Druna", -- [1]
      "Iron Docks", -- [2]
    },
    [189235] = {
      "Overseer Lahar", -- [1]
      "Neltharus", -- [2]
    },
    [179386] = {
      "Corsair Officer", -- [1]
      "Tazavesh, the Veiled Market", -- [2]
    },
    [204206] = {
      "Horde Farseer", -- [1]
      "Dawn of the Infinite", -- [2]
    },
    [75652] = {
      "Void Spawn", -- [1]
      "Shadowmoon Burial Grounds", -- [2]
    },
    [150292] = {
      "Mechagon Cavalry", -- [1]
      "Operation: Mechagon", -- [2]
    },
    [83392] = {
      "Rampaging Clefthoof", -- [1]
      "Iron Docks", -- [2]
    },
    [168384] = {
      "Flesh Construct", -- [1]
      "The Necrotic Wake", -- [2]
    },
    [130012] = {
      "Irontide Ravager", -- [1]
      "Freehold", -- [2]
    },
    [81985] = {
      "Everbloom Cultivator", -- [1]
      "The Everbloom", -- [2]
    },
    [185528] = {
      "Trickclaw Mystic", -- [1]
      "Brackenhide Hollow", -- [2]
    },
    [189878] = {
      "Nathrezim Infiltrator", -- [1]
      "Operation: Mechagon", -- [2]
    },
    [91005] = {
      "Naraxas", -- [1]
      "Neltharion's Lair", -- [2]
      "enUS", -- [3]
    },
    [165556] = {
      "Fleeting Manifestation", -- [1]
      "Sanguine Depths", -- [2]
    },
    [196202] = {
      "Spectral Invoker", -- [1]
      "Algeth'ar Academy", -- [2]
    },
    [176573] = {
      "Mawsworn Woebringer", -- [1]
      "Torghast, Tower of the Damned", -- [2]
    },
    [180336] = {
      "Cartel Wiseguy", -- [1]
      "Tazavesh, the Veiled Market", -- [2]
    },
    [132051] = {
      "Blood Tick", -- [1]
      "The Underrot", -- [2]
      "enUS", -- [3]
    },
    [179388] = {
      "Hourglass Tidesage", -- [1]
      "Tazavesh, the Veiled Market", -- [2]
    },
    [175550] = {
      "Volatile Faerie", -- [1]
      "9.0 Bastion Arena - Path of Ascension", -- [2]
    },
    [77700] = {
      "Shadowmoon Exhumer", -- [1]
      "Shadowmoon Burial Grounds", -- [2]
    },
    [169875] = {
      "Shackled Soul", -- [1]
      "Theater of Pain", -- [2]
    },
    [133663] = {
      "Fanatical Headhunter", -- [1]
      "The Underrot", -- [2]
      "enUS", -- [3]
    },
    [163458] = {
      "Forsworn Castigator", -- [1]
      "Spires of Ascension", -- [2]
    },
    [154758] = {
      "Toxic Monstrosity", -- [1]
      "Operation: Mechagon", -- [2]
    },
    [193462] = {
      "Batak", -- [1]
      "The Nokhud Offensive", -- [2]
    },
    [203811] = {
      "Incarnation of Entropy", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [184422] = {
      "Emberon", -- [1]
      "Uldaman: Legacy of Tyr", -- [2]
      "enUS", -- [3]
    },
    [91006] = {
      "Rockback Gnasher", -- [1]
      "Neltharion's Lair", -- [2]
    },
    [154020] = {
      "Prisonbreak Cursewalker", -- [1]
      "Torghast, Tower of the Damned", -- [2]
    },
    [203812] = {
      "Voice From Beyond", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [176575] = {
      "Mawsworn Soulwarden", -- [1]
      "Torghast, Tower of the Damned", -- [2]
    },
    [81283] = {
      "Grom'kar Footsoldier", -- [1]
      "Iron Docks", -- [2]
    },
    [166396] = {
      "Noble Skirmisher", -- [1]
      "Sanguine Depths", -- [2]
    },
    [136403] = {
      "Void Terror", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [174802] = {
      "Venomous Sniper", -- [1]
      "Plaguefall", -- [2]
    },
    [75713] = {
      "Shadowmoon Bone-Mender", -- [1]
      "Shadowmoon Burial Grounds", -- [2]
    },
    [194487] = {
      "Vile Rothexer", -- [1]
      "Brackenhide Hollow", -- [2]
    },
    [114803] = {
      "Spectral Stable Hand", -- [1]
      "Return to Karazhan", -- [2]
    },
    [45922] = {
      "Empyrean Assassin", -- [1]
      "The Vortex Pinnacle", -- [2]
    },
    [188252] = {
      "Melidrussa Chillworn", -- [1]
      "Ruby Life Pools", -- [2]
    },
    [24207] = {
      "Army of the Dead", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [136404] = {
      "Bilescourge", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [115757] = {
      "Wrathguard Flamebringer", -- [1]
      "Return to Karazhan", -- [2]
    },
    [198326] = {
      "Stormwrought Despoiler", -- [1]
      "Vault of the Incarnates", -- [2]
    },
    [169924] = {
      "Veteran Stoneguard", -- [1]
      "Castle Nathria", -- [2]
    },
    [171799] = {
      "Depths Warden", -- [1]
      "Sanguine Depths", -- [2]
    },
    [105720] = {
      "Understone Drudge", -- [1]
      "Neltharion's Lair", -- [2]
      "enUS", -- [3]
    },
    [198869] = {
      "Sundered Devastator", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [177891] = {
      "Mawforged Summoner", -- [1]
      "Sanctum of Domination", -- [2]
    },
    [75966] = {
      "Defiled Spirit", -- [1]
      "Shadowmoon Burial Grounds", -- [2]
    },
    [137486] = {
      "Queen Patlaa", -- [1]
      "Kings' Rest", -- [2]
    },
    [114266] = {
      "Shoreline Tidespeaker", -- [1]
      "Return to Karazhan", -- [2]
    },
    [115020] = {
      "Arcanid", -- [1]
      "Return to Karazhan", -- [2]
    },
    [114804] = {
      "Spectral Charger", -- [1]
      "Return to Karazhan", -- [2]
    },
    [135241] = {
      "Bilge Rat Pillager", -- [1]
      "Siege of Boralus", -- [2]
    },
    [164552] = {
      "Rotmarrow Slime", -- [1]
      "Plaguefall", -- [2]
    },
    [131858] = {
      "Thornguard", -- [1]
      "Waycrest Manor", -- [2]
    },
    [167111] = {
      "Spinemaw Staghorn", -- [1]
      "Mists of Tirna Scithe", -- [2]
    },
    [206140] = {
      "Coalesced Time", -- [1]
      "Dawn of the Infinite", -- [2]
      "enUS", -- [3]
    },
    [91008] = {
      "Rockbound Pelter", -- [1]
      "Neltharion's Lair", -- [2]
    },
    [196482] = {
      "Overgrown Ancient", -- [1]
      "Algeth'ar Academy", -- [2]
    },
    [196043] = {
      "Primalist Infuser", -- [1]
      "Halls of Infusion", -- [2]
    },
    [131545] = {
      "Lady Waycrest", -- [1]
      "Waycrest Manor", -- [2]
    },
    [191164] = {
      "Arcane Tender", -- [1]
      "The Azure Vault", -- [2]
    },
    [208698] = {
      "Infinite Riftmage", -- [1]
      "Dawn of the Infinite", -- [2]
      "enUS", -- [3]
    },
    [169159] = {
      "Unstable Canister", -- [1]
      "Plaguefall", -- [2]
    },
    [184020] = {
      "Hulking Berserker", -- [1]
      "Uldaman: Legacy of Tyr", -- [2]
    },
    [165222] = {
      "Zolramus Bonemender", -- [1]
      "The Necrotic Wake", -- [2]
    },
    [169927] = {
      "Putrid Butcher", -- [1]
      "Theater of Pain", -- [2]
    },
    [163366] = {
      "Magus of the Dead", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [133593] = {
      "Expert Technician", -- [1]
      "The MOTHERLODE!!", -- [2]
    },
    [192337] = {
      "Void Tendril", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [162763] = {
      "Soulforged Bonereaver", -- [1]
      "Theater of Pain", -- [2]
    },
    [167113] = {
      "Spinemaw Acidgullet", -- [1]
      "Mists of Tirna Scithe", -- [2]
    },
    [189886] = {
      "Blazebound Firestorm", -- [1]
      "Ruby Life Pools", -- [2]
    },
    [199368] = {
      "Hardened Crystal", -- [1]
      "The Azure Vault", -- [2]
    },
    [202814] = {
      "Twisted Aberration", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [196548] = {
      "Ancient Branch", -- [1]
      "Algeth'ar Academy", -- [2]
    },
    [168393] = {
      "Plaguebelcher", -- [1]
      "Plaguefall", -- [2]
    },
    [184581] = {
      "Baelog", -- [1]
      "Uldaman: Legacy of Tyr", -- [2]
    },
    [184911] = {
      "Urh Dismantler", -- [1]
      "The Necrotic Wake", -- [2]
    },
    [185537] = {
      "Foul Controller", -- [1]
      "Sepulcher of the First Ones", -- [2]
    },
    [205623] = {
      "Drazos Blackwing", -- [1]
      "Aberrus, the Shadowed Crucible", -- [2]
      "enUS", -- [3]
    },
    [126832] = {
      "Skycap'n Kragg", -- [1]
      "Freehold", -- [2]
      "enUS", -- [3]
    },
    [83761] = {
      "Ogron Laborer", -- [1]
      "Iron Docks", -- [2]
    },
    [200126] = {
      "Fallen Waterspeaker", -- [1]
      "Temple of the Jade Serpent", -- [2]
    },
    [173016] = {
      "Corpse Collector", -- [1]
      "The Necrotic Wake", -- [2]
    },
    [206065] = {
      "Interval", -- [1]
      "Dawn of the Infinite", -- [2]
    },
    [134139] = {
      "Shrine Templar", -- [1]
      "Shrine of the Storm", -- [2]
    },
    [84957] = {
      "Putrid Pyromancer", -- [1]
      "The Everbloom", -- [2]
    },
    [97720] = {
      "Blightshard Skitter", -- [1]
      "Neltharion's Lair", -- [2]
    },
    [180431] = {
      "Focused Ritualist", -- [1]
      "Tazavesh, the Veiled Market", -- [2]
    },
    [196671] = {
      "Arcane Ravager", -- [1]
      "Algeth'ar Academy", -- [2]
    },
    [138465] = {
      "Ashvane Cannoneer", -- [1]
      "Siege of Boralus", -- [2]
    },
    [178630] = {
      "Mawsworn Seeker", -- [1]
      "Sanctum of Domination", -- [2]
    },
    [133852] = {
      "Living Rot", -- [1]
      "The Underrot", -- [2]
    },
    [177787] = {
      "Mawsworn Hopebreaker", -- [1]
      "Sanctum of Domination", -- [2]
    },
    [134364] = {
      "Faithless Tender", -- [1]
      "Temple of Sethraliss", -- [2]
    },
    [155090] = {
      "Anodized Coilbearer", -- [1]
      "Operation: Mechagon", -- [2]
    },
    [129553] = {
      "Dinomancer Kish'o", -- [1]
      "Atal'Dazar", -- [2]
    },
    [190401] = {
      "Gusting Proto-Dragon", -- [1]
      "Halls of Infusion", -- [2]
    },
    [196798] = {
      "Corrupted Manafiend", -- [1]
      "Algeth'ar Academy", -- [2]
    },
    [168396] = {
      "Plaguebelcher", -- [1]
      "Plaguefall", -- [2]
    },
    [40634] = {
      "Naz'jar Tempest Witch", -- [1]
      "Throne of the Tides", -- [2]
    },
    [213942] = {
      "Sludge", -- [1]
      "Throne of the Tides", -- [2]
    },
    [128455] = {
      "T'lonja", -- [1]
      "Atal'Dazar", -- [2]
    },
    [95769] = {
      "Mindshattered Screecher", -- [1]
      "Darkheart Thicket", -- [2]
    },
    [44404] = {
      "Naz'jar Frost Witch", -- [1]
      "Throne of the Tides", -- [2]
    },
    [100532] = {
      "Bloodtainted Burster", -- [1]
      "Darkheart Thicket", -- [2]
    },
    [115486] = {
      "Erudite Slayer", -- [1]
      "Return to Karazhan", -- [2]
    },
    [99366] = {
      "Taintheart Summoner", -- [1]
      "Darkheart Thicket", -- [2]
    },
    [40633] = {
      "Naz'jar Honor Guard", -- [1]
      "Throne of the Tides", -- [2]
    },
    [98243] = {
      "Soul-Torn Champion", -- [1]
      "Black Rook Hold", -- [2]
    },
  },
  ["aura_grow_direction"] = 3,
  ["health_selection_overlay_alpha"] = 0.29999998211861,
  ["aura_stack_shadow_color"] = {
    nil, -- [1]
    nil, -- [2]
    nil, -- [3]
    0, -- [4]
  },
  ["minor_height_scale"] = 0.99999994039536,
  ["aura_padding"] = 2,
  ["indicator_worldboss"] = false,
  ["last_news_time"] = 1551553489,
  ["aura_width2"] = 15,
  ["aura_stack_size"] = 7,
  ["plater_resources_align"] = "horizontal",
  ["plater_resources_scale"] = 0.8,
  ["cast_colors"] = {
    [376171] = {
      true, -- [1]
      "orchid", -- [2]
      "", -- [3]
    },
    [375727] = {
      true, -- [1]
      "orangered", -- [2]
      "", -- [3]
    },
    [369409] = {
      true, -- [1]
      "orangered", -- [2]
      "", -- [3]
    },
    [397889] = {
      true, -- [1]
      "mediumturquoise", -- [2]
      "", -- [3]
    },
    [369061] = {
      true, -- [1]
      "orangered", -- [2]
      "", -- [3]
    },
    [375348] = {
      true, -- [1]
      "orangered", -- [2]
      "", -- [3]
    },
    [269843] = {
      true, -- [1]
      "orangered", -- [2]
      "", -- [3]
    },
    [396812] = {
      true, -- [1]
      "darkorange", -- [2]
      "", -- [3]
    },
    [88194] = {
      true, -- [1]
      "orangered", -- [2]
      "", -- [3]
    },
    [265019] = {
      true, -- [1]
      "orangered", -- [2]
      "", -- [3]
    },
    [375351] = {
      true, -- [1]
      "orangered", -- [2]
      "", -- [3]
    },
    [257756] = {
      true, -- [1]
      "orchid", -- [2]
      "", -- [3]
    },
    [272609] = {
      true, -- [1]
      "orangered", -- [2]
      "", -- [3]
    },
    [201226] = {
      true, -- [1]
      "orangered", -- [2]
      "", -- [3]
    },
    [265372] = {
      true, -- [1]
      "orangered", -- [2]
      "", -- [3]
    },
    [411994] = {
      true, -- [1]
      "darkorange", -- [2]
      "", -- [3]
    },
    [255567] = {
      true, -- [1]
      "orangered", -- [2]
      "", -- [3]
    },
    [200291] = {
      true, -- [1]
      "orchid", -- [2]
      "", -- [3]
    },
    [397931] = {
      true, -- [1]
      "mediumturquoise", -- [2]
      "", -- [3]
    },
    [257870] = {
      true, -- [1]
      "orchid", -- [2]
      "", -- [3]
    },
    [412505] = {
      true, -- [1]
      "orangered", -- [2]
      "", -- [3]
    },
    [226406] = {
      true, -- [1]
      "orangered", -- [2]
      "", -- [3]
    },
    [200768] = {
      true, -- [1]
      "orangered", -- [2]
      "", -- [3]
    },
    [257426] = {
      true, -- [1]
      "orangered", -- [2]
      "", -- [3]
    },
    [375327] = {
      true, -- [1]
      "orangered", -- [2]
      "", -- [3]
    },
    [372311] = {
      true, -- [1]
      "orangered", -- [2]
      "", -- [3]
    },
    [183465] = {
      true, -- [1]
      "orangered", -- [2]
      "", -- [3]
    },
    [226296] = {
      true, -- [1]
      "orangered", -- [2]
      "", -- [3]
    },
    [396665] = {
      true, -- [1]
      "orangered", -- [2]
      "", -- [3]
    },
    [373742] = {
      true, -- [1]
      "orangered", -- [2]
      "", -- [3]
    },
    [209628] = {
      true, -- [1]
      "blue", -- [2]
      "", -- [3]
    },
    [200913] = {
      true, -- [1]
      "orangered", -- [2]
      "", -- [3]
    },
    [199151] = {
      true, -- [1]
      "blue", -- [2]
      "", -- [3]
    },
    [265540] = {
      true, -- [1]
      "orchid", -- [2]
      "", -- [3]
    },
    [257397] = {
      true, -- [1]
      "darkorange", -- [2]
      "", -- [3]
    },
    [384597] = {
      false, -- [1]
      "white", -- [2]
    },
    [156718] = {
      true, -- [1]
      "darkorange", -- [2]
      "", -- [3]
    },
    [253721] = {
      true, -- [1]
      "orchid", -- [2]
      "", -- [3]
    },
    [388060] = {
      true, -- [1]
      "orangered", -- [2]
      "", -- [3]
    },
    [265568] = {
      true, -- [1]
      "orchid", -- [2]
      "", -- [3]
    },
    [369365] = {
      true, -- [1]
      "darkorange", -- [2]
      "", -- [3]
    },
    [413529] = {
      true, -- [1]
      "orangered", -- [2]
      "", -- [3]
    },
    [428293] = {
      true, -- [1]
      "orangered", -- [2]
      "", -- [3]
    },
    [372201] = {
      true, -- [1]
      "orangered", -- [2]
      "", -- [3]
    },
    [393432] = {
      true, -- [1]
      "orangered", -- [2]
      "", -- [3]
    },
    [260793] = {
      true, -- [1]
      "orangered", -- [2]
      "", -- [3]
    },
    [87618] = {
      true, -- [1]
      "orangered", -- [2]
      "", -- [3]
    },
    [369675] = {
      true, -- [1]
      "darkorange", -- [2]
      "", -- [3]
    },
    [419351] = {
      true, -- [1]
      "orangered", -- [2]
      "", -- [3]
    },
    [183088] = {
      true, -- [1]
      "orangered", -- [2]
      "", -- [3]
    },
    [370764] = {
      true, -- [1]
      "mediumturquoise", -- [2]
      "", -- [3]
    },
    [88308] = {
      true, -- [1]
      "orangered", -- [2]
      "", -- [3]
    },
    [375251] = {
      true, -- [1]
      "orangered", -- [2]
      "", -- [3]
    },
    [384524] = {
      true, -- [1]
      "orangered", -- [2]
      "", -- [3]
    },
    [426645] = {
      true, -- [1]
      "orangered", -- [2]
      "", -- [3]
    },
    [188169] = {
      true, -- [1]
      "orangered", -- [2]
      "", -- [3]
    },
    [200345] = {
      true, -- [1]
      "orchid", -- [2]
      "", -- [3]
    },
    [427376] = {
      true, -- [1]
      "orchid", -- [2]
      "", -- [3]
    },
    [164357] = {
      true, -- [1]
      "orangered", -- [2]
      "", -- [3]
    },
    [412200] = {
      true, -- [1]
      "orchid", -- [2]
      "", -- [3]
    },
    [169929] = {
      true, -- [1]
      "orangered", -- [2]
      "", -- [3]
    },
    [369465] = {
      true, -- [1]
      "orchid", -- [2]
      "", -- [3]
    },
    [200784] = {
      true, -- [1]
      "orchid", -- [2]
      "", -- [3]
    },
    [413607] = {
      true, -- [1]
      "orchid", -- [2]
      "", -- [3]
    },
    [382712] = {
      true, -- [1]
      "orangered", -- [2]
      "", -- [3]
    },
    [372223] = {
      true, -- [1]
      "darkorange", -- [2]
      "", -- [3]
    },
    [384978] = {
      true, -- [1]
      "mediumturquoise", -- [2]
      "", -- [3]
    },
    [416139] = {
      true, -- [1]
      "orangered", -- [2]
      "", -- [3]
    },
    [371875] = {
      true, -- [1]
      "orangered", -- [2]
      "", -- [3]
    },
    [412012] = {
      true, -- [1]
      "orchid", -- [2]
      "", -- [3]
    },
    [260894] = {
      true, -- [1]
      "orangered", -- [2]
      "", -- [3]
    },
    [412129] = {
      true, -- [1]
      "orangered", -- [2]
      "", -- [3]
    },
    [412215] = {
      true, -- [1]
      "orangered", -- [2]
      "", -- [3]
    },
    [193505] = {
      true, -- [1]
      "orangered", -- [2]
      "", -- [3]
    },
    [382708] = {
      true, -- [1]
      "orangered", -- [2]
      "", -- [3]
    },
    [372735] = {
      true, -- [1]
      "mediumturquoise", -- [2]
      "", -- [3]
    },
    [268202] = {
      true, -- [1]
      "orchid", -- [2]
      "", -- [3]
    },
    [388392] = {
      true, -- [1]
      "darkorange", -- [2]
      "", -- [3]
    },
    [169179] = {
      true, -- [1]
      "orangered", -- [2]
      "", -- [3]
    },
    [408141] = {
      true, -- [1]
      "orangered", -- [2]
      "", -- [3]
    },
    [200261] = {
      true, -- [1]
      "orangered", -- [2]
      "", -- [3]
    },
    [375439] = {
      true, -- [1]
      "orangered", -- [2]
      "", -- [3]
    },
    [411012] = {
      true, -- [1]
      "orangered", -- [2]
      "", -- [3]
    },
    [226304] = {
      true, -- [1]
      "orangered", -- [2]
      "", -- [3]
    },
    [376170] = {
      true, -- [1]
      "orangered", -- [2]
      "", -- [3]
    },
    [266209] = {
      true, -- [1]
      "white", -- [2]
      "", -- [3]
    },
    [377204] = {
      true, -- [1]
      "orangered", -- [2]
      "", -- [3]
    },
    [387950] = {
      true, -- [1]
      "orangered", -- [2]
      "", -- [3]
    },
    [197974] = {
      true, -- [1]
      "orangered", -- [2]
      "", -- [3]
    },
  },
  ["ui_parent_cast_strata"] = "DIALOG",
  ["class_colors"] = {
    ["DEATHKNIGHT"] = {
      ["colorStr"] = "ffc31d3a",
    },
    ["WARRIOR"] = {
      ["colorStr"] = "ffc69a6d",
    },
    ["PALADIN"] = {
      ["colorStr"] = "fff48bb9",
    },
    ["WARLOCK"] = {
      ["colorStr"] = "ff8687ed",
    },
    ["DEMONHUNTER"] = {
      ["colorStr"] = "ffa22fc8",
    },
    ["ROGUE"] = {
      ["colorStr"] = "fffff467",
    },
    ["DRUID"] = {
      ["colorStr"] = "ffff7c09",
    },
    ["EVOKER"] = {
      ["colorStr"] = "ff33937e",
    },
    ["SHAMAN"] = {
      ["colorStr"] = "ff006fdd",
    },
  },
  ["extra_icon_anchor"] = {
    ["x"] = 0,
    ["side"] = 9,
  },
  ["range_check_alpha"] = 0.5999999642372131,
  ["semver"] = "1.0.23",
  ["plater_resources_padding"] = 2,
  ["aura_frame2_anchor"] = {
    ["y"] = 0,
    ["x"] = 2.5,
    ["side"] = 6,
  },
  ["cast_statusbar_texture"] = "Melli",
  ["auto_toggle_friendly"] = {
    ["world"] = false,
  },
  ["indicator_faction"] = false,
  ["extra_icon_height"] = 8,
  ["plater_resources_show_number"] = false,
  ["debuff_show_cc_border"] = {
    0.090196080505848, -- [1]
    0.090196080505848, -- [2]
    0.090196080505848, -- [3]
  },
  ["aura_consolidate"] = true,
  ["extra_icon_width"] = 12,
  ["health_statusbar_texture"] = "Melli",
  ["hook_auto_imported"] = {
    ["Color Automation"] = 1,
    ["Blockade Encounter"] = 1,
    ["Cast Bar Icon Config"] = 2,
    ["Hide Neutral Units"] = 1,
    ["Aura Reorder"] = 3,
    ["Reorder Nameplate"] = 4,
    ["Dont Have Aura"] = 1,
    ["Players Targetting Amount"] = 4,
    ["Bwonsamdi Reaping"] = 1,
    ["Jaina Encounter"] = 6,
    ["Monk Statue"] = 2,
    ["Combo Points"] = 6,
    ["Extra Border"] = 2,
    ["Targetting Alpha"] = 3,
    ["Target Color"] = 3,
    ["Attacking Specific Unit"] = 2,
    ["Execute Range"] = 1,
  },
  ["extra_icon_border_color"] = {
    0.090196080505848, -- [1]
    0.090196080505848, -- [2]
    0.090196080505848, -- [3]
  },
  ["minor_width_scale"] = 0.99999994039536,
  ["indicator_pet"] = false,
  ["aura_frame1_anchor"] = {
    ["y"] = 8,
    ["side"] = 1,
  },
  ["aura_timer_text_font"] = "Cronix-Bold",
  ["cast_statusbar_color_finished"] = {
    0.52156865596771, -- [1]
    0.83921575546265, -- [2]
    0.58431375026703, -- [3]
  },
  ["extra_icon_stack_font"] = "Cronix",
  ["aura_height"] = 10,
  ["cast_statusbar_bgtexture"] = "Melli",
  ["plater_resources_personal_bar"] = false,
  ["target_indicator"] = "Thin Arrow",
  ["extra_icon_stack_size"] = 7,
  ["aura_show_buff_by_the_unit"] = false,
  ["saved_cvars"] = {
    ["nameplateShowOnlyNames"] = "0",
    ["nameplateOverlapV"] = "1.3999999761581",
    ["nameplateLargeTopInset"] = "0.085",
    ["nameplateShowEnemyMinus"] = "1",
    ["NamePlateClassificationScale"] = "1",
    ["nameplateShowFriendlyTotems"] = "0",
    ["nameplatePersonalHideDelaySeconds"] = "0.2",
    ["nameplateShowFriendlyPets"] = "0",
    ["nameplatePersonalShowInCombat"] = "1",
    ["nameplatePersonalShowWithTarget"] = "0",
    ["nameplateMinAlpha"] = "0.90135484",
    ["nameplateResourceOnTarget"] = "0",
    ["nameplateShowAll"] = "1",
    ["nameplateMaxDistance"] = "100",
    ["nameplateShowFriendlyMinions"] = "0",
    ["nameplateSelfScale"] = "1.0",
    ["nameplateTargetBehindMaxDistance"] = "30",
    ["nameplateShowEnemies"] = "1",
    ["NamePlateVerticalScale"] = "1",
    ["nameplateSelectedAlpha"] = "1",
    ["nameplateShowSelf"] = "0",
    ["nameplatePersonalShowAlways"] = "0",
    ["nameplateMotionSpeed"] = "0.05",
    ["nameplateGlobalScale"] = "1",
    ["nameplateShowEnemyMinions"] = "1",
    ["nameplateShowFriendlyNPCs"] = "1",
    ["nameplateSelectedScale"] = "1",
    ["nameplateMinAlphaDistance"] = "-158489.31924611",
    ["nameplateMotion"] = "1",
    ["ShowNamePlateLoseAggroFlash"] = "1",
    ["nameplateMinScale"] = "1",
    ["ShowClassColorInNameplate"] = "1",
    ["nameplateOtherTopInset"] = "0.085",
    ["nameplateOtherAtBase"] = "0",
    ["nameplateSelfBottomInset"] = "0.2",
    ["NamePlateHorizontalScale"] = "1",
    ["nameplateShowFriendlyGuardians"] = "0",
    ["nameplateSelfAlpha"] = "0.75",
    ["nameplateSelfTopInset"] = "0.5",
    ["nameplateOccludedAlphaMult"] = "1",
    ["nameplateTargetRadialPosition"] = "1",
    ["nameplateShowFriends"] = "0",
  },
  ["login_counter"] = 14333,
  ["click_space_friendly"] = {
    130, -- [1]
    30, -- [2]
  },
  ["plater_resources_show"] = false,
  ["blizzard_nameplate_font"] = "Cronix-Bold",
  ["auto_toggle_combat"] = {
    ["blizz_healthbar_ooc"] = true,
  },
  ["hide_friendly_castbars"] = true,
  ["OptionsPanelDB"] = {
    ["PlaterOptionsPanelFrame"] = {
      ["scale"] = 1.1000000238419,
    },
  },
  ["aura_timer_text_shadow_color"] = {
    nil, -- [1]
    nil, -- [2]
    nil, -- [3]
    0, -- [4]
  },
  ["auras_per_row_amount"] = 7,
  ["plater_resources_show_depleted"] = false,
  ["blizzard_nameplate_large_font"] = "Cronix-Bold",
  ["aura_stack_anchor"] = {
    ["y"] = 4.899999618530273,
    ["x"] = 2.799999237060547,
    ["side"] = 5,
  },
  ["usePlaterWidget"] = false,
  ["plate_config"] = {
    ["player"] = {
      ["spellpercent_text_font"] = "Cronix-Bold",
      ["power_percent_text_enabled"] = false,
      ["level_text_font"] = "Accidental Presidency",
      ["actorname_text_font"] = "Accidental Presidency",
      ["big_actortitle_text_font"] = "Accidental Presidency",
      ["spellname_text_font"] = "Cronix-Bold",
      ["click_through"] = true,
      ["big_actorname_text_font"] = "Accidental Presidency",
      ["power_percent_text_color"] = {
        1, -- [1]
        1, -- [2]
        1, -- [3]
      },
      ["percent_text_font"] = "Cronix-Bold",
      ["power_percent_text_font"] = "Cronix-Bold",
    },
    ["friendlyplayer"] = {
      ["actorname_use_friends_color"] = false,
      ["spellpercent_text_font"] = "ViklunD's SexFont",
      ["level_text_size"] = 7,
      ["actorname_use_class_color"] = true,
      ["cast"] = {
        120, -- [1]
      },
      ["big_actortitle_text_size"] = 8,
      ["spellpercent_text_anchor"] = {
        ["y"] = -0.8000030517578125,
        ["x"] = 3.899993896484375,
        ["side"] = 5,
      },
      ["percent_text_show_decimals"] = false,
      ["spellname_text_outline"] = "OUTLINE",
      ["big_actorname_text_shadow_color"] = {
        0, -- [1]
        0, -- [2]
        0, -- [3]
        1, -- [4]
      },
      ["level_text_font"] = "Cronix-Bold",
      ["actorname_text_font"] = "Cronix-Bold",
      ["big_actorname_text_shadow_color_offset"] = {
        1, -- [1]
        -1, -- [2]
      },
      ["mana_incombat"] = {
        nil, -- [1]
        4, -- [2]
      },
      ["actorname_use_guild_color"] = false,
      ["all_names"] = true,
      ["big_actortitle_text_outline"] = "OUTLINE",
      ["actorname_text_spacing"] = 6,
      ["only_damaged"] = false,
      ["quest_color_enemy"] = {
        0.63921570777893, -- [1]
        1, -- [2]
        0.31764706969261, -- [3]
        1, -- [4]
      },
      ["only_thename"] = true,
      ["big_actortitle_text_font"] = "Cronix",
      ["spellpercent_text_size"] = 7,
      ["level_text_anchor"] = {
        ["y"] = 100,
        ["x"] = 1,
        ["side"] = 5,
      },
      ["percent_show_percent"] = false,
      ["big_actortitle_text_shadow_color_offset"] = {
        1, -- [1]
        -1, -- [2]
      },
      ["cast_incombat"] = {
        120, -- [1]
        8, -- [2]
      },
      ["mana"] = {
        nil, -- [1]
        4, -- [2]
      },
      ["actorname_text_shadow_color"] = {
        nil, -- [1]
        nil, -- [2]
        nil, -- [3]
        0, -- [4]
      },
      ["spellname_text_anchor"] = {
        ["side"] = 3,
      },
      ["big_actortitle_text_shadow_color"] = {
        0, -- [1]
        0, -- [2]
        0, -- [3]
        1, -- [4]
      },
      ["percent_text_anchor"] = {
        ["side"] = 11,
      },
      ["big_actorname_text_size"] = 8,
      ["spellname_text_font"] = "Cronix-Bold",
      ["big_actorname_text_outline"] = "OUTLINE",
      ["quest_color_neutral"] = {
        0.63921570777893, -- [1]
        1, -- [2]
        0.31764706969261, -- [3]
        1, -- [4]
      },
      ["actorname_text_size"] = 7,
      ["power_percent_text_font"] = "Accidental Presidency",
      ["level_text_alpha"] = 0.29999998211861,
      ["percent_text_size"] = 7,
      ["percent_text_shadow_color"] = {
        nil, -- [1]
        nil, -- [2]
        nil, -- [3]
        0, -- [4]
      },
      ["percent_text_font"] = "Cronix-Bold",
      ["buff_frame_y_offset"] = 0,
      ["quest_enabled"] = true,
      ["spellname_text_color"] = {
        0.95294117647059, -- [1]
        [3] = 0.9921568627451,
      },
      ["quest_color_enabled"] = true,
      ["spellname_text_size"] = 7,
      ["health"] = {
        120, -- [1]
        12, -- [2]
      },
      ["health_incombat"] = {
        120, -- [1]
        12, -- [2]
      },
      ["big_actorname_text_font"] = "Cronix",
      ["spellname_text_shadow_color"] = {
        nil, -- [1]
        nil, -- [2]
        nil, -- [3]
        0, -- [4]
      },
      ["spellpercent_text_shadow_color"] = {
        nil, -- [1]
        nil, -- [2]
        nil, -- [3]
        0, -- [4]
      },
    },
    ["friendlynpc"] = {
      ["spellpercent_text_font"] = "ViklunD's SexFont",
      ["level_text_size"] = 7,
      ["cast"] = {
        120, -- [1]
        8, -- [2]
      },
      ["percent_text_shadow_color"] = {
        nil, -- [1]
        nil, -- [2]
        nil, -- [3]
        0, -- [4]
      },
      ["spellpercent_text_anchor"] = {
        ["y"] = -0.8000030517578125,
        ["x"] = 3.899993896484375,
        ["side"] = 5,
      },
      ["spellname_text_outline"] = "OUTLINE",
      ["level_text_font"] = "Cronix-Bold",
      ["actorname_text_font"] = "Cronix-Bold",
      ["actorname_text_outline"] = "OUTLINE",
      ["actorname_text_spacing"] = 6,
      ["quest_color_enemy"] = {
        0.63921570777893, -- [1]
        1, -- [2]
        0.31764706969261, -- [3]
        1, -- [4]
      },
      ["big_actortitle_text_font"] = "Cronix-Bold",
      ["spellpercent_text_size"] = 7,
      ["level_text_anchor"] = {
        ["y"] = 100,
        ["x"] = 1,
        ["side"] = 5,
      },
      ["spellpercent_text_shadow_color"] = {
        nil, -- [1]
        nil, -- [2]
        nil, -- [3]
        0, -- [4]
      },
      ["cast_incombat"] = {
        nil, -- [1]
        8, -- [2]
      },
      ["actorname_text_shadow_color"] = {
        nil, -- [1]
        nil, -- [2]
        nil, -- [3]
        0, -- [4]
      },
      ["spellname_text_anchor"] = {
        ["y"] = 0.09999847412109375,
        ["x"] = -0.8000030517578125,
        ["side"] = 3,
      },
      ["percent_text_anchor"] = {
        ["side"] = 11,
      },
      ["big_actortitle_text_size"] = 8,
      ["spellname_text_font"] = "Cronix-Bold",
      ["only_names"] = false,
      ["quest_color_neutral"] = {
        0.63921570777893, -- [1]
        1, -- [2]
        0.31764706969261, -- [3]
        1, -- [4]
      },
      ["actorname_text_size"] = 7,
      ["percent_text_enabled"] = true,
      ["big_actorname_text_size"] = 8,
      ["percent_text_ooc"] = true,
      ["level_text_alpha"] = 0.29999998211861,
      ["spellpercent_text_enabled"] = true,
      ["percent_text_font"] = "Cronix-Bold",
      ["spellname_text_color"] = {
        0.95294117647059, -- [1]
        [3] = 0.9921568627451,
      },
      ["big_actorname_text_font"] = "Cronix-Bold",
      ["power_percent_text_font"] = "Accidental Presidency",
      ["spellname_text_shadow_color"] = {
        nil, -- [1]
        nil, -- [2]
        nil, -- [3]
        0, -- [4]
      },
      ["spellname_text_size"] = 7,
      ["health"] = {
        120, -- [1]
      },
      ["percent_show_health"] = true,
      ["actorname_text_anchor"] = {
        ["y"] = -0.5,
        ["side"] = 1,
      },
      ["percent_text_size"] = 7,
      ["health_incombat"] = {
        nil, -- [1]
        12, -- [2]
      },
    },
    ["enemynpc"] = {
      ["big_actorname_text_size"] = 8,
      ["spellpercent_text_font"] = "ViklunD's SexFont",
      ["level_text_size"] = 7,
      ["cast"] = {
        120, -- [1]
        8, -- [2]
      },
      ["percent_text_shadow_color"] = {
        nil, -- [1]
        nil, -- [2]
        nil, -- [3]
        0, -- [4]
      },
      ["spellpercent_text_anchor"] = {
        ["y"] = -0.80000305175781,
        ["x"] = 3.8999938964844,
        ["side"] = 5,
      },
      ["level_text_font"] = "Cronix-Bold",
      ["spellname_text_color"] = {
        0.95294117647059, -- [1]
        [3] = 0.9921568627451,
      },
      ["actorname_text_outline"] = "OUTLINE",
      ["actorname_text_spacing"] = 6,
      ["quest_color_enemy"] = {
        0.28627452254295, -- [1]
        1, -- [2]
        0.094117656350136, -- [3]
      },
      ["big_actortitle_text_font"] = "Cronix-Bold",
      ["spellpercent_text_size"] = 7,
      ["level_text_anchor"] = {
        ["y"] = 100,
        ["x"] = 1,
        ["side"] = 5,
      },
      ["cast_incombat"] = {
        nil, -- [1]
        8, -- [2]
      },
      ["actorname_text_shadow_color"] = {
        nil, -- [1]
        nil, -- [2]
        nil, -- [3]
        0, -- [4]
      },
      ["spellname_text_anchor"] = {
        ["y"] = 0.099998474121094,
        ["x"] = -0.80000305175781,
        ["side"] = 3,
      },
      ["percent_text_anchor"] = {
        ["side"] = 11,
      },
      ["spellpercent_text_shadow_color"] = {
        nil, -- [1]
        nil, -- [2]
        nil, -- [3]
        0, -- [4]
      },
      ["quest_color_neutral"] = {
        0.28627452254295, -- [1]
        1, -- [2]
        0.094117656350136, -- [3]
      },
      ["actorname_text_size"] = 7,
      ["big_actorname_text_font"] = "Cronix-Bold",
      ["big_actortitle_text_size"] = 8,
      ["level_text_alpha"] = 0.29999998211861,
      ["percent_text_size"] = 7,
      ["percent_text_font"] = "Cronix-Bold",
      ["actorname_text_font"] = "Cronix-Bold",
      ["health_incombat"] = {
        nil, -- [1]
        12, -- [2]
      },
      ["spellname_text_shadow_color"] = {
        nil, -- [1]
        nil, -- [2]
        nil, -- [3]
        0, -- [4]
      },
      ["spellname_text_size"] = 7,
      ["health"] = {
        120, -- [1]
      },
      ["power_percent_text_font"] = "Accidental Presidency",
      ["actorname_text_anchor"] = {
        ["y"] = -0.5,
        ["side"] = 1,
      },
      ["spellname_text_font"] = "Cronix-Bold",
      ["level_text_enabled"] = false,
    },
    ["global_health_width"] = 120,
    ["enemyplayer"] = {
      ["spellpercent_text_font"] = "ViklunD's SexFont",
      ["level_text_size"] = 7,
      ["cast"] = {
        120, -- [1]
        8, -- [2]
      },
      ["percent_text_shadow_color"] = {
        nil, -- [1]
        nil, -- [2]
        nil, -- [3]
        0, -- [4]
      },
      ["spellpercent_text_anchor"] = {
        ["y"] = -0.8000030517578125,
        ["x"] = 3.899993896484375,
        ["side"] = 5,
      },
      ["spellname_text_outline"] = "OUTLINE",
      ["level_text_font"] = "Cronix-Bold",
      ["spellname_text_color"] = {
        0.95294117647059, -- [1]
        [3] = 0.9921568627451,
      },
      ["all_names"] = true,
      ["actorname_text_outline"] = "OUTLINE",
      ["actorname_text_spacing"] = 6,
      ["quest_color_enemy"] = {
        0.63921570777893, -- [1]
        1, -- [2]
        0.31764706969261, -- [3]
        1, -- [4]
      },
      ["big_actortitle_text_font"] = "Cronix",
      ["spellpercent_text_size"] = 7,
      ["level_text_anchor"] = {
        ["y"] = 100,
        ["x"] = 1,
        ["side"] = 5,
      },
      ["cast_incombat"] = {
        nil, -- [1]
        8, -- [2]
      },
      ["actorname_text_shadow_color"] = {
        nil, -- [1]
        nil, -- [2]
        nil, -- [3]
        0, -- [4]
      },
      ["spellname_text_anchor"] = {
        ["y"] = 0.09999847412109375,
        ["x"] = -0.8000030517578125,
        ["side"] = 3,
      },
      ["percent_text_anchor"] = {
        ["side"] = 11,
      },
      ["spellname_text_font"] = "Cronix-Bold",
      ["quest_color_neutral"] = {
        0.63921570777893, -- [1]
        1, -- [2]
        0.31764706969261, -- [3]
        1, -- [4]
      },
      ["actorname_text_size"] = 7,
      ["big_actortitle_text_size"] = 8,
      ["big_actorname_text_font"] = "Cronix",
      ["big_actorname_text_size"] = 8,
      ["actorname_text_anchor"] = {
        ["y"] = -0.5,
        ["side"] = 1,
      },
      ["percent_text_size"] = 7,
      ["percent_text_font"] = "Cronix-Bold",
      ["quest_enabled"] = true,
      ["actorname_text_font"] = "Cronix-Bold",
      ["power_percent_text_font"] = "Accidental Presidency",
      ["quest_color_enabled"] = true,
      ["spellname_text_size"] = 7,
      ["health"] = {
        120, -- [1]
      },
      ["level_text_alpha"] = 0.29999998211861,
      ["spellname_text_shadow_color"] = {
        nil, -- [1]
        nil, -- [2]
        nil, -- [3]
        0, -- [4]
      },
      ["health_incombat"] = {
        nil, -- [1]
        12, -- [2]
      },
      ["spellpercent_text_shadow_color"] = {
        nil, -- [1]
        nil, -- [2]
        nil, -- [3]
        0, -- [4]
      },
      ["level_text_enabled"] = false,
    },
    ["global_health_height"] = 10,
  },
  ["aura_y_offset"] = 8,
  ["use_ui_parent"] = true,
  ["indicator_elite"] = false,
  ["indicator_spec"] = false,
  ["border_thickness"] = 0.4999999701976776,
  ["plater_resources_grow_direction"] = "center",
  ["resources_settings"] = {
    ["chr"] = {
      ["Player-3691-09E75064"] = "Essence",
      ["Player-3691-06C34E69"] = "Runes",
      ["Player-3725-0C1533F1"] = "ComboPoints",
      ["Player-3725-0C16E871"] = "HolyPower",
      ["Player-3725-0C1632F3"] = "HolyPower",
      ["Player-4184-003D46E0"] = "Chi",
      ["Player-3725-0AA8E1EF"] = "Runes",
      ["Player-3725-0A9FE377"] = "Chi",
    },
  },
  ["indicator_scale"] = 0.99999994039536,
  ["cast_statusbar_spark_offset"] = -13,
  ["npc_colors"] = {
    [190404] = {
      true, -- [1]
      false, -- [2]
      "aqua", -- [3]
    },
    [196798] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [186696] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [194241] = {
      true, -- [1]
      false, -- [2]
      "mediumslateblue", -- [3]
    },
    [134012] = {
      true, -- [1]
      false, -- [2]
      "lightsalmon", -- [3]
    },
    [190405] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [196671] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [180431] = {
      true, -- [1]
      false, -- [2]
      "deepskyblue", -- [3]
    },
    [115407] = {
      true, -- [1]
      false, -- [2]
      "blue", -- [3]
    },
    [150253] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [184140] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [168156] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [184908] = {
      true, -- [1]
      false, -- [2]
      "magenta", -- [3]
    },
    [173016] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [129602] = {
      true, -- [1]
      false, -- [2]
      "aqua", -- [3]
    },
    [180433] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [200126] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [120651] = {
      true, -- [1]
      false, -- [2]
      "darkorange", -- [3]
    },
    [197697] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [131586] = {
      true, -- [1]
      false, -- [2]
      "peru", -- [3]
    },
    [184910] = {
      true, -- [1]
      false, -- [2]
      "palegreen", -- [3]
    },
    [164578] = {
      true, -- [1]
      false, -- [2]
      "blue", -- [3]
    },
    [135167] = {
      true, -- [1]
      false, -- [2]
      "peru", -- [3]
    },
    [201790] = {
      true, -- [1]
      false, -- [2]
      "mediumslateblue", -- [3]
    },
    [131587] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [184911] = {
      true, -- [1]
      false, -- [2]
      "darksalmon", -- [3]
    },
    [126918] = {
      true, -- [1]
      false, -- [2]
      "orchid", -- [3]
    },
    [196548] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [130435] = {
      false, -- [1]
      false, -- [2]
      "white", -- [3]
    },
    [186191] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [135169] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [161895] = {
      true, -- [1]
      false, -- [2]
      "magenta", -- [3]
    },
    [185680] = {
      true, -- [1]
      false, -- [2]
      "magenta", -- [3]
    },
    [83761] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [184018] = {
      true, -- [1]
      false, -- [2]
      "mediumslateblue", -- [3]
    },
    [126919] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [178392] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [200131] = {
      true, -- [1]
      false, -- [2]
      "mediumslateblue", -- [3]
    },
    [200387] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [213942] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [199748] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [165222] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [184020] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [199749] = {
      true, -- [1]
      false, -- [2]
      "aqua", -- [3]
    },
    [185683] = {
      true, -- [1]
      false, -- [2]
      "palegreen", -- [3]
    },
    [168420] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [165479] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [170850] = {
      true, -- [1]
      false, -- [2]
      "orchid", -- [3]
    },
    [134150] = {
      true, -- [1]
      false, -- [2]
      "navajowhite", -- [3]
    },
    [174175] = {
      true, -- [1]
      false, -- [2]
      "orchid", -- [3]
    },
    [96934] = {
      true, -- [1]
      false, -- [2]
      "orchid", -- [3]
    },
    [83763] = {
      true, -- [1]
      false, -- [2]
      "deepskyblue", -- [3]
    },
    [184022] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [189265] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [75899] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [185685] = {
      true, -- [1]
      false, -- [2]
      "darksalmon", -- [3]
    },
    [196043] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [184023] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [189266] = {
      true, -- [1]
      false, -- [2]
      "aqua", -- [3]
    },
    [178141] = {
      true, -- [1]
      false, -- [2]
      "blue", -- [3]
    },
    [196044] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [190034] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [160495] = {
      true, -- [1]
      false, -- [2]
      "magenta", -- [3]
    },
    [188244] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [178142] = {
      true, -- [1]
      false, -- [2]
      "deepskyblue", -- [3]
    },
    [98406] = {
      true, -- [1]
      false, -- [2]
      "orchid", -- [3]
    },
    [137478] = {
      true, -- [1]
      false, -- [2]
      "gold", -- [3]
    },
    [194894] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [200137] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [165483] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [135049] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [194895] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [83765] = {
      true, -- [1]
      false, -- [2]
      "aqua", -- [3]
    },
    [164461] = {
      true, -- [1]
      false, -- [2]
      "blue", -- [3]
    },
    [168681] = {
      true, -- [1]
      false, -- [2]
      "mediumslateblue", -- [3]
    },
    [128969] = {
      true, -- [1]
      false, -- [2]
      "goldenrod", -- [3]
    },
    [99366] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [101476] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [194896] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [177889] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [187224] = {
      true, -- [1]
      false, -- [2]
      "deepskyblue", -- [3]
    },
    [134284] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [194897] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [164463] = {
      true, -- [1]
      false, -- [2]
      "deepskyblue", -- [3]
    },
    [114584] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [98280] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [134157] = {
      true, -- [1]
      false, -- [2]
      "peru", -- [3]
    },
    [75966] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [194898] = {
      true, -- [1]
      false, -- [2]
      "orchid", -- [3]
    },
    [167533] = {
      true, -- [1]
      false, -- [2]
      "orchid", -- [3]
    },
    [177891] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [136076] = {
      true, -- [1]
      false, -- [2]
      "lightcoral", -- [3]
    },
    [134158] = {
      true, -- [1]
      false, -- [2]
      "navajowhite", -- [3]
    },
    [172265] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [150143] = {
      true, -- [1]
      false, -- [2]
      "blue", -- [3]
    },
    [177892] = {
      true, -- [1]
      false, -- [2]
      "blue", -- [3]
    },
    [165872] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [137484] = {
      true, -- [1]
      false, -- [2]
      "gold", -- [3]
    },
    [129227] = {
      false, -- [1]
      false, -- [2]
      "maroon", -- [3]
    },
    [131858] = {
      true, -- [1]
      false, -- [2]
      "dodgerblue", -- [3]
    },
    [129547] = {
      true, -- [1]
      false, -- [2]
      "deepskyblue", -- [3]
    },
    [45912] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [127757] = {
      true, -- [1]
      false, -- [2]
      "lightcoral", -- [3]
    },
    [167536] = {
      true, -- [1]
      false, -- [2]
      "orchid", -- [3]
    },
    [89011] = {
      true, -- [1]
      false, -- [2]
      "aqua", -- [3]
    },
    [188252] = {
      true, -- [1]
      false, -- [2]
      "mediumslateblue", -- [3]
    },
    [190426] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [189531] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [137486] = {
      true, -- [1]
      false, -- [2]
      "gold", -- [3]
    },
    [150146] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [137103] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [129548] = {
      true, -- [1]
      false, -- [2]
      "orchid", -- [3]
    },
    [101991] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [162039] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [115418] = {
      true, -- [1]
      false, -- [2]
      "orchid", -- [3]
    },
    [97068] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [75713] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [186208] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [138255] = {
      true, -- [1]
      false, -- [2]
      "maroon", -- [3]
    },
    [162040] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [195927] = {
      true, -- [1]
      false, -- [2]
      "dodgerblue", -- [3]
    },
    [81212] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [181861] = {
      true, -- [1]
      false, -- [2]
      "aqua", -- [3]
    },
    [150276] = {
      true, -- [1]
      false, -- [2]
      "orchid", -- [3]
    },
    [52019] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [83578] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [115419] = {
      true, -- [1]
      false, -- [2]
      "mediumslateblue", -- [3]
    },
    [97197] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [126928] = {
      false, -- [1]
      false, -- [2]
      "navajowhite", -- [3]
    },
    [203857] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [197847] = {
      true, -- [1]
      false, -- [2]
      "orchid", -- [3]
    },
    [195929] = {
      true, -- [1]
      false, -- [2]
      "dodgerblue", -- [3]
    },
    [131864] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [186339] = {
      true, -- [1]
      false, -- [2]
      "aqua", -- [3]
    },
    [75459] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [195930] = {
      true, -- [1]
      false, -- [2]
      "dodgerblue", -- [3]
    },
    [170483] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [104295] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [193373] = {
      true, -- [1]
      false, -- [2]
      "blue", -- [3]
    },
    [168310] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [133912] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [136214] = {
      true, -- [1]
      false, -- [2]
      "plum", -- [3]
    },
    [136470] = {
      true, -- [1]
      false, -- [2]
      "honeydew", -- [3]
    },
    [90997] = {
      true, -- [1]
      false, -- [2]
      "aqua", -- [3]
    },
    [197595] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [155908] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [179821] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [83389] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [81407] = {
      true, -- [1]
      false, -- [2]
      "orchid", -- [3]
    },
    [173044] = {
      true, -- [1]
      false, -- [2]
      "deepskyblue", -- [3]
    },
    [154758] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [193760] = {
      true, -- [1]
      false, -- [2]
      "mediumslateblue", -- [3]
    },
    [118491] = {
      true, -- [1]
      false, -- [2]
      "deepskyblue", -- [3]
    },
    [115486] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [90998] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [157572] = {
      true, -- [1]
      false, -- [2]
      "deepskyblue", -- [3]
    },
    [164861] = {
      true, -- [1]
      false, -- [2]
      "blue", -- [3]
    },
    [168058] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [178008] = {
      true, -- [1]
      false, -- [2]
      "yellow", -- [3]
    },
    [105704] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [166396] = {
      true, -- [1]
      false, -- [2]
      "blue", -- [3]
    },
    [127315] = {
      true, -- [1]
      false, -- [2]
      "plum", -- [3]
    },
    [83390] = {
      true, -- [1]
      false, -- [2]
      "deepskyblue", -- [3]
    },
    [187240] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [132126] = {
      true, -- [1]
      false, -- [2]
      "honeydew", -- [3]
    },
    [45915] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [202969] = {
      true, -- [1]
      false, -- [2]
      "magenta", -- [3]
    },
    [171384] = {
      true, -- [1]
      false, -- [2]
      "blue", -- [3]
    },
    [168443] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [77700] = {
      true, -- [1]
      false, -- [2]
      "deepskyblue", -- [3]
    },
    [80816] = {
      true, -- [1]
      false, -- [2]
      "deepskyblue", -- [3]
    },
    [162689] = {
      true, -- [1]
      false, -- [2]
      "orchid", -- [3]
    },
    [196576] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [180336] = {
      true, -- [1]
      false, -- [2]
      "deepskyblue", -- [3]
    },
    [98792] = {
      true, -- [1]
      false, -- [2]
      "aqua", -- [3]
    },
    [105705] = {
      true, -- [1]
      false, -- [2]
      "magenta", -- [3]
    },
    [170490] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [59598] = {
      false, -- [1]
      false, -- [2]
      "dimgray", -- [3]
    },
    [175861] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [83892] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [134174] = {
      true, -- [1]
      false, -- [2]
      "honeydew", -- [3]
    },
    [162047] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [180429] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [129600] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [115488] = {
      true, -- [1]
      false, -- [2]
      "blue", -- [3]
    },
    [102253] = {
      true, -- [1]
      false, -- [2]
      "orchid", -- [3]
    },
    [97202] = {
      true, -- [1]
      false, -- [2]
      "aqua", -- [3]
    },
    [162691] = {
      true, -- [1]
      false, -- [2]
      "mediumslateblue", -- [3]
    },
    [81985] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [122969] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [197857] = {
      true, -- [1]
      false, -- [2]
      "deepskyblue", -- [3]
    },
    [168318] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [168446] = {
      true, -- [1]
      false, -- [2]
      "mediumslateblue", -- [3]
    },
    [163459] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [83392] = {
      true, -- [1]
      false, -- [2]
      "mediumslateblue", -- [3]
    },
    [162692] = {
      true, -- [1]
      false, -- [2]
      "orchid", -- [3]
    },
    [178165] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [100527] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [114338] = {
      true, -- [1]
      false, -- [2]
      "aqua", -- [3]
    },
    [75451] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [185032] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [197219] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [98275] = {
      true, -- [1]
      false, -- [2]
      "aqua", -- [3]
    },
    [165762] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [205384] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [199233] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [183497] = {
      true, -- [1]
      false, -- [2]
      "blue", -- [3]
    },
    [131492] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [76104] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [81283] = {
      true, -- [1]
      false, -- [2]
      "aqua", -- [3]
    },
    [165763] = {
      true, -- [1]
      false, -- [2]
      "deepskyblue", -- [3]
    },
    [86526] = {
      true, -- [1]
      false, -- [2]
      "blue", -- [3]
    },
    [134024] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [135329] = {
      true, -- [1]
      false, -- [2]
      "plum", -- [3]
    },
    [81603] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [166275] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [196198] = {
      true, -- [1]
      false, -- [2]
      "blue", -- [3]
    },
    [91002] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [174843] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [165764] = {
      true, -- [1]
      false, -- [2]
      "mediumslateblue", -- [3]
    },
    [208438] = {
      true, -- [1]
      false, -- [2]
      "aqua", -- [3]
    },
    [187503] = {
      true, -- [1]
      false, -- [2]
      "mediumslateblue", -- [3]
    },
    [114266] = {
      true, -- [1]
      false, -- [2]
      "deepskyblue", -- [3]
    },
    [166276] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [84990] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [168578] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [150292] = {
      true, -- [1]
      false, -- [2]
      "blue", -- [3]
    },
    [65317] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [199124] = {
      true, -- [1]
      false, -- [2]
      "deepskyblue", -- [3]
    },
    [45917] = {
      true, -- [1]
      false, -- [2]
      "orchid", -- [3]
    },
    [162057] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [205151] = {
      true, -- [1]
      false, -- [2]
      "aqua", -- [3]
    },
    [191469] = {
      false, -- [1]
      false, -- [2]
      "aqua", -- [3]
    },
    [150165] = {
      true, -- [1]
      false, -- [2]
      "deepskyblue", -- [3]
    },
    [122972] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [186226] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [125977] = {
      true, -- [1]
      false, -- [2]
      "plum", -- [3]
    },
    [196712] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [168425] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [205152] = {
      true, -- [1]
      false, -- [2]
      "aqua", -- [3]
    },
    [180070] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [205408] = {
      true, -- [1]
      false, -- [2]
      "orchid", -- [3]
    },
    [178171] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [170882] = {
      true, -- [1]
      false, -- [2]
      "magenta", -- [3]
    },
    [99891] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [139425] = {
      false, -- [1]
      false, -- [2]
      "honeydew", -- [3]
    },
    [180473] = {
      true, -- [1]
      false, -- [2]
      "blue", -- [3]
    },
    [186739] = {
      true, -- [1]
      false, -- [2]
      "mediumslateblue", -- [3]
    },
    [169429] = {
      true, -- [1]
      false, -- [2]
      "gold", -- [3]
    },
    [196202] = {
      true, -- [1]
      false, -- [2]
      "blue", -- [3]
    },
    [150295] = {
      true, -- [1]
      false, -- [2]
      "mediumslateblue", -- [3]
    },
    [199368] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [164873] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [122973] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [100531] = {
      true, -- [1]
      false, -- [2]
      "aqua", -- [3]
    },
    [183671] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [174197] = {
      true, -- [1]
      false, -- [2]
      "magenta", -- [3]
    },
    [196203] = {
      true, -- [1]
      false, -- [2]
      "deepskyblue", -- [3]
    },
    [129601] = {
      true, -- [1]
      false, -- [2]
      "orchid", -- [3]
    },
    [186229] = {
      true, -- [1]
      false, -- [2]
      "aqua", -- [3]
    },
    [129559] = {
      true, -- [1]
      false, -- [2]
      "blue", -- [3]
    },
    [58319] = {
      false, -- [1]
      false, -- [2]
      "dimgray", -- [3]
    },
    [192464] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [186741] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [162317] = {
      true, -- [1]
      false, -- [2]
      "orchid", -- [3]
    },
    [150169] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [183033] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [133007] = {
      true, -- [1]
      false, -- [2]
      "aqua", -- [3]
    },
    [114790] = {
      true, -- [1]
      false, -- [2]
      "mediumslateblue", -- [3]
    },
    [207969] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [100532] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [136353] = {
      true, -- [1]
      false, -- [2]
      "royalblue", -- [3]
    },
    [182778] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [163458] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [196045] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [174210] = {
      true, -- [1]
      false, -- [2]
      "magenta", -- [3]
    },
    [114783] = {
      true, -- [1]
      false, -- [2]
      "deepskyblue", -- [3]
    },
    [187510] = {
      true, -- [1]
      false, -- [2]
      "orchid", -- [3]
    },
    [137511] = {
      true, -- [1]
      false, -- [2]
      "navajowhite", -- [3]
    },
    [176598] = {
      true, -- [1]
      false, -- [2]
      "blue", -- [3]
    },
    [180323] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [91006] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [187969] = {
      true, -- [1]
      false, -- [2]
      "deepskyblue", -- [3]
    },
    [191847] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [199659] = {
      true, -- [1]
      false, -- [2]
      "magenta", -- [3]
    },
    [173189] = {
      true, -- [1]
      false, -- [2]
      "deepskyblue", -- [3]
    },
    [156157] = {
      true, -- [1]
      false, -- [2]
      "blue", -- [3]
    },
    [205158] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [95674] = {
      true, -- [1]
      false, -- [2]
      "mediumslateblue", -- [3]
    },
    [129369] = {
      true, -- [1]
      false, -- [2]
      "lightsalmon", -- [3]
    },
    [97720] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [195928] = {
      true, -- [1]
      false, -- [2]
      "dodgerblue", -- [3]
    },
    [130436] = {
      false, -- [1]
      false, -- [2]
      "aqua", -- [3]
    },
    [43873] = {
      true, -- [1]
      false, -- [2]
      "aqua", -- [3]
    },
    [189247] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [187768] = {
      true, -- [1]
      false, -- [2]
      "deepskyblue", -- [3]
    },
    [164567] = {
      true, -- [1]
      false, -- [2]
      "deepskyblue", -- [3]
    },
    [171656] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [104278] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [169426] = {
      true, -- [1]
      false, -- [2]
      "gold", -- [3]
    },
    [138281] = {
      true, -- [1]
      false, -- [2]
      "aqua", -- [3]
    },
    [114792] = {
      true, -- [1]
      false, -- [2]
      "aqua", -- [3]
    },
    [153882] = {
      true, -- [1]
      false, -- [2]
      "deepskyblue", -- [3]
    },
    [150142] = {
      true, -- [1]
      false, -- [2]
      "deepskyblue", -- [3]
    },
    [187897] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [129370] = {
      true, -- [1]
      false, -- [2]
      "gold", -- [3]
    },
    [151325] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [194745] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [187602] = {
      true, -- [1]
      false, -- [2]
      "dodgerblue", -- [3]
    },
    [150297] = {
      true, -- [1]
      false, -- [2]
      "deepskyblue", -- [3]
    },
    [184131] = {
      true, -- [1]
      false, -- [2]
      "deepskyblue", -- [3]
    },
    [189816] = {
      true, -- [1]
      false, -- [2]
      "deepskyblue", -- [3]
    },
    [168658] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [188026] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [168717] = {
      true, -- [1]
      false, -- [2]
      "deepskyblue", -- [3]
    },
    [144293] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [115019] = {
      true, -- [1]
      false, -- [2]
      "deepskyblue", -- [3]
    },
    [183423] = {
      true, -- [1]
      false, -- [2]
      "deepskyblue", -- [3]
    },
    [137516] = {
      true, -- [1]
      false, -- [2]
      "lightsalmon", -- [3]
    },
    [187771] = {
      true, -- [1]
      false, -- [2]
      "blue", -- [3]
    },
    [206140] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [165010] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [168718] = {
      true, -- [1]
      false, -- [2]
      "blue", -- [3]
    },
    [144294] = {
      true, -- [1]
      false, -- [2]
      "deepskyblue", -- [3]
    },
    [184319] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [183424] = {
      true, -- [1]
      false, -- [2]
      "aqua", -- [3]
    },
    [137517] = {
      true, -- [1]
      false, -- [2]
      "peru", -- [3]
    },
    [185537] = {
      true, -- [1]
      false, -- [2]
      "blue", -- [3]
    },
    [45919] = {
      true, -- [1]
      false, -- [2]
      "aqua", -- [3]
    },
    [129366] = {
      true, -- [1]
      false, -- [2]
      "goldenrod", -- [3]
    },
    [192955] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [144295] = {
      true, -- [1]
      false, -- [2]
      "aqua", -- [3]
    },
    [192481] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [183425] = {
      true, -- [1]
      false, -- [2]
      "blue", -- [3]
    },
    [180864] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [105715] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [129788] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [186220] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [128967] = {
      true, -- [1]
      false, -- [2]
      "palegreen", -- [3]
    },
    [144296] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [205804] = {
      true, -- [1]
      false, -- [2]
      "orchid", -- [3]
    },
    [179334] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [168572] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [132532] = {
      true, -- [1]
      false, -- [2]
      "palegreen", -- [3]
    },
    [84520] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [139949] = {
      true, -- [1]
      false, -- [2]
      "honeydew", -- [3]
    },
    [197985] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [130012] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [163862] = {
      true, -- [1]
      false, -- [2]
      "blue", -- [3]
    },
    [134701] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [191739] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [168594] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [178630] = {
      true, -- [1]
      false, -- [2]
      "deepskyblue", -- [3]
    },
    [179847] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [171341] = {
      true, -- [1]
      false, -- [2]
      "deepskyblue", -- [3]
    },
    [144298] = {
      true, -- [1]
      false, -- [2]
      "blue", -- [3]
    },
    [114334] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [137521] = {
      true, -- [1]
      false, -- [2]
      "cornflowerblue", -- [3]
    },
    [176395] = {
      true, -- [1]
      false, -- [2]
      "orchid", -- [3]
    },
    [176523] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [104246] = {
      true, -- [1]
      false, -- [2]
      "blue", -- [3]
    },
    [189901] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [190206] = {
      true, -- [1]
      false, -- [2]
      "blue", -- [3]
    },
    [180104] = {
      true, -- [1]
      false, -- [2]
      "deepskyblue", -- [3]
    },
    [167956] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [114796] = {
      true, -- [1]
      false, -- [2]
      "blue", -- [3]
    },
    [184580] = {
      true, -- [1]
      false, -- [2]
      "blue", -- [3]
    },
    [75652] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [96574] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [191206] = {
      true, -- [1]
      false, -- [2]
      "deepskyblue", -- [3]
    },
    [92610] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [169875] = {
      true, -- [1]
      false, -- [2]
      "magenta", -- [3]
    },
    [165911] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [190207] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [206064] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [129758] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [104247] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [130909] = {
      true, -- [1]
      false, -- [2]
      "aqua", -- [3]
    },
    [186116] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [191230] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [133432] = {
      true, -- [1]
      false, -- [2]
      "gold", -- [3]
    },
    [187523] = {
      true, -- [1]
      false, -- [2]
      "mediumslateblue", -- [3]
    },
    [184582] = {
      true, -- [1]
      false, -- [2]
      "deepskyblue", -- [3]
    },
    [154020] = {
      true, -- [1]
      false, -- [2]
      "deepskyblue", -- [3]
    },
    [168153] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [164506] = {
      true, -- [1]
      false, -- [2]
      "blue", -- [3]
    },
    [191232] = {
      true, -- [1]
      false, -- [2]
      "blue", -- [3]
    },
    [98813] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [165913] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [45922] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [192767] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [114526] = {
      true, -- [1]
      false, -- [2]
      "aqua", -- [3]
    },
    [190174] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [114542] = {
      true, -- [1]
      false, -- [2]
      "blue", -- [3]
    },
    [126848] = {
      true, -- [1]
      false, -- [2]
      "deepskyblue", -- [3]
    },
    [186246] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [115757] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [155812] = {
      true, -- [1]
      false, -- [2]
      "blue", -- [3]
    },
    [129367] = {
      true, -- [1]
      false, -- [2]
      "honeydew", -- [3]
    },
    [184300] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [178139] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [157017] = {
      true, -- [1]
      false, -- [2]
      "blue", -- [3]
    },
    [92612] = {
      true, -- [1]
      false, -- [2]
      "aqua", -- [3]
    },
    [130011] = {
      true, -- [1]
      false, -- [2]
      "aqua", -- [3]
    },
    [165529] = {
      true, -- [1]
      false, -- [2]
      "magenta", -- [3]
    },
    [177808] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [199547] = {
      true, -- [1]
      false, -- [2]
      "blueviolet", -- [3]
    },
    [166299] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [134331] = {
      true, -- [1]
      false, -- [2]
      "gold", -- [3]
    },
    [56792] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [133436] = {
      true, -- [1]
      false, -- [2]
      "gold", -- [3]
    },
    [190340] = {
      true, -- [1]
      false, -- [2]
      "aqua", -- [3]
    },
    [136249] = {
      true, -- [1]
      false, -- [2]
      "plum", -- [3]
    },
    [204918] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [194816] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [150250] = {
      true, -- [1]
      false, -- [2]
      "deepskyblue", -- [3]
    },
    [134418] = {
      true, -- [1]
      false, -- [2]
      "dodgerblue", -- [3]
    },
    [164510] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [171799] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [180495] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [167963] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [199549] = {
      true, -- [1]
      false, -- [2]
      "orchid", -- [3]
    },
    [206070] = {
      true, -- [1]
      false, -- [2]
      "mediumslateblue", -- [3]
    },
    [199037] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [167964] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [114544] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [186122] = {
      true, -- [1]
      false, -- [2]
      "blue", -- [3]
    },
    [190342] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [101437] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [122984] = {
      true, -- [1]
      false, -- [2]
      "peru", -- [3]
    },
    [41096] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [166302] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [163086] = {
      true, -- [1]
      false, -- [2]
      "blue", -- [3]
    },
    [81297] = {
      true, -- [1]
      false, -- [2]
      "orchid", -- [3]
    },
    [186107] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [133430] = {
      true, -- [1]
      false, -- [2]
      "cornflowerblue", -- [3]
    },
    [167965] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [189555] = {
      true, -- [1]
      false, -- [2]
      "blue", -- [3]
    },
    [195842] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [180091] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [104251] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [45572] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [186124] = {
      true, -- [1]
      false, -- [2]
      "deepskyblue", -- [3]
    },
    [196482] = {
      true, -- [1]
      false, -- [2]
      "mediumslateblue", -- [3]
    },
    [101438] = {
      true, -- [1]
      false, -- [2]
      "blue", -- [3]
    },
    [135204] = {
      true, -- [1]
      false, -- [2]
      "honeydew", -- [3]
    },
    [165137] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [114632] = {
      true, -- [1]
      false, -- [2]
      "deepskyblue", -- [3]
    },
    [180474] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [129699] = {
      true, -- [1]
      false, -- [2]
      "magenta", -- [3]
    },
    [186125] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [190345] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [184335] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [45924] = {
      true, -- [1]
      false, -- [2]
      "orchid", -- [3]
    },
    [189706] = {
      true, -- [1]
      false, -- [2]
      "yellow", -- [3]
    },
    [195696] = {
      true, -- [1]
      false, -- [2]
      "magenta", -- [3]
    },
    [165410] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [163620] = {
      true, -- [1]
      false, -- [2]
      "blue", -- [3]
    },
    [97219] = {
      true, -- [1]
      false, -- [2]
      "mediumslateblue", -- [3]
    },
    [205691] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [98370] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [45935] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [193799] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [163621] = {
      true, -- [1]
      false, -- [2]
      "orchid", -- [3]
    },
    [179733] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [141285] = {
      true, -- [1]
      false, -- [2]
      "lightgreen", -- [3]
    },
    [171805] = {
      true, -- [1]
      false, -- [2]
      "blue", -- [3]
    },
    [187192] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [168992] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [134338] = {
      true, -- [1]
      false, -- [2]
      "navajowhite", -- [3]
    },
    [190348] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [45477] = {
      true, -- [1]
      false, -- [2]
      "aqua", -- [3]
    },
    [196102] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [177816] = {
      true, -- [1]
      false, -- [2]
      "deepskyblue", -- [3]
    },
    [98243] = {
      true, -- [1]
      false, -- [2]
      "aqua", -- [3]
    },
    [188302] = {
      true, -- [1]
      false, -- [2]
      "yellow", -- [3]
    },
    [83026] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [114803] = {
      true, -- [1]
      false, -- [2]
      "deepskyblue", -- [3]
    },
    [206074] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [175576] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [81236] = {
      true, -- [1]
      false, -- [2]
      "deepskyblue", -- [3]
    },
    [130404] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [180335] = {
      true, -- [1]
      false, -- [2]
      "deepskyblue", -- [3]
    },
    [175992] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [135235] = {
      true, -- [1]
      false, -- [2]
      "goldenrod", -- [3]
    },
    [82579] = {
      true, -- [1]
      false, -- [2]
      "deepskyblue", -- [3]
    },
    [114804] = {
      true, -- [1]
      false, -- [2]
      "blue", -- [3]
    },
    [141284] = {
      true, -- [1]
      false, -- [2]
      "gold", -- [3]
    },
    [165414] = {
      true, -- [1]
      false, -- [2]
      "magenta", -- [3]
    },
    [59544] = {
      true, -- [1]
      false, -- [2]
      "aqua", -- [3]
    },
    [193291] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [151476] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [164557] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [155824] = {
      true, -- [1]
      false, -- [2]
      "blue", -- [3]
    },
    [156245] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [175517] = {
      true, -- [1]
      false, -- [2]
      "blue", -- [3]
    },
    [167967] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [187154] = {
      true, -- [1]
      false, -- [2]
      "deepskyblue", -- [3]
    },
    [194315] = {
      true, -- [1]
      false, -- [2]
      "dodgerblue", -- [3]
    },
    [185528] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [184301] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [135365] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [141283] = {
      true, -- [1]
      false, -- [2]
      "navajowhite", -- [3]
    },
    [168357] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [193293] = {
      true, -- [1]
      false, -- [2]
      "aqua", -- [3]
    },
    [136006] = {
      false, -- [1]
      false, -- [2]
      "blue", -- [3]
    },
    [136005] = {
      false, -- [1]
      false, -- [2]
      "blue", -- [3]
    },
    [137830] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [163882] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [59553] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [195851] = {
      true, -- [1]
      false, -- [2]
      "blue", -- [3]
    },
    [134599] = {
      true, -- [1]
      false, -- [2]
      "gold", -- [3]
    },
    [201222] = {
      true, -- [1]
      false, -- [2]
      "mediumslateblue", -- [3]
    },
    [173729] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [194317] = {
      true, -- [1]
      false, -- [2]
      "dodgerblue", -- [3]
    },
    [169893] = {
      true, -- [1]
      false, -- [2]
      "magenta", -- [3]
    },
    [135239] = {
      true, -- [1]
      false, -- [2]
      "paleturquoise", -- [3]
    },
    [150712] = {
      true, -- [1]
      false, -- [2]
      "aqua", -- [3]
    },
    [133482] = {
      true, -- [1]
      false, -- [2]
      "maroon", -- [3]
    },
    [134600] = {
      true, -- [1]
      false, -- [2]
      "peru", -- [3]
    },
    [201223] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [167113] = {
      true, -- [1]
      false, -- [2]
      "blue", -- [3]
    },
    [186121] = {
      true, -- [1]
      false, -- [2]
      "mediumslateblue", -- [3]
    },
    [115765] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [135240] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [200840] = {
      true, -- [1]
      false, -- [2]
      "orchid", -- [3]
    },
    [176959] = {
      true, -- [1]
      false, -- [2]
      "deepskyblue", -- [3]
    },
    [59545] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [156212] = {
      true, -- [1]
      false, -- [2]
      "deepskyblue", -- [3]
    },
    [136934] = {
      true, -- [1]
      false, -- [2]
      "navajowhite", -- [3]
    },
    [188011] = {
      true, -- [1]
      false, -- [2]
      "mediumslateblue", -- [3]
    },
    [59873] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [135241] = {
      true, -- [1]
      false, -- [2]
      "peru", -- [3]
    },
    [102019] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [187155] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [82597] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [104273] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [133835] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [199595] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [194990] = {
      true, -- [1]
      false, -- [2]
      "aqua", -- [3]
    },
    [133836] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [100485] = {
      true, -- [1]
      false, -- [2]
      "aqua", -- [3]
    },
    [192786] = {
      true, -- [1]
      false, -- [2]
      "blue", -- [3]
    },
    [183707] = {
      true, -- [1]
      false, -- [2]
      "deepskyblue", -- [3]
    },
    [187160] = {
      true, -- [1]
      false, -- [2]
      "orchid", -- [3]
    },
    [163503] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [182045] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [81432] = {
      true, -- [1]
      false, -- [2]
      "deepskyblue", -- [3]
    },
    [91001] = {
      true, -- [1]
      false, -- [2]
      "aqua", -- [3]
    },
    [155831] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [156244] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [179852] = {
      true, -- [1]
      false, -- [2]
      "blue", -- [3]
    },
    [176396] = {
      true, -- [1]
      false, -- [2]
      "mediumslateblue", -- [3]
    },
    [187033] = {
      true, -- [1]
      false, -- [2]
      "aqua", -- [3]
    },
    [168747] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [136139] = {
      true, -- [1]
      false, -- [2]
      "peru", -- [3]
    },
    [187315] = {
      true, -- [1]
      false, -- [2]
      "blue", -- [3]
    },
    [47238] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [192788] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [101637] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [131817] = {
      true, -- [1]
      false, -- [2]
      "aqua", -- [3]
    },
    [102788] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [168109] = {
      true, -- [1]
      false, -- [2]
      "deepskyblue", -- [3]
    },
    [190359] = {
      true, -- [1]
      false, -- [2]
      "blue", -- [3]
    },
    [189464] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [76446] = {
      true, -- [1]
      false, -- [2]
      "dodgerblue", -- [3]
    },
    [162099] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [155090] = {
      true, -- [1]
      false, -- [2]
      "deepskyblue", -- [3]
    },
    [192333] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [134990] = {
      true, -- [1]
      false, -- [2]
      "honeydew", -- [3]
    },
    [115640] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [138187] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [197905] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [131666] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [87252] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [189232] = {
      true, -- [1]
      false, -- [2]
      "mediumslateblue", -- [3]
    },
    [196115] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [198311] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [164707] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [134629] = {
      true, -- [1]
      false, -- [2]
      "navajowhite", -- [3]
    },
    [189466] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [45928] = {
      true, -- [1]
      false, -- [2]
      "aqua", -- [3]
    },
    [189722] = {
      true, -- [1]
      false, -- [2]
      "mediumslateblue", -- [3]
    },
    [176551] = {
      true, -- [1]
      false, -- [2]
      "deepskyblue", -- [3]
    },
    [196116] = {
      true, -- [1]
      false, -- [2]
      "orchid", -- [3]
    },
    [144071] = {
      true, -- [1]
      false, -- [2]
      "gold", -- [3]
    },
    [138061] = {
      false, -- [1]
      false, -- [2]
      "magenta", -- [3]
    },
    [190362] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [189467] = {
      true, -- [1]
      false, -- [2]
      "blue", -- [3]
    },
    [155830] = {
      true, -- [1]
      false, -- [2]
      "deepskyblue", -- [3]
    },
    [165805] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [59547] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [196117] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [197671] = {
      true, -- [1]
      false, -- [2]
      "blue", -- [3]
    },
    [167876] = {
      true, -- [1]
      false, -- [2]
      "magenta", -- [3]
    },
    [189340] = {
      true, -- [1]
      false, -- [2]
      "aqua", -- [3]
    },
    [180432] = {
      true, -- [1]
      false, -- [2]
      "blue", -- [3]
    },
    [133685] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [162103] = {
      true, -- [1]
      false, -- [2]
      "orchid", -- [3]
    },
    [193944] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [115642] = {
      true, -- [1]
      false, -- [2]
      "blue", -- [3]
    },
    [81819] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [138063] = {
      false, -- [1]
      false, -- [2]
      "blue", -- [3]
    },
    [163121] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [163894] = {
      true, -- [1]
      false, -- [2]
      "blue", -- [3]
    },
    [169905] = {
      true, -- [1]
      false, -- [2]
      "blue", -- [3]
    },
    [171184] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [163128] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [131670] = {
      true, -- [1]
      false, -- [2]
      "palegreen", -- [3]
    },
    [190381] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [138064] = {
      false, -- [1]
      false, -- [2]
      "blue", -- [3]
    },
    [162744] = {
      true, -- [1]
      false, -- [2]
      "orchid", -- [3]
    },
    [189470] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [187552] = {
      true, -- [1]
      false, -- [2]
      "orchid", -- [3]
    },
    [152898] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [200836] = {
      true, -- [1]
      false, -- [2]
      "orchid", -- [3]
    },
    [165430] = {
      true, -- [1]
      false, -- [2]
      "orchid", -- [3]
    },
    [168627] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [204560] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [94224] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [189471] = {
      true, -- [1]
      false, -- [2]
      "deepskyblue", -- [3]
    },
    [189727] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [192796] = {
      true, -- [1]
      false, -- [2]
      "dodgerblue", -- [3]
    },
    [179841] = {
      true, -- [1]
      false, -- [2]
      "deepskyblue", -- [3]
    },
    [206351] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [169924] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [45704] = {
      true, -- [1]
      false, -- [2]
      "magenta", -- [3]
    },
    [126969] = {
      true, -- [1]
      false, -- [2]
      "magenta", -- [3]
    },
    [189472] = {
      true, -- [1]
      false, -- [2]
      "deepskyblue", -- [3]
    },
    [168942] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [115388] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [131545] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [130661] = {
      true, -- [1]
      false, -- [2]
      "lightgreen", -- [3]
    },
    [199703] = {
      true, -- [1]
      false, -- [2]
      "aqua", -- [3]
    },
    [198308] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [190368] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [164921] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [80936] = {
      true, -- [1]
      false, -- [2]
      "blue", -- [3]
    },
    [175550] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [188067] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [156226] = {
      true, -- [1]
      false, -- [2]
      "deepskyblue", -- [3]
    },
    [167607] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [163891] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [168886] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [134232] = {
      true, -- [1]
      false, -- [2]
      "goldenrod", -- [3]
    },
    [45930] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [163126] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [133593] = {
      true, -- [1]
      false, -- [2]
      "honeydew", -- [3]
    },
    [186644] = {
      true, -- [1]
      false, -- [2]
      "mediumslateblue", -- [3]
    },
    [40943] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [157634] = {
      true, -- [1]
      false, -- [2]
      "blue", -- [3]
    },
    [190370] = {
      true, -- [1]
      false, -- [2]
      "deepskyblue", -- [3]
    },
    [165946] = {
      true, -- [1]
      false, -- [2]
      "orchid", -- [3]
    },
    [98706] = {
      true, -- [1]
      false, -- [2]
      "aqua", -- [3]
    },
    [192800] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [170690] = {
      true, -- [1]
      false, -- [2]
      "magenta", -- [3]
    },
    [165919] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [82590] = {
      true, -- [1]
      false, -- [2]
      "blue", -- [3]
    },
    [186151] = {
      true, -- [1]
      false, -- [2]
      "mediumslateblue", -- [3]
    },
    [190371] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [166970] = {
      true, -- [1]
      false, -- [2]
      "blue", -- [3]
    },
    [83613] = {
      true, -- [1]
      false, -- [2]
      "mediumslateblue", -- [3]
    },
    [197406] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [152009] = {
      true, -- [1]
      false, -- [2]
      "orchid", -- [3]
    },
    [131677] = {
      true, -- [1]
      false, -- [2]
      "gold", -- [3]
    },
    [152905] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [180015] = {
      true, -- [1]
      false, -- [2]
      "blue", -- [3]
    },
    [172981] = {
      true, -- [1]
      false, -- [2]
      "blue", -- [3]
    },
    [135258] = {
      false, -- [1]
      false, -- [2]
      "peru", -- [3]
    },
    [114626] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [186664] = {
      true, -- [1]
      false, -- [2]
      "deepskyblue", -- [3]
    },
    [201754] = {
      true, -- [1]
      false, -- [2]
      "aqua", -- [3]
    },
    [164414] = {
      true, -- [1]
      false, -- [2]
      "deepskyblue", -- [3]
    },
    [133852] = {
      true, -- [1]
      false, -- [2]
      "blue", -- [3]
    },
    [128434] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [190373] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [164926] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [134364] = {
      true, -- [1]
      false, -- [2]
      "honeydew", -- [3]
    },
    [163520] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [113537] = {
      true, -- [1]
      false, -- [2]
      "aqua", -- [3]
    },
    [174773] = {
      true, -- [1]
      false, -- [2]
      "magenta", -- [3]
    },
    [166589] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [84957] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [197535] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [45932] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [135474] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [190377] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [198047] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [139422] = {
      true, -- [1]
      false, -- [2]
      "gold", -- [3]
    },
    [168882] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [128435] = {
      false, -- [1]
      false, -- [2]
      "aqua", -- [3]
    },
    [194467] = {
      true, -- [1]
      false, -- [2]
      "blue", -- [3]
    },
    [189478] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [164929] = {
      true, -- [1]
      false, -- [2]
      "blue", -- [3]
    },
    [76518] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [176565] = {
      true, -- [1]
      false, -- [2]
      "deepskyblue", -- [3]
    },
    [205337] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [153292] = {
      false, -- [1]
      false, -- [2]
      "khaki", -- [3]
    },
    [101326] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [165824] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [167998] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [184581] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [59546] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [192934] = {
      true, -- [1]
      false, -- [2]
      "blue", -- [3]
    },
    [186284] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [177716] = {
      true, -- [1]
      false, -- [2]
      "deepskyblue", -- [3]
    },
    [135007] = {
      true, -- [1]
      false, -- [2]
      "gold", -- [3]
    },
    [194469] = {
      true, -- [1]
      false, -- [2]
      "blue", -- [3]
    },
    [135263] = {
      true, -- [1]
      false, -- [2]
      "maroon", -- [3]
    },
    [133345] = {
      true, -- [1]
      false, -- [2]
      "goldenrod", -- [3]
    },
    [114624] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [199325] = {
      true, -- [1]
      false, -- [2]
      "deepskyblue", -- [3]
    },
    [167612] = {
      true, -- [1]
      false, -- [2]
      "blue", -- [3]
    },
    [163524] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [189227] = {
      true, -- [1]
      false, -- [2]
      "orchid", -- [3]
    },
    [184107] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [166971] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [192680] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [195877] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [168384] = {
      true, -- [1]
      false, -- [2]
      "blue", -- [3]
    },
    [169927] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [131812] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [166969] = {
      true, -- [1]
      false, -- [2]
      "deepskyblue", -- [3]
    },
    [165556] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [130400] = {
      true, -- [1]
      false, -- [2]
      "deepskyblue", -- [3]
    },
    [187566] = {
      true, -- [1]
      false, -- [2]
      "mediumslateblue", -- [3]
    },
    [195878] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [171376] = {
      true, -- [1]
      false, -- [2]
      "blue", -- [3]
    },
    [131685] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [102287] = {
      true, -- [1]
      false, -- [2]
      "aqua", -- [3]
    },
    [114627] = {
      true, -- [1]
      false, -- [2]
      "blue", -- [3]
    },
    [154744] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [184331] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [91000] = {
      true, -- [1]
      false, -- [2]
      "aqua", -- [3]
    },
    [157571] = {
      true, -- [1]
      false, -- [2]
      "deepskyblue", -- [3]
    },
    [76407] = {
      true, -- [1]
      false, -- [2]
      "mediumslateblue", -- [3]
    },
    [184132] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [196263] = {
      true, -- [1]
      false, -- [2]
      "deepskyblue", -- [3]
    },
    [186658] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [95766] = {
      true, -- [1]
      false, -- [2]
      "aqua", -- [3]
    },
    [81820] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [188703] = {
      true, -- [1]
      false, -- [2]
      "yellow", -- [3]
    },
    [115395] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [131585] = {
      true, -- [1]
      false, -- [2]
      "navajowhite", -- [3]
    },
    [104270] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [80805] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [114628] = {
      true, -- [1]
      false, -- [2]
      "magenta", -- [3]
    },
    [205727] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [199717] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [138465] = {
      true, -- [1]
      false, -- [2]
      "lightcoral", -- [3]
    },
    [208698] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [59552] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [167493] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [164552] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [130485] = {
      true, -- [1]
      false, -- [2]
      "peru", -- [3]
    },
    [96587] = {
      true, -- [1]
      false, -- [2]
      "deepskyblue", -- [3]
    },
    [138338] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [179386] = {
      true, -- [1]
      false, -- [2]
      "orchid", -- [3]
    },
    [190407] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [176573] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [192789] = {
      true, -- [1]
      false, -- [2]
      "orchid", -- [3]
    },
    [190128] = {
      true, -- [1]
      false, -- [2]
      "yellow", -- [3]
    },
    [114629] = {
      true, -- [1]
      false, -- [2]
      "blue", -- [3]
    },
    [162763] = {
      true, -- [1]
      false, -- [2]
      "mediumslateblue", -- [3]
    },
    [186420] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [167111] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [136549] = {
      true, -- [1]
      false, -- [2]
      "lightcoral", -- [3]
    },
    [80808] = {
      true, -- [1]
      false, -- [2]
      "orchid", -- [3]
    },
    [151127] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [131818] = {
      false, -- [1]
      false, -- [2]
      "plum", -- [3]
    },
    [189234] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [129527] = {
      true, -- [1]
      false, -- [2]
      "deepskyblue", -- [3]
    },
    [168007] = {
      true, -- [1]
      false, -- [2]
      "blue", -- [3]
    },
    [179388] = {
      true, -- [1]
      false, -- [2]
      "deepskyblue", -- [3]
    },
    [101075] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [176575] = {
      true, -- [1]
      false, -- [2]
      "deepskyblue", -- [3]
    },
    [79720] = {
      true, -- [1]
      false, -- [2]
      "magenta", -- [3]
    },
    [131819] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [189235] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [80935] = {
      true, -- [1]
      false, -- [2]
      "deepskyblue", -- [3]
    },
    [136295] = {
      true, -- [1]
      false, -- [2]
      "peru", -- [3]
    },
    [169159] = {
      true, -- [1]
      false, -- [2]
      "gold", -- [3]
    },
    [131436] = {
      true, -- [1]
      false, -- [2]
      "aqua", -- [3]
    },
    [41139] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [155221] = {
      true, -- [1]
      false, -- [2]
      "deepskyblue", -- [3]
    },
    [96664] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [164266] = {
      true, -- [1]
      false, -- [2]
      "orchid", -- [3]
    },
    [95769] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [194316] = {
      true, -- [1]
      false, -- [2]
      "dodgerblue", -- [3]
    },
    [77483] = {
      true, -- [1]
      false, -- [2]
      "orchid", -- [3]
    },
    [185656] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [168393] = {
      true, -- [1]
      false, -- [2]
      "orchid", -- [3]
    },
    [116549] = {
      true, -- [1]
      false, -- [2]
      "deepskyblue", -- [3]
    },
    [131821] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [77803] = {
      true, -- [1]
      false, -- [2]
      "orchid", -- [3]
    },
    [193457] = {
      true, -- [1]
      false, -- [2]
      "mediumslateblue", -- [3]
    },
    [134251] = {
      true, -- [1]
      false, -- [2]
      "honeydew", -- [3]
    },
    [185529] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [165197] = {
      true, -- [1]
      false, -- [2]
      "mediumslateblue", -- [3]
    },
    [177817] = {
      true, -- [1]
      false, -- [2]
      "blue", -- [3]
    },
    [134144] = {
      true, -- [1]
      false, -- [2]
      "lightgreen", -- [3]
    },
    [197698] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [130488] = {
      true, -- [1]
      false, -- [2]
      "lightsalmon", -- [3]
    },
    [129529] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [95834] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [114312] = {
      true, -- [1]
      false, -- [2]
      "mediumslateblue", -- [3]
    },
    [83025] = {
      true, -- [1]
      false, -- [2]
      "blue", -- [3]
    },
    [189878] = {
      true, -- [1]
      false, -- [2]
      "yellow", -- [3]
    },
    [104274] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [157810] = {
      true, -- [1]
      false, -- [2]
      "deepskyblue", -- [3]
    },
    [111563] = {
      true, -- [1]
      false, -- [2]
      "blue", -- [3]
    },
    [80937] = {
      true, -- [1]
      false, -- [2]
      "orchid", -- [3]
    },
    [132491] = {
      true, -- [1]
      false, -- [2]
      "palegreen", -- [3]
    },
    [163618] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [208165] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [168396] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [168418] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [133870] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [179010] = {
      true, -- [1]
      false, -- [2]
      "deepskyblue", -- [3]
    },
    [95771] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [166301] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [151773] = {
      true, -- [1]
      false, -- [2]
      "blue", -- [3]
    },
    [177787] = {
      true, -- [1]
      false, -- [2]
      "aqua", -- [3]
    },
    [173190] = {
      true, -- [1]
      false, -- [2]
      "deepskyblue", -- [3]
    },
    [104275] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [126845] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [114633] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [80938] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [88163] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [169861] = {
      true, -- [1]
      false, -- [2]
      "blue", -- [3]
    },
    [98521] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [169421] = {
      true, -- [1]
      false, -- [2]
      "gold", -- [3]
    },
    [170572] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [164562] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [162049] = {
      true, -- [1]
      false, -- [2]
      "mediumslateblue", -- [3]
    },
    [193462] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [122971] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [206066] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [162133] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [206065] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [150160] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [164563] = {
      true, -- [1]
      false, -- [2]
      "blue", -- [3]
    },
    [114634] = {
      true, -- [1]
      false, -- [2]
      "mediumslateblue", -- [3]
    },
    [186242] = {
      true, -- [1]
      false, -- [2]
      "blue", -- [3]
    },
    [179269] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [176521] = {
      true, -- [1]
      false, -- [2]
      "blue", -- [3]
    },
    [163157] = {
      true, -- [1]
      false, -- [2]
      "orchid", -- [3]
    },
    [59555] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [168934] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [168932] = {
      true, -- [1]
      false, -- [2]
      "gold", -- [3]
    },
    [127111] = {
      true, -- [1]
      false, -- [2]
      "deepskyblue", -- [3]
    },
    [194487] = {
      true, -- [1]
      false, -- [2]
      "deepskyblue", -- [3]
    },
    [151649] = {
      true, -- [1]
      false, -- [2]
      "orchid", -- [3]
    },
    [165076] = {
      true, -- [1]
      false, -- [2]
      "magenta", -- [3]
    },
    [134514] = {
      true, -- [1]
      false, -- [2]
      "lightgreen", -- [3]
    },
    [204206] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [154014] = {
      true, -- [1]
      false, -- [2]
      "deepskyblue", -- [3]
    },
    [118489] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [184130] = {
      true, -- [1]
      false, -- [2]
      "aqua", -- [3]
    },
    [170480] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [195265] = {
      true, -- [1]
      false, -- [2]
      "dodgerblue", -- [3]
    },
    [131318] = {
      true, -- [1]
      false, -- [2]
      "mediumslateblue", -- [3]
    },
    [171343] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [169425] = {
      true, -- [1]
      false, -- [2]
      "gold", -- [3]
    },
    [199220] = {
      false, -- [1]
      false, -- [2]
      "white", -- [3]
    },
    [191164] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [212775] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [91008] = {
      true, -- [1]
      false, -- [2]
      "deepskyblue", -- [3]
    },
    [179842] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [114316] = {
      true, -- [1]
      false, -- [2]
      "deepskyblue", -- [3]
    },
    [75506] = {
      true, -- [1]
      false, -- [2]
      "deepskyblue", -- [3]
    },
    [189886] = {
      true, -- [1]
      false, -- [2]
      "gold", -- [3]
    },
    [102232] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [198326] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [114636] = {
      true, -- [1]
      false, -- [2]
      "orchid", -- [3]
    },
    [137713] = {
      true, -- [1]
      false, -- [2]
      "paleturquoise", -- [3]
    },
    [180348] = {
      true, -- [1]
      false, -- [2]
      "blue", -- [3]
    },
    [137458] = {
      true, -- [1]
      false, -- [2]
      "deepskyblue", -- [3]
    },
    [162038] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [134139] = {
      true, -- [1]
      false, -- [2]
      "gold", -- [3]
    },
    [115020] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [95842] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [164737] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [186738] = {
      true, -- [1]
      false, -- [2]
      "mediumslateblue", -- [3]
    },
    [75979] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [114317] = {
      true, -- [1]
      false, -- [2]
      "deepskyblue", -- [3]
    },
    [164185] = {
      true, -- [1]
      false, -- [2]
      "orchid", -- [3]
    },
    [169428] = {
      true, -- [1]
      false, -- [2]
      "gold", -- [3]
    },
    [83893] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [104300] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [150168] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [128455] = {
      true, -- [1]
      false, -- [2]
      "aqua", -- [3]
    },
    [114319] = {
      true, -- [1]
      false, -- [2]
      "blue", -- [3]
    },
    [183495] = {
      true, -- [1]
      false, -- [2]
      "mediumpurple", -- [3]
    },
    [92538] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [137716] = {
      false, -- [1]
      false, -- [2]
      "blue", -- [3]
    },
    [113998] = {
      true, -- [1]
      false, -- [2]
      "aqua", -- [3]
    },
    [195399] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [176974] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [190401] = {
      true, -- [1]
      false, -- [2]
      "aqua", -- [3]
    },
    [134417] = {
      true, -- [1]
      false, -- [2]
      "gold", -- [3]
    },
    [165471] = {
      true, -- [1]
      false, -- [2]
      "blue", -- [3]
    },
    [84989] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [169430] = {
      true, -- [1]
      false, -- [2]
      "gold", -- [3]
    },
    [205363] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [213806] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [208193] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [134137] = {
      true, -- [1]
      false, -- [2]
      "dodgerblue", -- [3]
    },
    [129553] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [127106] = {
      true, -- [1]
      false, -- [2]
      "mediumslateblue", -- [3]
    },
    [136186] = {
      true, -- [1]
      false, -- [2]
      "honeydew", -- [3]
    },
    [212673] = {
      true, -- [1]
      false, -- [2]
      "aqua", -- [3]
    },
    [214209] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [174802] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [40634] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [190403] = {
      true, -- [1]
      false, -- [2]
      "aqua", -- [3]
    },
    [151657] = {
      true, -- [1]
      false, -- [2]
      "aqua", -- [3]
    },
    [44404] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [115406] = {
      true, -- [1]
      false, -- [2]
      "deepskyblue", -- [3]
    },
    [104217] = {
      true, -- [1]
      false, -- [2]
      "mediumslateblue", -- [3]
    },
    [195135] = {
      true, -- [1]
      false, -- [2]
      "fuchsia", -- [3]
    },
    [150251] = {
      true, -- [1]
      false, -- [2]
      "blue", -- [3]
    },
    [40633] = {
      true, -- [1]
      false, -- [2]
      "aqua", -- [3]
    },
  },
  ["extra_icon_show_enrage_border"] = {
    0.61568629741669, -- [1]
    0.18823531270027, -- [2]
    0.21176472306252, -- [3]
  },
  ["cast_statusbar_spark_half"] = true,
  ["hook_data"] = {
    {
      ["OptionsValues"] = {
      },
      ["HooksTemp"] = {
      },
      ["Hooks"] = {
        ["Nameplate Updated"] = "function (self, unitId, unitFrame, envTable)\n    \n    --get the GUID of the target of the unit\n    local targetGUID = UnitGUID (unitId .. \"target\")\n    \n    if (targetGUID) then\n        \n        --get the npcID of the target\n        local npcID = Plater.GetNpcIDFromGUID (targetGUID)\n        --check if the npcID of this unit is in the npc list \n        if (envTable.ListOfNpcs [npcID]) then\n            Plater.SetNameplateColor (unitFrame, envTable.ListOfNpcs [npcID])\n            \n        else\n            --check if the name of ths unit is in the list\n            local unitName = UnitName (unitId .. \"target\")\n            if (envTable.ListOfNpcs [unitName]) then\n                Plater.SetNameplateColor (unitFrame, envTable.ListOfNpcs [unitName])\n                \n            else\n                --check if the name of the unit in lower case is in the npc list\n                unitName = string.lower (unitName)\n                if (envTable.ListOfNpcs [unitName]) then\n                    Plater.SetNameplateColor (unitFrame, envTable.ListOfNpcs [unitName])                \n                    \n                end\n            end\n        end\n        \n    end\nend\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n",
        ["Constructor"] = "function (self, unitId, unitFrame, envTable)\n    \n    --list of npcs and their colors, can be inserted:\n    --name of the unit\n    --name of the unit in lower case\n    --npcID of the unit\n    \n    --color can be added as:\n    --color names: \"red\", \"yellow\"\n    --color hex: \"#FF0000\", \"#FFFF00\"\n    --color table: {1, 0, 0}, {1, 1, 0}    \n    \n    envTable.ListOfNpcs = {\n        [61146] = \"mediumseagreen\", --monk statue npcID\n        [103822] = \"mediumseagreen\", --druid treant npcID        \n        [61056] = \"mediumseagreen\", --shaman earth ele npcID\n        [95072] = \"mediumseagreen\", --shaman earth ele npcID    \n    }\n    \n    \n    \nend\n\n\n\n\n",
      },
      ["Time"] = 1674346231,
      ["LoadConditions"] = {
        ["talent"] = {
        },
        ["group"] = {
          ["Enabled"] = true,
          ["party"] = true,
        },
        ["class"] = {
        },
        ["map_ids"] = {
        },
        ["role"] = {
          ["Enabled"] = true,
          ["TANK"] = true,
        },
        ["pvptalent"] = {
        },
        ["spec"] = {
        },
        ["race"] = {
        },
        ["encounter_ids"] = {
        },
        ["affix"] = {
        },
      },
      ["url"] = "",
      ["Icon"] = 134400,
      ["Enabled"] = true,
      ["Revision"] = 293,
      ["semver"] = "",
      ["Author"] = "Kastfall-Azralon",
      ["Desc"] = "",
      ["Prio"] = 99,
      ["version"] = -1,
      ["PlaterCore"] = 1,
      ["Options"] = {
      },
      ["LastHookEdited"] = "",
      ["Name"] = "Attacking Specific Unit",
    }, -- [1]
    {
      ["OptionsValues"] = {
      },
      ["HooksTemp"] = {
      },
      ["Hooks"] = {
        ["Initialization"] = "function (modTable)\n    \n    --ATTENTION: after enabling this mod, you may have to adjust the anchor point at the Buff Settings tab\n    \n    local sortByTime = false\n    local invertSort = false\n    \n    --which auras goes first, assign a value (any number), bigger value goes first\n    local priority = {\n        [\"Burning Wound\"] = 50,\n        [\"Rend\"] = 50,\n        [\"Colossus Smash\"] = 50,\n        [\"Vampiric Touch\"] = 50,\n        [\"Shadow Word: Pain\"] = 40,\n        [\"Devouring Plague\"] = 30,\n        [\"Agony\"] = 50,\n        [\"Corruption\"] = 40,\n        [\"Unstable Affliction\"] = 30,\n        [\"Siphon Life\"] = 20,\n        [\"Shadow Embrace\"] = 10,\n        [\"Moonfire\"] = 40,\n        [\"Sunfire\"] = 50,\n        [\"Stellar Flare\"] = 30\n    }\n    \n    -- Sort function - do not touch\n    Plater.db.profile.aura_sort = true\n    \n    \n    function Plater.AuraIconsSortFunction (aura1, aura2)\n        local p1 = priority[aura1.SpellId] or priority[aura1.SpellName] or 1\n        local p2 = priority[aura2.SpellId] or priority[aura2.SpellName] or 1\n        \n        if sortByTime and p1 == p2 then\n            if invertSort then\n                return (aura1.Duration == 0 and 99999999 or aura1.RemainingTime or 0) > (aura2.Duration == 0 and 99999999 or aura2.RemainingTime or 0)\n            else\n                return (aura1.Duration == 0 and 99999999 or aura1.RemainingTime or 0) < (aura2.Duration == 0 and 99999999 or aura2.RemainingTime or 0)\n            end\n        else\n            if invertSort then\n                return p1 < p2\n            else\n                return p1 > p2\n            end\n        end\n    end\n    \nend\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n",
      },
      ["Time"] = 1674875715,
      ["LoadConditions"] = {
        ["talent"] = {
        },
        ["group"] = {
        },
        ["class"] = {
        },
        ["map_ids"] = {
        },
        ["role"] = {
        },
        ["pvptalent"] = {
        },
        ["spec"] = {
        },
        ["race"] = {
        },
        ["encounter_ids"] = {
        },
        ["affix"] = {
        },
      },
      ["url"] = "",
      ["Icon"] = 134400,
      ["Enabled"] = false,
      ["Revision"] = 387,
      ["semver"] = "",
      ["Author"] = "Ditador-Azralon",
      ["Desc"] = "",
      ["Prio"] = 99,
      ["version"] = -1,
      ["PlaterCore"] = 1,
      ["Options"] = {
      },
      ["LastHookEdited"] = "",
      ["Name"] = "Aura Reorder",
    }, -- [2]
    {
      ["OptionsValues"] = {
        ["Descanchor"] = 4,
        ["BSborderth"] = 1,
        ["BStimer_size"] = 10,
        ["Descyoff"] = -1,
        ["BSdesc_size"] = 8,
      },
      ["HooksTemp"] = {
      },
      ["Hooks"] = {
        ["Nameplate Created"] = "function (self, unitId, unitFrame, envTable, modTable)\n    \n    unitFrame.ExtraIconFrame:SetOption (\"text_size\", modTable.config.BStimer_size)\n    unitFrame.ExtraIconFrame:SetOption (\"text_color\", modTable.config.BStimer_color)\n    unitFrame.ExtraIconFrame:SetOption (\"desc_text_size\", modTable.config.BSdesc_size)\n    unitFrame.ExtraIconFrame:SetOption (\"stack_text_size\", modTable.config.BSstack_size)\n    \nend\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n",
        ["Nameplate Updated"] = "function (self, unitId, unitFrame, envTable, modTable)\n    \n    envTable.auramodifier ()\n    \nend\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n",
        ["Constructor"] = "function (self, unitId, unitFrame, envTable, modTable)\n    \n    envTable.auramodifier = function()\n        \n        if modTable.config.BShidefriendl and unitFrame.actorType == \"friendlyplayer\" then\n            unitFrame.ExtraIconFrame:Hide()\n        end      \n        \n        for index, auraIcon in ipairs (unitFrame.ExtraIconFrame.IconPool) do\n            if (auraIcon:IsShown()) then\n                \n                local profile = Plater.db.profile\n                local Anchor = {\n                    side = modTable.config.Descanchor, \n                    x = modTable.config.Descxoff, \n                    y = modTable.config.Descyoff,\n                }              \n                local size = modTable.config.BSborderth\n                \n                if (not auraIcon.PixelPerfectBorder) then\n                    auraIcon.PixelPerfectBorder = CreateFrame (\"frame\", nil, auraIcon, \"NamePlateFullBorderTemplate\")\n                end\n                \n                local r, g, b = auraIcon:GetBackdropBorderColor()\n                auraIcon:SetBackdropBorderColor (0, 0, 0, 0)\n                auraIcon.PixelPerfectBorder:SetVertexColor (r, g, b)\n                auraIcon.PixelPerfectBorder:SetBorderSizes (size, size, size, size)\n                auraIcon.PixelPerfectBorder:UpdateSizes()\n                \n                auraIcon.Texture:SetSize(profile.extra_icon_width - size/2, profile.extra_icon_height - size/2)\n                auraIcon.Texture:ClearAllPoints()\n                auraIcon.Texture:SetAllPoints()\n                auraIcon.Border:Hide() \n                \n                Plater.SetFontOutlineAndShadow (auraIcon.CountdownText, profile.aura_timer_text_outline, profile.aura_timer_text_shadow_color, profile.aura_timer_text_shadow_color_offset[1], profile.aura_timer_text_shadow_color_offset[2])\n                \n                Plater.SetAnchor (auraIcon.Desc, Anchor)\n                auraIcon.Cooldown:SetEdgeTexture (profile.aura_cooldown_edge_texture)\n                auraIcon.Cooldown:SetDrawSwipe (true) \n                if modTable.config.BScdreverse then\n                    auraIcon.Cooldown:SetReverse (profile.aura_cooldown_reverse)\n                end\n                \n            end\n        end\n    end\nend\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n",
      },
      ["Time"] = 1675003933,
      ["LoadConditions"] = {
        ["talent"] = {
        },
        ["group"] = {
        },
        ["class"] = {
        },
        ["map_ids"] = {
        },
        ["role"] = {
        },
        ["pvptalent"] = {
        },
        ["spec"] = {
        },
        ["race"] = {
        },
        ["encounter_ids"] = {
        },
        ["affix"] = {
        },
      },
      ["url"] = "",
      ["Icon"] = 134400,
      ["Enabled"] = true,
      ["Revision"] = 460,
      ["semver"] = "",
      ["Author"] = "Driani-Antonidas",
      ["Desc"] = "",
      ["Prio"] = 99,
      ["version"] = -1,
      ["PlaterCore"] = 1,
      ["Options"] = {
        {
          ["Type"] = 5,
          ["Key"] = "",
          ["Value"] = "Basic Options",
          ["Name"] = "Basic Options",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_label",
          ["Desc"] = "",
        }, -- [1]
        {
          ["Type"] = 4,
          ["Key"] = "BShidefriendly",
          ["Value"] = true,
          ["Name"] = "Hide Buff Special at Friendly UnitFrame",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_bool",
          ["Desc"] = "Hide Buff Special at Friendly UnitFrame",
        }, -- [2]
        {
          ["Type"] = 4,
          ["Key"] = "BScdreverse",
          ["Value"] = true,
          ["Name"] = "Swipe Closure Inverted",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_bool",
          ["Desc"] = "If enabled, swipe closure inverted",
        }, -- [3]
        {
          ["Type"] = 2,
          ["Max"] = 100,
          ["Desc"] = "Set Buff Special border thickness",
          ["Min"] = 0,
          ["Key"] = "BSborderth",
          ["Value"] = 2,
          ["Fraction"] = true,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Border Thickness",
        }, -- [4]
        {
          ["Type"] = 6,
          ["Key"] = "",
          ["Value"] = 0,
          ["Name"] = "Blank",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [5]
        {
          ["Type"] = 5,
          ["Key"] = "",
          ["Value"] = "Buff Special Text Options",
          ["Name"] = "Buff Special Text Options",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_label",
          ["Desc"] = "",
        }, -- [6]
        {
          ["Type"] = 2,
          ["Max"] = 100,
          ["Desc"] = "Set timer text size",
          ["Min"] = 1,
          ["Key"] = "BStimer_size",
          ["Value"] = 14,
          ["Fraction"] = false,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Timer Text Size",
        }, -- [7]
        {
          ["Type"] = 1,
          ["Key"] = "BStimer_color",
          ["Value"] = {
            1, -- [1]
            1, -- [2]
            0, -- [3]
            1, -- [4]
          },
          ["Name"] = "Timer Text Color",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
          ["Desc"] = "Set timer text color",
        }, -- [8]
        {
          ["Type"] = 2,
          ["Max"] = 100,
          ["Desc"] = "Set stack text size",
          ["Min"] = 1,
          ["Key"] = "BSstack_size",
          ["Value"] = 10,
          ["Fraction"] = false,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Stack Text Size",
        }, -- [9]
        {
          ["Type"] = 6,
          ["Key"] = "",
          ["Value"] = 0,
          ["Name"] = "Blank",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [10]
        {
          ["Type"] = 5,
          ["Key"] = "",
          ["Value"] = "Buff Special Player Name Options",
          ["Name"] = "Buff Special Player Name Options",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_label",
          ["Desc"] = "",
        }, -- [11]
        {
          ["Type"] = 2,
          ["Max"] = 100,
          ["Desc"] = "Set player name text size",
          ["Min"] = 1,
          ["Key"] = "BSdesc_size",
          ["Value"] = 10,
          ["Fraction"] = false,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Player Name Text Size",
        }, -- [12]
        {
          ["Type"] = 2,
          ["Max"] = 8,
          ["Desc"] = "1(TOP-LEFT) / 2(LEFT) / 3(BOT-LEFT) / 4(BOT) / 5(BOT-RIGHT) / 6(RIGHT) / 7(TOP-RIGHT) / 8(TOP)",
          ["Min"] = 1,
          ["Key"] = "Descanchor",
          ["Value"] = 4,
          ["Fraction"] = false,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Player Name Text Anchor",
        }, -- [13]
        {
          ["Type"] = 2,
          ["Max"] = 100,
          ["Desc"] = "Set player name text y-offset",
          ["Min"] = -100,
          ["Key"] = "Descyoff",
          ["Value"] = -2,
          ["Fraction"] = false,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Player Name Text Y-offset",
        }, -- [14]
        {
          ["Type"] = 2,
          ["Max"] = 100,
          ["Desc"] = "Set player name text x-offset",
          ["Min"] = -100,
          ["Key"] = "Descxoff",
          ["Value"] = 0,
          ["Fraction"] = false,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Player Name Text X-offset",
        }, -- [15]
      },
      ["LastHookEdited"] = "Nameplate Created",
      ["Name"] = "Buff Special",
    }, -- [3]
    {
      ["OptionsValues"] = {
      },
      ["HooksTemp"] = {
      },
      ["Hooks"] = {
        ["Cast Update"] = "function (self, unitId, unitFrame, envTable)\n    \n    envTable.UpdateBorder (unitFrame)\n    \nend\n\n\n",
        ["Destructor"] = "function (self, unitId, unitFrame, envTable)\n    if (unitFrame.castBar.CastBarBorder) then\n        unitFrame.castBar.CastBarBorder:Hide()\n    end    \nend",
        ["Cast Start"] = "function (self, unitId, unitFrame, envTable)\n    \n    envTable.UpdateBorder (unitFrame)\n    \nend\n\n\n",
        ["Constructor"] = "function (self, unitId, unitFrame, envTable)\n    \n    --settings\n    \n    --hide the icon of the spell, may require /reload after changing\n    envTable.HideIcon = false\n    \n    --border settings\n    envTable.BorderThickness = 0.5\n    envTable.BorderColor = \"black\"\n    \n    --private\n    --create the border\n    if (not unitFrame.castBar.CastBarBorder) then\n        unitFrame.castBar.CastBarBorder = CreateFrame (\"frame\", nil, unitFrame.castBar, \"NamePlateFullBorderTemplate\")\n        unitFrame.castBar.CastBarBorder:SetIgnoreParentScale(false)\n        \n    end    \n    \n    --update the border\n    function envTable.UpdateBorder (unitFrame)\n        local castBar = unitFrame.castBar\n        \n        local r, g, b, a = DetailsFramework:ParseColors (envTable.BorderColor)\n        castBar.CastBarBorder:SetVertexColor (r, g, b, a)\n        \n        local size = envTable.BorderThickness\n        castBar.CastBarBorder:SetBorderSizes (size, size, size, size)\n        castBar.CastBarBorder:UpdateSizes()        \n        \n        if (envTable.HideIcon) then\n            castBar.Icon:Hide()\n        end\n        \n        castBar.CastBarBorder:Show()\n    end\n    \nend\n\n\n\n\n",
      },
      ["Time"] = 1672803394,
      ["LoadConditions"] = {
        ["talent"] = {
        },
        ["group"] = {
        },
        ["class"] = {
        },
        ["map_ids"] = {
        },
        ["role"] = {
        },
        ["pvptalent"] = {
        },
        ["spec"] = {
        },
        ["race"] = {
        },
        ["encounter_ids"] = {
        },
        ["affix"] = {
        },
      },
      ["url"] = "",
      ["Icon"] = 134400,
      ["Enabled"] = true,
      ["Revision"] = 168,
      ["semver"] = "",
      ["Author"] = "Izimode-Azralon",
      ["Desc"] = "",
      ["Prio"] = 99,
      ["version"] = -1,
      ["PlaterCore"] = 1,
      ["Options"] = {
      },
      ["LastHookEdited"] = "",
      ["Name"] = "Cast Border",
    }, -- [4]
    {
      ["OptionsValues"] = {
      },
      ["HooksTemp"] = {
      },
      ["Hooks"] = {
        ["Cast Update"] = "function (self, unitId, unitFrame, envTable, modTable)\n    envTable.UpdateCastBarName(unitId, unitFrame.castBar)\nend\n\n\n",
        ["Cast Start"] = "function (self, unitId, unitFrame, envTable, modTable)\n    envTable.UpdateCastBarName(unitId, unitFrame.castBar)\nend\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n",
        ["Constructor"] = "function (self, unitId, unitFrame, envTable, modTable)\n    \n    --percent of total cast bar size, default: 60% spell name\n    local spellNameSize = 0.60\n    \n    --update function\n    function envTable.UpdateCastBarName(unitId, castBar)\n        --do nothing if interrupted\n        if castBar.IsInterrupted then\n            return\n            \n        end\n        \n        --get the target's unitId \n        local targetUnitId = unitId .. \"target\"\n        \n        --does the unit exists?\n        if (UnitExists(targetUnitId)) then\n            \n            --get the target name\n            local targetName = UnitName(targetUnitId)\n            \n            --does the target name exists?\n            if (targetName) then\n                --get the current spell name\n                local spellName = castBar.SpellName\n                --reset the text in the cast bar\n                castBar.Text:SetText(spellName)\n                \n                --paint the target name with the player's class color\n                local targetNameByColor = Plater.SetTextColorByClass (targetUnitId, targetName)\n                \n                --castbar width\n                local castBarWidth = castBar:GetWidth()\n                DetailsFramework:TruncateText (castBar.Text, castBarWidth * spellNameSize)\n                \n                --set the new text in the castbar spell name fontstring\n                local currentText = castBar.Text:GetText()\n                castBar.Text:SetText(currentText .. \" » \" .. targetNameByColor .. \"\")\n                DetailsFramework:TruncateText (castBar.Text, castBarWidth)                \n            end\n        end\n    end\n    \nend\n\n\n\n\n\n\n\n\n",
      },
      ["Time"] = 1672783061,
      ["LoadConditions"] = {
        ["talent"] = {
        },
        ["group"] = {
          ["Enabled"] = true,
          ["party"] = true,
          ["raid"] = true,
          ["arena"] = true,
          ["pvp"] = true,
        },
        ["class"] = {
        },
        ["map_ids"] = {
        },
        ["role"] = {
        },
        ["pvptalent"] = {
        },
        ["spec"] = {
        },
        ["race"] = {
        },
        ["encounter_ids"] = {
        },
        ["affix"] = {
        },
      },
      ["url"] = "",
      ["Icon"] = 134400,
      ["Enabled"] = false,
      ["Revision"] = 124,
      ["semver"] = "",
      ["Author"] = "Izimode-Azralon",
      ["Desc"] = "",
      ["Prio"] = 99,
      ["version"] = -1,
      ["PlaterCore"] = 1,
      ["Options"] = {
      },
      ["LastHookEdited"] = "",
      ["Name"] = "Cast Target",
    }, -- [5]
    {
      ["OptionsValues"] = {
      },
      ["HooksTemp"] = {
      },
      ["Hooks"] = {
        ["Nameplate Updated"] = "function (self, unitId, unitFrame, envTable)\n    \n    --border thickness\n    local size = .5 \n    \n    for index, auraIcon in ipairs (unitFrame.BuffFrame.PlaterBuffList) do\n        if (auraIcon:IsShown()) then\n            \n            if (not auraIcon.PixelPerfectBorder) then\n                auraIcon.PixelPerfectBorder = CreateFrame (\"frame\", nil, auraIcon, \"NamePlateFullBorderTemplate\")\n            end\n            \n            local r, g, b = auraIcon:GetBackdropBorderColor()\n            auraIcon:SetBackdropBorderColor (r, g, b, 0)\n            \n            auraIcon.PixelPerfectBorder:SetVertexColor (r, g, b)\n            auraIcon.PixelPerfectBorder:SetBorderSizes (size, size, size, size)\n            auraIcon.PixelPerfectBorder:UpdateSizes()\n            \n            auraIcon.Icon:ClearAllPoints()\n            auraIcon.Icon:SetAllPoints()\n            \n            auraIcon.Border:Hide() --hide plater default border\n        end\n    end\n    \n    for index, auraIcon in ipairs (unitFrame.BuffFrame2.PlaterBuffList) do\n        if (auraIcon:IsShown()) then\n            \n            if (not auraIcon.PixelPerfectBorder) then\n                auraIcon.PixelPerfectBorder = CreateFrame (\"frame\", nil, auraIcon, \"NamePlateFullBorderTemplate\")\n            end\n            \n            local r, g, b = auraIcon:GetBackdropBorderColor()\n            auraIcon:SetBackdropBorderColor (r, g, b, 0)\n            \n            auraIcon.PixelPerfectBorder:SetVertexColor (r, g, b)\n            auraIcon.PixelPerfectBorder:SetBorderSizes (size, size, size, size)\n            auraIcon.PixelPerfectBorder:UpdateSizes()            \n            \n            auraIcon.Icon:ClearAllPoints()\n            auraIcon.Icon:SetAllPoints()\n            \n            auraIcon.Border:Hide() --hide plater default border\n        end\n    end    \nend",
      },
      ["Time"] = 1689714052,
      ["LoadConditions"] = {
        ["talent"] = {
        },
        ["group"] = {
        },
        ["class"] = {
        },
        ["map_ids"] = {
        },
        ["role"] = {
        },
        ["pvptalent"] = {
        },
        ["spec"] = {
        },
        ["race"] = {
        },
        ["encounter_ids"] = {
        },
        ["affix"] = {
        },
      },
      ["url"] = "",
      ["Icon"] = 134400,
      ["Enabled"] = true,
      ["Revision"] = 182,
      ["semver"] = "",
      ["Author"] = "????????-Illidan",
      ["Desc"] = "",
      ["Prio"] = 31,
      ["version"] = -1,
      ["PlaterCore"] = 1,
      ["Options"] = {
      },
      ["LastHookEdited"] = "",
      ["Name"] = "Debuff Border",
    }, -- [6]
    {
      ["OptionsValues"] = {
      },
      ["HooksTemp"] = {
      },
      ["UID"] = "0x60f358aaaef576",
      ["Hooks"] = {
        ["Nameplate Updated"] = "function(self, unitId, unitFrame, envTable, modTable)\n    if Plater.NameplateHasAura(unitFrame, envTable.debuffID) then\n        Plater.SetNameplateColor(unitFrame, 'deeppink')\n    else\n        local npcId = unitFrame['namePlateNpcId']\n        local npcColor = envTable.dbColor[npcId]\n        if npcColor then\n            Plater.SetNameplateColor(unitFrame, npcColor)\n        else\n            Plater.RefreshNameplateColor(unitFrame)\n        end\n    end\nend",
        ["Constructor"] = "function(self, unitId, unitFrame, envTable, modTable)\n    local DF = _G ['DetailsFramework']\n    envTable.dbColor={}\n    for npcID, infoTable in pairs (Plater.db.profile.npc_colors) do\n        local enabled1 = infoTable[1] --this is the overall enabled\n        local enabled2 = infoTable[2] --if this is true, this color is only used for scripts\n        local colorID = infoTable[3] --the color\n        if (enabled1 and not enabled2) then\n            local r, g, b = DF:ParseColors (colorID)\n            envTable.dbColor[npcID] = {r, g, b, 1}\n        end\n    end\n    if Plater.PlayerClass == 'DEMONHUNTER' then\n        envTable.debuffID = 346278\n    elseif Plater.PlayerClass == 'ROGUE' then\n        envTable.debuffID = 324073\n    end\nend\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n",
      },
      ["Time"] = 1689714059,
      ["LoadConditions"] = {
        ["talent"] = {
        },
        ["group"] = {
          ["Enabled"] = true,
          ["party"] = true,
          ["scenario"] = true,
          ["raid"] = true,
          ["none"] = true,
        },
        ["class"] = {
          ["Enabled"] = true,
          ["ROGUE"] = true,
          ["DEMONHUNTER"] = true,
        },
        ["map_ids"] = {
        },
        ["role"] = {
        },
        ["pvptalent"] = {
        },
        ["spec"] = {
        },
        ["race"] = {
        },
        ["encounter_ids"] = {
        },
        ["affix"] = {
        },
      },
      ["url"] = "",
      ["Icon"] = 134400,
      ["Enabled"] = true,
      ["Revision"] = 242,
      ["semver"] = "",
      ["Author"] = "Avayde-Illidan",
      ["Desc"] = "",
      ["Prio"] = 30,
      ["version"] = -1,
      ["PlaterCore"] = 1,
      ["Name"] = "Debuff Color",
      ["Options"] = {
      },
      ["LastHookEdited"] = "",
    }, -- [7]
    {
      ["OptionsValues"] = {
      },
      ["HooksTemp"] = {
      },
      ["Hooks"] = {
        ["Nameplate Updated"] = "function (self, unitId, unitFrame, envTable)\n    if not envTable.units[select(6, strsplit(\"-\", UnitGUID(unitId)))] then\n        envTable.CheckAggro (unitFrame)\n    end\nend",
        ["Nameplate Added"] = "function (self, unitId, unitFrame, envTable)\n    if not envTable.units[select(6, strsplit(\"-\", UnitGUID(unitId)))] then\n        envTable.CheckAggro (unitFrame)\n    end\nend",
        ["Constructor"] = "function (self, unitId, unitFrame, envTable)\n    \n    envTable.units = {\n        [\"120651\"] = true, -- Explosives \n        [\"174773\"] = true, -- Spiteful\n        [\"169430\"] = true, -- Ur'zul DH Necrolord\n        [\"169428\"] = true, -- Wrathguard DH Necrolord\n        [\"169425\"] = true, -- Felhound DH Necrolord\n        [\"168932\"] = true, -- Doomguard DH Necrolord\n        [\"169429\"] = true, -- Shivarra DH Necrolord\n        [\"169426\"] = true, -- Infernal DH Necrolord\n        [\"169421\"] = true, -- Felguard DH Necrolord\n    }\n    \n    function envTable.CheckAggro (unitFrame)\n        --if the player isn't in combat, ignore this check\n        if (not Plater.IsInCombat()) then\n            return\n        end\n        \n        --if this unit is a player, ignore\n        if (UnitPlayerControlled(unitFrame.unit)) then\n            return\n        end\n        \n        --if this unit isn't in combat, ignore\n        if (not unitFrame.InCombat) then\n            return \n        end\n        \n        --player is a tank?\n        if (Plater.PlayerIsTank) then\n            --player isn't tanking this unit?\n            if (not unitFrame.namePlateThreatIsTanking) then\n                --check if a second tank is tanking it\n                if (Plater.ZoneInstanceType == \"raid\") then\n                    --return a list with the name of tanks in the raid\n                    local tankPlayersInTheRaid = Plater.GetTanks()\n                    \n                    --get the target name of this unit\n                    local unitTargetName = UnitName (unitFrame.targetUnitID)\n                    \n                    --check if the unit isn't targeting another tank in the raid and paint the color\n                    if (not tankPlayersInTheRaid [unitTargetName]) then\n                        Plater.SetNameplateColor (unitFrame, Plater.db.profile.tank.colors.noaggro)\n                    else\n                        Plater.SetNameplateColor (unitFrame, Plater.db.profile.tank.colors.anothertank)\n                        --another tank is tanking this unit\n                        --do nothing\n                    end\n                    \n                else\n                    Plater.SetNameplateColor (unitFrame, Plater.db.profile.tank.colors.noaggro)\n                end\n            end\n            \n        else\n            --player is a dps or healer\n            if (unitFrame.namePlateThreatIsTanking) then\n                Plater.SetNameplateColor (unitFrame, Plater.db.profile.dps.colors.aggro)\n            end\n            \n        end        \n    end\nend\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n",
      },
      ["Time"] = 1689714023,
      ["LoadConditions"] = {
        ["talent"] = {
        },
        ["group"] = {
        },
        ["class"] = {
        },
        ["map_ids"] = {
        },
        ["role"] = {
        },
        ["pvptalent"] = {
        },
        ["spec"] = {
        },
        ["race"] = {
        },
        ["encounter_ids"] = {
        },
        ["affix"] = {
        },
      },
      ["url"] = "",
      ["Icon"] = 134400,
      ["Enabled"] = true,
      ["Revision"] = 204,
      ["semver"] = "",
      ["Author"] = "Kastfall-Azralon",
      ["Desc"] = "When a mob is attacking you, force show the threat color. For tanks, force threat color if the mob is not attacking you.",
      ["Prio"] = 1,
      ["version"] = -1,
      ["PlaterCore"] = 1,
      ["Options"] = {
      },
      ["LastHookEdited"] = "",
      ["Name"] = "Force Threat Color",
    }, -- [8]
    {
      ["OptionsValues"] = {
      },
      ["HooksTemp"] = {
      },
      ["Hooks"] = {
        ["Nameplate Updated"] = "function (self, unitId, unitFrame, envTable)\n    \n    local buffSpecialGlow = true\n    \n    \n    -- functions --\n    local auraContainers = {unitFrame.BuffFrame.PlaterBuffList}\n    \n    if (Plater.db.profile.buffs_on_aura2) then\n        auraContainers [2] = unitFrame.BuffFrame2.PlaterBuffList\n    end\n    \n    for containerID = 1, #auraContainers do\n        \n        local auraContainer = auraContainers [containerID]\n        \n        for index, auraIcon in ipairs (auraContainer) do\n            if (auraIcon:IsShown() and auraIcon.RemainingTime > 0 and (envTable.glowSpells[auraIcon.spellId] and envTable.glowSpells[auraIcon.spellId] > auraIcon.RemainingTime)) then\n                if not auraIcon.pandemicGlowStarted then\n                    Plater.StartButtonGlow(auraIcon, nil, envTable.options)\n                    auraIcon.pandemicGlowStarted = true\n                end\n            else\n                if auraIcon.pandemicGlowStarted then\n                    Plater.StopButtonGlow(auraIcon, envTable.options.key)\n                    auraIcon.pandemicGlowStarted = false\n                end\n            end                \n        end\n        \n    end\n    \n    if buffSpecialGlow then\n        for _, auraIcon in ipairs (unitFrame.ExtraIconFrame.IconPool) do\n            if auraIcon:IsShown() then\n                local remainingTime = (auraIcon.startTime + auraIcon.duration - GetTime())\n                if (auraIcon:IsShown() and remainingTime > 0 and (envTable.glowSpells[auraIcon.spellId] and envTable.glowSpells[auraIcon.spellId] > remainingTime)) then\n                    if not auraIcon.pandemicGlowStarted then\n                        Plater.StartButtonGlow(auraIcon, nil, envTable.options)\n                        auraIcon.pandemicGlowStarted = true\n                    end\n                else\n                    if auraIcon.pandemicGlowStarted then\n                        Plater.StopButtonGlow(auraIcon, envTable.options.key)\n                        auraIcon.pandemicGlowStarted = false\n                    end                    \n                end  \n            end\n        end\n    end\nend",
        ["Constructor"] = "function (self, unitId, unitFrame, envTable)\n    \n    -- settings:\n    \n    -- spellIDs:\n    envTable.glowSpells = {\n        [164815] = 5.4, -- sunfire\n        [164812] = 6.6, -- moonfire\n        [202347] = 7.2, -- stellar flare\n        [980] = 5.4, -- agony\n        [146739] = 4.2, -- corruption\n        [316099] = 6.3, -- ua1\n        [342938] = 6.3, -- ua2\n        [63106] = 4.5, -- siphon life\n        [157736] = 5.4, -- immolate\n        [34914] = 6.3, -- vampiric touch\n        [589] = 4.8, -- sw: pain\n        [204213] = 4.8, -- purge the wicked\n        [188389] = 5.4, -- flame shock\n        [191587] = 8.1, -- virulent plague\n        [703] = 5.4, -- garrote\n        [1943] = 7.2, -- rupture\n        [121411] = 4.2, -- crimson tempest\n        [346278] = 4.5, -- burning wound\n        [1079] = 5.4, -- rip\n        [155722] = 5.4, -- rake\n        [106830] = 5.4, -- thrash\n        [772] = 4.5, --rend\n    }\n    \n    \n    -- for the LibCustomGlow implementation:\n    envTable.options = {\n        color = \"#e1e1e1\", -- all plater color types accepted, from lib: {r,g,b,a}, color of lines and opacity, from 0 to 1.\n        frequency = 0.4, -- frequency, set to negative to inverse direction of rotation. Default value is 0.25;\n        \n    }\n    \nend",
      },
      ["Time"] = 1672783081,
      ["LoadConditions"] = {
        ["talent"] = {
        },
        ["group"] = {
        },
        ["class"] = {
          ["DEATHKNIGHT"] = true,
          ["Enabled"] = true,
          ["WARLOCK"] = true,
          ["ROGUE"] = true,
          ["SHAMAN"] = true,
          ["DRUID"] = true,
          ["DEMONHUNTER"] = true,
          ["PRIEST"] = true,
        },
        ["map_ids"] = {
        },
        ["role"] = {
        },
        ["pvptalent"] = {
        },
        ["spec"] = {
        },
        ["race"] = {
        },
        ["encounter_ids"] = {
        },
        ["affix"] = {
        },
      },
      ["url"] = "",
      ["Icon"] = 134400,
      ["Enabled"] = false,
      ["Revision"] = 420,
      ["semver"] = "",
      ["Author"] = "Viashi-Antonidas",
      ["Desc"] = "",
      ["Prio"] = 99,
      ["version"] = -1,
      ["PlaterCore"] = 1,
      ["Options"] = {
      },
      ["LastHookEdited"] = "Nameplate Updated",
      ["Name"] = "Pandemic Glow",
    }, -- [9]
    {
      ["OptionsValues"] = {
      },
      ["HooksTemp"] = {
      },
      ["Hooks"] = {
        ["Nameplate Updated"] = "function (self, unitId, unitFrame, envTable)\n    \n    local auraContainers = {unitFrame.BuffFrame.PlaterBuffList}\n    \n    if (Plater.db.profile.buffs_on_aura2) then\n        auraContainers [2] = unitFrame.BuffFrame2.PlaterBuffList\n    end\n    \n    for containerID = 1, #auraContainers do\n        local auraContainer = auraContainers [containerID]\n        for index, auraIcon in ipairs (auraContainer) do\n            if (auraIcon:IsVisible()) then\n                if (auraIcon.RemainingTime < envTable.Timers.critical) then\n                    Plater:SetFontColor (auraIcon.TimerText, envTable.Colors.critical)\n                else\n                    Plater:SetFontColor (auraIcon.TimerText, envTable.Colors.okay)\n                end \n            end\n            \n        end\n    end\n    \n    \n    for _, auraIcon in ipairs (unitFrame.ExtraIconFrame.IconPool) do\n        if auraIcon:IsShown() then\n            if (auraIcon:IsVisible()) then\n                local remainingTime = (auraIcon.startTime + auraIcon.duration - GetTime())\n                if (remainingTime < envTable.Timers.critical) then\n                    Plater:SetFontColor (auraIcon.CountdownText, envTable.Colors.critical)\n                else\n                    Plater:SetFontColor (auraIcon.CountdownText, envTable.Colors.okay)\n                end\n            end\n        end\n    end\n    \nend\n\n\n",
        ["Constructor"] = "function (self, unitId, unitFrame, envTable)\n    \n    --colors for each time bracket\n    envTable.Colors = {\n        critical = \"red\",\n        okay = \"white\",\n    }\n    \n    --time amount to enter in warning or critical state\n    envTable.Timers = {\n        critical = 2.9,\n    }\n    \nend\n\n\n",
      },
      ["Time"] = 1689714040,
      ["LoadConditions"] = {
        ["talent"] = {
        },
        ["group"] = {
        },
        ["class"] = {
        },
        ["map_ids"] = {
        },
        ["role"] = {
        },
        ["pvptalent"] = {
        },
        ["spec"] = {
        },
        ["race"] = {
        },
        ["encounter_ids"] = {
        },
        ["affix"] = {
        },
      },
      ["url"] = "",
      ["Icon"] = 134400,
      ["Enabled"] = true,
      ["Revision"] = 78,
      ["semver"] = "",
      ["Author"] = "Ditador-Azralon",
      ["Desc"] = "",
      ["Prio"] = 51,
      ["version"] = -1,
      ["PlaterCore"] = 1,
      ["Options"] = {
      },
      ["LastHookEdited"] = "",
      ["Name"] = "Timer Text Color",
    }, -- [10]
    {
      ["OptionsValues"] = {
      },
      ["HooksTemp"] = {
      },
      ["Hooks"] = {
        ["Nameplate Updated"] = "function(self, unitId, unitFrame, envTable)\n    local text = unitFrame.healthBar.unitName:GetText()\n    if text then\n        -- if select(2, IsInInstance()) == 'party' or select(2, IsInInstance()) == 'raid' then\n        local  a , b, c, d, e = strsplit(' ', text, 5)\n        if\n        b == 'Assistant' or\n        b == 'Manastorm' or\n        b == 'Tonk' or\n        b == 'Relic' or\n        b == 'Slime' or\n        b == 'Tick' or\n        b == 'Totem' or\n        c == 'Totem'\n        then\n            unitFrame.healthBar.unitName:SetText(strsub(a or b or c or d or e, 1, 15))\n        else\n            unitFrame.healthBar.unitName:SetText(strsub(e or d or c or b or a, 1, 15))\n        end\n        --else\n        --unitFrame.healthBar.unitName:SetText(strsub(text,1,15))\n        --end\n    end\nend",
      },
      ["Time"] = 1671597988,
      ["LoadConditions"] = {
        ["talent"] = {
        },
        ["group"] = {
          ["Enabled"] = true,
          ["party"] = true,
        },
        ["class"] = {
        },
        ["map_ids"] = {
        },
        ["role"] = {
        },
        ["pvptalent"] = {
        },
        ["spec"] = {
        },
        ["race"] = {
        },
        ["encounter_ids"] = {
        },
        ["affix"] = {
        },
      },
      ["url"] = "",
      ["Icon"] = 134400,
      ["Enabled"] = false,
      ["Revision"] = 323,
      ["semver"] = "",
      ["Author"] = "Izimode-Azralon",
      ["Desc"] = "",
      ["Prio"] = 99,
      ["version"] = -1,
      ["PlaterCore"] = 1,
      ["Options"] = {
      },
      ["LastHookEdited"] = "Nameplate Updated",
      ["Name"] = "Last Name",
    }, -- [11]
    {
      ["OptionsValues"] = {
        ["kickReadyInTimeColor"] = {
          0.42352944612503, -- [1]
          0.47058826684952, -- [2]
          1, -- [3]
          1, -- [4]
        },
        ["noKickReadyColor"] = {
          0.49411767721176, -- [1]
          0.49803924560547, -- [2]
          0.50196081399918, -- [3]
          1, -- [4]
        },
      },
      ["HooksTemp"] = {
      },
      ["Hooks"] = {
        ["Nameplate Added"] = "function (self, unitId, unitFrame, envTable, modTable)\n    modTable.updateInterruptId(unitFrame)\nend\n\n\n",
        ["Cast Update"] = "function (self, unitId, unitFrame, envTable, modTable)\n    unitFrame.castBar:UpdateCastColor()\nend",
        ["Player Talent Update"] = "function (self, unitId, unitFrame, envTable, modTable)\n    modTable.updateInterruptIDs()\n    modTable.updateInterruptId(unitFrame)\nend\n\n\n",
        ["Initialization"] = "function (modTable)\n    \n    -- settings:\n    local noKickReadyColor = modTable.config.noKickReadyColor or \"blue\"\n    local kickReadyInTimeColor = modTable.config.kickReadyInTimeColor or \"purple\"\n    local kickReadyInTimeGraceTime = modTable.config. kickReadyInTimeGraceTime or 0.5 --sec - additional time on the CD to account for reaction, lag, etc\n    local checkCovenant = true\n    \n    -- functions:\n    \n    -- determine interrupt spell according to spec\n    function modTable.updateInterruptIDs ()\n        local specId = GetSpecializationInfo(GetSpecialization())\n        modTable.knownSpecID = specId\n        local interruptIDs = {} -- contains: [spellID] = <is player ability>, false meaning pet or weird workarounds needed\n        if Plater.PlayerClass == \"ROGUE\" then\n            interruptIDs[1766] = true\n        elseif Plater.PlayerClass == \"DEATHKNIGHT\" then\n            interruptIDs[47528] = true\n        elseif Plater.PlayerClass == \"DEMONHUNTER\" then\n            interruptIDs[183752] = true\n        elseif Plater.PlayerClass == \"DRUID\" then\n            if specId == 103 or specId == 104 then\n                interruptIDs[106839] = true -- feral/guardian\n            elseif specId == 102 then\n                interruptIDs[78675] = true -- moonkin\n            end\n        elseif Plater.PlayerClass == \"HUNTER\" then\n            if specId == 255 then\n                interruptIDs[187707] = true -- SV\n            else\n                interruptIDs[147362] = true -- BM/MS\n            end\n        elseif Plater.PlayerClass == \"MONK\" then\n            if specId == 268 or specId == 269 then\n                interruptIDs[116705] = true --WW/BM\n            end\n        elseif Plater.PlayerClass == \"PALADIN\" then\n            if specId == 66 or specId == 70 then\n                interruptIDs[96231] = true --prot/ret\n            end\n            if specId == 66 then\n                interruptIDs[31935] = true --prot\n                if checkCovenant and IsPlayerSpell(304971) then\n                    interruptIDs[304971] = true --kyrian\n                end\n            end\n        elseif Plater.PlayerClass == \"SHAMAN\" then\n            interruptIDs[57994] = true\n        elseif Plater.PlayerClass == \"WARRIOR\" then\n            interruptIDs[6552] = true\n        elseif Plater.PlayerClass == \"MAGE\" then\n            interruptIDs[2139] = true\n        elseif Plater.PlayerClass == \"PRIEST\" then\n            if specId == 258 then\n                interruptIDs[15487] = true\n            end\n        elseif Plater.PlayerClass == \"WARLOCK\" then\n            interruptIDs[119910] = 119898 --Spell Lock (command ability)\n            if IsPlayerSpell(108503) then --GoSac\n                interruptIDs[132409] = 119898 --sacrificed Spell Lock (command ability)\n            end\n            if specId == 266 then\n                interruptIDs[119914] = 119898 --demo/fel guard  Axe Toss (command ability)\n            end\n        end\n        modTable.interruptSpellIDs = interruptIDs\n    end\n    \n    function modTable.updateInterruptId (unitFrame)\n        local specId = GetSpecializationInfo(GetSpecialization())\n        if not modTable.interruptSpellIDs or modTable.knownSpecID ~= specId then\n            modTable.updateInterruptIDs()\n        end\n        unitFrame.castBar.interruptSpellIDs = modTable.interruptSpellIDs\n    end\n    \n    function modTable.setCastColorFunction (unitFrame)\n        -- overwrite the color function:\n        unitFrame.castBar.GetCastColor = function (self)\n            \n            local interruptCD, interruptReadyInTime = nil, false\n            if self.interruptSpellIDs and UnitCanAttack(\"player\", self.unit) then\n                \n                for interruptSpellId, playerAbility in pairs(self.interruptSpellIDs) do\n                    if playerAbility == true then\n                        \n                        if IsSpellKnown(interruptSpellId) then\n                            local cdStart, cdDur =  GetSpellCooldown(interruptSpellId)\n                            local tmpInterruptCD = (cdStart > 0 and  cdDur - (GetTime() - cdStart)) or 0\n                            if not interruptCD or (tmpInterruptCD < interruptCD) then\n                                interruptCD = tmpInterruptCD\n                            end\n                        end\n                    else\n                        if type(playerAbility) == \"number\" and FindSpellOverrideByID(playerAbility) then\n                            local cdStart, cdDur =  GetSpellCooldown(interruptSpellId)\n                            local tmpInterruptCD = (cdStart > 0 and  cdDur - (GetTime() - cdStart)) or 0\n                            -- workaround for WL: assume you only have one intterrupt, so check if the CD is actually > 0. defaults to 0 later\n                            if tmpInterruptCD > 0 and (not interruptCD or (tmpInterruptCD < interruptCD)) then\n                                interruptCD = tmpInterruptCD\n                            end\n                        end\n                    end\n                end\n                \n                if not interruptCD then\n                    interruptCD = 0\n                end\n                \n                if self.channeling then\n                    interruptReadyInTime = (interruptCD + kickReadyInTimeGraceTime) < self.value\n                else\n                    interruptReadyInTime = (interruptCD + kickReadyInTimeGraceTime) < (self.maxValue - self.value)\n                end\n            end\n            \n            if not interruptCD then\n                interruptCD = 0\n            end\n            \n            if (not self.canInterrupt) then\n                return self.Colors.NonInterruptible\n                \n            elseif (self.failed) then\n                return self.Colors.Failed\n                \n            elseif (self.interrupted) then\n                return self.Colors.Interrupted\n                \n            elseif (self.finished) then\n                return self.Colors.Finished\n                \n            elseif interruptCD > 0 and interruptReadyInTime then\n                return kickReadyInTimeColor\n                \n            elseif interruptCD > 0 then\n                return noKickReadyColor\n                \n            elseif (self.channeling) then\n                return self.Colors.Channeling\n                \n            else        \n                return self.Colors.Casting\n                \n            end\n        end\n    end\n    \nend",
        ["Constructor"] = "function (self, unitId, unitFrame, envTable, modTable)\n    modTable.updateInterruptId(unitFrame)\n    modTable.setCastColorFunction(unitFrame)\nend",
      },
      ["Time"] = 1672783072,
      ["LoadConditions"] = {
        ["talent"] = {
        },
        ["group"] = {
        },
        ["class"] = {
        },
        ["map_ids"] = {
        },
        ["role"] = {
        },
        ["pvptalent"] = {
        },
        ["spec"] = {
        },
        ["race"] = {
        },
        ["encounter_ids"] = {
        },
        ["affix"] = {
        },
      },
      ["url"] = "",
      ["Icon"] = 134400,
      ["Enabled"] = false,
      ["Revision"] = 540,
      ["semver"] = "",
      ["Author"] = "Viash-Thrall",
      ["Desc"] = "Sets the cast bar color to the specified one if your interrupt spell is not ready. Uses other Plater color settings otherwise.",
      ["Prio"] = 99,
      ["version"] = -1,
      ["PlaterCore"] = 1,
      ["Options"] = {
        {
          ["Type"] = 1,
          ["Key"] = "noKickReadyColor",
          ["Value"] = {
            0, -- [1]
            0, -- [2]
            1, -- [3]
            1, -- [4]
          },
          ["Name"] = "Kick not Ready Color",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
          ["Desc"] = "",
        }, -- [1]
        {
          ["Type"] = 1,
          ["Key"] = "kickReadyInTimeColor",
          ["Value"] = {
            0.50196078431373, -- [1]
            0, -- [2]
            1, -- [3]
            1, -- [4]
          },
          ["Name"] = "Kick Ready in Time Color",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
          ["Desc"] = "",
        }, -- [2]
        {
          ["Type"] = 2,
          ["Max"] = 1,
          ["Desc"] = "",
          ["Min"] = 0,
          ["Key"] = "kickReadyInTimeGraceTime",
          ["Value"] = 0.5,
          ["Fraction"] = true,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Reaction grace Time",
        }, -- [3]
      },
      ["LastHookEdited"] = "",
      ["Name"] = "Kick Color",
    }, -- [12]
    {
      ["OptionsValues"] = {
      },
      ["HooksTemp"] = {
      },
      ["UID"] = "0x61c385cc688c4f3",
      ["Hooks"] = {
        ["Target Changed"] = "function (self, unitId, unitFrame, envTable)\n    if (not unitFrame.Kicker) then return end\n    unitFrame.Kicker:Update()\nend",
        ["Cast Stop"] = "function (self, unitId, unitFrame, envTable)\n    if (not unitFrame.Kicker) then return end\n    unitFrame.Kicker:OnCastStop()\nend",
        ["Cast Update"] = "function (self, unitId, unitFrame, envTable)\n    if (not unitFrame.Kicker) then return end\n    unitFrame.Kicker:Update()\nend",
        ["Cast Start"] = "function (self, unitId, unitFrame, envTable)\n    if (not unitFrame.Kicker) then return end\n    unitFrame.Kicker:OnCastStart()\nend",
        ["Initialization"] = "function (modTable)\n    local options = {\n        width = 10,\n        height = 8,\n        updateInterval = 0.01,\n        fontName = STANDARD_TEXT_FONT,\n        fontSize = 1,\n        fontFlags = \"OUTLINE\"\n    }\n    \n    local version = select(4, GetBuildInfo())\n    modTable.IsTBC = version > 20000 and version < 30000\n    modTable.IsWrath = version > 30000 and version < 40000\n    modTable.IsShadowlands = version > 90000 and version < 100000\n    modTable.IsDragonflight = version > 100000 and version < 110000\n    \n    local config = modTable.config or {}\n    local SHOW_STATE = config.showState or 3\n    local REACTION_SECONDS = (config.reactionMS or 100) / 1000\n    \n    local classInterrupts = nil\n    \n    -- TBC\n    if (modTable.IsTBC) then\n        -- class interrupts in ascending order because then we can reverse iterate and\n        -- get the highest rank easily\n        classInterrupts = {\n            [\"WARRIOR\"] = { 6552, 6554 },\n            [\"HUNTER\"] = { 34490 },\n            [\"ROGUE\"] = { 1766, 1767, 1768, 1769, 38768 },\n            [\"SHAMAN\"] = { 8042, 8044, 8045, 8046, 10412, 10413, 10414, 25454 },\n            [\"MAGE\"] = { 2139 }\n        }\n        -- WotLK\n    elseif (modTable.IsWrath) then\n        classInterrupts = {\n            [\"WARRIOR\"] = { 6552 },\n            [\"HUNTER\"] = { 34490 },\n            [\"ROGUE\"] = { 1766 },\n            [\"SHAMAN\"] = { 8042, 8044, 8045, 8046, 10412, 10413, 10414, 25454, 49230, 49231 },\n            [\"MAGE\"] = { 2139 }\n        }\n        -- Shadowlands and Dragonflight\n    elseif (modTable.IsShadowlands or modTable.IsDragonflight) then\n        classInterrupts = {\n            [\"WARRIOR\"] = { 6552 },\n            [\"HUNTER\"] = { 147362, 187707 },\n            [\"ROGUE\"] = { 1766 },\n            [\"SHAMAN\"] = { 57994 },\n            [\"MAGE\"] = { 2139 },\n            [\"PALADIN\"] = { 96231 },\n            [\"PRIEST\"] = { 15487 },\n            [\"DEATHKNIGHT\"] = { 47528 },\n            [\"MONK\"] = { 116705 },\n            [\"DRUID\"] = { 106839, 78675 },\n            [\"DEMONHUNTER\"] = { 183752 },\n            [\"WARLOCK\"] = { 19647, 89766 },\n            [\"EVOKER\"] = { 351338 }\n        }\n    else\n        classInterrupts = {}\n    end\n    \n    -- Only call this from the constructor or something called in the constructor\n    local _getInterruptSpellId = function()\n        local _, playerClass = UnitClass(\"player\")\n        local interrupts = classInterrupts[playerClass] or {}\n        \n        for i = #interrupts, 1, -1 do\n            local spellId = interrupts[i]\n            if (IsSpellKnown(spellId)) then\n                return spellId\n            end\n        end\n        \n        return nil\n    end\n    \n    local _isNumberForCooldownOn = function()\n        return tonumber(GetCVar(\"countdownForCooldowns\")) == 1\n    end\n    \n    local _round = function(num, numDecimalPlaces)\n        local mult = 10 ^ (numDecimalPlaces or 0)\n        return math.floor(num * mult + 0.5) / mult\n    end\n    \n    local _getInterruptCooldown = function(interruptSpellId)\n        local startTime, duration = GetSpellCooldown(interruptSpellId)\n        local _, gcdMS = GetSpellBaseCooldown(interruptSpellId)\n        if (startTime ~= 0 and duration * 1000 > gcdMS) then\n            local remaining = (startTime + duration) - GetTime()\n            return true, startTime, duration, _round(remaining, 1)\n        end\n        return false, startTime, duration, 0\n    end\n    \n    local _isValidUnit = function(unitId)\n        -- Check for invalid unitId; if it is invalid then we assume the mod shouldn't run for this unit\n        if (not unitId) then return false end\n        return UnitCanAttack(\"player\", unitId) and (UnitIsUnit(unitId, \"focus\") or UnitIsUnit(unitId, \"target\"))\n    end\n    \n    function modTable.CreateKickerHostFrame(unitFrame)\n        -- Try and acquire the interrupt spell id, if you can't then return nil\n        local interruptSpellId = _getInterruptSpellId()\n        if (not interruptSpellId) then return nil end\n        \n        local castBar = unitFrame.castBar\n        \n        local hostFrame = CreateFrame(\"frame\", castBar:GetName() .. \"Kicker\", castBar)\n        hostFrame:SetPoint(\"RIGHT\", options.width -10, 0)\n        hostFrame:SetSize(options.width, options.height)\n        \n        local fileId = GetSpellTexture(interruptSpellId)\n        local indicator = hostFrame:CreateTexture(nil, \"BACKGROUND\")\n        indicator:SetTexture(fileId)\n        indicator:SetAllPoints(true)\n        \n        local cooldown = CreateFrame(\"Cooldown\", hostFrame:GetName() .. \"Cooldown\", hostFrame, \"CooldownFrameTemplate\")\n        cooldown:SetAllPoints()\n        \n        local cooldownText = hostFrame:CreateFontString(nil, \"OVERLAY\")\n        cooldownText:SetFont(options.fontName, options.fontSize, options.fontFlags)\n        cooldownText:SetPoint(\"CENTER\")\n        cooldownText:SetTextColor(1, 0, 0, 1)\n        cooldownText:SetText(\"\")\n        \n        if (_isNumberForCooldownOn()) then\n            cooldownText:Hide()\n        end\n        \n        hostFrame.Kicker_LastUpdate = 0\n        hostFrame.Kicker_PreviousRemaining = 0\n        hostFrame.interruptSpellId = interruptSpellId\n        \n        function hostFrame:OnUpdateInternal(elapsed)\n            self.Kicker_LastUpdate = self.Kicker_LastUpdate + elapsed\n            if (self.Kicker_LastUpdate >= options.updateInterval) then\n                self.Kicker_LastUpdate = 0\n                \n                local isOnCooldown, startTime, duration, remaining = _getInterruptCooldown(self.interruptSpellId)\n                \n                if ((startTime + duration + REACTION_SECONDS) < castBar.SpellEndTime) then\n                    cooldownText:SetTextColor(0, 1, 0, 1)\n                else\n                    cooldownText:SetTextColor(1, 0, 0, 1)\n                end\n                \n                if (not isOnCooldown) then\n                    if (self.Kicker_PreviousRemaining ~= 0) then\n                        cooldown:SetCooldown(0, 0)\n                    end\n                    cooldownText:SetText(\"\")\n                    ActionButton_HideOverlayGlow(self)\n                else\n                    cooldown:SetCooldown(startTime, duration)\n                    cooldownText:SetText(string.format(\"%.1f\", remaining))\n                    ActionButton_HideOverlayGlow(self)\n                end\n                self.Kicker_PreviousRemaining = remaining\n            end\n        end\n        \n        function hostFrame:ShouldShow()\n            -- Idk why this would ever happen\n            if (not unitFrame) then\n                return false\n            end\n            \n            -- If there is no cast bar currently then we shouldn't show\n            if (not castBar) then\n                return false\n            end\n            \n            -- Check if plater provides us information to determine if the spell is interruptable\n            if (castBar.canInterrupt == false) then\n                return false\n            end\n            \n            -- First check is if it's a valid unit for this mod. Early return if not\n            local isValidUnit = _isValidUnit(unitFrame.namePlateUnitToken)\n            if (not isValidUnit) then\n                return false\n            end\n            \n            -- Always show\n            if (SHOW_STATE == 1) then\n                return true\n            end\n            \n            -- Show if interrupt not on cooldown\n            if (SHOW_STATE == 2) then\n                local isOnCooldown = _getInterruptCooldown(self.interruptSpellId)\n                return not isOnCooldown\n            end\n            \n            -- Show if interrupt not on cooldown OR will be off cooldown\n            if (SHOW_STATE == 3) then\n                local isOnCooldown, startTime, duration = _getInterruptCooldown(self.interruptSpellId)\n                local interruptCDEndTime = startTime + duration + REACTION_SECONDS\n                local spellEndTime = castBar.SpellEndTime\n                if (type(spellEndTime) ~= 'number') then\n                    return not isOnCooldown\n                end\n                return not isOnCooldown or (interruptCDEndTime < spellEndTime)\n            end\n            \n            -- Unknown show state\n            return false\n        end\n        \n        function hostFrame:OnCastStart()\n            if (self:ShouldShow()) then\n                self:Show()\n            end\n        end\n        \n        function hostFrame:OnCastStop()\n            self:Hide()\n        end\n        \n        function hostFrame:Update()\n            local isShown = self:IsShown()\n            local shouldShow = self:ShouldShow()\n            if (isShown and not shouldShow) then\n                self:Hide()\n            elseif (not isShown and shouldShow) then\n                self:Show()\n            end\n        end\n        \n        function hostFrame:OnSpecChanged()\n            hostFrame.interruptSpellId = _getInterruptSpellId()\n            return hostFrame.interruptSpellId ~= nil\n        end\n        \n        function hostFrame:OnShowInternal()\n            -- early return in the event we should not show the frame\n            if (not _isValidUnit(unitFrame.namePlateUnitToken)) then\n                self:Hide()\n                return\n            end\n            \n            -- Run this on show because it probably won't change during\n            -- short duration the hostFrame is showing.\n            local isCooldownTextShown = cooldownText:IsShown()\n            local isNumberForCooldownOn = _isNumberForCooldownOn()\n            if (isCooldownTextShown and isNumberForCooldownOn) then\n                cooldownText:Hide()\n            elseif ((not isCooldownTextShown) and (not isNumberForCooldownOn)) then\n                cooldownText:Show()\n            end\n            \n            self.Kicker_LastUpdate = 0\n            self.Kicker_PreviousRemaining = 0\n            self:SetScript(\"OnUpdate\", self.OnUpdateInternal)\n        end\n        \n        function hostFrame:OnHideInternal()\n            self:SetScript(\"OnUpdate\", nil)\n            ActionButton_HideOverlayGlow(self)\n        end\n        \n        hostFrame:SetScript(\"OnShow\", hostFrame.OnShowInternal)\n        hostFrame:SetScript(\"OnHide\", hostFrame.OnHideInternal)\n        \n        hostFrame:Hide()\n        \n        return hostFrame\n    end\nend",
        ["Constructor"] = "function(self, unitId, unitFrame, envTable, modTable)\n    unitFrame.Kicker = modTable.CreateKickerHostFrame(unitFrame)\n    if (modTable.IsDragonflight or modTable.IsShadowlands or modTable.IsWrath) then\n        local eventFrame = CreateFrame(\"frame\")\n        function eventFrame:ACTIVE_TALENT_GROUP_CHANGED(...)\n            if (unitFrame.Kicker) then\n                local success = unitFrame.Kicker:OnSpecChanged()\n                if (not success) then\n                    unitFrame.Kicker:SetParent(nil)\n                    unitFrame.Kicker:Hide()\n                    unitFrame.Kicker = nil\n                end\n            else\n                unitFrame.Kicker = modTable.CreateKickerHostFrame(unitFrame)\n            end\n        end\n        eventFrame:SetScript(\"OnEvent\", function(self, event, ...)\n                self[event](self, ...)\n        end)\n        eventFrame:RegisterEvent(\"ACTIVE_TALENT_GROUP_CHANGED\")\n        unitFrame.KickerEventFrame = eventFrame\n    end\nend",
      },
      ["Time"] = 1689714025,
      ["LoadConditions"] = {
        ["talent"] = {
        },
        ["group"] = {
        },
        ["class"] = {
        },
        ["map_ids"] = {
        },
        ["role"] = {
        },
        ["pvptalent"] = {
        },
        ["spec"] = {
        },
        ["race"] = {
        },
        ["encounter_ids"] = {
        },
        ["affix"] = {
        },
      },
      ["url"] = "https://wago.io/Qereev58q/10",
      ["Icon"] = 132219,
      ["Enabled"] = true,
      ["Revision"] = 687,
      ["semver"] = "2.0.3",
      ["Author"] = "Bensun-Sulfuras",
      ["Desc"] = "An addon that shows you kick icon next to the cast bar.",
      ["Prio"] = 1,
      ["version"] = 10,
      ["PlaterCore"] = 1,
      ["Name"] = "Kickicon in Castbar",
      ["Options"] = {
      },
      ["LastHookEdited"] = "",
    }, -- [13]
    {
      ["OptionsValues"] = {
      },
      ["HooksTemp"] = {
      },
      ["Hooks"] = {
        ["Nameplate Added"] = "function (self, unitId, unitFrame, envTable)\n    envTable.UpdateBorder (unitFrame)\nend\n\n\n",
        ["Target Changed"] = "function (self, unitId, unitFrame, envTable)\n    envTable.UpdateBorder (unitFrame)\nend\n\n\n",
        ["Destructor"] = "function (self, unitId, unitFrame, envTable)\n    if (unitFrame.healthBar.TargetBorder) then\n        unitFrame.healthBar.TargetBorder:Hide()\n    end\n    if (unitFrame.healthBar.border) then\n        Plater.UpdateBorderColor (unitFrame)\n    end\nend",
        ["Enter Combat"] = "function (self, unitId, unitFrame, envTable, modTable)\n    envTable.UpdateBorder (unitFrame)\nend\n\n\n",
        ["Constructor"] = "function (self, unitId, unitFrame, envTable, modTable)\n    \n    if (not unitFrame.healthBar.TargetBorder) then\n        unitFrame.healthBar.TargetBorder = CreateFrame (\"frame\", nil, unitFrame.healthBar, \"NamePlateFullBorderTemplate\")\n    end\n    \n    function envTable.UpdateBorder (unitFrame)      \n        if unitFrame.namePlateIsTarget then       \n            local r, g, b, a = DetailsFramework:ParseColors (Plater.db.profile.target_highlight_color)\n            unitFrame.healthBar.TargetBorder:SetVertexColor (r, g, b, a)\n            if (unitFrame.healthBar.border) then\n                unitFrame.healthBar.border:SetVertexColor (r, g, b, a)\n            end\n            local size = modTable.config.targetborderSize\n            unitFrame.healthBar.TargetBorder:SetBorderSizes (size, size, size, size)\n            unitFrame.healthBar.TargetBorder:UpdateSizes()    \n            unitFrame.healthBar.TargetBorder:Show()\n        else        \n            if (unitFrame.healthBar.border) then\n                Plater.UpdateBorderColor (unitFrame)\n            end\n            unitFrame.healthBar.TargetBorder:Hide()\n        end\n    end\nend",
      },
      ["Time"] = 1689714029,
      ["LoadConditions"] = {
        ["talent"] = {
        },
        ["group"] = {
        },
        ["class"] = {
        },
        ["map_ids"] = {
        },
        ["role"] = {
        },
        ["pvptalent"] = {
        },
        ["spec"] = {
        },
        ["race"] = {
        },
        ["encounter_ids"] = {
        },
        ["affix"] = {
        },
      },
      ["url"] = "https://wago.io/5Nwc7vGKU/3",
      ["Icon"] = "Interface\\CHATFRAME\\UI-ChatInputBorder",
      ["Enabled"] = true,
      ["Revision"] = 744,
      ["semver"] = "1.0.2",
      ["Author"] = "Izimode-Azralon",
      ["Desc"] = "Add a border around the current target.",
      ["Prio"] = 99,
      ["version"] = 3,
      ["PlaterCore"] = 1,
      ["Options"] = {
        {
          ["Type"] = 2,
          ["Max"] = 10,
          ["Desc"] = "Set target border size",
          ["Min"] = 0,
          ["Key"] = "targetborderSize",
          ["Value"] = 1,
          ["Fraction"] = true,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Border Size",
        }, -- [1]
      },
      ["LastHookEdited"] = "",
      ["Name"] = "Target Border",
    }, -- [14]
    {
      ["OptionsValues"] = {
      },
      ["HooksTemp"] = {
      },
      ["Hooks"] = {
        ["Player Logon"] = "function()\n    -- /RELOAD AFTER IMPORTING OR CHANGING THE SCRIPT\n    -- SELECT THE INDICATOR AT THE TARGET TAB\n    \n    Plater.TargetIndicators    [\"Thin Arrow\"] = {\n        path = [[Interface\\AddOns\\Plater\\media\\arrow_thin_right_64]],\n        coords = {\n            {0, 1, 0, 1}, \n            {1, 0, 0, 1}\n        },\n        desaturated = false,\n        width = 15,\n        height = 12,\n        x = 14,\n        y = 0,\n        blend = \"ADD\",\n        color =  {0.36, 0.73, 1, 0.9},\n    }    \n    \nend",
      },
      ["Time"] = 1681735107,
      ["LoadConditions"] = {
        ["talent"] = {
        },
        ["group"] = {
        },
        ["class"] = {
        },
        ["map_ids"] = {
        },
        ["role"] = {
        },
        ["pvptalent"] = {
        },
        ["spec"] = {
        },
        ["race"] = {
        },
        ["encounter_ids"] = {
        },
        ["affix"] = {
        },
      },
      ["url"] = "https://wago.io/4rFUVdRiH/1",
      ["Icon"] = "Interface\\AddOns\\Plater\\media\\arrow_thin_right_64",
      ["Enabled"] = true,
      ["Revision"] = 57,
      ["semver"] = "1.0.0",
      ["Author"] = "Xitobel-Saurfang",
      ["Desc"] = "Adds a single thin arrow to target indicator options.",
      ["Prio"] = 99,
      ["version"] = 1,
      ["PlaterCore"] = 1,
      ["Options"] = {
      },
      ["LastHookEdited"] = "",
      ["Name"] = "Arrow Thin Target",
    }, -- [15]
    {
      ["OptionsValues"] = {
        ["dotscolor"] = {
          0.80784320831299, -- [1]
          1, -- [2]
          0.086274512112141, -- [3]
          1, -- [4]
        },
      },
      ["HooksTemp"] = {
      },
      ["UID"] = "0x638cdf6a597153e",
      ["Hooks"] = {
        ["Nameplate Updated"] = "function (self, unitId, unitFrame, envTable, modTable)\n    if envTable.isFodderDemon(unitFrame.namePlateNpcId) then\n        Plater.SetNameplateColor(unitFrame, modTable.config.nameplateColor)\n    end\nend\n\n\n",
        ["Nameplate Added"] = "function (self, unitId, unitFrame, envTable, modTable)\n    if envTable.isFodderDemon(unitFrame.namePlateNpcId) then\n        Plater.SetNameplateColor(unitFrame, modTable.config.nameplateColor)\n    end\nend",
        ["Constructor"] = "function (self, unitId, unitFrame, envTable, modTable)\n    envTable.isFodderDemon = function(unitId)      \n        return unitId == 169428 \n        or unitId == 169430 \n        or unitId == 169429 \n        or unitId == 169426 \n        or unitId == 169421 \n        or unitId == 169425 \n        or unitId == 168932  \n    end    \nend",
      },
      ["Time"] = 1689714207,
      ["LoadConditions"] = {
        ["talent"] = {
        },
        ["group"] = {
        },
        ["class"] = {
          ["Enabled"] = true,
          ["DEMONHUNTER"] = true,
        },
        ["map_ids"] = {
        },
        ["role"] = {
        },
        ["pvptalent"] = {
        },
        ["spec"] = {
        },
        ["race"] = {
        },
        ["encounter_ids"] = {
        },
        ["affix"] = {
        },
      },
      ["url"] = "https://wago.io/tNEPu2FMc/2",
      ["Icon"] = 236293,
      ["Enabled"] = true,
      ["Revision"] = 89,
      ["semver"] = "1.0.1",
      ["Author"] = "Xepheris-Twisting Nether",
      ["Desc"] = "enforces the demon hunter purple for fodder demons",
      ["Prio"] = 1,
      ["version"] = 2,
      ["PlaterCore"] = 1,
      ["Name"] = "Fodder to the Flame Recolor",
      ["Options"] = {
        {
          ["Type"] = 1,
          ["Key"] = "nameplateColor",
          ["Value"] = {
            0.52941179275513, -- [1]
            1, -- [2]
            0, -- [3]
            1, -- [4]
          },
          ["Name"] = "Nameplate Color",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
          ["Desc"] = "",
        }, -- [1]
      },
      ["LastHookEdited"] = "",
    }, -- [16]
    {
      ["OptionsValues"] = {
      },
      ["HooksTemp"] = {
      },
      ["Hooks"] = {
        ["Nameplate Created"] = "function (self, unitId, unitFrame, envTable, modTable)\n    --ensure reload updates existing\n    modTable.updateExisting(unitFrame)\nend\n\n\n",
        ["Initialization"] = "function (modTable)\n    \n    \n    -- settings:\n    local formatAuraTimers = modTable.config.formatAuraTimers\n    local formatBuffSpecialTimers = modTable.config.formatBuffSpecialTimers\n    \n    \n    -- time formatting function: (can be adjusted)\n    Plater.FormatTimeNew = function (s)\n        if s < 10 then\n            return (\"%.1f\"):format(s)\n        elseif s < 60 then\n            return (\"%d\"):format(s)\n        elseif s < 3600 then\n            return (\"%d:%02d\"):format(s/60%60, s%60)\n        elseif s < 86400 then\n            return (\"%dh %02dm\"):format(s/(3600), s/60%60)\n        else\n            return (\"%dd %02dh\"):format(s/86400, (s /3600) - (floor(s/86400) * 24))\n        end\n    end\n    Plater.FormatTimeOrig = Plater.FormatTimeOrig or Plater.FormatTime\n    \n    local DF = _G[\"DetailsFramework\"]\n    local IconRowFunctions = DF.IconRowFunctions or DF.IconMixin\n    IconRowFunctions.FormatCooldownTimeOrig = IconRowFunctions.FormatCooldownTimeOrig or IconRowFunctions.FormatCooldownTime\n    \n    \n    -- exchange formatting:\n    function modTable.hookTimeFormat()\n        if formatAuraTimers then\n            Plater.FormatTime = Plater.FormatTimeNew\n        else\n            Plater.FormatTime = Plater.FormatTimeOrig\n        end\n        \n        \n        if formatBuffSpecialTimers then\n            \n            -- change time formatting for the Buff Special icons\n            if IconRowFunctions.FormatCooldownTime then\n                IconRowFunctions.FormatCooldownTime = Plater.FormatTimeNew\n            else\n                IconRowFunctions.SetIcon = function (self, spellId, borderColor, startTime, duration, forceTexture, descText, count, debuffType, caster, canStealOrPurge)\n                    \n                    local spellName, _, spellIcon\n                    \n                    if (not forceTexture) then\n                        spellName, _, spellIcon = GetSpellInfo (spellId)\n                    else\n                        spellIcon = forceTexture\n                    end\n                    \n                    if (spellIcon) then\n                        local iconFrame = self:GetIcon()\n                        iconFrame.Texture:SetTexture (spellIcon)\n                        iconFrame.Texture:SetTexCoord (unpack (self.options.texcoord))\n                        \n                        if (borderColor) then\n                            iconFrame:SetBackdropBorderColor (Plater:ParseColors (borderColor))\n                        else\n                            iconFrame:SetBackdropBorderColor (0, 0, 0 ,0)\n                        end    \n                        \n                        if (startTime) then\n                            CooldownFrame_Set (iconFrame.Cooldown, startTime, duration, true, true)\n                            \n                            if (self.options.show_text) then\n                                iconFrame.CountdownText:Show()\n                                \n                                local formattedTime = Plater.FormatTimeNew (startTime + duration - GetTime())\n                                \n                                iconFrame.CountdownText:SetPoint (self.options.text_anchor or \"center\", iconFrame, self.options.text_rel_anchor or \"center\", self.options.text_x_offset or 0, self.options.text_y_offset or 0)\n                                DF:SetFontSize (iconFrame.CountdownText, self.options.text_size)\n                                DF:SetFontFace (iconFrame.CountdownText, self.options.text_font)\n                                DF:SetFontOutline (iconFrame.CountdownText, self.options.text_outline)\n                                iconFrame.CountdownText:SetText (formattedTime)\n                                iconFrame.Cooldown:SetHideCountdownNumbers (true)\n                            else\n                                iconFrame.CountdownText:Hide()\n                                iconFrame.Cooldown:SetHideCountdownNumbers (false)\n                            end\n                        else\n                            iconFrame.CountdownText:Hide()\n                        end\n                        \n                        if (descText and self.options.desc_text) then\n                            iconFrame.Desc:Show()\n                            iconFrame.Desc:SetText (descText.text)\n                            iconFrame.Desc:SetTextColor (DF:ParseColors (descText.text_color or self.options.desc_text_color))\n                            iconFrame.Desc:SetPoint(self.options.desc_text_anchor or \"bottom\", iconFrame, self.options.desc_text_rel_anchor or \"top\", self.options.desc_text_x_offset or 0, self.options.desc_text_y_offset or 2)\n                            DF:SetFontSize (iconFrame.Desc, descText.text_size or self.options.desc_text_size)\n                            DF:SetFontFace (iconFrame.Desc, self.options.desc_text_font)\n                            DF:SetFontOutline (iconFrame.Desc, self.options.desc_text_outline)\n                        else\n                            iconFrame.Desc:Hide()\n                        end\n                        \n                        if (count and count > 1 and self.options.stack_text) then\n                            iconFrame.StackText:Show()\n                            iconFrame.StackText:SetText (count)\n                            iconFrame.StackText:SetTextColor (DF:ParseColors (self.options.desc_text_color))\n                            iconFrame.StackText:SetPoint (self.options.stack_text_anchor or \"center\", iconFrame, self.options.stack_text_rel_anchor or \"bottomright\", self.options.stack_text_x_offset or 0, self.options.stack_text_y_offset or 0)\n                            DF:SetFontSize (iconFrame.StackText, self.options.stack_text_size)\n                            DF:SetFontFace (iconFrame.StackText, self.options.stack_text_font)\n                            DF:SetFontOutline (iconFrame.StackText, self.options.stack_text_outline)\n                        else\n                            iconFrame.StackText:Hide()\n                        end\n                        \n                        if PixelUtil then\n                            PixelUtil.SetSize (iconFrame, self.options.icon_width, self.options.icon_height)\n                        else\n                            DFPixelUtil.SetSize (iconFrame, self.options.icon_width, self.options.icon_height)\n                        end\n                        iconFrame:Show()\n                        \n                        --> update the size of the frame\n                        self:SetWidth ((self.options.left_padding * 2) + (self.options.icon_padding * (self.NextIcon-2)) + (self.options.icon_width * (self.NextIcon - 1)))\n                        self:SetHeight (self.options.icon_height + (self.options.top_padding * 2))\n                        \n                        --> make information available\n                        iconFrame.spellId = spellId\n                        iconFrame.startTime = startTime\n                        iconFrame.duration = duration\n                        iconFrame.count = count\n                        iconFrame.debuffType = debuffType\n                        iconFrame.caster = caster\n                        iconFrame.canStealOrPurge = canStealOrPurge\n                        \n                        --> show the frame\n                        self:Show()\n                        \n                        return iconFrame\n                    end\n                end\n            end\n        else\n            -- no buff special\n            if IconRowFunctions.FormatCooldownTime then\n                IconRowFunctions.FormatCooldownTime = IconRowFunctions.FormatCooldownTimeOrig\n            end\n        end\n    end\n    \n    function modTable.updateExisting(unitFrame)\n        \n        if formatBuffSpecialTimers then\n            \n            -- change time formatting for the Buff Special icons\n            if unitFrame.ExtraIconFrame.FormatCooldownTime then\n                unitFrame.ExtraIconFrame.FormatCooldownTime = Plater.FormatTimeNew\n            else\n                unitFrame.ExtraIconFrame.SetIcon = function (self, spellId, borderColor, startTime, duration, forceTexture, descText, count, debuffType, caster, canStealOrPurge)\n                    \n                    local spellName, _, spellIcon\n                    \n                    if (not forceTexture) then\n                        spellName, _, spellIcon = GetSpellInfo (spellId)\n                    else\n                        spellIcon = forceTexture\n                    end\n                    \n                    if (spellIcon) then\n                        local iconFrame = self:GetIcon()\n                        iconFrame.Texture:SetTexture (spellIcon)\n                        iconFrame.Texture:SetTexCoord (unpack (self.options.texcoord))\n                        \n                        if (borderColor) then\n                            iconFrame:SetBackdropBorderColor (Plater:ParseColors (borderColor))\n                        else\n                            iconFrame:SetBackdropBorderColor (0, 0, 0 ,0)\n                        end    \n                        \n                        if (startTime) then\n                            CooldownFrame_Set (iconFrame.Cooldown, startTime, duration, true, true)\n                            \n                            if (self.options.show_text) then\n                                iconFrame.CountdownText:Show()\n                                \n                                local formattedTime = Plater.FormatTimeNew (startTime + duration - GetTime())\n                                \n                                iconFrame.CountdownText:SetPoint (self.options.text_anchor or \"center\", iconFrame, self.options.text_rel_anchor or \"center\", self.options.text_x_offset or 0, self.options.text_y_offset or 0)\n                                DF:SetFontSize (iconFrame.CountdownText, self.options.text_size)\n                                DF:SetFontFace (iconFrame.CountdownText, self.options.text_font)\n                                DF:SetFontOutline (iconFrame.CountdownText, self.options.text_outline)\n                                iconFrame.CountdownText:SetText (formattedTime)\n                                iconFrame.Cooldown:SetHideCountdownNumbers (true)\n                            else\n                                iconFrame.CountdownText:Hide()\n                                iconFrame.Cooldown:SetHideCountdownNumbers (false)\n                            end\n                        else\n                            iconFrame.CountdownText:Hide()\n                        end\n                        \n                        if (descText and self.options.desc_text) then\n                            iconFrame.Desc:Show()\n                            iconFrame.Desc:SetText (descText.text)\n                            iconFrame.Desc:SetTextColor (DF:ParseColors (descText.text_color or self.options.desc_text_color))\n                            iconFrame.Desc:SetPoint(self.options.desc_text_anchor or \"bottom\", iconFrame, self.options.desc_text_rel_anchor or \"top\", self.options.desc_text_x_offset or 0, self.options.desc_text_y_offset or 2)\n                            DF:SetFontSize (iconFrame.Desc, descText.text_size or self.options.desc_text_size)\n                            DF:SetFontFace (iconFrame.Desc, self.options.desc_text_font)\n                            DF:SetFontOutline (iconFrame.Desc, self.options.desc_text_outline)\n                        else\n                            iconFrame.Desc:Hide()\n                        end\n                        \n                        if (count and count > 1 and self.options.stack_text) then\n                            iconFrame.StackText:Show()\n                            iconFrame.StackText:SetText (count)\n                            iconFrame.StackText:SetTextColor (DF:ParseColors (self.options.desc_text_color))\n                            iconFrame.StackText:SetPoint (self.options.stack_text_anchor or \"center\", iconFrame, self.options.stack_text_rel_anchor or \"bottomright\", self.options.stack_text_x_offset or 0, self.options.stack_text_y_offset or 0)\n                            DF:SetFontSize (iconFrame.StackText, self.options.stack_text_size)\n                            DF:SetFontFace (iconFrame.StackText, self.options.stack_text_font)\n                            DF:SetFontOutline (iconFrame.StackText, self.options.stack_text_outline)\n                        else\n                            iconFrame.StackText:Hide()\n                        end\n                        \n                        if PixelUtil then\n                            PixelUtil.SetSize (iconFrame, self.options.icon_width, self.options.icon_height)\n                        else\n                            DFPixelUtil.SetSize (iconFrame, self.options.icon_width, self.options.icon_height)\n                        end\n                        iconFrame:Show()\n                        \n                        --> update the size of the frame\n                        self:SetWidth ((self.options.left_padding * 2) + (self.options.icon_padding * (self.NextIcon-2)) + (self.options.icon_width * (self.NextIcon - 1)))\n                        self:SetHeight (self.options.icon_height + (self.options.top_padding * 2))\n                        \n                        --> make information available\n                        iconFrame.spellId = spellId\n                        iconFrame.startTime = startTime\n                        iconFrame.duration = duration\n                        iconFrame.count = count\n                        iconFrame.debuffType = debuffType\n                        iconFrame.caster = caster\n                        iconFrame.canStealOrPurge = canStealOrPurge\n                        \n                        --> show the frame\n                        self:Show()\n                        \n                        return iconFrame\n                    end\n                end\n            end\n            \n        else\n            \n            if unitFrame.ExtraIconFrame.FormatCooldownTime then\n                unitFrame.ExtraIconFrame.FormatCooldownTime = IconRowFunctions.FormatCooldownTimeOrig\n            else\n                unitFrame.ExtraIconFrame.SetIcon = function (self, spellId, borderColor, startTime, duration, forceTexture, descText, count, debuffType, caster, canStealOrPurge)\n                    \n                    local spellName, _, spellIcon\n                    \n                    if (not forceTexture) then\n                        spellName, _, spellIcon = GetSpellInfo (spellId)\n                    else\n                        spellIcon = forceTexture\n                    end\n                    \n                    if (spellIcon) then\n                        local iconFrame = self:GetIcon()\n                        iconFrame.Texture:SetTexture (spellIcon)\n                        iconFrame.Texture:SetTexCoord (unpack (self.options.texcoord))\n                        \n                        if (borderColor) then\n                            iconFrame:SetBackdropBorderColor (Plater:ParseColors (borderColor))\n                        else\n                            iconFrame:SetBackdropBorderColor (0, 0, 0 ,0)\n                        end    \n                        \n                        if (startTime) then\n                            CooldownFrame_Set (iconFrame.Cooldown, startTime, duration, true, true)\n                            \n                            if (self.options.show_text) then\n                                iconFrame.CountdownText:Show()\n                                \n                                local formattedTime = Plater.FormatTimeOrig (startTime + duration - GetTime())\n                                \n                                iconFrame.CountdownText:SetPoint (self.options.text_anchor or \"center\", iconFrame, self.options.text_rel_anchor or \"center\", self.options.text_x_offset or 0, self.options.text_y_offset or 0)\n                                DF:SetFontSize (iconFrame.CountdownText, self.options.text_size)\n                                DF:SetFontFace (iconFrame.CountdownText, self.options.text_font)\n                                DF:SetFontOutline (iconFrame.CountdownText, self.options.text_outline)\n                                iconFrame.CountdownText:SetText (formattedTime)\n                                iconFrame.Cooldown:SetHideCountdownNumbers (true)\n                            else\n                                iconFrame.CountdownText:Hide()\n                                iconFrame.Cooldown:SetHideCountdownNumbers (false)\n                            end\n                        else\n                            iconFrame.CountdownText:Hide()\n                        end\n                        \n                        if (descText and self.options.desc_text) then\n                            iconFrame.Desc:Show()\n                            iconFrame.Desc:SetText (descText.text)\n                            iconFrame.Desc:SetTextColor (DF:ParseColors (descText.text_color or self.options.desc_text_color))\n                            iconFrame.Desc:SetPoint(self.options.desc_text_anchor or \"bottom\", iconFrame, self.options.desc_text_rel_anchor or \"top\", self.options.desc_text_x_offset or 0, self.options.desc_text_y_offset or 2)\n                            DF:SetFontSize (iconFrame.Desc, descText.text_size or self.options.desc_text_size)\n                            DF:SetFontFace (iconFrame.Desc, self.options.desc_text_font)\n                            DF:SetFontOutline (iconFrame.Desc, self.options.desc_text_outline)\n                        else\n                            iconFrame.Desc:Hide()\n                        end\n                        \n                        if (count and count > 1 and self.options.stack_text) then\n                            iconFrame.StackText:Show()\n                            iconFrame.StackText:SetText (count)\n                            iconFrame.StackText:SetTextColor (DF:ParseColors (self.options.desc_text_color))\n                            iconFrame.StackText:SetPoint (self.options.stack_text_anchor or \"center\", iconFrame, self.options.stack_text_rel_anchor or \"bottomright\", self.options.stack_text_x_offset or 0, self.options.stack_text_y_offset or 0)\n                            DF:SetFontSize (iconFrame.StackText, self.options.stack_text_size)\n                            DF:SetFontFace (iconFrame.StackText, self.options.stack_text_font)\n                            DF:SetFontOutline (iconFrame.StackText, self.options.stack_text_outline)\n                        else\n                            iconFrame.StackText:Hide()\n                        end\n                        \n                        if PixelUtil then\n                            PixelUtil.SetSize (iconFrame, self.options.icon_width, self.options.icon_height)\n                        else\n                            DFPixelUtil.SetSize (iconFrame, self.options.icon_width, self.options.icon_height)\n                        end\n                        iconFrame:Show()\n                        \n                        --> update the size of the frame\n                        self:SetWidth ((self.options.left_padding * 2) + (self.options.icon_padding * (self.NextIcon-2)) + (self.options.icon_width * (self.NextIcon - 1)))\n                        self:SetHeight (self.options.icon_height + (self.options.top_padding * 2))\n                        \n                        --> make information available\n                        iconFrame.spellId = spellId\n                        iconFrame.startTime = startTime\n                        iconFrame.duration = duration\n                        iconFrame.count = count\n                        iconFrame.debuffType = debuffType\n                        iconFrame.caster = caster\n                        iconFrame.canStealOrPurge = canStealOrPurge\n                        \n                        --> show the frame\n                        self:Show()\n                        \n                        return iconFrame\n                    end\n                end\n            end\n            \n        end\n        \n    end\n    \n    \n    modTable.hookTimeFormat()\n    for _, plateFrame in ipairs (Plater.GetAllShownPlates()) do\n        modTable.updateExisting(plateFrame.unitFrame)\n    end\n    \nend",
        ["Player Logon"] = "function(modTable)\n    modTable.hookTimeFormat()\nend\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n",
      },
      ["Time"] = 1689714062,
      ["LoadConditions"] = {
        ["talent"] = {
        },
        ["group"] = {
        },
        ["class"] = {
        },
        ["map_ids"] = {
        },
        ["role"] = {
        },
        ["pvptalent"] = {
        },
        ["spec"] = {
        },
        ["race"] = {
        },
        ["encounter_ids"] = {
        },
        ["affix"] = {
        },
      },
      ["url"] = "https://wago.io/mULsbUUxJ/13",
      ["Icon"] = "INTERFACE\\ICONS\\Ability_BossMagistrix_TimeWarp2",
      ["Enabled"] = true,
      ["Revision"] = 194,
      ["semver"] = "1.0.12",
      ["Author"] = "Viash-Thrall",
      ["Desc"] = "Overwrites the Plater time formatting to show second fractions.",
      ["Prio"] = 99,
      ["version"] = 13,
      ["PlaterCore"] = 1,
      ["Options"] = {
        {
          ["Type"] = 4,
          ["Key"] = "formatAuraTimers",
          ["Value"] = true,
          ["Name"] = "Format Aura Timers",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_bool",
          ["Desc"] = "",
        }, -- [1]
        {
          ["Type"] = 4,
          ["Key"] = "formatBuffSpecialTimers",
          ["Value"] = true,
          ["Name"] = "Format Buff Special Timers",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_bool",
          ["Desc"] = "",
        }, -- [2]
      },
      ["LastHookEdited"] = "",
      ["Name"] = "Detailed Time Format",
    }, -- [17]
  },
  ["extra_icon_caster_outline"] = "OUTLINE",
  ["auras_per_row_amount2"] = 4,
  ["aura_width"] = 15,
  ["health_statusbar_bgcolor"] = {
    0.04313725605607, -- [1]
    0.04313725605607, -- [2]
    0.04313725605607, -- [3]
    0.7026187479496, -- [4]
  },
  ["cast_audiocues"] = {
    [376171] = "Interface\\Addons\\SharedMedia_Causese\\sound\\CC.ogg",
    [375727] = "Interface\\Addons\\SharedMedia_Causese\\sound\\Front.ogg",
    [375251] = "Interface\\Addons\\SharedMedia_Causese\\sound\\Front.ogg",
    [397889] = "Interface\\Addons\\SharedMedia_Causese\\sound\\CC.ogg",
    [369061] = "Interface\\Addons\\SharedMedia_Causese\\sound\\Front.ogg",
    [375348] = "Interface\\Addons\\SharedMedia_Causese\\sound\\Front.ogg",
    [413607] = "Interface\\Addons\\SharedMedia_Causese\\sound\\CC.ogg",
    [396812] = "nil",
    [265019] = "Interface\\Addons\\SharedMedia_Causese\\sound\\Front.ogg",
    [375351] = "Interface\\Addons\\SharedMedia_Causese\\sound\\Front.ogg",
    [257756] = "Interface\\Addons\\SharedMedia_Causese\\sound\\CC.ogg",
    [272609] = "Interface\\Addons\\SharedMedia_Causese\\sound\\Front.ogg",
    [201226] = "Interface\\Addons\\SharedMedia_Causese\\sound\\Front.ogg",
    [265372] = "Interface\\Addons\\SharedMedia_Causese\\sound\\Front.ogg",
    [411994] = "nil",
    [255567] = "Interface\\Addons\\SharedMedia_Causese\\sound\\Front.ogg",
    [200291] = "Interface\\Addons\\SharedMedia_Causese\\sound\\CC.ogg",
    [397931] = "Interface\\Addons\\SharedMedia_Causese\\sound\\Front.ogg",
    [257870] = "Interface\\Addons\\SharedMedia_Causese\\sound\\CC.ogg",
    [412505] = "Interface\\Addons\\SharedMedia_Causese\\sound\\Front.ogg",
    [226406] = "Interface\\Addons\\SharedMedia_Causese\\sound\\Front.ogg",
    [200768] = "Interface\\Addons\\SharedMedia_Causese\\sound\\Front.ogg",
    [257426] = "Interface\\Addons\\SharedMedia_Causese\\sound\\Front.ogg",
    [375327] = "Interface\\Addons\\SharedMedia_Causese\\sound\\Front.ogg",
    [372311] = "Interface\\Addons\\SharedMedia_Causese\\sound\\Front.ogg",
    [183465] = "Interface\\Addons\\SharedMedia_Causese\\sound\\Front.ogg",
    [226296] = "Interface\\Addons\\SharedMedia_Causese\\sound\\Front.ogg",
    [396665] = "nil",
    [373742] = "Interface\\Addons\\SharedMedia_Causese\\sound\\Front.ogg",
    [209628] = "nil",
    [200913] = "Interface\\Addons\\SharedMedia_Causese\\sound\\Front.ogg",
    [412129] = "Interface\\Addons\\SharedMedia_Causese\\sound\\Front.ogg",
    [265540] = "Interface\\Addons\\SharedMedia_Causese\\sound\\CC.ogg",
    [257397] = "nil",
    [156718] = "nil",
    [269843] = "Interface\\Addons\\SharedMedia_Causese\\sound\\Front.ogg",
    [419351] = "Interface\\Addons\\SharedMedia_Causese\\sound\\Front.ogg",
    [369409] = "Interface\\Addons\\SharedMedia_Causese\\sound\\Front.ogg",
    [266209] = "nil",
    [369365] = "nil",
    [200261] = "Interface\\Addons\\SharedMedia_Causese\\sound\\Front.ogg",
    [393432] = "Interface\\Addons\\SharedMedia_Causese\\sound\\Front.ogg",
    [369675] = "nil",
    [372201] = "Interface\\Addons\\SharedMedia_Causese\\sound\\Front.ogg",
    [412215] = "Interface\\Addons\\SharedMedia_Causese\\sound\\Front.ogg",
    [200784] = "Interface\\Addons\\SharedMedia_Causese\\sound\\CC.ogg",
    [183088] = "Interface\\Addons\\SharedMedia_Causese\\sound\\Front.ogg",
    [370764] = "Interface\\Addons\\SharedMedia_Causese\\sound\\CC.ogg",
    [260793] = "Interface\\Addons\\SharedMedia_Causese\\sound\\Front.ogg",
    [268202] = "Interface\\Addons\\SharedMedia_Causese\\sound\\CC.ogg",
    [372223] = "nil",
    [426645] = "Interface\\Addons\\SharedMedia_Causese\\sound\\Front.ogg",
    [384978] = "Interface\\Addons\\SharedMedia_Causese\\sound\\Reflect.ogg",
    [200345] = "Interface\\Addons\\SharedMedia_Causese\\sound\\CC.ogg",
    [188169] = "Interface\\Addons\\SharedMedia_Causese\\sound\\Front.ogg",
    [372735] = "Interface\\Addons\\SharedMedia_Causese\\sound\\CC.ogg",
    [412200] = "Interface\\Addons\\SharedMedia_Causese\\sound\\CC.ogg",
    [169929] = "Interface\\Addons\\SharedMedia_Causese\\sound\\Front.ogg",
    [369465] = "Interface\\Addons\\SharedMedia_Causese\\sound\\CC.ogg",
    [371875] = "nil",
    [413529] = "Interface\\Addons\\SharedMedia_Causese\\sound\\Front.ogg",
    [87618] = "Interface\\Addons\\SharedMedia_Causese\\sound\\Jump.ogg",
    [377204] = "Interface\\Addons\\SharedMedia_Causese\\sound\\Front.ogg",
    [427376] = "Interface\\Addons\\SharedMedia_Causese\\sound\\CC.ogg",
    [416139] = "Interface\\Addons\\SharedMedia_Causese\\sound\\Front.ogg",
    [384524] = "Interface\\Addons\\SharedMedia_Causese\\sound\\Front.ogg",
    [412012] = "Interface\\Addons\\SharedMedia_Causese\\sound\\CC.ogg",
    [260894] = "Interface\\Addons\\SharedMedia_Causese\\sound\\Front.ogg",
    [411012] = "Interface\\Addons\\SharedMedia_Causese\\sound\\Front.ogg",
    [169179] = "Interface\\Addons\\SharedMedia_Causese\\sound\\Front.ogg",
    [193505] = "Interface\\Addons\\SharedMedia_Causese\\sound\\Front.ogg",
    [382708] = "Interface\\Addons\\SharedMedia_Causese\\sound\\Front.ogg",
    [199151] = "nil",
    [164357] = "Interface\\Addons\\SharedMedia_Causese\\sound\\Front.ogg",
    [388392] = "nil",
    [382712] = "Interface\\Addons\\SharedMedia_Causese\\sound\\Front.ogg",
    [408141] = "Interface\\Addons\\SharedMedia_Causese\\sound\\Front.ogg",
    [428293] = "Interface\\Addons\\SharedMedia_Causese\\sound\\Front.ogg",
    [375439] = "Interface\\Addons\\SharedMedia_Causese\\sound\\Front.ogg",
    [88308] = "Interface\\Addons\\SharedMedia_Causese\\sound\\Front.ogg",
    [226304] = "Interface\\Addons\\SharedMedia_Causese\\sound\\Front.ogg",
    [376170] = "Interface\\Addons\\SharedMedia_Causese\\sound\\Front.ogg",
    [253721] = "Interface\\Addons\\SharedMedia_Causese\\sound\\CC.ogg",
    [197974] = "Interface\\Addons\\SharedMedia_Causese\\sound\\Front.ogg",
    [387950] = "nil",
    [388060] = "Interface\\Addons\\SharedMedia_Causese\\sound\\Front.ogg",
  },
  ["aura2_x_offset"] = 2.5,
  ["pet_width_scale"] = 0.99999994039536,
  ["quick_hide"] = true,
  ["castbar_target_text_size"] = 7,
  ["extra_icon_timer_size"] = 7,
  ["target_highlight_color"] = {
    nil, -- [1]
    0.52156865596771, -- [2]
  },
  ["ghost_auras"] = {
    ["auras"] = {
      ["DEATHKNIGHT"] = {
        ["43"] = {
        },
        ["41"] = {
        },
        ["47"] = {
        },
        ["37"] = {
        },
        ["45"] = {
        },
        ["35"] = {
        },
        ["39"] = {
        },
        ["29"] = {
        },
        ["1"] = {
        },
        ["0"] = {
        },
        ["3"] = {
        },
        ["2"] = {
        },
        ["5"] = {
        },
        ["4"] = {
        },
        ["7"] = {
        },
        ["6"] = {
        },
        ["25"] = {
        },
        ["8"] = {
        },
        ["27"] = {
        },
        ["17"] = {
        },
        ["31"] = {
        },
        ["21"] = {
        },
        ["11"] = {
        },
        ["23"] = {
        },
        ["42"] = {
        },
        ["40"] = {
        },
        ["36"] = {
        },
        ["46"] = {
        },
        ["34"] = {
        },
        ["44"] = {
        },
        ["28"] = {
        },
        ["38"] = {
        },
        ["10"] = {
        },
        ["9"] = {
        },
        ["30"] = {
        },
        ["15"] = {
        },
        ["19"] = {
        },
        ["18"] = {
        },
        ["13"] = {
        },
        ["33"] = {
        },
        ["14"] = {
        },
        ["24"] = {
        },
        ["16"] = {
        },
        ["26"] = {
        },
        ["20"] = {
        },
        ["12"] = {
        },
        ["22"] = {
        },
        ["32"] = {
        },
      },
      ["WARRIOR"] = {
        ["43"] = {
        },
        ["41"] = {
        },
        ["47"] = {
        },
        ["37"] = {
        },
        ["45"] = {
        },
        ["35"] = {
        },
        ["39"] = {
        },
        ["29"] = {
        },
        ["1"] = {
        },
        ["0"] = {
        },
        ["3"] = {
        },
        ["2"] = {
        },
        ["5"] = {
        },
        ["4"] = {
        },
        ["7"] = {
        },
        ["6"] = {
        },
        ["25"] = {
        },
        ["8"] = {
        },
        ["27"] = {
        },
        ["17"] = {
        },
        ["31"] = {
        },
        ["21"] = {
        },
        ["11"] = {
        },
        ["23"] = {
        },
        ["42"] = {
        },
        ["40"] = {
        },
        ["36"] = {
        },
        ["46"] = {
        },
        ["34"] = {
        },
        ["44"] = {
        },
        ["28"] = {
        },
        ["38"] = {
        },
        ["10"] = {
        },
        ["9"] = {
        },
        ["30"] = {
        },
        ["15"] = {
        },
        ["19"] = {
        },
        ["18"] = {
        },
        ["13"] = {
        },
        ["33"] = {
        },
        ["14"] = {
        },
        ["24"] = {
        },
        ["16"] = {
        },
        ["26"] = {
        },
        ["20"] = {
        },
        ["12"] = {
        },
        ["22"] = {
        },
        ["32"] = {
        },
      },
      ["SHAMAN"] = {
        ["43"] = {
        },
        ["41"] = {
        },
        ["47"] = {
        },
        ["37"] = {
        },
        ["45"] = {
        },
        ["35"] = {
        },
        ["39"] = {
        },
        ["29"] = {
        },
        ["1"] = {
        },
        ["0"] = {
        },
        ["3"] = {
        },
        ["2"] = {
        },
        ["5"] = {
        },
        ["4"] = {
        },
        ["7"] = {
        },
        ["6"] = {
        },
        ["25"] = {
        },
        ["8"] = {
        },
        ["27"] = {
        },
        ["17"] = {
        },
        ["31"] = {
        },
        ["21"] = {
        },
        ["11"] = {
        },
        ["23"] = {
        },
        ["42"] = {
        },
        ["40"] = {
        },
        ["36"] = {
        },
        ["46"] = {
        },
        ["34"] = {
        },
        ["44"] = {
        },
        ["28"] = {
        },
        ["38"] = {
        },
        ["10"] = {
        },
        ["9"] = {
        },
        ["30"] = {
        },
        ["15"] = {
        },
        ["19"] = {
        },
        ["18"] = {
        },
        ["13"] = {
        },
        ["33"] = {
        },
        ["14"] = {
        },
        ["24"] = {
        },
        ["16"] = {
        },
        ["26"] = {
        },
        ["20"] = {
        },
        ["12"] = {
        },
        ["22"] = {
        },
        ["32"] = {
        },
      },
      ["MAGE"] = {
        ["43"] = {
        },
        ["41"] = {
        },
        ["47"] = {
        },
        ["37"] = {
        },
        ["45"] = {
        },
        ["35"] = {
        },
        ["39"] = {
        },
        ["29"] = {
        },
        ["1"] = {
        },
        ["0"] = {
        },
        ["3"] = {
        },
        ["2"] = {
        },
        ["5"] = {
        },
        ["4"] = {
        },
        ["7"] = {
        },
        ["6"] = {
        },
        ["25"] = {
        },
        ["8"] = {
        },
        ["27"] = {
        },
        ["17"] = {
        },
        ["31"] = {
        },
        ["21"] = {
        },
        ["11"] = {
        },
        ["23"] = {
        },
        ["42"] = {
        },
        ["40"] = {
        },
        ["36"] = {
        },
        ["46"] = {
        },
        ["34"] = {
        },
        ["44"] = {
        },
        ["28"] = {
        },
        ["38"] = {
        },
        ["10"] = {
        },
        ["9"] = {
        },
        ["30"] = {
        },
        ["15"] = {
        },
        ["19"] = {
        },
        ["18"] = {
        },
        ["13"] = {
        },
        ["33"] = {
        },
        ["14"] = {
        },
        ["24"] = {
        },
        ["16"] = {
        },
        ["26"] = {
        },
        ["20"] = {
        },
        ["12"] = {
        },
        ["22"] = {
        },
        ["32"] = {
        },
      },
      ["PRIEST"] = {
        ["43"] = {
        },
        ["41"] = {
        },
        ["47"] = {
        },
        ["37"] = {
        },
        ["45"] = {
        },
        ["35"] = {
        },
        ["39"] = {
        },
        ["29"] = {
        },
        ["1"] = {
        },
        ["0"] = {
        },
        ["3"] = {
          ["589"] = true,
          ["34914"] = true,
        },
        ["2"] = {
        },
        ["5"] = {
        },
        ["4"] = {
        },
        ["7"] = {
        },
        ["6"] = {
        },
        ["25"] = {
        },
        ["8"] = {
        },
        ["27"] = {
        },
        ["17"] = {
        },
        ["31"] = {
        },
        ["21"] = {
        },
        ["11"] = {
        },
        ["23"] = {
        },
        ["42"] = {
        },
        ["40"] = {
        },
        ["36"] = {
        },
        ["46"] = {
        },
        ["34"] = {
        },
        ["44"] = {
        },
        ["28"] = {
        },
        ["38"] = {
        },
        ["10"] = {
        },
        ["9"] = {
        },
        ["30"] = {
        },
        ["15"] = {
        },
        ["19"] = {
        },
        ["18"] = {
        },
        ["13"] = {
        },
        ["33"] = {
        },
        ["14"] = {
        },
        ["24"] = {
        },
        ["16"] = {
        },
        ["26"] = {
        },
        ["20"] = {
        },
        ["12"] = {
        },
        ["22"] = {
        },
        ["32"] = {
        },
      },
      ["ROGUE"] = {
        ["43"] = {
        },
        ["41"] = {
        },
        ["47"] = {
        },
        ["37"] = {
        },
        ["45"] = {
        },
        ["35"] = {
        },
        ["39"] = {
        },
        ["29"] = {
        },
        ["1"] = {
        },
        ["0"] = {
        },
        ["3"] = {
        },
        ["2"] = {
        },
        ["5"] = {
        },
        ["4"] = {
        },
        ["7"] = {
        },
        ["6"] = {
        },
        ["25"] = {
        },
        ["8"] = {
        },
        ["27"] = {
        },
        ["17"] = {
        },
        ["31"] = {
        },
        ["21"] = {
        },
        ["11"] = {
        },
        ["23"] = {
        },
        ["42"] = {
        },
        ["40"] = {
        },
        ["36"] = {
        },
        ["46"] = {
        },
        ["34"] = {
        },
        ["44"] = {
        },
        ["28"] = {
        },
        ["38"] = {
        },
        ["10"] = {
        },
        ["9"] = {
        },
        ["30"] = {
        },
        ["15"] = {
        },
        ["19"] = {
        },
        ["18"] = {
        },
        ["13"] = {
        },
        ["33"] = {
        },
        ["14"] = {
        },
        ["24"] = {
        },
        ["16"] = {
        },
        ["26"] = {
        },
        ["20"] = {
        },
        ["12"] = {
        },
        ["22"] = {
        },
        ["32"] = {
        },
      },
      ["EVOKER"] = {
        ["43"] = {
        },
        ["41"] = {
        },
        ["47"] = {
        },
        ["37"] = {
        },
        ["45"] = {
        },
        ["35"] = {
        },
        ["39"] = {
        },
        ["29"] = {
        },
        ["1"] = {
        },
        ["0"] = {
        },
        ["3"] = {
        },
        ["2"] = {
        },
        ["5"] = {
        },
        ["4"] = {
        },
        ["7"] = {
        },
        ["6"] = {
        },
        ["25"] = {
        },
        ["8"] = {
        },
        ["27"] = {
        },
        ["17"] = {
        },
        ["31"] = {
        },
        ["21"] = {
        },
        ["11"] = {
        },
        ["23"] = {
        },
        ["42"] = {
        },
        ["40"] = {
        },
        ["36"] = {
        },
        ["46"] = {
        },
        ["34"] = {
        },
        ["44"] = {
        },
        ["28"] = {
        },
        ["38"] = {
        },
        ["10"] = {
        },
        ["9"] = {
        },
        ["30"] = {
        },
        ["15"] = {
        },
        ["19"] = {
        },
        ["18"] = {
        },
        ["13"] = {
        },
        ["33"] = {
        },
        ["14"] = {
        },
        ["24"] = {
        },
        ["16"] = {
        },
        ["26"] = {
        },
        ["20"] = {
        },
        ["12"] = {
        },
        ["22"] = {
        },
        ["32"] = {
        },
      },
      ["WARLOCK"] = {
        ["43"] = {
        },
        ["41"] = {
        },
        ["47"] = {
        },
        ["37"] = {
        },
        ["45"] = {
        },
        ["35"] = {
        },
        ["39"] = {
        },
        ["29"] = {
        },
        ["1"] = {
          [980] = true,
          [172] = true,
        },
        ["0"] = {
        },
        ["3"] = {
        },
        ["2"] = {
        },
        ["5"] = {
        },
        ["4"] = {
        },
        ["7"] = {
        },
        ["6"] = {
        },
        ["25"] = {
        },
        ["8"] = {
        },
        ["27"] = {
        },
        ["17"] = {
        },
        ["31"] = {
        },
        ["21"] = {
        },
        ["11"] = {
        },
        ["23"] = {
        },
        ["42"] = {
        },
        ["40"] = {
        },
        ["36"] = {
        },
        ["46"] = {
        },
        ["34"] = {
        },
        ["44"] = {
        },
        ["28"] = {
        },
        ["38"] = {
        },
        ["10"] = {
        },
        ["9"] = {
        },
        ["30"] = {
        },
        ["15"] = {
        },
        ["19"] = {
        },
        ["18"] = {
        },
        ["13"] = {
        },
        ["33"] = {
        },
        ["14"] = {
        },
        ["24"] = {
        },
        ["16"] = {
        },
        ["26"] = {
        },
        ["20"] = {
        },
        ["12"] = {
        },
        ["22"] = {
        },
        ["32"] = {
        },
      },
      ["DEMONHUNTER"] = {
        ["35"] = {
        },
        ["29"] = {
        },
        ["1"] = {
        },
        ["0"] = {
        },
        ["3"] = {
        },
        ["2"] = {
        },
        ["5"] = {
        },
        ["4"] = {
        },
        ["7"] = {
        },
        ["6"] = {
        },
        ["25"] = {
        },
        ["8"] = {
        },
        ["27"] = {
        },
        ["17"] = {
        },
        ["31"] = {
        },
        ["21"] = {
        },
        ["11"] = {
        },
        ["23"] = {
        },
        ["34"] = {
        },
        ["28"] = {
        },
        ["10"] = {
        },
        ["9"] = {
        },
        ["30"] = {
        },
        ["13"] = {
        },
        ["15"] = {
        },
        ["18"] = {
        },
        ["33"] = {
        },
        ["19"] = {
        },
        ["14"] = {
        },
        ["24"] = {
        },
        ["16"] = {
        },
        ["26"] = {
        },
        ["20"] = {
        },
        ["12"] = {
        },
        ["22"] = {
        },
        ["32"] = {
        },
      },
      ["PALADIN"] = {
        ["43"] = {
        },
        ["41"] = {
        },
        ["47"] = {
        },
        ["37"] = {
        },
        ["45"] = {
        },
        ["35"] = {
        },
        ["39"] = {
        },
        ["29"] = {
        },
        ["1"] = {
        },
        ["0"] = {
        },
        ["3"] = {
        },
        ["2"] = {
        },
        ["5"] = {
        },
        ["4"] = {
        },
        ["7"] = {
        },
        ["6"] = {
        },
        ["25"] = {
        },
        ["8"] = {
        },
        ["27"] = {
        },
        ["17"] = {
        },
        ["31"] = {
        },
        ["21"] = {
        },
        ["11"] = {
        },
        ["23"] = {
        },
        ["42"] = {
        },
        ["40"] = {
        },
        ["36"] = {
        },
        ["46"] = {
        },
        ["34"] = {
        },
        ["44"] = {
        },
        ["28"] = {
        },
        ["38"] = {
        },
        ["10"] = {
        },
        ["9"] = {
        },
        ["30"] = {
        },
        ["15"] = {
        },
        ["19"] = {
        },
        ["18"] = {
        },
        ["13"] = {
        },
        ["33"] = {
        },
        ["14"] = {
        },
        ["24"] = {
        },
        ["16"] = {
        },
        ["26"] = {
        },
        ["20"] = {
        },
        ["12"] = {
        },
        ["22"] = {
        },
        ["32"] = {
        },
      },
      ["DRUID"] = {
        ["43"] = {
        },
        ["51"] = {
        },
        ["41"] = {
        },
        ["47"] = {
        },
        ["37"] = {
        },
        ["45"] = {
        },
        ["57"] = {
        },
        ["59"] = {
        },
        ["49"] = {
        },
        ["39"] = {
        },
        ["29"] = {
        },
        ["53"] = {
        },
        ["1"] = {
        },
        ["0"] = {
        },
        ["3"] = {
        },
        ["2"] = {
        },
        ["19"] = {
        },
        ["4"] = {
        },
        ["7"] = {
        },
        ["6"] = {
        },
        ["9"] = {
        },
        ["15"] = {
        },
        ["27"] = {
        },
        ["17"] = {
        },
        ["13"] = {
        },
        ["21"] = {
        },
        ["11"] = {
        },
        ["23"] = {
        },
        ["42"] = {
        },
        ["52"] = {
        },
        ["40"] = {
        },
        ["50"] = {
        },
        ["54"] = {
        },
        ["46"] = {
        },
        ["34"] = {
        },
        ["44"] = {
        },
        ["48"] = {
        },
        ["58"] = {
        },
        ["28"] = {
        },
        ["38"] = {
        },
        ["55"] = {
        },
        ["35"] = {
        },
        ["5"] = {
        },
        ["25"] = {
        },
        ["8"] = {
        },
        ["31"] = {
        },
        ["33"] = {
        },
        ["36"] = {
        },
        ["56"] = {
        },
        ["18"] = {
        },
        ["10"] = {
        },
        ["30"] = {
        },
        ["14"] = {
        },
        ["24"] = {
        },
        ["16"] = {
        },
        ["26"] = {
        },
        ["20"] = {
        },
        ["12"] = {
        },
        ["22"] = {
        },
        ["32"] = {
        },
      },
      ["MONK"] = {
        ["43"] = {
        },
        ["41"] = {
        },
        ["47"] = {
        },
        ["37"] = {
        },
        ["45"] = {
        },
        ["35"] = {
        },
        ["39"] = {
        },
        ["29"] = {
        },
        ["1"] = {
        },
        ["0"] = {
        },
        ["3"] = {
        },
        ["2"] = {
        },
        ["5"] = {
        },
        ["4"] = {
        },
        ["7"] = {
        },
        ["6"] = {
        },
        ["25"] = {
        },
        ["8"] = {
        },
        ["27"] = {
        },
        ["17"] = {
        },
        ["31"] = {
        },
        ["21"] = {
        },
        ["11"] = {
        },
        ["23"] = {
        },
        ["42"] = {
        },
        ["40"] = {
        },
        ["36"] = {
        },
        ["46"] = {
        },
        ["34"] = {
        },
        ["44"] = {
        },
        ["28"] = {
        },
        ["38"] = {
        },
        ["10"] = {
        },
        ["9"] = {
        },
        ["30"] = {
        },
        ["15"] = {
        },
        ["19"] = {
        },
        ["18"] = {
        },
        ["13"] = {
        },
        ["33"] = {
        },
        ["14"] = {
        },
        ["24"] = {
        },
        ["16"] = {
        },
        ["26"] = {
        },
        ["20"] = {
        },
        ["12"] = {
        },
        ["22"] = {
        },
        ["32"] = {
        },
      },
      ["HUNTER"] = {
        ["43"] = {
        },
        ["41"] = {
        },
        ["47"] = {
        },
        ["37"] = {
        },
        ["45"] = {
        },
        ["35"] = {
        },
        ["39"] = {
        },
        ["29"] = {
        },
        ["1"] = {
        },
        ["0"] = {
        },
        ["3"] = {
        },
        ["2"] = {
        },
        ["5"] = {
        },
        ["4"] = {
        },
        ["7"] = {
        },
        ["6"] = {
        },
        ["25"] = {
        },
        ["8"] = {
        },
        ["27"] = {
        },
        ["17"] = {
        },
        ["31"] = {
        },
        ["21"] = {
        },
        ["11"] = {
        },
        ["23"] = {
        },
        ["42"] = {
        },
        ["40"] = {
        },
        ["36"] = {
        },
        ["46"] = {
        },
        ["34"] = {
        },
        ["44"] = {
        },
        ["28"] = {
        },
        ["38"] = {
        },
        ["10"] = {
        },
        ["9"] = {
        },
        ["30"] = {
        },
        ["15"] = {
        },
        ["19"] = {
        },
        ["18"] = {
        },
        ["13"] = {
        },
        ["33"] = {
        },
        ["14"] = {
        },
        ["24"] = {
        },
        ["16"] = {
        },
        ["26"] = {
        },
        ["20"] = {
        },
        ["12"] = {
        },
        ["22"] = {
        },
        ["32"] = {
        },
      },
    },
  },
  ["extra_icon_stack_outline"] = "OUTLINE",
  ["resources"] = {
    ["y_offset"] = 1,
    ["y_offset_target"] = 9,
    ["scale"] = 0.79999995231628,
  },
  ["click_space"] = {
    130, -- [1]
    30, -- [2]
  },
  ["extra_icon_auras"] = {
    277242, -- [1]
  },
  ["aura2_grow_direction"] = 3,
  ["castbar_target_outline"] = "NONE",
  ["cast_statusbar_fadeout_time"] = 0.48999997973442,
  ["health_animation_time_dilatation"] = 2.8699998855591,
  ["color_override_colors"] = {
    [3] = {
      0.61568629741669, -- [1]
      0.18823531270027, -- [2]
      0.21176472306252, -- [3]
    },
    [4] = {
      0.77647066116333, -- [1]
      0.69803923368454, -- [2]
      0.46666669845581, -- [3]
    },
    [5] = {
      0.39607846736908, -- [1]
      0.65098041296005, -- [2]
      0.39607846736908, -- [3]
    },
  },
  ["cast_statusbar_spark_texture"] = "Interface\\AddOns\\Plater\\images\\spark8",
  ["cast_statusbar_spark_color"] = {
    0.98823529411765, -- [1]
    [3] = 0.94117647058823,
  },
  ["castbar_framelevel"] = 0,
  ["cast_statusbar_spark_alpha"] = 0.71999996900558,
  ["target_shady_enabled"] = false,
  ["pet_height_scale"] = 0.99999994039536,
  ["aura_x_offset"] = 0,
  ["first_run3"] = true,
  ["aura_breakline_space"] = 4,
  ["ui_parent_scale_tune"] = 1.6700000762939,
  ["ui_parent_buff_strata"] = "LOW",
  ["healthbar_framelevel"] = 0,
  ["health_statusbar_bgtexture"] = "Melli",
  ["indicator_raidmark_anchor"] = {
    ["y"] = 0.4000015258789063,
    ["x"] = 16,
    ["side"] = 10,
  },
  ["tank"] = {
    ["colors"] = {
      ["pulling_from_tank"] = {
        nil, -- [1]
        0.56078433990479, -- [2]
        0.55686277151108, -- [3]
      },
      ["aggro"] = {
        0, -- [1]
        0.71372550725937, -- [2]
      },
      ["nocombat"] = {
        0.61568629741669, -- [1]
        0.18823531270027, -- [2]
        0.21176472306252, -- [3]
      },
      ["noaggro"] = {
        0.61568629741669, -- [1]
        0.18823531270027, -- [2]
        0.21176472306252, -- [3]
      },
      ["pulling"] = {
        0.69019609689713, -- [1]
        0.6235294342041, -- [2]
        1, -- [3]
      },
    },
  },
  ["aura_tracker"] = {
    ["buff_banned"] = {
      ["333553"] = true,
      ["281242"] = true,
      ["61573"] = true,
      ["206150"] = true,
      ["61574"] = true,
    },
    ["debuff_banned"] = {
      ["331653"] = true,
      ["330911"] = true,
      ["299151"] = true,
      ["327980"] = true,
      ["284678"] = true,
      ["281242"] = true,
      ["342938"] = true,
      ["340007"] = true,
    },
    ["debuff"] = {
      224991, -- [1]
      277950, -- [2]
    },
    ["debuff_tracked"] = {
      ["341408"] = true,
      ["324652"] = false,
      ["342938"] = true,
      ["281242"] = true,
    },
    ["buff_tracked"] = {
      ["280001"] = true,
      ["297133"] = true,
      ["328501"] = false,
      ["227931"] = true,
      ["163689"] = true,
      ["233210"] = true,
      ["329181"] = false,
    },
  },
  ["extra_icon_caster_font"] = "Cronix",
  ["castbar_target_show"] = true,
  ["cast_statusbar_color"] = {
    0, -- [1]
    0.71372550725937, -- [2]
    1, -- [3]
    1, -- [4]
  },
  ["update_throttle"] = 0.099999994039536,
  ["patch_version"] = 31,
  ["castbar_icon_show"] = false,
  ["indicator_extra_raidmark"] = false,
  ["extra_icon_timer_font"] = "Cronix-Bold",
  ["not_affecting_combat_alpha"] = 0.3999999761581421,
  ["use_health_animation"] = true,
  ["target_highlight_alpha"] = 1,
  ["news_frame"] = {
    ["PlaterNewsFrame"] = {
      ["scale"] = 1,
    },
  },
  ["target_shady_combat_only"] = false,
  ["aura_sort"] = true,
  ["target_shady_alpha"] = 0.2999999821186066,
  ["hover_highlight_alpha"] = 0.29999998211861,
  ["tap_denied_color"] = {
    0.60392159223557, -- [1]
    0.60392159223557, -- [2]
    0.60392159223557, -- [3]
  },
  ["bossmod_icons_anchor"] = {
    ["y"] = 0,
  },
  ["target_highlight_height"] = 18,
  ["indicator_quest"] = false,
  ["version"] = 24,
  ["first_run2"] = true,
  ["aura_cooldown_reverse"] = false,
  ["extra_icon_auras_mine"] = {
    ["277242"] = false,
    ["224991"] = true,
  },
  ["aura_height2"] = 10,
  ["cast_statusbar_color_interrupted"] = {
    0.61568629741669, -- [1]
    0.18823531270027, -- [2]
    0.21176472306252, -- [3]
  },
  ["no_spellname_length_limit"] = true,
  ["range_check_in_range_or_target_alpha"] = 0.89999997615814,
  ["aura_timer_text_size"] = 7,
  ["buff_frame_anchor_and_size_migrated"] = true,
  ["number_region_first_run"] = true,
  ["script_data_trash"] = {
    {
      ["ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    function envTable.UpdateMarkers(unitFrame)\n        local npcID = envTable._NpcID\n        if not npcID then \n            if (unitFrame.healthMarker) then\n                unitFrame.healthMarker:Hide()\n                unitFrame.healthOverlay:Hide()\n            end\n            return \n        end\n        \n        local _, zoneType, diff = GetInstanceInfo()\n        local markersTable = zoneType == \"raid\" and scriptTable.Difficulty[diff][npcID] or scriptTable.lifePercent[npcID]\n        \n        if (markersTable) then\n            for _, p in ipairs(markersTable) do\n                if (envTable._HealthPercent > p) then\n                    local healthBar = unitFrame.healthBar\n                    local overlaySize = healthBar:GetWidth() * p/100\n                    \n                    if (not unitFrame.healthMarker) then\n                        unitFrame.healthMarker = healthBar:CreateTexture(nil, \"overlay\")\n                        unitFrame.healthMarker:SetColorTexture(1, 1, 1)\n                        unitFrame.healthOverlay = healthBar:CreateTexture(nil, \"overlay\")\n                        unitFrame.healthOverlay:SetColorTexture(1, 1, 1)\n                    end\n                    \n                    unitFrame.healthMarker:Show()\n                    unitFrame.healthMarker:SetSize(1, healthBar:GetHeight())\n                    unitFrame.healthMarker:SetPoint(\"left\", healthBar, \"left\", overlaySize, 0)\n                    unitFrame.healthMarker:SetVertexColor(Plater:ParseColors(scriptTable.config.indicatorColor))\n                    \n                    unitFrame.healthOverlay:Show()\n                    unitFrame.healthOverlay:SetSize(overlaySize, healthBar:GetHeight())\n                    unitFrame.healthOverlay:SetPoint(\"right\", unitFrame.healthMarker, \"left\", 0, 0)\n                    unitFrame.healthOverlay:SetVertexColor(Plater:ParseColors(scriptTable.config.fillColor))\n                    unitFrame.healthOverlay:SetAlpha(scriptTable.config.fillAlpha)\n                    \n                    return\n                end\n            end\n            \n            if (unitFrame.healthMarker) then\n                unitFrame.healthMarker:Hide()\n                unitFrame.healthOverlay:Hide()\n            end\n        end\n    end\nend",
      ["OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    if (unitFrame.healthMarker) then\n        unitFrame.healthMarker:Hide()\n        unitFrame.healthOverlay:Hide()\n    end\nend\n\n\n\n",
      ["OptionsValues"] = {
        ["fillColor"] = {
          1, -- [1]
          1, -- [2]
          1, -- [3]
          1, -- [4]
        },
        ["indicatorAlpha"] = 0.798833966255188,
        ["fillAlpha"] = 0.1540231704711914,
      },
      ["Temp_OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    if unitFrame.IsSelf or (Plater.ZoneInstanceType == \"arena\" or Plater.ZoneInstanceType == \"pvp\") then return end\n    \n    envTable.UpdateMarkers(unitFrame)    \nend    \n\n\n",
      ["ScriptType"] = 3,
      ["__TrashAt"] = 1698536504,
      ["Time"] = 1693227024,
      ["Temp_Initialization"] = "function (scriptTable)\n    \n    scriptTable.lifePercent = {\n        -- Azure Vault\n        [186738] = {75, 50, 25}, -- Umbrelskul\n        \n        -- Court of Stars\n        [104215] = {25}, -- Patrol Captain Gerdo\n        \n        -- Halls of Valor\n        [94960] = {10}, -- Hymdall\n        [95674] = {60}, -- Fenryr\n        [95676] = {80}, -- Odyn\n        \n        -- Nokhud Offensive\n        [186151] = {60}, -- Balakar Khan\n        \n        -- Ruby Life Pools\n        [188252] = {75, 45}, -- Melidrussa\n        [190484] = {50}, -- Kyrakka\n        [197697] = {50}, -- Flamegullet\n        \n        -- Shadowmoon Burial Grounds\n        [76057] = {20}, -- Carrion Worm\n        \n        -- Temple of the Jade Serpent\n        [56732] = {70, 30}, -- Liu Flameheart\n        [59544] = {50}, -- The Nodding Tiger\n        \n        -- Vault of the Incarnates\n        [187967] = {5}, -- Sennarth\n        [189492] = {65}, -- Raszageth\n        \n        -- Neltharion's Lair\n        [91005] = {20}, -- Naraxas\n        \n        -- Neltharus\n        [194816] = {10}, -- Forgewrought Monstrosity\n        \n        -- Freehold\n        [129732] = {75}, -- Skycap'n Kragg\n        [126983] = {60, 30}, -- Harlan Sweete\n        \n        -- Uldaman\n        [184020] = {40}, -- Hulking Berserker\n        [184422] = {70, 30}, -- Emberon\n        [184580] = {10}, -- Olaf\n        [184581] = {10}, -- Baelog\n        [184582] = {10}, -- Eric \"The Swift\"\n        \n        -- Brackenhide Hollow\n        [185508] = {15}, -- Claw Fighter \n        [185528] = {15}, -- Trickclaw Mystic\n        [185534] = {15}, -- Bonebolt Hunter\n        [186121] = {4}, -- Decatriarch Wratheye \n        [186122] = {15}, -- Rira Hackclaw\n        [186124] = {15}, -- Gashtooth\n        [186125] = {15}, -- Tricktotem\n        [186206] = {15}, -- Cruel Bonecrusher\n        [186227] = {20}, -- Monstrous Decay\n        \n        -- Halls of Infusion\n        [189719] = {15}, -- Watcher Irideus\n        [190368] = {40}, -- Flamecaller Aymi\n        [190407] = {20}, -- Aqua Rager\n        \n        -- Abberus\n        [201261] = {80, 60, 40}, -- Kazzara\n    }\n    \n    scriptTable.Difficulty = {\n        [16] = { -- Mythic\n        },       \n        [15] = { -- Heroic\n        },       \n        [14] = { -- Normal\n        }, \n        [17] = { -- LFR\n        }, \n    }\nend",
      ["url"] = "https://wago.io/7DvxkttTL/26",
      ["Temp_ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    function envTable.UpdateMarkers(unitFrame)\n        local npcID = envTable._NpcID\n        if not npcID then \n            if (unitFrame.healthMarker) then\n                unitFrame.healthMarker:Hide()\n                unitFrame.healthOverlay:Hide()\n            end\n            return \n        end\n        \n        local _, zoneType, diff = GetInstanceInfo()\n        local markersTable = zoneType == \"raid\" and scriptTable.Difficulty[diff][npcID] or scriptTable.lifePercent[npcID]\n        \n        if (markersTable) then\n            for _, p in ipairs(markersTable) do\n                if (envTable._HealthPercent > p) then\n                    local healthBar = unitFrame.healthBar\n                    local overlaySize = healthBar:GetWidth() * p/100\n                    \n                    if (not unitFrame.healthMarker) then\n                        unitFrame.healthMarker = healthBar:CreateTexture(nil, \"overlay\")\n                        unitFrame.healthMarker:SetColorTexture(1, 1, 1)\n                        unitFrame.healthOverlay = healthBar:CreateTexture(nil, \"overlay\")\n                        unitFrame.healthOverlay:SetColorTexture(1, 1, 1)\n                    end\n                    \n                    unitFrame.healthMarker:Show()\n                    unitFrame.healthMarker:SetSize(1, healthBar:GetHeight())\n                    unitFrame.healthMarker:SetPoint(\"left\", healthBar, \"left\", overlaySize, 0)\n                    unitFrame.healthMarker:SetVertexColor(Plater:ParseColors(scriptTable.config.indicatorColor))\n                    \n                    unitFrame.healthOverlay:Show()\n                    unitFrame.healthOverlay:SetSize(overlaySize, healthBar:GetHeight())\n                    unitFrame.healthOverlay:SetPoint(\"right\", unitFrame.healthMarker, \"left\", 0, 0)\n                    unitFrame.healthOverlay:SetVertexColor(Plater:ParseColors(scriptTable.config.fillColor))\n                    unitFrame.healthOverlay:SetAlpha(scriptTable.config.fillAlpha)\n                    \n                    return\n                end\n            end\n            \n            if (unitFrame.healthMarker) then\n                unitFrame.healthMarker:Hide()\n                unitFrame.healthOverlay:Hide()\n            end\n        end\n    end\nend",
      ["Icon"] = "Interface\\Addons\\Plater\\images\\health_indicator",
      ["Enabled"] = true,
      ["Temp_OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    if (unitFrame.healthMarker) then\n        unitFrame.healthMarker:Hide()\n        unitFrame.healthOverlay:Hide()\n    end\nend\n\n\n\n",
      ["Revision"] = 1512,
      ["semver"] = "1.3.3",
      ["Desc"] = "Place a marker into the health bar to indicate when the unit will change phase or cast an important spell.",
      ["Temp_UpdateCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    if unitFrame.IsSelf or (Plater.ZoneInstanceType == \"arena\" or Plater.ZoneInstanceType == \"pvp\") then return end\n    \n    envTable.UpdateMarkers(unitFrame)    \nend    \n\n\n",
      ["Author"] = "Aelerolor-Torghast",
      ["Initialization"] = "function (scriptTable)\n    \n    scriptTable.lifePercent = {\n        -- Azure Vault\n        [186738] = {75, 50, 25}, -- Umbrelskul\n        \n        -- Court of Stars\n        [104215] = {25}, -- Patrol Captain Gerdo\n        \n        -- Halls of Valor\n        [94960] = {10}, -- Hymdall\n        [95674] = {60}, -- Fenryr\n        [95676] = {80}, -- Odyn\n        \n        -- Nokhud Offensive\n        [186151] = {60}, -- Balakar Khan\n        \n        -- Ruby Life Pools\n        [188252] = {75, 45}, -- Melidrussa\n        [190484] = {50}, -- Kyrakka\n        [197697] = {50}, -- Flamegullet\n        \n        -- Shadowmoon Burial Grounds\n        [76057] = {20}, -- Carrion Worm\n        \n        -- Temple of the Jade Serpent\n        [56732] = {70, 30}, -- Liu Flameheart\n        [59544] = {50}, -- The Nodding Tiger\n        \n        -- Vault of the Incarnates\n        [187967] = {5}, -- Sennarth\n        [189492] = {65}, -- Raszageth\n        \n        -- Neltharion's Lair\n        [91005] = {20}, -- Naraxas\n        \n        -- Neltharus\n        [194816] = {10}, -- Forgewrought Monstrosity\n        \n        -- Freehold\n        [129732] = {75}, -- Skycap'n Kragg\n        [126983] = {60, 30}, -- Harlan Sweete\n        \n        -- Uldaman\n        [184020] = {40}, -- Hulking Berserker\n        [184422] = {70, 30}, -- Emberon\n        [184580] = {10}, -- Olaf\n        [184581] = {10}, -- Baelog\n        [184582] = {10}, -- Eric \"The Swift\"\n        \n        -- Brackenhide Hollow\n        [185508] = {15}, -- Claw Fighter \n        [185528] = {15}, -- Trickclaw Mystic\n        [185534] = {15}, -- Bonebolt Hunter\n        [186121] = {4}, -- Decatriarch Wratheye \n        [186122] = {15}, -- Rira Hackclaw\n        [186124] = {15}, -- Gashtooth\n        [186125] = {15}, -- Tricktotem\n        [186206] = {15}, -- Cruel Bonecrusher\n        [186227] = {20}, -- Monstrous Decay\n        \n        -- Halls of Infusion\n        [189719] = {15}, -- Watcher Irideus\n        [190368] = {40}, -- Flamecaller Aymi\n        [190407] = {20}, -- Aqua Rager\n        \n        -- Abberus\n        [201261] = {80, 60, 40}, -- Kazzara\n    }\n    \n    scriptTable.Difficulty = {\n        [16] = { -- Mythic\n        },       \n        [15] = { -- Heroic\n        },       \n        [14] = { -- Normal\n        }, \n        [17] = { -- LFR\n        }, \n    }\nend",
      ["OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    if unitFrame.IsSelf or (Plater.ZoneInstanceType == \"arena\" or Plater.ZoneInstanceType == \"pvp\") then return end\n    \n    envTable.UpdateMarkers(unitFrame)    \nend    \n\n\n",
      ["SpellIds"] = {
      },
      ["Prio"] = 99,
      ["version"] = 26,
      ["PlaterCore"] = 1,
      ["Name"] = "Add - Health Markers [OPS]",
      ["Options"] = {
        {
          ["Type"] = 5,
          ["Name"] = "Option 1",
          ["Value"] = "Add markers into the health bar to remind you about boss abilities at life percent.",
          ["Key"] = "option1",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_label",
          ["Desc"] = "",
        }, -- [1]
        {
          ["Type"] = 1,
          ["Name"] = "Vertical Line Color",
          ["Value"] = {
            1, -- [1]
            1, -- [2]
            1, -- [3]
            1, -- [4]
          },
          ["Key"] = "indicatorColor",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
          ["Desc"] = "Indicator color.",
        }, -- [2]
        {
          ["Type"] = 2,
          ["Max"] = 1,
          ["Desc"] = "Indicator alpha.",
          ["Min"] = 0.1,
          ["Fraction"] = true,
          ["Value"] = 0.85,
          ["Key"] = "indicatorAlpha",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Vertical Line Alpha",
        }, -- [3]
        {
          ["Type"] = 6,
          ["Name"] = "blank line",
          ["Value"] = 0,
          ["Key"] = "",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [4]
        {
          ["Type"] = 1,
          ["Name"] = "Fill Color",
          ["Value"] = {
            0, -- [1]
            0, -- [2]
            0, -- [3]
            1, -- [4]
          },
          ["Key"] = "fillColor",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
          ["Desc"] = "Fill color.",
        }, -- [5]
        {
          ["Type"] = 2,
          ["Max"] = 1,
          ["Desc"] = "Fill alpha.",
          ["Min"] = 0,
          ["Fraction"] = true,
          ["Value"] = 0.5,
          ["Key"] = "fillAlpha",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Fill Alpha",
        }, -- [6]
      },
      ["NpcNames"] = {
        "56732", -- [1]
        "59544", -- [2]
        "76057", -- [3]
        "91005", -- [4]
        "94960", -- [5]
        "95674", -- [6]
        "95676", -- [7]
        "104215", -- [8]
        "126983", -- [9]
        "129723", -- [10]
        "184020", -- [11]
        "184422", -- [12]
        "184580", -- [13]
        "184581", -- [14]
        "184582", -- [15]
        "185508", -- [16]
        "185528", -- [17]
        "185534", -- [18]
        "186121", -- [19]
        "186122", -- [20]
        "186124", -- [21]
        "186125", -- [22]
        "186151", -- [23]
        "186206", -- [24]
        "186227", -- [25]
        "186738", -- [26]
        "187967", -- [27]
        "188252", -- [28]
        "189492", -- [29]
        "189719", -- [30]
        "190368", -- [31]
        "190407", -- [32]
        "190484", -- [33]
        "194816", -- [34]
        "197697", -- [35]
        "201261", -- [36]
      },
      ["UpdateCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    if unitFrame.IsSelf or (Plater.ZoneInstanceType == \"arena\" or Plater.ZoneInstanceType == \"pvp\") then return end\n    \n    envTable.UpdateMarkers(unitFrame)    \nend    \n\n\n",
    }, -- [1]
    {
      ["ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    --create a texture to use for a flash behind the cast bar\n    local backGroundFlashTexture = Plater:CreateImage (self, [[Interface\\ACHIEVEMENTFRAME\\UI-Achievement-Alert-Glow]], self:GetWidth()+40, self:GetHeight()+20, \"background\", {0, 400/512, 0, 170/256})\n    backGroundFlashTexture:SetBlendMode (\"ADD\")\n    backGroundFlashTexture:SetDrawLayer(\"OVERLAY\", 7)\n    backGroundFlashTexture:SetPoint (\"center\", self, \"center\")\n    backGroundFlashTexture:SetVertexColor(Plater:ParseColors(scriptTable.config.flashColor))\n    backGroundFlashTexture:Hide()\n    \n    --create the animation hub to hold the flash animation sequence\n    envTable.BackgroundFlash = envTable.BackgroundFlash or Plater:CreateAnimationHub (backGroundFlashTexture, \n        function()\n            backGroundFlashTexture:Show()\n        end,\n        function()\n            backGroundFlashTexture:Hide()\n        end\n    )\n    \n    --create the flash animation sequence\n    local fadeIn = Plater:CreateAnimation (envTable.BackgroundFlash, \"ALPHA\", 1, scriptTable.config.flashDuration/2, 0, 1)\n    local fadeOut = Plater:CreateAnimation (envTable.BackgroundFlash, \"ALPHA\", 2, scriptTable.config.flashDuration/2, 1, 0)\n    \n    --create a camera shake for the nameplate\n    envTable.FrameShake = Plater:CreateFrameShake (unitFrame, scriptTable.config.shakeDuration, scriptTable.config.shakeAmplitude, scriptTable.config.shakeFrequency, false, false, 0, 1, 0.05, 0.1, Plater.GetPoints (unitFrame))\n    \n    --update the config for the flash here so it wont need a /reload\n    fadeIn:SetDuration (scriptTable.config.flashDuration/2)\n    fadeOut:SetDuration (scriptTable.config.flashDuration/2)\n    \n    --update the config for the skake here so it wont need a /reload\n    envTable.FrameShake.OriginalAmplitude = scriptTable.config.shakeAmplitude\n    envTable.FrameShake.OriginalDuration = scriptTable.config.shakeDuration\n    envTable.FrameShake.OriginalFrequency = scriptTable.config.shakeFrequency\nend",
      ["OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    Plater.StopDotAnimation(unitFrame.castBar, envTable.dotAnimation)    \n    \n    envTable.BackgroundFlash:Stop()\n    \n    unitFrame:StopFrameShake (envTable.FrameShake)    \n    \nend\n\n\n",
      ["OptionsValues"] = {
      },
      ["Temp_OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    envTable.dotAnimation = Plater.PlayDotAnimation(unitFrame.castBar, 5, scriptTable.config.dotColor, scriptTable.config.xOffset, scriptTable.config.yOffset)\n    \n    envTable.BackgroundFlash:Play()\n    \n    Plater.FlashNameplateBorder (unitFrame, 0.05)   \n    Plater.FlashNameplateBody (unitFrame, \"\", 0.075)\n    \n    unitFrame:PlayFrameShake (envTable.FrameShake)\n    \n    Plater.SetCastBarColorForScript(self, scriptTable.config.useCastbarColor, scriptTable.config.castBarColor, envTable)\n    \n    --Dominator on Shadowmoon Burial Grounds\n    if (envTable._SpellID == 154327) then\n        if (UnitHealth(unitId) == UnitHealthMax(unitId)) then\n            if (envTable._Duration == 604800) then\n                Plater.SetCastBarColorForScript(self, scriptTable.config.useCastbarColor, {1, 0, 0, 1}, envTable)\n            end\n        end\n    end\nend",
      ["ScriptType"] = 2,
      ["UpdateCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \nend\n\n\n",
      ["Time"] = 1698536823,
      ["NpcNames"] = {
      },
      ["Temp_OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    Plater.StopDotAnimation(unitFrame.castBar, envTable.dotAnimation)    \n    \n    envTable.BackgroundFlash:Stop()\n    \n    unitFrame:StopFrameShake (envTable.FrameShake)    \n    \nend\n\n\n",
      ["url"] = "",
      ["Icon"] = "Interface\\AddOns\\Plater\\images\\cast_bar_darkorange",
      ["OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    envTable.dotAnimation = Plater.PlayDotAnimation(unitFrame.castBar, 5, scriptTable.config.dotColor, scriptTable.config.xOffset, scriptTable.config.yOffset)\n    \n    envTable.BackgroundFlash:Play()\n    \n    Plater.FlashNameplateBorder (unitFrame, 0.05)   \n    Plater.FlashNameplateBody (unitFrame, \"\", 0.075)\n    \n    unitFrame:PlayFrameShake (envTable.FrameShake)\n    \n    Plater.SetCastBarColorForScript(self, scriptTable.config.useCastbarColor, scriptTable.config.castBarColor, envTable)\n    \n    --Dominator on Shadowmoon Burial Grounds\n    if (envTable._SpellID == 154327) then\n        if (UnitHealth(unitId) == UnitHealthMax(unitId)) then\n            if (envTable._Duration == 604800) then\n                Plater.SetCastBarColorForScript(self, scriptTable.config.useCastbarColor, {1, 0, 0, 1}, envTable)\n            end\n        end\n    end\nend",
      ["Enabled"] = false,
      ["Revision"] = 836,
      ["Options"] = {
        {
          ["Type"] = 6,
          ["Key"] = "option1",
          ["Value"] = 0,
          ["Name"] = "Option 1",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [1]
        {
          ["Type"] = 5,
          ["Key"] = "option2",
          ["Value"] = "Plays a big animation when the cast start.",
          ["Name"] = "Option 2",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_label",
          ["Desc"] = "",
        }, -- [2]
        {
          ["Type"] = 5,
          ["Key"] = "option2",
          ["Value"] = "Enter the spell name or spellID of the Spell in the Add Trigger box and hit \"Add\".",
          ["Name"] = "Option 2",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_label",
          ["Desc"] = "",
        }, -- [3]
        {
          ["Type"] = 6,
          ["Key"] = "option4",
          ["Value"] = 0,
          ["Name"] = "Option 4",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [4]
        {
          ["Type"] = 5,
          ["Key"] = "option2",
          ["Value"] = "Flash:",
          ["Name"] = "Flash",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_label",
          ["Desc"] = "",
        }, -- [5]
        {
          ["Type"] = 2,
          ["Max"] = 1.2,
          ["Desc"] = "How long is the flash played when the cast starts.",
          ["Min"] = 0.1,
          ["Key"] = "flashDuration",
          ["Value"] = 0.8,
          ["Fraction"] = true,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Flash Duration",
        }, -- [6]
        {
          ["Type"] = 1,
          ["Key"] = "flashColor",
          ["Value"] = {
            1, -- [1]
            1, -- [2]
            1, -- [3]
            1, -- [4]
          },
          ["Name"] = "Flash Color",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
          ["Desc"] = "Color of the Flash",
        }, -- [7]
        {
          ["Type"] = 6,
          ["Key"] = "option7",
          ["Value"] = 0,
          ["Name"] = "Option 7",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [8]
        {
          ["Type"] = 5,
          ["Key"] = "option2",
          ["Value"] = "Shake:",
          ["Name"] = "Shake",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_label",
          ["Desc"] = "",
        }, -- [9]
        {
          ["Type"] = 2,
          ["Max"] = 0.5,
          ["Desc"] = "When the cast starts, there's a small shake in the nameplate, this settings controls how long it takes.",
          ["Min"] = 0.1,
          ["Key"] = "shakeDuration",
          ["Value"] = 0.2,
          ["Fraction"] = true,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Shake Duration",
        }, -- [10]
        {
          ["Type"] = 2,
          ["Max"] = 10,
          ["Desc"] = "How strong is the shake.",
          ["Min"] = 1,
          ["Key"] = "shakeAmplitude",
          ["Value"] = 5,
          ["Fraction"] = false,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Shake Amplitude",
        }, -- [11]
        {
          ["Type"] = 2,
          ["Max"] = 80,
          ["Desc"] = "How fast the shake moves.",
          ["Min"] = 1,
          ["Key"] = "shakeFrequency",
          ["Value"] = 40,
          ["Fraction"] = false,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Shake Frequency",
        }, -- [12]
        {
          ["Type"] = 6,
          ["Key"] = "option13",
          ["Value"] = 0,
          ["Name"] = "Option 13",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [13]
        {
          ["Type"] = 5,
          ["Key"] = "option14",
          ["Value"] = "Dot Animation:",
          ["Name"] = "Dot Animation",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_label",
          ["Desc"] = "",
        }, -- [14]
        {
          ["Type"] = 1,
          ["Key"] = "dotColor",
          ["Value"] = {
            0.56470588235294, -- [1]
            0.56470588235294, -- [2]
            0.56470588235294, -- [3]
            1, -- [4]
          },
          ["Name"] = "Dot Color",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
          ["Desc"] = "Adjust the color of the dots around the nameplate",
        }, -- [15]
        {
          ["Type"] = 2,
          ["Max"] = 20,
          ["Desc"] = "Adjust the width of the dots to better fit in your nameplate.",
          ["Min"] = -10,
          ["Key"] = "xOffset",
          ["Value"] = 8,
          ["Fraction"] = false,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Dot X Offset",
        }, -- [16]
        {
          ["Type"] = 2,
          ["Max"] = 10,
          ["Desc"] = "Adjust the height of the dots to better fit in your nameplate.",
          ["Min"] = -10,
          ["Key"] = "yOffset",
          ["Value"] = 3,
          ["Fraction"] = false,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Dot Y Offset",
        }, -- [17]
        {
          ["Type"] = 6,
          ["Key"] = "option18",
          ["Value"] = 0,
          ["Name"] = "blank",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [18]
        {
          ["Type"] = 6,
          ["Key"] = "option18",
          ["Value"] = 0,
          ["Name"] = "blank",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [19]
        {
          ["Type"] = 6,
          ["Key"] = "option18",
          ["Value"] = 0,
          ["Name"] = "blank",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [20]
        {
          ["Type"] = 6,
          ["Key"] = "option18",
          ["Value"] = 0,
          ["Name"] = "blank",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [21]
        {
          ["Type"] = 6,
          ["Key"] = "option18",
          ["Value"] = 0,
          ["Name"] = "blank",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [22]
        {
          ["Type"] = 6,
          ["Key"] = "option18",
          ["Value"] = 0,
          ["Name"] = "blank",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [23]
        {
          ["Type"] = 5,
          ["Key"] = "option19",
          ["Value"] = "Cast Bar",
          ["Name"] = "Option 19",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_label",
          ["Desc"] = "",
        }, -- [24]
        {
          ["Type"] = 4,
          ["Key"] = "useCastbarColor",
          ["Value"] = true,
          ["Name"] = "Use Cast Bar Color",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_bool",
          ["Desc"] = "Use cast bar color.",
        }, -- [25]
        {
          ["Type"] = 1,
          ["Key"] = "castBarColor",
          ["Value"] = {
            0.41176470588235, -- [1]
            1, -- [2]
            0, -- [3]
            1, -- [4]
          },
          ["Name"] = "Cast Bar Color",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
          ["Desc"] = "Cast bar color.",
        }, -- [26]
      },
      ["Name"] = "Cast - Very Important [Plater]",
      ["Prio"] = 99,
      ["Author"] = "Bombad o-Azralon",
      ["Initialization"] = "function (scriptTable)\n    --insert code here\n    \nend\n\n\n",
      ["Desc"] = "Highlight a very important cast applying several effects into the Cast Bar. Add spell in the Add Trigger field.",
      ["SpellIds"] = {
        373046, -- [1]
        372863, -- [2]
        164686, -- [3]
        153072, -- [4]
        153680, -- [5]
        196497, -- [6]
        388886, -- [7]
        387145, -- [8]
        384365, -- [9]
        152964, -- [10]
        398150, -- [11]
        152801, -- [12]
        397878, -- [13]
        397914, -- [14]
        183263, -- [15]
        3636, -- [16]
        376171, -- [17]
        350687, -- [18]
        385568, -- [19]
        372735, -- [20]
        373017, -- [21]
        392488, -- [22]
        257732, -- [23]
        256060, -- [24]
        257899, -- [25]
        384633, -- [26]
        374339, -- [27]
        395694, -- [28]
        391634, -- [29]
        372701, -- [30]
        369328, -- [31]
        265487, -- [32]
        413044, -- [33]
        183526, -- [34]
        88194, -- [35]
        87762, -- [36]
        413385, -- [37]
        411001, -- [38]
        378282, -- [39]
        384161, -- [40]
      },
      ["Temp_UpdateCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \nend\n\n\n",
      ["version"] = -1,
      ["PlaterCore"] = 1,
      ["Temp_ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    --create a texture to use for a flash behind the cast bar\n    local backGroundFlashTexture = Plater:CreateImage (self, [[Interface\\ACHIEVEMENTFRAME\\UI-Achievement-Alert-Glow]], self:GetWidth()+40, self:GetHeight()+20, \"background\", {0, 400/512, 0, 170/256})\n    backGroundFlashTexture:SetBlendMode (\"ADD\")\n    backGroundFlashTexture:SetDrawLayer(\"OVERLAY\", 7)\n    backGroundFlashTexture:SetPoint (\"center\", self, \"center\")\n    backGroundFlashTexture:SetVertexColor(Plater:ParseColors(scriptTable.config.flashColor))\n    backGroundFlashTexture:Hide()\n    \n    --create the animation hub to hold the flash animation sequence\n    envTable.BackgroundFlash = envTable.BackgroundFlash or Plater:CreateAnimationHub (backGroundFlashTexture, \n        function()\n            backGroundFlashTexture:Show()\n        end,\n        function()\n            backGroundFlashTexture:Hide()\n        end\n    )\n    \n    --create the flash animation sequence\n    local fadeIn = Plater:CreateAnimation (envTable.BackgroundFlash, \"ALPHA\", 1, scriptTable.config.flashDuration/2, 0, 1)\n    local fadeOut = Plater:CreateAnimation (envTable.BackgroundFlash, \"ALPHA\", 2, scriptTable.config.flashDuration/2, 1, 0)\n    \n    --create a camera shake for the nameplate\n    envTable.FrameShake = Plater:CreateFrameShake (unitFrame, scriptTable.config.shakeDuration, scriptTable.config.shakeAmplitude, scriptTable.config.shakeFrequency, false, false, 0, 1, 0.05, 0.1, Plater.GetPoints (unitFrame))\n    \n    --update the config for the flash here so it wont need a /reload\n    fadeIn:SetDuration (scriptTable.config.flashDuration/2)\n    fadeOut:SetDuration (scriptTable.config.flashDuration/2)\n    \n    --update the config for the skake here so it wont need a /reload\n    envTable.FrameShake.OriginalAmplitude = scriptTable.config.shakeAmplitude\n    envTable.FrameShake.OriginalDuration = scriptTable.config.shakeDuration\n    envTable.FrameShake.OriginalFrequency = scriptTable.config.shakeFrequency\nend",
      ["semver"] = "",
      ["Temp_Initialization"] = "function (scriptTable)\n    --insert code here\n    \nend\n\n\n",
      ["__TrashAt"] = 1698536827,
    }, -- [2]
    {
      ["ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    function envTable.UpdateMarkers(unitFrame)\n        local npcID = envTable._NpcID\n        if not npcID then \n            if (unitFrame.healthMarker) then\n                unitFrame.healthMarker:Hide()\n                unitFrame.healthOverlay:Hide()\n            end\n            return \n        end\n        \n        local _, zoneType, diff = GetInstanceInfo()\n        local markersTable = zoneType == \"raid\" and scriptTable.Difficulty[diff][npcID] or scriptTable.lifePercent[npcID]\n        \n        if (markersTable) then\n            for _, p in ipairs(markersTable) do\n                if (envTable._HealthPercent > p) then\n                    local healthBar = unitFrame.healthBar\n                    local overlaySize = healthBar:GetWidth() * p/100\n                    \n                    if (not unitFrame.healthMarker) then\n                        unitFrame.healthMarker = healthBar:CreateTexture(nil, \"overlay\")\n                        unitFrame.healthMarker:SetColorTexture(1, 1, 1)\n                        unitFrame.healthOverlay = healthBar:CreateTexture(nil, \"overlay\")\n                        unitFrame.healthOverlay:SetColorTexture(1, 1, 1)\n                    end\n                    \n                    unitFrame.healthMarker:Show()\n                    unitFrame.healthMarker:SetSize(1, healthBar:GetHeight())\n                    unitFrame.healthMarker:SetPoint(\"left\", healthBar, \"left\", overlaySize, 0)\n                    unitFrame.healthMarker:SetVertexColor(Plater:ParseColors(scriptTable.config.indicatorColor))\n                    \n                    unitFrame.healthOverlay:Show()\n                    unitFrame.healthOverlay:SetSize(overlaySize, healthBar:GetHeight())\n                    unitFrame.healthOverlay:SetPoint(\"right\", unitFrame.healthMarker, \"left\", 0, 0)\n                    unitFrame.healthOverlay:SetVertexColor(Plater:ParseColors(scriptTable.config.fillColor))\n                    unitFrame.healthOverlay:SetAlpha(scriptTable.config.fillAlpha)\n                    \n                    return\n                end\n            end\n            \n            if (unitFrame.healthMarker) then\n                unitFrame.healthMarker:Hide()\n                unitFrame.healthOverlay:Hide()\n            end\n        end\n    end\nend",
      ["OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    if (unitFrame.healthMarker) then\n        unitFrame.healthMarker:Hide()\n        unitFrame.healthOverlay:Hide()\n    end\nend\n\n\n\n",
      ["OptionsValues"] = {
        ["fillColor"] = {
          1, -- [1]
          1, -- [2]
          1, -- [3]
          1, -- [4]
        },
        ["indicatorAlpha"] = 0.798833966255188,
        ["fillAlpha"] = 0.1540231704711914,
      },
      ["Temp_OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    if unitFrame.IsSelf or (Plater.ZoneInstanceType == \"arena\" or Plater.ZoneInstanceType == \"pvp\") then return end\n    \n    envTable.UpdateMarkers(unitFrame)    \nend    \n\n\n",
      ["ScriptType"] = 3,
      ["Temp_Initialization"] = "function (scriptTable)\n    \n    scriptTable.lifePercent = {\n        -- Azure Vault\n        [186738] = {75, 50, 25}, -- Umbrelskul\n        \n        -- Court of Stars\n        [104215] = {25}, -- Patrol Captain Gerdo\n        \n        -- Halls of Valor\n        [94960] = {10}, -- Hymdall\n        [95674] = {60}, -- Fenryr\n        [95676] = {80}, -- Odyn\n        \n        -- Nokhud Offensive\n        [186151] = {60}, -- Balakar Khan\n        \n        -- Ruby Life Pools\n        [188252] = {75, 45}, -- Melidrussa\n        [190484] = {50}, -- Kyrakka\n        [197697] = {50}, -- Flamegullet\n        \n        -- Shadowmoon Burial Grounds\n        [76057] = {20}, -- Carrion Worm\n        \n        -- Temple of the Jade Serpent\n        [56732] = {70, 30}, -- Liu Flameheart\n        [59544] = {50}, -- The Nodding Tiger\n        \n        -- Vault of the Incarnates\n        [187967] = {5}, -- Sennarth\n        [189492] = {65}, -- Raszageth\n        \n        -- Neltharion's Lair\n        [91005] = {20}, -- Naraxas\n        \n        -- Neltharus\n        [194816] = {10}, -- Forgewrought Monstrosity\n        \n        -- Freehold\n        [129732] = {75}, -- Skycap'n Kragg\n        [126983] = {60, 30}, -- Harlan Sweete\n        \n        -- Uldaman\n        [184020] = {40}, -- Hulking Berserker\n        [184422] = {70, 30}, -- Emberon\n        [184580] = {10}, -- Olaf\n        [184581] = {10}, -- Baelog\n        [184582] = {10}, -- Eric \"The Swift\"\n        \n        -- Brackenhide Hollow\n        [185508] = {15}, -- Claw Fighter \n        [185528] = {15}, -- Trickclaw Mystic\n        [185534] = {15}, -- Bonebolt Hunter\n        [186121] = {4}, -- Decatriarch Wratheye \n        [186122] = {15}, -- Rira Hackclaw\n        [186124] = {15}, -- Gashtooth\n        [186125] = {15}, -- Tricktotem\n        [186206] = {15}, -- Cruel Bonecrusher\n        [186227] = {20}, -- Monstrous Decay\n        \n        -- Halls of Infusion\n        [189719] = {15}, -- Watcher Irideus\n        [190368] = {40}, -- Flamecaller Aymi\n        [190407] = {20}, -- Aqua Rager\n        \n        -- Abberus\n        [201261] = {80, 60, 40}, -- Kazzara\n    }\n    \n    scriptTable.Difficulty = {\n        [16] = { -- Mythic\n        },       \n        [15] = { -- Heroic\n        },       \n        [14] = { -- Normal\n        }, \n        [17] = { -- LFR\n        }, \n    }\nend",
      ["Time"] = 1698536515,
      ["Temp_OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    if (unitFrame.healthMarker) then\n        unitFrame.healthMarker:Hide()\n        unitFrame.healthOverlay:Hide()\n    end\nend\n\n\n\n",
      ["Options"] = {
        {
          ["Type"] = 5,
          ["Name"] = "Option 1",
          ["Value"] = "Add markers into the health bar to remind you about boss abilities at life percent.",
          ["Key"] = "option1",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_label",
          ["Desc"] = "",
        }, -- [1]
        {
          ["Type"] = 1,
          ["Name"] = "Vertical Line Color",
          ["Value"] = {
            1, -- [1]
            1, -- [2]
            1, -- [3]
            1, -- [4]
          },
          ["Key"] = "indicatorColor",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
          ["Desc"] = "Indicator color.",
        }, -- [2]
        {
          ["Type"] = 2,
          ["Max"] = 1,
          ["Desc"] = "Indicator alpha.",
          ["Min"] = 0.1,
          ["Fraction"] = true,
          ["Value"] = 0.85,
          ["Name"] = "Vertical Line Alpha",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Key"] = "indicatorAlpha",
        }, -- [3]
        {
          ["Type"] = 6,
          ["Name"] = "blank line",
          ["Value"] = 0,
          ["Key"] = "",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [4]
        {
          ["Type"] = 1,
          ["Name"] = "Fill Color",
          ["Value"] = {
            0, -- [1]
            0, -- [2]
            0, -- [3]
            1, -- [4]
          },
          ["Key"] = "fillColor",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
          ["Desc"] = "Fill color.",
        }, -- [5]
        {
          ["Type"] = 2,
          ["Max"] = 1,
          ["Desc"] = "Fill alpha.",
          ["Min"] = 0,
          ["Fraction"] = true,
          ["Value"] = 0.5,
          ["Name"] = "Fill Alpha",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Key"] = "fillAlpha",
        }, -- [6]
      },
      ["Temp_ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    function envTable.UpdateMarkers(unitFrame)\n        local npcID = envTable._NpcID\n        if not npcID then \n            if (unitFrame.healthMarker) then\n                unitFrame.healthMarker:Hide()\n                unitFrame.healthOverlay:Hide()\n            end\n            return \n        end\n        \n        local _, zoneType, diff = GetInstanceInfo()\n        local markersTable = zoneType == \"raid\" and scriptTable.Difficulty[diff][npcID] or scriptTable.lifePercent[npcID]\n        \n        if (markersTable) then\n            for _, p in ipairs(markersTable) do\n                if (envTable._HealthPercent > p) then\n                    local healthBar = unitFrame.healthBar\n                    local overlaySize = healthBar:GetWidth() * p/100\n                    \n                    if (not unitFrame.healthMarker) then\n                        unitFrame.healthMarker = healthBar:CreateTexture(nil, \"overlay\")\n                        unitFrame.healthMarker:SetColorTexture(1, 1, 1)\n                        unitFrame.healthOverlay = healthBar:CreateTexture(nil, \"overlay\")\n                        unitFrame.healthOverlay:SetColorTexture(1, 1, 1)\n                    end\n                    \n                    unitFrame.healthMarker:Show()\n                    unitFrame.healthMarker:SetSize(1, healthBar:GetHeight())\n                    unitFrame.healthMarker:SetPoint(\"left\", healthBar, \"left\", overlaySize, 0)\n                    unitFrame.healthMarker:SetVertexColor(Plater:ParseColors(scriptTable.config.indicatorColor))\n                    \n                    unitFrame.healthOverlay:Show()\n                    unitFrame.healthOverlay:SetSize(overlaySize, healthBar:GetHeight())\n                    unitFrame.healthOverlay:SetPoint(\"right\", unitFrame.healthMarker, \"left\", 0, 0)\n                    unitFrame.healthOverlay:SetVertexColor(Plater:ParseColors(scriptTable.config.fillColor))\n                    unitFrame.healthOverlay:SetAlpha(scriptTable.config.fillAlpha)\n                    \n                    return\n                end\n            end\n            \n            if (unitFrame.healthMarker) then\n                unitFrame.healthMarker:Hide()\n                unitFrame.healthOverlay:Hide()\n            end\n        end\n    end\nend",
      ["NpcNames"] = {
        "56732", -- [1]
        "59544", -- [2]
        "76057", -- [3]
        "91005", -- [4]
        "94960", -- [5]
        "95674", -- [6]
        "95676", -- [7]
        "104215", -- [8]
        "126983", -- [9]
        "129723", -- [10]
        "184020", -- [11]
        "184422", -- [12]
        "184580", -- [13]
        "184581", -- [14]
        "184582", -- [15]
        "185508", -- [16]
        "185528", -- [17]
        "185534", -- [18]
        "186121", -- [19]
        "186122", -- [20]
        "186124", -- [21]
        "186125", -- [22]
        "186151", -- [23]
        "186206", -- [24]
        "186227", -- [25]
        "186738", -- [26]
        "187967", -- [27]
        "188252", -- [28]
        "189492", -- [29]
        "189719", -- [30]
        "190368", -- [31]
        "190407", -- [32]
        "190484", -- [33]
        "194816", -- [34]
        "197697", -- [35]
        "201261", -- [36]
      },
      ["Desc"] = "Place a marker into the health bar to indicate when the unit will change phase or cast an important spell.",
      ["Enabled"] = true,
      ["Revision"] = 1510,
      ["semver"] = "1.3.3",
      ["version"] = 26,
      ["Temp_UpdateCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    if unitFrame.IsSelf or (Plater.ZoneInstanceType == \"arena\" or Plater.ZoneInstanceType == \"pvp\") then return end\n    \n    envTable.UpdateMarkers(unitFrame)    \nend    \n\n\n",
      ["Author"] = "Aelerolor-Torghast",
      ["Initialization"] = "function (scriptTable)\n    \n    scriptTable.lifePercent = {\n        -- Azure Vault\n        [186738] = {75, 50, 25}, -- Umbrelskul\n        \n        -- Court of Stars\n        [104215] = {25}, -- Patrol Captain Gerdo\n        \n        -- Halls of Valor\n        [94960] = {10}, -- Hymdall\n        [95674] = {60}, -- Fenryr\n        [95676] = {80}, -- Odyn\n        \n        -- Nokhud Offensive\n        [186151] = {60}, -- Balakar Khan\n        \n        -- Ruby Life Pools\n        [188252] = {75, 45}, -- Melidrussa\n        [190484] = {50}, -- Kyrakka\n        [197697] = {50}, -- Flamegullet\n        \n        -- Shadowmoon Burial Grounds\n        [76057] = {20}, -- Carrion Worm\n        \n        -- Temple of the Jade Serpent\n        [56732] = {70, 30}, -- Liu Flameheart\n        [59544] = {50}, -- The Nodding Tiger\n        \n        -- Vault of the Incarnates\n        [187967] = {5}, -- Sennarth\n        [189492] = {65}, -- Raszageth\n        \n        -- Neltharion's Lair\n        [91005] = {20}, -- Naraxas\n        \n        -- Neltharus\n        [194816] = {10}, -- Forgewrought Monstrosity\n        \n        -- Freehold\n        [129732] = {75}, -- Skycap'n Kragg\n        [126983] = {60, 30}, -- Harlan Sweete\n        \n        -- Uldaman\n        [184020] = {40}, -- Hulking Berserker\n        [184422] = {70, 30}, -- Emberon\n        [184580] = {10}, -- Olaf\n        [184581] = {10}, -- Baelog\n        [184582] = {10}, -- Eric \"The Swift\"\n        \n        -- Brackenhide Hollow\n        [185508] = {15}, -- Claw Fighter \n        [185528] = {15}, -- Trickclaw Mystic\n        [185534] = {15}, -- Bonebolt Hunter\n        [186121] = {4}, -- Decatriarch Wratheye \n        [186122] = {15}, -- Rira Hackclaw\n        [186124] = {15}, -- Gashtooth\n        [186125] = {15}, -- Tricktotem\n        [186206] = {15}, -- Cruel Bonecrusher\n        [186227] = {20}, -- Monstrous Decay\n        \n        -- Halls of Infusion\n        [189719] = {15}, -- Watcher Irideus\n        [190368] = {40}, -- Flamecaller Aymi\n        [190407] = {20}, -- Aqua Rager\n        \n        -- Abberus\n        [201261] = {80, 60, 40}, -- Kazzara\n    }\n    \n    scriptTable.Difficulty = {\n        [16] = { -- Mythic\n        },       \n        [15] = { -- Heroic\n        },       \n        [14] = { -- Normal\n        }, \n        [17] = { -- LFR\n        }, \n    }\nend",
      ["OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    if unitFrame.IsSelf or (Plater.ZoneInstanceType == \"arena\" or Plater.ZoneInstanceType == \"pvp\") then return end\n    \n    envTable.UpdateMarkers(unitFrame)    \nend    \n\n\n",
      ["SpellIds"] = {
      },
      ["Prio"] = 99,
      ["Name"] = "Add - Health Markers [OPS]",
      ["PlaterCore"] = 1,
      ["Icon"] = "Interface\\Addons\\Plater\\images\\health_indicator",
      ["url"] = "https://wago.io/7DvxkttTL/26",
      ["UpdateCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    if unitFrame.IsSelf or (Plater.ZoneInstanceType == \"arena\" or Plater.ZoneInstanceType == \"pvp\") then return end\n    \n    envTable.UpdateMarkers(unitFrame)    \nend    \n\n\n",
      ["__TrashAt"] = 1698536900,
    }, -- [3]
    {
      ["ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    function envTable.UpdateMarkers(unitFrame)\n        local npcID = envTable._NpcID\n        if not npcID then \n            if (unitFrame.healthMarker) then\n                unitFrame.healthMarker:Hide()\n                unitFrame.healthOverlay:Hide()\n            end\n            return \n        end\n        \n        local _, zoneType, diff = GetInstanceInfo()\n        local markersTable = zoneType == \"raid\" and scriptTable.Difficulty[diff][npcID] or scriptTable.lifePercent[npcID]\n        \n        if (markersTable) then\n            for _, p in ipairs(markersTable) do\n                if (envTable._HealthPercent > p) then\n                    local healthBar = unitFrame.healthBar\n                    local overlaySize = healthBar:GetWidth() * p/100\n                    \n                    if (not unitFrame.healthMarker) then\n                        unitFrame.healthMarker = healthBar:CreateTexture(nil, \"overlay\")\n                        unitFrame.healthMarker:SetColorTexture(1, 1, 1)\n                        unitFrame.healthOverlay = healthBar:CreateTexture(nil, \"overlay\")\n                        unitFrame.healthOverlay:SetColorTexture(1, 1, 1)\n                    end\n                    \n                    unitFrame.healthMarker:Show()\n                    unitFrame.healthMarker:SetSize(1, healthBar:GetHeight())\n                    unitFrame.healthMarker:SetPoint(\"left\", healthBar, \"left\", overlaySize, 0)\n                    unitFrame.healthMarker:SetVertexColor(Plater:ParseColors(scriptTable.config.indicatorColor))\n                    \n                    unitFrame.healthOverlay:Show()\n                    unitFrame.healthOverlay:SetSize(overlaySize, healthBar:GetHeight())\n                    unitFrame.healthOverlay:SetPoint(\"right\", unitFrame.healthMarker, \"left\", 0, 0)\n                    unitFrame.healthOverlay:SetVertexColor(Plater:ParseColors(scriptTable.config.fillColor))\n                    unitFrame.healthOverlay:SetAlpha(scriptTable.config.fillAlpha)\n                    \n                    return\n                end\n            end\n            \n            if (unitFrame.healthMarker) then\n                unitFrame.healthMarker:Hide()\n                unitFrame.healthOverlay:Hide()\n            end\n        end\n    end\nend",
      ["OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    if (unitFrame.healthMarker) then\n        unitFrame.healthMarker:Hide()\n        unitFrame.healthOverlay:Hide()\n    end\nend\n\n\n\n",
      ["OptionsValues"] = {
        ["fillColor"] = {
          1, -- [1]
          1, -- [2]
          1, -- [3]
          1, -- [4]
        },
        ["indicatorAlpha"] = 0.798833966255188,
        ["fillAlpha"] = 0.1540231704711914,
      },
      ["Temp_OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    if unitFrame.IsSelf or (Plater.ZoneInstanceType == \"arena\" or Plater.ZoneInstanceType == \"pvp\") then return end\n    \n    envTable.UpdateMarkers(unitFrame)    \nend    \n\n\n",
      ["ScriptType"] = 3,
      ["__TrashAt"] = 1698546830,
      ["Time"] = 1698536902,
      ["NpcNames"] = {
        "56732", -- [1]
        "59544", -- [2]
        "76057", -- [3]
        "91005", -- [4]
        "94960", -- [5]
        "95674", -- [6]
        "95676", -- [7]
        "104215", -- [8]
        "126983", -- [9]
        "129723", -- [10]
        "184020", -- [11]
        "184422", -- [12]
        "184580", -- [13]
        "184581", -- [14]
        "184582", -- [15]
        "185508", -- [16]
        "185528", -- [17]
        "185534", -- [18]
        "186121", -- [19]
        "186122", -- [20]
        "186124", -- [21]
        "186125", -- [22]
        "186151", -- [23]
        "186206", -- [24]
        "186227", -- [25]
        "186738", -- [26]
        "187967", -- [27]
        "188252", -- [28]
        "189492", -- [29]
        "189719", -- [30]
        "190368", -- [31]
        "190407", -- [32]
        "190484", -- [33]
        "194816", -- [34]
        "197697", -- [35]
        "201261", -- [36]
      },
      ["Options"] = {
        {
          ["Type"] = 5,
          ["Name"] = "Option 1",
          ["Value"] = "Add markers into the health bar to remind you about boss abilities at life percent.",
          ["Key"] = "option1",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_label",
          ["Desc"] = "",
        }, -- [1]
        {
          ["Type"] = 1,
          ["Name"] = "Vertical Line Color",
          ["Value"] = {
            1, -- [1]
            1, -- [2]
            1, -- [3]
            1, -- [4]
          },
          ["Key"] = "indicatorColor",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
          ["Desc"] = "Indicator color.",
        }, -- [2]
        {
          ["Type"] = 2,
          ["Max"] = 1,
          ["Desc"] = "Indicator alpha.",
          ["Min"] = 0.1,
          ["Fraction"] = true,
          ["Value"] = 0.85,
          ["Name"] = "Vertical Line Alpha",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Key"] = "indicatorAlpha",
        }, -- [3]
        {
          ["Type"] = 6,
          ["Name"] = "blank line",
          ["Value"] = 0,
          ["Key"] = "",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [4]
        {
          ["Type"] = 1,
          ["Name"] = "Fill Color",
          ["Value"] = {
            0, -- [1]
            0, -- [2]
            0, -- [3]
            1, -- [4]
          },
          ["Key"] = "fillColor",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
          ["Desc"] = "Fill color.",
        }, -- [5]
        {
          ["Type"] = 2,
          ["Max"] = 1,
          ["Desc"] = "Fill alpha.",
          ["Min"] = 0,
          ["Fraction"] = true,
          ["Value"] = 0.5,
          ["Name"] = "Fill Alpha",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Key"] = "fillAlpha",
        }, -- [6]
      },
      ["url"] = "https://wago.io/7DvxkttTL/26",
      ["Icon"] = "Interface\\Addons\\Plater\\images\\health_indicator",
      ["Desc"] = "Place a marker into the health bar to indicate when the unit will change phase or cast an important spell.",
      ["Temp_OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    if (unitFrame.healthMarker) then\n        unitFrame.healthMarker:Hide()\n        unitFrame.healthOverlay:Hide()\n    end\nend\n\n\n\n",
      ["Revision"] = 1509,
      ["semver"] = "1.3.3",
      ["Name"] = "Add - Health Markers [OPS]",
      ["Temp_UpdateCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    if unitFrame.IsSelf or (Plater.ZoneInstanceType == \"arena\" or Plater.ZoneInstanceType == \"pvp\") then return end\n    \n    envTable.UpdateMarkers(unitFrame)    \nend    \n\n\n",
      ["Author"] = "Aelerolor-Torghast",
      ["Initialization"] = "function (scriptTable)\n    \n    scriptTable.lifePercent = {\n        -- Azure Vault\n        [186738] = {75, 50, 25}, -- Umbrelskul\n        \n        -- Court of Stars\n        [104215] = {25}, -- Patrol Captain Gerdo\n        \n        -- Halls of Valor\n        [94960] = {10}, -- Hymdall\n        [95674] = {60}, -- Fenryr\n        [95676] = {80}, -- Odyn\n        \n        -- Nokhud Offensive\n        [186151] = {60}, -- Balakar Khan\n        \n        -- Ruby Life Pools\n        [188252] = {75, 45}, -- Melidrussa\n        [190484] = {50}, -- Kyrakka\n        [197697] = {50}, -- Flamegullet\n        \n        -- Shadowmoon Burial Grounds\n        [76057] = {20}, -- Carrion Worm\n        \n        -- Temple of the Jade Serpent\n        [56732] = {70, 30}, -- Liu Flameheart\n        [59544] = {50}, -- The Nodding Tiger\n        \n        -- Vault of the Incarnates\n        [187967] = {5}, -- Sennarth\n        [189492] = {65}, -- Raszageth\n        \n        -- Neltharion's Lair\n        [91005] = {20}, -- Naraxas\n        \n        -- Neltharus\n        [194816] = {10}, -- Forgewrought Monstrosity\n        \n        -- Freehold\n        [129732] = {75}, -- Skycap'n Kragg\n        [126983] = {60, 30}, -- Harlan Sweete\n        \n        -- Uldaman\n        [184020] = {40}, -- Hulking Berserker\n        [184422] = {70, 30}, -- Emberon\n        [184580] = {10}, -- Olaf\n        [184581] = {10}, -- Baelog\n        [184582] = {10}, -- Eric \"The Swift\"\n        \n        -- Brackenhide Hollow\n        [185508] = {15}, -- Claw Fighter \n        [185528] = {15}, -- Trickclaw Mystic\n        [185534] = {15}, -- Bonebolt Hunter\n        [186121] = {4}, -- Decatriarch Wratheye \n        [186122] = {15}, -- Rira Hackclaw\n        [186124] = {15}, -- Gashtooth\n        [186125] = {15}, -- Tricktotem\n        [186206] = {15}, -- Cruel Bonecrusher\n        [186227] = {20}, -- Monstrous Decay\n        \n        -- Halls of Infusion\n        [189719] = {15}, -- Watcher Irideus\n        [190368] = {40}, -- Flamecaller Aymi\n        [190407] = {20}, -- Aqua Rager\n        \n        -- Abberus\n        [201261] = {80, 60, 40}, -- Kazzara\n    }\n    \n    scriptTable.Difficulty = {\n        [16] = { -- Mythic\n        },       \n        [15] = { -- Heroic\n        },       \n        [14] = { -- Normal\n        }, \n        [17] = { -- LFR\n        }, \n    }\nend",
      ["OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    if unitFrame.IsSelf or (Plater.ZoneInstanceType == \"arena\" or Plater.ZoneInstanceType == \"pvp\") then return end\n    \n    envTable.UpdateMarkers(unitFrame)    \nend    \n\n\n",
      ["version"] = 26,
      ["Prio"] = 99,
      ["SpellIds"] = {
      },
      ["PlaterCore"] = 1,
      ["Temp_ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    function envTable.UpdateMarkers(unitFrame)\n        local npcID = envTable._NpcID\n        if not npcID then \n            if (unitFrame.healthMarker) then\n                unitFrame.healthMarker:Hide()\n                unitFrame.healthOverlay:Hide()\n            end\n            return \n        end\n        \n        local _, zoneType, diff = GetInstanceInfo()\n        local markersTable = zoneType == \"raid\" and scriptTable.Difficulty[diff][npcID] or scriptTable.lifePercent[npcID]\n        \n        if (markersTable) then\n            for _, p in ipairs(markersTable) do\n                if (envTable._HealthPercent > p) then\n                    local healthBar = unitFrame.healthBar\n                    local overlaySize = healthBar:GetWidth() * p/100\n                    \n                    if (not unitFrame.healthMarker) then\n                        unitFrame.healthMarker = healthBar:CreateTexture(nil, \"overlay\")\n                        unitFrame.healthMarker:SetColorTexture(1, 1, 1)\n                        unitFrame.healthOverlay = healthBar:CreateTexture(nil, \"overlay\")\n                        unitFrame.healthOverlay:SetColorTexture(1, 1, 1)\n                    end\n                    \n                    unitFrame.healthMarker:Show()\n                    unitFrame.healthMarker:SetSize(1, healthBar:GetHeight())\n                    unitFrame.healthMarker:SetPoint(\"left\", healthBar, \"left\", overlaySize, 0)\n                    unitFrame.healthMarker:SetVertexColor(Plater:ParseColors(scriptTable.config.indicatorColor))\n                    \n                    unitFrame.healthOverlay:Show()\n                    unitFrame.healthOverlay:SetSize(overlaySize, healthBar:GetHeight())\n                    unitFrame.healthOverlay:SetPoint(\"right\", unitFrame.healthMarker, \"left\", 0, 0)\n                    unitFrame.healthOverlay:SetVertexColor(Plater:ParseColors(scriptTable.config.fillColor))\n                    unitFrame.healthOverlay:SetAlpha(scriptTable.config.fillAlpha)\n                    \n                    return\n                end\n            end\n            \n            if (unitFrame.healthMarker) then\n                unitFrame.healthMarker:Hide()\n                unitFrame.healthOverlay:Hide()\n            end\n        end\n    end\nend",
      ["Enabled"] = true,
      ["Temp_Initialization"] = "function (scriptTable)\n    \n    scriptTable.lifePercent = {\n        -- Azure Vault\n        [186738] = {75, 50, 25}, -- Umbrelskul\n        \n        -- Court of Stars\n        [104215] = {25}, -- Patrol Captain Gerdo\n        \n        -- Halls of Valor\n        [94960] = {10}, -- Hymdall\n        [95674] = {60}, -- Fenryr\n        [95676] = {80}, -- Odyn\n        \n        -- Nokhud Offensive\n        [186151] = {60}, -- Balakar Khan\n        \n        -- Ruby Life Pools\n        [188252] = {75, 45}, -- Melidrussa\n        [190484] = {50}, -- Kyrakka\n        [197697] = {50}, -- Flamegullet\n        \n        -- Shadowmoon Burial Grounds\n        [76057] = {20}, -- Carrion Worm\n        \n        -- Temple of the Jade Serpent\n        [56732] = {70, 30}, -- Liu Flameheart\n        [59544] = {50}, -- The Nodding Tiger\n        \n        -- Vault of the Incarnates\n        [187967] = {5}, -- Sennarth\n        [189492] = {65}, -- Raszageth\n        \n        -- Neltharion's Lair\n        [91005] = {20}, -- Naraxas\n        \n        -- Neltharus\n        [194816] = {10}, -- Forgewrought Monstrosity\n        \n        -- Freehold\n        [129732] = {75}, -- Skycap'n Kragg\n        [126983] = {60, 30}, -- Harlan Sweete\n        \n        -- Uldaman\n        [184020] = {40}, -- Hulking Berserker\n        [184422] = {70, 30}, -- Emberon\n        [184580] = {10}, -- Olaf\n        [184581] = {10}, -- Baelog\n        [184582] = {10}, -- Eric \"The Swift\"\n        \n        -- Brackenhide Hollow\n        [185508] = {15}, -- Claw Fighter \n        [185528] = {15}, -- Trickclaw Mystic\n        [185534] = {15}, -- Bonebolt Hunter\n        [186121] = {4}, -- Decatriarch Wratheye \n        [186122] = {15}, -- Rira Hackclaw\n        [186124] = {15}, -- Gashtooth\n        [186125] = {15}, -- Tricktotem\n        [186206] = {15}, -- Cruel Bonecrusher\n        [186227] = {20}, -- Monstrous Decay\n        \n        -- Halls of Infusion\n        [189719] = {15}, -- Watcher Irideus\n        [190368] = {40}, -- Flamecaller Aymi\n        [190407] = {20}, -- Aqua Rager\n        \n        -- Abberus\n        [201261] = {80, 60, 40}, -- Kazzara\n    }\n    \n    scriptTable.Difficulty = {\n        [16] = { -- Mythic\n        },       \n        [15] = { -- Heroic\n        },       \n        [14] = { -- Normal\n        }, \n        [17] = { -- LFR\n        }, \n    }\nend",
      ["UpdateCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    if unitFrame.IsSelf or (Plater.ZoneInstanceType == \"arena\" or Plater.ZoneInstanceType == \"pvp\") then return end\n    \n    envTable.UpdateMarkers(unitFrame)    \nend    \n\n\n",
    }, -- [4]
    {
      ["ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    function envTable.UpdateMarkers(unitFrame)\n        local npcID = envTable._NpcID\n        if not npcID then \n            if (unitFrame.healthMarker) then\n                unitFrame.healthMarker:Hide()\n                unitFrame.healthOverlay:Hide()\n            end\n            return \n        end\n        \n        local _, zoneType, diff = GetInstanceInfo()\n        local markersTable = zoneType == \"raid\" and scriptTable.Difficulty[diff][npcID] or scriptTable.lifePercent[npcID]\n        \n        if (markersTable) then\n            for _, p in ipairs(markersTable) do\n                if (envTable._HealthPercent > p) then\n                    local healthBar = unitFrame.healthBar\n                    local overlaySize = healthBar:GetWidth() * p/100\n                    \n                    if (not unitFrame.healthMarker) then\n                        unitFrame.healthMarker = healthBar:CreateTexture(nil, \"overlay\")\n                        unitFrame.healthMarker:SetColorTexture(1, 1, 1)\n                        unitFrame.healthOverlay = healthBar:CreateTexture(nil, \"overlay\")\n                        unitFrame.healthOverlay:SetColorTexture(1, 1, 1)\n                    end\n                    \n                    unitFrame.healthMarker:Show()\n                    unitFrame.healthMarker:SetSize(1, healthBar:GetHeight())\n                    unitFrame.healthMarker:SetPoint(\"left\", healthBar, \"left\", overlaySize, 0)\n                    unitFrame.healthMarker:SetVertexColor(Plater:ParseColors(scriptTable.config.indicatorColor))\n                    \n                    unitFrame.healthOverlay:Show()\n                    unitFrame.healthOverlay:SetSize(overlaySize, healthBar:GetHeight())\n                    unitFrame.healthOverlay:SetPoint(\"right\", unitFrame.healthMarker, \"left\", 0, 0)\n                    unitFrame.healthOverlay:SetVertexColor(Plater:ParseColors(scriptTable.config.fillColor))\n                    unitFrame.healthOverlay:SetAlpha(scriptTable.config.fillAlpha)\n                    \n                    return\n                end\n            end\n            \n            if (unitFrame.healthMarker) then\n                unitFrame.healthMarker:Hide()\n                unitFrame.healthOverlay:Hide()\n            end\n        end\n    end\nend",
      ["OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    if (unitFrame.healthMarker) then\n        unitFrame.healthMarker:Hide()\n        unitFrame.healthOverlay:Hide()\n    end\nend\n\n\n\n",
      ["OptionsValues"] = {
        ["fillColor"] = {
          1, -- [1]
          1, -- [2]
          1, -- [3]
          1, -- [4]
        },
        ["indicatorAlpha"] = 0.798833966255188,
        ["fillAlpha"] = 0.1540231704711914,
      },
      ["Temp_OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    if unitFrame.IsSelf or (Plater.ZoneInstanceType == \"arena\" or Plater.ZoneInstanceType == \"pvp\") then return end\n    \n    envTable.UpdateMarkers(unitFrame)    \nend    \n\n\n",
      ["ScriptType"] = 3,
      ["__TrashAt"] = 1699196474,
      ["Time"] = 1698546837,
      ["NpcNames"] = {
        "56732", -- [1]
        "59544", -- [2]
        "76057", -- [3]
        "91005", -- [4]
        "94960", -- [5]
        "95674", -- [6]
        "95676", -- [7]
        "104215", -- [8]
        "126983", -- [9]
        "129723", -- [10]
        "184020", -- [11]
        "184422", -- [12]
        "184580", -- [13]
        "184581", -- [14]
        "184582", -- [15]
        "185508", -- [16]
        "185528", -- [17]
        "185534", -- [18]
        "186121", -- [19]
        "186122", -- [20]
        "186124", -- [21]
        "186125", -- [22]
        "186151", -- [23]
        "186206", -- [24]
        "186227", -- [25]
        "186738", -- [26]
        "187967", -- [27]
        "188252", -- [28]
        "189492", -- [29]
        "189719", -- [30]
        "190368", -- [31]
        "190407", -- [32]
        "190484", -- [33]
        "194816", -- [34]
        "197697", -- [35]
        "201261", -- [36]
      },
      ["Options"] = {
        {
          ["Type"] = 5,
          ["Name"] = "Option 1",
          ["Value"] = "Add markers into the health bar to remind you about boss abilities at life percent.",
          ["Key"] = "option1",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_label",
          ["Desc"] = "",
        }, -- [1]
        {
          ["Type"] = 1,
          ["Name"] = "Vertical Line Color",
          ["Value"] = {
            1, -- [1]
            1, -- [2]
            1, -- [3]
            1, -- [4]
          },
          ["Key"] = "indicatorColor",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
          ["Desc"] = "Indicator color.",
        }, -- [2]
        {
          ["Type"] = 2,
          ["Max"] = 1,
          ["Desc"] = "Indicator alpha.",
          ["Min"] = 0.1,
          ["Fraction"] = true,
          ["Value"] = 0.85,
          ["Name"] = "Vertical Line Alpha",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Key"] = "indicatorAlpha",
        }, -- [3]
        {
          ["Type"] = 6,
          ["Name"] = "blank line",
          ["Value"] = 0,
          ["Key"] = "",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [4]
        {
          ["Type"] = 1,
          ["Name"] = "Fill Color",
          ["Value"] = {
            0, -- [1]
            0, -- [2]
            0, -- [3]
            1, -- [4]
          },
          ["Key"] = "fillColor",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
          ["Desc"] = "Fill color.",
        }, -- [5]
        {
          ["Type"] = 2,
          ["Max"] = 1,
          ["Desc"] = "Fill alpha.",
          ["Min"] = 0,
          ["Fraction"] = true,
          ["Value"] = 0.5,
          ["Name"] = "Fill Alpha",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Key"] = "fillAlpha",
        }, -- [6]
      },
      ["url"] = "https://wago.io/7DvxkttTL/26",
      ["Icon"] = "Interface\\Addons\\Plater\\images\\health_indicator",
      ["OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    if unitFrame.IsSelf or (Plater.ZoneInstanceType == \"arena\" or Plater.ZoneInstanceType == \"pvp\") then return end\n    \n    envTable.UpdateMarkers(unitFrame)    \nend    \n\n\n",
      ["Enabled"] = true,
      ["Revision"] = 1511,
      ["semver"] = "1.3.3",
      ["Name"] = "Add - Health Markers [OPS]",
      ["Prio"] = 99,
      ["Author"] = "Aelerolor-Torghast",
      ["Initialization"] = "function (scriptTable)\n    \n    scriptTable.lifePercent = {\n        -- Azure Vault\n        [186738] = {75, 50, 25}, -- Umbrelskul\n        \n        -- Court of Stars\n        [104215] = {25}, -- Patrol Captain Gerdo\n        \n        -- Halls of Valor\n        [94960] = {10}, -- Hymdall\n        [95674] = {60}, -- Fenryr\n        [95676] = {80}, -- Odyn\n        \n        -- Nokhud Offensive\n        [186151] = {60}, -- Balakar Khan\n        \n        -- Ruby Life Pools\n        [188252] = {75, 45}, -- Melidrussa\n        [190484] = {50}, -- Kyrakka\n        [197697] = {50}, -- Flamegullet\n        \n        -- Shadowmoon Burial Grounds\n        [76057] = {20}, -- Carrion Worm\n        \n        -- Temple of the Jade Serpent\n        [56732] = {70, 30}, -- Liu Flameheart\n        [59544] = {50}, -- The Nodding Tiger\n        \n        -- Vault of the Incarnates\n        [187967] = {5}, -- Sennarth\n        [189492] = {65}, -- Raszageth\n        \n        -- Neltharion's Lair\n        [91005] = {20}, -- Naraxas\n        \n        -- Neltharus\n        [194816] = {10}, -- Forgewrought Monstrosity\n        \n        -- Freehold\n        [129732] = {75}, -- Skycap'n Kragg\n        [126983] = {60, 30}, -- Harlan Sweete\n        \n        -- Uldaman\n        [184020] = {40}, -- Hulking Berserker\n        [184422] = {70, 30}, -- Emberon\n        [184580] = {10}, -- Olaf\n        [184581] = {10}, -- Baelog\n        [184582] = {10}, -- Eric \"The Swift\"\n        \n        -- Brackenhide Hollow\n        [185508] = {15}, -- Claw Fighter \n        [185528] = {15}, -- Trickclaw Mystic\n        [185534] = {15}, -- Bonebolt Hunter\n        [186121] = {4}, -- Decatriarch Wratheye \n        [186122] = {15}, -- Rira Hackclaw\n        [186124] = {15}, -- Gashtooth\n        [186125] = {15}, -- Tricktotem\n        [186206] = {15}, -- Cruel Bonecrusher\n        [186227] = {20}, -- Monstrous Decay\n        \n        -- Halls of Infusion\n        [189719] = {15}, -- Watcher Irideus\n        [190368] = {40}, -- Flamecaller Aymi\n        [190407] = {20}, -- Aqua Rager\n        \n        -- Abberus\n        [201261] = {80, 60, 40}, -- Kazzara\n    }\n    \n    scriptTable.Difficulty = {\n        [16] = { -- Mythic\n        },       \n        [15] = { -- Heroic\n        },       \n        [14] = { -- Normal\n        }, \n        [17] = { -- LFR\n        }, \n    }\nend",
      ["Desc"] = "Place a marker into the health bar to indicate when the unit will change phase or cast an important spell.",
      ["version"] = 26,
      ["Temp_UpdateCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    if unitFrame.IsSelf or (Plater.ZoneInstanceType == \"arena\" or Plater.ZoneInstanceType == \"pvp\") then return end\n    \n    envTable.UpdateMarkers(unitFrame)    \nend    \n\n\n",
      ["SpellIds"] = {
      },
      ["PlaterCore"] = 1,
      ["Temp_ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    function envTable.UpdateMarkers(unitFrame)\n        local npcID = envTable._NpcID\n        if not npcID then \n            if (unitFrame.healthMarker) then\n                unitFrame.healthMarker:Hide()\n                unitFrame.healthOverlay:Hide()\n            end\n            return \n        end\n        \n        local _, zoneType, diff = GetInstanceInfo()\n        local markersTable = zoneType == \"raid\" and scriptTable.Difficulty[diff][npcID] or scriptTable.lifePercent[npcID]\n        \n        if (markersTable) then\n            for _, p in ipairs(markersTable) do\n                if (envTable._HealthPercent > p) then\n                    local healthBar = unitFrame.healthBar\n                    local overlaySize = healthBar:GetWidth() * p/100\n                    \n                    if (not unitFrame.healthMarker) then\n                        unitFrame.healthMarker = healthBar:CreateTexture(nil, \"overlay\")\n                        unitFrame.healthMarker:SetColorTexture(1, 1, 1)\n                        unitFrame.healthOverlay = healthBar:CreateTexture(nil, \"overlay\")\n                        unitFrame.healthOverlay:SetColorTexture(1, 1, 1)\n                    end\n                    \n                    unitFrame.healthMarker:Show()\n                    unitFrame.healthMarker:SetSize(1, healthBar:GetHeight())\n                    unitFrame.healthMarker:SetPoint(\"left\", healthBar, \"left\", overlaySize, 0)\n                    unitFrame.healthMarker:SetVertexColor(Plater:ParseColors(scriptTable.config.indicatorColor))\n                    \n                    unitFrame.healthOverlay:Show()\n                    unitFrame.healthOverlay:SetSize(overlaySize, healthBar:GetHeight())\n                    unitFrame.healthOverlay:SetPoint(\"right\", unitFrame.healthMarker, \"left\", 0, 0)\n                    unitFrame.healthOverlay:SetVertexColor(Plater:ParseColors(scriptTable.config.fillColor))\n                    unitFrame.healthOverlay:SetAlpha(scriptTable.config.fillAlpha)\n                    \n                    return\n                end\n            end\n            \n            if (unitFrame.healthMarker) then\n                unitFrame.healthMarker:Hide()\n                unitFrame.healthOverlay:Hide()\n            end\n        end\n    end\nend",
      ["Temp_OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    if (unitFrame.healthMarker) then\n        unitFrame.healthMarker:Hide()\n        unitFrame.healthOverlay:Hide()\n    end\nend\n\n\n\n",
      ["Temp_Initialization"] = "function (scriptTable)\n    \n    scriptTable.lifePercent = {\n        -- Azure Vault\n        [186738] = {75, 50, 25}, -- Umbrelskul\n        \n        -- Court of Stars\n        [104215] = {25}, -- Patrol Captain Gerdo\n        \n        -- Halls of Valor\n        [94960] = {10}, -- Hymdall\n        [95674] = {60}, -- Fenryr\n        [95676] = {80}, -- Odyn\n        \n        -- Nokhud Offensive\n        [186151] = {60}, -- Balakar Khan\n        \n        -- Ruby Life Pools\n        [188252] = {75, 45}, -- Melidrussa\n        [190484] = {50}, -- Kyrakka\n        [197697] = {50}, -- Flamegullet\n        \n        -- Shadowmoon Burial Grounds\n        [76057] = {20}, -- Carrion Worm\n        \n        -- Temple of the Jade Serpent\n        [56732] = {70, 30}, -- Liu Flameheart\n        [59544] = {50}, -- The Nodding Tiger\n        \n        -- Vault of the Incarnates\n        [187967] = {5}, -- Sennarth\n        [189492] = {65}, -- Raszageth\n        \n        -- Neltharion's Lair\n        [91005] = {20}, -- Naraxas\n        \n        -- Neltharus\n        [194816] = {10}, -- Forgewrought Monstrosity\n        \n        -- Freehold\n        [129732] = {75}, -- Skycap'n Kragg\n        [126983] = {60, 30}, -- Harlan Sweete\n        \n        -- Uldaman\n        [184020] = {40}, -- Hulking Berserker\n        [184422] = {70, 30}, -- Emberon\n        [184580] = {10}, -- Olaf\n        [184581] = {10}, -- Baelog\n        [184582] = {10}, -- Eric \"The Swift\"\n        \n        -- Brackenhide Hollow\n        [185508] = {15}, -- Claw Fighter \n        [185528] = {15}, -- Trickclaw Mystic\n        [185534] = {15}, -- Bonebolt Hunter\n        [186121] = {4}, -- Decatriarch Wratheye \n        [186122] = {15}, -- Rira Hackclaw\n        [186124] = {15}, -- Gashtooth\n        [186125] = {15}, -- Tricktotem\n        [186206] = {15}, -- Cruel Bonecrusher\n        [186227] = {20}, -- Monstrous Decay\n        \n        -- Halls of Infusion\n        [189719] = {15}, -- Watcher Irideus\n        [190368] = {40}, -- Flamecaller Aymi\n        [190407] = {20}, -- Aqua Rager\n        \n        -- Abberus\n        [201261] = {80, 60, 40}, -- Kazzara\n    }\n    \n    scriptTable.Difficulty = {\n        [16] = { -- Mythic\n        },       \n        [15] = { -- Heroic\n        },       \n        [14] = { -- Normal\n        }, \n        [17] = { -- LFR\n        }, \n    }\nend",
      ["UpdateCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    if unitFrame.IsSelf or (Plater.ZoneInstanceType == \"arena\" or Plater.ZoneInstanceType == \"pvp\") then return end\n    \n    envTable.UpdateMarkers(unitFrame)    \nend    \n\n\n",
    }, -- [5]
    {
      ["ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    function envTable.UpdateMarkers(unitFrame)\n        local npcID = envTable._NpcID\n        if not npcID then \n            if (unitFrame.healthMarker) then\n                unitFrame.healthMarker:Hide()\n                unitFrame.healthOverlay:Hide()\n            end\n            return \n        end\n        \n        local _, zoneType, diff = GetInstanceInfo()\n        local markersTable = zoneType == \"raid\" and scriptTable.Difficulty[diff][npcID] or scriptTable.lifePercent[npcID]\n        \n        if (markersTable) then\n            for _, p in ipairs(markersTable) do\n                if (envTable._HealthPercent > p) then\n                    local healthBar = unitFrame.healthBar\n                    local overlaySize = healthBar:GetWidth() * p/100\n                    \n                    if (not unitFrame.healthMarker) then\n                        unitFrame.healthMarker = healthBar:CreateTexture(nil, \"overlay\")\n                        unitFrame.healthMarker:SetColorTexture(1, 1, 1)\n                        unitFrame.healthOverlay = healthBar:CreateTexture(nil, \"overlay\")\n                        unitFrame.healthOverlay:SetColorTexture(1, 1, 1)\n                    end\n                    \n                    unitFrame.healthMarker:Show()\n                    unitFrame.healthMarker:SetSize(1, healthBar:GetHeight())\n                    unitFrame.healthMarker:SetPoint(\"left\", healthBar, \"left\", overlaySize, 0)\n                    unitFrame.healthMarker:SetVertexColor(Plater:ParseColors(scriptTable.config.indicatorColor))\n                    \n                    unitFrame.healthOverlay:Show()\n                    unitFrame.healthOverlay:SetSize(overlaySize, healthBar:GetHeight())\n                    unitFrame.healthOverlay:SetPoint(\"right\", unitFrame.healthMarker, \"left\", 0, 0)\n                    unitFrame.healthOverlay:SetVertexColor(Plater:ParseColors(scriptTable.config.fillColor))\n                    unitFrame.healthOverlay:SetAlpha(scriptTable.config.fillAlpha)\n                    \n                    return\n                end\n            end\n            \n            if (unitFrame.healthMarker) then\n                unitFrame.healthMarker:Hide()\n                unitFrame.healthOverlay:Hide()\n            end\n        end\n    end\nend",
      ["OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    if (unitFrame.healthMarker) then\n        unitFrame.healthMarker:Hide()\n        unitFrame.healthOverlay:Hide()\n    end\nend\n\n\n\n",
      ["OptionsValues"] = {
        ["fillColor"] = {
          1, -- [1]
          1, -- [2]
          1, -- [3]
          1, -- [4]
        },
        ["indicatorAlpha"] = 0.798833966255188,
        ["fillAlpha"] = 0.1540231704711914,
      },
      ["Temp_OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    if unitFrame.IsSelf or (Plater.ZoneInstanceType == \"arena\" or Plater.ZoneInstanceType == \"pvp\") then return end\n    \n    envTable.UpdateMarkers(unitFrame)    \nend    \n\n\n",
      ["ScriptType"] = 3,
      ["url"] = "https://wago.io/7DvxkttTL/26",
      ["scriptId"] = "table: 00000217F7485090",
      ["Time"] = 1699196628,
      ["Icon"] = "Interface\\Addons\\Plater\\images\\health_indicator",
      ["semver"] = "1.3.3",
      ["Temp_ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    function envTable.UpdateMarkers(unitFrame)\n        local npcID = envTable._NpcID\n        if not npcID then \n            if (unitFrame.healthMarker) then\n                unitFrame.healthMarker:Hide()\n                unitFrame.healthOverlay:Hide()\n            end\n            return \n        end\n        \n        local _, zoneType, diff = GetInstanceInfo()\n        local markersTable = zoneType == \"raid\" and scriptTable.Difficulty[diff][npcID] or scriptTable.lifePercent[npcID]\n        \n        if (markersTable) then\n            for _, p in ipairs(markersTable) do\n                if (envTable._HealthPercent > p) then\n                    local healthBar = unitFrame.healthBar\n                    local overlaySize = healthBar:GetWidth() * p/100\n                    \n                    if (not unitFrame.healthMarker) then\n                        unitFrame.healthMarker = healthBar:CreateTexture(nil, \"overlay\")\n                        unitFrame.healthMarker:SetColorTexture(1, 1, 1)\n                        unitFrame.healthOverlay = healthBar:CreateTexture(nil, \"overlay\")\n                        unitFrame.healthOverlay:SetColorTexture(1, 1, 1)\n                    end\n                    \n                    unitFrame.healthMarker:Show()\n                    unitFrame.healthMarker:SetSize(1, healthBar:GetHeight())\n                    unitFrame.healthMarker:SetPoint(\"left\", healthBar, \"left\", overlaySize, 0)\n                    unitFrame.healthMarker:SetVertexColor(Plater:ParseColors(scriptTable.config.indicatorColor))\n                    \n                    unitFrame.healthOverlay:Show()\n                    unitFrame.healthOverlay:SetSize(overlaySize, healthBar:GetHeight())\n                    unitFrame.healthOverlay:SetPoint(\"right\", unitFrame.healthMarker, \"left\", 0, 0)\n                    unitFrame.healthOverlay:SetVertexColor(Plater:ParseColors(scriptTable.config.fillColor))\n                    unitFrame.healthOverlay:SetAlpha(scriptTable.config.fillAlpha)\n                    \n                    return\n                end\n            end\n            \n            if (unitFrame.healthMarker) then\n                unitFrame.healthMarker:Hide()\n                unitFrame.healthOverlay:Hide()\n            end\n        end\n    end\nend",
      ["NpcNames"] = {
        "56732", -- [1]
        "59544", -- [2]
        "76057", -- [3]
        "91005", -- [4]
        "94960", -- [5]
        "95674", -- [6]
        "95676", -- [7]
        "104215", -- [8]
        "126983", -- [9]
        "129723", -- [10]
        "184020", -- [11]
        "184422", -- [12]
        "184580", -- [13]
        "184581", -- [14]
        "184582", -- [15]
        "185508", -- [16]
        "185528", -- [17]
        "185534", -- [18]
        "186121", -- [19]
        "186122", -- [20]
        "186124", -- [21]
        "186125", -- [22]
        "186151", -- [23]
        "186206", -- [24]
        "186227", -- [25]
        "186738", -- [26]
        "187967", -- [27]
        "188252", -- [28]
        "189492", -- [29]
        "189719", -- [30]
        "190368", -- [31]
        "190407", -- [32]
        "190484", -- [33]
        "194816", -- [34]
        "197697", -- [35]
        "201261", -- [36]
      },
      ["version"] = 26,
      ["Temp_OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    if (unitFrame.healthMarker) then\n        unitFrame.healthMarker:Hide()\n        unitFrame.healthOverlay:Hide()\n    end\nend\n\n\n\n",
      ["Revision"] = 1510,
      ["Options"] = {
        {
          ["Type"] = 5,
          ["Name"] = "Option 1",
          ["Value"] = "Add markers into the health bar to remind you about boss abilities at life percent.",
          ["Key"] = "option1",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_label",
          ["Desc"] = "",
        }, -- [1]
        {
          ["Type"] = 1,
          ["Name"] = "Vertical Line Color",
          ["Value"] = {
            1, -- [1]
            1, -- [2]
            1, -- [3]
            1, -- [4]
          },
          ["Key"] = "indicatorColor",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
          ["Desc"] = "Indicator color.",
        }, -- [2]
        {
          ["Type"] = 2,
          ["Max"] = 1,
          ["Desc"] = "Indicator alpha.",
          ["Min"] = 0.1,
          ["Fraction"] = true,
          ["Value"] = 0.85,
          ["Name"] = "Vertical Line Alpha",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Key"] = "indicatorAlpha",
        }, -- [3]
        {
          ["Type"] = 6,
          ["Name"] = "blank line",
          ["Value"] = 0,
          ["Key"] = "",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [4]
        {
          ["Type"] = 1,
          ["Name"] = "Fill Color",
          ["Value"] = {
            0, -- [1]
            0, -- [2]
            0, -- [3]
            1, -- [4]
          },
          ["Key"] = "fillColor",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
          ["Desc"] = "Fill color.",
        }, -- [5]
        {
          ["Type"] = 2,
          ["Max"] = 1,
          ["Desc"] = "Fill alpha.",
          ["Min"] = 0,
          ["Fraction"] = true,
          ["Value"] = 0.5,
          ["Name"] = "Fill Alpha",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Key"] = "fillAlpha",
        }, -- [6]
      },
      ["OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    if unitFrame.IsSelf or (Plater.ZoneInstanceType == \"arena\" or Plater.ZoneInstanceType == \"pvp\") then return end\n    \n    envTable.UpdateMarkers(unitFrame)    \nend    \n\n\n",
      ["Name"] = "Add - Health Markers [OPS]",
      ["Author"] = "Aelerolor-Torghast",
      ["Initialization"] = "function (scriptTable)\n    \n    scriptTable.lifePercent = {\n        -- Azure Vault\n        [186738] = {75, 50, 25}, -- Umbrelskul\n        \n        -- Court of Stars\n        [104215] = {25}, -- Patrol Captain Gerdo\n        \n        -- Halls of Valor\n        [94960] = {10}, -- Hymdall\n        [95674] = {60}, -- Fenryr\n        [95676] = {80}, -- Odyn\n        \n        -- Nokhud Offensive\n        [186151] = {60}, -- Balakar Khan\n        \n        -- Ruby Life Pools\n        [188252] = {75, 45}, -- Melidrussa\n        [190484] = {50}, -- Kyrakka\n        [197697] = {50}, -- Flamegullet\n        \n        -- Shadowmoon Burial Grounds\n        [76057] = {20}, -- Carrion Worm\n        \n        -- Temple of the Jade Serpent\n        [56732] = {70, 30}, -- Liu Flameheart\n        [59544] = {50}, -- The Nodding Tiger\n        \n        -- Vault of the Incarnates\n        [187967] = {5}, -- Sennarth\n        [189492] = {65}, -- Raszageth\n        \n        -- Neltharion's Lair\n        [91005] = {20}, -- Naraxas\n        \n        -- Neltharus\n        [194816] = {10}, -- Forgewrought Monstrosity\n        \n        -- Freehold\n        [129732] = {75}, -- Skycap'n Kragg\n        [126983] = {60, 30}, -- Harlan Sweete\n        \n        -- Uldaman\n        [184020] = {40}, -- Hulking Berserker\n        [184422] = {70, 30}, -- Emberon\n        [184580] = {10}, -- Olaf\n        [184581] = {10}, -- Baelog\n        [184582] = {10}, -- Eric \"The Swift\"\n        \n        -- Brackenhide Hollow\n        [185508] = {15}, -- Claw Fighter \n        [185528] = {15}, -- Trickclaw Mystic\n        [185534] = {15}, -- Bonebolt Hunter\n        [186121] = {4}, -- Decatriarch Wratheye \n        [186122] = {15}, -- Rira Hackclaw\n        [186124] = {15}, -- Gashtooth\n        [186125] = {15}, -- Tricktotem\n        [186206] = {15}, -- Cruel Bonecrusher\n        [186227] = {20}, -- Monstrous Decay\n        \n        -- Halls of Infusion\n        [189719] = {15}, -- Watcher Irideus\n        [190368] = {40}, -- Flamecaller Aymi\n        [190407] = {20}, -- Aqua Rager\n        \n        -- Abberus\n        [201261] = {80, 60, 40}, -- Kazzara\n    }\n    \n    scriptTable.Difficulty = {\n        [16] = { -- Mythic\n        },       \n        [15] = { -- Heroic\n        },       \n        [14] = { -- Normal\n        }, \n        [17] = { -- LFR\n        }, \n    }\nend",
      ["Desc"] = "Place a marker into the health bar to indicate when the unit will change phase or cast an important spell.",
      ["Temp_UpdateCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    if unitFrame.IsSelf or (Plater.ZoneInstanceType == \"arena\" or Plater.ZoneInstanceType == \"pvp\") then return end\n    \n    envTable.UpdateMarkers(unitFrame)    \nend    \n\n\n",
      ["Prio"] = 99,
      ["SpellIds"] = {
      },
      ["PlaterCore"] = 1,
      ["Enabled"] = true,
      ["Temp_Initialization"] = "function (scriptTable)\n    \n    scriptTable.lifePercent = {\n        -- Azure Vault\n        [186738] = {75, 50, 25}, -- Umbrelskul\n        \n        -- Court of Stars\n        [104215] = {25}, -- Patrol Captain Gerdo\n        \n        -- Halls of Valor\n        [94960] = {10}, -- Hymdall\n        [95674] = {60}, -- Fenryr\n        [95676] = {80}, -- Odyn\n        \n        -- Nokhud Offensive\n        [186151] = {60}, -- Balakar Khan\n        \n        -- Ruby Life Pools\n        [188252] = {75, 45}, -- Melidrussa\n        [190484] = {50}, -- Kyrakka\n        [197697] = {50}, -- Flamegullet\n        \n        -- Shadowmoon Burial Grounds\n        [76057] = {20}, -- Carrion Worm\n        \n        -- Temple of the Jade Serpent\n        [56732] = {70, 30}, -- Liu Flameheart\n        [59544] = {50}, -- The Nodding Tiger\n        \n        -- Vault of the Incarnates\n        [187967] = {5}, -- Sennarth\n        [189492] = {65}, -- Raszageth\n        \n        -- Neltharion's Lair\n        [91005] = {20}, -- Naraxas\n        \n        -- Neltharus\n        [194816] = {10}, -- Forgewrought Monstrosity\n        \n        -- Freehold\n        [129732] = {75}, -- Skycap'n Kragg\n        [126983] = {60, 30}, -- Harlan Sweete\n        \n        -- Uldaman\n        [184020] = {40}, -- Hulking Berserker\n        [184422] = {70, 30}, -- Emberon\n        [184580] = {10}, -- Olaf\n        [184581] = {10}, -- Baelog\n        [184582] = {10}, -- Eric \"The Swift\"\n        \n        -- Brackenhide Hollow\n        [185508] = {15}, -- Claw Fighter \n        [185528] = {15}, -- Trickclaw Mystic\n        [185534] = {15}, -- Bonebolt Hunter\n        [186121] = {4}, -- Decatriarch Wratheye \n        [186122] = {15}, -- Rira Hackclaw\n        [186124] = {15}, -- Gashtooth\n        [186125] = {15}, -- Tricktotem\n        [186206] = {15}, -- Cruel Bonecrusher\n        [186227] = {20}, -- Monstrous Decay\n        \n        -- Halls of Infusion\n        [189719] = {15}, -- Watcher Irideus\n        [190368] = {40}, -- Flamecaller Aymi\n        [190407] = {20}, -- Aqua Rager\n        \n        -- Abberus\n        [201261] = {80, 60, 40}, -- Kazzara\n    }\n    \n    scriptTable.Difficulty = {\n        [16] = { -- Mythic\n        },       \n        [15] = { -- Heroic\n        },       \n        [14] = { -- Normal\n        }, \n        [17] = { -- LFR\n        }, \n    }\nend",
      ["UpdateCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    if unitFrame.IsSelf or (Plater.ZoneInstanceType == \"arena\" or Plater.ZoneInstanceType == \"pvp\") then return end\n    \n    envTable.UpdateMarkers(unitFrame)    \nend    \n\n\n",
      ["__TrashAt"] = 1699196632,
    }, -- [6]
    {
      ["ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    local movingArrowTexture = unitFrame._movingArrowTexture\n    if (not movingArrowTexture) then\n        movingArrowTexture = self:CreateTexture(nil, \"artwork\", nil, 6)\n        unitFrame._movingArrowTexture = movingArrowTexture\n    end\n    \n    envTable.movingAnimation = envTable.movingAnimation or Plater:CreateAnimationHub (unitFrame._movingArrowTexture, \n        function() \n            unitFrame._movingArrowTexture:Show() \n            unitFrame._movingArrowTexture:SetPoint(\"left\", 0, 0)\n        end, \n        function() unitFrame._movingArrowTexture:Hide() end)\n    \n    envTable.movingAnimation:SetLooping (\"REPEAT\")\n    \n    envTable.arrowAnimation = envTable.arrowAnimation or Plater:CreateAnimation (envTable.movingAnimation, \"translation\", 1, 0.20, self:GetWidth()-16, 0)\n    \n    envTable.arrowAnimation:SetDuration(scriptTable.config.animSpeed)\nend\n\n\n\n\n\n\n",
      ["OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    envTable.movingAnimation:Stop()\nend\n\n\n",
      ["OptionsValues"] = {
      },
      ["Temp_OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    unitFrame._movingArrowTexture:SetTexture([[Interface\\PETBATTLES\\PetBattle-StatIcons]])\n    unitFrame._movingArrowTexture:SetSize(16, self:GetHeight() - 2)\n    unitFrame._movingArrowTexture:SetTexCoord(unpack({0, 15/32, 18/32, 30/32}))\n    unitFrame._movingArrowTexture:SetAlpha(scriptTable.config.arrowAlpha)\n    unitFrame._movingArrowTexture:SetDesaturated(scriptTable.config.desaturateArrow)    \n    \n    unitFrame._movingArrowTexture:SetParent(self.FrameOverlay)\n    unitFrame._movingArrowTexture:SetDrawLayer(\"overlay\",  7)\n    \n    envTable.arrowAnimation:SetDuration(scriptTable.config.animSpeed)\n    envTable.movingAnimation:Play()\nend\n\n\n",
      ["ScriptType"] = 2,
      ["__TrashAt"] = 1699196920,
      ["Time"] = 1671676194,
      ["Icon"] = "Interface\\AddOns\\Plater\\images\\cast_bar_frontal",
      ["Temp_OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    envTable.movingAnimation:Stop()\nend\n\n\n",
      ["url"] = "",
      ["NpcNames"] = {
      },
      ["OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    unitFrame._movingArrowTexture:SetTexture([[Interface\\PETBATTLES\\PetBattle-StatIcons]])\n    unitFrame._movingArrowTexture:SetSize(16, self:GetHeight() - 2)\n    unitFrame._movingArrowTexture:SetTexCoord(unpack({0, 15/32, 18/32, 30/32}))\n    unitFrame._movingArrowTexture:SetAlpha(scriptTable.config.arrowAlpha)\n    unitFrame._movingArrowTexture:SetDesaturated(scriptTable.config.desaturateArrow)    \n    \n    unitFrame._movingArrowTexture:SetParent(self.FrameOverlay)\n    unitFrame._movingArrowTexture:SetDrawLayer(\"overlay\",  7)\n    \n    envTable.arrowAnimation:SetDuration(scriptTable.config.animSpeed)\n    envTable.movingAnimation:Play()\nend\n\n\n",
      ["Enabled"] = false,
      ["Revision"] = 621,
      ["Options"] = {
        {
          ["Type"] = 6,
          ["Key"] = "option1",
          ["Value"] = 0,
          ["Name"] = "Option 1",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [1]
        {
          ["Type"] = 5,
          ["Key"] = "option2",
          ["Value"] = "Produces an effect to indicate the spell will hit players in front of the enemy.",
          ["Name"] = "Option 2",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_label",
          ["Desc"] = "",
        }, -- [2]
        {
          ["Type"] = 5,
          ["Key"] = "option4",
          ["Value"] = "Enter the spell name or spellID of the Spell in the Add Trigger box and hit \"Add\".",
          ["Name"] = "Option 4",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_label",
          ["Desc"] = "",
        }, -- [3]
        {
          ["Type"] = 6,
          ["Key"] = "option3",
          ["Value"] = 0,
          ["Name"] = "Option 3",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [4]
        {
          ["Type"] = 2,
          ["Max"] = 1,
          ["Desc"] = "Set the alpha of the moving arrow",
          ["Min"] = 0,
          ["Key"] = "arrowAlpha",
          ["Value"] = 0.73,
          ["Fraction"] = true,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Arrow Alpha",
        }, -- [5]
        {
          ["Type"] = 2,
          ["Max"] = 1,
          ["Desc"] = "Time that takes for an arrow to travel from the to right.",
          ["Min"] = 0,
          ["Key"] = "animSpeed",
          ["Value"] = 0.2,
          ["Fraction"] = true,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Animation Speed",
        }, -- [6]
        {
          ["Type"] = 4,
          ["Key"] = "desaturateArrow",
          ["Value"] = false,
          ["Name"] = "Use White Arrow",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_bool",
          ["Desc"] = "If enabled, the arrow color will be desaturated.",
        }, -- [7]
      },
      ["Name"] = "Cast - Frontal Cone [Plater]",
      ["Prio"] = 99,
      ["Author"] = "Izimode-Azralon",
      ["Initialization"] = "function (scriptTable)\n    --insert code here\n    \nend\n\n\n",
      ["Desc"] = "Does an animation for casts that affect the frontal area of the enemy. Add spell in the Add Trigger field.",
      ["SpellIds"] = {
        375943, -- [1]
        385958, -- [2]
        388623, -- [3]
        377034, -- [4]
        374361, -- [5]
        381525, -- [6]
        386660, -- [7]
        384699, -- [8]
        153501, -- [9]
        153686, -- [10]
        154442, -- [11]
        192018, -- [12]
        219488, -- [13]
        372087, -- [14]
        391726, -- [15]
        391723, -- [16]
        377383, -- [17]
        388976, -- [18]
        370764, -- [19]
        387067, -- [20]
        391118, -- [21]
        391136, -- [22]
        382233, -- [23]
        209027, -- [24]
        212031, -- [25]
        207261, -- [26]
        207979, -- [27]
        198888, -- [28]
        199805, -- [29]
        199050, -- [30]
        191508, -- [31]
        152792, -- [32]
        153395, -- [33]
        209495, -- [34]
        257426, -- [35]
        255952, -- [36]
        257870, -- [37]
        413147, -- [38]
        383107, -- [39]
        377559, -- [40]
        388060, -- [41]
        376170, -- [42]
        384524, -- [43]
        375351, -- [44]
        390111, -- [45]
        369791, -- [46]
        369573, -- [47]
        369563, -- [48]
        369335, -- [49]
        369061, -- [50]
        375727, -- [51]
        265016, -- [52]
        265019, -- [53]
        260793, -- [54]
        260292, -- [55]
        272457, -- [56]
        272609, -- [57]
        269843, -- [58]
        183465, -- [59]
        226296, -- [60]
        188169, -- [61]
        183088, -- [62]
        410873, -- [63]
        411012, -- [64]
        88308, -- [65]
        382708, -- [66]
        375251, -- [67]
        375439, -- [68]
        372311, -- [69]
        373742, -- [70]
        372201, -- [71]
        374533, -- [72]
        377204, -- [73]
      },
      ["Temp_UpdateCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    unitFrame._movingArrowTexture:SetAlpha(scriptTable.config.arrowAlpha)\n    \n    local percent = envTable.movingAnimation:GetProgress()\n    \n    if (percent < 0.4) then\n        local value = Lerp(0.01, scriptTable.config.arrowAlpha, percent) or 0\n        unitFrame._movingArrowTexture:SetAlpha(Saturate(value))\n        \n    elseif (percent > 0.6) then\n        local value = Lerp(scriptTable.config.arrowAlpha, 0.01, percent) or 0\n        unitFrame._movingArrowTexture:SetAlpha(Saturate(value))\n    end\n    \n    --unitFrame._movingArrowTexture:SetAlpha(1)\n    \n    self.ThrottleUpdate = 0\nend",
      ["version"] = -1,
      ["PlaterCore"] = 1,
      ["Temp_ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    local movingArrowTexture = unitFrame._movingArrowTexture\n    if (not movingArrowTexture) then\n        movingArrowTexture = self:CreateTexture(nil, \"artwork\", nil, 6)\n        unitFrame._movingArrowTexture = movingArrowTexture\n    end\n    \n    envTable.movingAnimation = envTable.movingAnimation or Plater:CreateAnimationHub (unitFrame._movingArrowTexture, \n        function() \n            unitFrame._movingArrowTexture:Show() \n            unitFrame._movingArrowTexture:SetPoint(\"left\", 0, 0)\n        end, \n        function() unitFrame._movingArrowTexture:Hide() end)\n    \n    envTable.movingAnimation:SetLooping (\"REPEAT\")\n    \n    envTable.arrowAnimation = envTable.arrowAnimation or Plater:CreateAnimation (envTable.movingAnimation, \"translation\", 1, 0.20, self:GetWidth()-16, 0)\n    \n    envTable.arrowAnimation:SetDuration(scriptTable.config.animSpeed)\nend\n\n\n\n\n\n\n",
      ["semver"] = "",
      ["Temp_Initialization"] = "function (scriptTable)\n    --insert code here\n    \nend\n\n\n",
      ["UpdateCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    unitFrame._movingArrowTexture:SetAlpha(scriptTable.config.arrowAlpha)\n    \n    local percent = envTable.movingAnimation:GetProgress()\n    \n    if (percent < 0.4) then\n        local value = Lerp(0.01, scriptTable.config.arrowAlpha, percent) or 0\n        unitFrame._movingArrowTexture:SetAlpha(Saturate(value))\n        \n    elseif (percent > 0.6) then\n        local value = Lerp(scriptTable.config.arrowAlpha, 0.01, percent) or 0\n        unitFrame._movingArrowTexture:SetAlpha(Saturate(value))\n    end\n    \n    --unitFrame._movingArrowTexture:SetAlpha(1)\n    \n    self.ThrottleUpdate = 0\nend",
    }, -- [7]
    {
      ["ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    --castbar color (when can be interrupted)\n    envTable.CastbarColor = scriptTable.config.castbarColor\n    \n    --flash duration\n    local CONFIG_BACKGROUND_FLASH_DURATION = scriptTable.config.flashDuration\n    \n    --add this value to the cast bar height\n    envTable.CastBarHeightAdd = scriptTable.config.castBarHeight\n    \n    --create a fast flash above the cast bar\n    envTable.FullBarFlash = envTable.FullBarFlash or Plater.CreateFlash (self, 0.05, 1, \"white\")\n    \n    --create a camera shake for the nameplate\n    envTable.FrameShake = Plater:CreateFrameShake (unitFrame, scriptTable.config.shakeDuration, scriptTable.config.shakeAmplitude, scriptTable.config.shakeFrequency, false, false, 0, 1, 0.05, 0.1, Plater.GetPoints (unitFrame))\n    \n    --create a texture to use for a flash behind the cast bar\n    local backGroundFlashTexture = Plater:CreateImage (self, [[Interface\\ACHIEVEMENTFRAME\\UI-Achievement-Alert-Glow]], self:GetWidth()+60, self:GetHeight()+50, \"background\", {0, 400/512, 0, 170/256})\n    backGroundFlashTexture:SetBlendMode (\"ADD\", 7)\n    backGroundFlashTexture:SetDrawLayer(\"OVERLAY\", 7)\n    backGroundFlashTexture:SetPoint (\"center\", self, \"center\")\n    backGroundFlashTexture:Hide()\n    \n    --create the animation hub to hold the flash animation sequence\n    envTable.BackgroundFlash = envTable.BackgroundFlash or Plater:CreateAnimationHub (backGroundFlashTexture, \n        function()\n            backGroundFlashTexture:Show()\n        end,\n        function()\n            backGroundFlashTexture:Hide()\n        end\n    )\n    \n    --create the flash animation sequence\n    envTable.BackgroundFlash.fadeIn = envTable.BackgroundFlash.fadeIn or Plater:CreateAnimation (envTable.BackgroundFlash, \"ALPHA\", 1, CONFIG_BACKGROUND_FLASH_DURATION/2, 0, .75)\n    envTable.BackgroundFlash.fadeIn:SetDuration(CONFIG_BACKGROUND_FLASH_DURATION/2)\n    \n    envTable.BackgroundFlash.fadeOut = envTable.BackgroundFlash.fadeOut or Plater:CreateAnimation (envTable.BackgroundFlash, \"ALPHA\", 2, CONFIG_BACKGROUND_FLASH_DURATION/2, 1, 0)    \n    envTable.BackgroundFlash.fadeOut:SetDuration(CONFIG_BACKGROUND_FLASH_DURATION/2)\n    \n    --envTable.BackgroundFlash:Play() --envTable.BackgroundFlash:Stop()    \n    \n    \n    \n    \n    \nend\n\n\n\n\n",
      ["OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    if (not Plater.IsShowingCastBarTest) then\n        --don't execute on battlegrounds and arenas\n        if (Plater.ZoneInstanceType == \"arena\" or Plater.ZoneInstanceType == \"pvp\" or Plater.ZoneInstanceType == \"none\") then\n            return\n        end    \n    end\n    \n    unitFrame.castBar:SetHeight (envTable._DefaultHeight)\n    \n    --stop the camera shake\n    unitFrame:StopFrameShake (envTable.FrameShake)\n    \n    envTable.FullBarFlash:Stop()\n    envTable.BackgroundFlash:Stop()\n    \n    unitFrame.castBar.Spark:SetHeight(unitFrame.castBar:GetHeight())\n    \nend\n\n\n\n\n\n\n\n",
      ["OptionsValues"] = {
        ["castbarColor"] = {
          1, -- [1]
          0.43137258291245, -- [2]
          0, -- [3]
          1, -- [4]
        },
      },
      ["Temp_OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    --don't execute on battlegrounds and arenas\n    if (not Plater.IsShowingCastBarTest) then\n        if (Plater.ZoneInstanceType == \"arena\" or Plater.ZoneInstanceType == \"pvp\" or Plater.ZoneInstanceType == \"none\") then\n            return\n        end\n    end\n    \n    --play flash animations\n    envTable.FullBarFlash:Play()\n    \n    --envTable.currentHeight = unitFrame.castBar:GetHeight()\n    \n    --restoring the default size (not required since it already restore in the hide script)\n    if (envTable.OriginalHeight) then\n        self:SetHeight (envTable.OriginalHeight)\n    end\n    \n    --increase the cast bar size\n    local height = self:GetHeight()\n    envTable.OriginalHeight = height\n    \n    self:SetHeight (height + envTable.CastBarHeightAdd)\n    \n    Plater.SetCastBarBorderColor (self, 1, .2, .2, 0.4)\n    \n    unitFrame:PlayFrameShake (envTable.FrameShake)\n    \n    --set the color of the cast bar to dark orange (only if can be interrupted)\n    --Plater auto set this color to default when a new cast starts, no need to reset this value at OnHide.    \n    if (envTable._CanInterrupt) then\n        if (scriptTable.config.useCastbarColor) then\n            self:SetStatusBarColor (Plater:ParseColors (envTable.CastbarColor))\n        end\n    end\n    \n    Plater.SetCastBarColorForScript(self, scriptTable.config.useCastbarColor, scriptTable.config.castbarColor, envTable)\n    \n    envTable.BackgroundFlash:Play()\n    \n    unitFrame.castBar.Spark:SetHeight(unitFrame.castBar:GetHeight())\n    \nend\n\n\n\n\n\n\n\n\n\n\n\n\n",
      ["ScriptType"] = 2,
      ["__TrashAt"] = 1699196934,
      ["Time"] = 1674873416,
      ["Icon"] = "Interface\\AddOns\\Plater\\images\\cast_bar_orange",
      ["Temp_OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    if (not Plater.IsShowingCastBarTest) then\n        --don't execute on battlegrounds and arenas\n        if (Plater.ZoneInstanceType == \"arena\" or Plater.ZoneInstanceType == \"pvp\" or Plater.ZoneInstanceType == \"none\") then\n            return\n        end    \n    end\n    \n    unitFrame.castBar:SetHeight (envTable._DefaultHeight)\n    \n    --stop the camera shake\n    unitFrame:StopFrameShake (envTable.FrameShake)\n    \n    envTable.FullBarFlash:Stop()\n    envTable.BackgroundFlash:Stop()\n    \n    unitFrame.castBar.Spark:SetHeight(unitFrame.castBar:GetHeight())\n    \nend\n\n\n\n\n\n\n\n",
      ["url"] = "",
      ["NpcNames"] = {
      },
      ["OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    --don't execute on battlegrounds and arenas\n    if (not Plater.IsShowingCastBarTest) then\n        if (Plater.ZoneInstanceType == \"arena\" or Plater.ZoneInstanceType == \"pvp\" or Plater.ZoneInstanceType == \"none\") then\n            return\n        end\n    end\n    \n    --play flash animations\n    envTable.FullBarFlash:Play()\n    \n    --envTable.currentHeight = unitFrame.castBar:GetHeight()\n    \n    --restoring the default size (not required since it already restore in the hide script)\n    if (envTable.OriginalHeight) then\n        self:SetHeight (envTable.OriginalHeight)\n    end\n    \n    --increase the cast bar size\n    local height = self:GetHeight()\n    envTable.OriginalHeight = height\n    \n    self:SetHeight (height + envTable.CastBarHeightAdd)\n    \n    Plater.SetCastBarBorderColor (self, 1, .2, .2, 0.4)\n    \n    unitFrame:PlayFrameShake (envTable.FrameShake)\n    \n    --set the color of the cast bar to dark orange (only if can be interrupted)\n    --Plater auto set this color to default when a new cast starts, no need to reset this value at OnHide.    \n    if (envTable._CanInterrupt) then\n        if (scriptTable.config.useCastbarColor) then\n            self:SetStatusBarColor (Plater:ParseColors (envTable.CastbarColor))\n        end\n    end\n    \n    Plater.SetCastBarColorForScript(self, scriptTable.config.useCastbarColor, scriptTable.config.castbarColor, envTable)\n    \n    envTable.BackgroundFlash:Play()\n    \n    unitFrame.castBar.Spark:SetHeight(unitFrame.castBar:GetHeight())\n    \nend\n\n\n\n\n\n\n\n\n\n\n\n\n",
      ["Enabled"] = false,
      ["Revision"] = 1255,
      ["Options"] = {
        {
          ["Type"] = 6,
          ["Key"] = "option1",
          ["Value"] = 0,
          ["Name"] = "Blank Line",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [1]
        {
          ["Type"] = 5,
          ["Key"] = "option2",
          ["Value"] = "Produces a notable effect in the cast bar when a spell from the 'Triggers' starts to cast.",
          ["Name"] = "Option 2",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_label",
          ["Desc"] = "",
        }, -- [2]
        {
          ["Type"] = 5,
          ["Key"] = "option3",
          ["Value"] = "Enter the spell name or spellID of the Spell in the Add Trigger box and hit \"Add\".",
          ["Name"] = "Option 3",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_label",
          ["Desc"] = "",
        }, -- [3]
        {
          ["Type"] = 6,
          ["Key"] = "option4",
          ["Value"] = 0,
          ["Name"] = "Blank Space",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [4]
        {
          ["Type"] = 4,
          ["Key"] = "useCastbarColor",
          ["Value"] = true,
          ["Name"] = "Cast Bar Color Enabled",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_bool",
          ["Desc"] = "When enabled, changes the cast bar color,",
        }, -- [5]
        {
          ["Type"] = 1,
          ["Key"] = "castbarColor",
          ["Value"] = {
            1, -- [1]
            0.43137254901961, -- [2]
            0, -- [3]
            1, -- [4]
          },
          ["Name"] = "Cast Bar Color",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
          ["Desc"] = "Color of the cast bar.",
        }, -- [6]
        {
          ["Type"] = 6,
          ["Key"] = "option7",
          ["Value"] = 0,
          ["Name"] = "Blank Line",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [7]
        {
          ["Type"] = 2,
          ["Max"] = 1,
          ["Desc"] = "When the cast starts it flash rapidly, adjust how fast it flashes. Value is milliseconds.",
          ["Min"] = 0.05,
          ["Key"] = "flashDuration",
          ["Value"] = 0.4,
          ["Fraction"] = true,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Flash Duration",
        }, -- [8]
        {
          ["Type"] = 2,
          ["Max"] = 10,
          ["Desc"] = "Increases the cast bar height by this value",
          ["Min"] = 0,
          ["Key"] = "castBarHeight",
          ["Value"] = 5,
          ["Fraction"] = false,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Cast Bar Height Mod",
        }, -- [9]
        {
          ["Type"] = 2,
          ["Max"] = 1,
          ["Desc"] = "When the cast starts, there's a small shake in the nameplate, this settings controls how long it takes.",
          ["Min"] = 0.1,
          ["Key"] = "shakeDuration",
          ["Value"] = 0.2,
          ["Fraction"] = true,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Shake Duration",
        }, -- [10]
        {
          ["Type"] = 2,
          ["Max"] = 100,
          ["Desc"] = "How strong is the shake.",
          ["Min"] = 2,
          ["Key"] = "shakeAmplitude",
          ["Value"] = 8,
          ["Fraction"] = false,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Shake Amplitude",
        }, -- [11]
        {
          ["Type"] = 2,
          ["Max"] = 80,
          ["Desc"] = "How fast the shake moves.",
          ["Min"] = 1,
          ["Key"] = "shakeFrequency",
          ["Value"] = 40,
          ["Fraction"] = false,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Shake Frequency",
        }, -- [12]
      },
      ["Name"] = "Cast - Big Alert [Plater]",
      ["Prio"] = 99,
      ["Author"] = "Tercioo-Sylvanas",
      ["Initialization"] = "function (scriptTable)\n    --insert code here\n    \nend",
      ["Desc"] = "Flash, Bounce and Red Color the CastBar border when when an important cast is happening. Add spell in the Add Trigger field.",
      ["SpellIds"] = {
        396640, -- [1]
        372743, -- [2]
        377389, -- [3]
        396812, -- [4]
        387955, -- [5]
        386546, -- [6]
        384808, -- [7]
        386024, -- [8]
        387615, -- [9]
        387606, -- [10]
        225100, -- [11]
        211401, -- [12]
        211470, -- [13]
        215433, -- [14]
        192563, -- [15]
        198959, -- [16]
        152818, -- [17]
        156776, -- [18]
        398206, -- [19]
        153524, -- [20]
        396073, -- [21]
        396018, -- [22]
        345202, -- [23]
        377950, -- [24]
        372223, -- [25]
        385578, -- [26]
        377488, -- [27]
        375596, -- [28]
        263365, -- [29]
        388392, -- [30]
        395859, -- [31]
        395872, -- [32]
        397914, -- [33]
        209410, -- [34]
        215433, -- [35]
        373395, -- [36]
        384194, -- [37]
        392451, -- [38]
        392924, -- [39]
        397889, -- [40]
        209413, -- [41]
        207980, -- [42]
        257397, -- [43]
        257736, -- [44]
        382787, -- [45]
        374699, -- [46]
        377402, -- [47]
        369602, -- [48]
        369465, -- [49]
        369400, -- [50]
        381593, -- [51]
        265091, -- [52]
        265433, -- [53]
        382791, -- [54]
        376780, -- [55]
      },
      ["Temp_UpdateCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \nend\n\n\n",
      ["version"] = -1,
      ["PlaterCore"] = 1,
      ["Temp_ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    --castbar color (when can be interrupted)\n    envTable.CastbarColor = scriptTable.config.castbarColor\n    \n    --flash duration\n    local CONFIG_BACKGROUND_FLASH_DURATION = scriptTable.config.flashDuration\n    \n    --add this value to the cast bar height\n    envTable.CastBarHeightAdd = scriptTable.config.castBarHeight\n    \n    --create a fast flash above the cast bar\n    envTable.FullBarFlash = envTable.FullBarFlash or Plater.CreateFlash (self, 0.05, 1, \"white\")\n    \n    --create a camera shake for the nameplate\n    envTable.FrameShake = Plater:CreateFrameShake (unitFrame, scriptTable.config.shakeDuration, scriptTable.config.shakeAmplitude, scriptTable.config.shakeFrequency, false, false, 0, 1, 0.05, 0.1, Plater.GetPoints (unitFrame))\n    \n    --create a texture to use for a flash behind the cast bar\n    local backGroundFlashTexture = Plater:CreateImage (self, [[Interface\\ACHIEVEMENTFRAME\\UI-Achievement-Alert-Glow]], self:GetWidth()+60, self:GetHeight()+50, \"background\", {0, 400/512, 0, 170/256})\n    backGroundFlashTexture:SetBlendMode (\"ADD\", 7)\n    backGroundFlashTexture:SetDrawLayer(\"OVERLAY\", 7)\n    backGroundFlashTexture:SetPoint (\"center\", self, \"center\")\n    backGroundFlashTexture:Hide()\n    \n    --create the animation hub to hold the flash animation sequence\n    envTable.BackgroundFlash = envTable.BackgroundFlash or Plater:CreateAnimationHub (backGroundFlashTexture, \n        function()\n            backGroundFlashTexture:Show()\n        end,\n        function()\n            backGroundFlashTexture:Hide()\n        end\n    )\n    \n    --create the flash animation sequence\n    envTable.BackgroundFlash.fadeIn = envTable.BackgroundFlash.fadeIn or Plater:CreateAnimation (envTable.BackgroundFlash, \"ALPHA\", 1, CONFIG_BACKGROUND_FLASH_DURATION/2, 0, .75)\n    envTable.BackgroundFlash.fadeIn:SetDuration(CONFIG_BACKGROUND_FLASH_DURATION/2)\n    \n    envTable.BackgroundFlash.fadeOut = envTable.BackgroundFlash.fadeOut or Plater:CreateAnimation (envTable.BackgroundFlash, \"ALPHA\", 2, CONFIG_BACKGROUND_FLASH_DURATION/2, 1, 0)    \n    envTable.BackgroundFlash.fadeOut:SetDuration(CONFIG_BACKGROUND_FLASH_DURATION/2)\n    \n    --envTable.BackgroundFlash:Play() --envTable.BackgroundFlash:Stop()    \n    \n    \n    \n    \n    \nend\n\n\n\n\n",
      ["semver"] = "",
      ["Temp_Initialization"] = "function (scriptTable)\n    --insert code here\n    \nend",
      ["UpdateCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \nend\n\n\n",
    }, -- [8]
    {
      ["ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    --insert code here\n    \n    local plateFrame = unitFrame.PlateFrame\n    \n    if (not plateFrame.BWC_RedBackground) then\n        plateFrame.BWC_RedBackground = plateFrame:CreateTexture(nil, \"background\")\n        plateFrame.BWC_RedBackground:SetAllPoints()\n    end\n    \n    plateFrame.BWC_RedBackground:SetTexture([[Interface/AddOns/Plater/masks/mask1]])\n    plateFrame.BWC_RedBackground:Hide()\n    \n    function envTable.ShowBackground(unitFrame)\n        local plateFrame = unitFrame.PlateFrame\n        plateFrame.BWC_RedBackground:SetVertexColor(1, 0, 0, 0.4)\n        plateFrame.BWC_RedBackground:Show()\n    end\n    \n    function envTable.HideBackground(unitFrame)\n        plateFrame.BWC_RedBackground:Hide()\n    end\nend\n\n\n\n\n\n\n",
      ["OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    --insert code here\n    envTable.HideBackground(unitFrame)\nend\n\n\n",
      ["OptionsValues"] = {
      },
      ["Temp_OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    --insert code here\n    \nend\n\n\n",
      ["ScriptType"] = 1,
      ["__TrashAt"] = 1699196947,
      ["Time"] = 1674873410,
      ["Icon"] = 236209,
      ["Temp_OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    --insert code here\n    envTable.HideBackground(unitFrame)\nend\n\n\n",
      ["url"] = "",
      ["NpcNames"] = {
      },
      ["OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    --insert code here\n    \nend\n\n\n",
      ["Enabled"] = true,
      ["Revision"] = 19,
      ["Options"] = {
      },
      ["Name"] = "Aura While Casting [P]",
      ["Prio"] = 99,
      ["Author"] = "Tiranaa-Azralon",
      ["Initialization"] = "		function (scriptTable)\n			--insert code here\n			\n		end\n	",
      ["Desc"] = "Highlight the nameplate of a unit when has a certain Buff (trigger) and start to cast a spell",
      ["SpellIds"] = {
        372743, -- [1]
        372749, -- [2]
        384933, -- [3]
      },
      ["Temp_UpdateCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    if (Plater.UnitIsCasting(unitId)) then\n        envTable.ShowBackground(unitFrame)\n    else\n        envTable.HideBackground(unitFrame)\n    end\n    \nend",
      ["version"] = -1,
      ["PlaterCore"] = 1,
      ["Temp_ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    --insert code here\n    \n    local plateFrame = unitFrame.PlateFrame\n    \n    if (not plateFrame.BWC_RedBackground) then\n        plateFrame.BWC_RedBackground = plateFrame:CreateTexture(nil, \"background\")\n        plateFrame.BWC_RedBackground:SetAllPoints()\n    end\n    \n    plateFrame.BWC_RedBackground:SetTexture([[Interface/AddOns/Plater/masks/mask1]])\n    plateFrame.BWC_RedBackground:Hide()\n    \n    function envTable.ShowBackground(unitFrame)\n        local plateFrame = unitFrame.PlateFrame\n        plateFrame.BWC_RedBackground:SetVertexColor(1, 0, 0, 0.4)\n        plateFrame.BWC_RedBackground:Show()\n    end\n    \n    function envTable.HideBackground(unitFrame)\n        plateFrame.BWC_RedBackground:Hide()\n    end\nend\n\n\n\n\n\n\n",
      ["semver"] = "",
      ["Temp_Initialization"] = "		function (scriptTable)\n			--insert code here\n			\n		end\n	",
      ["UpdateCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    if (Plater.UnitIsCasting(unitId)) then\n        envTable.ShowBackground(unitFrame)\n    else\n        envTable.HideBackground(unitFrame)\n    end\n    \nend",
    }, -- [9]
    {
      ["ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    --creates a glow around the icon\n    envTable.buffIconGlow = envTable.buffIconGlow or Plater.CreateIconGlow (self, scriptTable.config.glowColor)\n    \nend\n\n\n",
      ["OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    if (scriptTable.config.glowEnabled) then\n        envTable.buffIconGlow:Hide()\n    end\n    \n    if (scriptTable.config.dotsEnabled) then\n        Plater.StopDotAnimation(self, envTable.dotAnimation)\n    end\n    \n    \nend\n\n\n",
      ["OptionsValues"] = {
      },
      ["Temp_OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    if (scriptTable.config.glowEnabled) then\n        envTable.buffIconGlow:Show()\n    end\n    \n    if (scriptTable.config.dotsEnabled) then\n        envTable.dotAnimation = Plater.PlayDotAnimation(self, 6, scriptTable.config.dotsColor, 6, 3) \n    end\nend\n\n\n",
      ["ScriptType"] = 1,
      ["UpdateCode"] = "function (self, unitId, unitFrame, envTable)\n    \nend\n\n\n",
      ["Time"] = 1674873408,
      ["Temp_ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    --creates a glow around the icon\n    envTable.buffIconGlow = envTable.buffIconGlow or Plater.CreateIconGlow (self, scriptTable.config.glowColor)\n    \nend\n\n\n",
      ["NpcNames"] = {
      },
      ["semver"] = "",
      ["Enabled"] = true,
      ["Revision"] = 369,
      ["Options"] = {
        {
          ["Type"] = 6,
          ["Key"] = "option1",
          ["Value"] = 0,
          ["Name"] = "Blank Space",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [1]
        {
          ["Type"] = 5,
          ["Key"] = "option2",
          ["Value"] = "Enter the spell name or spellID of the Buff in the Add Trigger box and hit \"Add\".",
          ["Name"] = "Option 2",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_label",
          ["Desc"] = "",
        }, -- [2]
        {
          ["Type"] = 6,
          ["Key"] = "option3",
          ["Value"] = 0,
          ["Name"] = "Blank Space",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [3]
        {
          ["Type"] = 4,
          ["Key"] = "glowEnabled",
          ["Value"] = false,
          ["Name"] = "Glow Enabled",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_bool",
          ["Desc"] = "",
        }, -- [4]
        {
          ["Type"] = 1,
          ["Key"] = "glowColor",
          ["Value"] = {
            0.40392156862745, -- [1]
            0.003921568627451, -- [2]
            0, -- [3]
            1, -- [4]
          },
          ["Name"] = "Glow Color",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
          ["Desc"] = "",
        }, -- [5]
        {
          ["Type"] = 6,
          ["Key"] = "option3",
          ["Value"] = 0,
          ["Name"] = "Blank Space",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [6]
        {
          ["Type"] = 4,
          ["Key"] = "dotsEnabled",
          ["Value"] = true,
          ["Name"] = "Dots Enabled",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_bool",
          ["Desc"] = "",
        }, -- [7]
        {
          ["Type"] = 1,
          ["Key"] = "dotsColor",
          ["Value"] = {
            1, -- [1]
            0.32156862745098, -- [2]
            0, -- [3]
            1, -- [4]
          },
          ["Name"] = "Dots Color",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
          ["Desc"] = "",
        }, -- [8]
      },
      ["OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    if (scriptTable.config.glowEnabled) then\n        envTable.buffIconGlow:Show()\n    end\n    \n    if (scriptTable.config.dotsEnabled) then\n        envTable.dotAnimation = Plater.PlayDotAnimation(self, 6, scriptTable.config.dotsColor, 6, 3) \n    end\nend\n\n\n",
      ["version"] = -1,
      ["Author"] = "Tercioo-Sylvanas",
      ["Prio"] = 99,
      ["Desc"] = "Add the debuff name in the trigger box.",
      ["SpellIds"] = {
      },
      ["Temp_UpdateCode"] = "function (self, unitId, unitFrame, envTable)\n    \nend\n\n\n",
      ["Name"] = "Aura - Debuff Alert [Plater]",
      ["PlaterCore"] = 1,
      ["Temp_OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    if (scriptTable.config.glowEnabled) then\n        envTable.buffIconGlow:Hide()\n    end\n    \n    if (scriptTable.config.dotsEnabled) then\n        Plater.StopDotAnimation(self, envTable.dotAnimation)\n    end\n    \n    \nend\n\n\n",
      ["Icon"] = "Interface\\AddOns\\Plater\\images\\icon_aura",
      ["url"] = "",
      ["__TrashAt"] = 1699196958,
    }, -- [10]
    {
      ["ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    --creates a glow around the icon\n    envTable.buffIconGlow = envTable.buffIconGlow or Plater.CreateIconGlow (self, scriptTable.config.glowColor)\n    \nend",
      ["OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    if (scriptTable.config.glowEnabled) then\n        envTable.buffIconGlow:Hide()\n    end\n    \n    if (scriptTable.config.dotsEnabled) then\n        Plater.StopDotAnimation(self, envTable.dotAnimation)\n    end\n    \n    \nend",
      ["OptionsValues"] = {
      },
      ["Temp_OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    if (scriptTable.config.glowEnabled) then\n        envTable.buffIconGlow:Show()\n    end\n    \n    if (scriptTable.config.dotsEnabled) then\n        envTable.dotAnimation = Plater.PlayDotAnimation(self, 6, scriptTable.config.dotsColor, 6, 3) \n    end\n    \nend\n\n\n\n\n",
      ["ScriptType"] = 1,
      ["__TrashAt"] = 1699196967,
      ["Time"] = 1674873407,
      ["Icon"] = "Interface\\AddOns\\Plater\\images\\icon_aura",
      ["Temp_OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    if (scriptTable.config.glowEnabled) then\n        envTable.buffIconGlow:Hide()\n    end\n    \n    if (scriptTable.config.dotsEnabled) then\n        Plater.StopDotAnimation(self, envTable.dotAnimation)\n    end\n    \n    \nend",
      ["url"] = "",
      ["NpcNames"] = {
      },
      ["OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    if (scriptTable.config.glowEnabled) then\n        envTable.buffIconGlow:Show()\n    end\n    \n    if (scriptTable.config.dotsEnabled) then\n        envTable.dotAnimation = Plater.PlayDotAnimation(self, 6, scriptTable.config.dotsColor, 6, 3) \n    end\n    \nend\n\n\n\n\n",
      ["Enabled"] = true,
      ["Revision"] = 634,
      ["Options"] = {
        {
          ["Type"] = 6,
          ["Key"] = "option1",
          ["Value"] = 0,
          ["Name"] = "Blank Space",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [1]
        {
          ["Type"] = 5,
          ["Key"] = "option2",
          ["Value"] = "Enter the spell name or spellID of the Buff in the Add Trigger box and hit \"Add\".",
          ["Name"] = "Option 2",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_label",
          ["Desc"] = "",
        }, -- [2]
        {
          ["Type"] = 6,
          ["Key"] = "option3",
          ["Value"] = 0,
          ["Name"] = "Blank Space",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [3]
        {
          ["Type"] = 4,
          ["Key"] = "glowEnabled",
          ["Value"] = false,
          ["Name"] = "Glow Enabled",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_bool",
          ["Desc"] = "",
        }, -- [4]
        {
          ["Type"] = 1,
          ["Key"] = "glowColor",
          ["Value"] = {
            0.40392156862745, -- [1]
            0.003921568627451, -- [2]
            0, -- [3]
            1, -- [4]
          },
          ["Name"] = "Glow Color",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
          ["Desc"] = "",
        }, -- [5]
        {
          ["Type"] = 6,
          ["Key"] = "option3",
          ["Value"] = 0,
          ["Name"] = "Blank Space",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [6]
        {
          ["Type"] = 4,
          ["Key"] = "dotsEnabled",
          ["Value"] = true,
          ["Name"] = "Dots Enabled",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_bool",
          ["Desc"] = "",
        }, -- [7]
        {
          ["Type"] = 1,
          ["Key"] = "dotsColor",
          ["Value"] = {
            1, -- [1]
            0.32156862745098, -- [2]
            0, -- [3]
            1, -- [4]
          },
          ["Name"] = "Dots Color",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
          ["Desc"] = "",
        }, -- [8]
      },
      ["Name"] = "Aura - Buff Alert [Plater]",
      ["Prio"] = 99,
      ["Author"] = "Tercioo-Sylvanas",
      ["Initialization"] = "function (scriptTable)\n    --insert code here\n    \nend\n\n\n",
      ["Desc"] = "Add the buff name in the trigger box.",
      ["SpellIds"] = {
        398151, -- [1]
        375596, -- [2]
        377738, -- [3]
        378149, -- [4]
      },
      ["Temp_UpdateCode"] = "function (self, unitId, unitFrame, envTable)\n    \n    \n    \n    \nend",
      ["version"] = -1,
      ["PlaterCore"] = 1,
      ["Temp_ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    --creates a glow around the icon\n    envTable.buffIconGlow = envTable.buffIconGlow or Plater.CreateIconGlow (self, scriptTable.config.glowColor)\n    \nend",
      ["semver"] = "",
      ["Temp_Initialization"] = "function (scriptTable)\n    --insert code here\n    \nend\n\n\n",
      ["UpdateCode"] = "function (self, unitId, unitFrame, envTable)\n    \n    \n    \n    \nend",
    }, -- [11]
    {
      ["ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    envTable.lifePercent = { --dragonflight\n        [197697] = {50}, --Flamegullet\n        [59544] = {50}, --The Nodding Tiger\n        [186227] = {20}, --Monstrous Decay\n        [184020] = {40}, -- Hulking Berserker\n        [91005] = {20}, --Naraxas\n    }\n    \n    \n    function envTable.CreateMarker(unitFrame)\n        unitFrame.healthMarker = unitFrame.healthBar:CreateTexture(nil, \"overlay\")\n        unitFrame.healthMarker:SetColorTexture(1, 1, 1)\n        unitFrame.healthMarker:SetSize(1, unitFrame.healthBar:GetHeight())\n        \n        unitFrame.healthOverlay = unitFrame.healthBar:CreateTexture(nil, \"overlay\")\n        unitFrame.healthOverlay:SetColorTexture(1, 1, 1)\n        unitFrame.healthOverlay:SetSize(1, unitFrame.healthBar:GetHeight())\n    end\n    \n    function envTable.UpdateMarkers(unitFrame)\n        local markersTable = envTable.lifePercent[envTable._NpcID]\n        if (markersTable) then\n            local unitLifePercent = envTable._HealthPercent / 100\n            for i, percent in ipairs(markersTable) do\n                percent = percent / 100\n                if (unitLifePercent > percent) then\n                    if (not unitFrame.healthMarker) then\n                        envTable.CreateMarker(unitFrame)\n                    end\n                    \n                    unitFrame.healthMarker:Show()\n                    local width = unitFrame.healthBar:GetWidth()\n                    unitFrame.healthMarker:SetPoint(\"left\", unitFrame.healthBar, \"left\", width*percent, 0)\n                    \n                    local overlaySize = width * (unitLifePercent - percent)\n                    unitFrame.healthOverlay:SetWidth(overlaySize)\n                    unitFrame.healthOverlay:SetPoint(\"left\", unitFrame.healthMarker, \"right\", 0, 0)\n                    \n                    unitFrame.healthMarker:SetVertexColor(Plater:ParseColors(scriptTable.config.indicatorColor))\n                    unitFrame.healthMarker:SetAlpha(scriptTable.config.indicatorAlpha)\n                    \n                    unitFrame.healthOverlay:SetVertexColor(Plater:ParseColors(scriptTable.config.fillColor))\n                    unitFrame.healthOverlay:SetAlpha(scriptTable.config.fillAlpha)\n                    \n                    return\n                end\n            end --end for\n            \n            if (unitFrame.healthMarker and unitFrame.healthMarker:IsShown()) then\n                unitFrame.healthMarker:Hide()\n                unitFrame.healthOverlay:Hide()\n            end\n        end\n    end\nend      \n\n\n\n\n\n\n\n\n\n",
      ["OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    if (unitFrame.healthMarker) then\n        unitFrame.healthMarker:Hide()\n        unitFrame.healthOverlay:Hide()\n    end\nend\n\n\n\n\n",
      ["OptionsValues"] = {
        ["fillColor"] = {
          1, -- [1]
          1, -- [2]
          1, -- [3]
          1, -- [4]
        },
        ["indicatorAlpha"] = 0.798833966255188,
        ["indicatorColor"] = {
          1, -- [1]
          1, -- [2]
          1, -- [3]
          1, -- [4]
        },
      },
      ["Temp_OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    --insert code here\n    envTable.UpdateMarkers(unitFrame)\nend\n\n\n",
      ["ScriptType"] = 3,
      ["__TrashAt"] = 1699196976,
      ["Time"] = 1693227008,
      ["Icon"] = "Interface\\AddOns\\Plater\\images\\health_indicator",
      ["Temp_OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    if (unitFrame.healthMarker) then\n        unitFrame.healthMarker:Hide()\n        unitFrame.healthOverlay:Hide()\n    end\nend\n\n\n\n\n",
      ["url"] = "",
      ["NpcNames"] = {
        "197697", -- [1]
        "59544", -- [2]
        "186227", -- [3]
        "184020", -- [4]
        "91005", -- [5]
      },
      ["OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    --insert code here\n    envTable.UpdateMarkers(unitFrame)\nend\n\n\n",
      ["Enabled"] = false,
      ["Revision"] = 153,
      ["Options"] = {
        {
          ["Type"] = 5,
          ["Key"] = "option1",
          ["Value"] = "Add markers into the health bar to remind you about boss abilities at life percent.",
          ["Name"] = "Option 1",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_label",
          ["Desc"] = "",
        }, -- [1]
        {
          ["Type"] = 6,
          ["Key"] = "",
          ["Value"] = 0,
          ["Name"] = "blank line",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [2]
        {
          ["Type"] = 1,
          ["Key"] = "indicatorColor",
          ["Value"] = {
            1, -- [1]
            1, -- [2]
            1, -- [3]
            1, -- [4]
          },
          ["Name"] = "Vertical Line Color",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
          ["Desc"] = "Indicator color.",
        }, -- [3]
        {
          ["Type"] = 2,
          ["Max"] = 1,
          ["Desc"] = "Indicator alpha.",
          ["Min"] = 0.1,
          ["Key"] = "indicatorAlpha",
          ["Value"] = 0.79,
          ["Fraction"] = true,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Vertical Line Alpha",
        }, -- [4]
        {
          ["Type"] = 6,
          ["Key"] = "",
          ["Value"] = 0,
          ["Name"] = "blank line",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [5]
        {
          ["Type"] = 1,
          ["Key"] = "fillColor",
          ["Value"] = {
            1, -- [1]
            1, -- [2]
            1, -- [3]
            1, -- [4]
          },
          ["Name"] = "Fill Color",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
          ["Desc"] = "Fill color.",
        }, -- [6]
        {
          ["Type"] = 2,
          ["Max"] = 1,
          ["Desc"] = "Fill alpha.",
          ["Min"] = 0,
          ["Key"] = "fillAlpha",
          ["Value"] = 0.2,
          ["Fraction"] = true,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Fill Alpha",
        }, -- [7]
      },
      ["Name"] = "Add - Health Markers [P]",
      ["Prio"] = 99,
      ["Author"] = "Aelerolor-Torghast",
      ["Initialization"] = "function (scriptTable)\n    --insert code here\n    \nend\n\n\n",
      ["Desc"] = "Place a marker into the health bar to indicate when the unit will change phase or cast an important spell.",
      ["SpellIds"] = {
      },
      ["Temp_UpdateCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    --insert code here\n    envTable.UpdateMarkers(unitFrame)\nend\n\n\n",
      ["version"] = -1,
      ["PlaterCore"] = 1,
      ["Temp_ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    envTable.lifePercent = { --dragonflight\n        [197697] = {50}, --Flamegullet\n        [59544] = {50}, --The Nodding Tiger\n        [186227] = {20}, --Monstrous Decay\n        [184020] = {40}, -- Hulking Berserker\n        [91005] = {20}, --Naraxas\n    }\n    \n    \n    function envTable.CreateMarker(unitFrame)\n        unitFrame.healthMarker = unitFrame.healthBar:CreateTexture(nil, \"overlay\")\n        unitFrame.healthMarker:SetColorTexture(1, 1, 1)\n        unitFrame.healthMarker:SetSize(1, unitFrame.healthBar:GetHeight())\n        \n        unitFrame.healthOverlay = unitFrame.healthBar:CreateTexture(nil, \"overlay\")\n        unitFrame.healthOverlay:SetColorTexture(1, 1, 1)\n        unitFrame.healthOverlay:SetSize(1, unitFrame.healthBar:GetHeight())\n    end\n    \n    function envTable.UpdateMarkers(unitFrame)\n        local markersTable = envTable.lifePercent[envTable._NpcID]\n        if (markersTable) then\n            local unitLifePercent = envTable._HealthPercent / 100\n            for i, percent in ipairs(markersTable) do\n                percent = percent / 100\n                if (unitLifePercent > percent) then\n                    if (not unitFrame.healthMarker) then\n                        envTable.CreateMarker(unitFrame)\n                    end\n                    \n                    unitFrame.healthMarker:Show()\n                    local width = unitFrame.healthBar:GetWidth()\n                    unitFrame.healthMarker:SetPoint(\"left\", unitFrame.healthBar, \"left\", width*percent, 0)\n                    \n                    local overlaySize = width * (unitLifePercent - percent)\n                    unitFrame.healthOverlay:SetWidth(overlaySize)\n                    unitFrame.healthOverlay:SetPoint(\"left\", unitFrame.healthMarker, \"right\", 0, 0)\n                    \n                    unitFrame.healthMarker:SetVertexColor(Plater:ParseColors(scriptTable.config.indicatorColor))\n                    unitFrame.healthMarker:SetAlpha(scriptTable.config.indicatorAlpha)\n                    \n                    unitFrame.healthOverlay:SetVertexColor(Plater:ParseColors(scriptTable.config.fillColor))\n                    unitFrame.healthOverlay:SetAlpha(scriptTable.config.fillAlpha)\n                    \n                    return\n                end\n            end --end for\n            \n            if (unitFrame.healthMarker and unitFrame.healthMarker:IsShown()) then\n                unitFrame.healthMarker:Hide()\n                unitFrame.healthOverlay:Hide()\n            end\n        end\n    end\nend      \n\n\n\n\n\n\n\n\n\n",
      ["semver"] = "",
      ["Temp_Initialization"] = "function (scriptTable)\n    --insert code here\n    \nend\n\n\n",
      ["UpdateCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    --insert code here\n    envTable.UpdateMarkers(unitFrame)\nend\n\n\n",
    }, -- [12]
    {
      ["ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    function envTable.UpdateMarkers(unitFrame)\n        local npcID = envTable._NpcID\n        if not npcID then \n            if (unitFrame.healthMarker) then\n                unitFrame.healthMarker:Hide()\n                unitFrame.healthOverlay:Hide()\n            end\n            return \n        end\n        \n        local _, zoneType, diff = GetInstanceInfo()\n        local markersTable = zoneType == \"raid\" and scriptTable.Difficulty[diff][npcID] or scriptTable.lifePercent[npcID]\n        \n        if (markersTable) then\n            for _, p in ipairs(markersTable) do\n                if (envTable._HealthPercent > p) then\n                    local healthBar = unitFrame.healthBar\n                    local overlaySize = healthBar:GetWidth() * p/100\n                    \n                    if (not unitFrame.healthMarker) then\n                        unitFrame.healthMarker = healthBar:CreateTexture(nil, \"overlay\")\n                        unitFrame.healthMarker:SetColorTexture(1, 1, 1)\n                        unitFrame.healthOverlay = healthBar:CreateTexture(nil, \"overlay\")\n                        unitFrame.healthOverlay:SetColorTexture(1, 1, 1)\n                    end\n                    \n                    unitFrame.healthMarker:Show()\n                    unitFrame.healthMarker:SetSize(1, healthBar:GetHeight())\n                    unitFrame.healthMarker:SetPoint(\"left\", healthBar, \"left\", overlaySize, 0)\n                    unitFrame.healthMarker:SetVertexColor(Plater:ParseColors(scriptTable.config.indicatorColor))\n                    \n                    unitFrame.healthOverlay:Show()\n                    unitFrame.healthOverlay:SetSize(overlaySize, healthBar:GetHeight())\n                    unitFrame.healthOverlay:SetPoint(\"right\", unitFrame.healthMarker, \"left\", 0, 0)\n                    unitFrame.healthOverlay:SetVertexColor(Plater:ParseColors(scriptTable.config.fillColor))\n                    unitFrame.healthOverlay:SetAlpha(scriptTable.config.fillAlpha)\n                    \n                    return\n                end\n            end\n            \n            if (unitFrame.healthMarker) then\n                unitFrame.healthMarker:Hide()\n                unitFrame.healthOverlay:Hide()\n            end\n        end\n    end\nend",
      ["OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    if (unitFrame.healthMarker) then\n        unitFrame.healthMarker:Hide()\n        unitFrame.healthOverlay:Hide()\n    end\nend\n\n\n\n",
      ["OptionsValues"] = {
        ["fillColor"] = {
          1, -- [1]
          1, -- [2]
          1, -- [3]
          1, -- [4]
        },
        ["indicatorAlpha"] = 0.798833966255188,
        ["fillAlpha"] = 0.1540231704711914,
      },
      ["Temp_OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    if unitFrame.IsSelf or (Plater.ZoneInstanceType == \"arena\" or Plater.ZoneInstanceType == \"pvp\") then return end\n    \n    envTable.UpdateMarkers(unitFrame)    \nend    \n\n\n",
      ["ScriptType"] = 3,
      ["__TrashAt"] = 1699197137,
      ["Time"] = 1699196705,
      ["Icon"] = "Interface\\Addons\\Plater\\images\\health_indicator",
      ["Options"] = {
        {
          ["Type"] = 5,
          ["Name"] = "Option 1",
          ["Value"] = "Add markers into the health bar to remind you about boss abilities at life percent.",
          ["Key"] = "option1",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_label",
          ["Desc"] = "",
        }, -- [1]
        {
          ["Type"] = 1,
          ["Name"] = "Vertical Line Color",
          ["Value"] = {
            1, -- [1]
            1, -- [2]
            1, -- [3]
            1, -- [4]
          },
          ["Key"] = "indicatorColor",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
          ["Desc"] = "Indicator color.",
        }, -- [2]
        {
          ["Type"] = 2,
          ["Max"] = 1,
          ["Desc"] = "Indicator alpha.",
          ["Min"] = 0.1,
          ["Fraction"] = true,
          ["Value"] = 0.85,
          ["Name"] = "Vertical Line Alpha",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Key"] = "indicatorAlpha",
        }, -- [3]
        {
          ["Type"] = 6,
          ["Name"] = "blank line",
          ["Value"] = 0,
          ["Key"] = "",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [4]
        {
          ["Type"] = 1,
          ["Name"] = "Fill Color",
          ["Value"] = {
            0, -- [1]
            0, -- [2]
            0, -- [3]
            1, -- [4]
          },
          ["Key"] = "fillColor",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
          ["Desc"] = "Fill color.",
        }, -- [5]
        {
          ["Type"] = 2,
          ["Max"] = 1,
          ["Desc"] = "Fill alpha.",
          ["Min"] = 0,
          ["Fraction"] = true,
          ["Value"] = 0.5,
          ["Name"] = "Fill Alpha",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Key"] = "fillAlpha",
        }, -- [6]
      },
      ["url"] = "https://wago.io/7DvxkttTL/27",
      ["NpcNames"] = {
        "56732", -- [1]
        "59544", -- [2]
        "76057", -- [3]
        "91005", -- [4]
        "94960", -- [5]
        "95674", -- [6]
        "95676", -- [7]
        "104215", -- [8]
        "126832", -- [9]
        "126983", -- [10]
        "184020", -- [11]
        "184422", -- [12]
        "184580", -- [13]
        "184581", -- [14]
        "184582", -- [15]
        "185508", -- [16]
        "185528", -- [17]
        "185534", -- [18]
        "186121", -- [19]
        "186122", -- [20]
        "186124", -- [21]
        "186125", -- [22]
        "186151", -- [23]
        "186206", -- [24]
        "186227", -- [25]
        "186738", -- [26]
        "187967", -- [27]
        "188252", -- [28]
        "189492", -- [29]
        "189719", -- [30]
        "190368", -- [31]
        "190407", -- [32]
        "190484", -- [33]
        "194816", -- [34]
        "197697", -- [35]
        "201261", -- [36]
      },
      ["Desc"] = "Place a marker into the health bar to indicate when the unit will change phase or cast an important spell.",
      ["Temp_OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    if (unitFrame.healthMarker) then\n        unitFrame.healthMarker:Hide()\n        unitFrame.healthOverlay:Hide()\n    end\nend\n\n\n\n",
      ["Revision"] = 1515,
      ["semver"] = "1.3.4",
      ["version"] = 27,
      ["Prio"] = 99,
      ["Author"] = "Aelerolor-Torghast",
      ["Initialization"] = "function (scriptTable)\n    \n    scriptTable.lifePercent = {\n        -- Azure Vault\n        [186738] = {75, 50, 25}, -- Umbrelskul\n        \n        -- Court of Stars\n        [104215] = {25}, -- Patrol Captain Gerdo\n        \n        -- Halls of Valor\n        [94960] = {10}, -- Hymdall\n        [95674] = {60}, -- Fenryr\n        [95676] = {80}, -- Odyn\n        \n        -- Nokhud Offensive\n        [186151] = {60}, -- Balakar Khan\n        \n        -- Ruby Life Pools\n        [188252] = {75, 45}, -- Melidrussa\n        [190484] = {50}, -- Kyrakka\n        [197697] = {50}, -- Flamegullet\n        \n        -- Shadowmoon Burial Grounds\n        [76057] = {20}, -- Carrion Worm\n        \n        -- Temple of the Jade Serpent\n        [56732] = {70, 30}, -- Liu Flameheart\n        [59544] = {50}, -- The Nodding Tiger\n        \n        -- Vault of the Incarnates\n        [187967] = {5}, -- Sennarth\n        [189492] = {65}, -- Raszageth\n        \n        -- Neltharion's Lair\n        [91005] = {20}, -- Naraxas\n        \n        -- Neltharus\n        [194816] = {10}, -- Forgewrought Monstrosity\n        \n        -- Freehold\n        [126832] = {75}, -- Skycap'n Kragg\n        [126983] = {60, 30}, -- Harlan Sweete\n        \n        -- Uldaman\n        [184020] = {40}, -- Hulking Berserker\n        [184422] = {70, 30}, -- Emberon\n        [184580] = {10}, -- Olaf\n        [184581] = {10}, -- Baelog\n        [184582] = {10}, -- Eric \"The Swift\"\n        \n        -- Brackenhide Hollow\n        [185508] = {15}, -- Claw Fighter \n        [185528] = {15}, -- Trickclaw Mystic\n        [185534] = {15}, -- Bonebolt Hunter\n        [186121] = {4}, -- Decatriarch Wratheye \n        [186122] = {15}, -- Rira Hackclaw\n        [186124] = {15}, -- Gashtooth\n        [186125] = {15}, -- Tricktotem\n        [186206] = {15}, -- Cruel Bonecrusher\n        [186227] = {20}, -- Monstrous Decay\n        \n        -- Halls of Infusion\n        [189719] = {15}, -- Watcher Irideus\n        [190368] = {40}, -- Flamecaller Aymi\n        [190407] = {20}, -- Aqua Rager\n        \n        -- Abberus\n        [201261] = {80, 60, 40}, -- Kazzara\n    }\n    \n    scriptTable.Difficulty = {\n        [16] = { -- Mythic\n        },       \n        [15] = { -- Heroic\n        },       \n        [14] = { -- Normal\n        }, \n        [17] = { -- LFR\n        }, \n    }\nend",
      ["OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    if unitFrame.IsSelf or (Plater.ZoneInstanceType == \"arena\" or Plater.ZoneInstanceType == \"pvp\") then return end\n    \n    envTable.UpdateMarkers(unitFrame)    \nend    \n\n\n",
      ["Name"] = "Add - Health Markers [OPS]",
      ["Temp_UpdateCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    if unitFrame.IsSelf or (Plater.ZoneInstanceType == \"arena\" or Plater.ZoneInstanceType == \"pvp\") then return end\n    \n    envTable.UpdateMarkers(unitFrame)    \nend    \n\n\n",
      ["SpellIds"] = {
      },
      ["PlaterCore"] = 1,
      ["Temp_ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    function envTable.UpdateMarkers(unitFrame)\n        local npcID = envTable._NpcID\n        if not npcID then \n            if (unitFrame.healthMarker) then\n                unitFrame.healthMarker:Hide()\n                unitFrame.healthOverlay:Hide()\n            end\n            return \n        end\n        \n        local _, zoneType, diff = GetInstanceInfo()\n        local markersTable = zoneType == \"raid\" and scriptTable.Difficulty[diff][npcID] or scriptTable.lifePercent[npcID]\n        \n        if (markersTable) then\n            for _, p in ipairs(markersTable) do\n                if (envTable._HealthPercent > p) then\n                    local healthBar = unitFrame.healthBar\n                    local overlaySize = healthBar:GetWidth() * p/100\n                    \n                    if (not unitFrame.healthMarker) then\n                        unitFrame.healthMarker = healthBar:CreateTexture(nil, \"overlay\")\n                        unitFrame.healthMarker:SetColorTexture(1, 1, 1)\n                        unitFrame.healthOverlay = healthBar:CreateTexture(nil, \"overlay\")\n                        unitFrame.healthOverlay:SetColorTexture(1, 1, 1)\n                    end\n                    \n                    unitFrame.healthMarker:Show()\n                    unitFrame.healthMarker:SetSize(1, healthBar:GetHeight())\n                    unitFrame.healthMarker:SetPoint(\"left\", healthBar, \"left\", overlaySize, 0)\n                    unitFrame.healthMarker:SetVertexColor(Plater:ParseColors(scriptTable.config.indicatorColor))\n                    \n                    unitFrame.healthOverlay:Show()\n                    unitFrame.healthOverlay:SetSize(overlaySize, healthBar:GetHeight())\n                    unitFrame.healthOverlay:SetPoint(\"right\", unitFrame.healthMarker, \"left\", 0, 0)\n                    unitFrame.healthOverlay:SetVertexColor(Plater:ParseColors(scriptTable.config.fillColor))\n                    unitFrame.healthOverlay:SetAlpha(scriptTable.config.fillAlpha)\n                    \n                    return\n                end\n            end\n            \n            if (unitFrame.healthMarker) then\n                unitFrame.healthMarker:Hide()\n                unitFrame.healthOverlay:Hide()\n            end\n        end\n    end\nend",
      ["Enabled"] = false,
      ["Temp_Initialization"] = "function (scriptTable)\n    \n    scriptTable.lifePercent = {\n        -- Azure Vault\n        [186738] = {75, 50, 25}, -- Umbrelskul\n        \n        -- Court of Stars\n        [104215] = {25}, -- Patrol Captain Gerdo\n        \n        -- Halls of Valor\n        [94960] = {10}, -- Hymdall\n        [95674] = {60}, -- Fenryr\n        [95676] = {80}, -- Odyn\n        \n        -- Nokhud Offensive\n        [186151] = {60}, -- Balakar Khan\n        \n        -- Ruby Life Pools\n        [188252] = {75, 45}, -- Melidrussa\n        [190484] = {50}, -- Kyrakka\n        [197697] = {50}, -- Flamegullet\n        \n        -- Shadowmoon Burial Grounds\n        [76057] = {20}, -- Carrion Worm\n        \n        -- Temple of the Jade Serpent\n        [56732] = {70, 30}, -- Liu Flameheart\n        [59544] = {50}, -- The Nodding Tiger\n        \n        -- Vault of the Incarnates\n        [187967] = {5}, -- Sennarth\n        [189492] = {65}, -- Raszageth\n        \n        -- Neltharion's Lair\n        [91005] = {20}, -- Naraxas\n        \n        -- Neltharus\n        [194816] = {10}, -- Forgewrought Monstrosity\n        \n        -- Freehold\n        [126832] = {75}, -- Skycap'n Kragg\n        [126983] = {60, 30}, -- Harlan Sweete\n        \n        -- Uldaman\n        [184020] = {40}, -- Hulking Berserker\n        [184422] = {70, 30}, -- Emberon\n        [184580] = {10}, -- Olaf\n        [184581] = {10}, -- Baelog\n        [184582] = {10}, -- Eric \"The Swift\"\n        \n        -- Brackenhide Hollow\n        [185508] = {15}, -- Claw Fighter \n        [185528] = {15}, -- Trickclaw Mystic\n        [185534] = {15}, -- Bonebolt Hunter\n        [186121] = {4}, -- Decatriarch Wratheye \n        [186122] = {15}, -- Rira Hackclaw\n        [186124] = {15}, -- Gashtooth\n        [186125] = {15}, -- Tricktotem\n        [186206] = {15}, -- Cruel Bonecrusher\n        [186227] = {20}, -- Monstrous Decay\n        \n        -- Halls of Infusion\n        [189719] = {15}, -- Watcher Irideus\n        [190368] = {40}, -- Flamecaller Aymi\n        [190407] = {20}, -- Aqua Rager\n        \n        -- Abberus\n        [201261] = {80, 60, 40}, -- Kazzara\n    }\n    \n    scriptTable.Difficulty = {\n        [16] = { -- Mythic\n        },       \n        [15] = { -- Heroic\n        },       \n        [14] = { -- Normal\n        }, \n        [17] = { -- LFR\n        }, \n    }\nend",
      ["UpdateCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    if unitFrame.IsSelf or (Plater.ZoneInstanceType == \"arena\" or Plater.ZoneInstanceType == \"pvp\") then return end\n    \n    envTable.UpdateMarkers(unitFrame)    \nend    \n\n\n",
    }, -- [13]
    {
      ["ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    envTable.NameplateColor = scriptTable.config.nameplateColor\n    envTable.NameplateSizeOffset = scriptTable.config.nameplateSizeOffset\n    \n    unitFrame.UnitImportantSkullTexture = unitFrame.UnitImportantSkullTexture or unitFrame:CreateTexture(nil, \"background\")\n    \n    unitFrame.UnitImportantSkullTexture:Hide()\nend\n\n--[=[\n\n154564 - debug\n\nUsing spellIDs for multi-language support\n\n196548 = ancient branch (academy dungeon)\n195580, 195821, 195820 = nokhub saboteur\n189886 = blazebound firestorm\n75966 = Defiled Spirit\n102019 = Stormforged Obliterator\n    187159 = Shrieking Whelp\n194897 = stormsurge totem\n104251 = duskwatch sentry\n101326 = honored ancestor\n189669 = binding speakl netharius\n192464 = raging ember neltharius\n--]=]\n\n\n",
      ["OnHideCode"] = "function (self, unitId, unitFrame, envTable)\n    Plater.StopDotAnimation(unitFrame.healthBar, envTable.dotAnimation)   \n    \n    --restore the nameplate size\n    local nameplateHeight = Plater.db.profile.plate_config.enemynpc.health_incombat [2]\n    unitFrame.healthBar:SetHeight (nameplateHeight)    \n    \n    unitFrame.UnitImportantSkullTexture:Hide()\n    Plater.DenyColorChange(unitFrame, false)\nend\n\n\n",
      ["OptionsValues"] = {
        ["npcColor"] = {
          {
            "169421", -- [1]
            "lime", -- [2]
          }, -- [1]
          {
            "169425", -- [1]
            "lime", -- [2]
          }, -- [2]
          {
            "169426", -- [1]
            "lime", -- [2]
          }, -- [3]
          {
            "169428", -- [1]
            "lime", -- [2]
          }, -- [4]
          {
            "169429", -- [1]
            "lime", -- [2]
          }, -- [5]
          {
            "169430", -- [1]
            "lime", -- [2]
          }, -- [6]
          {
            "168932", -- [1]
            "lime", -- [2]
          }, -- [7]
        },
      },
      ["Temp_OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    if (envTable.dotAnimation) then\n        Plater.StopDotAnimation(unitFrame.healthBar, envTable.dotAnimation)\n    end\n    \n    envTable.dotAnimation = Plater.PlayDotAnimation(unitFrame.healthBar, 2, scriptTable.config.dotsColor, 3, 4) \n    \n    --increase the nameplate size\n    local nameplateHeight = Plater.db.profile.plate_config.enemynpc.health_incombat [2]\n    unitFrame.healthBar:SetHeight (nameplateHeight + envTable.NameplateSizeOffset)\n    \n    unitFrame.UnitImportantSkullTexture:Show()\n    \n    --color priority:\n    local npcIdString = tostring(envTable._NpcID)\n    envTable.NameplateColor = Plater.GetColorByPriority(unitFrame, scriptTable.config.npcColor[npcIdString], scriptTable.config.nameplateColor)    \n    \n    if (scriptTable.config.showExtraTexture) then\n        unitFrame.UnitImportantSkullTexture:SetVertexColor(Plater:ParseColors(scriptTable.config.skullColor))\n        unitFrame.UnitImportantSkullTexture:SetAlpha(scriptTable.config.skullAlpha)\n        unitFrame.UnitImportantSkullTexture:SetScale(scriptTable.config.skullScale)\n        unitFrame.UnitImportantSkullTexture:SetTexture([[Interface/AddOns/Plater/media/x_64]])\n        unitFrame.UnitImportantSkullTexture:ClearAllPoints()\n        unitFrame.UnitImportantSkullTexture:SetPoint(\"right\", unitFrame.healthBar, \"left\", -2, 0)\n        unitFrame.UnitImportantSkullTexture:SetSize(28, 28)\n        unitFrame.UnitImportantSkullTexture:Show()\n    else\n        unitFrame.UnitImportantSkullTexture:Hide()\n    end\n    \n    --rules for some npcs\n    if (envTable._NpcID == 194895) then --unstable squall (explode at dying\n        unitFrame.UnitImportantSkullTexture:Hide()\n        Plater.StopDotAnimation(unitFrame.healthBar, envTable.dotAnimation) \n    end\n    \n    if (scriptTable.config.changeNameplateColor) then\n        local npcIdString = tostring(envTable._NpcID)\n        \n        envTable.NameplateColor = Plater.GetColorByPriority(unitFrame, scriptTable.config.npcColor[npcIdString], scriptTable.config.nameplateColor)        \n        \n        Plater.DenyColorChange(unitFrame, true)\n    end\n    \nend\n\n\n\n\n",
      ["ScriptType"] = 3,
      ["__TrashAt"] = 1699197141,
      ["Time"] = 1699197046,
      ["Icon"] = "Interface\\AddOns\\Plater\\media\\skullbones_64",
      ["Temp_OnHideCode"] = "function (self, unitId, unitFrame, envTable)\n    Plater.StopDotAnimation(unitFrame.healthBar, envTable.dotAnimation)   \n    \n    --restore the nameplate size\n    local nameplateHeight = Plater.db.profile.plate_config.enemynpc.health_incombat [2]\n    unitFrame.healthBar:SetHeight (nameplateHeight)    \n    \n    unitFrame.UnitImportantSkullTexture:Hide()\n    Plater.DenyColorChange(unitFrame, false)\nend\n\n\n",
      ["url"] = "https://wago.io/TOUGl3IhN/14",
      ["NpcNames"] = {
        "75966", -- [1]
        "92538", -- [2]
        "94869", -- [3]
        "101326", -- [4]
        "101476", -- [5]
        "102019", -- [6]
        "104251", -- [7]
        "168932", -- [8]
        "169421", -- [9]
        "169425", -- [10]
        "169426", -- [11]
        "169428", -- [12]
        "169429", -- [13]
        "169430", -- [14]
        "187159", -- [15]
        "189669", -- [16]
        "189886", -- [17]
        "190174", -- [18]
        "190381", -- [19]
        "190426", -- [20]
        "192464", -- [21]
        "193352", -- [22]
        "193799", -- [23]
        "194897", -- [24]
        "195580", -- [25]
        "195820", -- [26]
        "195821", -- [27]
        "196548", -- [28]
        "201339", -- [29]
      },
      ["OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    if (envTable.dotAnimation) then\n        Plater.StopDotAnimation(unitFrame.healthBar, envTable.dotAnimation)\n    end\n    \n    envTable.dotAnimation = Plater.PlayDotAnimation(unitFrame.healthBar, 2, scriptTable.config.dotsColor, 3, 4) \n    \n    --increase the nameplate size\n    local nameplateHeight = Plater.db.profile.plate_config.enemynpc.health_incombat [2]\n    unitFrame.healthBar:SetHeight (nameplateHeight + envTable.NameplateSizeOffset)\n    \n    unitFrame.UnitImportantSkullTexture:Show()\n    \n    --color priority:\n    local npcIdString = tostring(envTable._NpcID)\n    envTable.NameplateColor = Plater.GetColorByPriority(unitFrame, scriptTable.config.npcColor[npcIdString], scriptTable.config.nameplateColor)    \n    \n    if (scriptTable.config.showExtraTexture) then\n        unitFrame.UnitImportantSkullTexture:SetVertexColor(Plater:ParseColors(scriptTable.config.skullColor))\n        unitFrame.UnitImportantSkullTexture:SetAlpha(scriptTable.config.skullAlpha)\n        unitFrame.UnitImportantSkullTexture:SetScale(scriptTable.config.skullScale)\n        unitFrame.UnitImportantSkullTexture:SetTexture([[Interface/AddOns/Plater/media/x_64]])\n        unitFrame.UnitImportantSkullTexture:ClearAllPoints()\n        unitFrame.UnitImportantSkullTexture:SetPoint(\"right\", unitFrame.healthBar, \"left\", -2, 0)\n        unitFrame.UnitImportantSkullTexture:SetSize(28, 28)\n        unitFrame.UnitImportantSkullTexture:Show()\n    else\n        unitFrame.UnitImportantSkullTexture:Hide()\n    end\n    \n    --rules for some npcs\n    if (envTable._NpcID == 194895) then --unstable squall (explode at dying\n        unitFrame.UnitImportantSkullTexture:Hide()\n        Plater.StopDotAnimation(unitFrame.healthBar, envTable.dotAnimation) \n    end\n    \n    if (scriptTable.config.changeNameplateColor) then\n        local npcIdString = tostring(envTable._NpcID)\n        \n        envTable.NameplateColor = Plater.GetColorByPriority(unitFrame, scriptTable.config.npcColor[npcIdString], scriptTable.config.nameplateColor)        \n        \n        Plater.DenyColorChange(unitFrame, true)\n    end\n    \nend\n\n\n\n\n",
      ["Enabled"] = false,
      ["Revision"] = 642,
      ["Options"] = {
        {
          ["Type"] = 6,
          ["Key"] = "option4",
          ["Value"] = 0,
          ["Name"] = "Blank Space",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [1]
        {
          ["Type"] = 5,
          ["Key"] = "option6",
          ["Value"] = "Enter the npc name or npcId in the \"Add Trigger\" box and hit \"Add\".",
          ["Name"] = "Option 6",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_label",
          ["Desc"] = "",
        }, -- [2]
        {
          ["Type"] = 6,
          ["Key"] = "option4",
          ["Value"] = 0,
          ["Name"] = "Blank Space",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [3]
        {
          ["Type"] = 4,
          ["Key"] = "changeNameplateColor",
          ["Value"] = true,
          ["Name"] = "Change Nameplate Color",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_bool",
          ["Desc"] = "change to true to change the color",
        }, -- [4]
        {
          ["Type"] = 1,
          ["Key"] = "nameplateColor",
          ["Value"] = {
            1, -- [1]
            0, -- [2]
            0.52549019607843, -- [3]
            1, -- [4]
          },
          ["Name"] = "Nameplate Color",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
          ["Desc"] = "Nameplate Color",
        }, -- [5]
        {
          ["Type"] = 2,
          ["Max"] = 6,
          ["Desc"] = "increase the nameplate height by this value",
          ["Min"] = 0,
          ["Key"] = "nameplateSizeOffset",
          ["Value"] = 3,
          ["Fraction"] = false,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Nameplate Size Offset",
        }, -- [6]
        {
          ["Type"] = 6,
          ["Key"] = "option4",
          ["Value"] = 0,
          ["Name"] = "Blank Space",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [7]
        {
          ["Type"] = 1,
          ["Key"] = "dotsColor",
          ["Value"] = {
            1, -- [1]
            0.71372550725937, -- [2]
            0, -- [3]
            0.56313106417656, -- [4]
          },
          ["Name"] = "Dot Color",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
          ["Desc"] = "Dot Color",
        }, -- [8]
        {
          ["Type"] = 6,
          ["Key"] = "option4",
          ["Value"] = 0,
          ["Name"] = "Blank Space",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [9]
        {
          ["Type"] = 5,
          ["Key"] = "option10",
          ["Value"] = "Extra Texture",
          ["Name"] = "Extra Texture",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_label",
          ["Desc"] = "Extra Texture",
        }, -- [10]
        {
          ["Type"] = 4,
          ["Key"] = "showExtraTexture",
          ["Value"] = false,
          ["Name"] = "Show Extra Texture",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_bool",
          ["Desc"] = "Show Extra Texture",
        }, -- [11]
        {
          ["Type"] = 1,
          ["Key"] = "skullColor",
          ["Value"] = {
            1, -- [1]
            0.46274509803922, -- [2]
            0, -- [3]
            1, -- [4]
          },
          ["Name"] = "Texture Color",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
          ["Desc"] = "Texture Color",
        }, -- [12]
        {
          ["Type"] = 2,
          ["Max"] = 1,
          ["Desc"] = "Alpha",
          ["Min"] = 0,
          ["Key"] = "skullAlpha",
          ["Value"] = 0.2,
          ["Fraction"] = true,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Alpha",
        }, -- [13]
        {
          ["Type"] = 2,
          ["Max"] = 2,
          ["Desc"] = "Scale",
          ["Min"] = 0.4,
          ["Key"] = "skullScale",
          ["Value"] = 0.6,
          ["Fraction"] = true,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Scale",
        }, -- [14]
        {
          ["Type"] = 7,
          ["Key"] = "npcColor",
          ["Value"] = {
            {
              "169421", -- [1]
              "lime", -- [2]
            }, -- [1]
            {
              "169425", -- [1]
              "lime", -- [2]
            }, -- [2]
            {
              "169426", -- [1]
              "lime", -- [2]
            }, -- [3]
            {
              "169428", -- [1]
              "lime", -- [2]
            }, -- [4]
            {
              "169429", -- [1]
              "lime", -- [2]
            }, -- [5]
            {
              "169430", -- [1]
              "lime", -- [2]
            }, -- [6]
            {
              "168932", -- [1]
              "lime", -- [2]
            }, -- [7]
          },
          ["Name"] = "Npc Color By NpcID",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_list",
          ["Desc"] = "Key is the npcID, value is the color name",
        }, -- [15]
      },
      ["Name"] = "Add - Important [OPS]",
      ["Prio"] = 99,
      ["Author"] = "Izimode-Azralon",
      ["Initialization"] = "function (scriptTable)\n    --insert code here\n    \nend\n\n\n",
      ["Desc"] = "Change the color and highlight a nameplate of an important Add. Add the unit name or NpcID into the trigger box to add more.",
      ["SpellIds"] = {
      },
      ["Temp_UpdateCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    --check if can change the nameplate color\n    if (scriptTable.config.changeNameplateColor) then\n        Plater.SetNameplateColor(unitFrame, envTable.NameplateColor)\n    end\n    \nend\n\n\n\n\n",
      ["version"] = 14,
      ["PlaterCore"] = 1,
      ["Temp_ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    envTable.NameplateColor = scriptTable.config.nameplateColor\n    envTable.NameplateSizeOffset = scriptTable.config.nameplateSizeOffset\n    \n    unitFrame.UnitImportantSkullTexture = unitFrame.UnitImportantSkullTexture or unitFrame:CreateTexture(nil, \"background\")\n    \n    unitFrame.UnitImportantSkullTexture:Hide()\nend\n\n--[=[\n\n154564 - debug\n\nUsing spellIDs for multi-language support\n\n196548 = ancient branch (academy dungeon)\n195580, 195821, 195820 = nokhub saboteur\n189886 = blazebound firestorm\n75966 = Defiled Spirit\n102019 = Stormforged Obliterator\n    187159 = Shrieking Whelp\n194897 = stormsurge totem\n104251 = duskwatch sentry\n101326 = honored ancestor\n189669 = binding speakl netharius\n192464 = raging ember neltharius\n--]=]\n\n\n",
      ["semver"] = "1.2.5",
      ["Temp_Initialization"] = "function (scriptTable)\n    --insert code here\n    \nend\n\n\n",
      ["UpdateCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    --check if can change the nameplate color\n    if (scriptTable.config.changeNameplateColor) then\n        Plater.SetNameplateColor(unitFrame, envTable.NameplateColor)\n    end\n    \nend\n\n\n\n\n",
    }, -- [14]
    {
      ["ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    --castbar color (when can be interrupted)\n    envTable.CastbarColor = scriptTable.config.castbarColor\n    envTable.CastbarNoInterruptColor = scriptTable.config.castbarNoInterruptColor\n    envTable.BorderColor = scriptTable.config.borderColor\n    \n    --flash duration\n    local CONFIG_BACKGROUND_FLASH_DURATION = scriptTable.config.flashDuration\n    \n    --add this value to the cast bar height\n    envTable.CastBarHeightAdd = scriptTable.config.castBarHeight\n    \n    --create a fast flash above the cast bar\n    envTable.FullBarFlash = envTable.FullBarFlash or Plater.CreateFlash (self, 0.05, 1, \"white\")\n    \n    --create a camera shake for the nameplate\n    envTable.FrameShake = Plater:CreateFrameShake (unitFrame, scriptTable.config.shakeDuration, scriptTable.config.shakeAmplitude, scriptTable.config.shakeFrequency, false, false, 0, 1, 0.05, 0.1, Plater.GetPoints (unitFrame))\n    \n    --create a texture to use for a flash behind the cast bar\n    local backGroundFlashTexture = Plater:CreateImage (self, [[Interface\\ACHIEVEMENTFRAME\\UI-Achievement-Alert-Glow]], self:GetWidth()+60, self:GetHeight()+50, \"background\", {0, 400/512, 0, 170/256})\n    backGroundFlashTexture:SetBlendMode (\"ADD\", 7)\n    backGroundFlashTexture:SetDrawLayer(\"OVERLAY\", 7)\n    backGroundFlashTexture:SetPoint (\"center\", self, \"center\")\n    backGroundFlashTexture:Hide()\n    \n    --create the animation hub to hold the flash animation sequence\n    envTable.BackgroundFlash = envTable.BackgroundFlash or Plater:CreateAnimationHub (backGroundFlashTexture, \n        function()\n            backGroundFlashTexture:Show()\n        end,\n        function()\n            backGroundFlashTexture:Hide()\n        end\n    )\n    \n    --create the flash animation sequence\n    envTable.BackgroundFlash.fadeIn = envTable.BackgroundFlash.fadeIn or Plater:CreateAnimation (envTable.BackgroundFlash, \"ALPHA\", 1, CONFIG_BACKGROUND_FLASH_DURATION/2, 0, .75)\n    envTable.BackgroundFlash.fadeIn:SetDuration(CONFIG_BACKGROUND_FLASH_DURATION/2)\n    \n    envTable.BackgroundFlash.fadeOut = envTable.BackgroundFlash.fadeOut or Plater:CreateAnimation (envTable.BackgroundFlash, \"ALPHA\", 2, CONFIG_BACKGROUND_FLASH_DURATION/2, 1, 0)    \n    envTable.BackgroundFlash.fadeOut:SetDuration(CONFIG_BACKGROUND_FLASH_DURATION/2)\n    \n    --envTable.BackgroundFlash:Play() --envTable.BackgroundFlash:Stop()    \n    \n    \n    \n    \n    \nend\n\n\n\n\n",
      ["OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    if (not Plater.IsShowingCastBarTest) then\n        --don't execute on battlegrounds and arenas\n        if (Plater.ZoneInstanceType == \"arena\" or Plater.ZoneInstanceType == \"pvp\") then\n            return\n        end    \n    end\n    \n    unitFrame.castBar:SetHeight (envTable._DefaultHeight)\n    \n    --stop the camera shake\n    unitFrame:StopFrameShake (envTable.FrameShake)\n    \n    envTable.FullBarFlash:Stop()\n    envTable.BackgroundFlash:Stop()\n    \n    unitFrame.castBar.Spark:SetHeight(unitFrame.castBar:GetHeight())\n    \nend\n\n\n\n\n\n\n\n",
      ["OptionsValues"] = {
        ["castbarNoInterruptColor"] = {
          0.6313725709915161, -- [1]
          0.1372549086809158, -- [2]
          0.168627455830574, -- [3]
          0.8082544207572937, -- [4]
        },
      },
      ["Temp_OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    --don't execute on battlegrounds and arenas\n    if (not Plater.IsShowingCastBarTest) then\n        if (Plater.ZoneInstanceType == \"arena\" or Plater.ZoneInstanceType == \"pvp\") then\n            return\n        end\n    end\n    \n    --play flash animations\n    envTable.FullBarFlash:Play()\n    \n    --envTable.currentHeight = unitFrame.castBar:GetHeight()\n    \n    --restoring the default size (not required since it already restore in the hide script)\n    if (envTable.OriginalHeight) then\n        self:SetHeight (envTable.OriginalHeight)\n    end\n    \n    --increase the cast bar size\n    local height = self:GetHeight()\n    envTable.OriginalHeight = height\n    \n    self:SetHeight (height + envTable.CastBarHeightAdd)\n    \n    if (scriptTable.config.useBorderColor) then\n        -- Plater.SetCastBarBorderColor (self, 1, .2, .2, 0.4)\n        Plater.SetCastBarBorderColor (self, Plater:ParseColors (envTable.BorderColor))\n    end\n    \n    unitFrame:PlayFrameShake (envTable.FrameShake)\n    \n    --set the color of the cast bar to dark orange (only if can be interrupted)\n    --Plater auto set this color to default when a new cast starts, no need to reset this value at OnHide.    \n    if (scriptTable.config.useCastbarColor) then\n        if (envTable._CanInterrupt) then\n            self:SetStatusBarColor (Plater:ParseColors (envTable.CastbarColor))\n        else\n            self:SetStatusBarColor (Plater:ParseColors (envTable.CastbarNoInterruptColor))\n        end\n    end\n    \n    -- Does not support non-interruptable casts\n    -- Plater.SetCastBarColorForScript(self, scriptTable.config.useCastbarColor, scriptTable.config.castbarColor, envTable)\n    \n    envTable.BackgroundFlash:Play()\n    \n    unitFrame.castBar.Spark:SetHeight(unitFrame.castBar:GetHeight())\n    \nend\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n",
      ["ScriptType"] = 2,
      ["__TrashAt"] = 1699197149,
      ["Time"] = 1692724469,
      ["Enabled"] = false,
      ["Options"] = {
        {
          ["Type"] = 6,
          ["Name"] = "Blank Line",
          ["Value"] = 0,
          ["Key"] = "option1",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [1]
        {
          ["Type"] = 5,
          ["Name"] = "Option 2",
          ["Value"] = "Produces a notable effect in the cast bar when a spell from the 'Triggers' starts to cast.",
          ["Key"] = "option2",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_label",
          ["Desc"] = "",
        }, -- [2]
        {
          ["Type"] = 5,
          ["Name"] = "Option 3",
          ["Value"] = "Enter the spell name or spellID of the Spell in the Add Trigger box and hit \"Add\".",
          ["Key"] = "option3",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_label",
          ["Desc"] = "",
        }, -- [3]
        {
          ["Type"] = 6,
          ["Name"] = "Blank Space",
          ["Value"] = 0,
          ["Key"] = "option4",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [4]
        {
          ["Type"] = 4,
          ["Name"] = "Cast Bar Color Enabled",
          ["Value"] = true,
          ["Key"] = "useCastbarColor",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_bool",
          ["Desc"] = "When enabled, changes the cast bar color.",
        }, -- [5]
        {
          ["Type"] = 1,
          ["Name"] = "Cast Bar Color",
          ["Value"] = {
            1, -- [1]
            0.43137254901961, -- [2]
            0, -- [3]
            1, -- [4]
          },
          ["Key"] = "castbarColor",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
          ["Desc"] = "Color of the cast bar.",
        }, -- [6]
        {
          ["Type"] = 1,
          ["Name"] = "Cast Bar Uninterruptible Color",
          ["Value"] = {
            1, -- [1]
            1, -- [2]
            0, -- [3]
            1, -- [4]
          },
          ["Key"] = "castbarNoInterruptColor",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
          ["Desc"] = "Color of the uninterruptible cast bar.",
        }, -- [7]
        {
          ["Type"] = 6,
          ["Name"] = "Blank Line",
          ["Value"] = 0,
          ["Key"] = "option7",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [8]
        {
          ["Type"] = 4,
          ["Name"] = "Cast Bar Border Color Enabled",
          ["Value"] = false,
          ["Key"] = "useBorderColor",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_bool",
          ["Desc"] = "When enabled, changes the cast bar border color.",
        }, -- [9]
        {
          ["Type"] = 1,
          ["Name"] = "Cast Bar Border Color",
          ["Value"] = {
            1, -- [1]
            0.20000001788139, -- [2]
            0.20000001788139, -- [3]
            0.40000003576279, -- [4]
          },
          ["Key"] = "borderColor",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
          ["Desc"] = "",
        }, -- [10]
        {
          ["Type"] = 6,
          ["Name"] = "Blank Line",
          ["Value"] = 0,
          ["Key"] = "option14",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [11]
        {
          ["Type"] = 2,
          ["Max"] = 1,
          ["Desc"] = "When the cast starts it flash rapidly, adjust how fast it flashes. Value is milliseconds.",
          ["Min"] = 0.05,
          ["Fraction"] = true,
          ["Value"] = 0.4,
          ["Key"] = "flashDuration",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Flash Duration",
        }, -- [12]
        {
          ["Type"] = 2,
          ["Max"] = 10,
          ["Desc"] = "Increases the cast bar height by this value",
          ["Min"] = 0,
          ["Fraction"] = false,
          ["Value"] = 5,
          ["Key"] = "castBarHeight",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Cast Bar Height Mod",
        }, -- [13]
        {
          ["Type"] = 2,
          ["Max"] = 1,
          ["Desc"] = "When the cast starts, there's a small shake in the nameplate, this settings controls how long it takes.",
          ["Min"] = 0.1,
          ["Fraction"] = true,
          ["Value"] = 0.2,
          ["Key"] = "shakeDuration",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Shake Duration",
        }, -- [14]
        {
          ["Type"] = 2,
          ["Max"] = 100,
          ["Desc"] = "How strong is the shake.",
          ["Min"] = 2,
          ["Fraction"] = false,
          ["Value"] = 8,
          ["Key"] = "shakeAmplitude",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Shake Amplitude",
        }, -- [15]
        {
          ["Type"] = 2,
          ["Max"] = 80,
          ["Desc"] = "How fast the shake moves.",
          ["Min"] = 1,
          ["Fraction"] = false,
          ["Value"] = 40,
          ["Key"] = "option15",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Shake Move",
        }, -- [16]
      },
      ["Temp_ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    --castbar color (when can be interrupted)\n    envTable.CastbarColor = scriptTable.config.castbarColor\n    envTable.CastbarNoInterruptColor = scriptTable.config.castbarNoInterruptColor\n    envTable.BorderColor = scriptTable.config.borderColor\n    \n    --flash duration\n    local CONFIG_BACKGROUND_FLASH_DURATION = scriptTable.config.flashDuration\n    \n    --add this value to the cast bar height\n    envTable.CastBarHeightAdd = scriptTable.config.castBarHeight\n    \n    --create a fast flash above the cast bar\n    envTable.FullBarFlash = envTable.FullBarFlash or Plater.CreateFlash (self, 0.05, 1, \"white\")\n    \n    --create a camera shake for the nameplate\n    envTable.FrameShake = Plater:CreateFrameShake (unitFrame, scriptTable.config.shakeDuration, scriptTable.config.shakeAmplitude, scriptTable.config.shakeFrequency, false, false, 0, 1, 0.05, 0.1, Plater.GetPoints (unitFrame))\n    \n    --create a texture to use for a flash behind the cast bar\n    local backGroundFlashTexture = Plater:CreateImage (self, [[Interface\\ACHIEVEMENTFRAME\\UI-Achievement-Alert-Glow]], self:GetWidth()+60, self:GetHeight()+50, \"background\", {0, 400/512, 0, 170/256})\n    backGroundFlashTexture:SetBlendMode (\"ADD\", 7)\n    backGroundFlashTexture:SetDrawLayer(\"OVERLAY\", 7)\n    backGroundFlashTexture:SetPoint (\"center\", self, \"center\")\n    backGroundFlashTexture:Hide()\n    \n    --create the animation hub to hold the flash animation sequence\n    envTable.BackgroundFlash = envTable.BackgroundFlash or Plater:CreateAnimationHub (backGroundFlashTexture, \n        function()\n            backGroundFlashTexture:Show()\n        end,\n        function()\n            backGroundFlashTexture:Hide()\n        end\n    )\n    \n    --create the flash animation sequence\n    envTable.BackgroundFlash.fadeIn = envTable.BackgroundFlash.fadeIn or Plater:CreateAnimation (envTable.BackgroundFlash, \"ALPHA\", 1, CONFIG_BACKGROUND_FLASH_DURATION/2, 0, .75)\n    envTable.BackgroundFlash.fadeIn:SetDuration(CONFIG_BACKGROUND_FLASH_DURATION/2)\n    \n    envTable.BackgroundFlash.fadeOut = envTable.BackgroundFlash.fadeOut or Plater:CreateAnimation (envTable.BackgroundFlash, \"ALPHA\", 2, CONFIG_BACKGROUND_FLASH_DURATION/2, 1, 0)    \n    envTable.BackgroundFlash.fadeOut:SetDuration(CONFIG_BACKGROUND_FLASH_DURATION/2)\n    \n    --envTable.BackgroundFlash:Play() --envTable.BackgroundFlash:Stop()    \n    \n    \n    \n    \n    \nend\n\n\n\n\n",
      ["NpcNames"] = {
      },
      ["Desc"] = "Flash, Bounce and Red Color the CastBar border when when an important cast is happening. Add spell in the Add Trigger field.",
      ["Temp_OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    if (not Plater.IsShowingCastBarTest) then\n        --don't execute on battlegrounds and arenas\n        if (Plater.ZoneInstanceType == \"arena\" or Plater.ZoneInstanceType == \"pvp\") then\n            return\n        end    \n    end\n    \n    unitFrame.castBar:SetHeight (envTable._DefaultHeight)\n    \n    --stop the camera shake\n    unitFrame:StopFrameShake (envTable.FrameShake)\n    \n    envTable.FullBarFlash:Stop()\n    envTable.BackgroundFlash:Stop()\n    \n    unitFrame.castBar.Spark:SetHeight(unitFrame.castBar:GetHeight())\n    \nend\n\n\n\n\n\n\n\n",
      ["Revision"] = 1375,
      ["semver"] = "1.1.15",
      ["Name"] = "Cast - Big Alert [OPS]",
      ["Prio"] = 99,
      ["Author"] = "Tercioo-Sylvanas",
      ["Initialization"] = "function (scriptTable)\n    --insert code here\n    \nend",
      ["OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    --don't execute on battlegrounds and arenas\n    if (not Plater.IsShowingCastBarTest) then\n        if (Plater.ZoneInstanceType == \"arena\" or Plater.ZoneInstanceType == \"pvp\") then\n            return\n        end\n    end\n    \n    --play flash animations\n    envTable.FullBarFlash:Play()\n    \n    --envTable.currentHeight = unitFrame.castBar:GetHeight()\n    \n    --restoring the default size (not required since it already restore in the hide script)\n    if (envTable.OriginalHeight) then\n        self:SetHeight (envTable.OriginalHeight)\n    end\n    \n    --increase the cast bar size\n    local height = self:GetHeight()\n    envTable.OriginalHeight = height\n    \n    self:SetHeight (height + envTable.CastBarHeightAdd)\n    \n    if (scriptTable.config.useBorderColor) then\n        -- Plater.SetCastBarBorderColor (self, 1, .2, .2, 0.4)\n        Plater.SetCastBarBorderColor (self, Plater:ParseColors (envTable.BorderColor))\n    end\n    \n    unitFrame:PlayFrameShake (envTable.FrameShake)\n    \n    --set the color of the cast bar to dark orange (only if can be interrupted)\n    --Plater auto set this color to default when a new cast starts, no need to reset this value at OnHide.    \n    if (scriptTable.config.useCastbarColor) then\n        if (envTable._CanInterrupt) then\n            self:SetStatusBarColor (Plater:ParseColors (envTable.CastbarColor))\n        else\n            self:SetStatusBarColor (Plater:ParseColors (envTable.CastbarNoInterruptColor))\n        end\n    end\n    \n    -- Does not support non-interruptable casts\n    -- Plater.SetCastBarColorForScript(self, scriptTable.config.useCastbarColor, scriptTable.config.castbarColor, envTable)\n    \n    envTable.BackgroundFlash:Play()\n    \n    unitFrame.castBar.Spark:SetHeight(unitFrame.castBar:GetHeight())\n    \nend\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n",
      ["version"] = 19,
      ["Temp_UpdateCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \nend\n\n\n",
      ["SpellIds"] = {
        87779, -- [1]
        88170, -- [2]
        188587, -- [3]
        193585, -- [4]
        202075, -- [5]
        257397, -- [6]
        257478, -- [7]
        257739, -- [8]
        257899, -- [9]
        265081, -- [10]
        265089, -- [11]
        265487, -- [12]
        266209, -- [13]
        272402, -- [14]
        278961, -- [15]
        367484, -- [16]
        367503, -- [17]
        369365, -- [18]
        369400, -- [19]
        369411, -- [20]
        369602, -- [21]
        369675, -- [22]
        369823, -- [23]
        369853, -- [24]
        372223, -- [25]
        372226, -- [26]
        372711, -- [27]
        372735, -- [28]
        372743, -- [29]
        373024, -- [30]
        373897, -- [31]
        374073, -- [32]
        374339, -- [33]
        374706, -- [34]
        376171, -- [35]
        377384, -- [36]
        377389, -- [37]
        377402, -- [38]
        377500, -- [39]
        377950, -- [40]
        381770, -- [41]
        382410, -- [42]
        383385, -- [43]
        383651, -- [44]
        383693, -- [45]
        384161, -- [46]
        384194, -- [47]
        384633, -- [48]
        384808, -- [49]
        385036, -- [50]
        385046, -- [51]
        386012, -- [52]
        386025, -- [53]
        386223, -- [54]
        386546, -- [55]
        387440, -- [56]
        387596, -- [57]
        387606, -- [58]
        387608, -- [59]
        387615, -- [60]
        387955, -- [61]
        388392, -- [62]
        388863, -- [63]
        392924, -- [64]
        395427, -- [65]
        396640, -- [66]
        396812, -- [67]
        400165, -- [68]
        410870, -- [69]
        410873, -- [70]
        411958, -- [71]
        411994, -- [72]
        412012, -- [73]
        412233, -- [74]
        413427, -- [75]
        413544, -- [76]
        413607, -- [77]
        415437, -- [78]
        415770, -- [79]
      },
      ["PlaterCore"] = 1,
      ["url"] = "https://wago.io/rHwS23Nmu/19",
      ["Icon"] = "Interface\\AddOns\\Plater\\images\\cast_bar_orange",
      ["UpdateCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \nend\n\n\n",
      ["Temp_Initialization"] = "function (scriptTable)\n    --insert code here\n    \nend",
    }, -- [15]
    {
      ["ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    local movingArrowTexture = unitFrame._movingArrowTexture\n    if (not movingArrowTexture) then\n        movingArrowTexture = self:CreateTexture(nil, \"artwork\", nil, 6)\n        unitFrame._movingArrowTexture = movingArrowTexture\n    end\n    \n    envTable.movingAnimation = envTable.movingAnimation or Plater:CreateAnimationHub (unitFrame._movingArrowTexture, \n        function() \n            unitFrame._movingArrowTexture:Show() \n            unitFrame._movingArrowTexture:SetPoint(\"left\", 0, 0)\n        end, \n        function() unitFrame._movingArrowTexture:Hide() end)\n    \n    envTable.movingAnimation:SetLooping (\"REPEAT\")\n    \n    envTable.arrowAnimation = envTable.arrowAnimation or Plater:CreateAnimation (envTable.movingAnimation, \"translation\", 1, 0.20, self:GetWidth()-16, 0)\n    \n    envTable.arrowAnimation:SetDuration(scriptTable.config.animSpeed)\n    \n    -- castbar color\n    envTable.castBarColor = scriptTable.config.castBarColor\n    envTable.castBarNoInterruptColor = scriptTable.config.castBarNoInterruptColor\n    \nend\n\n\n",
      ["OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    envTable.movingAnimation:Stop()\nend\n\n\n",
      ["OptionsValues"] = {
      },
      ["Temp_OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    unitFrame._movingArrowTexture:SetTexture([[Interface\\PETBATTLES\\PetBattle-StatIcons]])\n    unitFrame._movingArrowTexture:SetSize(16, self:GetHeight() - 2)\n    unitFrame._movingArrowTexture:SetTexCoord(unpack({0, 15/32, 18/32, 30/32}))\n    unitFrame._movingArrowTexture:SetAlpha(scriptTable.config.arrowAlpha)\n    unitFrame._movingArrowTexture:SetDesaturated(scriptTable.config.desaturateArrow)    \n    \n    unitFrame._movingArrowTexture:SetParent(self.FrameOverlay)\n    unitFrame._movingArrowTexture:SetDrawLayer(\"overlay\",  7)\n    \n    envTable.arrowAnimation:SetDuration(scriptTable.config.animSpeed)\n    envTable.movingAnimation:Play()\n    \n    --Plater auto set this color to default when a new cast starts, no need to reset this value at OnHide.    \n    if (scriptTable.config.useCastBarColor) then\n        if (envTable._CanInterrupt) then\n            self:SetStatusBarColor (Plater:ParseColors (envTable.castBarColor))\n        else\n            self:SetStatusBarColor (Plater:ParseColors (envTable.castBarNoInterruptColor))\n        end\n    end\n    \nend",
      ["ScriptType"] = 2,
      ["__TrashAt"] = 1699197151,
      ["Time"] = 1689716173,
      ["Icon"] = "Interface\\AddOns\\Plater\\images\\cast_bar_frontal",
      ["Temp_OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    envTable.movingAnimation:Stop()\nend\n\n\n",
      ["url"] = "https://wago.io/e8dU21tna/13",
      ["NpcNames"] = {
      },
      ["OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    unitFrame._movingArrowTexture:SetTexture([[Interface\\PETBATTLES\\PetBattle-StatIcons]])\n    unitFrame._movingArrowTexture:SetSize(16, self:GetHeight() - 2)\n    unitFrame._movingArrowTexture:SetTexCoord(unpack({0, 15/32, 18/32, 30/32}))\n    unitFrame._movingArrowTexture:SetAlpha(scriptTable.config.arrowAlpha)\n    unitFrame._movingArrowTexture:SetDesaturated(scriptTable.config.desaturateArrow)    \n    \n    unitFrame._movingArrowTexture:SetParent(self.FrameOverlay)\n    unitFrame._movingArrowTexture:SetDrawLayer(\"overlay\",  7)\n    \n    envTable.arrowAnimation:SetDuration(scriptTable.config.animSpeed)\n    envTable.movingAnimation:Play()\n    \n    --Plater auto set this color to default when a new cast starts, no need to reset this value at OnHide.    \n    if (scriptTable.config.useCastBarColor) then\n        if (envTable._CanInterrupt) then\n            self:SetStatusBarColor (Plater:ParseColors (envTable.castBarColor))\n        else\n            self:SetStatusBarColor (Plater:ParseColors (envTable.castBarNoInterruptColor))\n        end\n    end\n    \nend",
      ["Enabled"] = false,
      ["Revision"] = 742,
      ["Options"] = {
        {
          ["Type"] = 5,
          ["Key"] = "option2",
          ["Value"] = "Produces an effect to indicate the spell will hit players in front of the enemy.",
          ["Name"] = "Option 2",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_label",
          ["Desc"] = "",
        }, -- [1]
        {
          ["Type"] = 5,
          ["Key"] = "option4",
          ["Value"] = "Enter the spell name or spellID of the Spell in the Add Trigger box and hit \"Add\".",
          ["Name"] = "Option 4",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_label",
          ["Desc"] = "",
        }, -- [2]
        {
          ["Type"] = 6,
          ["Key"] = "option1",
          ["Value"] = 0,
          ["Name"] = "Option 1",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [3]
        {
          ["Type"] = 2,
          ["Max"] = 1,
          ["Desc"] = "Set the alpha of the moving arrow",
          ["Min"] = 0,
          ["Key"] = "arrowAlpha",
          ["Value"] = 0.73,
          ["Fraction"] = true,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Arrow Alpha",
        }, -- [4]
        {
          ["Type"] = 2,
          ["Max"] = 1,
          ["Desc"] = "Time that takes for an arrow to travel from the to right.",
          ["Min"] = 0,
          ["Key"] = "animSpeed",
          ["Value"] = 0.2,
          ["Fraction"] = true,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Animation Speed",
        }, -- [5]
        {
          ["Type"] = 4,
          ["Key"] = "desaturateArrow",
          ["Value"] = false,
          ["Name"] = "Use White Arrow",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_bool",
          ["Desc"] = "If enabled, the arrow color will be desaturated.",
        }, -- [6]
        {
          ["Type"] = 6,
          ["Key"] = "option3",
          ["Value"] = 0,
          ["Name"] = "Option 3",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [7]
        {
          ["Type"] = 4,
          ["Key"] = "useCastBarColor",
          ["Value"] = true,
          ["Name"] = "Cast Bar Color Enabled",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_bool",
          ["Desc"] = "When enabled, changes the cast bar color.",
        }, -- [8]
        {
          ["Type"] = 1,
          ["Key"] = "castBarColor",
          ["Value"] = {
            1, -- [1]
            0.43137258291245, -- [2]
            0, -- [3]
            1, -- [4]
          },
          ["Name"] = "Cast Bar Color",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
          ["Desc"] = "",
        }, -- [9]
        {
          ["Type"] = 1,
          ["Key"] = "castBarNoInterruptColor",
          ["Value"] = {
            0.24705883860588, -- [1]
            0, -- [2]
            1, -- [3]
            1, -- [4]
          },
          ["Name"] = "Cast Bar Uninterruptible Color",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
          ["Desc"] = "",
        }, -- [10]
      },
      ["Name"] = "Cast - Frontal Cone [OPS]",
      ["Prio"] = 99,
      ["Author"] = "Izimode-Azralon",
      ["Initialization"] = "function (scriptTable)\n    --insert code here\n    \nend\n\n\n",
      ["Desc"] = "Does an animation for casts that affect the frontal area of the enemy. Add spell in the Add Trigger field.",
      ["SpellIds"] = {
        88308, -- [1]
        183088, -- [2]
        183465, -- [3]
        188169, -- [4]
        200700, -- [5]
        226296, -- [6]
        226406, -- [7]
        257426, -- [8]
        257870, -- [9]
        260793, -- [10]
        260894, -- [11]
        265019, -- [12]
        265540, -- [13]
        269843, -- [14]
        272457, -- [15]
        272609, -- [16]
        274400, -- [17]
        369061, -- [18]
        369409, -- [19]
        369563, -- [20]
        369573, -- [21]
        370764, -- [22]
        372087, -- [23]
        372311, -- [24]
        374361, -- [25]
        374563, -- [26]
        375251, -- [27]
        375351, -- [28]
        375727, -- [29]
        375943, -- [30]
        376170, -- [31]
        376811, -- [32]
        377034, -- [33]
        377204, -- [34]
        377383, -- [35]
        377559, -- [36]
        381525, -- [37]
        382233, -- [38]
        382708, -- [39]
        382712, -- [40]
        384524, -- [41]
        384699, -- [42]
        385578, -- [43]
        385958, -- [44]
        386660, -- [45]
        387067, -- [46]
        388060, -- [47]
        388623, -- [48]
        388976, -- [49]
        390006, -- [50]
        391118, -- [51]
        391136, -- [52]
        391723, -- [53]
        391726, -- [54]
        393432, -- [55]
        394357, -- [56]
        395184, -- [57]
        413145, -- [58]
        413147, -- [59]
        400430, -- [60]
        401258, -- [61]
        404472, -- [62]
        404896, -- [63]
        406227, -- [64]
        406333, -- [65]
        406783, -- [66]
        407733, -- [67]
        409093, -- [68]
        410351, -- [69]
        412117, -- [70]
        412129, -- [71]
        412200, -- [72]
        413529, -- [73]
        419351, -- [74]
      },
      ["Temp_UpdateCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    unitFrame._movingArrowTexture:SetAlpha(scriptTable.config.arrowAlpha)\n    \n    local percent = envTable.movingAnimation:GetProgress()\n    \n    if (percent < 0.4) then\n        local value = Lerp(0.01, scriptTable.config.arrowAlpha, percent) or 0\n        unitFrame._movingArrowTexture:SetAlpha(Saturate(value))\n        \n    elseif (percent > 0.6) then\n        local value = Lerp(scriptTable.config.arrowAlpha, 0.01, percent) or 0\n        unitFrame._movingArrowTexture:SetAlpha(Saturate(value))\n    end\n    \n    unitFrame._movingArrowTexture:SetAlpha(1)\n    \n    self.ThrottleUpdate = 0\nend",
      ["version"] = 13,
      ["PlaterCore"] = 1,
      ["Temp_ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    local movingArrowTexture = unitFrame._movingArrowTexture\n    if (not movingArrowTexture) then\n        movingArrowTexture = self:CreateTexture(nil, \"artwork\", nil, 6)\n        unitFrame._movingArrowTexture = movingArrowTexture\n    end\n    \n    envTable.movingAnimation = envTable.movingAnimation or Plater:CreateAnimationHub (unitFrame._movingArrowTexture, \n        function() \n            unitFrame._movingArrowTexture:Show() \n            unitFrame._movingArrowTexture:SetPoint(\"left\", 0, 0)\n        end, \n        function() unitFrame._movingArrowTexture:Hide() end)\n    \n    envTable.movingAnimation:SetLooping (\"REPEAT\")\n    \n    envTable.arrowAnimation = envTable.arrowAnimation or Plater:CreateAnimation (envTable.movingAnimation, \"translation\", 1, 0.20, self:GetWidth()-16, 0)\n    \n    envTable.arrowAnimation:SetDuration(scriptTable.config.animSpeed)\n    \n    -- castbar color\n    envTable.castBarColor = scriptTable.config.castBarColor\n    envTable.castBarNoInterruptColor = scriptTable.config.castBarNoInterruptColor\n    \nend\n\n\n",
      ["semver"] = "1.1.10",
      ["Temp_Initialization"] = "function (scriptTable)\n    --insert code here\n    \nend\n\n\n",
      ["UpdateCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    unitFrame._movingArrowTexture:SetAlpha(scriptTable.config.arrowAlpha)\n    \n    local percent = envTable.movingAnimation:GetProgress()\n    \n    if (percent < 0.4) then\n        local value = Lerp(0.01, scriptTable.config.arrowAlpha, percent) or 0\n        unitFrame._movingArrowTexture:SetAlpha(Saturate(value))\n        \n    elseif (percent > 0.6) then\n        local value = Lerp(scriptTable.config.arrowAlpha, 0.01, percent) or 0\n        unitFrame._movingArrowTexture:SetAlpha(Saturate(value))\n    end\n    \n    unitFrame._movingArrowTexture:SetAlpha(1)\n    \n    self.ThrottleUpdate = 0\nend",
    }, -- [16]
    {
      ["ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    --settings\n    envTable.NameplateSizeOffset = scriptTable.config.castBarHeight\n    envTable.ShowArrow = scriptTable.config.showArrow\n    envTable.ArrowAlpha = scriptTable.config.arrowAlpha\n    \n    --creates the spark to show the cast progress inside the health bar\n    envTable.overlaySpark = envTable.overlaySpark or Plater:CreateImage (unitFrame.healthBar)\n    envTable.overlaySpark:SetBlendMode (\"ADD\")\n    envTable.overlaySpark.width = 16\n    envTable.overlaySpark.height = 36\n    envTable.overlaySpark.alpha = .9\n    envTable.overlaySpark.texture = [[Interface\\AddOns\\Plater\\images\\spark3]]\n    \n    envTable.topArrow = envTable.topArrow or Plater:CreateImage (unitFrame.healthBar)\n    envTable.topArrow:SetBlendMode (\"ADD\")\n    envTable.topArrow.width = scriptTable.config.arrowWidth\n    envTable.topArrow.height = scriptTable.config.arrowHeight\n    envTable.topArrow.alpha = envTable.ArrowAlpha\n    envTable.topArrow.texture = [[Interface\\BUTTONS\\Arrow-Down-Up]]\n    \n    --scale animation\n    envTable.smallScaleAnimation = envTable.smallScaleAnimation or Plater:CreateAnimationHub (unitFrame.healthBar)\n    Plater:CreateAnimation (envTable.smallScaleAnimation, \"SCALE\", 1, 0.075, 1, 1, 1.08, 1.08)\n    Plater:CreateAnimation (envTable.smallScaleAnimation, \"SCALE\", 2, 0.075, 1, 1, 0.95, 0.95)    \n    --envTable.smallScaleAnimation:Play() --envTable.smallScaleAnimation:Stop()\n    \n    --create a camera shake for the nameplate\n    envTable.FrameShake = Plater:CreateFrameShake (unitFrame, scriptTable.config.shakeDuration, scriptTable.config.shakeAmplitude, scriptTable.config.shakeFrequency, false, false, 0, 1, 0.05, 0.1, Plater.GetPoints (unitFrame))    \n    \n    --update the config for the skake here so it wont need a /reload\n    envTable.FrameShake.OriginalAmplitude = scriptTable.config.shakeAmplitude\n    envTable.FrameShake.OriginalDuration = scriptTable.config.shakeDuration\n    envTable.FrameShake.OriginalFrequency = scriptTable.config.shakeFrequency\nend\n\n\n\n\n\n\n\n",
      ["OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    Plater.StopDotAnimation(unitFrame.healthBar, envTable.dotAnimation)\n    \n    envTable.overlaySpark:Hide()\n    envTable.topArrow:Hide()\n    \n    Plater.RefreshNameplateColor (unitFrame)\n    \n    envTable.smallScaleAnimation:Stop()\n    \n    --increase the nameplate size\n    local nameplateHeight = Plater.db.profile.plate_config.enemynpc.health_incombat [2]\n    unitFrame.healthBar:SetHeight (nameplateHeight)\n    \n    Plater.DenyColorChange(unitFrame, false)\nend\n\n\n",
      ["OptionsValues"] = {
        ["castColor"] = {
          {
            "200682", -- [1]
            "darkslateblue", -- [2]
          }, -- [1]
          {
            "192307", -- [1]
            "goldenrod", -- [2]
          }, -- [2]
          {
            "196838", -- [1]
            "maroon", -- [2]
          }, -- [3]
          {
            "193827", -- [1]
            "darkgreen", -- [2]
          }, -- [4]
          {
            "194043", -- [1]
            "darkgreen", -- [2]
          }, -- [5]
          {
            "156718", -- [1]
            "DRUID", -- [2]
          }, -- [6]
          {
            "395859", -- [1]
            "ROGUE", -- [2]
          }, -- [7]
        },
        ["castBarNoInterruptColor"] = {
          0.6313725709915161, -- [1]
          0.1372549086809158, -- [2]
          0.168627455830574, -- [3]
          0.8041767030954361, -- [4]
        },
      },
      ["Temp_OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    envTable.overlaySpark:Show()\n    \n    if (envTable.ShowArrow) then\n        envTable.topArrow:Show()\n    else\n        envTable.topArrow:Hide()\n    end\n    \n    Plater.FlashNameplateBorder (unitFrame, 0.05)   \n    Plater.FlashNameplateBody (unitFrame, \"\", 0.075)\n    \n    envTable.smallScaleAnimation:Play()\n    \n    --increase the nameplate size\n    local nameplateHeight = Plater.db.profile.plate_config.enemynpc.health_incombat [2]\n    unitFrame.healthBar:SetHeight (nameplateHeight + envTable.NameplateSizeOffset)\n    \n    envTable.overlaySpark.height = nameplateHeight + 5\n    \n    envTable.dotAnimation = Plater.PlayDotAnimation(unitFrame.healthBar, 2, scriptTable.config.dotColor, scriptTable.config.xOffset, scriptTable.config.yOffset)\n    \n    local customColor = scriptTable.config.castColor[tostring(envTable._SpellID)]\n    \n    if (scriptTable.config.useCastbarColor) then\n        if (envTable._CanInterrupt) then\n            self:SetStatusBarColor (Plater:ParseColors (scriptTable.config.castBarColor))\n        else\n            self:SetStatusBarColor (Plater:ParseColors (scriptTable.config.castBarNoInterruptColor))\n        end\n    end\n    \n    -- Plater.SetCastBarColorForScript(self, scriptTable.config.useCastbarColor, customColor or scriptTable.config.castBarColor, envTable)\n    \n    if (scriptTable.config.useNameplateColor) then\n        local npcIdString = tostring(envTable._NpcID)\n        envTable.NameplateColor = Plater.GetColorByPriority(unitFrame, scriptTable.config.healthBarColor)        \n        Plater.DenyColorChange(unitFrame, true)            \n    end\n    \nend",
      ["ScriptType"] = 2,
      ["__TrashAt"] = 1699197153,
      ["Time"] = 1699196710,
      ["Icon"] = "Interface\\AddOns\\Plater\\images\\cast_bar_red",
      ["Temp_OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    Plater.StopDotAnimation(unitFrame.healthBar, envTable.dotAnimation)\n    \n    envTable.overlaySpark:Hide()\n    envTable.topArrow:Hide()\n    \n    Plater.RefreshNameplateColor (unitFrame)\n    \n    envTable.smallScaleAnimation:Stop()\n    \n    --increase the nameplate size\n    local nameplateHeight = Plater.db.profile.plate_config.enemynpc.health_incombat [2]\n    unitFrame.healthBar:SetHeight (nameplateHeight)\n    \n    Plater.DenyColorChange(unitFrame, false)\nend\n\n\n",
      ["url"] = "https://wago.io/JgozGbm1a/16",
      ["NpcNames"] = {
      },
      ["OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    envTable.overlaySpark:Show()\n    \n    if (envTable.ShowArrow) then\n        envTable.topArrow:Show()\n    else\n        envTable.topArrow:Hide()\n    end\n    \n    Plater.FlashNameplateBorder (unitFrame, 0.05)   \n    Plater.FlashNameplateBody (unitFrame, \"\", 0.075)\n    \n    envTable.smallScaleAnimation:Play()\n    \n    --increase the nameplate size\n    local nameplateHeight = Plater.db.profile.plate_config.enemynpc.health_incombat [2]\n    unitFrame.healthBar:SetHeight (nameplateHeight + envTable.NameplateSizeOffset)\n    \n    envTable.overlaySpark.height = nameplateHeight + 5\n    \n    envTable.dotAnimation = Plater.PlayDotAnimation(unitFrame.healthBar, 2, scriptTable.config.dotColor, scriptTable.config.xOffset, scriptTable.config.yOffset)\n    \n    local customColor = scriptTable.config.castColor[tostring(envTable._SpellID)]\n    \n    if (scriptTable.config.useCastbarColor) then\n        if (envTable._CanInterrupt) then\n            self:SetStatusBarColor (Plater:ParseColors (scriptTable.config.castBarColor))\n        else\n            self:SetStatusBarColor (Plater:ParseColors (scriptTable.config.castBarNoInterruptColor))\n        end\n    end\n    \n    -- Plater.SetCastBarColorForScript(self, scriptTable.config.useCastbarColor, customColor or scriptTable.config.castBarColor, envTable)\n    \n    if (scriptTable.config.useNameplateColor) then\n        local npcIdString = tostring(envTable._NpcID)\n        envTable.NameplateColor = Plater.GetColorByPriority(unitFrame, scriptTable.config.healthBarColor)        \n        Plater.DenyColorChange(unitFrame, true)            \n    end\n    \nend",
      ["Enabled"] = false,
      ["Revision"] = 800,
      ["Options"] = {
        {
          ["Type"] = 6,
          ["Key"] = "option1",
          ["Value"] = 0,
          ["Name"] = "Option 1",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [1]
        {
          ["Type"] = 5,
          ["Key"] = "option2",
          ["Value"] = "Plays a special animation showing the explosion time.",
          ["Name"] = "Option 2",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_label",
          ["Desc"] = "",
        }, -- [2]
        {
          ["Type"] = 6,
          ["Key"] = "option3",
          ["Value"] = 0,
          ["Name"] = "Option 3",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [3]
        {
          ["Type"] = 2,
          ["Max"] = 6,
          ["Desc"] = "Increases the health bar height by this value",
          ["Min"] = 0,
          ["Key"] = "castBarHeight",
          ["Value"] = 3,
          ["Fraction"] = false,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Health Bar Height Mod",
        }, -- [4]
        {
          ["Type"] = 4,
          ["Key"] = "useNameplateColor",
          ["Value"] = true,
          ["Name"] = "Change Nameplate Color",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_bool",
          ["Desc"] = "Change Nameplate Color",
        }, -- [5]
        {
          ["Type"] = 1,
          ["Key"] = "healthBarColor",
          ["Value"] = {
            1, -- [1]
            0.5843137254902, -- [2]
            0, -- [3]
            1, -- [4]
          },
          ["Name"] = "Nameplate Color",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
          ["Desc"] = "Nameplate Color",
        }, -- [6]
        {
          ["Type"] = 6,
          ["Key"] = "option7",
          ["Value"] = 0,
          ["Name"] = "Option 7",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [7]
        {
          ["Type"] = 4,
          ["Key"] = "useCastbarColor",
          ["Value"] = true,
          ["Name"] = "Use Cast Bar Color",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_bool",
          ["Desc"] = "Show an arrow above Use Cast Bar Color",
        }, -- [8]
        {
          ["Type"] = 1,
          ["Key"] = "castBarColor",
          ["Value"] = {
            1, -- [1]
            0.43137258291245, -- [2]
            0, -- [3]
            1, -- [4]
          },
          ["Name"] = "Cast Bar Color",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
          ["Desc"] = "Cast Bar Color",
        }, -- [9]
        {
          ["Type"] = 1,
          ["Key"] = "castBarNoInterruptColor",
          ["Value"] = {
            1, -- [1]
            1, -- [2]
            0, -- [3]
            1, -- [4]
          },
          ["Name"] = "Cast Bar Uninterruptible Color",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
          ["Desc"] = "Cast Bar Uninterruptible Color",
        }, -- [10]
        {
          ["Type"] = 6,
          ["Key"] = "option7",
          ["Value"] = 0,
          ["Name"] = "Option 7",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [11]
        {
          ["Type"] = 5,
          ["Key"] = "option6",
          ["Value"] = "Arrow:",
          ["Name"] = "Arrow:",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_label",
          ["Desc"] = "",
        }, -- [12]
        {
          ["Type"] = 4,
          ["Key"] = "showArrow",
          ["Value"] = true,
          ["Name"] = "Show Arrow",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_bool",
          ["Desc"] = "Show an arrow above the nameplate showing the cast bar progress.",
        }, -- [13]
        {
          ["Type"] = 2,
          ["Max"] = 1,
          ["Desc"] = "Arrow alpha.",
          ["Min"] = 0,
          ["Key"] = "arrowAlpha",
          ["Value"] = 0.5,
          ["Fraction"] = true,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Arrow Alpha",
        }, -- [14]
        {
          ["Type"] = 2,
          ["Max"] = 12,
          ["Desc"] = "Arrow Width.",
          ["Min"] = 4,
          ["Key"] = "arrowWidth",
          ["Value"] = 8,
          ["Fraction"] = false,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Arrow Width",
        }, -- [15]
        {
          ["Type"] = 2,
          ["Max"] = 12,
          ["Desc"] = "Arrow Height.",
          ["Min"] = 4,
          ["Key"] = "arrowHeight",
          ["Value"] = 8,
          ["Fraction"] = false,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Arrow Height",
        }, -- [16]
        {
          ["Type"] = 6,
          ["Key"] = "option13",
          ["Value"] = 0,
          ["Name"] = "Option 13",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [17]
        {
          ["Type"] = 5,
          ["Key"] = "option12",
          ["Value"] = "Dot Animation:",
          ["Name"] = "Dot Animation:",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_label",
          ["Desc"] = "",
        }, -- [18]
        {
          ["Type"] = 1,
          ["Key"] = "dotColor",
          ["Value"] = {
            1, -- [1]
            0.6156862745098, -- [2]
            0, -- [3]
            1, -- [4]
          },
          ["Name"] = "Dot Color",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
          ["Desc"] = "Adjust the color of the dot animation.",
        }, -- [19]
        {
          ["Type"] = 2,
          ["Max"] = 10,
          ["Desc"] = "Dot X Offset",
          ["Min"] = -10,
          ["Key"] = "xOffset",
          ["Value"] = 4,
          ["Fraction"] = false,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Dot X Offset",
        }, -- [20]
        {
          ["Type"] = 2,
          ["Max"] = 10,
          ["Desc"] = "Dot Y Offset",
          ["Min"] = -10,
          ["Key"] = "yOffset",
          ["Value"] = 3,
          ["Fraction"] = false,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Dot Y Offset",
        }, -- [21]
        {
          ["Type"] = 7,
          ["Key"] = "castColor",
          ["Value"] = {
            {
              "200682", -- [1]
              "darkslateblue", -- [2]
            }, -- [1]
            {
              "192307", -- [1]
              "goldenrod", -- [2]
            }, -- [2]
            {
              "196838", -- [1]
              "maroon", -- [2]
            }, -- [3]
            {
              "193827", -- [1]
              "darkgreen", -- [2]
            }, -- [4]
            {
              "194043", -- [1]
              "darkgreen", -- [2]
            }, -- [5]
            {
              "156718", -- [1]
              "DRUID", -- [2]
            }, -- [6]
            {
              "395859", -- [1]
              "ROGUE", -- [2]
            }, -- [7]
          },
          ["Name"] = "Color List by SpellId",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_list",
          ["Desc"] = "Insert the spellId in the Key, and the color name in the Value",
        }, -- [22]
      },
      ["Name"] = "Cast - Ultra Important [OPS]",
      ["Prio"] = 99,
      ["Author"] = "Bombad�o-Azralon",
      ["Initialization"] = "function (scriptTable)\n    --insert code here\n    \nend\n\n\n",
      ["Desc"] = "Used on casts that make the mob explode or transform if the cast passes.",
      ["SpellIds"] = {
        87618, -- [1]
        87761, -- [2]
        87762, -- [3]
        183526, -- [4]
        188114, -- [5]
        193803, -- [6]
        198963, -- [7]
        200404, -- [8]
        201983, -- [9]
        256060, -- [10]
        257736, -- [11]
        257784, -- [12]
        265091, -- [13]
        265433, -- [14]
        266106, -- [15]
        278755, -- [16]
        367500, -- [17]
        368990, -- [18]
        369328, -- [19]
        369703, -- [20]
        370225, -- [21]
        372107, -- [22]
        372701, -- [23]
        372719, -- [24]
        372851, -- [25]
        373939, -- [26]
        374045, -- [27]
        374569, -- [28]
        374594, -- [29]
        374699, -- [30]
        375056, -- [31]
        375596, -- [32]
        376049, -- [33]
        376200, -- [34]
        377348, -- [35]
        377488, -- [36]
        378208, -- [37]
        378229, -- [38]
        378282, -- [39]
        381663, -- [40]
        382578, -- [41]
        382670, -- [42]
        383823, -- [43]
        384662, -- [44]
        384899, -- [45]
        385442, -- [46]
        385536, -- [47]
        386024, -- [48]
        386757, -- [49]
        387411, -- [50]
        387618, -- [51]
        388537, -- [52]
        391634, -- [53]
        392451, -- [54]
        395694, -- [55]
        400777, -- [56]
        403459, -- [57]
        403671, -- [58]
        403978, -- [59]
        404713, -- [60]
        404732, -- [61]
        405375, -- [62]
        405437, -- [63]
        405886, -- [64]
        407775, -- [65]
        408476, -- [66]
        409271, -- [67]
        411001, -- [68]
        413044, -- [69]
        412063, -- [70]
        412922, -- [71]
      },
      ["Temp_UpdateCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    --update the percent\n    envTable.overlaySpark:SetPoint (\"left\", unitFrame.healthBar:GetWidth() * (envTable._CastPercent / 100)-9, 0)\n    \n    envTable.topArrow:SetPoint (\"bottomleft\", unitFrame.healthBar, \"topleft\", unitFrame.healthBar:GetWidth() * (envTable._CastPercent / 100) - 4, 2 )\n    \n    --forces the script to update on a 60Hz base\n    self.ThrottleUpdate = 0\n    \n    if (scriptTable.config.useNameplateColor) then\n        Plater.SetNameplateColor(unitFrame, envTable.NameplateColor)\n    end\n    \nend\n\n\n\n\n",
      ["version"] = 16,
      ["PlaterCore"] = 1,
      ["Temp_ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    --settings\n    envTable.NameplateSizeOffset = scriptTable.config.castBarHeight\n    envTable.ShowArrow = scriptTable.config.showArrow\n    envTable.ArrowAlpha = scriptTable.config.arrowAlpha\n    \n    --creates the spark to show the cast progress inside the health bar\n    envTable.overlaySpark = envTable.overlaySpark or Plater:CreateImage (unitFrame.healthBar)\n    envTable.overlaySpark:SetBlendMode (\"ADD\")\n    envTable.overlaySpark.width = 16\n    envTable.overlaySpark.height = 36\n    envTable.overlaySpark.alpha = .9\n    envTable.overlaySpark.texture = [[Interface\\AddOns\\Plater\\images\\spark3]]\n    \n    envTable.topArrow = envTable.topArrow or Plater:CreateImage (unitFrame.healthBar)\n    envTable.topArrow:SetBlendMode (\"ADD\")\n    envTable.topArrow.width = scriptTable.config.arrowWidth\n    envTable.topArrow.height = scriptTable.config.arrowHeight\n    envTable.topArrow.alpha = envTable.ArrowAlpha\n    envTable.topArrow.texture = [[Interface\\BUTTONS\\Arrow-Down-Up]]\n    \n    --scale animation\n    envTable.smallScaleAnimation = envTable.smallScaleAnimation or Plater:CreateAnimationHub (unitFrame.healthBar)\n    Plater:CreateAnimation (envTable.smallScaleAnimation, \"SCALE\", 1, 0.075, 1, 1, 1.08, 1.08)\n    Plater:CreateAnimation (envTable.smallScaleAnimation, \"SCALE\", 2, 0.075, 1, 1, 0.95, 0.95)    \n    --envTable.smallScaleAnimation:Play() --envTable.smallScaleAnimation:Stop()\n    \n    --create a camera shake for the nameplate\n    envTable.FrameShake = Plater:CreateFrameShake (unitFrame, scriptTable.config.shakeDuration, scriptTable.config.shakeAmplitude, scriptTable.config.shakeFrequency, false, false, 0, 1, 0.05, 0.1, Plater.GetPoints (unitFrame))    \n    \n    --update the config for the skake here so it wont need a /reload\n    envTable.FrameShake.OriginalAmplitude = scriptTable.config.shakeAmplitude\n    envTable.FrameShake.OriginalDuration = scriptTable.config.shakeDuration\n    envTable.FrameShake.OriginalFrequency = scriptTable.config.shakeFrequency\nend\n\n\n\n\n\n\n\n",
      ["semver"] = "1.1.13",
      ["Temp_Initialization"] = "function (scriptTable)\n    --insert code here\n    \nend\n\n\n",
      ["UpdateCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    --update the percent\n    envTable.overlaySpark:SetPoint (\"left\", unitFrame.healthBar:GetWidth() * (envTable._CastPercent / 100)-9, 0)\n    \n    envTable.topArrow:SetPoint (\"bottomleft\", unitFrame.healthBar, \"topleft\", unitFrame.healthBar:GetWidth() * (envTable._CastPercent / 100) - 4, 2 )\n    \n    --forces the script to update on a 60Hz base\n    self.ThrottleUpdate = 0\n    \n    if (scriptTable.config.useNameplateColor) then\n        Plater.SetNameplateColor(unitFrame, envTable.NameplateColor)\n    end\n    \nend\n\n\n\n\n",
    }, -- [17]
    {
      ["ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    --create a texture to use for a flash behind the cast bar\n    local backGroundFlashTexture = Plater:CreateImage (self, [[Interface\\ACHIEVEMENTFRAME\\UI-Achievement-Alert-Glow]], self:GetWidth()+40, self:GetHeight()+20, \"background\", {0, 400/512, 0, 170/256})\n    backGroundFlashTexture:SetBlendMode (\"ADD\")\n    backGroundFlashTexture:SetDrawLayer(\"OVERLAY\", 7)\n    backGroundFlashTexture:SetPoint (\"center\", self, \"center\")\n    backGroundFlashTexture:SetVertexColor(Plater:ParseColors(scriptTable.config.flashColor))\n    backGroundFlashTexture:Hide()\n    \n    --create the animation hub to hold the flash animation sequence\n    envTable.BackgroundFlash = envTable.BackgroundFlash or Plater:CreateAnimationHub (backGroundFlashTexture, \n        function()\n            backGroundFlashTexture:Show()\n        end,\n        function()\n            backGroundFlashTexture:Hide()\n        end\n    )\n    \n    --create the flash animation sequence\n    local fadeIn = Plater:CreateAnimation (envTable.BackgroundFlash, \"ALPHA\", 1, scriptTable.config.flashDuration/2, 0, 1)\n    local fadeOut = Plater:CreateAnimation (envTable.BackgroundFlash, \"ALPHA\", 2, scriptTable.config.flashDuration/2, 1, 0)\n    \n    --create a camera shake for the nameplate\n    envTable.FrameShake = Plater:CreateFrameShake (unitFrame, scriptTable.config.shakeDuration, scriptTable.config.shakeAmplitude, scriptTable.config.shakeFrequency, false, false, 0, 1, 0.05, 0.1, Plater.GetPoints (unitFrame))\n    \n    --update the config for the flash here so it wont need a /reload\n    fadeIn:SetDuration (scriptTable.config.flashDuration/2)\n    fadeOut:SetDuration (scriptTable.config.flashDuration/2)\n    \n    --update the config for the skake here so it wont need a /reload\n    envTable.FrameShake.OriginalAmplitude = scriptTable.config.shakeAmplitude\n    envTable.FrameShake.OriginalDuration = scriptTable.config.shakeDuration\n    envTable.FrameShake.OriginalFrequency = scriptTable.config.shakeFrequency\n    \n    envTable.castBarColor = scriptTable.config.castBarColor\n    envTable.castBarNoInterruptColor = scriptTable.config.castBarNoInterruptColor\nend",
      ["OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    Plater.StopDotAnimation(unitFrame.castBar, envTable.dotAnimation)    \n    \n    envTable.BackgroundFlash:Stop()\n    \n    unitFrame:StopFrameShake (envTable.FrameShake)    \n    \nend\n\n\n",
      ["OptionsValues"] = {
        ["castBarNoInterruptColor"] = {
          0.6313725709915161, -- [1]
          0.1372549086809158, -- [2]
          0.168627455830574, -- [3]
          0.8062664121389389, -- [4]
        },
      },
      ["Temp_OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    envTable.dotAnimation = Plater.PlayDotAnimation(unitFrame.castBar, 5, scriptTable.config.dotColor, scriptTable.config.xOffset, scriptTable.config.yOffset)\n    \n    envTable.BackgroundFlash:Play()\n    \n    Plater.FlashNameplateBorder (unitFrame, 0.05)   \n    Plater.FlashNameplateBody (unitFrame, \"\", 0.075)\n    \n    unitFrame:PlayFrameShake (envTable.FrameShake)\n    \n    -- Plater auto set this color to default when a new cast starts, no need to reset this value at OnHide.\n    if (scriptTable.config.useCastbarColor) then\n        if (envTable._CanInterrupt) then\n            self:SetStatusBarColor (Plater:ParseColors (envTable.castBarColor))\n        else\n            self:SetStatusBarColor (Plater:ParseColors (envTable.castBarNoInterruptColor))\n        end\n    end\n    \n    -- Does not support non-interruptable casts\n    -- Plater.SetCastBarColorForScript(self, scriptTable.config.useCastbarColor, scriptTable.config.castBarColor, envTable)\n    \n    --Dominator on Shadowmoon Burial Grounds\n    if (envTable._SpellID == 154327) then\n        if (UnitHealth(unitId) == UnitHealthMax(unitId)) then\n            if (envTable._Duration == 604800) then\n                Plater.SetCastBarColorForScript(self, scriptTable.config.useCastbarColor, {1, 0, 0, 1}, envTable)\n            end\n        end\n    end\nend",
      ["ScriptType"] = 2,
      ["__TrashAt"] = 1699197158,
      ["Time"] = 1698536536,
      ["Icon"] = "Interface\\AddOns\\Plater\\images\\cast_bar_darkorange",
      ["Temp_OnHideCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \n    Plater.StopDotAnimation(unitFrame.castBar, envTable.dotAnimation)    \n    \n    envTable.BackgroundFlash:Stop()\n    \n    unitFrame:StopFrameShake (envTable.FrameShake)    \n    \nend\n\n\n",
      ["url"] = "https://wago.io/oJsL1K1Dt/15",
      ["NpcNames"] = {
      },
      ["OnShowCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    envTable.dotAnimation = Plater.PlayDotAnimation(unitFrame.castBar, 5, scriptTable.config.dotColor, scriptTable.config.xOffset, scriptTable.config.yOffset)\n    \n    envTable.BackgroundFlash:Play()\n    \n    Plater.FlashNameplateBorder (unitFrame, 0.05)   \n    Plater.FlashNameplateBody (unitFrame, \"\", 0.075)\n    \n    unitFrame:PlayFrameShake (envTable.FrameShake)\n    \n    -- Plater auto set this color to default when a new cast starts, no need to reset this value at OnHide.\n    if (scriptTable.config.useCastbarColor) then\n        if (envTable._CanInterrupt) then\n            self:SetStatusBarColor (Plater:ParseColors (envTable.castBarColor))\n        else\n            self:SetStatusBarColor (Plater:ParseColors (envTable.castBarNoInterruptColor))\n        end\n    end\n    \n    -- Does not support non-interruptable casts\n    -- Plater.SetCastBarColorForScript(self, scriptTable.config.useCastbarColor, scriptTable.config.castBarColor, envTable)\n    \n    --Dominator on Shadowmoon Burial Grounds\n    if (envTable._SpellID == 154327) then\n        if (UnitHealth(unitId) == UnitHealthMax(unitId)) then\n            if (envTable._Duration == 604800) then\n                Plater.SetCastBarColorForScript(self, scriptTable.config.useCastbarColor, {1, 0, 0, 1}, envTable)\n            end\n        end\n    end\nend",
      ["Enabled"] = false,
      ["Revision"] = 931,
      ["Options"] = {
        {
          ["Type"] = 6,
          ["Key"] = "option1",
          ["Value"] = 0,
          ["Name"] = "Option 1",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [1]
        {
          ["Type"] = 5,
          ["Key"] = "option2",
          ["Value"] = "Plays a big animation when the cast start.",
          ["Name"] = "Option 2",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_label",
          ["Desc"] = "",
        }, -- [2]
        {
          ["Type"] = 5,
          ["Key"] = "option2",
          ["Value"] = "Enter the spell name or spellID of the Spell in the Add Trigger box and hit \"Add\".",
          ["Name"] = "Option 2",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_label",
          ["Desc"] = "",
        }, -- [3]
        {
          ["Type"] = 6,
          ["Key"] = "option4",
          ["Value"] = 0,
          ["Name"] = "Option 4",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [4]
        {
          ["Type"] = 5,
          ["Key"] = "option2",
          ["Value"] = "Flash:",
          ["Name"] = "Flash",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_label",
          ["Desc"] = "",
        }, -- [5]
        {
          ["Type"] = 2,
          ["Max"] = 1.2,
          ["Desc"] = "How long is the flash played when the cast starts.",
          ["Min"] = 0.1,
          ["Key"] = "flashDuration",
          ["Value"] = 0.8,
          ["Fraction"] = true,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Flash Duration",
        }, -- [6]
        {
          ["Type"] = 1,
          ["Key"] = "flashColor",
          ["Value"] = {
            1, -- [1]
            0, -- [2]
            1, -- [3]
            1, -- [4]
          },
          ["Name"] = "Flash Color",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
          ["Desc"] = "Color of the Flash",
        }, -- [7]
        {
          ["Type"] = 6,
          ["Key"] = "option7",
          ["Value"] = 0,
          ["Name"] = "Option 7",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [8]
        {
          ["Type"] = 5,
          ["Key"] = "option2",
          ["Value"] = "Shake:",
          ["Name"] = "Shake",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_label",
          ["Desc"] = "",
        }, -- [9]
        {
          ["Type"] = 2,
          ["Max"] = 0.5,
          ["Desc"] = "When the cast starts, there's a small shake in the nameplate, this settings controls how long it takes.",
          ["Min"] = 0.1,
          ["Key"] = "shakeDuration",
          ["Value"] = 0.2,
          ["Fraction"] = true,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Shake Duration",
        }, -- [10]
        {
          ["Type"] = 2,
          ["Max"] = 10,
          ["Desc"] = "How strong is the shake.",
          ["Min"] = 1,
          ["Key"] = "shakeAmplitude",
          ["Value"] = 5,
          ["Fraction"] = false,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Shake Amplitude",
        }, -- [11]
        {
          ["Type"] = 2,
          ["Max"] = 80,
          ["Desc"] = "How fast the shake moves.",
          ["Min"] = 1,
          ["Key"] = "shakeFrequency",
          ["Value"] = 40,
          ["Fraction"] = false,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Shake Frequency",
        }, -- [12]
        {
          ["Type"] = 6,
          ["Key"] = "option13",
          ["Value"] = 0,
          ["Name"] = "Option 13",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [13]
        {
          ["Type"] = 5,
          ["Key"] = "option14",
          ["Value"] = "Dot Animation:",
          ["Name"] = "Dot Animation",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_label",
          ["Desc"] = "",
        }, -- [14]
        {
          ["Type"] = 1,
          ["Key"] = "dotColor",
          ["Value"] = {
            1, -- [1]
            0, -- [2]
            1, -- [3]
            1, -- [4]
          },
          ["Name"] = "Dot Color",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
          ["Desc"] = "Adjust the color of the dots around the nameplate",
        }, -- [15]
        {
          ["Type"] = 2,
          ["Max"] = 20,
          ["Desc"] = "Adjust the width of the dots to better fit in your nameplate.",
          ["Min"] = -10,
          ["Key"] = "xOffset",
          ["Value"] = 8,
          ["Fraction"] = false,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Dot X Offset",
        }, -- [16]
        {
          ["Type"] = 2,
          ["Max"] = 10,
          ["Desc"] = "Adjust the height of the dots to better fit in your nameplate.",
          ["Min"] = -10,
          ["Key"] = "yOffset",
          ["Value"] = 3,
          ["Fraction"] = false,
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_number",
          ["Name"] = "Dot Y Offset",
        }, -- [17]
        {
          ["Type"] = 6,
          ["Key"] = "option18",
          ["Value"] = 0,
          ["Name"] = "blank",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [18]
        {
          ["Type"] = 6,
          ["Key"] = "option18",
          ["Value"] = 0,
          ["Name"] = "blank",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [19]
        {
          ["Type"] = 6,
          ["Key"] = "option18",
          ["Value"] = 0,
          ["Name"] = "blank",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [20]
        {
          ["Type"] = 6,
          ["Key"] = "option18",
          ["Value"] = 0,
          ["Name"] = "blank",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [21]
        {
          ["Type"] = 6,
          ["Key"] = "option18",
          ["Value"] = 0,
          ["Name"] = "blank",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [22]
        {
          ["Type"] = 6,
          ["Key"] = "option18",
          ["Value"] = 0,
          ["Name"] = "blank",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_blank",
          ["Desc"] = "",
        }, -- [23]
        {
          ["Type"] = 5,
          ["Key"] = "option19",
          ["Value"] = "Cast Bar",
          ["Name"] = "Option 19",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_label",
          ["Desc"] = "",
        }, -- [24]
        {
          ["Type"] = 4,
          ["Key"] = "useCastbarColor",
          ["Value"] = true,
          ["Name"] = "Use Cast Bar Color",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_bool",
          ["Desc"] = "Use cast bar color.",
        }, -- [25]
        {
          ["Type"] = 1,
          ["Key"] = "castBarColor",
          ["Value"] = {
            0.68627452850342, -- [1]
            0, -- [2]
            1, -- [3]
            1, -- [4]
          },
          ["Name"] = "Cast Bar Color",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
          ["Desc"] = "Cast bar color.",
        }, -- [26]
        {
          ["Type"] = 1,
          ["Key"] = "castBarNoInterruptColor",
          ["Value"] = {
            0.87450987100601, -- [1]
            0, -- [2]
            1, -- [3]
            1, -- [4]
          },
          ["Name"] = "Cast Bar Uninterruptible Color",
          ["Icon"] = "Interface\\AddOns\\Plater\\images\\option_color",
          ["Desc"] = "Uninterruptible cast bar color.",
        }, -- [27]
      },
      ["Name"] = "Cast - Very Important [OPS]",
      ["Prio"] = 99,
      ["Author"] = "Bombad�o-Azralon",
      ["Initialization"] = "function (scriptTable)\n    --insert code here\n    \nend\n\n\n",
      ["Desc"] = "Highlight a very important cast applying several effects into the Cast Bar. Add spell in the Add Trigger field.",
      ["SpellIds"] = {
        3636, -- [1]
        88194, -- [2]
        183548, -- [3]
        193375, -- [4]
        198024, -- [5]
        198428, -- [6]
        199176, -- [7]
        200732, -- [8]
        210150, -- [9]
        255952, -- [10]
        257402, -- [11]
        257458, -- [12]
        257904, -- [13]
        259732, -- [14]
        260333, -- [15]
        264603, -- [16]
        264757, -- [17]
        265568, -- [18]
        369110, -- [19]
        369335, -- [20]
        369677, -- [21]
        369754, -- [22]
        369791, -- [23]
        369806, -- [24]
        372296, -- [25]
        372623, -- [26]
        372863, -- [27]
        373046, -- [28]
        373084, -- [29]
        373424, -- [30]
        374020, -- [31]
        374186, -- [32]
        374365, -- [33]
        374724, -- [34]
        374823, -- [35]
        374839, -- [36]
        375065, -- [37]
        375439, -- [38]
        376208, -- [39]
        376933, -- [40]
        376934, -- [41]
        378827, -- [42]
        381379, -- [43]
        381470, -- [44]
        381593, -- [45]
        381694, -- [46]
        382435, -- [47]
        382802, -- [48]
        384014, -- [49]
        384365, -- [50]
        384961, -- [51]
        385551, -- [52]
        385832, -- [53]
        386559, -- [54]
        387145, -- [55]
        388424, -- [56]
        388882, -- [57]
        392488, -- [58]
        397878, -- [59]
        397914, -- [60]
        398150, -- [61]
        398446, -- [62]
        411000, -- [63]
        413385, -- [64]
        413387, -- [65]
        401316, -- [66]
        401318, -- [67]
        401319, -- [68]
        403101, -- [69]
        403326, -- [70]
        403740, -- [71]
        405016, -- [72]
        405391, -- [73]
        405413, -- [74]
        405492, -- [75]
        405641, -- [76]
        405821, -- [77]
        406358, -- [78]
        406851, -- [79]
        408193, -- [80]
        410019, -- [81]
        412215, -- [82]
        413024, -- [83]
        415769, -- [84]
      },
      ["Temp_UpdateCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \nend\n\n\n",
      ["version"] = 15,
      ["PlaterCore"] = 1,
      ["Temp_ConstructorCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    --create a texture to use for a flash behind the cast bar\n    local backGroundFlashTexture = Plater:CreateImage (self, [[Interface\\ACHIEVEMENTFRAME\\UI-Achievement-Alert-Glow]], self:GetWidth()+40, self:GetHeight()+20, \"background\", {0, 400/512, 0, 170/256})\n    backGroundFlashTexture:SetBlendMode (\"ADD\")\n    backGroundFlashTexture:SetDrawLayer(\"OVERLAY\", 7)\n    backGroundFlashTexture:SetPoint (\"center\", self, \"center\")\n    backGroundFlashTexture:SetVertexColor(Plater:ParseColors(scriptTable.config.flashColor))\n    backGroundFlashTexture:Hide()\n    \n    --create the animation hub to hold the flash animation sequence\n    envTable.BackgroundFlash = envTable.BackgroundFlash or Plater:CreateAnimationHub (backGroundFlashTexture, \n        function()\n            backGroundFlashTexture:Show()\n        end,\n        function()\n            backGroundFlashTexture:Hide()\n        end\n    )\n    \n    --create the flash animation sequence\n    local fadeIn = Plater:CreateAnimation (envTable.BackgroundFlash, \"ALPHA\", 1, scriptTable.config.flashDuration/2, 0, 1)\n    local fadeOut = Plater:CreateAnimation (envTable.BackgroundFlash, \"ALPHA\", 2, scriptTable.config.flashDuration/2, 1, 0)\n    \n    --create a camera shake for the nameplate\n    envTable.FrameShake = Plater:CreateFrameShake (unitFrame, scriptTable.config.shakeDuration, scriptTable.config.shakeAmplitude, scriptTable.config.shakeFrequency, false, false, 0, 1, 0.05, 0.1, Plater.GetPoints (unitFrame))\n    \n    --update the config for the flash here so it wont need a /reload\n    fadeIn:SetDuration (scriptTable.config.flashDuration/2)\n    fadeOut:SetDuration (scriptTable.config.flashDuration/2)\n    \n    --update the config for the skake here so it wont need a /reload\n    envTable.FrameShake.OriginalAmplitude = scriptTable.config.shakeAmplitude\n    envTable.FrameShake.OriginalDuration = scriptTable.config.shakeDuration\n    envTable.FrameShake.OriginalFrequency = scriptTable.config.shakeFrequency\n    \n    envTable.castBarColor = scriptTable.config.castBarColor\n    envTable.castBarNoInterruptColor = scriptTable.config.castBarNoInterruptColor\nend",
      ["semver"] = "1.1.10",
      ["Temp_Initialization"] = "function (scriptTable)\n    --insert code here\n    \nend\n\n\n",
      ["UpdateCode"] = "function (self, unitId, unitFrame, envTable, scriptTable)\n    \nend\n\n\n",
    }, -- [18]
  },
  ["extra_icon_timer_outline"] = "OUTLINE",
  ["castbar_target_anchor"] = {
    ["side"] = 9,
  },
  ["script_auto_imported"] = {
    ["Relics 9.2 M Dungeons"] = 2,
    ["Cast - Effect After Cast [P]"] = 2,
    ["Cast - Circular Swipe"] = 4,
    ["Aura - Debuff Alert"] = 12,
    ["Cast - Castbar is Timer [P]"] = 2,
    ["Cast - Ultra Important"] = 14,
    ["Add - Health Markers [P]"] = 2,
    ["Cast - Small Alert"] = 12,
    ["Aura - Invalidate Unit"] = 1,
    ["Add - Important [P]"] = 4,
    ["Unit - Main Target"] = 11,
    ["Aura - Blink Time Left"] = 13,
    ["Add - Tag Number [P]"] = 2,
    ["Unit Power"] = 1,
    ["Cast - Glowing [P]"] = 10,
    ["Cast - Important Target [P]"] = 2,
    ["Unit - Show Energy"] = 11,
    ["Blink by Time Left"] = 1,
    ["Cast - Shield Interrupt"] = 2,
    ["Cast - Alert + Timer [P]"] = 4,
    ["Explosion Affix M+"] = 14,
    ["Unit - Health Markers"] = 12,
    ["Aura is Shield [P]"] = 2,
    ["Add - Warning [P]"] = 5,
    ["Add - Explode on Die [P]"] = 1,
    ["Aura While Casting [P]"] = 1,
    ["Cast - Big Alert"] = 14,
    ["Countdown"] = 11,
    ["Color Change"] = 1,
    ["Cast - On Going Cast [P]"] = 2,
    ["Spiteful Affix"] = 3,
    ["Auto Set Skull"] = 11,
    ["Cast - Quick Flash"] = 2,
    ["Add - Non Elite Trash [P]"] = 4,
    ["Cast - Tank Interrupt"] = 12,
    ["Aura Border Color"] = 1,
    ["Cast - Stop Casting"] = 4,
    ["Fixate by Unit Buff [P]"] = 2,
    ["Cast - Frontal Cone"] = 15,
    ["Fixate"] = 11,
    ["Unit - Important"] = 11,
    ["Aura - Buff Alert"] = 15,
    ["Cast - Very Important"] = 15,
    ["Fixate On You"] = 11,
  },
  ["cast_statusbar_color_channeling"] = {
    0.37647062540054, -- [1]
    nil, -- [2]
    0.48235297203064, -- [3]
    0.96000000089407, -- [4]
  },
  ["plater_resources_anchor"] = {
    ["y"] = 40,
    ["x"] = 0,
    ["side"] = 8,
  },
  ["castbar_target_font"] = "Cronix-Bold",
  ["aura_cooldown_show_swipe"] = false,
  ["aura_alpha"] = 0.84999996423721,
  ["dps"] = {
    ["colors"] = {
      ["solo"] = {
        0, -- [1]
        0.71372550725937, -- [2]
      },
      ["notontank"] = {
        0.69019609689713, -- [1]
        0.6235294342041, -- [2]
      },
      ["aggro"] = {
        0.61568629741669, -- [1]
        0.18823531270027, -- [2]
        0.21176472306252, -- [3]
      },
      ["noaggro"] = {
        0, -- [1]
        0.71372550725937, -- [2]
      },
      ["pulling"] = {
        nil, -- [1]
        0.56078433990479, -- [2]
        0.55686277151108, -- [3]
      },
    },
  },
  ["aura_cooldown_edge_texture"] = "Interface\\GLUES\\loadingOld",
  ["aura_stack_font"] = "Cronix-Bold",
  ["show_healthbars_on_not_attackable"] = true,
  ["cast_statusbar_bgcolor"] = {
    0, -- [1]
    0, -- [2]
    0, -- [3]
    0.7049064040184, -- [4]
  },
  ["extra_icon_show_purge_border"] = {
    nil, -- [1]
    0.71372550725937, -- [2]
  },
  ["cast_statusbar_spark_width"] = 25,
}

function private:PlaterImport()
  PlaterDB["profiles"][private.Profilename] = PlaterDump
  
  local name = UnitName("PLAYER")
  local realm = GetRealmName()
  --if we overwrite the PlaterDB to add our profiles it will forget which profile to load
  --set the profile key manually so the correct profile is selected after a reload
  PlaterDB["profileKeys"][name.." - "..realm] = private.Profilename
  
  PluginInstallStepComplete.message = "Plater Profile Imported"
  PluginInstallStepComplete:Show()
end