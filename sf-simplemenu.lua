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

--create a reverse key ENUM table to get Key name by ENUM code

local inputENUMToKey = {}

for k, v in pairs(inputENUM) do
    inputENUMToKey[v] = k
end

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
    [inputENUM.E] = menuInputENUM.enter,
    [inputENUM.Q] = menuInputENUM.back,

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

local menuInputState = {
    [menuInputENUM.up] = false,
    [menuInputENUM.down] = false,
    [menuInputENUM.left] = false,
    [menuInputENUM.right] = false,
    [menuInputENUM.enter] = false,
    [menuInputENUM.back] = false,
}

local COLORS = {
    cursor = Color(5, 55, 215),
    text = Color(215, 215, 215),
    textBright = Color(255, 255, 255),
    background = Color(0, 0, 0, 210),
}

local lastLockControl = 0

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
local windowMinWidth = 50
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
    if menuInputs[key] then
        menuInputState[menuInputs[key]] = pressed
    end
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
---@class Widget
local Widget = class("Widget")
SimpleMenu.classes.Widget = Widget

--initialize base widget
function Widget:initialize(tbl)
    self._type = "Widget"
    self._pressable = false
    self._selectable = false

    if tbl then
        assertType(tbl, "Table of arguments", "table")
        assertType(tbl.name, "Name", { "string", "nil" })
        self._name = tbl.name and tbl.name or nil
    else
        self._name = nil
    end
end

function Widget:isPressable()
    return self._pressable
end

function Widget:isSelectable()
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

function Widget:renderGetTextWidth()
    return 0
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
---@class Label : Widget
local Label = class("Label", Widget)
SimpleMenu.classes.Label = Label

function Label:initialize(tbl)
    Widget.initialize(self, tbl)
    self._type = "Label"

    if tbl then
        assertType(tbl, "Table of arguments", "table")
        assertType(tbl.text, "Text", { "string", "function", "nil" })
        self._text = tbl.text and tbl.text or nil
    end
end

--allows for text be defined by string or function on every render call
function Label:setText(text)
    assertType(text, "Text", { "string", "function" })
    self._text = text
end

function Label:getText()
    return self._text
end

function Label:renderGetTextWidth()
    local totalWidth = 0

    totalWidth = totalWidth + Widget.renderGetTextWidth(self)

    if self._text then
        local text = self._text

        if type(self._text) == "function" then
            text = self._text()
            assert(type(text) == "string", "Text function returned non string value")
        end

        local width, _ = render.getTextSize(text)
        totalWidth = totalWidth + width
    end

    return totalWidth
end

function Label:render(pos, isSelected)
    Widget.render(self, pos, isSelected)

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
---@class Menu : Label
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
        if (menuInputCode == menuInputENUM.up or menuInputCode == menuInputENUM.down) and
            not (menuInputState[menuInputENUM.enter] or menuInputState[menuInputENUM.back])
        then
            local direction = menuInputCode == menuInputENUM.up and -1 or 1
            local newCursor = cursor

            repeat
                newCursor = newCursor + direction
            until
                (direction > 0 and newCursor > #menuChildren) or
                (direction < 0 and newCursor < 1) or
                menuChildren[newCursor]:isSelectable()

            if (direction > 0 and newCursor <= #menuChildren) or (direction < 0 and newCursor >= 1) then
                cursor = newCursor
            end
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

function Menu:initialize(tbl)
    self._type = "Menu"
    self._pressable = true
    self._selectable = true

    if tbl then
        assertType(tbl, "Table of arguments", "table")
        assertType(tbl.text, "Text", { "string", "function", "nil" })
        self._text = tbl.text and tbl.text or nil

        assertType(tbl.children, "Children table", { "table", "nil" })
        assert(
            function()
                if tbl.children == nil or table.isEmpty(tbl.children) then return true end

                for _, child in ipairs(tbl.children) do
                    if child.getType == nil or SimpleMenu.classes[child.getType()] == nil then
                        return false
                    end
                end

                return true
            end,
            "One of specified children does not belong to any registered class"
        )

        self._children = tbl.children and tbl.children or {}
    else
        self._text = nil
        self._children = {}
    end

    self._inputHandler = menuInputHandler
end

function Menu:press()
    if #self._children > 0 then
        pushInputStack(self._inputHandler)
        tableInsert(menuStack, self)
        tableInsert(cursorStack, cursor)
        cursor = 1
    end
end

function Menu:release()
    --placeholder
end

function Menu:back()
    popInputStack()
    tableRemove(menuStack)
    cursor = tableRemove(cursorStack)
end

function Menu:addChild(child, position)
    assertType(child, "Child instance", "table")
    if position then
        assertType(position, "Position", "number")
        tableInsert(self._children, position, child)
    else
        tableInsert(self._children, child)
    end
end

function Menu:getChildren()
    return self._children
end

function Menu:renderGetTextWidth()
    local totalWidth = render.getTextSize("\t")

    totalWidth = totalWidth + Label.renderGetTextWidth(self)
    local width, _ = render.getTextSize("->")
    totalWidth = totalWidth + width

    return totalWidth
end

function Menu:render(pos, isSelected)
    Label.render(self, pos, isSelected)
    local textColor = isSelected and COLORS.textBright or COLORS.text
    render.setColor(textColor)
    render.drawText(
        windowPosX + windowWidth, windowPosY + (fontHeight + rowPadding) * pos + rowPadding * 0.5,
        "->",
        TEXT_ALIGN["RIGHT"]
    )
end

--Button
---@class Button : Label
local Button = class("Button", Label)
SimpleMenu.classes.Button = Button

function Button:initialize(tbl)
    self._type = "Button"
    self._pressable = true
    self._selectable = true
    self._pressed = false

    if tbl then
        assertType(tbl, "Table of arguments", "table")
        assertType(tbl.value, "Text", { "string", "function", "nil" })
        self._text = tbl.text and tbl.text or nil
        assertType(tbl.value, "Value", { "string", "function", "nil" })
        self._value = tbl.value and tbl.value or nil
    else
        self._text = nil
        self._value = nil
    end
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

function Button:renderGetTextWidth()
    local totalWidth = render.getTextSize("\t")

    if self._text then
        local text = self._text

        if type(self._text) == "function" then
            text = self._text()
            assert(type(text) == "string", "Text function returned non string value")
        end

        if type(self._text) ~= "string" then
            text = tostring(text)
        end

        local width, _ = render.getTextSize(text)
        totalWidth = totalWidth + width
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

        local width, _ = render.getTextSize(text)
        totalWidth = totalWidth + width
    end

    return totalWidth
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

--Value slider
---@class Slider: Label
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

function Slider:initialize(tbl)
    self._type = "Slider"
    self._pressable = true
    self._selectable = true
    self._pressed = false

    if tbl then
        assertType(tbl, "Table of arguments", "table")

        assertType(text, "Text", { "string", "function", "nil" })
        self._text = (tbl and tbl.text) and tbl.text or nil
        assertType(text, "Precision", { "number", "nil" })
        self._precision = (tbl and tbl.precision) and tbl.precision or nil
        assertType(text, "Min Calue", { "number", "nil" })
        self._minValue = (tbl and tbl.min) and tbl.min or nil
        assertType(text, "Mac Value", { "number", "nil" })
        self._maxValue = (tbl and tbl.max) and tbl.max or nil
        assertType(text, "Increment/Decrement Step", { "number", "nil" })
        self._step = (tbl and tbl.step) and tbl.step or 1

        assertType(text, "Value", { "number", "nil" })
        local value = (tbl and tbl.value) and tbl.value or 0
        if self._minValue then value = mathMax(self._minValue, value) end
        if self._maxValue then value = mathMin(self._maxValue, value) end
        self._value = value
    else
        self._text = nil
        self._precision = nil
        self._minValue = nil
        self._maxValue = nil
        self._step = 1
        self._value = 0
    end

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
    local oldValue = self._value

    self._value = self._value + self._step * (direction == true and 1 or -1)
    if self._minValue then self._value = mathMax(self._value, self._minValue) end
    if self._maxValue then self._value = mathMin(self._value, self._maxValue) end

    if self._onChange and self._value ~= oldValue then self._onChange(self._value) end
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

function Slider:renderGetTextWidth()
    local totalWidth = render.getTextSize("\t")

    if self._text then
        local text = self._text

        if type(self._text) == "function" then
            text = self._text()
            assert(type(text) == "string", "Text function returned non string value")
        end

        if type(self._text) ~= "string" then
            text = tostring(text)
        end

        local width, _ = render.getTextSize(text)
        totalWidth = totalWidth + width
    end

    if self._value then
        local width, _ = render.getTextSize(
            "[" ..
            (self._precision and stringFormat("%.0" .. self._precision .. "f", self._value) or tostring(self._value))
            .. "]"
        )
        totalWidth = totalWidth + width
    end

    return totalWidth
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
            (self._precision and stringFormat("%.0" .. self._precision .. "f", self._value) or tostring(self._value))
            .. "]",
            TEXT_ALIGN.RIGHT
        )
    end
end

--Key reader
---@class KeyReader : Label
local KeyReader = class("KeyReader", Label)
SimpleMenu.classes.KeyReader = KeyReader

local function keyReaderInputHandler(pressed, key)
    --local KeyName = inputENUMToKey[key]
    if pressed == true then
        autoRepeatStop()
        activeElement:confirm(key)
    end
end

function KeyReader:initialize(tbl)
    self._type = "KeyReader"
    self._pressable = true
    self._selectable = true
    self._pressed = false
    if tbl then
        assertType(tbl, "Table of arguments", "table")
        assertType(text, "Text", { "string", "function", "nil" })
        self._text = (tbl and tbl.text) and tbl.text or nil

        assertType(text, "Value", { "number", "nil" })
        self._value = (tbl and tbl.value) and tbl.value or nil
    else
        self._text = nil
        self._value = nil
    end

    self._inputHandler = keyReaderInputHandler
end

function KeyReader:setValue(value)
    assertType(value, "Value", { "string", "number", "nil" })

    if type(value) == string then
        assert(inputENUM[value] ~= nil, "Unknown key name specified")
        self._value = inputENUM[value]
    else
        self._value = value
    end
end

function KeyReader:getValue()
    return self._value, inputENUM[self._value]
end

function KeyReader:press()
    self._pressed = true
    --[[
     if not input.canLockControls() then return end

    self._kbLockState = input.isControlLocked()
    self._mouseLockState = input.getCursorVisible()

    if self._kbLockState == false then input.lockControls(true) end
    if self._mouseLockState == false then input.enableCursor(true) end
 ]]
    activateElement(self)
end

function KeyReader:confirm(key)
    self._pressed = false
    self._value = key
    --[[
    if input.isControlLocked() ~= self._kbLockState then input.lockControls(self._kbLockState) end
    if input.getCursorVisible() ~= self._mouseLockState then input.enableCursor(self._mouseLockState) end
 ]]
    if self._onConfirm then self._onConfirm(self._value) end
    deactivateElement()
end

function KeyReader:onConfirm(func)
    assertType(func, "On Confirm Function", { "function", "nil" })
    self._onConfirm = func
end

function KeyReader:renderGetTextWidth()
    local totalWidth = render.getTextSize("\t")

    if self._text and not self._pressed then
        local text = self._text

        if type(self._text) == "function" then
            text = self._text()
            assert(type(text) == "string", "Text function returned non string value")
        end

        if type(self._text) ~= "string" then
            text = tostring(text)
        end
        local width, _ = render.getTextSize(text)
        totalWidth = totalWidth + width
    elseif self._pressed then
        local width, _ = render.getTextSize("Press a key to assign")
        totalWidth = totalWidth + width
    end

    local width, _ = render.getTextSize("[" .. (self._value and inputENUMToKey[self._value] or " ") .. "]")
    totalWidth = totalWidth + width

    return totalWidth
end

function KeyReader:render(pos, isSelected)
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

    if self._text and not self._pressed then
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
    elseif self._pressed then
        render.drawText(
            windowPosX, windowPosY + (fontHeight + rowPadding) * pos + rowPadding * 0.5,
            "Press a key to assign",
            TEXT_ALIGN.LEFT
        )
    end

    --print(self._value, inputENUMToKey[self._value])
    render.drawText(
        windowPosX + windowWidth, windowPosY + (fontHeight + rowPadding) * pos + rowPadding * 0.5,
        "[" .. (self._value and inputENUMToKey[self._value] or " ") .. "]",
        TEXT_ALIGN.RIGHT
    )
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

    if currentMenu == nil then return end

    render.setFont(font)
    _, fontHeight = render.getTextSize("TEST")
    windowHeight = (fontHeight + rowPadding) * #currentMenu:getChildren()
    rowHeight = fontHeight + rowPadding

    windowWidth = windowMinWidth

    for i, child in ipairs(currentMenu:getChildren()) do
        windowWidth = mathMax(windowWidth, child:renderGetTextWidth())
    end

    windowPosX = scrCenterX - windowWidth * 0.5
    windowPosY = scrCenterY - windowHeight * 0.5

    render.setColor(COLORS.background)
    render.drawRect(
        windowPosX - windowMarginX,
        windowPosY - windowMarginY,
        windowWidth + windowMarginX * 2,
        windowHeight + windowMarginY * 2
    )

    for i, child in ipairs(currentMenu:getChildren()) do
        isSelected = i == cursor and child:isSelectable()
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

function SimpleMenu:onOpen(func)
    assertType(func, "Function", { "function", "nil" })
    SimpleMenu.onOpen = func
end

function SimpleMenu:onClose(func)
    assertType(func, "Function", { "function", "nil" })
    SimpleMenu.onClose = func
end

--initializes and opens menu window
function SimpleMenu:Open(lockControls, enableCursor)
    assertType(lockControls, "Lock Controls", { "boolean", "nil" })
    assertType(enableCursor, "Enable Cursor", { "boolean", "nil" })

    if lockControls then
        if not input.canLockControls() then
            print(
                "Can't lock controls yet. Please wait for " ..
                mathRound(lastLockControl + 10 - timer.curtime())
                .. " seconds and try again. Blame Sparky for this 10 sec cooldown."
            )
            return
        else
            lastLockControl = timer.curtime()
        end
    end

    if SimpleMenu.onOpen then SimpleMenu.onOpen() end

    input.lockControls((lockControls and input.canLockControls()) and lockControls or false)
    input.enableCursor((enableCursor and not input.getCursorVisible()) and enableCursor or false)

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

    if SimpleMenu.onClose then SimpleMenu.onClose() end
end

return SimpleMenu
