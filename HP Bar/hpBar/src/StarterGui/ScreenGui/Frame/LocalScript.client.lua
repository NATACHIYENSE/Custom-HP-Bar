--driver code

local res = game:GetService('ReplicatedStorage')
local HPBar = require(res.HPBar)

local main = script.Parent
local resetB = main:WaitForChild('reset')
local healB = main:WaitForChild('heal')
local tinyB = main:WaitForChild('tiny')
local smallB = main:WaitForChild('small')
local mediumB = main:WaitForChild('medium')
local largeB = main:WaitForChild('large')
local killB = main:WaitForChild('kill')

local test: HPBar.HPBar
local function init()
	if test then
		test:Destroy()
	end
	test = HPBar.new{
		Adornee = workspace:WaitForChild('R6'):WaitForChild('HumanoidRootPart'),
		MaxHP = 100000,
		Label = 'testing 123',
		Title = 'EXPERIMENTAL',
	}
end

local invertDmg: number = 1
healB.MouseButton1Up:Connect(function()
	invertDmg *= -1
	healB.Text = `Invert damage ({invertDmg == -1})`
end)
local function hurtWrapper(from: number, to: number): () -> ()
	return function()
		if test and not test.__deleted then
			test:Inflict(math.random(from, to)*invertDmg)
			return
		end
		warn('Reset the health bar!')
	end
end

resetB.MouseButton1Click:Connect(init)
tinyB.MouseButton1Click:Connect(hurtWrapper(10, 100))
smallB.MouseButton1Click:Connect(hurtWrapper(100, 1000))
mediumB.MouseButton1Click:Connect(hurtWrapper(2000, 5000))
largeB.MouseButton1Click:Connect(hurtWrapper(5000, 20_000))
killB.MouseButton1Click:Connect(hurtWrapper(1e6, 1e6))

init()