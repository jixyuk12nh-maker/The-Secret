--[[
    KiciaHooker-style UI-only standalone shell
    Rebuilt from the original UI's visible tab/subtab structure.
    This file intentionally contains NO gameplay/spoofing/aim/automation backend.
    Controls are visual/local only; changing them does not alter the game.
    Roblox LocalScript / executor-compatible UI primitives only.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local previous = PlayerGui:FindFirstChild("OriginalStyle_UI_Only")
if previous then previous:Destroy() end

local Theme = {
    Background = Color3.fromRGB(16, 17, 22),
    Header = Color3.fromRGB(22, 24, 31),
    Sidebar = Color3.fromRGB(19, 20, 27),
    Panel = Color3.fromRGB(26, 28, 36),
    Row = Color3.fromRGB(32, 34, 43),
    Border = Color3.fromRGB(53, 57, 70),
    Text = Color3.fromRGB(237, 239, 246),
    Muted = Color3.fromRGB(150, 155, 171),
    Accent = Color3.fromRGB(126, 170, 246),
    On = Color3.fromRGB(101, 194, 143),
    Off = Color3.fromRGB(74, 78, 94),
}

local function make(className, props, parent)
    local object = Instance.new(className)
    for key, value in pairs(props or {}) do
        object[key] = value
    end
    object.Parent = parent
    return object
end

local function corner(parent, radius)
    return make("UICorner", {CornerRadius = UDim.new(0, radius or 7)}, parent)
end

local function stroke(parent, color, transparency)
    return make("UIStroke", {
        Color = color or Theme.Border,
        Transparency = transparency or 0,
        Thickness = 1,
    }, parent)
end

local function label(parent, text, size, color, font)
    return make("TextLabel", {
        BackgroundTransparency = 1,
        Text = text or "",
        TextColor3 = color or Theme.Text,
        Font = font or Enum.Font.Gotham,
        TextSize = size or 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextWrapped = true,
    }, parent)
end

local gui = make("ScreenGui", {
    Name = "OriginalStyle_UI_Only",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, PlayerGui)

local window = make("Frame", {
    Name = "Window",
    Size = UDim2.fromOffset(920, 610),
    Position = UDim2.new(0.5, -460, 0.5, -305),
    BackgroundColor3 = Theme.Background,
    BorderSizePixel = 0,
    ClipsDescendants = true,
    Active = true,
}, gui)
corner(window, 10)
stroke(window, Theme.Border, 0.15)

local top = make("Frame", {
    Name = "TopBar",
    Size = UDim2.new(1, 0, 0, 46),
    BackgroundColor3 = Theme.Header,
    BorderSizePixel = 0,
}, window)
label(top, "KiciaHooker  /  UI Preview", 15, Theme.Text, Enum.Font.GothamSemibold).Position = UDim2.fromOffset(16, 0)
local titleLabel = top:FindFirstChildOfClass("TextLabel")
titleLabel.Size = UDim2.new(1, -115, 1, 0)

local closeButton = make("TextButton", {
    Name = "Close",
    AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -12, 0.5, 0),
    Size = UDim2.fromOffset(28, 28),
    BackgroundColor3 = Theme.Row,
    Text = "×",
    TextColor3 = Theme.Text,
    Font = Enum.Font.Gotham,
    TextSize = 20,
    BorderSizePixel = 0,
}, top)
corner(closeButton, 7)
closeButton.Activated:Connect(function() gui:Destroy() end)

local sidebar = make("Frame", {
    Name = "Sidebar",
    Position = UDim2.fromOffset(0, 46),
    Size = UDim2.new(0, 185, 1, -46),
    BackgroundColor3 = Theme.Sidebar,
    BorderSizePixel = 0,
}, window)
local sidebarPadding = make("UIPadding", {
    PaddingTop = UDim.new(0, 12),
    PaddingLeft = UDim.new(0, 10),
    PaddingRight = UDim.new(0, 10),
}, sidebar)
local sidebarLayout = make("UIListLayout", {
    Padding = UDim.new(0, 5),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, sidebar)

local content = make("Frame", {
    Name = "Content",
    Position = UDim2.fromOffset(185, 46),
    Size = UDim2.new(1, -185, 1, -46),
    BackgroundColor3 = Theme.Background,
    BorderSizePixel = 0,
}, window)

local pageHeader = make("Frame", {
    Name = "PageHeader",
    Size = UDim2.new(1, 0, 0, 63),
    BackgroundTransparency = 1,
}, content)
local pageTitle = label(pageHeader, "Combat", 19, Theme.Text, Enum.Font.GothamSemibold)
pageTitle.Position = UDim2.fromOffset(20, 7)
pageTitle.Size = UDim2.new(1, -40, 0, 26)
local pageDescription = label(pageHeader, "UI-only preview — controls are not connected to game features.", 11, Theme.Muted)
pageDescription.Position = UDim2.fromOffset(20, 34)
pageDescription.Size = UDim2.new(1, -40, 0, 20)

local subtabBar = make("ScrollingFrame", {
    Name = "Subtabs",
    Position = UDim2.fromOffset(18, 62),
    Size = UDim2.new(1, -36, 0, 36),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 0,
    CanvasSize = UDim2.new(),
    AutomaticCanvasSize = Enum.AutomaticSize.X,
}, content)
make("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    Padding = UDim.new(0, 6),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, subtabBar)

local pagesHolder = make("Frame", {
    Name = "Pages",
    Position = UDim2.fromOffset(18, 105),
    Size = UDim2.new(1, -36, 1, -122),
    BackgroundTransparency = 1,
}, content)

local state = {}
local selectedMain, selectedSub = nil, nil
local mainButtons, subButtons = {}, {}
local currentPageFrame

local function record(key, value)
    state[key] = value
end

local function addControl(parent, title, kind, default, options, uniqueKey)
    local row = make("Frame", {
        Name = "Control_" .. title:gsub("[^%w]", ""),
        Size = UDim2.new(1, 0, 0, 57),
        BackgroundColor3 = Theme.Row,
        BorderSizePixel = 0,
    }, parent)
    corner(row, 7)

    local titleLabel = label(row, title, 12, Theme.Text, Enum.Font.GothamMedium)
    titleLabel.Position = UDim2.fromOffset(11, 4)
    titleLabel.Size = UDim2.new(0.52, -12, 0, 48)

    local key = uniqueKey or ((selectedMain or "Main") .. "/" .. (selectedSub or "Overview") .. "/" .. title)
    if kind == "toggle" then
        local on = default == true
        record(key, on)
        local button = make("TextButton", {
            Position = UDim2.new(1, -60, 0.5, -12),
            Size = UDim2.fromOffset(48, 24),
            BackgroundColor3 = on and Theme.On or Theme.Off,
            BorderSizePixel = 0,
            Text = on and "ON" or "OFF",
            TextColor3 = Theme.Text,
            Font = Enum.Font.GothamBold,
            TextSize = 10,
        }, row)
        corner(button, 12)
        button.Activated:Connect(function()
            on = not on
            record(key, on)
            button.Text = on and "ON" or "OFF"
            TweenService:Create(button, TweenInfo.new(0.12), {
                BackgroundColor3 = on and Theme.On or Theme.Off
            }):Play()
        end)
    elseif kind == "dropdown" then
        options = options or {"Default", "Option 2"}
        local index = 1
        for i, v in ipairs(options) do if v == default then index = i end end
        record(key, options[index])
        local button = make("TextButton", {
            Position = UDim2.new(0.52, 0, 0.5, -13),
            Size = UDim2.new(0.48, -9, 0, 26),
            BackgroundColor3 = Theme.Panel,
            BorderSizePixel = 0,
            Text = tostring(options[index]) .. "  ▾",
            TextColor3 = Theme.Text,
            Font = Enum.Font.Gotham,
            TextSize = 11,
        }, row)
        corner(button, 5)
        button.Activated:Connect(function()
            index = (index % #options) + 1
            record(key, options[index])
            button.Text = tostring(options[index]) .. "  ▾"
        end)
    elseif kind == "slider" then
        local minV, maxV = (options and options.Min) or 0, (options and options.Max) or 100
        local value = tonumber(default) or minV
        record(key, value)
        local valueText = label(row, tostring(value), 10, Theme.Muted)
        valueText.TextXAlignment = Enum.TextXAlignment.Right
        valueText.Position = UDim2.new(0.58, 0, 0, 4)
        valueText.Size = UDim2.new(0.38, -10, 0, 17)
        local track = make("Frame", {
            Position = UDim2.new(0.55, 0, 0, 34),
            Size = UDim2.new(0.4, -10, 0, 5),
            BackgroundColor3 = Theme.Off,
            BorderSizePixel = 0,
        }, row)
        corner(track, 4)
        local ratio = math.clamp((value - minV) / math.max(1, maxV - minV), 0, 1)
        local fill = make("Frame", {
            Size = UDim2.new(ratio, 0, 1, 0),
            BackgroundColor3 = Theme.Accent,
            BorderSizePixel = 0,
        }, track)
        corner(fill, 4)
        local hit = make("TextButton", {
            Size = UDim2.new(1, 0, 0, 20),
            Position = UDim2.new(0, 0, 0.5, -10),
            BackgroundTransparency = 1,
            Text = "",
        }, track)
        local function setFromX(x)
            local r = math.clamp((x - track.AbsolutePosition.X) / math.max(1, track.AbsoluteSize.X), 0, 1)
            value = math.floor((minV + (maxV - minV) * r) * 100 + 0.5) / 100
            record(key, value)
            valueText.Text = tostring(value)
            fill.Size = UDim2.new(r, 0, 1, 0)
        end
        hit.Activated:Connect(function() end)
        hit.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                setFromX(input.Position.X)
            end
        end)
    else
        local box = make("TextBox", {
            Position = UDim2.new(0.52, 0, 0.5, -13),
            Size = UDim2.new(0.48, -9, 0, 26),
            BackgroundColor3 = Theme.Panel,
            BorderSizePixel = 0,
            Text = default == nil and "" or tostring(default),
            PlaceholderText = kind == "text" and "Enter value" or "0",
            ClearTextOnFocus = false,
            TextColor3 = Theme.Text,
            PlaceholderColor3 = Theme.Muted,
            Font = Enum.Font.Gotham,
            TextSize = 11,
        }, row)
        corner(box, 5)
        make("UIPadding", {PaddingLeft = UDim.new(0, 7), PaddingRight = UDim.new(0, 6)}, box)
        record(key, default)
        box.FocusLost:Connect(function()
            local value = box.Text
            if kind == "number" or kind == "percent" then
                local n = tonumber(value)
                if n then
                    if kind == "percent" then n = math.clamp(n, 0, 100) end
                    record(key, n)
                    box.Text = tostring(n)
                else
                    box.Text = default == nil and "" or tostring(state[key] or default)
                end
            else
                record(key, value)
            end
        end)
    end
    return row
end

local function addSection(parent, title, controls)
    local section = make("Frame", {
        Name = "Section_" .. title:gsub("[^%w]", ""),
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y,
        Size = UDim2.new(1, 0, 0, 0),
    }, parent)
    local heading = make("Frame", {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = Theme.Panel,
        BorderSizePixel = 0,
    }, section)
    corner(heading, 6)
    label(heading, title, 12, Theme.Accent, Enum.Font.GothamSemibold).Position = UDim2.fromOffset(10, 0)
    heading:FindFirstChildOfClass("TextLabel").Size = UDim2.new(1, -20, 1, 0)

    local list = make("Frame", {
        Position = UDim2.fromOffset(0, 36),
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y,
    }, section)
    make("UIListLayout", {
        Padding = UDim.new(0, 7),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, list)
    for _, item in ipairs(controls or {}) do
        addControl(list, item[1], item[2], item[3], item[4])
    end
    return section
end

local function makePage(mainName, subName)
    local page = make("ScrollingFrame", {
        Name = mainName .. "_" .. subName,
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = Theme.Border,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false,
    }, pagesHolder)
    local columns = make("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
    }, page)
    make("UIListLayout", {
        Padding = UDim.new(0, 10),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, columns)
    make("UIPadding", {
        PaddingBottom = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 5),
    }, columns)

    local catalog = {
        Combat = {
            Aimbot = {{"Aim Assistance", {{"Enable Aimbot","toggle",false},{"Target Part","dropdown","Head",{"Head","Torso","Closest"}},{"Field of View","slider",120,{Min=0,Max=360}},{"Smoothness","slider",5,{Min=1,Max=20}}}}, {"Target Filtering", {{"Team Check","toggle",true},{"Visible Check","toggle",false},{"Ignore Friends","toggle",false}}}},
            ["Silent Aim"] = {{"Silent Aim", {{"Enable Silent Aim","toggle",false},{"Hit Chance","slider",100,{Min=0,Max=100}},{"Target Part","dropdown","Head",{"Head","Torso","Closest"}}}}},
            Ragebot = {{"Ragebot", {{"Enable Ragebot","toggle",false},{"Target Selection","dropdown","Closest",{"Closest","Lowest Health","Distance"}},{"Auto Fire","toggle",false}}}},
            ["Fire Assist"] = {{"Fire Assist", {{"Enable Fire Assist","toggle",false},{"Auto Shoot","toggle",false},{"Flick Speed","slider",10,{Min=1,Max=30}}}}},
            ["Weapon Handling"] = {{"Weapon Handling", {{"No Recoil","toggle",false},{"No Spread","toggle",false},{"Fire Cooldown","slider",0,{Min=0,Max=100}},{"Melee Cooldown","slider",0,{Min=0,Max=100}}}}},
            ["Hit Feedback"] = {{"Hit Feedback", {{"Hitmarker","toggle",true},{"Hit Sound","toggle",false},{"Damage Indicator","toggle",true}}}},
        },
        Automation = {
            ["Match Flow"] = {{"Queue & Voting", {{"Auto Queue","toggle",false},{"Auto Vote","toggle",false},{"Auto Respawn","toggle",false}}}},
            ["Auto Loadout"] = {{"Loadout", {{"Enable Auto Loadout","toggle",false},{"Primary","dropdown","Default",{"Default","Rifle","Shotgun"}},{"Secondary","dropdown","Default",{"Default","Pistol"}}}}},
            ["In-Match Automation"] = {{"Pickups & Actions", {{"Auto Pickup","toggle",false},{"Auto Counter","toggle",false},{"Auto Tripmine","toggle",false}}}},
            Detection = {{"Detection", {{"Detect Players","toggle",false},{"Detect Moderators","toggle",false},{"Notify on Detection","toggle",true}}}},
        },
        Cosmetics = {
            Overview = {{"Cosmetics", {{"Enable Cosmetics UI","toggle",false},{"Unlock All Preview","toggle",false},{"Auto Reroll","toggle",false}}}},
            Skins = {{"Weapon Skins", {{"Enable Skin Override","toggle",false},{"Skin Name","text",""},{"Apply to All Weapons","toggle",false}}}},
            Wraps = {{"Weapon Wraps", {{"Enable Wrap Override","toggle",false},{"Wrap Name","text",""},{"Invert Pattern","toggle",false}}}},
            Charms = {{"Weapon Charms", {{"Enable Charm Override","toggle",false},{"Charm Name","text",""}}}},
            Finishers = {{"Finishers", {{"Enable Finisher Override","toggle",false},{"Finisher Name","text",""}}}},
            Presets = {{"Cosmetic Presets", {{"Preset Name","text",""},{"Auto Load Preset","toggle",false},{"Save Preset UI","toggle",false}}}},
        },
        Player = {
            Movement = {{"Movement", {{"Walk Speed","slider",16,{Min=1,Max=100}},{"Jump Power","slider",50,{Min=1,Max=150}},{"Flight","toggle",false},{"Noclip","toggle",false},{"Auto Strafe","toggle",false}}}},
            ["Movement Recorder"] = {{"Recorder", {{"Record Route","toggle",false},{"Replay Route","toggle",false},{"Hide Recorder UI","toggle",false}}}},
            Character = {{"Character", {{"Third Person","toggle",false},{"Camera FOV","slider",70,{Min=40,Max=120}},{"Animation Player","toggle",false},{"Animation ID","text",""}}}},
            ["Identity Spoofing"] = {
                {"Local Player", {{"Name","text","Nosniy"},{"Display Name","text","Nosniy"},{"Avatar","text","20349956"},{"Winstreak","number",999},{"Level","number",999},{"Casual Wins","number",99999},{"Ranked Wins","number",9999},{"Casual Win %","percent",100},{"Ranked Win %","percent",100},{"Ranked ELO","number",3600},{"Leaderboard Rank","number",1},{"Favorite Map","text","Arena"},{"Nametag Status","dropdown","Prime",{"Prime","Contraband"}},{"Influencer","toggle",true},{"Roblox Employee","toggle",true},{"Nosniy Games Team","toggle",false}}},
                {"Other Player", {{"Other Player Name","text",""},{"Other Display Name","text",""},{"Other Avatar User ID","text",""},{"Other Winstreak","number",0},{"Other Level","number",0},{"Other Casual Wins","number",0},{"Other Ranked Wins","number",0},{"Other Casual Win %","percent",0},{"Other Ranked Win %","percent",0},{"Other Ranked ELO","number",0},{"Other Leaderboard Rank","number",200},{"Other Favorite Map","text",""},{"Other Nametag Status","dropdown","Prime",{"Prime","Contraband"}},{"Other Influencer","toggle",false},{"Other Roblox Employee","toggle",false},{"Other Nosniy Team","toggle",false}}},
            },
        },
        Visuals = {
            ["Player ESP"] = {{"Player ESP", {{"Enable ESP","toggle",false},{"Box ESP","toggle",true},{"Name","toggle",true},{"Health Bar","toggle",true},{"Distance","toggle",false},{"Team Color","toggle",true}}}},
            Crosshair = {{"Crosshair", {{"Enable Crosshair","toggle",false},{"Style","dropdown","Lines",{"Lines","Circle","Dot","Image"}},{"Length","slider",12,{Min=1,Max=50}},{"Thickness","slider",2,{Min=1,10}},{"Gap","slider",6,{Min=0,30}},{"Rotation","toggle",false}}}},
            ["Weapon Visuals"] = {{"Weapon Visuals", {{"Viewmodel Chams","toggle",false},{"Bullet Tracers","toggle",false},{"Weapon Bob","toggle",true},{"Tracer Lifetime","slider",1,{Min=0.1,Max=5}}}}},
            ["Camera & Screen"] = {{"Camera & Screen", {{"Third Person","toggle",false},{"Field of View","slider",70,{Min=40,Max=120}},{"No Flash","toggle",false},{"No Scope Overlay","toggle",false},{"Stretched Resolution","toggle",false}}}},
            ["Sound ESP"] = {{"Sound ESP", {{"Enable Sound ESP","toggle",false},{"Footsteps","toggle",true},{"Other Sounds","toggle",false},{"Minimum Volume","slider",0.25,{Min=0,Max=1}}}}},
        },
        World = {
            Lighting = {{"Lighting", {{"Override Time","toggle",false},{"Time of Day","slider",14,{Min=0,Max=24}},{"Brightness","slider",2,{Min=0,10}},{"No Fog","toggle",false},{"Shadows","toggle",true}}}},
            ["Post Processing"] = {{"Post Processing", {{"Enable Effects","toggle",false},{"Bloom","toggle",false},{"Blur","toggle",false},{"Color Correction","toggle",false},{"Depth of Field","toggle",false}}}},
            ["Sky & Weather"] = {{"Sky & Weather", {{"Custom Sky","toggle",false},{"Skybox Name","text",""},{"Weather","dropdown","Default",{"Default","Clear","Rain","Storm"}},{"Ambient Sound","toggle",false}}}},
        },
        Misc = {
            Overview = {{"Miscellaneous", {{"Device Spoofer","toggle",false},{"Device Type","dropdown","VR",{"VR","Touch","Gamepad","Mouse + Keyboard"}},{"Third Person","toggle",false},{"Auto Grab Drops","toggle",false},{"Emote Hop","toggle",false},{"Emote Speed","slider",1,{Min=1,Max=40}}}}},
        },
        Settings = {
            General = {{"General", {{"Show Notifications","toggle",true},{"UI Scale","slider",100,{Min=75,Max=125}},{"Theme Color","dropdown","Sky Blue",{"Sky Blue","Red","Lime Green","Purple","Orange"}},{"Show Watermark","toggle",true}}}},
            ["Config Profiles"] = {{"Configuration", {{"Config Name","text",""},{"Save Config UI","toggle",false},{"Load Config UI","toggle",false},{"Reset UI Values","toggle",false}}}},
        },
    }

    local groups = catalog[mainName] and catalog[mainName][subName]
    if not groups then groups = {{"UI Preview", {{"This is UI only","toggle",false},{"Example Value","text",""}}}} end
    for _, group in ipairs(groups) do
        addSection(columns, group[1], group[2])
    end
    return page
end

local structure = {
    {Name="Combat", Description="Aim assistance, weapon handling, and feedback.", Subs={"Aimbot","Silent Aim","Ragebot","Fire Assist","Weapon Handling","Hit Feedback"}},
    {Name="Automation", Description="Match flow, loadouts, and detection.", Subs={"Match Flow","Auto Loadout","In-Match Automation","Detection"}},
    {Name="Cosmetics", Description="Cosmetic runtime and presets.", Subs={"Overview","Skins","Wraps","Charms","Finishers","Presets"}},
    {Name="Player", Description="Movement, character, and identity.", Subs={"Movement","Movement Recorder","Character","Identity Spoofing"}},
    {Name="Visuals", Description="ESP, crosshair, weapon, camera, and sound.", Subs={"Player ESP","Crosshair","Weapon Visuals","Camera & Screen","Sound ESP"}},
    {Name="World", Description="Lighting, post processing, sky and weather.", Subs={"Lighting","Post Processing","Sky & Weather"}},
    {Name="Misc", Description="Miscellaneous UI controls.", Subs={"Overview"}},
    {Name="Settings", Description="Theme and configuration.", Subs={"General","Config Profiles"}},
}

local function showSubtab(name)
    selectedSub = name
    for _, button in ipairs(subButtons) do
        button.BackgroundColor3 = button.Name == name and Theme.Accent or Theme.Panel
        button.TextColor3 = Theme.Text
    end
    if currentPageFrame then currentPageFrame:Destroy() end
    currentPageFrame = makePage(selectedMain, name)
    currentPageFrame.Visible = true
end

local function showMainTab(name)
    selectedMain = name
    for _, button in ipairs(mainButtons) do
        button.BackgroundColor3 = button.Name == name and Theme.Accent or Theme.Sidebar
        button.TextColor3 = button.Name == name and Theme.Text or Theme.Muted
    end
    pageTitle.Text = name
    local config
    for _, item in ipairs(structure) do if item.Name == name then config = item break end end
    pageDescription.Text = config and config.Description or "UI-only preview."
    for _, child in ipairs(subtabBar:GetChildren()) do
        if child:IsA("GuiObject") and not child:IsA("UIListLayout") then child:Destroy() end
    end
    subButtons = {}
    for _, subName in ipairs(config.Subs) do
        local button = make("TextButton", {
            Name = subName,
            Size = UDim2.fromOffset(math.max(82, #subName * 7 + 24), 30),
            BackgroundColor3 = Theme.Panel,
            BorderSizePixel = 0,
            Text = subName,
            TextColor3 = Theme.Muted,
            Font = Enum.Font.GothamMedium,
            TextSize = 11,
            AutomaticSize = Enum.AutomaticSize.X,
        }, subtabBar)
        button.Size = UDim2.new(0, math.max(82, #subName * 7 + 24), 0, 30)
        corner(button, 6)
        table.insert(subButtons, button)
        button.Activated:Connect(function() showSubtab(subName) end)
    end
    showSubtab(config.Subs[1])
end

for i, item in ipairs(structure) do
    local button = make("TextButton", {
        Name = item.Name,
        LayoutOrder = i,
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = Theme.Sidebar,
        BorderSizePixel = 0,
        Text = "   " .. item.Name,
        TextColor3 = Theme.Muted,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, sidebar)
    corner(button, 6)
    table.insert(mainButtons, button)
    button.Activated:Connect(function() showMainTab(item.Name) end)
end

-- Drag the window from its top bar (mouse and touch).
local dragging, dragStart, startPosition = false, nil, nil
top.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPosition = window.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        window.Position = UDim2.new(
            startPosition.X.Scale, startPosition.X.Offset + delta.X,
            startPosition.Y.Scale, startPosition.Y.Offset + delta.Y
        )
    end
end)

-- Expose local UI state for testing only; no gameplay functions are attached.
_G.OriginalStyleUIOnlyState = state
showMainTab("Combat")
