-- Modules:
local Preview = require(script.Preview)
local Selection = require(script.Selection)

-- Main Module:
local Interface = {}
Interface.Preview = Preview
Interface.Selection = Selection

function Interface.Load(Plugin: Plugin)
	Preview.Load(Plugin)
	Selection.Load(Plugin)
end

return Interface
