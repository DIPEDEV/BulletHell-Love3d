-- ============================================================
-- BULLET HELL - RNG Shop, upgrade tree, immersive UI
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

local fonts = {}

local POWER_TYPES = {
    spread  = { name = "SPREAD",  hue = 0.14, sides = 4 },
    rapid   = { name = "RAPID",   hue = 0.55, sides = 3 },
    shield  = { name = "SHIELD",  hue = 0.0,  sides = 6 },
    score2x = { name = "2X SCR",  hue = 0.45, sides = 5 },
    speed   = { name = "SPEED",   hue = 0.33, sides = 0 },
}

local UPGRADE_DEFS = {
    rapid_fire   = { name = "RAPID FIRE",  branch = "weapon",  cost = 250, prereq = nil,            icon = { sides = 3, hue = 0.08 }, rarity = 1 },
    double_shot  = { name = "DOUBLE SHOT",  branch = "weapon",  cost = 500, prereq = "rapid_fire",   icon = { sides = 3, hue = 0.12 }, rarity = 2 },
    triple_shot  = { name = "TRIPLE SHOT",  branch = "weapon",  cost = 750, prereq = "double_shot",  icon = { sides = 3, hue = 0.16 }, rarity = 3 },
    heavy_bullet = { name = "HVY BULLETS",  branch = "weapon",  cost = 350, prereq = nil,            icon = { sides = 4, hue = 0.0  }, rarity = 1 },
    piercing     = { name = "PIERCING",     branch = "weapon",  cost = 600, prereq = "heavy_bullet", icon = { sides = 4, hue = 0.03 }, rarity = 2 },
    extra_life   = { name = "EXTRA LIFE",   branch = "char",    cost = 400, prereq = nil,            icon = { sides = 5, hue = 0.35 }, rarity = 1 },
    fast_feet    = { name = "FAST FEET",    branch = "char",    cost = 300, prereq = nil,            icon = { sides = 5, hue = 0.55 }, rarity = 1 },
    magnet       = { name = "MAGNET",       branch = "char",    cost = 250, prereq = nil,            icon = { sides = 6, hue = 0.6  }, rarity = 1 },
    shield_core  = { name = "SHIELD CORE",  branch = "char",    cost = 500, prereq = "magnet",       icon = { sides = 6, hue = 0.0  }, rarity = 2 },
    tiny_hitbox  = { name = "TINY HITBOX",  branch = "char",    cost = 500, prereq = "fast_feet",    icon = { sides = 5, hue = 0.5  }, rarity = 2 },
    score_boost  = { name = "SCORE BOOST",  branch = "util",    cost = 300, prereq = nil,            icon = { sides = 0, hue = 0.45 }, rarity = 1 },
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

function love.load()
    W, H = love.graphics.getDimensions()
    fonts.title    = love.graphics.newFont(52)
    fonts.wave     = love.graphics.newFont(36)
    fonts.hud      = love.graphics.newFont(13)
    fonts.hudBig   = love.graphics.newFont(18)
    fonts.gameover = love.graphics.newFont(48)
    fonts.score    = love.graphics.newFont(20)
    fonts.medium   = love.graphics.newFont(16)
    fonts.shop     = love.graphics.newFont(15)
    fonts.shopBig  = love.graphics.newFont(28)
    fonts.tiny     = love.graphics.newFont(11)
    resetGame()
end

function resetGame()
    state = "intro"
    introRot = 0; introTimer = 0; introParticles = {}
    shopItems = {}
    upgrades = {}
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
    powerTimers = {}
    wave = 0; waveTimer = 0; waveActive = false
    waveSpawnQueue = {}; waveSpawnTimer = 0
    score = 0; shakeAmount = 0; totalTime = 0
    for _ = 1, 80 do
        table.insert(stars, { x = math.random() * W, y = math.random() * H, r = math.random() * 1.5 + 0.5, b = math.random() * 0.5 + 0.5 })
    end
end

function startGame()
    state = "playing"
    startNextWave()
end

function startNextWave()
    wave = wave + 1
    waveTimer = 1.5
    waveActive = false
    waveSpawnQueue = {}
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
        powerTimers["shield"] = 8
    end
end

function openShop()
    state = "shop"
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
        for _ = 1, UPGRADE_DEFS[id].rarity + 1 do
            table.insert(pool, id)
        end
    end
    local used = {}
    for _ = 1, math.min(3, #eligible) do
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
    if score < def.cost then return end
    score = score - def.cost
    upgrades[id] = true
    if id == "extra_life" then
        player.maxLives = math.min(player.maxLives + 1, 8)
        player.lives = math.min(player.lives + 1, player.maxLives)
    end
end

local isPowerActive

local function getBulletDamage()
    return upgrades["heavy_bullet"] and 2 or 1
end

local function getBulletPierce()
    return upgrades["piercing"] and 1 or 0
end

local function getBulletCount()
    if upgrades["triple_shot"] then return 3
    elseif upgrades["double_shot"] then return 2
    else return 1 end
end

local function getShootRate()
    local r = player.shootRate
    if upgrades["rapid_fire"] then r = r * 0.55 end
    if isPowerActive("rapid") then r = r * 0.5 end
    return r
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
    table.insert(enemies, e)
end

local function addEBullet(x, y, angle, speedRatio)
    local spd = 200 + (wave * 12)
    spd = math.min(spd, 380)
    spd = spd * (speedRatio or 1)
    table.insert(eBullets, {
        x = x, y = y,
        vx = math.cos(angle) * spd,
        vy = math.sin(angle) * spd,
        radius = 3.5,
    })
end

local function addPBullet(x, y, angle)
    table.insert(pBullets, {
        x = x, y = y,
        vx = math.cos(angle) * 700,
        vy = math.sin(angle) * 700,
        radius = 2.0,
        dmg = getBulletDamage(),
        pierce = getBulletPierce(),
        hitEnemies = {},
    })
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

isPowerActive = function(ptype)
    return powerTimers[ptype] and powerTimers[ptype] > 0
end

local function applyPower(ptype)
    powerTimers[ptype] = 8
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

local function killEnemy(e, wasZombieContact)
    local hue = 0
    local points = 0
    if e.type == "shooter" then hue = 0.05; points = 150
    elseif e.type == "spreader" then hue = 0.12; points = 300
    elseif e.type == "spiral" then hue = 0.55; points = 400
    elseif e.type == "zombie" then hue = 0.3; points = 200
    elseif e.type == "boss" then hue = 0.0; points = 1500 end

    if isPowerActive("score2x") then points = points * 2 end
    if upgrades["score_boost"] then points = math.floor(points * 1.25) end
    score = score + points

    addParticle(e.x, e.y, 12, hue, 1)
    shakeAmount = math.max(shakeAmount, e.type == "boss" and 8 or (e.type == "zombie" and 5 or 2))

    if not wasZombieContact then
        local dropChance = e.type == "boss" and 1.0 or 0.18
        if math.random() < dropChance then
            spawnPickup(e.x, e.y)
        end
    end
end

local function hitPlayer()
    if player.invuln > 0 then return end
    if isPowerActive("shield") then
        powerTimers["shield"] = 0
        addParticle(player.x, player.y, 15, 0.0, 1.2)
        player.invuln = 1.0
        shakeAmount = 3
        return
    end
    player.lives = player.lives - 1
    player.invuln = 2.0
    addParticle(player.x, player.y, 20, 0.0, 1.5)
    shakeAmount = 6
    if player.lives <= 0 then
        state = "gameover"
        addParticle(player.x, player.y, 40, 0.0, 2)
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

    if player.shootCd <= 0 then
        local rate = getShootRate()
        local count = getBulletCount()
        local a = player.aimAngle
        if count == 3 then
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
        player.shootCd = rate
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
            local bonus = wave * 500
            if isPowerActive("score2x") then bonus = bonus * 2 end
            if upgrades["score_boost"] then bonus = math.floor(bonus * 1.25) end
            score = score + bonus
            waveActive = false
            openShop()
        end
    end

    for _, e in ipairs(enemies) do
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

    for _, b in ipairs(eBullets) do b.x = b.x + b.vx * dt; b.y = b.y + b.vy * dt end
    for _, b in ipairs(pBullets) do b.x = b.x + b.vx * dt; b.y = b.y + b.vy * dt end

    local pRad = getPickupRadius()
    for i = #pickups, 1, -1 do
        local p = pickups[i]
        p.y = p.y + p.vy * dt
        p.rot = p.rot + dt * 3
        if p.y > H + 20 then
            table.remove(pickups, i)
        elseif dist(p.x, p.y, player.x, player.y) < pRad + p.radius then
            applyPower(p.type)
            addParticle(p.x, p.y, 8, POWER_TYPES[p.type].hue, 0.8)
            table.remove(pickups, i)
        end
    end

    local hitboxR = getHitboxRadius()
    for i = #eBullets, 1, -1 do
        local b = eBullets[i]
        if b.x < -30 or b.x > W + 30 or b.y < -30 or b.y > H + 30 then
            table.remove(eBullets, i)
        elseif player.invuln <= 0 and dist(b.x, b.y, player.x, player.y) < hitboxR + b.radius then
            hitPlayer()
            table.remove(eBullets, i)
        end
    end

    for i = #pBullets, 1, -1 do
        local b = pBullets[i]
        if b.x < -10 or b.x > W + 10 or b.y < -10 or b.y > H + 10 then
            table.remove(pBullets, i)
        else
            local hit = false
            for j = #enemies, 1, -1 do
                local e = enemies[j]
                if not b.hitEnemies[e] and dist(b.x, b.y, e.x, e.y) < e.radius + b.radius then
                    e.hp = e.hp - b.dmg
                    b.hitEnemies[e] = true
                    if e.hp <= 0 then
                        killEnemy(e, false)
                        table.remove(enemies, j)
                    else
                        addParticle(b.x, b.y, 3, 0.0, 0.5)
                    end
                    b.pierce = b.pierce - 1
                    if b.pierce < 0 then
                        hit = true
                        break
                    end
                end
            end
            if hit then table.remove(pBullets, i) end
        end
    end

    for i = #enemies, 1, -1 do
        if enemies[i].y > H + 50 then table.remove(enemies, i) end
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
    -- Top bar background
    love.graphics.setColor(0.03, 0.03, 0.05, 0.9)
    love.graphics.rectangle("fill", 0, 0, W, 52)

    love.graphics.setColor(0.15, 0.15, 0.22, 0.8)
    love.graphics.rectangle("fill", 0, 51, W, 1)

    -- Score icon + number (left)
    love.graphics.setColor(1, 0.85, 0.3, 1)
    drawShape(22, 22, totalTime * 2, 4, 8, 1, 0.85, 0.3, 1, 3, 0.9, 0.7, 0.2, 0.7)
    love.graphics.setFont(fonts.hudBig)
    love.graphics.setColor(1, 0.9, 0.5, 1)
    love.graphics.print(tostring(score), 34, 16)

    -- Separator
    love.graphics.setColor(0.2, 0.2, 0.3, 0.6)
    love.graphics.rectangle("fill", 110, 8, 1, 36)

    -- Wave indicator (center-left)
    local waveX = 130
    love.graphics.setColor(0.6, 0.5, 0.8, 0.7)
    love.graphics.circle("line", waveX + 14, 26, 12)
    love.graphics.circle("line", waveX + 14, 26, 6)
    love.graphics.setFont(fonts.hudBig)
    love.graphics.setColor(1, 0.8, 0.3, 1)
    love.graphics.print("W" .. wave, waveX + 32, 16)

    -- Enemy count
    love.graphics.setColor(0.8, 0.3, 0.3, 0.7)
    love.graphics.setFont(fonts.hud)
    love.graphics.print("#" .. #enemies, waveX + 100, 20)

    -- Center: active upgrades as small icons
    local ux = W / 2 - 30
    local ucount = 0
    for id, _ in pairs(upgrades) do
        local def = UPGRADE_DEFS[id]
        if def then
            local r, g, b = hsv(def.icon.hue, 0.8, 0.9)
            love.graphics.setColor(0.05, 0.05, 0.08, 0.7)
            love.graphics.rectangle("fill", ux + ucount * 30, 32, 24, 16, 3, 3)
            drawShape(ux + ucount * 30 + 12, 40, 0, def.icon.sides, 6, r, g, b, 1)
            ucount = ucount + 1
            if ucount > 5 then break end
        end
    end

    -- Lives (right)
    local lx = W - 18
    for i = 1, player.lives do
        drawSmallShip(lx, 12, -math.pi / 2, 0.2, 0.7, 1, 0.9, 0.8)
        lx = lx - 22
    end
    love.graphics.setColor(0.5, 0.5, 0.5, 0.5)
    love.graphics.setFont(fonts.tiny)
    love.graphics.print("HP", W - 20 - player.lives * 22, 2)

    -- Active power timers below HUD
    local py = 54
    local activeList = {}
    for k, t in pairs(powerTimers) do
        if t > 0 then table.insert(activeList, { type = k, timer = t }) end
    end
    if #activeList > 0 then
        local px = 10
        for _, a in ipairs(activeList) do
            local info = POWER_TYPES[a.type]
            local r, g, b = hsv(info.hue, 0.8, 0.9)
            local barW = 80 * (a.timer / 8)
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
end

function drawShop()
    -- Darken background
    love.graphics.setColor(0.02, 0.02, 0.04, 0.85)
    love.graphics.rectangle("fill", 0, 0, W, H)

    -- Title
    love.graphics.setFont(fonts.shopBig)
    love.graphics.setColor(1, 0.85, 0.3, 1)
    local title = "UPGRADE STATION"
    local tw = fonts.shopBig:getWidth(title)
    love.graphics.print(title, W / 2 - tw / 2, 40)

    love.graphics.setColor(0.5, 0.5, 0.5, 0.6)
    love.graphics.setFont(fonts.hud)
    local sub = "Spend score to enhance your ship"
    local sw = fonts.hud:getWidth(sub)
    love.graphics.print(sub, W / 2 - sw / 2, 72)

    -- Cards
    local cardW = 180
    local cardH = 240
    local spacing = 24
    local totalW = #shopItems * cardW + (#shopItems - 1) * spacing
    local startX = W / 2 - totalW / 2
    local cardY = 110

    for i, id in ipairs(shopItems) do
        local cx = startX + (i - 1) * (cardW + spacing)
        local def = UPGRADE_DEFS[id]
        local r, g, b = hsv(def.icon.hue, 0.8, 0.9)
        local highlight = shopSelect == i

        -- Card shadow
        love.graphics.setColor(0, 0, 0, 0.4)
        love.graphics.rectangle("fill", cx + 3, cardY + 3, cardW, cardH, 8, 8)

        -- Card bg
        if highlight then
            love.graphics.setColor(0.2, 0.18, 0.12, 0.95)
        else
            love.graphics.setColor(0.08, 0.08, 0.12, 0.92)
        end
        love.graphics.rectangle("fill", cx, cardY, cardW, cardH, 8, 8)

        -- Card border
        love.graphics.setColor(highlight and 1 or 0.3, highlight and 0.8 or 0.25, highlight and 0.2 or 0.2, highlight and 0.8 or 0.4)
        love.graphics.rectangle("line", cx, cardY, cardW, cardH, 8, 8)

        -- Rarity indicator
        local rarityColors = { {0.4, 0.4, 0.5}, {0.2, 0.6, 0.8}, {0.8, 0.4, 1} }
        local rc = rarityColors[def.rarity] or rarityColors[1]
        love.graphics.setColor(rc[1], rc[2], rc[3], 0.5)
        love.graphics.rectangle("fill", cx + 6, cardY + 6, cardW - 12, 3, 2, 2)

        -- Branch label
        love.graphics.setFont(fonts.tiny)
        love.graphics.setColor(0.5, 0.5, 0.6, 0.7)
        local branchLabel = def.branch == "weapon" and "WEAPON" or (def.branch == "char" and "BODY" or "UTILITY")
        love.graphics.print(branchLabel, cx + cardW / 2 - fonts.tiny:getWidth(branchLabel) / 2, cardY + 16)

        -- Icon
        local iconSize = 28
        love.graphics.setColor(r * 0.15, g * 0.15, b * 0.15, 0.6)
        love.graphics.circle("fill", cx + cardW / 2, cardY + 80, iconSize + 10)
        drawShape(cx + cardW / 2, cardY + 80, totalTime * 2 + i, def.icon.sides, iconSize, r, g, b, 1, iconSize * 0.45, 1, 1, 1, 0.4)

        -- Name
        love.graphics.setFont(fonts.shop)
        love.graphics.setColor(1, 1, 1, 1)
        local nw = fonts.shop:getWidth(def.name)
        love.graphics.print(def.name, cx + cardW / 2 - nw / 2, cardY + 120)

        -- Cost
        love.graphics.setColor(1, 0.85, 0.3, score >= def.cost and 1 or 0.35)
        drawShape(cx + cardW / 2 - 22, cardY + 165, 0, 4, 7, 1, 0.85, 0.3, 1, 3, 0.9, 0.7, 0.2, 0.6)
        love.graphics.setFont(fonts.hudBig)
        local costStr = tostring(def.cost)
        local cw = fonts.hudBig:getWidth(costStr)
        love.graphics.print(costStr, cx + cardW / 2 - cw / 2 + 6, cardY + 157)

        -- Prerequisite
        if def.prereq and not upgrades[def.prereq] then
            love.graphics.setFont(fonts.tiny)
            love.graphics.setColor(0.7, 0.3, 0.3, 0.8)
            local preq = "Need: " .. UPGRADE_DEFS[def.prereq].name
            local pw = fonts.tiny:getWidth(preq)
            love.graphics.print(preq, cx + cardW / 2 - pw / 2, cardY + 195)
        elseif upgrades[id] then
            love.graphics.setFont(fonts.tiny)
            love.graphics.setColor(0.3, 0.8, 0.3, 0.8)
            local owned = "OWNED"
            love.graphics.print(owned, cx + cardW / 2 - fonts.tiny:getWidth(owned) / 2, cardY + 195)
        end

        -- Key hint
        love.graphics.setFont(fonts.hud)
        love.graphics.setColor(0.5, 0.5, 0.5, 0.7)
        local keyH = "[" .. i .. "]"
        love.graphics.print(keyH, cx + cardW / 2 - fonts.hud:getWidth(keyH) / 2, cardY + cardH - 25)
    end

    -- Footer
    love.graphics.setFont(fonts.hud)
    love.graphics.setColor(0.5, 0.5, 0.6, 0.7)
    local footer = "Press 1-3 to buy  |  ENTER / SPACE to skip  |  Score: " .. score
    local fw = fonts.hud:getWidth(footer)
    love.graphics.print(footer, W / 2 - fw / 2, cardY + cardH + 30)
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

    for _, p in ipairs(pickups) do
        local info = POWER_TYPES[p.type]
        local r, g, b = hsv(info.hue, 0.9, 1)
        love.graphics.setColor(1, 1, 1, 0.12)
        love.graphics.circle("fill", p.x, p.y, p.radius + 6)
        love.graphics.setColor(r, g, b, 1)
        if info.sides == 0 then
            love.graphics.circle("fill", p.x, p.y, p.radius)
        else
            drawShape(p.x, p.y, p.rot, info.sides, p.radius, r, g, b, 1, p.radius * 0.45, 1, 1, 1, 0.5)
        end
        love.graphics.setColor(r, g, b, 0.4)
        love.graphics.circle("line", p.x, p.y, p.radius + 3)
    end

    for _, b in ipairs(pBullets) do
        local pr, pg, pb = 0.3, 0.8, 1
        if getBulletDamage() > 1 then pr, pg, pb = 1, 0.5, 0.1 end
        love.graphics.setColor(pr, pg, pb, 1)
        love.graphics.circle("fill", b.x, b.y, b.radius + (getBulletDamage() > 1 and 1 or 0))
        love.graphics.setColor(pr * 0.6 + 0.3, pg * 0.6 + 0.3, pb * 0.6 + 0.3, 0.5)
        love.graphics.circle("fill", b.x, b.y, b.radius * 0.5)
    end

    for _, b in ipairs(eBullets) do
        love.graphics.setColor(1, 0.3, 0.2, 1)
        love.graphics.circle("fill", b.x, b.y, b.radius)
        love.graphics.setColor(1, 0.7, 0.4, 0.5)
        love.graphics.circle("fill", b.x, b.y, b.radius * 1.8)
    end

    for _, e in ipairs(enemies) do
        if e.type == "shooter" then
            drawShape(e.x, e.y, 0, 5, e.radius, 0.9, 0.2, 0.2, 1, e.radius * 0.4, 1, 0.4, 0.3, 0.7)
        elseif e.type == "spreader" then
            drawShape(e.x, e.y, waveSpawnTimer * 2, 6, e.radius, 1, 0.5, 0.1, 1, e.radius * 0.45, 1, 0.8, 0.3, 0.7)
        elseif e.type == "spiral" then
            drawShape(e.x, e.y, waveSpawnTimer * 3, 8, e.radius, 0.5, 0.2, 0.9, 1, e.radius * 0.5, 0.7, 0.4, 1, 0.7)
        elseif e.type == "zombie" then
            local pulse = 1 + math.sin(waveSpawnTimer * 4) * 0.15
            local zr = e.radius * pulse
            drawShape(e.x, e.y, 0, 4, zr, 0.2, 0.8, 0.3, 1, zr * 0.4, 0.4, 1, 0.5, 0.6)
            love.graphics.setColor(0.4, 1, 0.5, 0.25)
            love.graphics.circle("line", e.x, e.y, zr + 4)
        elseif e.type == "boss" then
            local orot = waveSpawnTimer * 2
            drawShape(e.x, e.y, orot, 6, e.radius, 0.9, 0.1, 0.4, 1, e.radius * 0.5, 1, 0.3, 0.5, 0.8)
            drawShape(e.x, e.y, -orot, 4, e.radius * 0.55, 1, 0.2, 0.3, 0.6)
            love.graphics.setColor(0.3, 0.05, 0.05, 0.5)
            love.graphics.rectangle("fill", e.x - 28, e.y - e.radius - 16, 56, 8, 3, 3)
            local maxHp = 22 + wave * 3
            local hpPct = math.max(0, e.hp / maxHp)
            love.graphics.setColor(hpPct > 0.3 and 1 or 0.8, hpPct > 0.3 and 0.2 or 0.1, 0.1, 1)
            love.graphics.rectangle("fill", e.x - 26, e.y - e.radius - 14, 52 * hpPct, 4, 2, 2)
        end
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
    if key == "escape" then love.event.quit() end
    if state == "intro" and (key == "return" or key == "enter") then startGame() end
    if state == "gameover" and (key == "return" or key == "enter" or key == "r") then resetGame() end
    if state == "shop" then
        if key == "1" and #shopItems >= 1 then buyUpgrade(shopItems[1]) end
        if key == "2" and #shopItems >= 2 then buyUpgrade(shopItems[2]) end
        if key == "3" and #shopItems >= 3 then buyUpgrade(shopItems[3]) end
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
end
