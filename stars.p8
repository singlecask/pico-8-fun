pico-8 cartridge // http://www.pico-8.com
version 27
__lua__

-- constants
maxSpeed = 5
turnRate = 0x0.02           -- use hex fractions to ensure they work with fixed-point numbers
acceleration = 0x0.008      -- use hex fractions to ensure they work with fixed-point numbers
deceleration = 0x0.004      -- use hex fractions to ensure they work with fixed-point numbers
starDirectionOffset = -0.5  -- opposite direction to ship
shipDirectionOffset = -0.25 -- ship starts pointing right
transparentCol = 15         -- color to treat as transparent for sprite rotation

function _init()
    -- initialise stars
    nStars = 20
    stars = {}
    for i = 1,nStars do
        stars[i] = {}
        stars[i].x = flr(rnd(128))  -- x-coord
        stars[i].y = flr(rnd(128))  -- y-coord
        stars[i].z = 1+flr(rnd(10)) -- z-coord (sort-of)
        stars[i].d = flr(rnd(5))    -- diameter
        stars[i].c = 1+flr(rnd(15)) -- colour
    end

    -- sort by z-coord (so that 'nearer' stars are rendered after 'further' stars, and thus drawn 'on top' of them)
    for i=2,#stars do
        local j=i
        while j > 1 and stars[j].z < stars[j-1].z do
            stars[j], stars[j-1] = stars[j-1], stars[j]
            j -= 1
        end
    end

    -- set initial speed and direction
    speed = 0
    direction = 0

    -- flags for which thrusters are firing
    leftThruster = false
    centreThruster = false
    rightThruster = false
end

function _update()
    -- update direction and velocity based on key presses
    if btn(0) then direction += turnRate end
    if btn(1) then direction -= turnRate end
    if btn(2) then
        if speed < maxSpeed then speed += acceleration end
    else
        if speed > 0 then speed -= deceleration end
    end

    -- flag thrusters
    leftThruster = btn(1)
    rightThruster = btn(0)
    centreThruster = btn(2)
    
    -- work out deltas
    local dx = speed * cos(direction+starDirectionOffset)
    local dy = speed * sin(direction+starDirectionOffset)

    -- update each star
    for i = 1,#stars do
        -- apply deltas
        stars[i].x += dx * stars[i].z
        stars[i].y += dy * stars[i].z

        -- wrap any stars that are off-screen
        local radius = stars[i].d/2
        local min = -radius
        local max = 127 + radius
        if stars[i].x > max then
            stars[i].x = min
        elseif stars[i].x < min then
            stars[i].x = max
        end
        if stars[i].y > max then
            stars[i].y = min
        elseif stars[i].y < min then
            stars[i].y = max
        end
    end
end

function _draw()
    -- clear screen
    cls()

    -- -- draw some stars to check scales
    -- for i = 0,6 do
    --     circfill_dia(i*12, 10, i, 3)
    -- end

    -- draw each star
    for i = 1,#stars do
        circfill_dia(stars[i].x, stars[i].y, stars[i].d, stars[i].c)
    end

    -- draw ship and thruster fire
    local shipDirection = direction+shipDirectionOffset
    spr_rotated(16, 0, 16, 16, 64, 64, shipDirection)
    if leftThruster then spr_rotated(48, 0, 16, 16, 64, 64, shipDirection) end
    if centreThruster then spr_rotated(32, 0, 16, 16, 64, 64, shipDirection) end
    if rightThruster then spr_rotated(64, 0, 16, 16, 64, 64, shipDirection) end

    -- -- print stuff
    -- print("S:" .. speed, 0, 0, 7)
    -- print("D:" .. direction, 0, 8, 7)
    -- print("L:" .. (leftThruster and 'T' or 'F'), 0, 16, 7)
    -- print("C:" .. (centreThruster and 'T' or 'F'), 0, 24, 7)
    -- print("R:" .. (rightThruster and 'T' or 'F'), 0, 32, 7)
end

--[[
    // quick and dirty way of rotating a sprite
    // adapted from: https://www.lexaloffle.com/bbs/?tid=3936
    sx = spritesheet x-coord
    sy = spritesheet y-coord
    sw = pixel width of source sprite
    sh = pixel height of source sprite
    px = x-coord of where to draw rotated sprite on screen
    py = x-coord of where to draw rotated sprite on screen
    r = amount to rotate (radians)
]]
function spr_rotated(sx,sy,sw,sh,px,py,r)
    -- loop through all the pixels
    for y=sy,sy+sh-1 do
        for x=sx,sx+sw-1 do
            -- get source pixel color
            col = sget(x,y)
            -- skip transparent pixel
            if (col != transparentCol) then
                -- rotate pixel around center
                local xx = (x-sx)-sw/2
                local yy = (y-sy)-sh/2
                local x2 = xx*cos(r) - yy*sin(r)
                local y2 = yy*cos(r) + xx*sin(r)
                -- translate rotated pixel to where we want to draw it on screen
                local x3 = flr(x2+px)
                local y3 = flr(y2+py)
                -- pixel it
                pset(x3,y3,col)
            end
        end
    end
end

--[[
    // Draw a filled circle.
    // Similar effect to circfill(), but specify diameter instead of radius (thus allowing finer control over size).
]]
function circfill_dia(x, y, d, c)
    local r = d/2
    local miny = y-r --max(y - r, 0)
    local maxy = y+r --min(y + r, 127)
    local minx = x-r --max(x - r, 0)
    local maxx = x+r --min(x + r, 127)
    for py=miny,maxy do
        for px=minx,maxx do
            -- use Pythagorean theorem to determine if coordinate is within circle
            local xx = (px - x) * 2
            local yy = (py - y) * 2
            if xx*xx + yy*yy <= d*d+d then
                pset(px,py,c)
            end
        end
    end
end

__gfx__
00000000fff6fffffffffff6ffffffffffffffffffffffffffffffffffffffffffffffffffffffff000000000000000000000000000000000000000000000000
00000000ff6c6fffffffff6c6fffffffffffffffffffffffffffffffffffffffffffffffffffffff000000000000000000000000000000000000000000000000
00700700ff6c6fffffffff6c6fffffffffffffffffffffffffffffffffffffffffffffffffffffff000000000000000000000000000000000000000000000000
000770006f6c6f6ffffff6c1c6ffffffffffffffffffffffffffffffffffffffffffffffffffffff000000000000000000000000000000000000000000000000
0007700066ccc66ffffff6c3c6ffffffffffffffffffffffffffffffffffffffffffffffffffffff000000000000000000000000000000000000000000000000
0070070066ccc66ffffff6c1c6ffffffffffffffffffffffffffffffffffffffffffffffffffffff000000000000000000000000000000000000000000000000
000000006f6c6f6fff6ff6c3c6ff6fffffffffffffffffffffffffffffffffffffffffffffffffff000000000000000000000000000000000000000000000000
00000000fffffffff6c6f6c1c6f6c6ffffffffffffffffffffffffffffffffffffffffffffffffff000000000000000000000000000000000000000000000000
0000000000000000f6c666c3c666c6ffffffffffffffffffffffffffffffffffffffffffffffffff000000000000000000000000000000000000000000000000
0000000000000000f6ccccc1ccccc6ffffffffffffffffffffffffffffffffffffffffffffffffff000000000000000000000000000000000000000000000000
0000000000000000f6c666c3c666c6ffffffffffffffffffffffffffffffffffffffffffffffffff000000000000000000000000000000000000000000000000
0000000000000000f6c6f6c1c6f6c6ffffffffffffffffffffffffffffffffffffffffffffffffff000000000000000000000000000000000000000000000000
0000000000000000f6d6f6ddd6f6d6ffffffffffffffffffffffffffffffffffffffffffffffffff000000000000000000000000000000000000000000000000
0000000000000000ffffffffffffffffffffff888fffffffff8fffffffffffffffffffffffff8fff000000000000000000000000000000000000000000000000
0000000000000000fffffffffffffffffffff98889fffffff898fffffffffffffffffffffff898ff000000000000000000000000000000000000000000000000
0000000000000000fffffffffffffffffffff89898ffffffffffffffffffffffffffffffffffffff000000000000000000000000000000000000000000000000
