require "engine.class"
local DamageType = require "engine.DamageType"
local Map = require "engine.Map"
local Target = require "engine.Target"
local Talents = require "engine.interface.ActorTalents"

--- Interface to add ToME combat system
module(..., package.seeall, class.make)

--- Checks what to do with the target
-- Talk ? attack ? displace ?
function _M:bumpInto(target)
	local reaction = self:reactionToward(target)
	if reaction < 0 then
		return self:meleeTarget(self:meleeAttack(target), target:getDefense(),target)
	elseif reaction >= 0 then
		if self.move_others then
			-- Displace
			game.level.map:remove(self.x, self.y, Map.ACTOR)
			game.level.map:remove(target.x, target.y, Map.ACTOR)
			game.level.map(self.x, self.y, Map.ACTOR, target)
			game.level.map(target.x, target.y, Map.ACTOR, self)
			self.x, self.y, target.x, target.y = target.x, target.y, self.x, self.y
		end
	end
end

--- Makes the death happen!
function _M:meleeTarget(atk, def, target)
	local srcname = game.level.map.seens(self.x, self.y) and self.name:capitalize() or "Something"

	if target:knowTalent(T_DEFENSIVE_MARTIAL_ARTS) then def = def + 1 end

	local dam = self:strMod() + self.melee_bonus
	local hit = self:combatRoll(atk, def)
	
	if hit == 1 then
		dam = dam + self:meleeRoll()
	elseif hit == 2 then
		game.logSeen(self, "%s preforms a critical hit!", srcname)
		dam = dam + self:meleeRoll() + self:meleeRoll()
	else
		game.logSeen(self, "%s misses %s.", srcname, target.name)
	end

	if hit then
		DamageType:get(DamageType.PHYSICAL).projector(self, target.x, target.y, DamageType.PHYSICAL, math.max(1, dam))
	end

	-- We use up our own energy
	self:useEnergy(game.energy_to_act)
end

function _M:combatRoll(atk, def)
	local roll = rng.dice(1, 20)
	local crit = rng.dice(1, 20)

	local hit = nil

	-- Checks the combat roll
	if roll == 1 then
		return false
	elseif roll == 20 then
		hit = 1
		if (crit + atk >= def) then
			 hit = 2
		end
	elseif (roll + atk >= def) then hit = 1
	else
		return false
	end

	return hit
end

function _M:meleeAttack(target)
	local atk = self:strMod() + (target.size - self.size) * 2 + self.atk
	
	if self:knowTalent(self.T_BRAWL) and not self:getInven("MAINHAND")[1] then atk = atk + 1 end
	if self:knowTalent(self.T_IMPROVED_BRAWL) and not self:getInven("MAINHAND")[1] then atk = atk + 1 end
	
	return atk
end

function _M:getDefense()
	local def = self.defense + self:dexMod()

	if self:getInven("BODY") then
		local armor = self:getInven("BODY")[1]
		if armor and self:hasProficiency(armor.subtype) then
			def = def + self.prof_defense
		end
	end
	
	return self.defense + self:dexMod()
end

function _M:meleeRoll()
	local weapon = self:hasMeleeWeapon()
	local melee = {}	

	if weapon then
		melee = weapon.melee
	else	
		melee = self.melee		
	end

	return rng.dice(melee.num, melee.sides) + (melee.bonus or 0)
end

function _M:hasMeleeWeapon()
	if not self:getInven("MAINHAND") then return end
	local weapon = self:getInven("MAINHAND")[1]
	if not weapon or not weapon.melee then
		return nil
	end
	return weapon
end

-- Ranged Attack functions
function _M:rangedTarget(target, talent, tg)
	local weapon = self:hasRangedWeapon()

	if not weapon then
		game.logPlayer(self, "You need to wield a gun to shoot.")
		return nil
	end

	if weapon.ammo and not self:hasAmmo(weapon.ammo) then
		game.logPlayer(self, "You need "..weapon.ammo.." to shoot.")
		return nil
	end

	local tg = tg or {type="bolt"}
	tg.range = tg.range or weapon.ranged.range
	tg.radius = weapon.ranged.radius or 0
	tg.talent = tg.talent or talent
	tg.atk = tg.atk or 0
	tg.bonus = tg.bonus or 0

	local x, y, target = self:getTarget(tg)
	if not x or not y or not target then return nil end

	local srcname = game.level.map.seens(self.x, self.y) and self.name:capitalize() or "Something"

	local dam = self:dexMod()
	local hit = self:combatRoll(self:rangedAttack(target), target:getDefense())
	
	if hit == 1 then
		dam = dam + self:rangedRoll(tg.bonus)
	elseif hit == 2 then
		game.logSeen(self, "%s preforms a critical hit!", srcname)
		dam = dam + self:rangedRoll(tg.bonus) + self:rangedRoll(tg.bonus)
	else
		game.logSeen(self, "%s misses %s.", srcname, target.name)
	end

	if hit then
		self:project(tg, target.x, target.y, DamageType.PHYSICAL, math.max(1, dam), {type="gun"})
	end
	
	if weapon.ammo then
		local ammo = self:hasAmmo()
		-- Can add multiple bullet effects later
		ammo.remaining = ammo.remaining - 1
	end
		
	self:useEnergy(game.energy_to_act)
end

function _M:rangedAttack(target)
	local atk = self:dexMod() + (target.size - self.size) * 2
	
	local weapon = self:hasRangedWeapon()
	if weapon.subtype and not self:hasProficiency(weapon.subtype) then
		atk = atk - 4
	end

	if weapon.subtype and self:hasFocus(weapon.subtype) then
		atk = atk + 1
	end

	return atk
end

-- Checks weapon/armor training
_M.proficiencies = {
	handgun =  Talents.T_HANDGUN_PROFICIENCY,
	longarm =  Talents.T_LONGARM_PROFICIENCY,
	light =    Talents.T_LIGHT_PROFICIENCY,
	medium =   Talents.T_MEDIUM_PROFICIENCY,
	heavy =    Talents.T_HEAVY_PROFICIENCY,
}

function _M:hasProficiency(type)
	if self:knowTalent(proficiencies[type]) then return true
	else return false end
end

_M.focuses = {
	handgun =   Talents.T_HANDGUN_FOCUS,
	longarm =   Talents.T_LONGARM_FOCUS,
}

function _M:hasFocus(type)
	if self:knowTalent(focuses[type]) then return true
	else return false end
end

_M.specializations = {
	handgun =   Talents.T_HANDGUN_SPECIALIZATION,
	longarm =   Talents.T_LONGARM_SPECIALIZATION,
}

function _M:hasSpecialization(type)
	if self:knowTalent(specializations[type]) then return true
	else return false end
end

function _M:hasRangedWeapon(type)
	if not self:getInven("MAINHAND") then 
		if self.ranged then return self
		else return nil end
	end

	local weapon = self:getInven("MAINHAND")[1]
	if not weapon or not weapon.ranged then
		if self.ranged then
			return self
		else
			return nil
		end
	end
	return weapon
end

function _M:rangedRoll(mod)
	local weapon = self:hasRangedWeapon()
	local ranged = {}	
	ranged = weapon.ranged

	local dam = rng.dice(ranged.num, ranged.sides) + (ranged.bonus or 0)

	dam = dam + (mod or 0)
	
	if weapon.subtype and self:hasSpecialization(weapon.subtype) then dam = dam + 2 end
	
	return dam
end

function _M:hasAmmo(type)
	if not self:getInven("CLIP") then return nil end

	local ammo = self:getInven("CLIP")[1]
	if not ammo then
		return nil
	end
	
	
	if (type and not (type == ammo.subtype)) or not (ammo.remaining > 0) then
		return nil
	end
	
	return ammo
end

-- Saves
function _M:saveRoll(num, saves)
	local roll = rng.dice(1, 20)

	if roll == 1 then return false end
	if roll == 20 then return true end

	if roll + saves > num then return true end

end

function _M:strSave()
	local save = self.saves.physical + self:strMod()

	return saves
end

function _M:dexSave()
	local save = self.saves.reflex + self:dexMod()

	return saves
end

function _M:conSave()
	local save = self.saves.fortitude + self:conMod()

	return saves
end

function _M:intSave()
	local saves = self.saves.mental + self:intMod()

	return saves
end
