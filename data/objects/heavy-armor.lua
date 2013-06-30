newEntity{ 
	define_as = "BASE_HEAVY", 
	slot = "BODY", 
	type = "armor", 
	subtype="heavy", 
	display = "[", 
	color=colors.DARK_GREY, 
	rarity = 5,
	encumber = 0,
	egos = "/data/objects/egos/heavy-armor.lua",
	egos_chance = 20,
	name = "a generic armor",
} 	

newEntity{ 
	base = "BASE_HEAVY", 
	name = "special response vest", 
	level_range = {1, 10}, 
	cost = 1, 
	wielder = {
		defense = 3,
		prof_defense = 7,
	}, 
} 