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
"DA1AVTTnu0)k7hW6aFD5JpUKM0fGo3GQuShFqam2Y2cvwYqsUjP)63H8sL420HbmeyeQljVpoNdVK1Y67QRExtFZySlnCU5X5tJntPXtZX5ttxehtFCX7QRUCCOV9X6Q7HPLpMXFvBh6NF9w22f3vx9HpD37Vz1v8IEXhtTFTPEL0N2E76H(0gg2o9NW23Tumk2VE)W)PpN5K52448tP1ECzW(2D77WV50h76gE4ItB3E3th5YCy72M(P2V0uFb7aabJrud5zhJTBW4monTF4HpIVVloURz(3JJFgBPA34WdF64dXXnPV6gw)5M8OP1XouIIFXr1vhI9NID3o8kF(u91oVqj1Kqtgh5nI6TVXyQRES(AJl4jNpO0e5mlZKtYNr6)ODZ8(6vkvAIfxRsUUPpEFhNl)OWRkHNmKLKMGL86GbU5LW7fUGjinEV2Qu0zH)LYSl(0Wjybeu7xbDaDu16HUth6NQxzxGHR9AN1giTWgebPsbFrA2x7Er(Lq4BHhBgZKr1XHP25wwD8StnjQDZM2(DSAjophxVVU6UpC77V66eXdbCZ8zgafddy1Qeu84QthUbso4k)ZAR0I)4nV73WQpTfsQMUU3WkPLG9xPGn)Ty5Qfo06SsRX4msqwaqFbeTcHeZcuKisA9Pzsf(k6)9wt0)rKGxpgp0KZIG1HJsRelNMY88MMjOrgJZn)66zwFVWgKwcM2rwHkGDAz2aL24NVQFpGeWT3Z0XDddDZThz(ih2SZTADYFALhCAAKmemgF2MmOP021E4BtEsPxO9zBkjjCjBoNK3PMCkjpYsKNsJ8EJkhajsWSfLlOfQ0iJW608iI0bEwHWtYSpCcynVvHXuSyTe7FVrQsPHuy9HC2IZwkzGT5ixopGdmk2fEfBsksjqAK1eesUIrrzk(ql5ykjPZMTHc1QkLafCCMdiXwYxPZu8IuSSxHJrqNrXvdPzamJrMCwcMZYMcEt2KseueJUETGteLY5nooaO3qih(G3XbNcMs5fS5nIkWqfEuxyuLeKSKJ5YSkHthcfunuqvuQIaxPiQ60oaMYSH0x2O140ujl4DPDfsrid56WQHGCXJsEvEJLZbGj6I(cydJNi)nsgprGceZIqNuqwQaXkyrusqKHmMj8cERK3JWMdHsWHqHJgHSOqHWBlsS08SJT5DA0GbYOnjHp48vRSzSWAsZL5e02JHmddk4SUrvgL07zeojnzNdyNvvsTTOGrRz(CrsTyk6abKvCIHRgkLcf0fkwi9LtbbvUOY9n6h6B(B8RQzEg90wUKmFNW)6vLtiEFZH)K(u5Yfh4mDoFCgbJRgbtDLMsjEvz5bGKuSGcshkx4Kuq5tKpJxgYWTkGQtlZon4m2YIY)dh8e8s8W3LEnWwruiyvKnuiDCi2l4A45MJRho1p3mwX9dTAbU)nyG6fUmqL(HR3NUPVA5I8WzxQhS)4gS)OwOxpmEFtCmz7soSCYKa9lFBvkDsDpjUNMZ5zzo5Kl9E(UksRvmHJUsLovNx)kvrwSWejXvO(v3OE21IPzgBXv48lME5nrRqr3E4WP(0mRKQV7c7VM1sDnRNr5UiM(MBXp7RRECbr(ySFh)ERx)0KlF7zpobIcC9OdhkWzEVtF2LJO5VsRD4EtNoDndMXT8gWV0o1EFBxPAIJ4Pq5qNF0Pruww9ho03E5BvXUUFMFd5p9PB(N"

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
