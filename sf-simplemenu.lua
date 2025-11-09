--@name simple menu
--@author dobriyprop
--@client

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

local menuInputENUM = {
    up = 1,
    down = 2,
    left = 3,
    right = 4,
    enter = 5,
    back = 6,
}

local menuInputs = {
    [KEY.W] = menuInputENUM.up,
    [KEY.S] = menuInputENUM.down,
    [KEY.A] = menuInputENUM.left,
    [KEY.D] = menuInputENUM.right,

    [KEY.UPARROW] = menuInputENUM.up,
    [KEY.DOWNARROW] = menuInputENUM.down,
    [KEY.LEFTARROW] = menuInputENUM.left,
    [KEY.RIGHTARROW] = menuInputENUM.right,

    [KEY.ENTER] = menuInputENUM.enter,
    [KEY.BACKSPACE] = menuInputENUM.back,
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

hook.add("drawhud","",function()
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
