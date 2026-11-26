-- X-Perl UnitFrames
-- License: GNU GPL v3, 29 June 2007 (see LICENSE.txt)
--
-- Dropdowns added to the options window (the Edit Mode dialogs and the Settings panel get theirs from
-- XPerl_EditModeSettings.lua). Loaded at the end of XPerl_FrameOptions.xml, once the pages exist. Each goes under
-- an existing row, and whatever hung below that row moves down under it.
--  * "2D Portrait Style" under 3D Portrait on each portrait page; the "All" page's sets every portrait frame. It is
--    greyed out with 3D Portrait while the page's Portrait is off.
--  * "Font" and "Outline" (the global font, conf.font) on the "All" page, under its 2D Portrait Style.

local PAGES = {
	{page = "Player", key = "player"},
	{page = "Pet", key = "pet"},
	{page = "Target", key = "target"},
	{page = "Focus", key = "focus"},
	{page = "Party", key = "party"},
}

-- Every frame key with a 2D Portrait Style setting (XPerl_EditModeSettings.lua), for the "All" page
local ALL_KEYS = {"player", "pet", "target", "focus", "party", "arena"}

-- Children of `parent` anchored to `old`, with their points
local function Followers(parent, old)
	local list = {}
	for _, child in ipairs({parent:GetChildren()}) do
		local points, follows = {}, false
		for i = 1, child:GetNumPoints() do
			points[i] = {child:GetPoint(i)}
			follows = follows or points[i][2] == old
		end
		if (follows) then
			list[child] = points
		end
	end
	return list
end

-- AddDropdown(above, suffix, label, values, isSelected, select): a labelled dropdown under `above`.
-- values() returns {label key or text, value} pairs; isSelected(value) and select(value) read and write it.
local function AddDropdown(above, suffix, label, values, isSelected, select)
	local parent = above:GetParent()
	local followers = Followers(parent, above)

	local holder = CreateFrame("Frame", parent:GetName().."_"..suffix, parent)
	holder:SetSize(260, 26)
	holder:SetPoint("TOPLEFT", above, "BOTTOMLEFT", 0, 2)
	local text = holder:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	text:SetPoint("LEFT", 4, 0)
	text:SetText(label)

	local dropdown = CreateFrame("DropdownButton", nil, holder, "WowStyle1DropdownTemplate")
	dropdown:SetPoint("LEFT", text, "RIGHT", 6, 0)
	dropdown:SetWidth(130)
	dropdown:SetupMenu(function(_, root)
		root:SetScrollMode(400)
		for _, entry in ipairs(values()) do
			local value = entry[2]
			local name = type(_G[entry[1]]) == "string" and _G[entry[1]] or entry[1]
			root:CreateRadio(name, function() return isSelected(value) end, function()
				select(value)
				XPerl_OptionActions()
			end)
		end
	end)
	-- Edit Mode, the Settings panel and profiles change these too: show the current value when the page opens
	holder:SetScript("OnShow", function() dropdown:GenerateMenu() end)
	holder.dropdown, holder.label = dropdown, text

	for child, points in pairs(followers) do
		child:ClearAllPoints()
		for _, p in ipairs(points) do
			child:SetPoint(p[1], p[2] == above and holder or p[2], p[3], p[4], p[5])
		end
	end
	return holder
end

------------------------------------------------------------------------------
-- 2D Portrait Style
------------------------------------------------------------------------------

local function StyleValues()
	local values = {}
	for i, style in ipairs(XPerl_PortraitStyles) do
		values[i] = {style[2], style[1]}
	end
	return values
end

local function CurrentStyle(key)
	local section = XPerlDB and XPerlDB[key]
	return section and section.portraitStyle or "default"
end

-- keys: the frame keys the dropdown sets; it shows a style as chosen only when they all have it
local function AddStyleDropdown(above, keys)
	return AddDropdown(above, "PortraitStyle", XPERL_CONF_PORTRAITSTYLE, StyleValues,
		function(value)
			for _, key in ipairs(keys) do
				if (CurrentStyle(key) ~= value) then
					return false
				end
			end
			return true
		end,
		function(value)
			for _, key in ipairs(keys) do
				local section = XPerlDB and XPerlDB[key]
				if (section) then
					section.portraitStyle = value
				end
			end
		end)
end

-- Greys the dropdown out while the page's Portrait check button is off
local function FollowPortrait(holder, portrait)
	if (not portrait) then
		return
	end
	local function Update()
		local on = portrait:GetChecked() and true or false
		holder.dropdown:SetEnabled(on)
		holder.label:SetTextColor((on and NORMAL_FONT_COLOR or GRAY_FONT_COLOR):GetRGB())
	end
	portrait:HookScript("OnClick", Update)
	holder:HookScript("OnShow", Update)
end

for _, info in ipairs(PAGES) do
	local prefix = "XPerl_Options_"..info.page.."_Options"
	local above = _G[prefix.."_Portrait3D"]
	if (above) then
		FollowPortrait(AddStyleDropdown(above, {info.key}), _G[prefix.."_Portrait"])
	end
end

------------------------------------------------------------------------------
-- "All" page: 2D Portrait Style, Font, Outline
------------------------------------------------------------------------------

local function FontSetting(field, default)
	local function get()
		local font = XPerlDB and XPerlDB.font
		return font and font[field] or default
	end
	local function set(value)
		if (XPerlDB) then
			XPerlDB.font = XPerlDB.font or {}
			XPerlDB.font[field] = value
		end
	end
	return function(value) return get() == value end, set
end

if (XPerl_Options_All_Options_Portrait3D) then
	local style = AddStyleDropdown(XPerl_Options_All_Options_Portrait3D, ALL_KEYS)
	FollowPortrait(style, _G.XPerl_Options_All_Options_Portrait)
	local faceSelected, faceSet = FontSetting("face", "default")
	local face = AddDropdown(style, "FontFace", XPERL_CONF_FONT_FACE, XPerl_FontFaces, faceSelected, faceSet)
	local outlineSelected, outlineSet = FontSetting("outline", "NONE")
	AddDropdown(face, "FontOutline", XPERL_CONF_FONT_OUTLINE, function() return XPerl_FontOutlines end,
		outlineSelected, outlineSet)
end
