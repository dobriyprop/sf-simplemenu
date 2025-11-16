--@name simple menu usage sample
--@author dobriyprop
--@client

--@include sf-simplemenu.lua

local menuFont = render.createFont("Default", 20, 500, true, false, false, false, 0, false, 0)

local simpleMenu = require("sf-simplemenu.lua")

simpleMenu:setWindowMargins(4, 4)
simpleMenu:setRowPadding(4)
simpleMenu:setFont(menuFont)
simpleMenu:setDescriptionDelay(1)

local mainMenu = simpleMenu:createInstance("Menu")
simpleMenu:setRoot(mainMenu)

local mainMenuLabel = simpleMenu:createInstance("Label")
mainMenuLabel:setText("Main Menu")
mainMenu:addChild(mainMenuLabel)

local staticLabels = simpleMenu:createInstance("Menu")
staticLabels:setText("Static Labels")
mainMenu:addChild(staticLabels)

for i = 1, 50 do
    local label = simpleMenu:createInstance("Label")
    label:setText("Label " .. i)
    staticLabels:addChild(label)
end

local dynamicLabels = simpleMenu:createInstance("Menu")
dynamicLabels:setText("Dynamic Labels")
mainMenu:addChild(dynamicLabels)

for j = 1, 10 do
    local label = simpleMenu:createInstance("Label")
    label:setText(function() return "curtime()" .. tostring(math.round(timer.curtime(), 3)) end)
    dynamicLabels:addChild(label)
end

local buttons = simpleMenu:createInstance("Menu")
buttons:setText("Buttons")
mainMenu:addChild(buttons)

local printButton = simpleMenu:createInstance("Button")
printButton:setText("Print \"Hello World!\"")
printButton:onPress(function() print("Hello World!") end)
buttons:addChild(printButton)

local pressReleaseButton = simpleMenu:createInstance("Button")
pressReleaseButton:setText("I change name when pressed!")
pressReleaseButton:onPress(function() pressReleaseButton:setText("I change name when released!") end)
pressReleaseButton:onRelease(function() pressReleaseButton:setText("I change name when pressed!") end)
buttons:addChild(pressReleaseButton)

local toggleButton = simpleMenu:createInstance("Button")
local toggleValue = false
toggleButton:setText("Toggle Button")
toggleButton:setValue(function() return "[" .. (toggleValue and "ON" or "OFF") .. "]" end)
toggleButton:onPress(function() toggleValue = not toggleValue end)
buttons:addChild(toggleButton)

local slider = simpleMenu:createInstance("Slider",
    {
        text = "Slider test",
        value = 5,
        precision = 2,
        step = 0.05,
        min = 0,
        max = 10,
        description = "testtesttesttesttesttesttest\ntest\ntest\ntest\ntest\ntest\ntest\ntest\ntest",
    })
slider:onChange(function(value) print("On Change:", value) end)
slider:onConfirm(function(value) print("On Confirm:", value) end)
mainMenu:addChild(slider)

local keyReader = simpleMenu:createInstance("KeyReader", { text = "Key Reader Test" })
keyReader:onConfirm(function(value) print("On Confirm:", value) end)
mainMenu:addChild(keyReader)

local dropDown = simpleMenu:createInstance("Dropdown", {
    text = "Dropdown Menu Test",
    options = { "Option 1", "Option 2", "Option 3", "Option 4" },
})
dropDown:onConfirm(function(optionNumber, optionName) print("On Confirm:", optionNumber, optionName) end)
dropDown:setParent(mainMenu)

enableHud(_, true)
simpleMenu:Open(true, true)
