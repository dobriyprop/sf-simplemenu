--@name simple menu usage sample
--@author dobriyprop
--@client

--@include sf-simplemenu.lua
SimpleMenu = require("sf-simplemenu.lua")

Menu = SimpleMenu.classes.Menu:new()

SimpleMenu:setRoot(Menu)

for i = 1, 10 do
    local Label = SimpleMenu.classes.Label:new()
    Label:setName(tostring(i), "Label " .. i)
    --Menu:addElement(Label)
    Menu.elements[#Menu.elements + 1] = Label
end

enableHud(_, true)

SimpleMenu:Open()
