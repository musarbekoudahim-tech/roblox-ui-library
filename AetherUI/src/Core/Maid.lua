--!strict
--[[
	AetherUI • Core/Maid
	Tracks connections, instances, threads and callbacks for deterministic cleanup.
]]

export type Task = RBXScriptConnection | Instance | thread | () -> () | { Disconnect: (any) -> () } | { Destroy: (any) -> () }

export type Maid = {
	Add: <T>(self: Maid, task: T & Task) -> T,
	Remove: (self: Maid, task: Task) -> (),
	Clean: (self: Maid) -> (),
	Destroy: (self: Maid) -> (),
}

local Maid = {}
Maid.__index = Maid

function Maid.new(): Maid
	return (setmetatable({ _tasks = {} :: { Task } }, Maid) :: any) :: Maid
end

local function cleanTask(item: Task)
	local itemType = typeof(item)
	if itemType == "RBXScriptConnection" then
		(item :: RBXScriptConnection):Disconnect()
	elseif itemType == "Instance" then
		(item :: Instance):Destroy()
	elseif itemType == "thread" then
		pcall(task.cancel, item :: thread)
	elseif itemType == "function" then
		(item :: () -> ())()
	elseif itemType == "table" then
		local tbl = item :: any
		if type(tbl.Disconnect) == "function" then
			tbl:Disconnect()
		elseif type(tbl.Destroy) == "function" then
			tbl:Destroy()
		elseif type(tbl.Clean) == "function" then
			tbl:Clean()
		end
	end
end

function Maid:Add(item)
	table.insert(self._tasks, item)
	return item
end

function Maid:Remove(item)
	local index = table.find(self._tasks, item)
	if index then
		table.remove(self._tasks, index)
	end
end

function Maid:Clean()
	local tasks = self._tasks
	self._tasks = {}
	for i = #tasks, 1, -1 do
		cleanTask(tasks[i])
	end
end

function Maid:Destroy()
	self:Clean()
end

return Maid
