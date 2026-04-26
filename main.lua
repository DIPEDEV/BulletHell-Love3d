-- ============================================================
-- BULLET HELL - 5 rarity tiers, 40+ upgrades, creative mechanics
-- ============================================================

local W, H
local state = "intro"
local player
local enemies = {}
local eBullets = {}
local pBullets = {}
local particles = {}
local stars = {}
local pickups = {}
local powerTimers = {}
local upgrades = {}
local shopItems = {}
local wave = 0
local waveTimer = 0
local waveActive = false
local waveSpawnQueue = {}
local waveSpawnTimer = 0
local score = 0
local shakeAmount = 0
local introRot = 0
local introParticles = {}
local introTimer = 0
local shopSelect = 0
local totalTime = 0
local scorePopups = {}
local reviveUsed = false
local killStreak = 0
local killStreakTimer = 0
local cloneData = nil
local droneAngle = 0
local droneTimer = 0

local fonts = {}

local pBulletPool = {}
local eBulletPool = {}

local POWER_TYPES = {
    spread  = { name = "SPREAD",  hue = 0.14, sides = 4 },
    rapid   = { name = "RAPID",   hue = 0.55, sides = 3 },
    shield  = { name = "SHIELD",  hue = 0.0,  sides = 6 },
    score2x = { name = "2X SCR",  hue = 0.45, sides = 5 },
    speed   = { name = "SPEED",   hue = 0.33, sides = 0 },
}

-- Rarity 1 = Common, 2 = Uncommon, 3 = Rare, 4 = Legendary, 5 = Ultimate
local UPGRADE_DEFS = {
    -- === COMMON (cost 250-350) ===
    rapid_fire    = { name = "RAPID FIRE",   branch = "weapon", cost = 250,  prereq = nil,             icon = { sides = 3, hue = 0.08 }, rarity = 1 },
    heavy_bullet  = { name = "HVY BULLETS",  branch = "weapon", cost = 300,  prereq = nil,             icon = { sides = 4, hue = 0.0  }, rarity = 1 },
    bullet_speed  = { name = "BULLET SPD",   branch = "weapon", cost = 250,  prereq = nil,             icon = { sides = 0, hue = 0.60 }, rarity = 1 },
    sniper        = { name = "SNIPER",       branch = "weapon", cost = 300,  prereq = nil,             icon = { sides = 3, hue = 0.80 }, rarity = 1 },
    homing        = { name = "HOMING",       branch = "weapon", cost = 280,  prereq = "rapid_fire",    icon = { sides = 8, hue = 0.55 }, rarity = 1 },
    extra_life    = { name = "EXTRA LIFE",   branch = "char",   cost = 350,  prereq = nil,             icon = { sides = 5, hue = 0.35 }, rarity = 1 },
    fast_feet     = { name = "FAST FEET",    branch = "char",   cost = 280,  prereq = nil,             icon = { sides = 5, hue = 0.55 }, rarity = 1 },
    magnet        = { name = "MAGNET",       branch = "char",   cost = 250,  prereq = nil,             icon = { sides = 6, hue = 0.6  }, rarity = 1 },
    score_boost   = { name = "SCORE BOOST",  branch = "util",   cost = 280,  prereq = nil,             icon = { sides = 0, hue = 0.45 }, rarity = 1 },
    discount      = { name = "DISCOUNT",     branch = "util",   cost = 320,  prereq = nil,             icon = { sides = 4, hue = 0.30 }, rarity = 1 },
    power_extend  = { name = "PW EXTEND",    branch = "util",   cost = 280,  prereq = nil,             icon = { sides = 6, hue = 0.14 }, rarity = 1 },
    start_bonus   = { name = "START BONUS",  branch = "util",   cost = 300,  prereq = nil,             icon = { sides = 4, hue = 0.80 }, rarity = 1 },
    recycle       = { name = "RECYCLE",      branch = "util",   cost = 250,  prereq = nil,             icon = { sides = 6, hue = 0.30 }, rarity = 1 },
    luck          = { name = "LUCK",         branch = "util",   cost = 280,  prereq = nil,             icon = { sides = 5, hue = 0.12 }, rarity = 1 },

    -- === UNCOMMON (cost 850-950) ===
    double_shot   = { name = "DOUBLE SHOT",  branch = "weapon", cost = 850,  prereq = "rapid_fire",    icon = { sides = 3, hue = 0.12 }, rarity = 2 },
    back_shot     = { name = "BACK SHOT",    branch = "weapon", cost = 850,  prereq = "double_shot",   icon = { sides = 7, hue = 0.12 }, rarity = 2 },
    piercing      = { name = "PIERCING",     branch = "weapon", cost = 850,  prereq = "heavy_bullet",  icon = { sides = 4, hue = 0.03 }, rarity = 2 },
    crit_chance   = { name = "CRIT CHANCE",  branch = "weapon", cost = 900,  prereq = "heavy_bullet",  icon = { sides = 5, hue = 0.08 }, rarity = 2 },
    ricochet      = { name = "RICOCHET",     branch = "weapon", cost = 850,  prereq = "bullet_speed",  icon = { sides = 6, hue = 0.60 }, rarity = 2 },
    bullet_trail  = { name = "B TRAIL",      branch = "weapon", cost = 850,  prereq = "bullet_speed",  icon = { sides = 3, hue = 0.60 }, rarity = 2 },
    tiny_hitbox   = { name = "TINY HITBOX",  branch = "char",   cost = 850,  prereq = "fast_feet",     icon = { sides = 5, hue = 0.5  }, rarity = 2 },
    slow_field    = { name = "SLOW FIELD",   branch = "char",   cost = 850,  prereq = "tiny_hitbox",   icon = { sides = 8, hue = 0.55 }, rarity = 2 },
    shield_core   = { name = "SHIELD CORE",  branch = "char",   cost = 900,  prereq = "magnet",        icon = { sides = 6, hue = 0.0  }, rarity = 2 },
    thick_skin    = { name = "THICK SKIN",   branch = "char",   cost = 900,  prereq = "extra_life",    icon = { sides = 5, hue = 0.38 }, rarity = 2 },
    extra_choice  = { name = "+1 CHOICE",    branch = "util",   cost = 900,  prereq = nil,             icon = { sides = 0, hue = 0.30 }, rarity = 2 },
    wave_bonus    = { name = "WAVE BONUS",   branch = "util",   cost = 850,  prereq = "score_boost",   icon = { sides = 5, hue = 0.45 }, rarity = 2 },

    -- === RARE (cost 1450-1550) ===
    triple_shot   = { name = "TRIPLE SHOT",  branch = "weapon", cost = 1450, prereq = "double_shot",   icon = { sides = 3, hue = 0.16 }, rarity = 3 },
    multi_pierce  = { name = "MULTI PIERCE", branch = "weapon", cost = 1450, prereq = "piercing",      icon = { sides = 4, hue = 0.06 }, rarity = 3 },
    explosive     = { name = "EXPLOSIVE",    branch = "weapon", cost = 1450, prereq = "heavy_bullet",  icon = { sides = 8, hue = 0.06 }, rarity = 3 },
    burning       = { name = "BURNING",      branch = "weapon", cost = 1500, prereq = "heavy_bullet",  icon = { sides = 4, hue = 0.1  }, rarity = 3 },
    dodge         = { name = "DODGE",        branch = "char",   cost = 1450, prereq = "tiny_hitbox",   icon = { sides = 7, hue = 0.50 }, rarity = 3 },
    regen         = { name = "REGEN",        branch = "char",   cost = 1500, prereq = "extra_life",    icon = { sides = 4, hue = 0.35 }, rarity = 3 },
    retaliation   = { name = "RETALIATION",  branch = "char",   cost = 1500, prereq = "shield_core",   icon = { sides = 5, hue = 0.02 }, rarity = 3 },

    -- === LEGENDARY (cost 2050-2150) ===
    quad_shot     = { name = "QUAD SHOT",    branch = "weapon", cost = 2050, prereq = "triple_shot",   icon = { sides = 3, hue = 0.20 }, rarity = 4 },
    chain_lgt     = { name = "CHAIN LIGHT",  branch = "weapon", cost = 2100, prereq = "explosive",     icon = { sides = 8, hue = 0.55 }, rarity = 4 },
    overkill      = { name = "OVERKILL",     branch = "weapon", cost = 2050, prereq = "multi_pierce",  icon = { sides = 4, hue = 0.90 }, rarity = 4 },
    drone         = { name = "DRONE",        branch = "char",   cost = 2050, prereq = "magnet",        icon = { sides = 3, hue = 0.55 }, rarity = 4 },
    vampiric      = { name = "VAMPIRIC",     branch = "char",   cost = 2100, prereq = "extra_life",    icon = { sides = 4, hue = 0.95 }, rarity = 4 },

    -- === ULTIMATE (cost 2650-3000) ===
    second_wind   = { name = "2ND WIND",     branch = "char",   cost = 2650, prereq = "thick_skin",    icon = { sides = 5, hue = 0.32 }, rarity = 5 },
    time_dilation = { name = "TIME DILATE",  branch = "char",   cost = 2800, prereq = "slow_field",    icon = { sides = 6, hue = 0.55 }, rarity = 5 },
    clone         = { name = "CLONE",        branch = "weapon", cost = 3000, prereq = "quad_shot",     icon = { sides = 3, hue = 0.15 }, rarity = 5 },
}

local waveDefs = {
    { shooters = 4, interval = 0.9 },
    { shooters = 5, spreaders = 2, interval = 0.8 },
    { shooters = 3, spreaders = 2, zombies = 3, interval = 0.7 },
    { spreaders = 3, spirals = 2, zombies = 2, interval = 0.7 },
    { shooters = 4, spreaders = 2, spirals = 2, zombies = 4, interval = 0.6 },
    { boss = 1, zombies = 3, interval = 0.5 },
    { shooters = 5, spreaders = 3, spirals = 2, zombies = 3, interval = 0.5 },
    { spreaders = 4, spirals = 3, boss = 1, interval = 0.5 },
    { shooters = 6, spreaders = 4, spirals = 3, zombies = 5, interval = 0.45 },
    { boss = 2, spirals = 4, zombies = 4, interval = 0.4 },
}

local function hsv(h, s, v)
    h = h % 1
    local i = math.floor(h * 6)
    local f = h * 6 - i
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t = v * (1 - (1 - f) * s)
    i = i % 6
    if i == 0 then return v, t, p
    elseif i == 1 then return q, v, p
    elseif i == 2 then return p, v, t
    elseif i == 3 then return p, q, v
    elseif i == 4 then return t, p, v
    elseif i == 5 then return v, p, q
    end
end

local function dist(ax, ay, bx, by)
    return math.sqrt((bx - ax) ^ 2 + (by - ay) ^ 2)
end

local function angleTo(ax, ay, bx, by)
    return math.atan2(by - ay, bx - ax)
end

local function roundRect(x, y, w, h, r)
    r = r or 5
    love.graphics.rectangle("fill", x + r, y, w - 2 * r, h)
    love.graphics.rectangle("fill", x, y + r, w, h - 2 * r)
    love.graphics.circle("fill", x + r, y + r, r)
    love.graphics.circle("fill", x + w - r, y + r, r)
    love.graphics.circle("fill", x + r, y + h - r, r)
    love.graphics.circle("fill", x + w - r, y + h - r, r)
end

local function createFonts()
    local scale = math.min(W, H) / 700
    scale = math.max(0.5, math.min(scale, 2.5))
    local function fs(size) return math.floor(size * scale + 0.5) end
    fonts.title    = love.graphics.newFont(fs(52))
    fonts.wave     = love.graphics.newFont(fs(36))
    fonts.hud      = love.graphics.newFont(fs(13))
    fonts.hudBig   = love.graphics.newFont(fs(18))
    fonts.gameover = love.graphics.newFont(fs(48))
    fonts.score    = love.graphics.newFont(fs(20))
    fonts.medium   = love.graphics.newFont(fs(16))
    fonts.shop     = love.graphics.newFont(fs(15))
    fonts.shopBig  = love.graphics.newFont(fs(28))
    fonts.tiny     = love.graphics.newFont(fs(11))
    fonts.popup    = love.graphics.newFont(fs(12))
end

function love.load()
    W, H = love.graphics.getDimensions()
    createFonts()
    resetGame()
end

function resetGame()
    state = "intro"
    love.mouse.setVisible(true)
    introRot = 0; introTimer = 0; introParticles = {}
    shopItems = {}
    upgrades = {}
    scorePopups = {}
    reviveUsed = false
    killStreak = 0; killStreakTimer = 0
    cloneData = nil; droneAngle = 0; droneTimer = 0
    player = {
        x = W / 2, y = H - 80,
        vx = 0, vy = 0,
        speed = 260,
        radius = 5,
        visualRadius = 12,
        lives = 3,
        maxLives = 3,
        invuln = 0,
        shootCd = 0,
        shootRate = 0.22,
        focusSpeed = 130,
        aimAngle = -math.pi / 2,
        magnet = 1,
    }
    enemies = {}; eBullets = {}; pBullets = {}
    particles = {}; pickups = {}; stars = {}
    powerTimers = {}; pBulletPool = {}; eBulletPool = {}
    wave = 0; waveTimer = 0; waveActive = false
    waveSpawnQueue = {}; waveSpawnTimer = 0
    score = 0; shakeAmount = 0; totalTime = 0
    for _ = 1, 80 do
        table.insert(stars, { x = math.random() * W, y = math.random() * H, r = math.random() * 1.5 + 0.5, b = math.random() * 0.5 + 0.5 })
    end
end

function startGame()
    state = "playing"
    love.mouse.setVisible(false)
    if upgrades["start_bonus"] then score = score + 500 end
    if upgrades["clone"] then
        cloneData = { hist = {}, angle = player.aimAngle }
    end
    startNextWave()
end

function startNextWave()
    wave = wave + 1
    waveTimer = 1.5
    waveActive = false
    waveSpawnQueue = {}
    if upgrades["regen"] and wave % 3 == 0 and player.lives < player.maxLives then
        player.lives = player.lives + 1
        table.insert(scorePopups, { x = player.x, y = player.y - 20, text = "+1 LIFE", life = 1.5, maxLife = 1.5, vy = -40, r = 0.3, g = 0.9, b = 0.3 })
    end
    local defi = ((wave - 1) % #waveDefs) + 1
    local def = waveDefs[defi]
    local scaling = 1 + math.floor((wave - 1) / #waveDefs) * 0.5
    scaling = math.min(scaling, 3.5)
    local totalSpawns = 0
    if def.shooters then
        for _ = 1, math.ceil(def.shooters * scaling) do
            table.insert(waveSpawnQueue, { type = "shooter", delay = totalSpawns * def.interval })
            totalSpawns = totalSpawns + 1
        end
    end
    if def.spreaders then
        for _ = 1, math.ceil(def.spreaders * scaling) do
            table.insert(waveSpawnQueue, { type = "spreader", delay = totalSpawns * def.interval })
            totalSpawns = totalSpawns + 1
        end
    end
    if def.spirals then
        for _ = 1, math.ceil(def.spirals * scaling) do
            table.insert(waveSpawnQueue, { type = "spiral", delay = totalSpawns * def.interval })
            totalSpawns = totalSpawns + 1
        end
    end
    if def.zombies then
        for _ = 1, math.ceil(def.zombies * scaling) do
            table.insert(waveSpawnQueue, { type = "zombie", delay = totalSpawns * def.interval })
            totalSpawns = totalSpawns + 1
        end
    end
    if def.boss then
        for _ = 1, def.boss do
            table.insert(waveSpawnQueue, { type = "boss", delay = totalSpawns * def.interval + 0.5 })
            totalSpawns = totalSpawns + 1
        end
    end
    waveSpawnTimer = 0
    if upgrades["shield_core"] then
        local duration = upgrades["power_extend"] and 12 or 8
        powerTimers["shield"] = duration
    end
end

function openShop()
    state = "shop"
    love.mouse.setVisible(true)
    shopSelect = 0
    local eligible = {}
    for id, def in pairs(UPGRADE_DEFS) do
        if not upgrades[id] then
            if not def.prereq or upgrades[def.prereq] then
                table.insert(eligible, id)
            end
        end
    end
    shopItems = {}
    local pool = {}
    for _, id in ipairs(eligible) do
        local weight = UPGRADE_DEFS[id].rarity + 1
        if upgrades["luck"] then
            if UPGRADE_DEFS[id].rarity >= 4 then weight = weight + 4
            elseif UPGRADE_DEFS[id].rarity >= 3 then weight = weight + 2
            elseif UPGRADE_DEFS[id].rarity >= 2 then weight = weight + 1
            end
        end
        for _ = 1, weight do
            table.insert(pool, id)
        end
    end
    local used = {}
    local choices = upgrades["extra_choice"] and 4 or 3
    for _ = 1, math.min(choices, #eligible) do
        if #pool == 0 then break end
        local idx = math.random(#pool)
        local chosen = pool[idx]
        while used[chosen] do
            if #pool == 0 then break end
            idx = math.random(#pool)
            chosen = pool[idx]
        end
        used[chosen] = true
        table.insert(shopItems, chosen)
    end
end

local function buyUpgrade(id)
    local def = UPGRADE_DEFS[id]
    if not def or upgrades[id] then return end
    local cost = def.cost
    if upgrades["discount"] then cost = math.ceil(cost * 0.8) end
    if score < cost then return end
    score = score - cost
    upgrades[id] = true
    if id == "extra_life" then
        player.maxLives = math.min(player.maxLives + 1, 8)
        player.lives = math.min(player.lives + 1, player.maxLives)
    elseif id == "thick_skin" then
        player.maxLives = math.min(player.maxLives + 1, 8)
        player.lives = math.min(player.lives + 1, player.maxLives)
    elseif id == "start_bonus" then
        score = score + 500
    elseif id == "clone" then
        cloneData = { hist = {}, angle = player.aimAngle }
    end
end

local isPowerActive
local killEnemy

local function getBulletDamage()
    local dmg = 1
    if upgrades["heavy_bullet"] then dmg = dmg + 1 end
    if upgrades["sniper"] then dmg = dmg + 1 end
    return dmg
end

local function getBulletPierce()
    if upgrades["multi_pierce"] then return 2
    elseif upgrades["piercing"] then return 1
    else return 0 end
end

local function getBulletCount()
    if upgrades["quad_shot"] then return 4
    elseif upgrades["triple_shot"] then return 3
    elseif upgrades["double_shot"] then return 2
    else return 1 end
end

local function getShootRate()
    local r = player.shootRate
    if upgrades["rapid_fire"] then r = r * 0.55 end
    if isPowerActive("rapid") then r = r * 0.5 end
    if upgrades["sniper"] then r = r * 1.35 end
    return r
end

local function getBulletSpeed()
    local s = 700
    if upgrades["bullet_speed"] then s = s * 1.4 end
    return s
end

local function getPlayerSpeed()
    local s = player.speed
    if upgrades["fast_feet"] then s = s * 1.2 end
    if isPowerActive("speed") then s = s * 1.3 end
    return s
end

local function getHitboxRadius()
    local r = player.radius
    if upgrades["tiny_hitbox"] then r = r * 0.55 end
    return r
end

local function getPickupRadius()
    return player.visualRadius + 6 + (upgrades["magnet"] and 25 or 0)
end

local function getCritChance()
    return upgrades["crit_chance"] and 0.25 or 0
end

local function allocPBullet()
    local b = table.remove(pBulletPool)
    if not b then b = {} end
    b.hitEnemies = {}
    return b
end

local function freePBullet(b)
    table.insert(pBulletPool, b)
end

local function allocEBullet()
    local b = table.remove(eBulletPool)
    if not b then b = {} end
    return b
end

local function freeEBullet(b)
    table.insert(eBulletPool, b)
end

function spawnEnemy(etype)
    local margin = 30
    local sx = margin + math.random() * (W - margin * 2)
    local sy = -20
    local targetY = 50 + math.random() * 200
    local e = {
        type = etype,
        x = sx, y = sy,
        targetY = targetY,
        angle = 0, vx = 0, vy = 0,
        speed = 80 + math.random() * 40,
        radius = 10, hp = 1,
        shootTimer = 1 + math.random(),
        shootCd = 0, fireAngle = 0,
        pierceHit = false,
        flashTimer = 0, burnTimer = 0,
        origSpeed = 0,
    }
    if etype == "shooter" then
        e.speed = 60 + math.random() * 30
        e.shootCd = 1.0 + math.random() * 0.5
        e.hp = 2; e.radius = 13
    elseif etype == "spreader" then
        e.speed = 50 + math.random() * 20
        e.shootCd = 1.8 + math.random() * 0.5
        e.hp = 4; e.radius = 14
    elseif etype == "spiral" then
        e.speed = 40 + math.random() * 20
        e.shootCd = 0.06
        e.hp = 6; e.radius = 16
        e.fireAngle = math.random() * math.pi * 2
    elseif etype == "zombie" then
        e.speed = 100 + math.random() * 40
        e.shootCd = 9999
        e.hp = 4; e.radius = 11
        e.targetY = nil
    elseif etype == "boss" then
        e.speed = 30
        e.shootCd = 0.15
        e.hp = 22 + wave * 3; e.radius = 28
        e.targetY = 80 + math.random() * 100
        e.fireAngle = math.random() * math.pi * 2
        e.patternTimer = 0
        e.currentPattern = 1
    end
    e.origSpeed = e.speed
    table.insert(enemies, e)
end

local function addEBullet(x, y, angle, speedRatio)
    local spd = 200 + (wave * 12)
    spd = math.min(spd, 380)
    spd = spd * (speedRatio or 1)
    local b = allocEBullet()
    b.x = x; b.y = y
    b.vx = math.cos(angle) * spd
    b.vy = math.sin(angle) * spd
    b.radius = 3.5
    b.prevX = x; b.prevY = y
    b.slowedByDilation = false
    table.insert(eBullets, b)
end

local function addPBullet(x, y, angle, overrideDmg, overridePierce)
    local spd = getBulletSpeed()
    local b = allocPBullet()
    b.x = x; b.y = y
    b.vx = math.cos(angle) * spd
    b.vy = math.sin(angle) * spd
    b.radius = 2.0
    b.dmg = overrideDmg or getBulletDamage()
    b.pierce = overridePierce or getBulletPierce()
    b.hitEnemies = {}
    b.prevX = x; b.prevY = y
    b.crit = not overrideDmg and math.random() < getCritChance()
    if b.crit then b.dmg = b.dmg * 3 end
    table.insert(pBullets, b)
end

local function addParticle(x, y, count, hue, speedMul)
    for _ = 1, count do
        local a = math.random() * math.pi * 2
        local sp = math.random() * 200 + 80
        sp = sp * (speedMul or 1)
        table.insert(particles, {
            x = x, y = y,
            vx = math.cos(a) * sp,
            vy = math.sin(a) * sp,
            life = 0.3 + math.random() * 0.5,
            maxLife = 0.3 + math.random() * 0.5,
            hue = hue, size = 1 + math.random() * 2,
        })
    end
end

local function addScorePopup(x, y, text, r, g, b)
    table.insert(scorePopups, {
        x = x, y = y,
        text = text,
        life = 1.0, maxLife = 1.0,
        vy = -50, r = r or 1, g = g or 1, b = b or 1,
    })
end

local function spawnPickup(x, y)
    local types = { "spread", "rapid", "shield", "score2x", "speed" }
    local ptype = types[math.random(#types)]
    table.insert(pickups, {
        type = ptype,
        x = x, y = y,
        vy = 60 + math.random() * 30,
        radius = 10, rot = 0,
    })
end

-- killEnemy must be defined before applyExplosion (which calls it)
killEnemy = function(e, wasZombieContact)
    local hue = 0
    local points = 0
    if e.type == "shooter" then hue = 0.05; points = 80
    elseif e.type == "spreader" then hue = 0.12; points = 160
    elseif e.type == "spiral" then hue = 0.55; points = 220
    elseif e.type == "zombie" then hue = 0.3; points = 100
    elseif e.type == "boss" then hue = 0.0; points = 800 end

    if isPowerActive("score2x") then points = points * 2 end
    if upgrades["score_boost"] then points = math.floor(points * 1.25) end
    score = score + points

    killStreak = killStreak + 1
    killStreakTimer = 2.0
    if killStreak >= 5 then
        addScorePopup(e.x, e.y, "x" .. killStreak .. "!", 1, 0.85, 0.3)
    elseif killStreak >= 3 then
        addScorePopup(e.x, e.y, "+" .. points, 1, 0.9, 0.5)
    end

    if upgrades["vampiric"] and player.lives < player.maxLives and math.random() < 0.15 then
        player.lives = player.lives + 1
        addScorePopup(e.x, e.y, "+HP", 0.3, 1, 0.3)
    end

    -- Chain lightning: on kill, damage 2 nearest enemies for 60% dmg
    if upgrades["chain_lgt"] and not wasZombieContact then
        local targets = {}
        for _, other in ipairs(enemies) do
            if other ~= e then
                local d = dist(e.x, e.y, other.x, other.y)
                table.insert(targets, { e = other, d = d })
            end
        end
        table.sort(targets, function(a, b) return a.d < b.d end)
        for t = 1, math.min(2, #targets) do
            local tg = targets[t].e
            local dmg = math.ceil(points * 0.6)
            tg.hp = tg.hp - dmg
            tg.flashTimer = 0.15
            addScorePopup(tg.x, tg.y - 10, "" .. dmg, 0.4, 0.7, 1)
            if tg.hp <= 0 then
                killEnemy(tg, false)
                -- mark for removal by setting HP negative so the caller removes it
                tg.hp = -999
            end
        end
    end

    addParticle(e.x, e.y, 12, hue, 1)
    shakeAmount = math.max(shakeAmount, e.type == "boss" and 8 or (e.type == "zombie" and 5 or 2))

    if not wasZombieContact then
        local dropChance = e.type == "boss" and 1.0 or 0.18
        if math.random() < dropChance then
            spawnPickup(e.x, e.y)
        end
    end
end

local function applyExplosion(x, y)
    local radius = 60
    addParticle(x, y, 8, 0.08, 1)
    for j = #enemies, 1, -1 do
        local e = enemies[j]
        if dist(x, y, e.x, e.y) < radius + e.radius then
            e.hp = e.hp - 1
            e.flashTimer = 0.1
            if e.hp <= 0 then
                killEnemy(e, false)
                table.remove(enemies, j)
            end
        end
    end
end

isPowerActive = function(ptype)
    return powerTimers[ptype] and powerTimers[ptype] > 0
end

local function applyPower(ptype)
    local duration = upgrades["power_extend"] and 12 or 8
    powerTimers[ptype] = duration
end

local function hitPlayer()
    if player.invuln > 0 then return end
    if upgrades["dodge"] and math.random() < 0.15 then
        addScorePopup(player.x, player.y - 20, "DODGE!", 0.5, 0.8, 1)
        player.invuln = 0.3
        return
    end
    if isPowerActive("shield") then
        powerTimers["shield"] = 0
        addParticle(player.x, player.y, 15, 0.0, 1.2)
        player.invuln = 1.0
        shakeAmount = 3
        addScorePopup(player.x, player.y - 20, "SHIELD!", 1, 1, 1)
        if upgrades["retaliation"] then
            for i = 0, 7 do
                local a = i * math.pi / 4
                addPBullet(player.x, player.y, a, getBulletDamage(), 0)
            end
            addScorePopup(player.x, player.y - 40, "RETAL!", 1, 0.4, 0.1)
        end
        return
    end
    player.lives = player.lives - 1
    player.invuln = 2.0
    addParticle(player.x, player.y, 20, 0.0, 1.5)
    shakeAmount = 6
    if upgrades["retaliation"] then
        for i = 0, 7 do
            local a = i * math.pi / 4
            addPBullet(player.x, player.y, a, getBulletDamage(), 0)
        end
        addScorePopup(player.x, player.y - 40, "RETAL!", 1, 0.4, 0.1)
    end
    if player.lives <= 0 then
        if upgrades["second_wind"] and not reviveUsed then
            reviveUsed = true
            player.lives = 1
            player.invuln = 3.0
            addScorePopup(player.x, player.y - 30, "2ND WIND!", 1, 0.5, 0.3)
            addParticle(player.x, player.y, 30, 0.08, 2)
            shakeAmount = 10
            return
        end
        state = "gameover"
        love.mouse.setVisible(true)
        addParticle(player.x, player.y, 40, 0.0, 2)
        killStreak = 0
    end
end

local function drawShape(x, y, angle, sides, radius, r, g, b, a, innerRadius, ir, ig, ib, ia)
    love.graphics.setColor(r, g, b, a)
    local pts = {}
    if sides == 0 then
        love.graphics.circle("fill", x, y, radius, 16)
    else
        local step = math.pi * 2 / sides
        for i = 0, sides - 1 do
            local da = angle + step * i - math.pi / 2
            table.insert(pts, x + math.cos(da) * radius)
            table.insert(pts, y + math.sin(da) * radius)
        end
        love.graphics.polygon("fill", pts)
    end
    if innerRadius and ir then
        love.graphics.setColor(ir, ig, ib, ia)
        if sides == 0 then
            love.graphics.circle("fill", x, y, innerRadius, 16)
        else
            pts = {}
            local step = math.pi * 2 / sides
            for i = 0, sides - 1 do
                local da = angle + step * i - math.pi / 2
                table.insert(pts, x + math.cos(da) * innerRadius)
                table.insert(pts, y + math.sin(da) * innerRadius)
            end
            love.graphics.polygon("fill", pts)
        end
    end
end

local function drawPlayerShape(x, y, angle, r, g, b, a)
    love.graphics.setColor(r, g, b, a)
    love.graphics.polygon("fill",
        x + math.cos(angle) * 14, y + math.sin(angle) * 14,
        x + math.cos(angle + math.pi - 0.6) * 10, y + math.sin(angle + math.pi - 0.6) * 10,
        x + math.cos(angle + math.pi + 0.6) * 10, y + math.sin(angle + math.pi + 0.6) * 10
    )
    love.graphics.setColor(0.4, 0.9, 1, 0.5)
    love.graphics.polygon("fill",
        x + math.cos(angle) * 5, y + math.sin(angle) * 5,
        x + math.cos(angle + math.pi - 0.4) * 2, y + math.sin(angle + math.pi - 0.4) * 2,
        x + math.cos(angle + math.pi + 0.4) * 2, y + math.sin(angle + math.pi + 0.4) * 2
    )
end

local function drawSmallShip(x, y, angle, r, g, b, a, scale)
    scale = scale or 1
    love.graphics.setColor(r, g, b, a)
    love.graphics.polygon("fill",
        x + math.cos(angle) * 8 * scale, y + math.sin(angle) * 8 * scale,
        x + math.cos(angle + math.pi - 0.5) * 5 * scale, y + math.sin(angle + math.pi - 0.5) * 5 * scale,
        x + math.cos(angle + math.pi + 0.5) * 5 * scale, y + math.sin(angle + math.pi + 0.5) * 5 * scale
    )
end

function love.update(dt)
    W, H = love.graphics.getDimensions()
    totalTime = totalTime + dt

    if state == "intro" then
        introRot = introRot + dt * 0.8
        introTimer = introTimer + dt
        if introTimer > 0.15 then
            introTimer = 0
            local a = math.random() * math.pi * 2 + introRot
            local dist = 60 + math.random() * 120
            table.insert(introParticles, {
                x = W / 2 + math.cos(a) * dist,
                y = H / 2 + math.sin(a) * dist,
                life = 0.8 + math.random() * 0.6,
                maxLife = 0.8 + math.random() * 0.6,
                hue = math.random(), size = 1 + math.random() * 2,
            })
        end
        for i = #introParticles, 1, -1 do
            local p = introParticles[i]
            p.life = p.life - dt
            if p.life <= 0 then table.remove(introParticles, i) end
        end
        return
    end

    if state == "shop" then
        for i = #particles, 1, -1 do
            local p = particles[i]
            p.x = p.x + p.vx * dt; p.y = p.y + p.vy * dt
            p.life = p.life - dt
            if p.life <= 0 then table.remove(particles, i) end
        end
        return
    end

    if state == "gameover" then
        for i = #particles, 1, -1 do
            local p = particles[i]
            p.x = p.x + p.vx * dt; p.y = p.y + p.vy * dt
            p.life = p.life - dt
            if p.life <= 0 then table.remove(particles, i) end
        end
        shakeAmount = shakeAmount * 0.9
        return
    end

    -- PLAYING
    if player.invuln > 0 then player.invuln = player.invuln - dt end
    if player.shootCd > 0 then player.shootCd = player.shootCd - dt end

    for k, _ in pairs(powerTimers) do
        powerTimers[k] = powerTimers[k] - dt
        if powerTimers[k] <= 0 then powerTimers[k] = nil end
    end

    if killStreakTimer > 0 then
        killStreakTimer = killStreakTimer - dt
        if killStreakTimer <= 0 then killStreak = 0 end
    end

    for i = #scorePopups, 1, -1 do
        local sp = scorePopups[i]
        sp.life = sp.life - dt
        sp.y = sp.y + sp.vy * dt
        if sp.life <= 0 then table.remove(scorePopups, i) end
    end

    local mx, my = love.mouse.getPosition()
    player.aimAngle = angleTo(player.x, player.y, mx, my)

    local isFocus = love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")
    local spd = isFocus and player.focusSpeed or getPlayerSpeed()

    player.vx = 0; player.vy = 0
    if love.keyboard.isDown("w") or love.keyboard.isDown("up") then player.vy = -1 end
    if love.keyboard.isDown("s") or love.keyboard.isDown("down") then player.vy = 1 end
    if love.keyboard.isDown("a") or love.keyboard.isDown("left") then player.vx = -1 end
    if love.keyboard.isDown("d") or love.keyboard.isDown("right") then player.vx = 1 end

    local mag = math.sqrt(player.vx ^ 2 + player.vy ^ 2)
    if mag > 0 then player.vx = player.vx / mag; player.vy = player.vy / mag end
    player.x = player.x + player.vx * spd * dt
    player.y = player.y + player.vy * spd * dt

    local hr = getHitboxRadius()
    if player.x < hr then player.x = hr end
    if player.x > W - hr then player.x = W - hr end
    if player.y < hr then player.y = hr end
    if player.y > H - hr then player.y = H - hr end

    -- Clone: store position history
    if cloneData then
        table.insert(cloneData.hist, { x = player.x, y = player.y, angle = player.aimAngle })
        if #cloneData.hist > 30 then table.remove(cloneData.hist, 1) end
        cloneData.angle = player.aimAngle
    end

    -- Time dilation: during focus, slow nearby enemy bullets
    if upgrades["time_dilation"] and isFocus then
        for _, b in ipairs(eBullets) do
            if not b.slowedByDilation and dist(player.x, player.y, b.x, b.y) < 120 then
                b.vx = b.vx * 0.4
                b.vy = b.vy * 0.4
                b.slowedByDilation = true
            end
        end
    end

    -- Slow field
    if upgrades["slow_field"] then
        for _, e in ipairs(enemies) do
            local d = dist(player.x, player.y, e.x, e.y)
            if d < 100 then
                local factor = 0.5 + (d / 100) * 0.5
                e.speed = e.origSpeed * factor
            else
                e.speed = e.origSpeed
            end
        end
    end

    -- Shooting
    if player.shootCd <= 0 then
        local rate = getShootRate()
        local count = getBulletCount()
        local a = player.aimAngle
        if count >= 4 then
            addPBullet(player.x, player.y, a - 0.25)
            addPBullet(player.x, player.y, a - 0.08)
            addPBullet(player.x, player.y, a + 0.08)
            addPBullet(player.x, player.y, a + 0.25)
        elseif count == 3 then
            addPBullet(player.x, player.y, a)
            addPBullet(player.x, player.y, a - 0.2)
            addPBullet(player.x, player.y, a + 0.2)
        elseif count == 2 then
            addPBullet(player.x, player.y, a - 0.15)
            addPBullet(player.x, player.y, a + 0.15)
        elseif isPowerActive("spread") then
            addPBullet(player.x, player.y, a)
            addPBullet(player.x, player.y, a - 0.18)
            addPBullet(player.x, player.y, a + 0.18)
        else
            addPBullet(player.x, player.y, a)
        end
        if upgrades["back_shot"] then
            if count >= 3 then
                addPBullet(player.x, player.y, a + math.pi)
                addPBullet(player.x, player.y, a + math.pi - 0.2)
                addPBullet(player.x, player.y, a + math.pi + 0.2)
            else
                addPBullet(player.x, player.y, a + math.pi)
            end
        end
        player.shootCd = rate
    end

    -- Drone firing
    if upgrades["drone"] then
        droneTimer = droneTimer + dt
        droneAngle = droneAngle + dt * 3
        if droneTimer > 0.35 then
            droneTimer = 0
            local nearest = nil
            local nearDist = 250
            for _, e in ipairs(enemies) do
                local dx = player.x + math.cos(droneAngle) * 45
                local dy = player.y + math.sin(droneAngle) * 45
                local d = dist(dx, dy, e.x, e.y)
                if d < nearDist then nearDist = d; nearest = e end
            end
            if nearest then
                local dx = player.x + math.cos(droneAngle) * 45
                local dy = player.y + math.sin(droneAngle) * 45
                addPBullet(dx, dy, angleTo(dx, dy, nearest.x, nearest.y), 1, 0)
            end
        end
    end

    -- Clone firing
    if cloneData and #cloneData.hist > 15 and player.shootCd <= getShootRate() * 0.5 then
        local old = cloneData.hist[#cloneData.hist - 15]
        if old then
            local a = old.angle + math.pi
            local count = getBulletCount()
            if count >= 3 then
                addPBullet(old.x, old.y, a)
                addPBullet(old.x, old.y, a - 0.2)
                addPBullet(old.x, old.y, a + 0.2)
            else
                addPBullet(old.x, old.y, a)
            end
        end
    end

    if waveTimer > 0 then
        waveTimer = waveTimer - dt
        if waveTimer <= 0 then waveActive = true end
    end

    if waveActive then
        waveSpawnTimer = waveSpawnTimer + dt
        while #waveSpawnQueue > 0 and waveSpawnQueue[1].delay <= waveSpawnTimer do
            local spawn = table.remove(waveSpawnQueue, 1)
            spawnEnemy(spawn.type)
        end
        if #waveSpawnQueue == 0 and #enemies == 0 and #eBullets == 0 then
            waveActive = false
            openShop()
        end
    end

    -- Enemy updates + burn damage
    for _, e in ipairs(enemies) do
        if e.flashTimer > 0 then e.flashTimer = e.flashTimer - dt end
        if e.burnTimer > 0 then
            e.burnTimer = e.burnTimer - dt
            if math.floor(e.burnTimer * 10) % 2 == 0 then
                e.hp = e.hp - 1
                e.flashTimer = 0.08
                if e.hp <= 0 then
                    -- will be removed in cleanup loop
                    e.hp = -999
                end
            end
        end
        if e.targetY and e.y < e.targetY then
            e.y = e.y + e.speed * dt
        end
        if e.type == "zombie" then
            local a = angleTo(e.x, e.y, player.x, player.y)
            e.x = e.x + math.cos(a) * e.speed * dt
            e.y = e.y + math.sin(a) * e.speed * dt
            if dist(e.x, e.y, player.x, player.y) < getHitboxRadius() + e.radius + 2 then
                hitPlayer()
                killEnemy(e, true)
                e.hp = 0
            end
        end
        if e.type == "boss" then
            if e.targetY and e.y < e.targetY then
                e.y = e.y + e.speed * dt
            else
                local bossTargetX = W / 2 + math.sin(waveSpawnTimer * 0.5) * 150
                local dx = bossTargetX - e.x
                if math.abs(dx) > 2 then
                    e.x = e.x + (dx > 0 and 1 or -1) * 60 * dt
                end
            end
        end
        e.shootTimer = e.shootTimer + dt
        if e.shootTimer >= e.shootCd and e.y >= -10 then
            e.shootTimer = 0
            if e.type == "shooter" then
                addEBullet(e.x, e.y, angleTo(e.x, e.y, player.x, player.y), 1)
            elseif e.type == "spreader" then
                local a = angleTo(e.x, e.y, player.x, player.y)
                for i = -2, 2 do
                    addEBullet(e.x, e.y, a + i * 0.2, 0.7 + math.abs(i) * 0.15)
                end
            elseif e.type == "spiral" then
                e.fireAngle = e.fireAngle + 0.25
                addEBullet(e.x, e.y, e.fireAngle, 0.8)
                addEBullet(e.x, e.y, e.fireAngle + math.pi, 0.8)
            elseif e.type == "boss" then
                e.patternTimer = e.patternTimer + dt
                if e.patternTimer > 0.8 then
                    e.patternTimer = 0
                    e.currentPattern = e.currentPattern + 1
                    if e.currentPattern > 3 then e.currentPattern = 1 end
                end
                if e.currentPattern == 1 then
                    e.fireAngle = e.fireAngle + 0.15
                    for i = 0, 7 do
                        addEBullet(e.x, e.y, e.fireAngle + i * math.pi / 4, 0.6)
                    end
                elseif e.currentPattern == 2 then
                    local a = angleTo(e.x, e.y, player.x, player.y)
                    for i = -4, 4 do
                        addEBullet(e.x, e.y, a + i * 0.15, 0.9)
                    end
                elseif e.currentPattern == 3 then
                    for i = 0, 11 do
                        addEBullet(e.x, e.y, e.fireAngle + i * math.pi / 6, 1.1)
                    end
                    e.fireAngle = e.fireAngle + 0.3
                end
            end
        end
    end

    -- Update bullets
    for _, b in ipairs(eBullets) do
        b.prevX = b.x; b.prevY = b.y
        b.x = b.x + b.vx * dt; b.y = b.y + b.vy * dt
        if b.slowedByDilation and dist(player.x, player.y, b.x, b.y) > 130 then
            b.vx = b.vx / 0.4
            b.vy = b.vy / 0.4
            b.slowedByDilation = false
        end
    end

    for _, b in ipairs(pBullets) do
        b.prevX = b.x; b.prevY = b.y
        if upgrades["homing"] and #enemies > 0 then
            local nearest = nil
            local nearDist = 200
            for _, e in ipairs(enemies) do
                local d = dist(b.x, b.y, e.x, e.y)
                if d < nearDist then
                    nearDist = d
                    nearest = e
                end
            end
            if nearest then
                local ta = angleTo(b.x, b.y, nearest.x, nearest.y)
                local ca = math.atan2(b.vy, b.vx)
                local diff = ta - ca
                while diff > math.pi do diff = diff - math.pi * 2 end
                while diff < -math.pi do diff = diff + math.pi * 2 end
                local turnRate = 3.0 * dt
                if math.abs(diff) < turnRate then
                    ca = ta
                elseif diff > 0 then
                    ca = ca + turnRate
                else
                    ca = ca - turnRate
                end
                local speed = math.sqrt(b.vx ^ 2 + b.vy ^ 2)
                b.vx = math.cos(ca) * speed
                b.vy = math.sin(ca) * speed
            end
        end
        b.x = b.x + b.vx * dt; b.y = b.y + b.vy * dt
    end

    -- Pickups with auto-collect
    local pRad = getPickupRadius()
    local autoCollectRange = pRad + 40
    for i = #pickups, 1, -1 do
        local p = pickups[i]
        p.y = p.y + p.vy * dt
        p.rot = p.rot + dt * 3
        local d = dist(p.x, p.y, player.x, player.y)
        if d < autoCollectRange then
            local a = angleTo(p.x, p.y, player.x, player.y)
            local pullSpeed = 150 * (1 - d / autoCollectRange) + 40
            p.x = p.x + math.cos(a) * pullSpeed * dt
            p.y = p.y + math.sin(a) * pullSpeed * dt
        end
        if p.y > H + 20 then
            table.remove(pickups, i)
        elseif d < pRad + p.radius then
            applyPower(p.type)
            addParticle(p.x, p.y, 8, POWER_TYPES[p.type].hue, 0.8)
            table.remove(pickups, i)
        end
    end

    -- Enemy bullets vs player
    local hitboxR = getHitboxRadius()
    for i = #eBullets, 1, -1 do
        local b = eBullets[i]
        if b.x < -30 or b.x > W + 30 or b.y < -30 or b.y > H + 30 then
            freeEBullet(b)
            table.remove(eBullets, i)
        elseif player.invuln <= 0 and dist(b.x, b.y, player.x, player.y) < hitboxR + b.radius then
            hitPlayer()
            freeEBullet(b)
            table.remove(eBullets, i)
        end
    end

    -- Player bullets vs enemies
    for i = #pBullets, 1, -1 do
        local b = pBullets[i]
        local killed = false
        if b.x < -10 or b.x > W + 10 or b.y < -10 or b.y > H + 10 then
            if upgrades["ricochet"] and b.pierce >= 0 then
                if b.x < -10 or b.x > W + 10 then b.vx = -b.vx; b.x = math.max(10, math.min(W - 10, b.x)) end
                if b.y < -10 or b.y > H + 10 then b.vy = -b.vy; b.y = math.max(10, math.min(H - 10, b.y)) end
                b.pierce = b.pierce - 1
                if b.pierce < 0 then killed = true end
            end
        end
        if not killed then
            local hit = false
            for j = #enemies, 1, -1 do
                local e = enemies[j]
                if not b.hitEnemies[e] and not killed and dist(b.x, b.y, e.x, e.y) < e.radius + b.radius then
                    local dmg = b.dmg
                    local excessDmg = dmg - e.hp
                    e.hp = e.hp - dmg
                    b.hitEnemies[e] = true
                    e.flashTimer = 0.1
                    if upgrades["burning"] then
                        e.burnTimer = math.max(e.burnTimer or 0, 3)
                    end
                    if e.hp <= 0 then
                        if upgrades["explosive"] then applyExplosion(e.x, e.y) end
                        -- Overkill: excess damage hits nearest enemy
                        if upgrades["overkill"] and excessDmg > 0 then
                            local nearest, nearDist = nil, 9999
                            for _, other in ipairs(enemies) do
                                if other ~= e then
                                    local d = dist(e.x, e.y, other.x, other.y)
                                    if d < nearDist then nearDist = d; nearest = other end
                                end
                            end
                            if nearest and nearDist < 120 then
                                nearest.hp = nearest.hp - excessDmg
                                nearest.flashTimer = 0.12
                                addScorePopup(nearest.x, nearest.y - 10, "" .. excessDmg, 1, 0.6, 0.1)
                            end
                        end
                        killEnemy(e, false)
                        table.remove(enemies, j)
                    else
                        addParticle(b.x, b.y, 3, 0.0, 0.5)
                        if b.crit then addScorePopup(b.x, b.y, "CRIT!", 1, 0.3, 0.3) end
                    end
                    b.pierce = b.pierce - 1
                    if b.pierce < 0 then hit = true; break end
                end
            end
            if hit then killed = true end
        end
        if killed then
            freePBullet(b)
            table.remove(pBullets, i)
        end
    end

    -- Cleanup dead enemies (HP <= 0 or HP == -999)
    for i = #enemies, 1, -1 do
        if enemies[i].hp <= 0 or enemies[i].y > H + 50 then
            if enemies[i].hp <= 0 and enemies[i].hp ~= -999 then
                -- zombies killed by contact are handled in zombie loop
            end
            table.remove(enemies, i)
        end
    end

    for i = #particles, 1, -1 do
        local p = particles[i]
        p.x = p.x + p.vx * dt; p.y = p.y + p.vy * dt
        p.life = p.life - dt
        if p.life <= 0 then table.remove(particles, i) end
    end

    shakeAmount = shakeAmount * 0.85
    if shakeAmount < 0.1 then shakeAmount = 0 end
end

function drawImmersiveHUD()
    love.graphics.setColor(0.03, 0.03, 0.05, 0.9)
    love.graphics.rectangle("fill", 0, 0, W, 52)
    love.graphics.setColor(0.15, 0.15, 0.22, 0.8)
    love.graphics.rectangle("fill", 0, 51, W, 1)

    love.graphics.setColor(1, 0.85, 0.3, 1)
    drawShape(22, 22, totalTime * 2, 4, 8, 1, 0.85, 0.3, 1, 3, 0.9, 0.7, 0.2, 0.7)
    love.graphics.setFont(fonts.hudBig)
    love.graphics.setColor(1, 0.9, 0.5, 1)
    love.graphics.print(tostring(score), 34, 16)

    love.graphics.setColor(0.2, 0.2, 0.3, 0.6)
    love.graphics.rectangle("fill", 110, 8, 1, 36)

    local waveX = 130
    love.graphics.setColor(0.6, 0.5, 0.8, 0.7)
    love.graphics.circle("line", waveX + 14, 26, 12)
    love.graphics.circle("line", waveX + 14, 26, 6)
    love.graphics.setFont(fonts.hudBig)
    love.graphics.setColor(1, 0.8, 0.3, 1)
    love.graphics.print("W" .. wave, waveX + 32, 16)

    love.graphics.setColor(0.8, 0.3, 0.3, 0.7)
    love.graphics.setFont(fonts.hud)
    love.graphics.print("#" .. #enemies, waveX + 100, 20)

    if killStreak >= 3 then
        love.graphics.setColor(1, 0.85, 0.3, 0.7 + math.sin(totalTime * 4) * 0.3)
        love.graphics.print("STREAK x" .. killStreak, waveX + 140, 20)
    end

    local ux = W / 2 - 60
    local ucount = 0
    for id, _ in pairs(upgrades) do
        local def = UPGRADE_DEFS[id]
        if def then
            local r, g, b = hsv(def.icon.hue, 0.8, 0.9)
            love.graphics.setColor(0.05, 0.05, 0.08, 0.7)
            love.graphics.rectangle("fill", ux + ucount * 28, 32, 22, 16, 3, 3)
            drawShape(ux + ucount * 28 + 11, 40, 0, def.icon.sides, 6, r, g, b, 1)
            ucount = ucount + 1
            if ucount > 5 then break end
        end
    end

    local lx = W - 18
    for i = 1, player.lives do
        drawSmallShip(lx, 12, -math.pi / 2, 0.2, 0.7, 1, 0.9, 0.8)
        lx = lx - 22
    end
    love.graphics.setColor(0.5, 0.5, 0.5, 0.5)
    love.graphics.setFont(fonts.tiny)
    love.graphics.print("HP", W - 20 - player.lives * 22, 2)

    local py = 54
    local activeList = {}
    for k, t in pairs(powerTimers) do
        if t > 0 then table.insert(activeList, { type = k, timer = t }) end
    end
    if #activeList > 0 then
        local px = 10
        local maxDur = upgrades["power_extend"] and 12 or 8
        for _, a in ipairs(activeList) do
            local info = POWER_TYPES[a.type]
            local r, g, b = hsv(info.hue, 0.8, 0.9)
            local barW = 80 * (a.timer / maxDur)
            love.graphics.setColor(0.03, 0.03, 0.05, 0.8)
            love.graphics.rectangle("fill", px, py, 84, 14, 3, 3)
            love.graphics.setColor(r * 0.25, g * 0.25, b * 0.25, 0.8)
            love.graphics.rectangle("fill", px + 2, py + 2, 80, 10, 2, 2)
            love.graphics.setColor(r, g, b, 1)
            love.graphics.rectangle("fill", px + 2, py + 2, barW, 10, 2, 2)
            drawShape(px + 42, py + 7, 0, info.sides, 5, r, g, b, 1)
            px = px + 92
        end
    end

    if upgrades["second_wind"] then
        love.graphics.setFont(fonts.tiny)
        love.graphics.setColor(reviveUsed and 0.3 or 1, reviveUsed and 0.5 or 0.5, reviveUsed and 0.3 or 0.3, 0.6)
        love.graphics.print(reviveUsed and "2ND WIND: USED" or "2ND WIND: READY", W - 110, py + 4)
    end
end

function drawShop()
    local sc = math.min(W, H) / 700
    sc = math.max(0.5, math.min(sc, 2.5))

    love.graphics.setColor(0.02, 0.02, 0.04, 0.85)
    love.graphics.rectangle("fill", 0, 0, W, H)

    love.graphics.setFont(fonts.shopBig)
    love.graphics.setColor(1, 0.85, 0.3, 1)
    local title = "UPGRADE STATION"
    local tw = fonts.shopBig:getWidth(title)
    love.graphics.print(title, W / 2 - tw / 2, 40 * sc)

    love.graphics.setColor(0.5, 0.5, 0.5, 0.6)
    love.graphics.setFont(fonts.hud)
    local sub = "Spend score to enhance your ship"
    local sw = fonts.hud:getWidth(sub)
    love.graphics.print(sub, W / 2 - sw / 2, 75 * sc)

    if upgrades["discount"] then
        love.graphics.setColor(0.3, 0.9, 0.3, 0.7)
        love.graphics.setFont(fonts.tiny)
        love.graphics.print("(-20% costs active)", W / 2 - 30 * sc, 90 * sc)
    end

    local cardW = math.floor(160 * sc)
    local cardH = math.floor(230 * sc)
    local spacing = math.floor(16 * sc)
    local totalW = #shopItems * cardW + (#shopItems - 1) * spacing
    local startX = W / 2 - totalW / 2
    local cardY = 110 * sc

    local rarityColors = {
        {0.45, 0.45, 0.55},  -- Common
        {0.2,  0.65, 0.85},  -- Uncommon
        {0.8,  0.4,  1.0 },  -- Rare
        {1.0,  0.7,  0.2 },  -- Legendary
        {1.0,  0.3,  0.0 },  -- Ultimate
    }
    local rarityNames = { "COMMON", "UNCOMMON", "RARE", "LEGENDARY", "ULTIMATE" }

    for i, id in ipairs(shopItems) do
        local cx = startX + (i - 1) * (cardW + spacing)
        local def = UPGRADE_DEFS[id]
        local r, g, b = hsv(def.icon.hue, 0.8, 0.9)
        local highlight = shopSelect == i

        love.graphics.setColor(0, 0, 0, 0.4)
        local soff = math.floor(3 * sc)
        love.graphics.rectangle("fill", cx + soff, cardY + soff, cardW, cardH, 8, 8)

        if highlight then
            love.graphics.setColor(0.2, 0.18, 0.12, 0.95)
        else
            love.graphics.setColor(0.08, 0.08, 0.12, 0.92)
        end
        love.graphics.rectangle("fill", cx, cardY, cardW, cardH, 8, 8)

        love.graphics.setColor(highlight and 1 or 0.3, highlight and 0.8 or 0.25, highlight and 0.2 or 0.2, highlight and 0.8 or 0.4)
        love.graphics.rectangle("line", cx, cardY, cardW, cardH, 8, 8)

        local rc = rarityColors[def.rarity] or rarityColors[1]
        love.graphics.setColor(rc[1], rc[2], rc[3], 0.5)
        love.graphics.rectangle("fill", cx + 6 * sc, cardY + 6 * sc, cardW - 12 * sc, 3, 2, 2)

        -- Rarity label
        love.graphics.setFont(fonts.tiny)
        love.graphics.setColor(rc[1], rc[2], rc[3], 0.8)
        local rlabel = rarityNames[def.rarity] or "COMMON"
        local rlw = fonts.tiny:getWidth(rlabel)
        love.graphics.print(rlabel, cx + cardW / 2 - rlw / 2, cardY + 14 * sc)

        local branchLabel = def.branch == "weapon" and "WEAPON" or (def.branch == "char" and "BODY" or "UTILITY")
        love.graphics.setColor(0.5, 0.5, 0.6, 0.6)
        love.graphics.print(branchLabel, cx + cardW / 2 - fonts.tiny:getWidth(branchLabel) / 2, cardY + 28 * sc)

        local iconSize = math.floor(22 * sc)
        local iconY = cardY + 80 * sc
        love.graphics.setColor(r * 0.15, g * 0.15, b * 0.15, 0.6)
        love.graphics.circle("fill", cx + cardW / 2, iconY, iconSize + 10 * sc)
        drawShape(cx + cardW / 2, iconY, totalTime * 2 + i, def.icon.sides, iconSize, r, g, b, 1, iconSize * 0.45, 1, 1, 1, 0.4)

        love.graphics.setFont(fonts.shop)
        love.graphics.setColor(1, 1, 1, 1)
        local nw = fonts.shop:getWidth(def.name)
        love.graphics.print(def.name, cx + cardW / 2 - nw / 2, cardY + 115 * sc)

        local cost = def.cost
        if upgrades["discount"] then cost = math.ceil(cost * 0.8) end
        local costY = cardY + 145 * sc
        love.graphics.setColor(1, 0.85, 0.3, score >= cost and 1 or 0.35)
        drawShape(cx + cardW / 2 - 18 * sc, costY + 3 * sc, 0, 4, 6 * sc, 1, 0.85, 0.3, 1, 2.5 * sc, 0.9, 0.7, 0.2, 0.6)
        love.graphics.setFont(fonts.hudBig)
        local costStr = tostring(cost)
        local cw = fonts.hudBig:getWidth(costStr)
        love.graphics.print(costStr, cx + cardW / 2 - cw / 2 + 5 * sc, costY)

        local prereqY = cardY + 175 * sc
        if def.prereq and not upgrades[def.prereq] then
            love.graphics.setFont(fonts.tiny)
            love.graphics.setColor(0.7, 0.3, 0.3, 0.8)
            local preq = "Need: " .. UPGRADE_DEFS[def.prereq].name
            local pw = fonts.tiny:getWidth(preq)
            love.graphics.print(preq, cx + cardW / 2 - pw / 2, prereqY)
        elseif upgrades[id] then
            love.graphics.setFont(fonts.tiny)
            love.graphics.setColor(0.3, 0.8, 0.3, 0.8)
            local owned = "OWNED"
            love.graphics.print(owned, cx + cardW / 2 - fonts.tiny:getWidth(owned) / 2, prereqY)
        end

        love.graphics.setFont(fonts.hud)
        love.graphics.setColor(0.5, 0.5, 0.5, 0.7)
        local keyH = "[" .. i .. "]"
        love.graphics.print(keyH, cx + cardW / 2 - fonts.hud:getWidth(keyH) / 2, cardY + cardH - 25 * sc)
    end

    love.graphics.setFont(fonts.hud)
    love.graphics.setColor(0.5, 0.5, 0.6, 0.7)
    local footer = "Press 1-4 to buy  |  ENTER / SPACE to skip  |  Score: " .. score
    local fw = fonts.hud:getWidth(footer)
    love.graphics.print(footer, W / 2 - fw / 2, cardY + cardH + 25 * sc)
end

function drawIntro()
    local cx = W / 2; local cy = H / 2
    for _, s in ipairs(stars) do
        love.graphics.setColor(1, 1, 1, s.b)
        love.graphics.circle("fill", s.x, s.y, s.r)
    end
    for _, p in ipairs(introParticles) do
        local alpha = p.life / p.maxLife
        local r, g, b = hsv(p.hue, 0.8, 0.8)
        love.graphics.setColor(r, g, b, alpha)
        love.graphics.circle("fill", p.x, p.y, p.size * alpha)
    end
    local r1, g1, b1 = hsv((introRot * 0.3) % 1, 0.8, 1)
    local r2, g2, b2 = hsv((introRot * 0.3 + 0.5) % 1, 0.8, 1)
    drawShape(cx, cy - 30, introRot, 6, 50, r1, g1, b1, 0.6, 25, r2, g2, b2, 0.4)
    drawShape(cx, cy - 30, -introRot * 1.5, 4, 40, r2, g2, b2, 0.4, 15, r1, g1, b1, 0.3)
    drawSmallShip(cx, cy - 30, -math.pi / 2, 0.2, 0.7, 1, 1, 2.5)
    love.graphics.setFont(fonts.title)
    local title = "BULLET HELL"
    local tw = fonts.title:getWidth(title)
    love.graphics.setColor(1, 0.2, 0.15, 1)
    love.graphics.print(title, cx - tw / 2, cy - 120)
    love.graphics.setFont(fonts.medium)
    love.graphics.setColor(0.6, 0.6, 0.7, 1)
    local sub = "Shop. Upgrade. Survive."
    local sw = fonts.medium:getWidth(sub)
    love.graphics.print(sub, cx - sw / 2, cy - 80)
    love.graphics.setColor(0.5, 0.5, 0.5, 0.7)
    love.graphics.setFont(fonts.hud)
    local lines = {
        "Dodge bullet patterns. Destroy waves. Buy upgrades between rounds.",
        "",
        "WASD = Move    SHIFT = Focus (precise mode)",
        "MOUSE = Aim    Auto-fire toward cursor",
        "",
        "RNG SHOP between waves  —  spend score on permanent run upgrades",
        "Power-ups drop from enemies  —  bosses always drop something",
    }
    local ly = cy + 50
    for _, line in ipairs(lines) do
        if line == "" then ly = ly + 12
        else
            local lw = fonts.hud:getWidth(line)
            love.graphics.setColor(0.5, 0.5, 0.55, line:find("WASD") and 0.8 or 0.6)
            love.graphics.print(line, cx - lw / 2, ly)
            ly = ly + 18
        end
    end
    love.graphics.setFont(fonts.score)
    local pulse = 0.6 + math.sin(introRot * 3) * 0.4
    love.graphics.setColor(1, 0.85, 0.3, pulse)
    local startText = "Press ENTER or CLICK to start"
    local stw = fonts.score:getWidth(startText)
    love.graphics.print(startText, cx - stw / 2, cy + 220)
end

function drawGameOver()
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, W, H)
    love.graphics.setColor(1, 0.2, 0.2, 1)
    love.graphics.setFont(fonts.gameover)
    local text = "GAME OVER"
    local tw = fonts.gameover:getWidth(text)
    love.graphics.print(text, W / 2 - tw / 2, H / 2 - 60)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(fonts.score)
    local scoreText = "Score: " .. score .. "  |  Wave: " .. wave
    local stw = fonts.score:getWidth(scoreText)
    love.graphics.print(scoreText, W / 2 - stw / 2, H / 2)
    love.graphics.setColor(0.5, 0.5, 0.5, 0.7)
    love.graphics.setFont(fonts.hud)
    local upgText = "Upgrades: " .. tableLength(upgrades)
    local uw = fonts.hud:getWidth(upgText)
    love.graphics.print(upgText, W / 2 - uw / 2, H / 2 + 28)
    love.graphics.setColor(0.7, 0.7, 0.7, 1)
    love.graphics.setFont(fonts.score)
    local restart = "Press ENTER or R to restart"
    local rtw = fonts.score:getWidth(restart)
    love.graphics.print(restart, W / 2 - rtw / 2, H / 2 + 55)
end

function tableLength(t)
    local n = 0
    for _ in pairs(t) do n = n + 1 end
    return n
end

function love.draw()
    love.graphics.setBackgroundColor(0.03, 0.03, 0.06)
    love.graphics.clear(0.03, 0.03, 0.06)

    if state == "intro" then
        drawIntro()
        return
    end

    local sx = (math.random() - 0.5) * shakeAmount
    local sy = (math.random() - 0.5) * shakeAmount
    love.graphics.push()
    love.graphics.translate(sx, sy)

    for _, s in ipairs(stars) do
        love.graphics.setColor(1, 1, 1, s.b)
        love.graphics.circle("fill", s.x, s.y, s.r)
    end

    for _, p in ipairs(particles) do
        local alpha = p.life / p.maxLife
        local pr, pg, pb = hsv(p.hue, 0.8, 0.9)
        love.graphics.setColor(pr, pg, pb, alpha)
        love.graphics.circle("fill", p.x, p.y, p.size * alpha)
    end

    -- Time dilation area
    if upgrades["time_dilation"] and isFocusVisible() then
        love.graphics.setColor(0.2, 0.3, 0.9, 0.05 + math.sin(totalTime * 4) * 0.02)
        love.graphics.circle("fill", player.x, player.y, 120)
        love.graphics.setColor(0.3, 0.5, 1, 0.12)
        love.graphics.circle("line", player.x, player.y, 120)
    end

    -- Slow field aura
    if upgrades["slow_field"] then
        love.graphics.setColor(0.3, 0.3, 0.8, 0.06 + math.sin(totalTime * 3) * 0.02)
        love.graphics.circle("fill", player.x, player.y, 100)
    end

    for _, p in ipairs(pickups) do
        local info = POWER_TYPES[p.type]
        local pr, pg, pb = hsv(info.hue, 0.9, 1)
        love.graphics.setColor(1, 1, 1, 0.12)
        love.graphics.circle("fill", p.x, p.y, p.radius + 6)
        love.graphics.setColor(pr, pg, pb, 1)
        if info.sides == 0 then
            love.graphics.circle("fill", p.x, p.y, p.radius)
        else
            drawShape(p.x, p.y, p.rot, info.sides, p.radius, pr, pg, pb, 1, p.radius * 0.45, 1, 1, 1, 0.5)
        end
        love.graphics.setColor(pr, pg, pb, 0.4)
        love.graphics.circle("line", p.x, p.y, p.radius + 3)
    end

    for _, b in ipairs(pBullets) do
        local pr, pg, pb = 0.3, 0.8, 1
        if getBulletDamage() > 1 then pr, pg, pb = 1, 0.5, 0.1 end
        if b.crit then pr, pg, pb = 1, 0.2, 0.2 end
        if upgrades["bullet_trail"] then
            love.graphics.setColor(pr * 0.4, pg * 0.4, pb * 0.4, 0.3)
            love.graphics.line(b.prevX, b.prevY, b.x, b.y)
        end
        love.graphics.setColor(pr, pg, pb, 1)
        love.graphics.circle("fill", b.x, b.y, b.radius + (getBulletDamage() > 1 and 1 or 0) + (b.crit and 1 or 0))
        love.graphics.setColor(pr * 0.6 + 0.3, pg * 0.6 + 0.3, pb * 0.6 + 0.3, 0.5)
        love.graphics.circle("fill", b.x, b.y, b.radius * 0.5)
    end

    for _, b in ipairs(eBullets) do
        love.graphics.setColor(1, 0.3, 0.2, 0.15)
        love.graphics.line(b.prevX, b.prevY, b.x, b.y)
        love.graphics.setColor(1, 0.3, 0.2, 1)
        love.graphics.circle("fill", b.x, b.y, b.radius)
        love.graphics.setColor(1, 0.7, 0.4, 0.5)
        love.graphics.circle("fill", b.x, b.y, b.radius * 1.8)
    end

    for _, e in ipairs(enemies) do
        local flashCol = (e.flashTimer > 0 and math.floor(e.flashTimer * 30) % 2 == 0)
        local baseColors = {
            shooter  = { 0.9, 0.2, 0.2 },
            spreader = { 1, 0.5, 0.1 },
            spiral   = { 0.5, 0.2, 0.9 },
            zombie   = { 0.2, 0.8, 0.3 },
            boss     = { 0.9, 0.1, 0.4 },
        }
        local bc = baseColors[e.type] or { 1, 1, 1 }
        local efR, efG, efB = flashCol and 1 or bc[1], flashCol and 1 or bc[2], flashCol and 1 or bc[3]

        -- Burn indicator
        if e.burnTimer > 0 then
            local burnAlpha = 0.2 + math.sin(totalTime * 10) * 0.1
            love.graphics.setColor(1, 0.5, 0.1, burnAlpha)
            love.graphics.circle("line", e.x, e.y, e.radius + 4)
        end

        if e.type == "shooter" then
            drawShape(e.x, e.y, 0, 5, e.radius, efR, efG, efB, 1, e.radius * 0.4, 1, 0.4, 0.3, 0.7)
        elseif e.type == "spreader" then
            drawShape(e.x, e.y, waveSpawnTimer * 2, 6, e.radius, efR, efG, efB, 1, e.radius * 0.45, 1, 0.8, 0.3, 0.7)
        elseif e.type == "spiral" then
            drawShape(e.x, e.y, waveSpawnTimer * 3, 8, e.radius, efR, efG, efB, 1, e.radius * 0.5, 0.7, 0.4, 1, 0.7)
        elseif e.type == "zombie" then
            local pulse = 1 + math.sin(waveSpawnTimer * 4) * 0.15
            local zr = e.radius * pulse
            drawShape(e.x, e.y, 0, 4, zr, efR, efG, efB, 1, zr * 0.4, 0.4, 1, 0.5, 0.6)
            love.graphics.setColor(0.4, 1, 0.5, 0.25)
            love.graphics.circle("line", e.x, e.y, zr + 4)
        elseif e.type == "boss" then
            local orot = waveSpawnTimer * 2
            drawShape(e.x, e.y, orot, 6, e.radius, efR, efG, efB, 1, e.radius * 0.5, 1, 0.3, 0.5, 0.8)
            drawShape(e.x, e.y, -orot, 4, e.radius * 0.55, 1, 0.2, 0.3, 0.6)
            love.graphics.setColor(0.3, 0.05, 0.05, 0.5)
            love.graphics.rectangle("fill", e.x - 28, e.y - e.radius - 16, 56, 8, 3, 3)
            local maxHp = 22 + wave * 3
            local hpPct = math.max(0, e.hp / maxHp)
            love.graphics.setColor(hpPct > 0.3 and 1 or 0.8, hpPct > 0.3 and 0.2 or 0.1, 0.1, 1)
            love.graphics.rectangle("fill", e.x - 26, e.y - e.radius - 14, 52 * hpPct, 4, 2, 2)
        end
    end

    -- Drone visual
    if upgrades["drone"] then
        local dx = player.x + math.cos(droneAngle) * 45
        local dy = player.y + math.sin(droneAngle) * 45
        love.graphics.setColor(0.4, 0.9, 1, 0.4)
        love.graphics.line(player.x, player.y, dx, dy)
        drawSmallShip(dx, dy, droneAngle + math.pi / 2, 0.4, 0.9, 1, 0.8, 0.5)
    end

    -- Clone visual
    if cloneData and #cloneData.hist > 15 then
        local old = cloneData.hist[#cloneData.hist - 15]
        if old then
            drawSmallShip(old.x, old.y, old.angle, 0.5, 0.8, 1, 0.25, 1.2)
        end
    end

    -- Score popups
    for _, sp in ipairs(scorePopups) do
        local alpha = sp.life / sp.maxLife
        love.graphics.setFont(fonts.popup)
        love.graphics.setColor(sp.r, sp.g, sp.b, alpha)
        local tw = fonts.popup:getWidth(sp.text)
        love.graphics.print(sp.text, sp.x - tw / 2, sp.y)
    end

    if player.invuln <= 0 or math.floor(player.invuln * 20) % 2 == 0 then
        drawPlayerShape(player.x, player.y, player.aimAngle, 0.2, 0.7, 1, 1)
        if isFocusVisible() then
            love.graphics.setColor(0.6, 1, 1, 0.3)
            love.graphics.circle("line", player.x, player.y, player.visualRadius + 2)
        end
    end

    if isPowerActive("shield") then
        love.graphics.setColor(1, 1, 1, 0.2 + math.sin(waveSpawnTimer * 5) * 0.08)
        love.graphics.circle("line", player.x, player.y, player.visualRadius + 6)
    end

    if waveTimer > 0 and state == "playing" then
        local alpha = waveTimer > 1.3 and (1.5 - waveTimer) / 0.2 or 1
        alpha = math.max(0, math.min(1, alpha))
        love.graphics.setColor(1, 0.8, 0.2, alpha)
        love.graphics.setFont(fonts.wave)
        local text = "WAVE " .. wave
        local tw = fonts.wave:getWidth(text)
        love.graphics.print(text, W / 2 - tw / 2, H / 2 - 18)
    end

    local mx, my = love.mouse.getPosition()
    love.graphics.setColor(0.3, 0.3, 0.3, 0.2)
    love.graphics.setLineWidth(1)
    love.graphics.line(player.x, player.y, mx, my)
    love.graphics.setColor(1, 0.3, 0.3, 0.4)
    love.graphics.circle("line", mx, my, 8)
    love.graphics.line(mx - 12, my, mx - 5, my)
    love.graphics.line(mx + 5, my, mx + 12, my)
    love.graphics.line(mx, my - 12, mx, my - 5)
    love.graphics.line(mx, my + 5, mx, my + 12)

    drawImmersiveHUD()

    if state == "shop" then drawShop() end
    if state == "gameover" then drawGameOver() end

    love.graphics.pop()
end

function isFocusVisible()
    return love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")
end

function love.keypressed(key)
    if key == "f11" then
        local fullscreen = not love.window.getFullscreen()
        love.window.setFullscreen(fullscreen)
    end
    if key == "escape" then love.event.quit() end
    if state == "intro" and (key == "return" or key == "enter") then startGame() end
    if state == "gameover" and (key == "return" or key == "enter" or key == "r") then resetGame() end
    if state == "shop" then
        if key == "1" and #shopItems >= 1 then buyUpgrade(shopItems[1]) end
        if key == "2" and #shopItems >= 2 then buyUpgrade(shopItems[2]) end
        if key == "3" and #shopItems >= 3 then buyUpgrade(shopItems[3]) end
        if key == "4" and #shopItems >= 4 then buyUpgrade(shopItems[4]) end
        if key == "return" or key == "enter" or key == "space" then
            state = "playing"
            startNextWave()
        end
    end
end

function love.mousepressed(x, y, button)
    if state == "intro" and button == 1 then startGame() end
    if state == "gameover" and button == 1 then resetGame() end
end

function love.resize(w, h)
    W, H = w, h
    createFonts()
    stars = {}
    for _ = 1, 80 do
        table.insert(stars, { x = math.random() * W, y = math.random() * H, r = math.random() * 1.5 + 0.5, b = math.random() * 0.5 + 0.5 })
    end
    if player then
        local hr = getHitboxRadius()
        if player.x < hr then player.x = hr end
        if player.x > W - hr then player.x = W - hr end
        if player.y < hr then player.y = hr end
        if player.y > H - hr then player.y = H - hr end
    end
end
