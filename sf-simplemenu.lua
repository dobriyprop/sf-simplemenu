--@name simple menu
--@author dobriyprop
--@client

local mathMin = math.min
local mathMax = math.max
local mathClamp = math.clamp
local mathRound = math.round

local tableInsert = table.insert
local tableRemove = table.remove

local stringFormat = string.format


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
    cursor = Color(5, 55, 215),
    text = Color(215, 215, 215),
    textBright = Color(255, 255, 255),
    background = Color(0, 0, 0, 210),
}

local instances = {}

local cursor = 1
local autoRepeatAllowed = true
local cursorStack = {}
local menuStack = {}
local inputStack = {}
local activeElement = nil
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

local function pushInputStack(inputHandler)
    assertType(inputHandler, "Input Handler", "function")
    tableInsert(inputStack, inputHandler)
end

local function popInputStack()
    return tableRemove(inputStack)
end

local function activateElement(Instance)
    activeElement = Instance
    pushInputStack(Instance._inputHandler)
end

local function deactivateElement(Instance)
    activeElement = nil
    popInputStack()
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

function Widget:render(pos, isSelected)
    --sorry nothing
    --can be used as a spacer maybe
end

function Widget:press()
    --dummy function
end

function Widget:release()
    --dummy function
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

function Label:render(pos, isSelected)
    self.class.super.render(pos, isSelected)

    if isSelected then
        render.setColor(COLORS.cursor)
        render.drawRect(
            windowPosX - windowMarginX,
            windowPosY + rowHeight * pos,
            windowWidth + windowMarginX * 2,
            rowHeight
        )
    end
    if self._text then
        local text = self._text

        if type(self._text) == "function" then
            text = self._text()
            assert(type(text) == "string", "Text function returned non string value")
        end

        local textColor = isSelected and COLORS.textBright or COLORS.text
        render.setColor(textColor)
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
local function menuInputHandler(pressed, key)
    if menuInputs[key] == nil then return end

    local menuInputCode = menuInputs[key]
    local menu = menuStack[#menuStack]
    local menuChildren = menu:getChildren()
    local cursorChild = menuChildren[cursor]

    if pressed == true then -- true for inputPressed hook
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
                menu:back()
            end
        end
    elseif pressed == false then -- false for inputReleased hook
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
    pushInputStack(self._inputHandler)
    table.insert(menuStack, self)
    table.insert(cursorStack, cursor)
    cursor = 1
end

function Menu:release()
    --placeholder
end

function Menu:back()
    popInputStack()
    tableRemove(menuStack)
    cursor = tableRemove(cursorStack)
end

function Menu:addChild(child)
    self._children[#self._children + 1] = child
end

function Menu:getChildren()
    return self._children
end

function Menu:render(pos, isSelected)
    self.class.super.render(pos, isSelected)
    local textColor = isSelected and COLORS.textBright or COLORS.text
    render.setColor(textColor)
    render.drawText(
        windowPosX + windowWidth, windowPosY + (fontHeight + rowPadding) * pos + rowPadding * 0.5,
        "->",
        TEXT_ALIGN["RIGHT"]
    )
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

function Button:render(pos, isSelected)
    if self._pressed or isSelected then
        local bgColor = self._pressed and COLORS.textBright or COLORS.cursor
        render.setColor(bgColor)
        render.drawRect(
            windowPosX - windowMarginX,
            windowPosY + rowHeight * pos,
            windowWidth + windowMarginX * 2,
            rowHeight
        )
    end

    local textColor = self._pressed and COLORS.cursor or (isSelected and COLORS.textBright or COLORS.text)
    render.setColor(textColor)

    if self._text then
        local text = self._text

        if type(self._text) == "function" then
            text = self._text()
            assert(type(text) == "string", "Text function returned non string value")
        end

        if type(self._text) ~= "string" then
            text = tostring(text)
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

        if type(self._value) ~= "string" then
            text = tostring(text)
        end

        render.drawText(
            windowPosX + windowWidth, windowPosY + (fontHeight + rowPadding) * pos + rowPadding * 0.5,
            text,
            TEXT_ALIGN.RIGHT
        )
    end
end

--value slider
local Slider = class("Slider", Label)
SimpleMenu.classes.Slider = Slider

local function sliderInputHandler(pressed, key)
    if menuInputs[key] == nil then return end

    local menuInputCode = menuInputs[key]

    if pressed == true then -- true for inputPressed hook
        if menuInputCode == menuInputENUM.up or menuInputCode == menuInputENUM.down then
            activeElement:change(menuInputCode == menuInputENUM.up)
        elseif menuInputCode == menuInputENUM.enter then
            autoRepeatStop()
            activeElement:confirm()
        elseif menuInputCode == menuInputENUM.back then
            autoRepeatStop()
            activeElement:cancel()
        end
    end
end

function Slider:initialize(initTbl)
    self._type = "Slider"
    self._pressable = true
    self._pressed = false
    assertType(text, "Text", { "string", "function", "nil" })
    self._text = (initTbl and initTbl.text) and initTbl.text or nil
    assertType(text, "Precision", { "number", "nil" })
    self._precision = (initTbl and initTbl.precision) and initTbl.precision or nil
    assertType(text, "Min Calue", { "number", "nil" })
    self._minValue = (initTbl and initTbl.min) and initTbl.min or nil
    assertType(text, "Mac Value", { "number", "nil" })
    self._maxValue = (initTbl and initTbl.max) and initTbl.max or nil
    assertType(text, "Increment/Decrement Step", { "number", "nil" })
    self._step = (initTbl and initTbl.step) and initTbl.step or 1

    assertType(text, "Value", { "number", "nil" })
    local value = (initTbl and initTbl.value) and initTbl.value or 0
    if self._minValue then value = mathMax(self._minValue, value) end
    if self._maxValue then value = mathMin(self._maxValue, value) end
    self._value = value

    self._inputHandler = sliderInputHandler
end

function Slider:setValue(value)
    assertType(value, "Value", "number")
    self._value = value
end

function Slider:getValue()
    return self._value
end

function Slider:setPrecision(precision)
    assertType(value, "Precision", { "number", "nil" })
    if precision then
        assert(precision >= 0, "Precision should be 0 or more")
        self._precision = precision
    else
        self._precision = nil
    end
end

function Slider:setMinValue(minValue)
    assertType(minValue, "MinValue", { "number", "nil" })
    if minValue then
        self._minValue = minValue
        self._value = mathMax(minValue, value)
    else
        self._minValue = nil
    end
end

function Slider:setMaxValue(maxValue)
    assertType(maxValue, "Value", { "number", "nil" })
    if maxValue then
        self._minValue = maxValue
        self._value = mathMin(maxValue, value)
    else
        self._minValue = nil
    end
end

function Slider:setStep(step)
    assertType(step, "Step", "number")
    self._step = step
end

function Slider:press()
    self._pressed = true
    self._oldValue = self._value

    activateElement(self)
end

function Slider:change(direction)
    local value = self._value

    self._value = self._value + self._step * (direction == true and 1 or -1)
    if self._minValue then self._value = mathMax(self._value, self._minValue) end
    if self._maxValue then self._value = mathMin(self._value, self._maxValue) end

    if self._onChange then self._onChange(self._value) end
end

function Slider:confirm()
    self._pressed = false
    self._oldValue = nil

    if self._onConfirm then self._onConfirm(self._value) end

    deactivateElement()
end

function Slider:cancel()
    self._pressed = false
    self._value = self._oldValue
    self._oldValue = nil

    deactivateElement()
end

function Slider:onConfirm(func)
    assertType(func, "On Confirm Function", "function")
    self._onConfirm = func
end

function Slider:onChange(func)
    assertType(func, "On Confirm Function", "function")
    self._onChange = func
end

function Slider:render(pos, isSelected)
    if self._pressed or isSelected then
        local bgColor = self._pressed and COLORS.textBright or COLORS.cursor
        render.setColor(bgColor)
        render.drawRect(
            windowPosX - windowMarginX,
            windowPosY + rowHeight * pos,
            windowWidth + windowMarginX * 2,
            rowHeight
        )
    end

    local textColor = self._pressed and COLORS.cursor or (isSelected and COLORS.textBright or COLORS.text)
    render.setColor(textColor)

    if self._text then
        local text = self._text

        if type(self._text) == "function" then
            text = self._text()
            assert(type(text) == "string", "Text function returned non string value")
        end

        if type(self._text) ~= "string" then
            text = tostring(text)
        end

        render.drawText(
            windowPosX, windowPosY + (fontHeight + rowPadding) * pos + rowPadding * 0.5,
            text,
            TEXT_ALIGN.LEFT
        )
    end

    if self._value then
        render.drawText(
            windowPosX + windowWidth, windowPosY + (fontHeight + rowPadding) * pos + rowPadding * 0.5,
            "[" ..
            (self._precision and string.format("%.0" .. self._precision .. "f", self._value) or tostring(self._value))
            .. "]",
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

    for i, child in ipairs(currentMenu:getChildren()) do
        isSelected = i == cursor
        child:render(i - 1, isSelected)
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
