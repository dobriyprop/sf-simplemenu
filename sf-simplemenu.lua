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
    cursor = Color(0, 0, 0),
    elementActive = Color(0, 0, 0),
    text = Color(255, 255, 255),
    textActive = Color(0, 0, 0),
    background = Color(0, 0, 0, 150),
}

local SimpleMenu = {
    classes = {},
    font = render.getDefaultFont(),

    cursor = 1,
    menuStack = {},
    inputStack = {},
    root = nil,

    scrX = 0,
    scrY = 0,
    scrCenterX = 0,
    scrCenterY = 0,
    windowPosX = 0,
    windowPosY = 0,
    windowMarginX = 0,
    windowMarginY = 0,
    windowMinWidth = 200,
    rowHeight = 0,
}

function assertType(value, valueName, expectedType)
    assert(
        type(value) == "string",
        valueName .. " value should be \"" .. expectedType .. "\", not \"" .. type(value) .. "\""
    )
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
    self.windowMinWidth = minWidth
end

function SimpleMenu:setWindowMargins(x, y)
    assertType(x, "Window Margin X", "number")
    assertType(y, "Window Margin Y", "number")
    self.windowMarginX, self.windowMarginY = x, y
end

function SimpleMenu:assertClass(Name)
    assert(self.classes[Name] == nil, "Class " .. Name .. " doesn't exists")
end

function SimpleMenu:registerClass(Name, ParentName)
    assertType(Name, "Name", "string")

    if ParentName ~= nil then
        assertType(ParentName, "Parent Name", "string")
        assert(self.classes[ParentName] == nil, "Class \"" .. ParentName .. "\" does not exists")

        self.classes[Name] = class(Name, self.classes[ParentName])
    else
        self.classes[Name] = class(Name)
    end

    return self.classes[Name]
end

function SimpleMenu:createElement(class, parentMenu)
    assertType(class, "Class", "string")

    if class == "Menu" then
        return self.registry[class]:new()
    elseif not parentMenu then
        assertType(class, "Parent Menu", "table")
        return self.registry[class]:new()
    end
end

function SimpleMenu:InitDisplay()
    scrX, scrY = render.getGameResolution()
    centerX, centerY = srcx * 0.5, srcy * 0.5

    self.scrX, self.scrY, self.scrCenterX, self.scrCenterY = scrX, scrY, centerX, centerY
end

function SimpleMenu:Render()
    local currentMenu = self.menuStack[#self.menuStack]

    _, self.fontHeight = render.getTextSize("TEST")
    self.windowHeight = (fontHeight + rowPadding) * #currentMenu
    self.rowHeight = self.fontHeight + self.windowHeight
    self.windowWidth = self.windowMinWidth
    self.windowPosX = self.srcCenterPosX - self.windowMinWidth * 0.5
    self.windowPosY = self.srcCenterPosX - self.windowHeight * 0.5

    render.setColor(COLORS.background)
    render.drawRect(
        self.windowPosX - self.windowMarginX,
        self.windowPosY - self.windowMarginY,
        self.windowWidth + self.windowMarginX * 2,
        self.windowHeight + self.windowMarginX * 2
    )

    render.setColor(COLORS.cursor)
    render.drawRect(
        self.windowPosX - self.windowMarginX,
        self.windowPosY + self.rowHeight * (self.cursor - 1),
        self.windowWidth + self.windowMarginX * 2,
        self.rowHeight
    )

    for i, Element in ipairs(CurrentMenu) do
        Element:Render(i)
    end
end

function SimpleMenu:Open()
    self:InitDisplay()

    self.cursor = 1
    self.menuStack = { self.root }

    hook.add("drawhud", "SimpleMenu Render", function()
        self:Render()
    end)

    hook.add("inputPressed", "SimpleMenu Input Read", function(key)
        if self.inputStack and not table.isEmpty(self.inputStack) then
            self.inputStack[#self.inputStack](key)
        end
    end)
end

function SimpleMenu:Close()
    hook.remove("drawhud", "SimpleMenu Render")
    hook.remove("inputPressed", "SimpleMenu Input Read")
end

--classes
--Base Panel
Panel = SimpleMenu:registerClass("Panel")

function Panel:init()
    self.type = "Panel"
end

function Panel:Render(pos)
    --sorry nothing
    --can be used as spacer
end

--Label
Label = SimpleMenu:registerClass("Label", "Panel")

function Label:init()
    self.type = "Label"
end

function Label:setName(name, prettyName)
    self.name = name
    self.prettyName = prettyName
end

function Label:Render(pos)
    Panel:Render(pos)
    local startx = SimpleMenu.windowPosX
    local starty = SimpleMenu.windowPosY
    local padding = SimpleMenu.padding
    local fontHeight = SimpleMenu.fontHeight

    render.setColor(COLORS.text)
    render.drawText(startx, starty + (fontHeight + padding) * pos + padding * 0.5,
        self.prettyName ~= nil and self.prettyName or self.name,
        TEXT_ALIGN.LEFT)
end

--Menu
Menu = SimpleMenu:registerClass("Menu", "Label")

function Menu:init()
    self.type = "Menu"
    self.elements = {}
end

function Menu:addElement(Element)
    table.insert(self.elements, Element)
end

--Button
Button = SimpleMenu:registerClass("Button", "Label")

function Button:init()
    self.type = "Button"
    self.pressed = false
end

function Button:onPress()
    self.pressed = true
    self.onPress = nil
    self.onRelease = nil

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
