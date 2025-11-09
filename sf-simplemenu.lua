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

    classes = {},

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
    black = Color(0, 0, 0),
    white = Color(255, 255, 255),
    background = Color(0, 0, 0, 150),
}

function assertType(value, valueName, expectedType)
    assert(type(value) == "string", valueName .. " value should be \"" .. expectedType .. "\", not \"" ..
        type(value) .. "\"")
end

function SimpleMenu:setFont(font)
    assertType(font, "Font", "string")
    self.font = font
end

function SimpleMenu:setRowPadding(padding)
    assertType(padding, "Row Padding", "number")
    self.padding = padding
end

function SimpleMenu:setMinWidth(minWidth)
    assertType(minWidth, "Minimal Width", "number")
    self.minwidth = minWidth
end

function SimpleMenu:setWindowMargins(x, y)
    assertType(x, "Window Margin X", "number")
    assertType(y, "Window Margin Y", "number")
    self.marginx, self.marginy = x, y
end

function SimpleMenu:assertClass(Name)
    assert(self.classes[Name] == nil, "Class " .. Name .. " doesn't exists")
end

function SimpleMenu:registerClass(Name, ParentName)
    assertType(Name, "Name", "string")

    if ParentName ~= nil then
        assertType(value, "Name", expectedType)
        assert(self.classes[ParentName] == nil, "Class \"" .. ParentName .. "\" does not exists")

        self.classes[Name] = class(Name, self.classes[ParentName])
    else
        self.classes[Name] = class(Name)
    end

    return self.classes[Name]
end

--classes
--Base Panel
Panel = SimpleMenu:registerClass("Panel")

function Panel:Render()
    --sorry nothing
end

--Label
Label = SimpleMenu:registerClass("Label", "Panel")

function Label:setName(name, prettyName)
    self.name = name
    self.prettyName = prettyName
end

--Menu
Menu = SimpleMenu:registerClass("Menu", "Label")

function Menu:addElement(Element)
    if self.elements == nil then self.elements = {} end
    
end

--Button
Button = SimpleMenu:registerClass("Button", "Label")

function Button:onPress()
    self.pressed = true

    if self.onPress then self.onPress() end
end

function Button:onRelease()
    self.pressed = false

    if self.onRelease then self.onRelease() end
end

--[[
hook.add("drawhud", "", function() --old render function from draft i made. just for history.
    render.setFont(render.getDefaultFont())

    local _, fontHeight = render.getTextSize("TEST")
    local windowHeight = (fontHeight + rowPadding) * #currentMenu
    local rowHeight = fontHeight + rowPadding
    local startPosX = screenCenterX - windowWidth * 0.5
    local startPosY = screenCenterY - windowHeight * 0.5
    local counter = 0

    render.setColor(Color(0, 0, 0, 100))
    render.drawRect(startPosX - windowMarginX, startPosY - windowMarginY, windowWidth + windowMarginX * 2,
        windowHeight + windowMarginY * 2)

    render.setColor(Color(0, 0, 0, 255))
    render.drawRect(startPosX - windowMarginX, startPosY + (cursorPos - 1) * rowHeight, windowWidth + windowMarginX * 2,
        rowHeight)

    for i, entry in ipairs(currentMenu) do
        local posY = startPosY + (fontHeight + rowPadding) * counter

        render.setColor(Color(255, 255, 255))
        render.drawText(startPosX, posY + rowPadding * 0.5, entry.prettyName ~= nil and entry.prettyName or entry.name,
            TEXT_ALIGN.LEFT)
        if entry.value then
            render.drawText(startPosX + windowWidth, posY + rowPadding * 0.5, "[" .. tostring(entry.value) .. "]",
                TEXT_ALIGN.RIGHT)
        end

        counter = counter + 1
    end
end)
 ]]
