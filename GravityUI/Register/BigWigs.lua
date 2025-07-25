local addon, private = ...

-- the following convention is applied
--[[ save private.Addons[addonname] = {
name = addonName
import = importLink this needs to be a function
importText = importText Text that will be on the button
importTwink = Twinkinstallation Process 
}
]]

local addonName = "BigWigs"
local importText = "Import"
local importString = "BW1:Lv1tVnoru8e5LfqlisAvZcsirbjQupWQTfwqQcuvDB2MS02eL4YUBp5XoVypAT9mmZ42goHI4ah4upZP9JqoWvKI4c3SI4tqfhrGu)aamp)3S76dw(nV)(797npx)x4ncbPK4b9zsQIYIKBmhc5(fIpABRE9tmQh086iMiKeuQWXSNLvVJ16ERglYdY(SaMqEUdpwWdGD6BC)79f1tFB6eeNDW24RpZyGNaGOStmsFB6oHuCGHZeiiGDXogP62YHjirEWoPspi9OTfWOm50iU9n51WqqPOrEYFSHGfRcOrGO3Pwh19K2thZIudPFhS5ceINY5GWLib7PJjJafne6BS192(Au5XSiMRVGfc(P9JhQD9esi4SVGfrVmnuOCsltxFIYF2iQKhqMGr51MHE0ll5jnM5jyxCk)cIyK0FASeOU62S9ZDdisPl2XSltbwDpDajG6f5SF7tSAp45HvvcVzKoL60OQq59xOGlvOVPn)hzOF4RGPapBjyWBHhEOUwoGkaxKdhQicL5rTFO1nOUhthP8TicpqTjVbEshG65R6P8bHCZuB2tY1(oGOD3oZMd10KLg1hbJv15RIhTpJfmIDr0jXHoApT5TWA8vtDIXm08EJhlb1tRpVOQZASxJITVKRDbZHDPASj1SQIZlVzyokc1nf2wXcvQFs9RrHLP4IEiMzEZtyk26djrY1haEXberAPCaijQyHU5xzpwkFCkdunnXB(kO9JoTpVzrZ6Hc4BJHi3j9VLES9bPLQjtmcezmy961ZzWkWBnHdd40lHGRRmhtEULOn9r1hPbRS5ZRmYM)ULgiyU7frdpabHUQm4RTSQukb1BNxRlJGKnYO2QebrEk)3mBgOGWBpYdSxu07xAGS5Ywn8ckp3mmCzM1z3)(F)V1RvRMrND)ND31g)I)Ef2SxSITprQ6RlrQBGgI5JZfLJLp19zAOlnYi6mAFUvNU7)15x)tvmKtC13BQNo4LlymffoJXcXfjF6lod3n6C90f4V0K6tQFvMfLWBPllf3Fw7Ll9HUKaW4khsgnl)Mf6pnjUptVEioAes7D29x79vAGxdvzHvRprxdPteI8Jst40IO8iTp)PcFo3Wa9QTErcrQhmg9cQeii0042MpEl(kU6eQqWvU0V1uEXE9K1tw)lR9hVXmD0k3Y8(jVtsJRGIGBFZ5uj1jamjIJOHu1VFv6olCpWGbDpSJ1vWL8SgYNKEVTitjBCtzuWbSyUTjUZ0EQ2H0RZ)WD4nknzaiXPsBtmg2cKbJf6DdydyOAsa4G3IpTRqMtLZZ(lvwQ3CwMuACvVTJxrc1HXo5UjTYRATyYgMJPbb(lktnILpGV6lbuS)(6jFOFsZ1Mx87e8S7YxT0ZJJduuEafe4)t2QkKhZox36k7(zZbTUACXDLpFfHXkEgR4ymxJVQ)ipt3BkKod5NFB1F(2tpTR(2aePsU1zjqc8x1(PBN898MLHVG8gJCxstYIsni0UdccDlyW5mQlmVDKxav6VZ67fo5)p"

table.insert(private.Addons, {
    name = addonName,
    import = function()
        return BigWigsAPI.RegisterProfile(private.g.name, importString, private.g.name)
    end,
    importText = importText,
    importTwink = function()
        local name = UnitName("PLAYER")
        local realm = GetRealmName()
        if BigWigs3DB then
            BigWigs3DB["profileKeys"][name .. " - " .. realm] = private.g.name
        end  
    end
})