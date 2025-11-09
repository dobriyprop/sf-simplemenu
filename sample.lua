--@name simple menu usage sample
--@author dobriyprop
--@client

--@include sf-simplemenu.lua
SimpleMenu = require("sf-simplemenu.lua")

SimpleMenu:printClasses()

Menu = SimpleMenu:createElement("Menu")
for i = 1, 10 do
    local label = SimpleMenu:createElement("Label", Menu)
    label:setName(str(i), "Label " .. i)
end

enableHud(_, true)

SimpleMenu:Open()
