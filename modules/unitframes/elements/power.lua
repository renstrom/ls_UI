local _, ns = ...
local E, C, M, L, P = ns.E, ns.C, ns.M, ns.L, ns.P
local UF = P:GetModule("UnitFrames")

-- Lua
local _G = getfenv(0)

-- Blizz
local UnitGUID = _G.UnitGUID
local UnitIsConnected = _G.UnitIsConnected
local UnitIsDeadOrGhost = _G.UnitIsDeadOrGhost

-- Mine
do
	local function PostUpdate(element, unit, cur, _, max)
		if element.Inset then
			if not max or max == 0 then
				element.Inset:Collapse()
			else
				element.Inset:Expand()
			end
		end

		if element:IsShown() then
			local unitGUID = UnitGUID(unit)

			element:UpdateGainLoss(cur, max, unitGUID == element._UnitGUID)

			element._UnitGUID = unitGUID
		else
			return element.Text and element.Text:SetText(nil)
		end

		if not element.Text then
			return
		else
			if max == 0 then
				return element.Text:SetText(nil)
			elseif UnitIsDeadOrGhost(unit) or not UnitIsConnected(unit) then
				element:SetValue(0)

				return element.Text:SetText(nil)
			end
		end

		local r, g, b = element:GetStatusBarColor()
		local hex = E:RGBToHEX(E:AdjustColor(r, g, b, 0.3))

		if element.__owner.isMouseOver then
			if unit ~= "player" and unit ~= "vehicle" and unit ~= "pet" then
				return element.Text:SetFormattedText(L["BAR_COLORED_DETAILED_VALUE_TEMPLATE"], E:NumberFormat(cur, 1), E:NumberFormat(max, 1), hex)
			end
		else
			if cur == max or cur == 0 then
				if unit == "player" or unit == "vehicle" or unit == "pet" then
					return element.Text:SetText(nil)
				end
			end
		end

		element.Text:SetFormattedText(L["BAR_COLORED_VALUE_TEMPLATE"], E:NumberFormat(cur, 1), hex)
	end

	function UF:CreatePower(parent, text, textFontObject, textParent)
		local element = _G.CreateFrame("StatusBar", nil, parent)
		element:SetStatusBarTexture("Interface\\BUTTONS\\WHITE8X8")

		if text then
			text = (textParent or element):CreateFontString(nil, "ARTWORK", textFontObject)
			text:SetWordWrap(false)
			E:ResetFontStringHeight(text)
			element.Text = text
		end

		E:SmoothBar(element)
		E:CreateGainLossIndicators(element)

		element.colorPower = true
		element.colorDisconnected = true
		element.frequentUpdates = true
		element.PostUpdate = PostUpdate

		return element
	end

	function UF:UpdatePower(frame)
		local config = frame._config.power
		local element = frame.Power

		element:SetOrientation(config.orientation)

		if element.Text then
			element.Text:SetJustifyV(config.text.v_alignment or "MIDDLE")
			element.Text:SetJustifyH(config.text.h_alignment or "CENTER")
			element.Text:ClearAllPoints()

			local point1 = config.text.point1

			if point1 and point1.p then
				element.Text:SetPoint(point1.p, E:ResolveAnchorPoint(frame, point1.anchor), point1.rP, point1.x, point1.y)
			end
		end

		E:ReanchorGainLossIndicators(element, config.orientation)

		frame._mouseovers[element] = config.update_on_mouseover and true or nil

		if config.enabled and not frame:IsElementEnabled("Power") then
			frame:EnableElement("Power")
		elseif not config.enabled and frame:IsElementEnabled("Power") then
			frame:DisableElement("Power")
		end

		if frame:IsElementEnabled("Power") then
			element:ForceUpdate()
		end
	end
end

do
	local function PostUpdate(element, _, cur, max)
		if element:IsShown() then
			element:UpdateGainLoss(cur, max)
		end
	end

	function UF:CreateAdditionalPower(parent)
		local element = _G.CreateFrame("StatusBar", nil, parent)
		element:SetStatusBarTexture("Interface\\BUTTONS\\WHITE8X8")
		element:Hide()

		E:SmoothBar(element)
		E:CreateGainLossIndicators(element)

		element.colorPower = true
		element.PostUpdate = PostUpdate

		return element
	end

	function UF:UpdateAdditionalPower(frame)
		local config = frame._config.class_power
		local element = frame.AdditionalPower

		element:SetOrientation(config.orientation)

		E:ReanchorGainLossIndicators(element, config.orientation)

		if config.enabled and not frame:IsElementEnabled("AdditionalPower") then
			frame:EnableElement("AdditionalPower")
		elseif not config.enabled and frame:IsElementEnabled("AdditionalPower") then
			frame:DisableElement("AdditionalPower")
		end

		if frame:IsElementEnabled("AdditionalPower") then
			element:ForceUpdate()
		end
	end
end

do
	function UF:CreatePowerPrediction(parent1, parent2)
		local mainBar = _G.CreateFrame("StatusBar", nil, parent1)
		mainBar:SetStatusBarTexture("Interface\\BUTTONS\\WHITE8X8")
		mainBar:SetStatusBarColor(0.55, 0.75, 0.95) -- MOVE TO CONSTANTS!
		mainBar:SetReverseFill(true)
		parent1.CostPrediction = mainBar

		local altBar = _G.CreateFrame("StatusBar", nil, parent2)
		altBar:SetStatusBarTexture("Interface\\BUTTONS\\WHITE8X8")
		altBar:SetStatusBarColor(0.55, 0.75, 0.95) -- MOVE TO CONSTANTS!
		altBar:SetReverseFill(true)
		parent2.CostPrediction = altBar

		E:SmoothBar(mainBar)
		E:SmoothBar(altBar)

		return {
			mainBar_ = mainBar,
			mainBar = mainBar,
			altBar_ = altBar,
			altBar = altBar,
		}
	end

	function UF:UpdatePowerPrediction(frame)
		local config1 = frame._config.power
		local config2 = frame._config.class_power
		local element = frame.PowerPrediction

		if config1.prediction.enabled then
			local mainBar_ = element.mainBar_
			mainBar_:SetOrientation(config1.orientation)
			mainBar_:ClearAllPoints()

			if config1.orientation == "HORIZONTAL" then
				local width = frame.Power:GetWidth()
				width = width > 0 and width or frame:GetWidth()

				mainBar_:SetPoint("TOP")
				mainBar_:SetPoint("BOTTOM")
				mainBar_:SetPoint("RIGHT", frame.Power:GetStatusBarTexture(), "RIGHT")
				mainBar_:SetWidth(width)
			else
				local height = frame.Power:GetHeight()
				height = height > 0 and height or frame:GetHeight()

				mainBar_:SetPoint("LEFT")
				mainBar_:SetPoint("RIGHT")
				mainBar_:SetPoint("TOP", frame.Power:GetStatusBarTexture(), "TOP")
				mainBar_:SetHeight(height)
			end

			element.mainBar = mainBar_
		else
			element.mainBar = nil

			element.mainBar_:Hide()
			element.mainBar_:ClearAllPoints()
		end

		if config2.prediction.enabled then
			local altBar_ = element.altBar_
			altBar_:SetOrientation(config2.orientation)
			altBar_:ClearAllPoints()

			if config2.orientation == "HORIZONTAL" then
				local width = frame.AdditionalPower:GetWidth()
				width = width > 0 and width or frame:GetWidth()

				altBar_:SetPoint("TOP")
				altBar_:SetPoint("BOTTOM")
				altBar_:SetPoint("RIGHT", frame.AdditionalPower:GetStatusBarTexture(), "RIGHT")
				altBar_:SetWidth(width)
			else
				local height = frame.AdditionalPower:GetHeight()
				height = height > 0 and height or frame:GetHeight()

				altBar_:SetPoint("LEFT")
				altBar_:SetPoint("RIGHT")
				altBar_:SetPoint("TOP", frame.AdditionalPower:GetStatusBarTexture(), "TOP")
				altBar_:SetHeight(height)
			end

			element.altBar = altBar_
		else
			element.altBar = nil

			element.altBar_:Hide()
			element.altBar_:ClearAllPoints()
		end

		local isEnabled = config1.prediction.enabled or config2.prediction.enabled

		if isEnabled and not frame:IsElementEnabled("PowerPrediction") then
			frame:EnableElement("PowerPrediction")
		elseif not isEnabled and frame:IsElementEnabled("PowerPrediction") then
			frame:DisableElement("PowerPrediction")
		end

		if frame:IsElementEnabled("PowerPrediction") then
			element:ForceUpdate()
		end
	end
end
