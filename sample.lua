--@name simple menu usage sample
--@author dobriyprop
--@client

--@include sf-simplemenu.lua
SimpleMenu = require("sf-simplemenu.lua")

SimpleMenu:setWindowMargins(4, 0)
SimpleMenu:setRowPadding(4)

Menu = SimpleMenu:createInstance("Menu")

SimpleMenu:setRoot(Menu)

for i = 0, 4 do
    local SubMenu = SimpleMenu:createInstance("Menu")
    SubMenu:setText("Sub Menu " .. i + 1)
    Menu:addChild(SubMenu)

    for j = 1, 15 do
        local Label = SimpleMenu:createInstance("Label")
        Label:setText("Label " .. i * 15 + j)
        SubMenu:addChild(Label)
    end
end

enableHud(_, true)
SimpleMenu:Open(true, false)
