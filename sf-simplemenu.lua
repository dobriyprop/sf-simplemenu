--@name simple menu
--@author dobriyprop
--@client

local inputENUM = table.copy(KEY) --table of ENUMs to unify keyboard and mouse input codes

--define mouse input codes
inputENUM.MOUSE1 = MOUSE.MOUSE1
inputENUM.MOUSE2 = MOUSE.MOUSE2
inputENUM.MOUSE3 = MOUSE.MOUSE3
inputENUM.MOUSE4 = MOUSE.MOUSE4
inputENUM.MOUSE5 = MOUSE.MOUSE5
inputENUM.MWHEELUP = MOUSE.MWHEELUP
inputENUM.MWHEELDOWN = MOUSE.MWHEELDOWN

local SimpleMenu = {
    cursor = 1,
    menuStack = {},
    inputStack = {},
    
    font = render.getDefaultFont(),
    minwidth = 200,
    marginx = 0,
    marginy = 0,
    
    root = nil,
}

local menuInputENUM = { --ENUMs for menu actions
    up = 1,
    down = 2,
    left = 3,
    right = 4,
    enter = 5,
    back = 6,
}

local menuInputs = { --inputs map
    [inputENUM.W] = menuInputENUM.up,
    [inputENUM.S] = menuInputENUM.down,
    [inputENUM.A] = menuInputENUM.left,
    [inputENUM.D] = menuInputENUM.right,

    [inputENUM.UPARROW] = menuInputENUM.up,
    [inputENUM.DOWNARROW] = menuInputENUM.down,
    [inputENUM.LEFTARROW] = menuInputENUM.left,
    [inputENUM.RIGHTARROW] = menuInputENUM.right,

    [inputENUM.ENTER] = menuInputENUM.enter,
    [inputENUM.BACKSPACE] = menuInputENUM.back,
}

local COLORS = {
    black = Color(0,0,0),
    white = Color(255,255,255),
    background = Color(0,0,0,150)
}

function SimpleMenu:setFont(font)
    assert(type(font) == "string", "Font value should be \"string\" type, not \""..type(font).."\"")
    self.font = font
end

function SimpleMenu:setRowPadding(padding)
    assert(type(padding) == "number", "Row Padding value should be \"number\" type, not \""..type(font).."\"")
    self.padding = padding
end

function SimpleMenu:setWindowMargins(x,y)
    assert(type(x) == "number", "Windows Margin X value should be \"number\" type, not \""..type(x).."\"")
    assert(type(y) == "number", "Windows Margin Y value should be \"number\" type, not \""..type(y).."\"")
    self.marginx,self.marginy = x,y
end

hook.add("drawhud","",function() --old render function from draft i made. just for history.
    render.setFont(render.getDefaultFont())
    
    local _,fontHeight = render.getTextSize("TEST")
    local windowHeight = (fontHeight + rowPadding) * #currentMenu
    local rowHeight = fontHeight + rowPadding
    local startPosX = screenCenterX - windowWidth * 0.5
    local startPosY = screenCenterY - windowHeight * 0.5
    local counter = 0
    
    render.setColor(Color(0,0,0,100))
    render.drawRect(startPosX - windowMarginX, startPosY - windowMarginY, windowWidth + windowMarginX*2, windowHeight + windowMarginY*2)
    
    render.setColor(Color(0,0,0,255))
    render.drawRect(startPosX - windowMarginX, startPosY + (cursorPos-1) * rowHeight, windowWidth+ windowMarginX*2, rowHeight)

    for i,entry in ipairs(currentMenu) do
        local posY = startPosY + (fontHeight + rowPadding) * counter
        
        render.setColor(Color(255,255,255))
        render.drawText(startPosX, posY + rowPadding * 0.5, entry.prettyName ~= nil and entry.prettyName or entry.name, TEXT_ALIGN.LEFT)
        if entry.value then
            render.drawText(startPosX + windowWidth, posY + rowPadding * 0.5, "["..tostring(entry.value).."]", TEXT_ALIGN.RIGHT)
        end
        
        counter = counter + 1
    end
end)
