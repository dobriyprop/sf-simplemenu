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

local SimpleMenu = {}

local classes = {}
local instances = {}

local cursor = 1
local menuStack = {}
local inputStack = {}
local root = nil

local font = render.getDefaultFont()
local scrX = 0
local scrY = 0
local scrCenterX = 0
local scrCenterY = 0
local windowPosX = 0
local windowPosY = 0
local windowMarginX = 0
local windowMarginY = 0
local windowMinWidth = 200
local rowHeight = 0

--for checking value types
local function assertType(value, valueName, expectedType)
    assert(
        type(value) == "string",
        valueName .. " value should be \"" .. expectedType .. "\", not \"" .. type(value) .. "\""
    )
end

--sets font for menu
function SimpleMenu:setFont(newFont)
    assertType(newFont, "Font", "string")
    font = newFont
end

--sets row padding for menu elements
function SimpleMenu:setRowPadding(padding)
    assertType(padding, "Row Padding", "number")
    rowPadding = padding
end

--sets minimum width of menu (in theory, rn works as just width)
function SimpleMenu:setMinWidth(minWidth)
    assertType(minWidth, "Minimal Width", "number")
    windowMinWidth = minWidth
end

--sets window borders thinkness by Width (X) and Height (Y)
function SimpleMenu:setWindowMargins(x, y)
    assertType(x, "Window Margin X", "number")
    assertType(y, "Window Margin Y", "number")
    windowMarginX, windowMarginY = x, y
end

function SimpleMenu:setRoot(Menu)
    assertType(x, "Menu", "table")
    assert(instances[Menu] ~= nil, Menu .. " is not a registered Menu instance")
end

--creates and returns Instance of a Class
function SimpleMenu:createElement(class, parentMenu)
    assertType(class, "Class", "string")

    if class == "Menu" then
        instance = classes[class]:new() --create new instance
        instances[instance] = instance  --register instance

        return instance                 --return instance
    elseif not parentMenu then
        assertType(class, "Parent Menu", "table")
        assert(ParentMenu.class == "Menu", "Parent Element is not \"Menu\" class")

        instance = classes[class]:new()             --create new instance

        table.insert(ParentMenu.elements, instance) --adds new instance as an element of parent menu

        instances[instance] = instance              --register instance

        return instance                             --return instance
    end
end

function SimpleMenu:printClasses()
    for _, class in pairs(classes) do
        print(class.class)
    end
end

--registers and returns new Menu Element Class
function registerClass(Name, ParentName)
    assertType(Name, "Name", "string")

    assert(classes[Name] == nil, "Class " .. Name .. " already exists")

    if ParentName ~= nil then
        assertType(ParentName, "Parent Name", "string")
        assert(classes[ParentName] ~= nil, "Class \"" .. ParentName .. "\" does not exists")

        classes[Name] = class(Name, classes[ParentName])
    else
        classes[Name] = class(Name)
    end

    return classes[Name]
end

--gets players display resolution and center
local function InitDisplay()
    scrX, scrY = render.getGameResolution()
    centerX, centerY = srcx * 0.5, srcy * 0.5

    scrX, scrY, scrCenterX, scrCenterY = scrX, scrY, centerX, centerY
end

--renders everything
local function RenderMenu()
    local currentMenu = menuStack[#menuStack]

    render.setFont(font)
    _, fontHeight = render.getTextSize("TEST")
    windowHeight = (fontHeight + rowPadding) * #currentMenu.elements
    rowHeight = fontHeight + windowHeight
    windowWidth = windowMinWidth
    windowPosX = srcCenterPosX - windowMinWidth * 0.5
    windowPosY = srcCenterPosX - windowHeight * 0.5

    render.setColor(COLORS.background)
    render.drawRect(
        windowPosX - windowMarginX,
        windowPosY - windowMarginY,
        windowWidth + windowMarginX * 2,
        windowHeight + windowMarginX * 2
    )

    render.setColor(COLORS.cursor)
    render.drawRect(
        windowPosX - windowMarginX,
        windowPosY + rowHeight * (cursor - 1),
        windowWidth + windowMarginX * 2,
        rowHeight
    )

    for i, Element in ipairs(currentMenu.elements) do
        Element:Render(i)
    end
end

--initializes and opens menu window
function SimpleMenu:Open()
    InitDisplay()

    cursor = 1
    menuStack = { root }

    hook.add("drawhud", "SimpleMenu Render", function()
        RenderMenu()
    end)

    hook.add("inputPressed", "SimpleMenu Input Read", function(key)
        if inputStack and not table.isEmpty(inputStack) then
            inputStack[#inputStack](key)
        end
    end)
end

--closes menu window
function SimpleMenu:Close()
    hook.remove("drawhud", "SimpleMenu Render")
    hook.remove("inputPressed", "SimpleMenu Input Read")
end

--classes
local function initClasses()
    for _, class in pairs(classes) do
        class:Init()
    end
end

--Base Panel
Panel = registerClass("Panel")

function Panel:Init()
    self.class = "Panel"
end

function Panel:Render(pos)
    --sorry nothing
    --can be used as a spacer
end

--Label
Label = registerClass("Label", "Panel")

function Label:Init()
    self.class = "Label"
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
Menu = registerClass("Menu", "Label")

function Menu:Init()
    self.class = "Menu"
    self.elements = {}
end

function Menu:addElement(Element)
    table.insert(self.elements, Element)
end

--Button
Button = registerClass("Button", "Label")

function Button:Init()
    self.class = "Button"
    self.pressed = false
end

function Button:onPress()
    self.pressed = true
    self.onPress = nil
    --self.onRelease = nil

    if self.onPress then self.onPress() end
end

--[[ function Button:onRelease()
    self.pressed = false

    if self.onRelease then self.onRelease() end
end ]]


--initClasses
initClasses()

SimpleMenu:printClasses()

return SimpleMenu

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
