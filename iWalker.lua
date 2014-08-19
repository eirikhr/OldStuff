--[[
      i Walker
                by Icy & Eirik
                Based on your mothers cunt
               
        Features:
                - Orb Walker: Orb walks around the target champion (works with every champion)
                - Orb Walker - Auto Attack (VIP only): Orb walks around the closest thing unless there is a champion in range
                - Supports: Bilgewater Cutlass, Hextech Gunblade and Blade of the Ruined King
                - Auto attack reset detection
                - Prevents the cancellation of Katarina and Nunu ults
                - Marks the target
                - Press shift to configure
               
        I recommend using it any champion
--]]
 
------ Configuration -------
local OrbWalkerKey = 32
local OrbWalkerKeyAA = GetKey("Y")
 
---------------------
local SOWConfig, ts, MyTrueRange
local HitBoxSize = 65
local lastAttack = GetTickCount()
local walkDistance = 300
local lastWindUpTime = 0
local lastAttackCD = 0
 
--Channeling related
local lastAnimation = ""
local lastChanneling = 0
--
function OnLoad()
        MyTrueRange = myHero.range + HitBoxSize
        SOWConfig = scriptConfig("Simple Orb Walker 1.0", "simpleOrbWalker")
    SOWConfig:addParam("OrbWalker", "Orb Walker", SCRIPT_PARAM_ONKEYDOWN, false, OrbWalkerKey)
    if VIP_USER then SOWConfig:addParam("OrbWalkerAA", "Orb Walker - Auto Attack", SCRIPT_PARAM_ONKEYDOWN, false, OrbWalkerKeyAA) end
    SOWConfig:addParam("attackFocused", "Kite focused targets", SCRIPT_PARAM_ONOFF, false)
    SOWConfig:addParam("drawCircles", "Display circles", SCRIPT_PARAM_ONOFF, true)
    ts = TargetSelector(TARGET_LESS_CAST_PRIORITY, MyTrueRange, DAMAGE_PHYSICAL, false)
        ts.name = "OrbWalker"
    SOWConfig:addTS(ts)
    PrintChat(" >> iWalker 1.0 loaded!")
end
 
function OnProcessSpell(object, spell)
    if myHero.dead then return end
        local spellIsAA = (spell.name:lower():find("attack") or isSpellAttack(spell.name)) and not isNotAttack(spell.name)
    if object.isMe then
                if spellIsAA then
            lastAttack = GetTickCount() - GetLatency()/2
                        lastWindUpTime = spell.windUpTime*1000
                        lastAttackCD = spell.animationTime*1000
        elseif refreshAttack(spell.name) then
            lastAttack = GetTickCount() - GetLatency()/2 - lastAttackCD
        end
    end
end
 
function OnTick()
        MyTrueRange = myHero.range + HitBoxSize
        ts.range = MyTrueRange
        ts.targetSelected = SOWConfig.attackFocused
        ts:update()
        if myHero.dead or myHeroisChanneling() then return end
    if SOWConfig.OrbWalker or SOWConfig.OrbWalkerAA then
        if (SOWConfig.OrbWalker or SOWConfig.OrbWalkerAA) and ts.target ~= nil and GetDistance(ts.target) - HitBoxSize < MyTrueRange then
            if GetDistance(ts.target) <= 500 then
                                if GetInventoryItemIsCastable(3153) then
                                        CastItem(3153, ts.target)
                                elseif GetInventoryItemIsCastable(3144) then
                                        CastItem(3144, ts.target)
                                elseif GetInventoryItemIsCastable(3146) then
                                        CastItem(3146, ts.target)
                                end
                        end
                        if timeToShoot() then
                                myHero:Attack(ts.target)
                        elseif heroCanMove() then
                                moveToCursor()
                        end
                elseif SOWConfig.OrbWalkerAA then
                        if timeToShoot() then
                                local moveToPos = myHero + (Vector(mousePos) - myHero):normalized()*walkDistance
                                Packet("S_MOVE", {type = 7, x = moveToPos.x, y = moveToPos.z}):send()
                        elseif heroCanMove() then
                                moveToCursor()
                        end
        elseif heroCanMove() then
                        moveToCursor()
        end
    end
end
function heroCanMove()
    return (GetTickCount() + GetLatency()/2 > lastAttack + lastWindUpTime + 20)
end
function timeToShoot()
    return (GetTickCount() + GetLatency()/2 > lastAttack + lastAttackCD)
end
function moveToCursor()
        if GetDistance(mousePos) > 50 or lastAnimation == "Idle1" then
                local moveToPos = myHero + (Vector(mousePos) - myHero):normalized()*walkDistance
                myHero:MoveTo(moveToPos.x, moveToPos.z)
        end
end
function OnDraw()
    if not myHero.dead and SOWConfig.drawCircles then
                DrawCircle(myHero.x, myHero.y, myHero.z, MyTrueRange, 0x19A712)
        if ts.target ~= nil then
            for j=0, 5 do DrawCircle(ts.target.x, ts.target.y, ts.target.z, 50 + j*1.5, 0x00FF00) end
        end
    end
end
--Channeling related
function OnSendPacket(p)
        local packet = Packet(p)
        if packet:get('name') == 'S_CAST' and packet:get('sourceNetworkId') == myHero.networkID then
                local spellId = packet:get('spellId')
                if (myHero.charName == "Katarina" and spellId == _R) or (myHero.charName == "Nunu" and spellId == _R) then
                        lastChanneling = GetTickCount()
                end
        end
end
function OnAnimation(unit,animationName)
        if unit.isMe and lastAnimation ~= animationName then lastAnimation = animationName end
end
function myHeroisChanneling()
        return (
                (GetTickCount() <= lastChanneling + GetLatency() + 50)
                or (myHero.charName == "Katarina" and lastAnimation == "Spell4")
                or (myHero.charName == "Nunu" and (lastAnimation == "Spell4" or lastAnimation == "Spell4_Loop"))
    )
end
--
function refreshAttack(spellName)
    return (
                --Blitzcrank
                spellName == "PowerFist"
                --Darius
                or spellName == "DariusNoxianTacticsONH"
                --Nidalee
                or spellName == "Takedown"
                --Sivir
                or spellName == "Ricochet"
                --Teemo
                or spellName == "BlindingDart"
                --Vayne
                or spellName == "VayneTumble"
                --Jax
                or spellName == "JaxEmpowerTwo"
                --Mordekaiser
                or spellName == "MordekaiserMaceOfSpades"
                --Nasus
                or spellName == "SiphoningStrikeNew"
                --Rengar
                or spellName == "RengarQ"
                --Wukong
                or spellName == "MonkeyKingDoubleAttack"
                --Yorick
                or spellName == "YorickSpectral"
                --Vi
                or spellName == "ViE"
                --Garen
                or spellName == "GarenSlash3"
                --Hecarim
                or spellName == "HecarimRamp"
                --XinZhao
                or spellName == "XenZhaoComboTarget"
                --Leona
                or spellName == "LeonaShieldOfDaybreak"
                --Shyvana
                or spellName == "ShyvanaDoubleAttack"
                or spellName == "shyvanadoubleattackdragon"
                --Talon
                or spellName == "TalonNoxianDiplomacy"
                --Trundle
                or spellName == "TrundleTrollSmash"
                --Volibear
                or spellName == "VolibearQ"
                --Poppy
                or spellName == "PoppyDevastatingBlow"
    )
end
function isSpellAttack(spellName)
        return (
                --Ashe
                spellName == "frostarrow"
                --Caitlyn
                or spellName == "CaitlynHeadshotMissile"
                --Quinn
                or spellName == "QuinnWEnhanced"
                --Trundle
                or spellName == "TrundleQ"
                --XinZhao
                or spellName == "XenZhaoThrust"
                or spellName == "XenZhaoThrust2"
                or spellName == "XenZhaoThrust3"
                --Garen
                or spellName == "GarenSlash2"
                --Renekton
                or spellName == "RenektonExecute"
                or spellName == "RenektonSuperExecute"
    )
end
function isNotAttack(spellName)
        return (
                --Shyvana
                spellName == "shyvanadoubleattackdragon"
                or spellName == "ShyvanaDoubleAttack"
                --MonkeyKing
                or spellName == "MonkeyKingDoubleAttack"
                --JarvanIV
                --or spellName == "JarvanIVCataclysmAttack"
                --or spellName == "jarvanivcataclysmattack"
    )
end
