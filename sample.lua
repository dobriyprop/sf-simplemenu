--@name simple menu usage sample
--@author dobriyprop
--@client

--@include sf-simplemenu.lua
local simpleMenu = require("sf-simplemenu.lua")

simpleMenu:setWindowMargins(4, 0)
simpleMenu:setRowPadding(4)

local mainMenu = simpleMenu:createInstance("Menu")
simpleMenu:setRoot(mainMenu)

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

enableHud(_, true)
simpleMenu:Open(true, false)
