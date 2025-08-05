local addon, private = ...


-- the following convention is applied
--[[ save private.Addons[addonname] = {
name = addonName
import = importLink this needs to be a function
importText = importText Text that will be on the button
importTwink = Twinkinstallation Process 
}
]]
local addonName = "OmniCD"
local importText = "Import"
local importString =
"DA16UTUnm4xL9aSZbsuI6YpxVUcCwAXjPyx(HbCtCsmQJDGTZPxE6hfPCAAxhgW(rauOiP(i5hjDHUyrX8RRAR6lBshx31ooKommwoEy4SYEwAt5MI53E)IVDZSlfLkMFEFxB9ZKM1Vwvmthkiz1l7Atg0TE4pizFqv6uz7YTD)N(CmP6y1ZJh6R(NO5SRF7XFGeDQvKD3v2p(ssV9th2v2EOS5UUKRMXr8lfx58oTZA9wDemw0vS(lwBX8NPBuknDBuBre1Uq6gd55z4)BtjyrrtFjfbC80xwVIoZyzyB3tFN()IY(nvJ)wz)JfNvmFtF3t3V)PY(vP)10T8Xk(0WYYgkDR(QhFFG9oFsG0huG2GkdA9yWQEdKwFmG(aHDe92PByqEmp)71Rg3wmdG0ftUgsUUQT8Hgbll7AoSRDOyM7ue2u(s3bYiQox)kvvjI1NcuiduKYGO2gDyWeT0d(gqdkF0sjZqW4aapfOCA4QGX7Cr0OCrvudaPbMZ3BR3STH(nMEMnnDpD2H1Rx8YEHq1TEDv7q9pQieZQVVBOESwyVhJlBIeTAvD7gHnxoowUCBX8f3E33U8QefJ4NvJNiG8ljG0gsb9ZZoS7gQLqsrzUFs5VFZ1)kP9H1e5TQP5lcND6X(Z0JrEDZB9LjsYDuMTQNb88H9Kzx1xURI50rNNAaNPM6b5yCv1avn7lhR(LLJsOorF0FvhtaS)XlB3s4IQCpipYIUUMX69N8kSVCgtYCdeOKD6KogT2althnyYCQHWcA(sDqzcjzgqJkFsM3RflnaOvr(KdXaMofcwGFane9SeWhnkiDYQCEJCcrtuUvz8qghO3NEjTI4gjN6vohkUpy1GCNlezWsCEGcDwMh9SliVAz)RvbqePvP3pDYzJkjMIumzZ(WOf0QrT3XYO40b5iaJEb4MGCBcK2St0QjtvEj)5TaYpbAcSw2yGDGb9G2MalGHGtXjumgSwj1cuEwYgrsbwwWOeOzS6mSPE4yg2wuj6JrBoGJo2qqtvynNxOQPjRM3eJzWMnLSWQLiwPckj6aWhmjBD2GLpqjz9XiqCMZ6nyo64R0Hj0Ocs87mOtOioLokbo5ARpNMmzchLUIzzQOuRbYDrMfsYOcQGvIcjXjqhuzSsEKJtTfMceTptDaL8eGhDrMMaoJwEccVojhBDsQYAIP4nv50u9HDrWaoHChOwsXTeYmImWiSBQHLvpnAgf0KiRYvuPq4zAJlZPPrJHSHbTu(1u4HsHLy(sLaqmA8tbvyklaCqXJ5A7AR(l638QXrAsZ0ssEM8hxvYcp)ItgvtLxA1NNGivbcEZjl(OEtWy80orVjf30n(8O6JdrsmDGBwnuP2WHH3Y0AkguczopllXMaNCGCiK5M0edoFHAfcVJY5I5kSsjKilALzqolRj1)QYvEQ)vAMcKmVuCPxtQe0qGaFB0BDjlpDM6YUdTJv9ZL1poJIwWgTe9NCqeL1p8C0R66FOQSpnB9CXMKlpU9o6(85ZFCK8YTPVky(rZM2gF(fZtWjnfgLzJEFq6oqV2)(mXuQXyGChRcYJ8ojdOaiZMMQejozKzoVB94j74s30xtl6Lp06TTQZO1l172DOnDZmn8VUrEqsWF6QUlFMZzNU6B(Rm5TPA5iLGMyVYNq1U5428Fupu)qDtgwL90hTWUI)uvRk)PIf3URT(8lGYMMFw(gYF6(B(7)"

table.insert(private.Addons, {
    name = addonName,
    import = function ()
        if OmniCD then
            local profileType, profileKey, profileData = OmniCD[1].ProfileSharing:Decode(importString)
            if profileType then
                OmniCD[1].ProfileSharing:CopyProfile(profileType, profileKey, profileData)
            end
           
        end
    end,
    importText = importText,
    
    importTwink = function()
        if OmniCDDB then 
            OmniCDDB["profileKeys"][private.g.cName .. " - " .. private.g.cRealm] = "Cronix UI"
        end
    end
})
