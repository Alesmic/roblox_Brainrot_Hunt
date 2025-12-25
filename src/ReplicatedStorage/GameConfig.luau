local GameConfig = {}

-- ==========================================
-- 1. Rarity Color Configuration
-- ==========================================
GameConfig.RarityColors = {
	["Common"] = Color3.fromRGB(150, 150, 150),   -- Gray (Common)
	["Rare"] = Color3.fromRGB(0, 170, 255),       -- Blue (Rare)
	["Epic"] = Color3.fromRGB(170, 0, 255),       -- Purple (Epic)
	["Legendary"] = Color3.fromRGB(255, 170, 0)   -- Orange (Legendary)
}

-- ==========================================
-- 2. Base Settings & Leveling Curve
-- ==========================================
GameConfig.DefaultPlayer = {
	Level = 1, Gold = 0, Experience = 0, MaxHealth = 100,
	WalkSpeed = 16, SprintSpeed = 24, JumpPower = 50
}

GameConfig.Leveling = {
	-- [Leveling Curve] Experience Requirement Formula
	GetXpRequired = function(level)
		if level >= 1 and level <= 10 then return 1000
		elseif level >= 11 and level <= 20 then return 1200
		elseif level >= 21 and level <= 30 then return 1500
		elseif level >= 31 and level <= 40 then return 1900
		elseif level >= 41 and level <= 50 then return 2400
		elseif level >= 51 and level <= 60 then return 3000
		elseif level >= 61 and level <= 70 then return 3800
		elseif level >= 71 and level <= 80 then return 4800
		elseif level >= 81 and level <= 90 then return 6000
		elseif level >= 91 and level <= 98 then return 8000
		else return 10000 end -- Levels 99-100
	end,
	-- Level Up Rewards: +10 Health, +3 Damage per level
	RewardsPerLevel = { HealthBonus = 10, DamageBonus = 3 }
}

-- ==========================================
-- 3. Mob Attribute Configuration (Mobs & Bosses)
-- ⚠️ IMPORTANT: The Mob Model.Name in Workspace must match the Key here exactly!
-- ==========================================
GameConfig.Mobs = {
	-- 🏙️ Urban Area (Japan)
	["Samurai"] = { 
		Name = "Samurai", 
		MaxHealth = 50,    -- 50 HP
		Damage = 10,       -- 10 Damage
		Exp = 200,          -- 50 EXP
		AttackRange = 5,
		AttackSpeed = 1.5,
		WalkSpeed = 12,
		Drops = {
			{ ItemName = "Medpack", Chance = 0.05 } -- 15% drop chance for Medpack
		}
	},
	-- Urban Boss (Unlocked at Lvl 20)
	["Saharan Master"] = {
		Name = "Saharan Master",
		MaxHealth = 1000,   
		Damage = 40,       
		Exp = 500,         
		UnlockLevel = 20,  -- Unlocks Boss Fight at Level 20
		AttackRange = 8,
		AttackSpeed = 1.2,
		WalkSpeed = 16,
		Drops = {
			{ ItemName = "ClassicSword", Chance = 0.1 }, -- 50% drop chance for Weapon
			{ ItemName = "Red Aura", Chance = 0.1 }      -- 10% drop chance for Aura
		}
	},
	["Ant(Forest Spirit)"] = {
		Name = "Ant(Forest Spirit)",
		MaxHealth = 150,   
		Damage = 20,       
		Exp = 300,         
		UnlockLevel = 20, 
		AttackRange = 8,
		AttackSpeed = 1.2,
		WalkSpeed = 16,
		Drops = {
			{ ItemName = "Medpack", Chance = 0.1 }
		}
	},

	-- 🌲 Forest Area
	-- Forest Boss (Unlocked at Lvl 50)
	["Forest Guardian"] = { 
		Name = "Forest Guardian", 
		MaxHealth = 750,   
		Damage = 40,
		Exp = 2000,
		UnlockLevel = 50,  -- Unlocks Boss Fight at Level 50
		AttackRange = 10,
		AttackSpeed = 1.0,
		WalkSpeed = 12,
		Drops = {
			{ ItemName = "Gold Statue", Chance = 0.2 }
		}
	},

	-- 🏜️ Desert Area
	["DesertMob"] = { 
		Name = "Desert Raider", -- Ensure model name is Desert Raider
		MaxHealth = 200,   -- 200 HP
		Damage = 30,       -- 30 Damage
		Exp = 1000,         -- 200 EXP
		AttackRange = 8,
		AttackSpeed = 1.0,
		WalkSpeed = 14,
		Drops = {
			{ ItemName = "Medpack", Chance = 0.5 }
		}
	},
	-- Desert Boss (Unlocked at Lvl 99)
	["DesertKing"] = { 
		Name = "DesertKing", 
		MaxHealth = 1000,  
		Damage = 90,
		Exp = 5000,
		UnlockLevel = 99,  -- Unlocks Boss Fight at Level 99
		AttackRange = 12,
		AttackSpeed = 0.8,
		WalkSpeed = 16,
		Drops = {
			{ ItemName = "Real Knife", Chance = 0.05 } -- 5% drop chance for Legendary Weapon
		}
	}
}GameConfig.Mobs = {
	-- 🏙️ Urban Area (Japan)
	["Samurai"] = { 
		Name = "Samurai", 
		MaxHealth = 50,    -- 50 HP
		Damage = 10,       -- 10 Damage
		Exp = 50,          -- 50 EXP
		AttackRange = 5,
		AttackSpeed = 1.5,
		WalkSpeed = 12,
		Drops = {
			{ ItemName = "Medpack", Chance = 0.15 } -- 15% drop chance for Medpack
		}
	},
	-- Urban Boss (Unlocked at Lvl 20)
	["Saharan Master"] = {
		Name = "Saharan Master",
		MaxHealth = 1000,   
		Damage = 40,       
		Exp = 500,         
		UnlockLevel = 20,  -- Unlocks Boss Fight at Level 20
		AttackRange = 8,
		AttackSpeed = 1.2,
		WalkSpeed = 16,
		Drops = {
			{ ItemName = "ClassicSword", Chance = 0.5 }, -- 50% drop chance for Weapon
			{ ItemName = "Red Aura", Chance = 0.1 }      -- 10% drop chance for Aura
		}
	},
	["Ant(Forest Spirit)"] = {
		Name = "Ant(Forest Spirit)",
		MaxHealth = 300,   
		Damage = 20,       
		Exp = 300,         
		UnlockLevel = 20,  -- Unlocks Boss Fight at Level 20
		AttackRange = 8,
		AttackSpeed = 1.2,
		WalkSpeed = 16,
		Drops = {
			{ ItemName = "ClassicSword", Chance = 0.5 }, -- 50% drop chance for Weapon
			{ ItemName = "Red Aura", Chance = 0.1 }      -- 10% drop chance for Aura
		}
	},

	-- 🌲 Forest Area
	-- Forest Boss (Unlocked at Lvl 50)
	["WolfBoss"] = { 
		Name = "AntBoss", 
		MaxHealth = 1000,   
		Damage = 40,
		Exp = 2000,
		UnlockLevel = 50,  -- Unlocks Boss Fight at Level 50
		AttackRange = 10,
		AttackSpeed = 1.0,
		WalkSpeed = 12,
		Drops = {
			{ ItemName = "Gold Statue", Chance = 0.2 }
		}
	},

	-- 🏜️ Desert Area
	["DesertMob"] = { 
		Name = "Desert Raider", -- Ensure model name is Desert Raider
		MaxHealth = 200,   -- 200 HP
		Damage = 30,       -- 30 Damage
		Exp = 200,         -- 200 EXP
		AttackRange = 8,
		AttackSpeed = 1.0,
		WalkSpeed = 14,
		Drops = {
			{ ItemName = "Medpack", Chance = 0.5 }
		}
	},
	-- Desert Boss (Unlocked at Lvl 99)
	["DesertKing"] = { 
		Name = "DesertKing", 
		MaxHealth = 1000,  
		Damage = 90,
		Exp = 5000,
		UnlockLevel = 99,  -- Unlocks Boss Fight at Level 99
		AttackRange = 12,
		AttackSpeed = 0.8,
		WalkSpeed = 16,
		Drops = {
			{ ItemName = "Real Knife", Chance = 0.05 } -- 5% drop chance for Legendary Weapon
		}
	}
}

-- ==========================================
-- 4. Quest Configuration
-- ==========================================
GameConfig.Quests = {
	-- Quest: Kill 10 Samurai
	["SamuraiSlayer"] = {
		Name = "Kill 10 Samurai",
		TargetMob = "Samurai", 
		TargetCount = 10,      
		ExpReward = 300,       -- Rewards 300 EXP
		GoldReward = 100,      
		TargetPosition = Vector3.new(-522.6, 21.8, 287.9) 
	},

	-- Quest: Defeat Samurai Boss
	["KillSamuraiBoss"] = {
		Name = "Defeat Samurai Boss",
		TargetMob = "Samurai Boss",
		TargetCount = 1,
		ExpReward = 500,       -- Rewards 500 EXP
		GoldReward = 500,
		TargetPosition = Vector3.new(-313, 38.4, 208.582)
	},

	-- Quest: Defeat Forest Boss
	["KillForestBoss"] = {
		Name = "Defeat Forest Boss",
		TargetMob = "Forest Guardian", 
		TargetCount = 1,
		ExpReward = 2000,      -- Rewards 2000 EXP
		GoldReward = 1000,
	},

	-- Quest: Defeat Desert Boss
	["KillDesertKing"] = {
		Name = "Defeat Desert Boss", 
		TargetMob = "Saharan Master", 
		TargetCount = 1,
		ExpReward = 5000,      -- Rewards 5000 EXP
		GoldReward = 5000,
	}
}

-- ==========================================
-- 5. Item Configuration (Weapons, Skins, Items)
-- ==========================================
GameConfig.Weapons = {
	["Bat"] = { 
		DisplayName = "Wooden Bat", Damage = 20, Cooldown = 0.5, 
		Category = "Weapons", Price = 0, CanSell = false,
		Rarity = "Common",
		ImageId = "rbxassetid://11265603711",
	},
	["ClassicSword"] = { 
		DisplayName = "Classic Sword", Damage = 35, Cooldown = 0.6, 
		Category = "Weapons", Price = 0, ProductId = 3481635197, 
		RobuxPrice = 1, CanSell = true, Rarity = "Rare",
		ImageId = "rbxasset://Textures/Sword128.png"
	},
	["Machete"] = { 
		DisplayName = "Machete", Damage = 200, Cooldown = 0.1, 
		Category = "Weapons", Price = 100, 
		CanSell = true, Rarity = "Legendary",
		ImageId = "http://www.roblox.com/asset/?id=7722474825"
	},
	["Real Knife"] = { 
		DisplayName = "Real Knife", Damage = 999, Cooldown = 0.3, 
		Category = "Weapons", Price = 0, ProductId = 87654321, 
		RobuxPrice = 99, CanSell = false, Rarity = "Legendary",
		ImageId = "rbxassetid://732391130"
	}
}

GameConfig.Skin = {
	["Red Aura"] = {
		DisplayName = "Red Aura", Type = "Skin",
		Price = 0, Category = "Skins", CanSell = false,
		Rarity = "Rare",
		ImageId = "rbxassetid://732391130"
	}
}

GameConfig.Items = {
	["Medpack"] = {
		DisplayName = "Medpack", Type = "Consumable", 
		Price = 20, Category = "Consumables", CanSell = true, HideInShop = true,
		Rarity = "Common",
		ImageId = "rbxassetid://108387389354561"
	}
}

-- ==========================================
-- 6. PvP Configuration
-- ==========================================
GameConfig.PvP = {
	MinLevel = 20, -- PvP Unlock Level

	-- Level Protection Logic: Can only damage if level difference is <= 25%
	LevelRangeCheck = function(lvlA, lvlB)
		local minLvl = math.min(lvlA, lvlB)
		local maxLvl = math.max(lvlA, lvlB)
		if maxLvl < 20 then return false end 
		local diff = maxLvl - minLvl
		return diff <= (0.25 * maxLvl)
	end,

	-- Arena and Safe Zone Coordinates
	ArenaSpawnA = Vector3.new(1266, 629.9, 753), 
	ArenaSpawnB = Vector3.new(1266, 629.9, 800), 
	CitySpawn = Vector3.new(-783.183, 36.304, 220.17), 
	CitySafetyZoneCenter = Vector3.new(-783.183, 36.304, 220.17),
	CitySafetyZoneRadius = 200 
}

return GameConfig