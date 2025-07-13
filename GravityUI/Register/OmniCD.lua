local addon, private = ...


-- the following convention is applied
--[[ save private.Addons[addonname] = {
name = addonName
import = importLink this needs to be a function
importText = importText Text that will be on the button
}
]]
local addonName = "Details"
local importText = "import"
local importString =
"DAv6UnUnq4xL(a0DbVp(zD240aSvjiYb94hcGwM2wiYsguuBCYtFhEiBLSgOafggy4WHZX38XHQcxTQQ8oBN1zAdIE7j)OZoeKh8g)4WcJlSyXDvL3467AovvUgunTWd)k3235)5JST1SRQ8HNx997lUnz0fFm08UTQaRchVPUVlCG(Td)fO7tMcsMU699)N(0NsMhno)BbBpojS7s9nSV)1hBnVzDvlcgdLRZa5Bm7DMMnGmEYWNG1RmUDw)FyCVahOCNR)1Np(QXTjSQTV(fBuAO20cLd6RsEv5bt3OP9X(FYNVvTuQqemLJOCMKRyOQTFHXQkpvTKj1kUuPjuoxYM2jwrNr1)SzJFFvbHe2yY1KGRTDM1TPC5AHNKdpNXfCmtl4kQMbU5s4viPMPXmLIkie(SWFPmbGRFe0anJM3bOhW0Y6(2XdDdvfIjyyPIkfcnNIeAKgtiGV40KV23SBFl83h7lT9VUyC72vVDmX463U12n08dBS5aMFSFOX3KyhNdel0A3SPPBxITy8Et9(QYvp843VDzOXdeyRFMcWVGcWAsaEovmE4EGYLY5m3ky8t3F3VdwpUfOu222VKystb7VdbZ)r8TyQVkKcSGXKmm0abq(cWkqimSlGSCohluHDcGrb))9rduIJqcU0zoyJzHwiHRsfOPBtr0CJDa4noJ3(B1(eOoruXFfRdvI7LB72dia0ExN48R67B9nht3oIrj6lkrb9ZGhOCjbZcMtfunweKiybLIJsinHRcsyScrtsaXwPJNahOUrvXeokrZogReebpOJPKAs0EcbCtCtcrQObDkbqttHIkjO8Mmjk6nKIOq5iaGw0okwP5PegH1P4hG0yQRc8Z1rFariijykgnxFCA0CLmwCsw01CIugnetPPYhHuirityigvHtXhUfhXlgKD805yImkqrPmttqPiP0PcimviN1CcovNemxqIENZO5uKKRwTid2CaoYyhsM2mvyujJWXXmjG1GQibQRVZ(pW)sR3dK7PPLXbgHg(vVOoep9CAb4CI8JGvgLiigk37o3SHgCsaAjKmmn1M4yeN8b8xlzcsU6O4e88jeqRaOpAYzYdvb6KX4IqIi)aymjEYe7y(TK6(XoV1vMgDjOiy4SMbKnWLAEA0vz9(WZaLtt51ZM4Rfx)M21UCTS3T2ACbD3KcBkzcG(nFRmKoyTMXtDBPuPY34Ws0vRikLKiEq3giArvZQFsuZSobmebU8S4ZJwNnFmSJRbMVNE68Ye5cOOBoCySlStbM85rH5Iy2JnqFegTjXAmhgbiPZgSb3(iuQeM5jbCo(mKmXlN9w97r6zRT2di4e)8dpGpB1TNMa5NmD7o)aYpAgAw30MRgJdENmAx8RpyO83mu9WHUMB(gX02(RPpM4xE(()9d"

private.Addons[addonName] = {
    name = addonName,
    import = function ()
        if OmniCD.ProfileSharing.ImportProfile then
            OmniCD.ProfileSharing:ImportProfile(importString)
        end
    end,
    importText = importText
}

