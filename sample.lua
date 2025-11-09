--@name simple menu usage sample
--@author dobriyprop
--@client

--@include sf-simplemenu.lua
SimpleMenu = require("sf-simplemenu.lua")

Menu = SimpleMenu:createInstance("Menu")
for i = 1, 10 do
    Label = SimpleMenu:createInstance("Label", Menu)
    Label
end
