-- Main Module:
local Table = {}

function Table.Copy<T>(Input: T, IsDeep: boolean?): T
	local RetypedInput: any = Input
	local Copy: any = {}

	for Key, Value in RetypedInput do
		if typeof(Value) == "table" and IsDeep then
			Copy[Key] = Table.Copy(Value, IsDeep)
		else
			Copy[Key] = Value
		end
	end

	return Copy
end

return Table
