load("/data/talents/ranged/handgun.lua")
load("/data/talents/ranged/longarm.lua")

newTalentType{ type = "ranged", name = "ranged", description = "Ranged weapon talents" }

newTalent{
	name = "Deadly Aim",
	type = {"ranged", 1},
	mode = "passive",
	points = 1,
	on_learn = function(self, t)
		self.ranged_bonus = self.ranged_bonus + 1
	end,
	on_unlearn = function(self, t)
		self.ranged_bonus = self.ranged_bonus - 1
	end,
	info = function(self, t)
		return [[Increase damage with ranged weapons by +1.]]
	end,
}

newTalent{
	name = "Far Shot",
	type = {"ranged", 1},
	points = 1,
	on_pre_use = function(self, t) 
		if not self:hasRangedWeapon() then 
			game.logPlayer(self, "You require a gun for this talent.") 
			return false
		 end 

		return true 
	end,
	action = function(self, t)
		local tg = {range = self:hasRangedWeapon().ranged.range + 2}
		self:rangedTarget(target, t, tg)
	end,
	info = function(self, t)
		return [[Shoot with ranged weapons, increasing range by +2.]]
	end,
}

newTalent{
	name = "Point Blank Shot",
	type = {"ranged", 1},
	points = 1,
	on_pre_use = function(self, t) 
		if not self:hasRangedWeapon() then 
			game.logPlayer(self, "You require a gun for this talent.") 
			return false
		 end 

		return true 
	end,
	action = function(self, t)
		local tg = {range = 2, atk = 1, bonus = 1}
		self:rangedTarget(target, t, tg)
	end,
	info = function(self, t)
		return [[Shoot with ranged weapons at range of 2 with +1 attack and +1 damage.]]
	end,
}

newTalent{
	name = "Sniper Shot",
	type = {"ranged", 1},
	points = 1,
	on_pre_use = function(self, t) 
		if not self:hasRangedWeapon() then 
			game.logPlayer(self, "You require a gun for this talent.") 
			return false
		 end 

		return true 
	end,
	action = function(self, t)
		local tg = {crit = 1}
		self:rangedTarget(target, t, tg)
		self:setEffect(self.EFF_DEFENSE, 1, {power = -5})
	end,
	info = function(self, t)
		return [[Increases critical hit threshold by +1, by reduces defense by -5 for one turn.]]
	end,
}