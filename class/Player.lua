require "engine.class"
require "mod.class.Actor"
require "engine.interface.PlayerRest"
require "engine.interface.PlayerRun"
require "engine.interface.PlayerMouse"
require "engine.interface.PlayerHotkeys"
local Map = require "engine.Map"
local Dialog = require "engine.Dialog"
local ActorTalents = require "engine.interface.ActorTalents"
local DeathDialog = require "mod.dialogs.Death"
local Astar = require"engine.Astar"
local DirectPath = require"engine.DirectPath"

--- Defines the player
-- It is a normal actor, with some redefined methods to handle user interaction.<br/>
-- It is also able to run and rest and use hotkeys
module(..., package.seeall, class.inherit(
	mod.class.Actor,
	engine.interface.PlayerRest,
	engine.interface.PlayerRun,
	engine.interface.PlayerMouse,
	engine.interface.PlayerHotkeys
))

function _M:init(t, no_default)
	t.display=t.display or '@'
	t.color_r=t.color_r or 230
	t.color_g=t.color_g or 230
	t.color_b=t.color_b or 230

	t.player = true
	t.type = t.type or "humanoid"
	t.subtype = t.subtype or "player"
	t.faction = t.faction or "players"

	t.lite = t.lite or 0

	t.fixed_rating = true

	self.move_others = true
	
	mod.class.Actor.init(self, t, no_default)
	engine.interface.PlayerHotkeys.init(self, t)

	self.descriptor = {}
end

function _M:move(x, y, force)
	local moved = mod.class.Actor.move(self, x, y, force)
	if moved then
		game.level.map:moveViewSurround(self.x, self.y, 8, 8)
	end
	return moved
end

function _M:act()
	if not mod.class.Actor.act(self) then return end

	-- Clean log flasher
	game.flash:empty()

	-- Resting ? Running ? Otherwise pause
	if not self:restStep() and not self:runStep() and self.player then
		game.paused = true
	end
end

-- Precompute FOV form, for speed
local fovdist = {}
for i = 0, 30 * 30 do
	fovdist[i] = math.max((20 - math.sqrt(i)) / 14, 0.6)
end

function _M:playerFOV()
	-- Clean FOV before computing it
	game.level.map:cleanFOV()

	if not self:attr("blind") then
		-- Handle infravision which allow to see outside of lite radius but with LOS
		if self:attr("infravision") then
			local radius = self.infravision
			local rad2 = math.max(1, math.floor(radius / 4))
			self:computeFOV(radius, "block_sight", function(x, y, dx, dy, sqdist) if game.level.map(x, y, game.level.map.ACTOR) then game.level.map.seens(x, y, fovdist[sqdist]) end end, true, true, true)
			self:computeFOV(rad2, "block_sight", function(x, y, dx, dy, sqdist) game.level.map:applyLite(x, y, fovdist[sqdist]) end, true, true, true)
		end

		-- Compute both the normal and the lite FOV, using cache
		-- Do it last so it overrides others
		self:computeFOV(self.sight or 20, "block_sight", function(x, y, dx, dy, sqdist)
			game.level.map:apply(x, y, fovdist[sqdist])
		end, true, false, true)
		if self.lite <= 0 then game.level.map:applyLite(self.x, self.y)
		else self:computeFOV(self.lite, "block_sight", function(x, y, dx, dy, sqdist) game.level.map:applyLite(x, y) end, true, true, true) end

		-- For each entity, generate lite
		local uid, e = next(game.level.entities)
		while uid do
			if e ~= self and e.lite and e.lite > 0 and e.computeFOV then
				e:computeFOV(e.lite, "block_sight", function(x, y, dx, dy, sqdist) game.level.map:applyExtraLite(x, y, fovdist[sqdist]) end, true, true)
			end
			uid, e = next(game.level.entities, uid)
		end
	else
		self:computeFOV(self.sight or 10, "block_sight") -- Still compute FOV so NPCs may target us even while blinded
		-- Inner Sight; works even while blinded
		if self:attr("blind_sight") then
			self:computeFOV(self:attr("blind_sight"), "block_sight", function(x, y, dx, dy, sqdist) game.level.map:applyLite(x, y, 0.6) end, true, true, true)
		end	
	end
end


--- Called before taking a hit, overload mod.class.Actor:onTakeHit() to stop resting and running
function _M:onTakeHit(value, src)
	self:runStop("taken damage")
	self:restStop("taken damage")
	local ret = mod.class.Actor.onTakeHit(self, value, src)
	if self.life < self.max_life * 0.3 then
		local sx, sy = game.level.map:getTileToScreen(self.x, self.y)
		game.flyers:add(sx, sy, 30, (rng.range(0,2)-1) * 0.5, 2, "LOW HEALTH!", {255,0,0}, true)
	end
	return ret
end

function _M:die(src)
	if self.game_ender then
		engine.interface.ActorLife.die(self, src)
		game.paused = true
		self.energy.value = game.energy_to_act
		game:registerDialog(DeathDialog.new(self))
	else
		mod.class.Actor.die(self, src)
	end
end

function _M:setName(name)
	self.name = name
	game.save_name = name
end

--- Notify the player of available cooldowns
function _M:onTalentCooledDown(tid)
	local t = self:getTalentFromId(tid)

	local x, y = game.level.map:getTileToScreen(self.x, self.y)
	game.flyers:add(x, y, 30, -0.3, -3.5, ("%s available"):format(t.name:capitalize()), {0,255,00})
	game.log("#00ff00#Talent %s is ready to use.", t.name)
end

function _M:levelup()
	mod.class.Actor.levelup(self)

	local x, y = game.level.map:getTileToScreen(self.x, self.y)
	game.flyers:add(x, y, 80, 0.5, -2, "LEVEL UP!", {0,255,255})
	game.log("#00ffff#Welcome to level %d.", self.level)
end

function _M:playerLevelup(on_finish)
	game:registerDialog(require("mod.dialogs.LevelupStats").new(self, on_finish))
end

--- Tries to get a target from the user
function _M:getTarget(typ)
	return game:targetGetForPlayer(typ)
end

--- Sets the current target
function _M:setTarget(target)
	return game:targetSetForPlayer(target)
end

local function spotHostiles(self)
	local seen = false
	-- Check for visible monsters, only see LOS actors, so telepathy wont prevent resting
	core.fov.calc_circle(self.x, self.y, game.level.map.w, game.level.map.h, 20, function(_, x, y) return game.level.map:opaque(x, y) end, function(_, x, y)
		local actor = game.level.map(x, y, game.level.map.ACTOR)
		if actor and self:reactionToward(actor) < 0 and self:canSee(actor) and game.level.map.seens(x, y) then seen = true end
	end, nil)
	return seen
end

--- Can we continue resting ?
-- We can rest if no hostiles are in sight, and if we need life/mana/stamina (and their regen rates allows them to fully regen)
function _M:restCheck()
	if spotHostiles(self) then return false, "hostile spotted" end

	-- Check resources, make sure they CAN go up, otherwise we will never stop
	if self:getPower() < self:getMaxPower() and self.power_regen > 0 then return true end
	if self.life < self.max_life and self.life_regen> 0 then return true end

	return false, "all resources and life at maximum"
end

--- Can we continue running?
-- We can run if no hostiles are in sight, and if we no interesting terrains are next to us
function _M:runCheck()
	if spotHostiles(self) then return false, "hostile spotted" end

	-- Notice any noticeable terrain
	local noticed = false
	self:runScan(function(x, y)
		-- Only notice interesting terrains
		local grid = game.level.map(x, y, Map.TERRAIN)
		if grid and grid.notice then noticed = "interesting terrain" end
	end)
	if noticed then return false, noticed end

	self:playerFOV()

	return engine.interface.PlayerRun.runCheck(self)
end

--- Move with the mouse
-- We just feed our spotHostile to the interface mouseMove
function _M:mouseMove(tmx, tmy)
	return engine.interface.PlayerMouse.mouseMove(self, tmx, tmy, spotHostiles)
end

function _M:playerPickup() 
	-- If 2 or more objects, display a pickup dialog, otherwise just picks up 
	if game.level.map:getObject(self.x, self.y, 2) then 
		local d d = self:showPickupFloor("Pickup", nil, function(o, item) 
			self:pickupFloor(item, true) 
			self.changed = true 
			d:used() 
		end) 
	else 
		self:pickupFloor(1, true) 
		self:sortInven() 
		self:useEnergy() 
		self.changed = true 
	end 
end 

function _M:playerDrop() 
	local inven = self:getInven(self.INVEN_INVEN) 
	local d d = self:showInventory("Drop object", inven, nil, function(o, item) 
		self:dropFloor(inven, item, true, true) 
		self:sortInven(inven) 
		self:useEnergy() 
		self.changed = true return true 
	end) 
end

function _M:doDrop(inven, item, on_done, nb)
	if self.no_inventory_access then return end
	
	if nb == nil or nb >= self:getInven(inven)[item]:getNumber() then
		self:dropFloor(inven, item, true, true)
	else
		for i = 1, nb do self:dropFloor(inven, item, true) end
	end
	self:sortInven(inven)
	self:useEnergy()
	self.changed = true
	if on_done then on_done() end
end

function _M:doWear(inven, item, o) 
	self:removeObject(inven, item, true) 
	local ro = self:wearObject(o, true, true) 
	if ro then 
		if type(ro) == "table" then self:addObject(inven, ro) end 		elseif not ro then 
		self:addObject(inven, o) 
	end 
	self:sortInven() 
	self:useEnergy() 
	self.changed = true 
end

function _M:doTakeoff(inven, item, o) 
	if self:takeoffObject(inven, item) then 
		self:addObject(self.INVEN_INVEN, o) 
	end 
	self:sortInven() 
	self:useEnergy() 
	self.changed = true 
end

function _M:playerUseItem(object, item, inven)
	--if not game.zone or game.zone.world then game.logPlayer(self, "You cannot use items on the world map.") return end

	local use_fct = function(o, inven, item)
		if not o then return end
		local co = coroutine.create(function()
			self.changed = true

			local ret = o:use(self, nil, inven, item) or {}
			if not ret.used then return end
			if ret.destroy then
				if o.multicharge and o.multicharge > 1 then
					o.multicharge = o.multicharge - 1
				else
					local _, del = self:removeObject(self:getInven(inven), item)
					if del then
						game.log("You have no more %s.", o:getName{no_count=true, do_color=true})
					else
						game.log("You have %s.", o:getName{do_color=true})
					end
					self:sortInven(self:getInven(inven))
				end
			end
		end)
		local ok, ret = coroutine.resume(co)
		if not ok and ret then print(debug.traceback(co)) error(ret) end
		return true
	end

	if object and item then return use_fct(object, inven, item) end

	local titleupdator = self:getEncumberTitleUpdator("Use object")
	self:showEquipInven(titleupdator(),
		function(o)
			return o:canUseObject()
		end,
		use_fct
	)
end

-- Quest Events
function _M:on_quest_grant(quest)
	game.logPlayer(self, "#LIGHT_GREEN#Accepted quest '%s'! #WHITE#(Press CTRL+Q to see the quest log)", quest.name)
end

function _M:on_quest_status(quest, status, sub)
	if sub then
		game.logPlayer(self, "#LIGHT_GREEN#Quest '%s' status updated! #WHITE#(Press CTRL+Q to see the quest log)", quest.name)
	elseif status == engine.Quest.COMPLETED then
		game.logPlayer(self, "#LIGHT_GREEN#Quest '%s' completed! #WHITE#(Press CTRL+Q to see the quest log)", quest.name)
	elseif status == engine.Quest.DONE then
		game.logPlayer(self, "#LIGHT_GREEN#Quest '%s' is done! #WHITE#(Press CTRL+Q to see the quest log)", quest.name)
	elseif status == engine.Quest.FAILED then
		game.logPlayer(self, "#LIGHT_RED#Quest '%s' is failed! #WHITE#(Press CTRL+Q to see the quest log)", quest.name)
	end
end