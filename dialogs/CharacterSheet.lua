require "engine.class"

local Dialog = require "engine.ui.Dialog"
local Talents = require "engine.interface.ActorTalents"
local SurfaceZone = require "engine.ui.SurfaceZone"
local Stats = require "engine.interface.ActorStats"
local Textzone = require "engine.ui.Textzone"

module(..., package.seeall, class.inherit(Dialog))

function _M:init(actor)
	self.actor = actor
    
	self.font = core.display.newFont("/data/font/VeraMono.ttf", 12)
	Dialog.init(self, "Character Sheet: "..self.actor.name, math.max(game.w * 0.7, 950), 500, nil, nil, font)
    
	self.c_desc = SurfaceZone.new{width=self.iw, height=self.ih,alpha=0}

	self:loadUI{
		{left=0, top=0, ui=self.c_desc},
	}
    
    	self:setupUI()
    
    	self:drawDialog()
    
	self.key:addBind("EXIT", function() cs_player_dup = game.player:clone() game:unregisterDialog(self) end)
end

function _M:drawDialog()
    	local player = self.actor
    	local s = self.c_desc.s

    	s:erase(0,0,0,0)

    	local h = 0
    	local w = 0

    	h = 0
    	w = 0
    	s:drawStringBlended(self.font, "Name : "..(player.name or "Unnamed"), w, h, 255, 255, 255, true) h = h + self.font_h
    	s:drawStringBlended(self.font, "Species : "..(player.descriptor.species or player.type:capitalize()), w, h, 255, 255, 255, true) h = h + self.font_h
	s:drawStringBlended(self.font, game.zone.name..": ".. game.level.level, w, h, 255, 255, 255, true) h = h + self.font_h     
   
    	h = h + self.font_h -- Adds an empty row
    
    	h = 0
    	w = self.w * 0.25 
    	-- start on second column
        
    	s:drawStringBlended(self.font, "STR : "..(player:getStr()), w, h, 255, 255, 255, true) h = h + self.font_h
    	s:drawStringBlended(self.font, "DEX : "..(player:getDex()), w, h, 255, 255, 255, true) h = h + self.font_h
	s:drawStringBlended(self.font, "Int : "..(player:getInt()), w, h, 255, 255, 255, true) h = h + self.font_h
    
	h = h + self.font_h

	h = 0
    	w = self.w * 0.25 

	s:drawStringBlended(self.font, "Attack : "..(player.atk), w, h, 255, 255, 255, true) h = h + self.font_h
    	s:drawStringBlended(self.font, "Defense : "..(player.defense), w, h, 255, 255, 255, true) h = h + self.font_h
	s:drawStringBlended(self.font, "Melee bonus : "..(player.melee_bonus), w, h, 255, 255, 255, true) h = h + self.font_h

    	self.c_desc:generate()
    	self.changed = false
end