--old driver code; NOT IN USE!!!

local res = game:GetService('ReplicatedStorage')
local HPBar = require(res.HPBar)

local test = HPBar.new{
	Adornee = workspace.Prototrode.HumanoidRootPart,
	MaxHP = 1000,
	Label = 'testing 123',
	Title = 'EXPERIMENTAL',
}

task.wait(4)
print('inflicting')

test:Inflict(1)
task.wait()

test:Inflict(100)
task.wait(3)

test:Inflict(10)
task.wait(.1)
test:Inflict(250)
test:Inflict(50)
task.wait(5)

for _ = 1, 100 do
	test:Inflict(1)
	task.wait()
end
task.wait(1)

test:SetHealth(0)
