local tws = game:GetService('TweenService')
local dbs = game:GetService('Debris')

local ex = script:WaitForChild('HealthBar')

type Object = typeof(ex)
type class = {
	--universal configurations
	DefaultBarColor: Color3,
	TweenInfo: TweenInfo,
	TweenInfoFade: TweenInfo,
	TweenInfoShake: TweenInfo,
	TweenInfoFlash: TweenInfo,
	FeedBases: {TextLabel},
	FeedTypeRegimes: {number},
	FeedTweenInfo: TweenInfo,
	FeedTweenProperty: {[string]: any},
	
	PropertiesOnInflict: {[string]: {[string]: any}},
	
	new: (data: constructor) -> HPBar,
}
type constructor = {
	Adornee: BasePart,
	MaxHP: number,
	CurrentHP: number?,
	BarColor: Color3?,
	Label: string, --nametag
	Title: string, --secondary header
	DestroyManually: boolean?, --object will not automatically destroy itself when health reaches zero
}
type attributes = constructor & {
	Object: Object,
	CurrentHP: number,
	BarColor: Color3,
	FadeIn: Tween,
	FadeOut: Tween,
	TweensOnInflict: {Tween},
	
	--hidden/internal attributes
	__buffering: boolean?,
	__deleting: boolean?,
	__deleted: boolean?,
	__nextAnimAlpha: number,
	__lastAnimAlpha: number,
	
	--instances
	__mainCG: typeof(ex.Main),
	__labelF: typeof(ex.Main.Label),
	__titleF: typeof(ex.Main.Title),
	__absHpL: typeof(ex.Main.Bar.AbsHP),
	__perHpL: typeof(ex.Main.Bar.PerHP),
	__levelF: typeof(ex.Main.Bar.Level),
	__bufferF: typeof(ex.Main.Bar.Buffer),
}
export type HPBar = attributes & {
	__animateBarAsync: (self: HPBar, to: number) -> (), --yields; tweens the health bar
	__newFeed: (self: HPBar, damage: number, percentage: number) -> (), --generates a new damage feed
	Inflict: (self: HPBar, damage: number) -> (), --deal a set amount of damage, can be negative to heal
	SetHealth: (self: HPBar, currentHP: number) -> (), --just for QoL
	Update: (self: HPBar, ignoreBar: boolean?) -> (),
	Destroy: (self: HPBar) -> (),
}

local HPBar = {}::class do
	HPBar.DefaultBarColor = Color3.fromRGB(170, 0, 0)
	HPBar.TweenInfo = TweenInfo.new(.5, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut)
	HPBar.TweenInfoFade = TweenInfo.new(2)
	HPBar.TweenInfoShake = TweenInfo.new(.5, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out)
	HPBar.TweenInfoFlash = TweenInfo.new(.1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	HPBar.FeedBases = {
		script:WaitForChild('Feed0'),
		script:WaitForChild('Feed1'),
		script:WaitForChild('Feed2'),
		script:WaitForChild('Feed3'),
	}
	HPBar.FeedTypeRegimes = {0, .05, .15, math.huge}
	
	HPBar.FeedTweenInfo = TweenInfo.new(1, Enum.EasingStyle.Linear)
	HPBar.FeedTweenProperty = {Size = UDim2.new(1, 0, 1, 100), TextTransparency = 1}
	
	HPBar.PropertiesOnInflict = {
		__perHpL = {AnchorPoint = Vector2.new(1, 5), TextStrokeColor3 = Color3.new(1, 1, 1),},
		__levelF = {BackgroundColor3 = Color3.new(1, 1, 1)},
	}
end HPBar.__index = HPBar

function HPBar.new(data: constructor): HPBar	
	local new: Object = ex:Clone()
	local newMain = new:WaitForChild('Main')
	local newBar = newMain:WaitForChild('Bar')
	
	local self: attributes = {
		Adornee = data.Adornee,
		Object = new,
		MaxHP = data.MaxHP,
		CurrentHP = data.CurrentHP or data.MaxHP,
		BarColor = data.BarColor or HPBar.DefaultBarColor,
		Label = data.Label,
		Title = data.Title,
		DestroyManually = data.DestroyManually,
		FadeIn = tws:Create(newMain, HPBar.TweenInfoFade, {GroupTransparency = 0}),
		FadeOut = tws:Create(newMain, HPBar.TweenInfoFade, {GroupTransparency = 1}),
		
		TweensOnInflict = {}, --EDIT BELOW AFTER TABLE DECLARATION
		
		__nextAnimAlpha = 1,
		__lastAnimAlpha = 1,
		
		__mainCG = newMain,
		__labelF = newMain:WaitForChild('Label'),
		__titleF = newMain:WaitForChild('Title'),
		__absHpL = newBar:WaitForChild('AbsHP'),
		__perHpL = newBar:WaitForChild('PerHP'),
		__levelF = newBar:WaitForChild('Level'),
		__bufferF = newBar:WaitForChild('Buffer'),
	}
	
	self.__nextAnimAlpha = self.CurrentHP/self.MaxHP
	self.__lastAnimAlpha = self.__nextAnimAlpha
	self.Object.Parent = self.Adornee
	self.TweensOnInflict = {
		tws:Create(self.__perHpL, HPBar.TweenInfoShake, {AnchorPoint = Vector2.new(1, 0), TextStrokeColor3 = Color3.new(),}),
		tws:Create(self.__levelF, HPBar.TweenInfoFlash, {BackgroundColor3 = self.BarColor}),
	}
	
	local self: HPBar = setmetatable(self, HPBar)::any
	
	self:Update(false)
	
	return self
end

function HPBar.Update(self: HPBar, ignoreBar: boolean?)
	if self.__deleted then
		return error('Attempt to update destroyed HPBar object')
	end
	
	local alpha = self.CurrentHP/self.MaxHP
	
	self.Object.Adornee = self.Adornee
	self.__labelF.Text = self.Label
	self.__titleF.Text = self.Title
	self.__absHpL.Text = `{self.CurrentHP}/{self.MaxHP}`
	self.__perHpL.Text = `{math.ceil(alpha*100)}%`
	self.__levelF.BackgroundColor3 = self.BarColor
	
	if self.CurrentHP::number <= 0 and not self.DestroyManually then
		self.__deleting = true
		task.spawn(function()
			self.FadeOut:Play()
			self.FadeOut.Completed:Wait()
			self:Destroy()
		end)
	end
	
	if ignoreBar then return end
	local size: UDim2 = UDim2.fromScale(alpha, 1) 
	self.__levelF.Size = size
	self.__bufferF.Size = size
end

function HPBar.__animateBarAsync(self: HPBar, to: number)
	if self.__deleted then
		return
	end
	
	if to == self.__lastAnimAlpha then
		return
	end
	
	self.__buffering = true
	local pt = {Size = UDim2.fromScale(to, 1)}
	local tw1 = tws:Create(self.__levelF, HPBar.TweenInfo, pt)
	local tw2 = tws:Create(self.__bufferF, HPBar.TweenInfo, pt)
	
	if self.__lastAnimAlpha > to then
		tw1:Play()
		tw1.Completed:Wait()
		tw2:Play()
		tw2.Completed:Wait()
	else --if the entity is healing, reverse the animation order
		tw2:Play()
		tw2.Completed:Wait()
		tw1:Play()
		tw1.Completed:Wait()
	end
	
	self.__buffering = false
	
	self.__lastAnimAlpha = to
	if self.__nextAnimAlpha ~= self.__lastAnimAlpha then
		self:__animateBarAsync(self.__nextAnimAlpha)
	end
end

function HPBar.__newFeed(self: HPBar, damage: number, percentage: number)
	local regime: number = 1
	for r, upper in HPBar.FeedTypeRegimes do
		if percentage <= upper then
			regime = r
			break
		end
	end
	local new = HPBar.FeedBases[regime]:Clone()
	new.Text = if damage > 0 then damage else '+'..-damage
	new.Parent = self.Object
	tws:Create(new, HPBar.FeedTweenInfo, HPBar.FeedTweenProperty):Play()
	dbs:AddItem(new, HPBar.FeedTweenInfo.Time)
end

function HPBar.Inflict(self: HPBar, damage: number)
	if self.__deleted then
		return
	end
	
	if damage == 0 then
		return
	end
	
	self.CurrentHP = math.clamp(self.CurrentHP - damage, 0, self.MaxHP)
	self.__nextAnimAlpha = self.CurrentHP/self.MaxHP
	self:Update(true)
	self:__newFeed(damage, damage/self.MaxHP)
	
	for k, v in HPBar.PropertiesOnInflict do
		local obj = (self::any)[k]
		for property, value in v do
			obj[property] = value
		end
	end
	for _, v in self.TweensOnInflict do
		if v.PlaybackState == Enum.PlaybackState.Playing then
			v:Cancel()
		end
		v:Play()
	end
	
	if self.__buffering then	
		return
	end
	task.spawn(self.__animateBarAsync, self, self.__nextAnimAlpha)
end

function HPBar.SetHealth(self: HPBar, currentHP: number)
	if self.__deleted then
		return
	end
	
	self:Inflict(self.CurrentHP - currentHP)
end

function HPBar.Destroy(self: HPBar)
	if self.__deleted then
		return
	end
	
	self.__mainCG = nil
	self.__labelF = nil
	self.__titleF = nil
	self.__absHpL = nil
	self.__perHpL = nil
	self.__levelF = nil
	self.__bufferF = nil
	self.Object:Destroy()
	self.Object = nil
	self.__deleted = true
	self.__deleting = false	
	self = nil::any
end

return HPBar::class
