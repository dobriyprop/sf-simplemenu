--@name simple menu
--@author dobriyprop
--@client

local mathClamp = math.clamp

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

    [inputENUM.MOUSE1] = menuInputENUM.enter,
    [inputENUM.MOUSE2] = menuInputENUM.back,
    [inputENUM.MWHEELUP] = menuInputENUM.up,
    [inputENUM.MWHEELDOWN] = menuInputENUM.down,
}

local menuInputsAutoRepeat = {
    [menuInputENUM.up] = true,
    [menuInputENUM.down] = true,
    [menuInputENUM.left] = true,
    [menuInputENUM.right] = true,
    [menuInputENUM.enter] = false,
    [menuInputENUM.back] = false,
}

local COLORS = {
    cursor = Color(0, 0, 0),
    elementActive = Color(0, 0, 0),
    text = Color(255, 255, 255),
    textActive = Color(0, 0, 0),
    background = Color(0, 0, 0, 150),
}

local instances = {}

local cursor = 1
local autoRepeatAllowed = true
local cursorStack = {}
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
local windowWidth = 0
local rowPadding = 0

local SimpleMenu = {
    classes = {},
}

--for checking value types
local function assertType(value, valueName, expectedTypes)
    if type(expectedTypes) == "string" then
        assert(
            type(value) == expectedTypes,
            valueName .. " value should be \"" .. expectedTypes .. "\" type, not \"" .. type(value) .. "\""
        )
    elseif type(expectedType) == "table" then
        --builds expected types string from table and asserts incorrect entries in expected types table
        local expectedTypesString = ""
        for i, expectedType in ipairs(expectedTypes) do
            assert(
                type(expectedType) == "string",
                "Assert type failed. Multiple expected types should be described as table of strings"
            )
            expectedTypesString = expectedTypesString .. "\"expectedType\""
            if i < #expectedTypes - 1 then
                expectedTypesString = expectedTypesString .. ", "
            elseif i == #expectedTypes - 1 then
                expectedTypesString = expectedTypesString .. " or "
            end
        end

        --checks value against table of expected types
        for i, expectedType in ipairs(expectedTypes) do
            --if there's a match - exit the function
            if type(value) == expectedType then return end
        end

        --if no matches - create an assert
        assert(
            false,
            valueName .. " value should be " .. expectedTypesString .. " type, not \"" .. type(value) .. "\""
        )
    end
end

--stops autorepeat. can be used for certain input processing functions that do not need to be repeated
local function autoRepeatStop()
    timer.stop("autorepeat_delay")
    timer.stop("autorepeat")
end

--input processing function with autorepeat functionality
local function processInput(pressed, key)
    --if new input arrived be it on press or release - stop all autorepeat timers
    autoRepeatStop()

    --check if input stack is valid table and not empty
    if inputStack and not table.isEmpty(inputStack) then
        --perform an input action according to pressed keys
        local inputFunc = inputStack[#inputStack]

        --if input is pressed and and auto repeat is allowed and menu input action is allowed to be autorepeated
        if pressed == true and autoRepeatAllowed == true then
            --create autorepeat delay timer for X seconds (0.5 in this case, make it adjustable later)
            timer.create("autorepeat_delay", 0.5, 1, function()
                --after which autorepeat timer will start and spam last performed input Y seconds
                --(0.03 in this case, also make it adjustable later)
                timer.create("autorepeat", 0.02, 0, function()
                    inputFunc(true, key)
                end)
            end)
        end

        inputFunc(pressed, key)
    end
end

--classes

--Base Widget
local Widget = class("Widget")
SimpleMenu.classes.Widget = Widget

--initialize base widget
function Widget:initialize()
    self._type = "Widget"
    self._name = ""
    self._pressable = false
end

function Widget:isPressable()
    return self._pressable
end

function Widget:setName(name)
    assertType(name, "Name", "string")
    self._name = name
end

function Widget:getName()
    return self._name
end

function Widget:getClass()
    return self._type
end

function Widget:Render(pos)
    --sorry nothing
    --can be used as a spacer maybe
end

--Label
local Label = class("Label", Widget)
SimpleMenu.classes.Label = Label

function Label:initialize()
    self._type = "Label"
    --self._text = ""
end

--allows for text be defined by string or function on every render call
function Label:setText(text)
    assertType(text, "Text", { "string", "function" })
    self._text = text
end

function Label:getText()
    return self._text
end

function Label:Render(pos)
    Widget:Render(pos)

    if self._text then
        local text = self._text

        if type(self._text) == "function" then
            text = self._text()
            assert(type(text) == "string", "Text function returned non string value")
        end

        render.setColor(COLORS.text)
        render.drawText(
            windowPosX, windowPosY + (fontHeight + rowPadding) * pos + rowPadding * 0.5,
            text,
            TEXT_ALIGN.LEFT
        )
    end
end

--Menu
local Menu = class("Menu", Label)
SimpleMenu.classes.Menu = Menu

--handles inputs while in menus
local function menuInputHandler(hook, key)
    if menuInputs[key] == nil then return end

    local menuInputCode = menuInputs[key]
    local menu = menuStack[#menuStack]
    local menuChildren = menu:getChildren()
    local cursorChild = menuChildren[cursor]

    if hook == true then -- true for inputPressed hook
        if menuInputCode == menuInputENUM.up or menuInputCode == menuInputENUM.down then
            local direction = menuInputCode == menuInputENUM.up and -1 or 1
            cursor = mathClamp(cursor + direction, 1, #menuChildren)
        elseif menuInputCode == menuInputENUM.enter and cursorChild:isPressable() then
            autoRepeatStop()
            cursorChild:press()
        elseif menuInputCode == menuInputENUM.back then
            autoRepeatStop()
            cursor = 1
            if menu == root then
                SimpleMenu:Close()
            else
                table.remove(menuStack)
                table.remove(inputStack)
                cursor = table.remove(cursorStack)
            end
        end
    elseif hook == false then -- false for inputReleased hook
        if menuInputCode == menuInputENUM.enter and cursorChild:isPressable() then
            cursorChild:release()
        end
    end
end

function Menu:initialize()
    self._type = "Menu"
    self._pressable = true
    self._children = {}
    self._inputHandler = menuInputHandler
end

function Menu:press()
    menuStack[#menuStack + 1] = self
    inputStack[#inputStack + 1] = self._inputHandler
    cursorStack[#cursorStack + 1] = cursor
    cursor = 1
end

function Menu:release()
    --placeholder
end

function Menu:addChild(child)
    self._children[#self._children + 1] = child
end

function Menu:getChildren()
    return self._children
end

--Button
local Button = class("Button", Label)
SimpleMenu.classes.Button = Button

function Button:initialize()
    self._type = "Button"
    self._pressable = true
    self._pressed = false
    self._value = nil
end

function Button:setValue(text)
    assertType(text, "Text", { "string", "function" })
    self._value = text
end

function Button:press()
    self._pressed = true

    if self._onPress then self._onPress() end
end

function Button:release()
    self._pressed = false

    if self._onRelease then self._onRelease() end
end

function Button:onPress(func)
    assertType(func, "On Press Function", "function")
    self._onPress = func
end

function Button:onRelease(func)
    assertType(func, "On Release Function", "function")
    self._onRelease = func
end

function Button:Render(pos)
    Widget:Render(pos)

    if self._pressed then
        render.setColor(COLORS.text)
        render.drawRect(
            windowPosX - windowMarginX,
            windowPosY + rowHeight * pos,
            windowWidth + windowMarginX * 2,
            rowHeight
        )
    end

    render.setColor(self._pressed == true and COLORS.cursor or COLORS.text)

    if self._text then
        local text = self._text

        if type(self._text) == "function" then
            text = self._text()
            assert(type(text) == "string", "Text function returned non string value")
        end

        render.drawText(
            windowPosX, windowPosY + (fontHeight + rowPadding) * pos + rowPadding * 0.5,
            text,
            TEXT_ALIGN.LEFT
        )
    end

    if self._value then
        local text = self._value

        if type(self._value) == "function" then
            text = self._value()
            assert(type(text) == "string", "Value Text function returned non string value")
        end

        render.drawText(
            windowPosX + windowWidth, windowPosY + (fontHeight + rowPadding) * pos + rowPadding * 0.5,
            text,
            TEXT_ALIGN.RIGHT
        )
    end
end

--gets players display resolution and center
local function InitDisplay()
    scrX, scrY = render.getGameResolution()
    centerX, centerY = scrX * 0.5, scrY * 0.5

    scrX, scrY, scrCenterX, scrCenterY = scrX, scrY, centerX, centerY
end

--renders everything
local function RenderMenu()
    local currentMenu = menuStack[#menuStack]

    render.setFont(font)
    _, fontHeight = render.getTextSize("TEST")
    windowHeight = (fontHeight + rowPadding) * #currentMenu:getChildren()
    rowHeight = fontHeight + rowPadding
    windowWidth = windowMinWidth
    windowPosX = scrCenterX - windowMinWidth * 0.5
    windowPosY = scrCenterY - windowHeight * 0.5

    render.setColor(COLORS.background)
    render.drawRect(
        windowPosX - windowMarginX,
        windowPosY - windowMarginY,
        windowWidth + windowMarginX * 2,
        windowHeight + windowMarginY * 2
    )

    render.setColor(COLORS.cursor)
    render.drawRect(
        windowPosX - windowMarginX,
        windowPosY + rowHeight * (cursor - 1),
        windowWidth + windowMarginX * 2,
        rowHeight
    )

    for i, child in ipairs(currentMenu:getChildren()) do
        child:Render(i - 1)
    end
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

function SimpleMenu:setRoot(menuInstance)
    assert(menuInstance:isInstanceOf(self.classes.Menu), "Instance is not of a \"Menu\" class")

    root = menuInstance
end

function SimpleMenu:createInstance(className, ...)
    assertType(className, "Class Name", "string")
    assert(self.classes[className] ~= nil, "Class " .. className .. " doesn't exist")

    local instance = self.classes[className]:new(...)

    return instance
end

function SimpleMenu:autoRepeat(enabled)
    if enabled ~= nil then
        assertType(enabled, "Auto Repeat", "boolean")
        autoRepeatAllowed = enabled
    else
        return autoRepeatAllowed
    end
end

--initializes and opens menu window
function SimpleMenu:Open(lockControls, enableCursor)
    assertType(lockControls, "Lock Controls", "boolean")
    assertType(enableCursor, "Enable Cursor", "boolean")

    input.enableCursor(enableCursor and enableCursor or false)
    input.lockControls(lockControls and lockControls or false)

    InitDisplay()

    cursor = 1
    menuStack = { root }
    inputStack = { root._inputHandler }

    hook.add("drawhud", "SimpleMenu Render", function()
        RenderMenu()
    end)

    hook.add("inputPressed", "SimpleMenu Input Read", function(key)
        processInput(true, key)
    end)

    hook.add("inputReleased", "SimpleMenu Input Read", function(key)
        processInput(false, key)
    end)
end

--closes menu window
function SimpleMenu:Close()
    input.enableCursor(false)
    input.lockControls(false)
    hook.remove("drawhud", "SimpleMenu Render")
    hook.remove("inputPressed", "SimpleMenu Input Read")
end

return SimpleMenu
