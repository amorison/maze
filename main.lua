function gridxy(mc)
    -- grid position of a maze cell
    local x = (mc.idx - 1) % gs.nx
    local y = (mc.idx - x - 1) / gs.nx
    return x, y
end

function mask(x, y, trsp)
    love.graphics.setColor(0, 0, 0, trsp)
    love.graphics.rectangle('fill', x * gs.dx + gs.ox, y * gs.dy + gs.oy,
                            gs.dx, gs.dy)
    love.graphics.setColor(1, 1, 1, 1)
end

function initMaze()
    gs.ncells = gs.nx * gs.ny
    gs.maze = Maze:new(gs.nx, gs.ny)
    gs.solved = false
    gs.tLastVisit = {}
    for i = 1, gs.ncells do
        gs.tLastVisit[i] = 0
    end
    gs.x = 0
    gs.y = 0
    gs.cc = gs.maze[1]  -- holds cell where player is

    gs.lyr.ground:clear()
    gs.lyr.solve:clear()
    gs.lyr.bridge:clear()
    gs.lyr.bsolve:clear()
    gs.lyr.hero:clear()
    for icell = 1, gs.ncells do
        local mc = gs.maze[icell]
        local x, y = gridxy(mc)
        gs.lyr.ground:add(getSprite(mc), x * gs.dx, y * gs.dy)
    end
    for icell = gs.ncells + 1, #gs.maze do
        local mc = gs.maze[icell]
        local x, y = gridxy(mc)
        gs.lyr.bridge:add(getSprite(mc), x * gs.dx, y * gs.dy)
    end

    local idh = gs.lyr.hero:add(getSpriteHero(gs.cc), 0, 0)
    function setHero()
        gs.lyr.hero:set(idh, getSpriteHero(gs.cc), gs.x, gs.y)
    end
end

function love.load()
    require('Maze')
    gs = {}  -- game state namespace
    local sprites = love.graphics.newImage('sprites/digital.png')
    gs.dx = sprites:getWidth() / 5
    gs.dy = sprites:getHeight() / 6
    gs.nx = 10
    gs.ny = 10
    gs.ox = 0
    gs.oy = 0

    love.window.setTitle('Amazing maze')
    love.mouse.setVisible(false)
    love.window.setMode(gs.nx * gs.dx, gs.ny * gs.dy,
                        {resizable=true, minwidth=3*gs.dx, minheight=3*gs.dy})
    gs.tr = love.math.newTransform()

    local function nquad(col, row)
        return love.graphics.newQuad(col * gs.dx, row * gs.dy,
            gs.dx, gs.dy, sprites:getDimensions())
    end
    local sp = {}
    for i = 0, 4 do
        for j = 0, 2 do
            sp[(i+1)+j*5] = nquad(i, j)
        end
    end

    local spHero = {}
    spHero[false] = nquad(2, 3)
    spHero[true] = nquad(3, 3)

    local bridges = {}
    bridges[5] = nquad(0, 3)
    bridges[10] = nquad(1, 3)
    local spSolve = {}
    for i = 0, 4 do
        for j = 0, 1 do
            spSolve[(i+1)+j*5] = nquad(i, j + 4)
        end
    end

    function getSprite(mc)
        local score = 0
        if mc.linked.left then
            score = 1 end
        if mc.linked.down then
            score = score + 2 end
        if mc.linked.right then
            score = score + 4 end
        if mc.linked.up then
            score = score + 8 end
        if mc.isbridge then
            return bridges[score]
        else
            return sp[score]
        end
    end

    function getSpriteHero(mc)
        return spHero[mc.bridged ~= nil]
    end

    function getSpriteSolve(mc, mcb, mca)
        -- current cell, cell before, cell after
        -- in the solution path
        local score = 0
        local lefty = false
        for _, nc in pairs{mcb, mca} do
            if nc == mc.linked.left then
                score = score + 1
                lefty = true
            elseif nc == mc.linked.down then
                score = score + 2
            elseif nc == mc.linked.right then
                score = score + 3
            elseif nc == mc.linked.up then
                score = score + 4
            end
        end
        if mcb and mca then
            score = score + (lefty and 2 or 3)
        end
        return spSolve[score]
    end

    gs.lyr = {}  -- spritebatch layers
    gs.lyr.ground = love.graphics.newSpriteBatch(sprites)
    gs.lyr.solve = love.graphics.newSpriteBatch(sprites)
    gs.lyr.bridge = love.graphics.newSpriteBatch(sprites)
    gs.lyr.bsolve = love.graphics.newSpriteBatch(sprites)
    gs.lyr.hero = love.graphics.newSpriteBatch(sprites)

    gs.memory = true

    initMaze()
end

function love.update(dt)
    local xT, yT = gridxy(gs.cc)
    xT = xT * gs.dx
    yT = yT * gs.dy
    local atTarget = gs.x == xT and gs.y == yT
    if love.keyboard.isDown('right') and atTarget and gs.cc.linked.right then
        xT = xT + gs.dx
        gs.cc = gs.cc.linked.right
        gs.solved = false
    elseif love.keyboard.isDown('left') and atTarget and gs.cc.linked.left then
        xT = xT - gs.dx
        gs.cc = gs.cc.linked.left
        gs.solved = false
    elseif love.keyboard.isDown('down') and atTarget and gs.cc.linked.down then
        yT = yT + gs.dy
        gs.cc = gs.cc.linked.down
        gs.solved = false
    elseif love.keyboard.isDown('up') and atTarget and gs.cc.linked.up then
        yT = yT - gs.dy
        gs.cc = gs.cc.linked.up
        gs.solved = false
    end

    if math.abs(gs.x - xT) < 1 and math.abs(gs.y - yT) < 1 then
        gs.x = xT
        gs.y = yT
    else
        gs.x = gs.x + (xT - gs.x) * 30 * dt
        gs.y = gs.y + (yT - gs.y) * 30 * dt
    end
    setHero()
end

function love.draw()
    love.graphics.draw(gs.lyr.ground, gs.tr)
    love.graphics.draw(gs.lyr.solve, gs.tr)
    love.graphics.draw(gs.lyr.bridge, gs.tr)
    love.graphics.draw(gs.lyr.bsolve, gs.tr)
    love.graphics.draw(gs.lyr.hero, gs.tr)
    local time = love.timer.getTime()
    gs.tLastVisit[gs.cc.idx] = time
    if gs.memory then
        for i = 1, gs.ncells do
            local x, y = gridxy(gs.maze[i])
            local etrsp = (time - gs.tLastVisit[i]) / 4
            mask(x, y, (etrsp < 1 and etrsp or 1))
        end
    end
end

function love.keyreleased(key)
    if key == 's' then
        if gs.solved then
            gs.lyr.solve:clear()
            gs.lyr.bsolve:clear()
            gs.solved = false
        else
            local path_out = gs.maze:solve(gs.cc)
            gs.lyr.solve:clear()
            gs.lyr.bsolve:clear()
            for i, cell in ipairs(path_out) do
                local xc, yc = gridxy(cell)
                local sprt = getSpriteSolve(cell, path_out[i-1], path_out[i+1])
                if cell.isbridge then
                    gs.lyr.bsolve:add(sprt, xc * gs.dx, yc * gs.dy)
                else
                    gs.lyr.solve:add(sprt, xc * gs.dx, yc * gs.dy)
                end
            end
            gs.memory = false
            gs.solved = true
        end
    end
    if key == 'v' then
        gs.memory = not gs.memory
        if gs.memory then
            gs.lyr.solve:clear()
            gs.lyr.bsolve:clear()
            gs.solved = false
        end
    end
    if key == 'right' and gs.cc.idx == gs.ncells then
        initMaze()
    end
end

function love.resize(width, height)
    local nxNew = math.floor(width / gs.dx)
    local nyNew = math.floor(height / gs.dy)
    if nxNew ~= gs.nx or nyNew ~= gs.ny then
        gs.nx = nxNew
        gs.ny = nyNew
        initMaze()
    end
    gs.ox = math.floor((width - nxNew * gs.dx) / 2)
    gs.oy = math.floor((height - nyNew * gs.dy) / 2)
    gs.tr:reset():translate(gs.ox, gs.oy)
end
