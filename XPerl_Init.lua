-- X-Perl UnitFrames
-- Author: Zek <Boodhoof-EU>
-- License: GNU GPL v3, 29 June 2007 (see LICENSE.txt)

local init_done, gradient, conf, doneOptions
local errorCount = 0
XPerl_RequestConfig(function(new) conf = new end, "$Revision$")

-- SetTex
local highlightPositions = {	{0, 0.25, 0, 0.5},
				{0.25, 0.75, 0, 0.5},
				{0, 1, 0.5, 1},
				{0.75, 1, 0, 0.5}}
local function SetTex(self, num)
	local p = highlightPositions[num]
	if ((self.GetFrameType or self.GetObjectType)(self) == "Button") then
		if (conf.highlightSelection == 1) then
			self:SetHighlightTexture("Interface\\Addons\\XPerl\\images\\XPerl_Highlight", "ADD")
			local tex = self:GetHighlightTexture()
			tex:SetTexCoord(unpack(p))
			tex:SetVertexColor(0.86, 0.82, 0.41)
		else
			self:ClearHighlightTexture()
		end

	elseif ((self.GetFrameType or self.GetObjectType)(self) == "Frame") then
		if (self.tex) then
			self.tex:SetTexture("Interface\\Addons\\XPerl\\images\\XPerl_Highlight", "ADD")
			self.tex:SetTexCoord(unpack(p))
			self.tex:SetVertexColor(0.86, 0.82, 0.41)
			XPerl_Highlight:UnitFrameChanged(self:GetParent())
		end
	end
end

-- RegisterHighlight
local HighlightFrames = {}
function XPerl_RegisterHighlight(frame, ratio)
	HighlightFrames[frame] = ratio
	if (init_done) then
		SetTex(frame, ratio)
	end
end

-- XPerl_GetHighlightTexCoords(frame): where in XPerl_Highlight a registered highlight frame's art is
function XPerl_GetHighlightTexCoords(frame)
	return unpack(highlightPositions[HighlightFrames[frame]])
end

-- SetHighlights
local function SetHighlights()
	for k,v in pairs(HighlightFrames) do
		SetTex(k, v)
	end
end

-- XPerl_MakeGradient(self)
function XPerl_DoGradient(self, force)
	if ((force or (conf and conf.colour.gradient.enable)) and not self.tfade) then
		if (gradient) then
			if (not self.gradient) then
				local w = self:GetWidth()
				if (w and w > 10) then
					self.gradient = self:CreateTexture(nil, "BORDER")
					self.gradient:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
					self.gradient:SetBlendMode("ADD")

					local bd = self:GetBackdrop()

					if (bd) then
						self.gradient:SetPoint("TOPLEFT", bd.insets.left, -bd.insets.top)
						self.gradient:SetPoint("BOTTOMRIGHT", -bd.insets.right, bd.insets.bottom)
					else
						self.gradient:SetAllPoints()
					end
				end
			end
			if (self.gradient) then
				self.gradient:Show()
				self.gradient:SetGradient(unpack(gradient))
			end
			return true
		end
	else
		if (self.gradient) then
			self.gradient:Hide()
		end
	end
end

-- SetupUnitFrame
local function SetupUnitFrame(self)
	self:SetBackdropBorderColor(conf.colour.border.r, conf.colour.border.g, conf.colour.border.b, conf.colour.border.a)
	self:SetBackdropColor(conf.colour.frame.r, conf.colour.frame.g, conf.colour.frame.b, conf.colour.frame.a)
	XPerl_DoGradient(self)
end

-- SetupUnitFrameList
local function SetupUnitFrameList(frame, subList)

	if (conf.colour.gradient.enable) then
		local o
		if (conf.colour.gradient.horizontal) then
			o = "HORIZONTAL"
		else
			o = "VERTICAL"
		end

		local e, s = conf.colour.gradient.e, conf.colour.gradient.s
		gradient = {o, CreateColor(e.r, e.g, e.b, e.a), CreateColor(s.r, s.g, s.b, s.a)}
	end

	if (type(subList) == "table") then
		frame:SetAlpha(conf.transparency.frame)
		for k,v in pairs(subList) do
			SetupUnitFrame(v)
		end
	else
		SetupUnitFrame(frame)
	end
end

-- XPerl_RegisterUnitFrame(frame)
local UnitFrames = {}
function XPerl_RegisterPerlFrames(frame, subList)
	if (not subList) then
		subList = true
	end
	UnitFrames[frame] = subList

	if (init_done) then
		SetupUnitFrameList(frame, subList)
	end
end

-- SetupAllPerlFrames
local function SetupAllPerlFrames()
	for k,v in pairs(UnitFrames) do
		SetupUnitFrameList(k, v)
	end
end

-- XPerl_SetAllFrames
function XPerl_SetAllFrames()
	SetupAllPerlFrames()
	SetHighlights()
end

-- XPerl_pcall
function XPerl_pcall(...)
	local success, error = pcall(...)
	if (not success) then
		errorCount = errorCount + 1
		if (not doneOptions) then
			XPerl_Notice("Error:"..error)
		end
		geterrorhandler()(error)
	end
end

-- XPerl_Init()
function XPerl_Init()
	init_done = true

	C_AddOns.DisableAddOn("XPerl_TeamSpeak")

	-- Check for eCastbar and disable old frame if used.
	if (eCastingBar_Saved and eCastingBar_Player and eCastingBar_Saved[eCastingBar_Player].Enabled == 1) then
		conf.player.castBar.original = false
	elseif (BCastBar and BCastingBar and BCastBarDragButton) then
		conf.player.castBar.original = false
	end

	XPerl_pcall(XPerl_OptionActions)

	--PartyMemberFrame:UnregisterEvent("UNIT_NAME_UPDATE")

	if (CT_PartyBuffFrame1) then
		if (XPerl_party1) then
			CT_PartyBuffFrame1:Hide()
			CT_PartyBuffFrame2:Hide()
			CT_PartyBuffFrame3:Hide()
			CT_PartyBuffFrame4:Hide()
		end
		if (XPerl_Player_Pet) then
			CT_PetBuffFrame:Hide()
		end
	end

	if (CT_RAMTGroup) then
		-- Fix CTRA lockup issues for WoW 2.1
		-- Sure it's not my responsibility, but you can bet your ass I'll get blamed for it's lockups...
		CT_RAMTGroup:UnregisterEvent("UNIT_NAME_UPDATE")
		if (CT_RAMTTGroup) then	CT_RAMTTGroup:UnregisterEvent("UNIT_NAME_UPDATE")	end
		if (CT_RAPTGroup) then	CT_RAPTGroup:UnregisterEvent("UNIT_NAME_UPDATE")	end
		if (CT_RAPTTGroup) then	CT_RAPTTGroup:UnregisterEvent("UNIT_NAME_UPDATE")	end
		if (CT_RAGroup1) then
			for i = 1,8 do
				local f = _G["CT_RAGroup"..i]
				if (f) then	f:UnregisterEvent("UNIT_NAME_UPDATE")		end
			end
		end
	end

	local function EnabledAddOnVersion(addon)
		if (not C_AddOns.DoesAddOnExist(addon) or not XPerlAPI.IsAddOnEnabled(addon)) then
			return
		end
		return C_AddOns.GetAddOnMetadata(addon, "Version")
	end

	local ver = EnabledAddOnVersion("SupportFuncs")
	if (ver and tonumber(ver) and tonumber(ver) < 20000.2) then
		XPerl_Notice("Out-dated version of SupportFuncs detected. This will break the X-Perl Range Finder by replacing standard Blizzard API functions.")
	end

	ver = EnabledAddOnVersion("AutoBar")
	if (ver and ver < "2.01.00.02 beta") then
		XPerl_Notice("Out-dated version of AutoBar detected. This will taint the Targetting system for all mods that use them, including X-Perl.")
	end

	ver = EnabledAddOnVersion("TrinityBars")
	if (ver and ver <= "20003.14") then
		XPerl_Notice("Out-dated version of TrinityBars detected. This will taint the Targetting system for all mods that use them, including X-Perl.")
	end

	if (EarthFeature_AddButton) then
		EarthFeature_AddButton ({name = XPerl_ProductName,
					icon = XPerl_ModMenuIcon,
					subtext = "by "..XPerl_Author,
					tooltip = XPerl_LongDescription,
					callback = XPerl_Toggle})
	end

	if (CT_RegisterMod) then
		CT_RegisterMod(XPerl_ProductName.." "..XPerl_VersionNumber, "By "..XPerl_Author, 4, XPerl_ModMenuIcon, XPerl_LongDescription, "switch", "", XPerl_Toggle)
	end

	if (myAddOnsFrame) then
		myAddOnsList.XPerl_Description = {
			name			= XPerl_Description,
			description		= XPerl_LongDescription,
			version			= XPerl_VersionNumber,
			category		= MYADDONS_CATEGORY_OTHERS,
			frame			= "XPerl_Globals",
			optionsframe		= "XPerl_Options"
		}
	end

	XPerl_RegisterSMBarTextures()

	XPerl_Init = nil
end

-- XPerl_StatsFrame_Setup
function XPerl_StatsFrameSetup(self, others, offset)
	if (not self) then
		return
	end
	local StatsFrame = self.statsFrame
	if (not StatsFrame) then
		return
	end

        local healthBar = StatsFrame.healthBar
        local healthBarText = healthBar.text
        local healthBarPercent = healthBar.percent
        local manaBar = StatsFrame.manaBar
        local manaBarPercent = manaBar.percent
	local otherBars = {}
	local secondaryBarsShown = 0
        local percentSize = 0
	if (healthBarPercent:IsShown() or manaBarPercent:IsShown()) then
		percentSize = 35
	end

	offset = (offset or 0)
	
	healthBar:SetWidth(0)

	if (manaBar:IsShown()) then
		secondaryBarsShown = secondaryBarsShown + 1
		manaBar:SetWidth(0)
	end

	local needTicker = 0
	if (StatsFrame.energyTicker) then
		needTicker = 1
	end

	if (others) then
		for i,bar in pairs(others) do
			if (bar) then
				tinsert(otherBars, bar)
				if (bar:IsShown()) then
					secondaryBarsShown = secondaryBarsShown + 1
					bar:SetWidth(0)
				end
			end
		end
	end
	
	if (conf.bar.fat) then       
		if (StatsFrame == XPerl_Player_PetstatsFrame) then
			healthBarText:SetFontObject(GameFontNormalSmall)
		else
			healthBarText:SetFontObject(GameFontNormal)
		end

        	healthBar:ClearAllPoints()
        	healthBar:SetPoint("TOPLEFT", 5, -5)
        	healthBar:SetPoint("BOTTOMRIGHT", -(5 + percentSize), 5 + needTicker + (secondaryBarsShown * 10))

        	manaBar:ClearAllPoints()
        	manaBar:SetPoint("BOTTOMLEFT", 5, -5 + needTicker + (secondaryBarsShown * 10))
        	manaBar:SetPoint("TOPRIGHT", healthBar, "BOTTOMRIGHT", 0, 0)

		local lastBar = manaBar
		local tickerSpace = needTicker * 1.5
		for i,bar in pairs(otherBars) do
			if (bar:IsShown()) then
        	        	bar:ClearAllPoints()

        	        	bar:SetPoint("TOPLEFT", lastBar, "BOTTOMLEFT", 0, -tickerSpace)
        	        	bar:SetPoint("BOTTOMRIGHT", lastBar, "BOTTOMRIGHT", 0, -10 - tickerSpace)

				lastBar = bar
				tickerSpace = 0
			end
        	end
	else
		healthBarText:SetFontObject(GameFontNormalSmall)

        	healthBar:ClearAllPoints()
        	healthBar:SetPoint("TOPLEFT", 8, -9 + offset)
        	healthBar:SetPoint("BOTTOMRIGHT", StatsFrame, "TOPRIGHT", -(8 + percentSize), -19 + offset)

        	manaBar:ClearAllPoints()
        	manaBar:SetPoint("TOPLEFT", healthBar, "BOTTOMLEFT", 0, -2)
        	manaBar:SetPoint("BOTTOMRIGHT", healthBar, "BOTTOMRIGHT", 0, -12)

		local lastBar = manaBar
		for i,bar in pairs(otherBars) do
			if (bar:IsShown()) then
        	        	bar:ClearAllPoints()

        	        	bar:SetPoint("TOPLEFT", lastBar, "BOTTOMLEFT", 0, -2)
        	        	bar:SetPoint("BOTTOMRIGHT", lastBar, "BOTTOMRIGHT", 0, -12)

				lastBar = bar
			end
        	end
	end
end

-- XPerl_RegisterUnitText(self)
local unitText = {}
local SetTextFont, textFontOriginal
function XPerl_RegisterUnitText(self)
	tinsert(unitText, self)
	-- Frame code sets fonts again later (party names on every update, the health text with the bar layout,
	-- raid InitType): the global font goes back on top, over the new font as the text's own
	hooksecurefunc(self, "SetFontObject", function(text)
		textFontOriginal[text] = nil
		if (conf) then
			SetTextFont(text)
		end
	end)
	if (conf) then
		SetTextFont(self)
	end
end

-- Global font (conf.font): face is a LibSharedMedia font name or "default" (the text's own font), outline one of
-- XPerl_FontOutlines or "NONE" (the text's own outline). Each text keeps its own size.
XPerl_FontOutlines = {
	{"XPERL_CONF_FONT_OUTLINE_NONE", "NONE"},
	{"XPERL_CONF_FONT_OUTLINE_OUTLINE", "OUTLINE"},
	{"XPERL_CONF_FONT_OUTLINE_THICK", "THICKOUTLINE"},
	{"XPERL_CONF_FONT_OUTLINE_SLUG", "OUTLINESLUG"},
	{"XPERL_CONF_FONT_OUTLINE_MONO", "MONOCHROMEOUTLINE"},
	{"XPERL_CONF_FONT_OUTLINE_MONOTHICK", "MONOCHROMETHICKOUTLINE"},
}

-- XPerl_FontFaces(): {label, value} for the font menus: Default, then every LibSharedMedia font by name
function XPerl_FontFaces()
	local faces = {{"XPERL_CONF_FONT_DEFAULT", "default"}}
	local LSM = LibStub("LibSharedMedia-3.0", true)
	if (LSM) then
		for _, name in ipairs(LSM:List("font")) do
			faces[#faces + 1] = {name, name}
		end
	end
	return faces
end

textFontOriginal = setmetatable({}, {__mode = "k"})	-- text -> {face, flags} it had before the global font

SetTextFont = function(text)
	if (not text.GetFont or (text.IsForbidden and text:IsForbidden())) then
		return
	end
	local font = conf.font
	local outline = font and font.outline or "NONE"
	local LSM = LibStub("LibSharedMedia-3.0", true)
	local face = font and font.face ~= "default" and LSM and LSM:Fetch("font", font.face, true)
	local active = face or outline ~= "NONE"

	local original = textFontOriginal[text]
	if (not original and not active) then
		return
	end
	local currentFace, size, currentFlags = text:GetFont()
	if (not size or issecretvalue(size) or issecretvalue(currentFace)) then
		return
	end
	if (not original) then
		original = {currentFace, currentFlags or ""}
		textFontOriginal[text] = original
	end
	if (active) then
		text:SetFont(face or original[1], size, outline == "NONE" and original[2] or outline)
	else
		text:SetFont(original[1], size, original[2])
		textFontOriginal[text] = nil
	end
end

-- XPerl_SetTextFont()
function XPerl_SetTextFont()
	for _, text in pairs(unitText) do
		SetTextFont(text)
	end
end

-- XPerl_SetTextTransparency()
function XPerl_SetTextTransparency()
	local t = conf.transparency.text
	for k,v in pairs(unitText) do
		if (v.GetTextColor) then
			local r, g, b = v:GetTextColor()
			v:SetTextColor(r, g, b, t)
		end
	end
end

-- Set1Bar
local function Set1Bar(bar, tex)
	if (bar.tex) then
		bar.tex:SetTexture(tex)
		bar.tex:SetHorizTile(false)
		bar.tex:SetVertTile(false)
	end
	if (bar.bg) then
		if (conf.bar.background) then
			bar.bg:SetTexture(tex)
		else
			bar.bg:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
		end
		bar.bg:SetHorizTile(false)
		bar.bg:SetVertTile(false)
	end
end

-- XPerl_RegisterBar
local XPerlBars = {}
function XPerl_RegisterBar(bar)
	tinsert(XPerlBars, bar)
	if (init_done) then
		local tex = XPerl_GetBarTexture()
		Set1Bar(bar, tex)
	end
end

-- XPerl_SetBarTextures
function XPerl_SetBarTextures()
	local tex = XPerl_GetBarTexture()
	for k,v in pairs(XPerlBars) do
		Set1Bar(v, tex)
	end
end

-- XPerl_RegisterOptionChanger
local optionFuncs = {}
function XPerl_RegisterOptionChanger(f, s)
	tinsert(optionFuncs, {func = f, slf = s})
end

-- XPerl_OptionActions()
function XPerl_OptionActions(which)

	UIParent:UnregisterEvent("GROUP_ROSTER_UPDATE")			-- IMPORTANT! Stops raid framerate lagging when members join/leave/zone

	if (InCombatLockdown()) then
		XPerl_OutOfCombatOptionSet = true
		return
	end

	conf.transparency.frame	= min(max(tonumber(conf.transparency.frame or 1), 0), 1)
	conf.transparency.text	= min(max(tonumber(conf.transparency.text or 1), 0), 1)

	XPerl_pcall(XPerl_SetBarTextures)

	XPerl_pcall(XPerl_SetAllFrames)

	for k,v in pairs(optionFuncs) do
		XPerl_pcall(v.func, v.slf, which)
	end

	XPerl_pcall(XPerl_SetTextTransparency)
	XPerl_pcall(XPerl_SetTextFont)
	doneOptions = true

	-- Avoid tainting default blizzard buffs using cooldown options. Cooldowns won't show immediately atm.
	--if (conf.buffs.blizzardCooldowns and BuffFrame and BuffFrame:IsShown()) then
	--	securecall("BuffFrame_Update")
	--end
end
