dofile("/mod/class/AsciiMap.lua")
local Map = require "engine.Map"

-- This file loads the game module, and loads data
local KeyBind = require "engine.KeyBind"
local DamageType = require "engine.DamageType"
local ActorStats = require "engine.interface.ActorStats"
local ActorResource = require "engine.interface.ActorResource"
local ActorTalents = require "engine.interface.ActorTalents"
local ActorAI = require "engine.interface.ActorAI"
local ActorLevel = require "engine.interface.ActorLevel"
local ActorTemporaryEffects = require "engine.interface.ActorTemporaryEffects"
local Birther = require "engine.Birther"
local UIBase = require "engine.ui.Base"
local ActorInventory = require "engine.interface.ActorInventory"
local Quest = require "engine.Quest"
local System = require "mod.class.System"
local Faction = require "engine.Faction"

UIBase.ui = "simple"

profile.mod.allow_build = profile.mod.allow_build or {}

-- Additional entities resolvers
dofile("/mod/resolvers.lua")

-- Useful keybinds
KeyBind:load("move,hotkeys,inventory,actions,interface,debug")

-- Damage types
DamageType:loadDefinition("/data/damage_types.lua")

-- Talents
ActorTalents:loadDefinition("/data/talents/talents.lua")

-- Timed Effects
ActorTemporaryEffects:loadDefinition("/data/timed_effects.lua")

-- Actor resources
ActorResource:defineResource("Power", "power", nil, "power_regen", "Power represent your ability to use special talents.")
ActorResource:defineResource("Stamina", "stamina", nil, "stamina_regen", "Stamina represents your physical fatigue. Using abilities and being hit in combat reduces it.")

-- Actor stats
ActorStats:defineStat("Strength",	"str", 10, 1, 20, "Strength defines your character's ability to apply physical force. It increases your melee damage, damage with heavy weapons, your chance to resist physical effects, and carrying capacity.")
ActorStats:defineStat("Dexterity",	"dex", 10, 1, 20, "Dexterity defines your character's ability to be agile and alert. It increases your chance to hit, your ability to avoid attacks and your damage with light weapons.")
ActorStats:defineStat("Intelligence",	"int", 10, 1, 20, "Intelligence defines your character's metal abilities. It affects you skill in using devices.")
ActorStats:defineStat("Constitution",	"con", 10, 1, 20, "Constitution defines your character's ability to withstand and resist damage. It increases your maximum life and physical resistance.")

ActorInventory:defineInventory("MAINHAND", "Mainhand", true, "normal")
ActorInventory:defineInventory("OFFHAND", "Offhand", true, "normal")
ActorInventory:defineInventory("BODY", "Body", true, "normal")
ActorInventory:defineInventory("HEAD", "Head", true, "normal")
ActorInventory:defineInventory("CLIP", "Clip", true, "normal")
ActorInventory:defineInventory("COMBAT_SOFTWARE", "Combat Software", true, "normal")

ActorInventory:defineInventory("EYES", "Eyes", true, "implant")

-- Actor AIs
ActorAI:loadDefinition("/engine/ai/")
ActorAI:loadDefinition("/mod/ai/")

-- Birther descriptor
Birther:loadDefinition("/data/birth/descriptors.lua")

-- Systems
System:loadDefinition("/data/systems/solar-system.lua")

-- Factions
Faction:add{ name="Neutral", reaction = {}, }

return {require "mod.class.Game" }
