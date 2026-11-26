-- X-Perl UnitFrames
-- License: GNU GPL v3, 29 June 2007 (see LICENSE.txt)
--
-- "2D Portrait Style" dropdown on the options window's portrait pages, right under 3D Portrait (the Edit Mode
-- dialogs and the Settings panel get theirs from XPerl_EditModeSettings.lua). The "All" page sets every frame
-- with a portrait at once. Loaded at the end of XPerl_FrameOptions.xml, once the pages exist; whatever hung
-- below 3D Portrait moves down under it.

local PAGES = {
	{page = "Player", key = "player"},
	{page = "Pet", key = "pet"},
	{page = "Target", key = "target"},
	{page = "Focus", key = "focus"},
	{page = "Party", key = "party"},
}

-- Every frame key with a 2D Portrait Style setting (XPerl_EditModeSettings.lua), for the "All" page
local ALL_KEYS = {"player", "pet", "target", "focus", "party", "boss", "arena"}

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

local function Current(key)
	local section = XPerlDB and XPerlDB[key]
	return section and section.portraitStyle or "default"
end

-- keys: the frame keys the dropdown sets; it shows a style as chosen only when they all have it
local function AddDropdown(above, keys)
	local parent = above:GetParent()
	local followers = Followers(parent, above)

	local holder = CreateFrame("Frame", parent:GetName().."_PortraitStyle", parent)
	holder:SetSize(260, 26)
	holder:SetPoint("TOPLEFT", above, "BOTTOMLEFT", 0, 2)
	local label = holder:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	label:SetPoint("LEFT", 4, 0)
	label:SetText(XPERL_CONF_PORTRAITSTYLE)

	local dropdown = CreateFrame("DropdownButton", nil, holder, "WowStyle1DropdownTemplate")
	dropdown:SetPoint("LEFT", label, "RIGHT", 6, 0)
	dropdown:SetWidth(110)
	dropdown:SetupMenu(function(_, root)
		for _, style in ipairs(XPerl_PortraitStyles) do
			local value = style[1]
			root:CreateRadio(_G[style[2]] or value,
				function()
					for _, key in ipairs(keys) do
						if (Current(key) ~= value) then
							return false
						end
					end
					return true
				end,
				function()
					for _, key in ipairs(keys) do
						local section = XPerlDB and XPerlDB[key]
						if (section) then
							section.portraitStyle = value
						end
					end
					XPerl_OptionActions()
				end)
		end
	end)
	-- Edit Mode, the Settings panel and profiles change it too: show the current style when the page opens
	holder:SetScript("OnShow", function() dropdown:GenerateMenu() end)

	for child, points in pairs(followers) do
		child:ClearAllPoints()
		for _, p in ipairs(points) do
			child:SetPoint(p[1], p[2] == above and holder or p[2], p[3], p[4], p[5])
		end
	end
end

for _, info in ipairs(PAGES) do
	local above = _G["XPerl_Options_"..info.page.."_Options_Portrait3D"]
	if (above) then
		AddDropdown(above, {info.key})
	end
end

if (XPerl_Options_All_Options_Portrait3D) then
	AddDropdown(XPerl_Options_All_Options_Portrait3D, ALL_KEYS)
end
