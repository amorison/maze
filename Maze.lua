Maze = {}
function Maze:new(nx, nz)
    local maze = {}
    maze.nx = nx or 10
    maze.nz = nz or 10
    setmetatable(maze, self)
    self.__index = self
    maze:compute()
    return maze
end

function Maze:compute()
    -- Maze generation with backtracking, using a FIFO stack.
    -- Bridges over existing corridors are allowed.

    local freeCells = self.nx * self.nz
    math.randomseed(os.time())
    local otherDir = {up='down', down='up', right='left', left='right'}

    for i = 1, freeCells do
        self[i] = {idx=i, free=true, linked={}}
    end

    for i, cell in ipairs(self) do
        cell.up = self[i - self.nx]
        cell.down = self[i + self.nx]
        if (i - 1) % self.nx ~= 0 then
            cell.left = self[i - 1]
        end
        if i % self.nx ~= 0 then
            cell.right = self[i + 1]
        end
    end
    self[freeCells].up.down = nil
    self[freeCells].up = nil

    -- definition of the FIFO stack
    local stack = {first=0,last=-1}
    function stack.push(val)
        stack.last = stack.last+1
        stack[stack.last] = val
    end
    function stack.pop()
        local val = stack[stack.first]
        stack[stack.first] = nil
        stack.first = stack.first+1
        return val
    end

    -- here begins the serious stuff
    local cc = self[1]  -- start exploring from first cell
    cc.free = false
    freeCells = freeCells-1
    while freeCells~=0 do
        -- make a list of accessible neighbors
        local neighbor = {}
        for direc, other in pairs(otherDir) do
            -- close neighbors
            local nc = cc[direc]
            if nc and nc.free then
                table.insert(neighbor, {direc, nc})
            end
            -- neighbors reachable with a bridge
            local ncb = nc and nc[direc]
            if ncb and not nc.free and ncb.free and
                not nc.linked[direc] and
                not nc.linked[other] then
                table.insert(neighbor, {direc, ncb})
            end
        end

        if #neighbor > 0 then
            -- choose a neighbor
            local nb = neighbor[math.random(#neighbor)]
            local dir = nb[1]
            local nc = nb[2]
            -- make the link
            if cc[dir] == nc then
                cc.linked[dir] = nc
                nc.linked[otherDir[dir]] = cc
            else  -- this is a bridge, held in new artifical cell
                local bc = {}
                table.insert(self, bc)
                bc.isbridge = true
                cc[dir].bridged = bc
                bc.idx = cc[dir].idx
                bc.linked = {}
                cc.linked[dir] = bc
                bc.linked[dir] = nc
                nc.linked[otherDir[dir]] = bc
                bc.linked[otherDir[dir]] = cc
            end
            -- chosen neighbor become current cell
            stack.push(cc)
            cc = nc
            cc.free = false
            freeCells = freeCells-1
        else
            -- if no reachable neighbor,
            -- open a new way from a previous cell
            cc = stack.pop()
        end
    end
end

function Maze:solve(cc)
    -- solve the maze starting at an arbitrary position
    local ncells = self.nx * self.nz  -- exit
    local wayout = {{cc}}
    local stack = {}
    local last_move = ''  -- make sure not to go back
    while not (cc.idx == ncells) do
        local dir_score = 0
        if cc.linked.up and last_move ~= 'down' then
            dir_score = dir_score + 1
        end
        if cc.linked.left and last_move ~= 'right' then
            dir_score = dir_score + 2
        end
        if cc.linked.down and last_move ~= 'up' then
            dir_score = dir_score + 4
        end
        if cc.linked.right and last_move ~= 'left' then
            dir_score = dir_score + 8
        end
        if dir_score == 0 then
            local popstack = table.remove(stack)
            cc = popstack[1]
            dir_score = popstack[2]
            table.remove(wayout)
        end

        if dir_score >= 8 then
            dir_score = dir_score - 8
            last_move = 'right'
        elseif dir_score >= 4 then
            dir_score = dir_score - 4
            last_move = 'down'
        elseif dir_score >= 2 then
            dir_score = dir_score - 2
            last_move = 'left'
        elseif dir_score >= 1 then
            dir_score = dir_score - 1
            last_move = 'up'
        end
        if dir_score > 0 then
            table.insert(stack, {cc, dir_score})
            table.insert(wayout, {})
        end
        cc = cc.linked[last_move]
        table.insert(wayout[#wayout], cc)
    end
    -- flatten wayout
    local wayout_flat = {}
    for _, path in ipairs(wayout) do
        for _, cell in ipairs(path) do
            table.insert(wayout_flat, cell)
        end
    end
    return wayout_flat
end
