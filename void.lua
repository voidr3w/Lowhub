-- [[ LOW HUB - PRIVATE BUILD ]]
-- [[ CUSTOM UI + PHYSICS ENGINE ]]

if game:GetService("CoreGui"):FindFirstChild("LowHubUI_Final") then
    warn("Low Hub is already loaded (Process Killed)")
    return
end

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

-- Universal Request Function
-- Universal Request Function
local http_request = function(options)
    if syn and syn.request then
        -- warn("[LowHub Debug] Using syn.request")
        return syn.request(options)
    elseif http and http.request then
        -- warn("[LowHub Debug] Using http.request")
        return http.request(options)
    elseif request then
        -- warn("[LowHub Debug] Using Global request")
        return request(options)
    elseif game.HttpGet then
        -- warn("[LowHub Debug] Fallback to game:HttpGet")
        local s, r = pcall(game.HttpGet, game, options.Url)
        if s then 
            return {StatusCode = 200, Body = r} 
        else
            warn("[LowHub Debug] game:HttpGet FAILED: " .. tostring(r))
        end
    else
        warn("[LowHub Debug] No HTTP Method Found!")
    end
    return {StatusCode = 500, Body = "No Request Function Found"}
end
repeat task.wait() until Players.LocalPlayer
local LocalPlayer = Players.LocalPlayer
local LowHubLoaded = false -- Prevents Toggles from firing on startup sequence

-- // CONFIGURATION //
local USE_API_WHITELIST = true -- Mude para true se quiser usar o Nível 2
local API_URL = "https://lowhubserver.discloud.app/check" -- Coloque o link do seu Render/Replit aqui

local RoleConfig = {
    -- Users moved to API Database
}

-- Helper function for lookup (Supports Name, ID, or Player Object)
local function GetRole(playerOrCharacterOrName)
    local p = nil
    if typeof(playerOrCharacterOrName) == "Instance" then
        if playerOrCharacterOrName:IsA("Player") then
            p = playerOrCharacterOrName
        elseif playerOrCharacterOrName:IsA("Model") then
            p = game:GetService("Players"):GetPlayerFromCharacter(playerOrCharacterOrName)
        end
    elseif typeof(playerOrCharacterOrName) == "string" then
        p = game:GetService("Players"):FindFirstChild(playerOrCharacterOrName)
    end

    local name = p and p.Name or tostring(playerOrCharacterOrName or "")
    local id = p and p.UserId or nil
    
    -- Check ID first (CACHE HIT)
    if id and RoleConfig[id] then return RoleConfig[id] end
    if id and RoleConfig[tostring(id)] then return RoleConfig[tostring(id)] end

    -- Check Name (Case-Insensitive - CACHE HIT)
    for user, role in pairs(RoleConfig) do
        if typeof(user) == "string" and string.lower(user) == string.lower(name) then
            return role
        end
    end

    -- API Check (Level 2 - MISS)
    if USE_API_WHITELIST and name and #name > 0 then
        local targetUrl = API_URL .. "?user=" .. name
        -- warn("[LowHub Debug] Checking URL: " .. targetUrl) -- SPAM STOP
        
        local success, result = pcall(function()
            local response = http_request({Url = targetUrl, Method = "GET"})
            
            if response then
                -- warn("[LowHub Debug] Status: " .. tostring(response.StatusCode))
                
                if response.StatusCode == 200 then
                    return HttpService:JSONDecode(response.Body)
                else
                    return nil
                end
            else
                return nil
            end
        end)
        
        if success and result then
            if result.valid then
                 -- warn("[LowHub Debug] Access GRANTED for " .. name .. " as " .. tostring(result.role))
                 -- // UPDATE CACHE //
                 if id then RoleConfig[id] = result.role end
                 RoleConfig[name] = result.role
                 return result.role
            else
                 -- warn("[LowHub Debug] Access DENIED (Valid=False). Response: " .. tostring(result.error))
            end
        else
            -- warn("[LowHub Debug] API Processing FAILED. Error: " .. tostring(result))
        end
        
        -- If we reached here, the API check failed or user is not whitelisted.
        -- CACHE THE FAILURE so we don't spam requests.
        if id then RoleConfig[id] = "User" end
        RoleConfig[name] = "User"
    end
    
    return "User" -- Default to User instead of nil
end


-- // FLASHBACK SYSTEM //
_G.flashbackEnabled = false
_G.flashbackKey = Enum.KeyCode.E
_G.flashbackLength = 60
_G.flashbackSpeed = 1
local flashback_frames = {}
_G.ShaderEffects = {}
_G.NewShaderEnabled = false

local function flashback_Advance(char, hrp, hum)
    if #flashback_frames > _G.flashbackLength * 60 then
        table.remove(flashback_frames, 1)
    end
    table.insert(flashback_frames, {
        hrp.CFrame,
        hrp.Velocity,
        hum:GetState(),
        hum.PlatformStand,
        char:FindFirstChildOfClass("Tool")
    })
end

local function flashback_Revert(char, hrp, hum)
    if flying then return end
    if #flashback_frames <= 0 then return end
    for i = 1, _G.flashbackSpeed do
        if #flashback_frames > 0 then table.remove(flashback_frames, #flashback_frames) end
    end
    if #flashback_frames <= 0 then return end
    local last = flashback_frames[#flashback_frames]
    table.remove(flashback_frames, #flashback_frames)
    hrp.CFrame = last[1]
    hrp.Velocity = -last[2]
    hum:ChangeState(last[3])
    hum.PlatformStand = last[4]
    if last[5] then pcall(function() hum:EquipTool(last[5]) end) else pcall(function() hum:UnequipTools() end) end
end



-- PLACEHOLDER TO KEEP LINE COUNTS CONSISTENT IF NEEDED, BUT WE ARE REPLACING 100-119 which is 20 lines.
-- The new code is roughly 30 lines.


local function PlayGlobalAnim(id, time, speed)
    pcall(function()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChild("Humanoid")
        if not hum then return end
        
        char.Animate.Disabled = false
        local tracks = hum:GetPlayingAnimationTracks()
        for _, t in pairs(tracks) do t:Stop() end
        char.Animate.Disabled = true
        
        local anim = Instance.new("Animation")
        anim.AnimationId = "rbxassetid://" .. id
        local track = hum:LoadAnimation(anim)
        track:Play()
        track.TimePosition = time or 0
        track:AdjustSpeed(speed or 1)
        
        track.Stopped:Connect(function()
            char.Animate.Disabled = false
        end)
    end)
end

local function SetCharacterAnimations(anims)
    pcall(function()
        local char = LocalPlayer.Character
        local animate = char and char:FindFirstChild("Animate")
        if not animate then return end
        
        animate.Disabled = true
        for _, t in pairs(char.Humanoid:GetPlayingAnimationTracks()) do t:Stop() end
        
        local function set(name, id)
            if animate:FindFirstChild(name) and animate[name]:FindFirstChildOfClass("Animation") then
                animate[name]:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://" .. id
            end
        end
        
        if anims.idle then set("idle", anims.idle) end
        if anims.walk then set("walk", anims.walk) end
        if anims.run then set("run", anims.run) end
        if anims.jump then set("jump", anims.jump) end
        if anims.climb then set("climb", anims.climb) end
        if anims.fall then set("fall", anims.fall) end
        
        animate.Disabled = false
        char.Humanoid:ChangeState(Enum.HumanoidStateType.Landing)
    end)
end

-- ///////////////////////////////////////////////////////////
-- //               FLUENT GRADIENT LIBRARY                 //
-- ///////////////////////////////////////////////////////////

local FluentGradient = {}
local Config = {
    MainColor = Color3.fromRGB(20, 20, 20),
    AccentColor = Color3.fromRGB(255, 45, 90), 
    GradientColor1 = Color3.fromRGB(255, 45, 90),
    GradientColor2 = Color3.fromRGB(150, 0, 200),
    TextColor = Color3.fromRGB(255, 255, 255),
    SecondaryTextColor = Color3.fromRGB(180, 180, 180),
    Font = Enum.Font.GothamBold,
    CornerRadius = UDim.new(0, 8),
    ClickSoundId = "rbxassetid://12221967",
    SoundEnabled = false,
    BackgroundColor = Color3.fromRGB(20, 20, 20), -- Added for MainFrame
}

-- // DRAG LOGIC //
local function MakeDraggable(gui, onClick)
    local dragging
    local dragInput
    local dragStart
    local startPos
    local startClickTime = 0
    
    gui.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = gui.Position
            startClickTime = tick()
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    -- Click Detection (if dragged less than 2 pixels and short time)
                    if onClick and (tick() - startClickTime < 0.3) and (input.Position - dragStart).Magnitude < 5 then
                        onClick()
                    end
                end
            end)
        end
    end)
    
    gui.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            gui.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

function FluentGradient:Create(options)
    local Window = {}
    options = options or {}
    local TitleText = options.Title or "Fluent Gradient"
    
    Window.ToggleKey = Enum.KeyCode.RightControl
    
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "LowHubUI_Final"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.DisplayOrder = 9999
    if pcall(function() ScreenGui.Parent = CoreGui end) then else ScreenGui.Parent = LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui", 5) end
    
    -- warn("LowHub Loaded. User: " .. LocalPlayer.Name .. " | Role: " .. tostring(GetRole(LocalPlayer))) -- Silenciado
    
    Window.Instance = ScreenGui
    
    local Sound = Instance.new("Sound")
    Sound.SoundId = Config.ClickSoundId
    Sound.Volume = 1
    Sound.Parent = ScreenGui
    local function PlayClick() if Config.SoundEnabled then pcall(function() Sound:Play() end) end end
    
    function Window:Destroy() ScreenGui:Destroy() end

    -- FLOATING TOGGLE BUTTON ("L" Icon)
    local ToggleBtn = Instance.new("TextButton")
    ToggleBtn.Name = "ToggleUI"
    ToggleBtn.Size = UDim2.new(0, 50, 0, 50)
    ToggleBtn.Position = UDim2.new(0, 50, 0.5, -25)
    ToggleBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    ToggleBtn.Text = "L"
    ToggleBtn.TextColor3 = Config.AccentColor
    ToggleBtn.Font = Enum.Font.GothamBlack
    ToggleBtn.TextSize = 32
    ToggleBtn.AutoButtonColor = false -- Disable default flash to handle it manually or simple
    ToggleBtn.Parent = ScreenGui
    local TBtnCorner = Instance.new("UICorner") TBtnCorner.CornerRadius = UDim.new(0, 12) TBtnCorner.Parent = ToggleBtn
    local TBtnStroke = Instance.new("UIStroke") TBtnStroke.Thickness = 2 TBtnStroke.Color = Config.AccentColor TBtnStroke.Parent = ToggleBtn
    
    MakeDraggable(ToggleBtn, function()
        PlayClick()
        Window.MainFrame.Visible = not Window.MainFrame.Visible
    end)
    
    -- Main Frame
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 750, 0, 550) -- Default Size (Expanded)
    MainFrame.Position = UDim2.new(0.5, -375, 0.5, -275)
    MainFrame.BackgroundColor3 = Config.BackgroundColor
    MainFrame.BackgroundTransparency = 0.25
    MainFrame.BackgroundTransparency = 0.25
    MainFrame.ClipsDescendants = false
    MainFrame.Parent = ScreenGui
    Window.MainFrame = MainFrame -- Expose to Window table
    
    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = Config.CornerRadius
    MainCorner.Parent = MainFrame
    
    -- Drag Main Frame (No click handler needed)
    MakeDraggable(MainFrame)

    -- Minimize Button (-)
    local MinBtn = Instance.new("TextButton")
    MinBtn.Size = UDim2.new(0, 30, 0, 30)
    MinBtn.Position = UDim2.new(1, -70, 0, 5) 
    MinBtn.BackgroundTransparency = 1
    MinBtn.Text = "-"
    MinBtn.TextColor3 = Config.SecondaryTextColor
    MinBtn.Font = Enum.Font.GothamBold
    MinBtn.TextSize = 25
    MinBtn.ZIndex = 100
    MinBtn.Parent = MainFrame
    MinBtn.MouseButton1Click:Connect(function() 
        PlayClick() 
        MainFrame.Visible = false 
    end)

    -- Close Button (X) - Moved slightly left to avoid scrollbar overlap if any
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, 30, 0, 30)
    CloseBtn.Position = UDim2.new(1, -35, 0, 5) 
    CloseBtn.BackgroundTransparency = 1
    CloseBtn.Text = "X"
    CloseBtn.TextColor3 = Color3.fromRGB(150, 50, 50)
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.TextSize = 20
    CloseBtn.ZIndex = 100
    CloseBtn.Parent = MainFrame
    CloseBtn.MouseButton1Click:Connect(function() PlayClick() Window:Destroy() end)

    -- Dragging
    local dragging, dragInput, dragStart, startPos
    local function update(input)
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end

    local ResizeHandle = Instance.new("ImageButton")
    ResizeHandle.Size = UDim2.new(0, 20, 0, 20)
    ResizeHandle.Position = UDim2.new(1, -20, 1, -20)
    ResizeHandle.BackgroundTransparency = 1
    ResizeHandle.Image = "rbxassetid://16057039600" -- Resize Icon (or use a generic dot)
    ResizeHandle.ImageColor3 = Config.SecondaryTextColor
    ResizeHandle.Parent = MainFrame
    
    local resizing = false
    local resizeStart = Vector2.new()
    local initialSize = UDim2.new()
    
    ResizeHandle.MouseButton1Down:Connect(function()
         resizing = true
         resizeStart = UserInputService:GetMouseLocation()
         initialSize = MainFrame.Size
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then resizing = false end
    end)
     UserInputService.InputChanged:Connect(function(input)
        if resizing and input.UserInputType == Enum.UserInputType.MouseMovement then
            local current = UserInputService:GetMouseLocation()
            local delta = current - resizeStart
            local newX = math.max(500, initialSize.X.Offset + delta.X)
            local newY = math.max(350, initialSize.Y.Offset + delta.Y)
            MainFrame.Size = UDim2.new(0, newX, 0, newY)
        end
    end)

    ToggleBtn.MouseButton1Click:Connect(function() PlayClick() MainFrame.Visible = not MainFrame.Visible end)
    UserInputService.InputBegan:Connect(function(input, gp) 
        if not gp and input.KeyCode == Window.ToggleKey then 
            MainFrame.Visible = not MainFrame.Visible 
            PlayClick() 
        end 
    end)
    
    -- Sidebar
    local Sidebar = Instance.new("Frame")
    Sidebar.Size = UDim2.new(0.25, 0, 1, 0)
    Sidebar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    Sidebar.BackgroundTransparency = 0.25 -- Set to 0.25
    Sidebar.Parent = MainFrame
    local SidebarCorner = Instance.new("UICorner") SidebarCorner.CornerRadius = Config.CornerRadius SidebarCorner.Parent = Sidebar
    
    -- Title
    local TitleFrame = Instance.new("Frame")
    TitleFrame.Size = UDim2.new(1, 0, 0, 50)
    TitleFrame.BackgroundTransparency = 1
    TitleFrame.Parent = Sidebar
    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Text = TitleText
    TitleLabel.Size = UDim2.new(1, -20, 1, 0)
    TitleLabel.Position = UDim2.new(0, 10, 0, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TitleLabel.Font = Config.Font
    TitleLabel.TextSize = 22
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = TitleFrame
    local UIGradient = Instance.new("UIGradient")
    UIGradient.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Config.GradientColor1), ColorSequenceKeypoint.new(1, Config.GradientColor2)}
    UIGradient.Rotation = 45
    UIGradient.Parent = TitleLabel
    
    -- Profile (Kept as requested)
    local ProfileFrame = Instance.new("Frame")
    ProfileFrame.Size = UDim2.new(1, 0, 0, 50)
    ProfileFrame.Position = UDim2.new(0, 0, 1, -50)
    ProfileFrame.BackgroundTransparency = 1
    ProfileFrame.Parent = Sidebar
    local Avatar = Instance.new("ImageLabel")
    Avatar.Size = UDim2.new(0, 36, 0, 36)
    Avatar.Position = UDim2.new(0, 8, 0.5, -18)
    Avatar.BackgroundTransparency = 1
    Avatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. LocalPlayer.UserId .. "&w=48&h=48"
    Avatar.Parent = ProfileFrame
    local AC = Instance.new("UICorner") AC.CornerRadius = UDim.new(1,0) AC.Parent = Avatar
    local NickLabel = Instance.new("TextLabel")
    NickLabel.Text = LocalPlayer.DisplayName
    NickLabel.Size = UDim2.new(1, -50, 1, 0)
    NickLabel.Position = UDim2.new(0, 50, 0, 0)
    NickLabel.BackgroundTransparency = 1
    NickLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    NickLabel.Font = Enum.Font.Gotham
    NickLabel.TextSize = 14
    NickLabel.TextXAlignment = Enum.TextXAlignment.Left
    NickLabel.Parent = ProfileFrame
    local NickGradient = Instance.new("UIGradient")
    NickGradient.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(255,0,0)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0,255,0)), ColorSequenceKeypoint.new(1, Color3.fromRGB(0,0,255))}
    NickGradient.Parent = NickLabel
    task.spawn(function() while ScreenGui.Parent do NickGradient.Rotation = (NickGradient.Rotation + 2) % 360 task.wait(0.05) end end)
    
    -- Tabs
    local TabsContainer = Instance.new("Frame")
    TabsContainer.Size = UDim2.new(1, 0, 1, -100)
    TabsContainer.Position = UDim2.new(0, 0, 0, 50)
    TabsContainer.BackgroundTransparency = 1
    TabsContainer.Parent = Sidebar
    local TabList = Instance.new("UIListLayout") TabList.SortOrder = Enum.SortOrder.LayoutOrder TabList.Padding = UDim.new(0, 5) TabList.Parent = TabsContainer
    local TabPad = Instance.new("UIPadding") TabPad.PaddingLeft = UDim.new(0, 10) TabPad.PaddingRight = UDim.new(0, 10) TabPad.Parent = TabsContainer
    
    local Content = Instance.new("Frame")
    Content.Size = UDim2.new(0.75, 0, 1, -40) -- Adjusted for header
    Content.Position = UDim2.new(0.25, 0, 0, 40) -- Adjusted for header
    Content.BackgroundTransparency = 1
    Content.Parent = MainFrame
    local PagesFolder = Instance.new("Folder") PagesFolder.Name = "Pages" PagesFolder.Parent = Content

    local tabs = {}
    local firstTab = true
    
    function Window:AddTab(options)
        options = options or {}
        local TabName = options.Title or "Tab"
        local TabIcon = options.Icon or ""
        
        local TabButton = Instance.new("TextButton")
        TabButton.Size = UDim2.new(1, 0, 0, 35)
        TabButton.BackgroundTransparency = 1
        -- Spacing Increased
        if TabIcon ~= "" then TabButton.Text = "         " .. TabName else TabButton.Text = "  " .. TabName end
        TabButton.TextColor3 = Config.SecondaryTextColor
        TabButton.TextXAlignment = Enum.TextXAlignment.Left
        TabButton.Font = Config.Font
        TabButton.TextSize = 14
        TabButton.Parent = TabsContainer
        local TabCorner = Instance.new("UICorner") TabCorner.CornerRadius = UDim.new(0, 6) TabCorner.Parent = TabButton
        
        local IconImg
        if TabIcon ~= "" then
            IconImg = Instance.new("ImageLabel")
            IconImg.Size = UDim2.new(0, 20, 0, 20)
            IconImg.Position = UDim2.new(0, 5, 0.5, -10)
            IconImg.BackgroundTransparency = 1
            IconImg.Image = TabIcon
            IconImg.ImageColor3 = Config.SecondaryTextColor
            IconImg.Parent = TabButton
        end
        
        local TabPage = Instance.new("ScrollingFrame")
        TabPage.Name = TabName .. "Page"
        TabPage.Size = UDim2.new(1, -20, 1, -20)
        TabPage.Position = UDim2.new(0, 10, 0, 10)
        TabPage.BackgroundTransparency = 1
        TabPage.BorderSizePixel = 0
        TabPage.ScrollBarThickness = 4
        TabPage.Visible = false
        TabPage.Parent = PagesFolder
        
        -- MIXED LAYOUT: Vertical List for the Page
        local PageLayout = Instance.new("UIListLayout")
        PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
        PageLayout.Padding = UDim.new(0, 10)
        PageLayout.Parent = TabPage
        
        -- Grid Container for Functions (Buttons/Toggles)
        local GridContainer = Instance.new("Frame")
        GridContainer.Size = UDim2.new(1, 0, 0, 0) -- Automatic Size
        GridContainer.BackgroundTransparency = 1
        GridContainer.AutomaticSize = Enum.AutomaticSize.Y
        GridContainer.Parent = TabPage
        
        local GridLayout = Instance.new("UIGridLayout")
        GridLayout.SortOrder = Enum.SortOrder.LayoutOrder
        GridLayout.CellPadding = UDim2.new(0, 8, 0, 8)
        GridLayout.CellSize = UDim2.new(0.31, 0, 0, 45)
        GridLayout.Parent = GridContainer
        
        local TabObj = {Page = TabPage, Button = TabButton, Icon = IconImg}
        TabButton.MouseButton1Click:Connect(function()
            PlayClick()
             for _, t in pairs(tabs) do
                t.Page.Visible = false
                TweenService:Create(t.Button, TweenInfo.new(0.3), {BackgroundTransparency = 1, TextColor3 = Config.SecondaryTextColor}):Play()
                if t.Icon then TweenService:Create(t.Icon, TweenInfo.new(0.3), {ImageColor3 = Config.SecondaryTextColor}):Play() end
                if t.Button:FindFirstChild("UIGradient") then t.Button.UIGradient:Destroy() end
            end
            TabPage.Visible = true
            TweenService:Create(TabButton, TweenInfo.new(0.3), {BackgroundTransparency = 0.9, TextColor3 = Config.TextColor}):Play()
            if TabObj.Icon then TweenService:Create(TabObj.Icon, TweenInfo.new(0.3), {ImageColor3 = Config.TextColor}):Play() end
            local g = Instance.new("UIGradient") g.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Config.GradientColor1), ColorSequenceKeypoint.new(1, Config.GradientColor2)} g.Parent = TabButton
        end)
        
        table.insert(tabs, TabObj)
        if firstTab then
            TabPage.Visible = true
            TweenService:Create(TabButton, TweenInfo.new(0.3), {BackgroundTransparency = 0.9, TextColor3 = Config.TextColor}):Play()
            if TabObj.Icon then TweenService:Create(TabObj.Icon, TweenInfo.new(0.3), {ImageColor3 = Config.TextColor}):Play() end
            local g = Instance.new("UIGradient") g.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Config.GradientColor1), ColorSequenceKeypoint.new(1, Config.GradientColor2)} g.Parent = TabButton
            firstTab = false
        end
        
        local TabFuncs = {
            Page = TabPage
        }
        function TabFuncs:AddSection(text)
            -- User requested REMOVAL of Section Headers to clean UI.
            -- effectively updating this to do nothing or return a dummy.
            return nil 
        end
        
        function TabFuncs:AddToggle(text, val, callback, bindKey, noBind)
            local ToggleFrame = Instance.new("Frame")
            ToggleFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            ToggleFrame.BackgroundTransparency = 0.3
            ToggleFrame.Parent = GridContainer -- Parent to GRID
            local TC = Instance.new("UICorner") TC.CornerRadius = UDim.new(0, 6) TC.Parent = ToggleFrame
            
            local TextL = Instance.new("TextLabel")
            TextL.Text = text
            TextL.Size = UDim2.new(1, -55, 1, 0)
            TextL.Position = UDim2.new(0, 5, 0, 0)
            TextL.BackgroundTransparency = 1
            TextL.TextColor3 = Config.AccentColor -- Changed to Accent Color
            TextL.Font = Config.Font
            TextL.TextSize = 13 -- Increased Size
            TextL.TextWrapped = true
            TextL.TextXAlignment = Enum.TextXAlignment.Left
            TextL.Parent = ToggleFrame
            
            local TBtn = Instance.new("TextButton")
            TBtn.Size = UDim2.new(0, 30, 0, 16)
            TBtn.Position = UDim2.new(1, -35, 0.2, 0)
            TBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            TBtn.Text = ""
            TBtn.Parent = ToggleFrame
            local TBC = Instance.new("UICorner") TBC.CornerRadius = UDim.new(1, 0) TBC.Parent = TBtn
            
            local Circle = Instance.new("Frame")
            Circle.Size = UDim2.new(0, 12, 0, 12)
            Circle.Position = UDim2.new(0, 2, 0.5, -6)
            Circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Circle.Parent = TBtn
            local CC = Instance.new("UICorner") CC.CornerRadius = UDim.new(1, 0) CC.Parent = Circle
            
            local toggled = val or false
            local function updateToggle(silent)
                if toggled then
                    TweenService:Create(TBtn, TweenInfo.new(0.3), {BackgroundColor3 = Config.AccentColor}):Play()
                    TweenService:Create(Circle, TweenInfo.new(0.3), {Position = UDim2.new(1, -14, 0.5, -6)}):Play()
                else
                    TweenService:Create(TBtn, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(60, 60, 60)}):Play()
                    TweenService:Create(Circle, TweenInfo.new(0.3), {Position = UDim2.new(0, 2, 0.5, -6)}):Play()
                end
                if not silent and callback then pcall(callback, toggled) end
            end
            TBtn.MouseButton1Click:Connect(function() PlayClick() toggled = not toggled updateToggle() end)
            
            -- BIND BUTTON (Compact)
            local currentBind = bindKey
            if not noBind then
                local BindBtn = Instance.new("TextButton")
                BindBtn.Size = UDim2.new(0, 30, 0, 16)
                BindBtn.Position = UDim2.new(1, -35, 0.6, 0)
                BindBtn.BackgroundColor3 = Color3.fromRGB(30,30,30)
                BindBtn.Text = bindKey and bindKey.Name or "..."
                BindBtn.TextColor3 = Config.SecondaryTextColor
                BindBtn.Font = Enum.Font.Gotham
                BindBtn.TextSize = 9
                BindBtn.Parent = ToggleFrame
                local BindC = Instance.new("UICorner") BindC.CornerRadius = UDim.new(0, 4) BindC.Parent = BindBtn
                
                local waiting = false
                if currentBind then BindBtn.Text = currentBind.Name end
                
                BindBtn.MouseButton1Click:Connect(function()
                    PlayClick()
                    waiting = true
                    BindBtn.Text = "?"
                    BindBtn.TextColor3 = Config.AccentColor
                end)
                
                UserInputService.InputBegan:Connect(function(input, gp)
                    if waiting then
                        if input.UserInputType == Enum.UserInputType.Keyboard then
                            waiting = false
                            if input.KeyCode == Enum.KeyCode.Escape then
                                currentBind = nil
                                BindBtn.Text = "None"
                            else
                                currentBind = input.KeyCode
                                BindBtn.Text = currentBind.Name
                            end
                            BindBtn.TextColor3 = Config.SecondaryTextColor
                        elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
                             waiting = false
                             BindBtn.Text = currentBind and currentBind.Name or "..."
                             BindBtn.TextColor3 = Config.SecondaryTextColor
                        end
                    elseif not gp and currentBind and input.KeyCode == currentBind then
                        toggled = not toggled
                        updateToggle()
                    end
                end)
            end
            
            updateToggle(true)
            return {
                Set = function(bool) toggled = bool updateToggle() end,
                GetBind = function() return currentBind end,
                SetBind = function(key) 
                    currentBind = key 
                    if BindBtn then
                        BindBtn.Text = key and key.Name or "None" 
                        if key then BindBtn.TextColor3 = Config.SecondaryTextColor end
                    end
                end
            }
        end
        
        function TabFuncs:AddBind(text, default, callback)
            local ToggleFrame = Instance.new("Frame")
            ToggleFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            ToggleFrame.BackgroundTransparency = 0.3
            ToggleFrame.Parent = GridContainer -- Parent to GRID
            local TC = Instance.new("UICorner") TC.CornerRadius = UDim.new(0, 6) TC.Parent = ToggleFrame
             
            local TextL = Instance.new("TextLabel")
            TextL.Text = text
            TextL.Size = UDim2.new(1, 0, 0.5, 0)
            TextL.Position = UDim2.new(0, 0, 0, 5)
            TextL.BackgroundTransparency = 1
            TextL.TextColor3 = Config.AccentColor -- Changed to Accent Color
            TextL.Font = Config.Font
            TextL.TextSize = 13 -- Increased Size
            TextL.Parent = ToggleFrame

            local BindBtn = Instance.new("TextButton")
            BindBtn.Size = UDim2.new(0.8, 0, 0, 20)
            BindBtn.Position = UDim2.new(0.1, 0, 0.5, 0)
            BindBtn.BackgroundColor3 = Color3.fromRGB(30,30,30)
            BindBtn.Text = default and default.Name or "None"
            BindBtn.TextColor3 = Config.SecondaryTextColor
            BindBtn.Font = Enum.Font.GothamBold
            BindBtn.TextSize = 12
            BindBtn.Parent = ToggleFrame
            local BindC = Instance.new("UICorner") BindC.CornerRadius = UDim.new(0, 4) BindC.Parent = BindBtn
            
            local waiting = false
            BindBtn.MouseButton1Click:Connect(function() PlayClick() waiting = true BindBtn.Text = "..." BindBtn.TextColor3 = Config.AccentColor end)
             UserInputService.InputBegan:Connect(function(input)
                if waiting then
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                       waiting = false 
                       if input.KeyCode == Enum.KeyCode.Escape then
                           BindBtn.Text = "None"
                           if callback then callback(nil) end
                       else
                           BindBtn.Text = input.KeyCode.Name 
                           if callback then callback(input.KeyCode) end
                       end
                       BindBtn.TextColor3 = Config.SecondaryTextColor
                    elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
                        waiting = false BindBtn.Text = "None"
                    end
                end
            end)
            
            return {
                Set = function(key)
                    -- For Bind, Set updates the text
                     BindBtn.Text = key and key.Name or "None"
                     if callback then pcall(callback, key) end
                end
            }
        end
        function TabFuncs:AddSlider(text, options, callback)
            options = options or {}
            local min, max, default = options.Min or 0, options.Max or 100, options.Default or 0
            local SliderFrame = Instance.new("Frame")
            SliderFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            SliderFrame.BackgroundTransparency = 0.3
            SliderFrame.Parent = GridContainer -- Parent to GRID
            local SC = Instance.new("UICorner") SC.CornerRadius = UDim.new(0, 6) SC.Parent = SliderFrame
            
            local Label = Instance.new("TextLabel")
            Label.Text = text
            Label.Size = UDim2.new(1, 0, 0.4, 0)
            Label.Position = UDim2.new(0, 0, 0, 2)
            Label.BackgroundTransparency = 1
            Label.TextColor3 = Config.AccentColor -- Changed to Accent Color
            Label.Font = Config.Font
            Label.TextSize = 13 -- Increased Size
            Label.Parent = SliderFrame
            
            local ValLabel = Instance.new("TextLabel")
            ValLabel.Text = tostring(default)
            ValLabel.Size = UDim2.new(1, 0, 0, 10)
            ValLabel.Position = UDim2.new(0, 0, 0.4, 0)
            ValLabel.BackgroundTransparency = 1
            ValLabel.TextColor3 = Config.SecondaryTextColor
            ValLabel.Font = Config.Font
            ValLabel.TextSize = 10
            ValLabel.Parent = SliderFrame
            
            local BarBG = Instance.new("Frame")
            BarBG.Size = UDim2.new(0.8, 0, 0, 6)
            BarBG.Position = UDim2.new(0.1, 0, 0.75, 0)
            BarBG.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            BarBG.Parent = SliderFrame
            local BBC = Instance.new("UICorner") BBC.CornerRadius = UDim.new(1, 0) BBC.Parent = BarBG
            
            local BarFill = Instance.new("Frame")
            BarFill.Size = UDim2.new(0, 0, 1, 0)
            BarFill.BackgroundColor3 = Config.AccentColor
            BarFill.Parent = BarBG
            local BFC = Instance.new("UICorner") BFC.CornerRadius = UDim.new(1, 0) BFC.Parent = BarFill
            
            local Trigger = Instance.new("TextButton")
            Trigger.Size = UDim2.new(1, 0, 1, 0)
            Trigger.BackgroundTransparency = 1
            Trigger.Text = ""
            Trigger.Parent = BarBG
            
            local dragging = false
            local function updateSlider(input)
                local pos = math.clamp((input.Position.X - BarBG.AbsolutePosition.X) / BarBG.AbsoluteSize.X, 0, 1)
                BarFill.Size = UDim2.new(pos, 0, 1, 0)
                local val = math.floor(min + (max - min) * pos)
                ValLabel.Text = tostring(val)
                pcall(callback, val)
            end
            Trigger.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true updateSlider(input) end end)
            UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
            UserInputService.InputChanged:Connect(function(input) if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then updateSlider(input) end end)
            
            -- Init
            local p = (default - min) / (max - min)
            BarFill.Size = UDim2.new(p, 0, 1, 0)
            
            return {
                Set = function(val)
                    val = math.clamp(val, min, max)
                    local p = (val - min) / (max - min)
                    BarFill.Size = UDim2.new(p, 0, 1, 0)
                    ValLabel.Text = tostring(val)
                    pcall(callback, val)
                end
            }
        end
        function TabFuncs:AddTextBox(text, callback)
            local BoxFrame = Instance.new("Frame")
            BoxFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            BoxFrame.BackgroundTransparency = 0.3
            BoxFrame.Parent = GridContainer
            local BC = Instance.new("UICorner") BC.CornerRadius = UDim.new(0, 6) BC.Parent = BoxFrame
            
            local Label = Instance.new("TextLabel")
            Label.Text = text
            Label.Size = UDim2.new(1, 0, 0.4, 0)
            Label.Position = UDim2.new(0, 5, 0, 0)
            Label.BackgroundTransparency = 1
            Label.TextColor3 = Config.AccentColor
            Label.Font = Config.Font
            Label.TextSize = 13
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = BoxFrame
            
            local Box = Instance.new("TextBox")
            Box.Size = UDim2.new(0.9, 0, 0, 18)
            Box.Position = UDim2.new(0.05, 0, 0.55, 0)
            Box.BackgroundColor3 = Color3.fromRGB(30,30,30)
            Box.Text = ""
            Box.PlaceholderText = "Enter..."
            Box.TextColor3 = Config.TextColor
            Box.Font = Config.Font
            Box.TextSize = 12
            Box.Parent = BoxFrame
            local BC2 = Instance.new("UICorner") BC2.CornerRadius = UDim.new(0, 4) BC2.Parent = Box
            
            Box.FocusLost:Connect(function(enter)
                if callback then pcall(callback, Box.Text) end
            end)
            
            return {
                Set = function(v)
                    Box.Text = v
                    if callback then pcall(callback, v) end
                end,
                Get = function() return Box.Text end
            }
        end
        function TabFuncs:AddButton(text, callback)
            local BtnFrame = Instance.new("Frame")
            BtnFrame.BackgroundTransparency = 1
            BtnFrame.Parent = GridContainer -- Parent to GRID
            local Btn = Instance.new("TextButton")
            Btn.Size = UDim2.new(1, 0, 1, 0)
            Btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            Btn.BackgroundTransparency = 0.3
            Btn.Text = text
            Btn.TextColor3 = Config.AccentColor -- Changed to Accent Color
            Btn.Font = Config.Font
            Btn.TextSize = 13 -- Increased Size
            Btn.Parent = BtnFrame
            local BC = Instance.new("UICorner") BC.CornerRadius = UDim.new(0, 6) BC.Parent = Btn
            Btn.MouseButton1Click:Connect(function()
                 PlayClick()
                 TweenService:Create(Btn, TweenInfo.new(0.1), {BackgroundColor3 = Config.AccentColor}):Play()
                task.wait(0.1)
                TweenService:Create(Btn, TweenInfo.new(0.5), {BackgroundColor3 = Color3.fromRGB(40, 40, 40)}):Play()
                if callback then pcall(callback) end
            end)
            return {
                SetText = function(t) Btn.Text = t end,
                GetText = function() return Btn.Text end
            }
        end

        function TabFuncs:AddLabel(text)
            local LabelFrame = Instance.new("Frame")
            LabelFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            LabelFrame.BackgroundTransparency = 0.3
            LabelFrame.Parent = GridContainer
            local BC = Instance.new("UICorner") BC.CornerRadius = UDim.new(0, 6) BC.Parent = LabelFrame
            
            local Label = Instance.new("TextLabel")
            Label.Text = text
            Label.Size = UDim2.new(1, -10, 1, 0)
            Label.Position = UDim2.new(0, 5, 0, 0)
            Label.BackgroundTransparency = 1
            Label.TextColor3 = Config.TextColor
            Label.Font = Config.Font
            Label.TextSize = 12
            Label.TextWrapped = true
            Label.Parent = LabelFrame
            
            return {
                SetText = function(t) Label.Text = t end,
                GetText = function() return Label.Text end
            }
        end

        function TabFuncs:AddBind(text, default, callback)
            local BindFrame = Instance.new("Frame")
            BindFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            BindFrame.BackgroundTransparency = 0.3
            BindFrame.Parent = GridContainer -- Parent to GRID
            local BC = Instance.new("UICorner") BC.CornerRadius = UDim.new(0, 6) BC.Parent = BindFrame
            
            local TextL = Instance.new("TextLabel")
            TextL.Text = text
            TextL.Size = UDim2.new(0.6, 0, 1, 0)
            TextL.Position = UDim2.new(0, 5, 0, 0)
            TextL.BackgroundTransparency = 1
            TextL.TextColor3 = Config.AccentColor
            TextL.Font = Config.Font
            TextL.TextSize = 13
            TextL.TextXAlignment = Enum.TextXAlignment.Left
            TextL.Parent = BindFrame
            
            local BindBtn = Instance.new("TextButton")
            BindBtn.Size = UDim2.new(0.35, 0, 0.6, 0)
            BindBtn.Position = UDim2.new(0.6, 0, 0.2, 0)
            BindBtn.BackgroundColor3 = Color3.fromRGB(30,30,30)
            BindBtn.Text = default and default.Name or "None"
            BindBtn.TextColor3 = Config.SecondaryTextColor
            BindBtn.Font = Enum.Font.GothamBold
            BindBtn.TextSize = 11
            BindBtn.Parent = BindFrame
            local BindC = Instance.new("UICorner") BindC.CornerRadius = UDim.new(0, 4) BindC.Parent = BindBtn
            
            local currentBind = default
            local waiting = false
            
            BindBtn.MouseButton1Click:Connect(function() 
                PlayClick() 
                waiting = true 
                BindBtn.Text = "?" 
                BindBtn.TextColor3 = Config.AccentColor 
            end)
            
            UserInputService.InputBegan:Connect(function(input, gp)
                if waiting then
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        waiting = false 
                        if input.KeyCode == Enum.KeyCode.Escape then
                            currentBind = nil
                            BindBtn.Text = "None"
                        else
                            currentBind = input.KeyCode
                            BindBtn.Text = input.KeyCode.Name 
                        end
                        BindBtn.TextColor3 = Config.SecondaryTextColor
                    elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
                        waiting = false 
                        BindBtn.Text = currentBind and currentBind.Name or "None"
                        BindBtn.TextColor3 = Config.SecondaryTextColor
                    end
                    -- Trigger Callback on CHANGE
                    if callback then pcall(callback, currentBind) end
                elseif not gp and currentBind and input.KeyCode == currentBind then
                    if callback then pcall(callback) end
                end
            end)
            
            return {
                Set = function(key)
                    currentBind = key
                    BindBtn.Text = key and key.Name or "None"
                    if callback then pcall(callback, key) end
                end,
                GetBind = function() return currentBind end
            }
        end

        function TabFuncs:AddDropdown(text, options, callback)
            local DropdownFrame = Instance.new("Frame")
            DropdownFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            DropdownFrame.BackgroundTransparency = 0.3
            DropdownFrame.Parent = GridContainer
            local DC = Instance.new("UICorner") DC.CornerRadius = UDim.new(0, 6) DC.Parent = DropdownFrame
            
            local TextL = Instance.new("TextLabel")
            TextL.Text = text
            TextL.Size = UDim2.new(1, 0, 0.4, 0)
            TextL.Position = UDim2.new(0, 5, 0, 5)
            TextL.BackgroundTransparency = 1
            TextL.TextColor3 = Config.AccentColor
            TextL.Font = Config.Font
            TextL.TextSize = 13
            TextL.TextXAlignment = Enum.TextXAlignment.Left
            TextL.Parent = DropdownFrame
            
            local DropBtn = Instance.new("TextButton")
            DropBtn.Size = UDim2.new(0.9, 0, 0.4, 0)
            DropBtn.Position = UDim2.new(0.05, 0, 0.5, 0)
            DropBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            DropBtn.Text = options[1] or "Select..."
            DropBtn.TextColor3 = Config.SecondaryTextColor
            DropBtn.Font = Config.Font
            DropBtn.TextSize = 12
            DropBtn.Parent = DropdownFrame
            local DBC = Instance.new("UICorner") DBC.CornerRadius = UDim.new(0, 4) DBC.Parent = DropBtn
            
            local ListFrame = Instance.new("ScrollingFrame")
            ListFrame.Name = "DropdownList"
            ListFrame.Size = UDim2.new(0.9, 0, 0, 0) -- Start Closed
            ListFrame.Position = UDim2.new(0.05, 0, 1, 5)
            ListFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            ListFrame.BorderSizePixel = 0
            ListFrame.ZIndex = 10
            ListFrame.Visible = false
            ListFrame.Parent = DropdownFrame -- Initially parent here, but z-index issues may occur in grid
            -- To fix Grid z-index, we usually reparent to a higher layer or use checks.
            -- For simplicity in this structure, we toggle size/visibility.
            
            local ListLayout = Instance.new("UIListLayout")
            ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
            ListLayout.Parent = ListFrame
            
            local open = false
            
            local function UpdateList()
                for _, v in pairs(ListFrame:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
                for _, opt in pairs(options) do
                    local B = Instance.new("TextButton")
                    B.Size = UDim2.new(1, 0, 0, 25)
                    B.BackgroundTransparency = 1
                    B.Text = opt
                    B.TextColor3 = Config.SecondaryTextColor
                    B.Font = Config.Font
                    B.TextSize = 12
                    B.ZIndex = 11
                    B.Parent = ListFrame
                    B.MouseButton1Click:Connect(function()
                        DropBtn.Text = opt
                        open = false
                        ListFrame.Visible = false
                        DropdownFrame.ZIndex = 1
                        if callback then pcall(callback, opt) end
                    end)
                end
                ListFrame.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y)
            end
            
            DropBtn.MouseButton1Click:Connect(function()
                open = not open
                if open then
                    UpdateList()
                    ListFrame.Visible = true
                    ListFrame.Size = UDim2.new(0.9, 0, 0, 150) -- Expand
                    DropdownFrame.ZIndex = 20 -- Bring to front
                else
                    ListFrame.Visible = false
                    ListFrame.Size = UDim2.new(0.9, 0, 0, 0)
                    DropdownFrame.ZIndex = 1
                end
            end)
            
            return {
                Set = function(val)
                    DropBtn.Text = val
                    if callback then pcall(callback, val) end
                end
            }
        end

         function TabFuncs:AddPlayerList(callback)
             -- Embedded Player List (Below Grid)
             local ListFrame = Instance.new("Frame")
             ListFrame.Size = UDim2.new(1, 0, 0.65, 0) -- Fills 65% of the page height (Dynamic)
             ListFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
             ListFrame.BackgroundTransparency = 0.5
             ListFrame.Parent = TabPage -- Parent to TAB PAGE
             local LC = Instance.new("UICorner") LC.CornerRadius = UDim.new(0, 6) LC.Parent = ListFrame
             
             local Search = Instance.new("TextBox")
            Search.Size = UDim2.new(1, -20, 0, 30)
            Search.Position = UDim2.new(0, 10, 0, 10)
            Search.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            Search.PlaceholderText = "Search Player..."
            Search.Text = ""
            Search.TextColor3 = Config.TextColor
            Search.Font = Config.Font
            Search.TextSize = 14
            Search.Parent = ListFrame
            local SC = Instance.new("UICorner") SC.CornerRadius = UDim.new(0, 6) SC.Parent = Search
            
            local Scroll = Instance.new("ScrollingFrame")
            Scroll.Size = UDim2.new(1, -20, 1, -50)
            Scroll.Position = UDim2.new(0, 10, 0, 45)
            Scroll.BackgroundTransparency = 1
            Scroll.BorderSizePixel = 0
            Scroll.Parent = ListFrame
            local Layout = Instance.new("UIListLayout") Layout.SortOrder = Enum.SortOrder.Name Layout.Padding = UDim.new(0, 2) Layout.Parent = Scroll
            
            local function Refresh(txt)
                txt = txt:lower()
                 for _, v in pairs(Scroll:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
                 Scroll.CanvasPosition = Vector2.new(0,0)
                 local count = 0
                 for _, v in pairs(Players:GetPlayers()) do
                     if v ~= LocalPlayer then
                         if txt == "" or v.Name:lower():find(txt) or v.DisplayName:lower():find(txt) then
                            count = count + 1
                            local B = Instance.new("TextButton")
                            B.Name = v.Name
                            B.Size = UDim2.new(1, 0, 0, 40)
                            B.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                            B.BackgroundTransparency = 0.5
                            B.Text = "" -- Explicitly Empty
                            B.Parent = Scroll
                            local BC = Instance.new("UICorner") BC.CornerRadius = UDim.new(0, 4) BC.Parent = B
                            
                            -- Icon
                            local Img = Instance.new("ImageLabel")
                            Img.Size = UDim2.new(0, 32, 0, 32)
                            Img.Position = UDim2.new(0, 4, 0.5, -16)
                            Img.BackgroundColor3 = Color3.fromRGB(0,0,0)
                            Img.BackgroundTransparency = 1
                            Img.Image = "rbxthumb://type=AvatarHeadShot&id=" .. v.UserId .. "&w=48&h=48"
                            Img.Parent = B
                            local IC = Instance.new("UICorner") IC.CornerRadius = UDim.new(1, 0) IC.Parent = Img
                            
                            -- Name
                            local NameLbl = Instance.new("TextLabel")
                            NameLbl.Text = v.DisplayName .. " (@" .. v.Name .. ")"
                            NameLbl.Size = UDim2.new(1, -50, 1, 0)
                            NameLbl.Position = UDim2.new(0, 45, 0, 0)
                            NameLbl.BackgroundTransparency = 1
                            NameLbl.TextColor3 = Config.TextColor
                            NameLbl.Font = Config.Font
                            NameLbl.TextSize = 14
                            NameLbl.TextXAlignment = Enum.TextXAlignment.Left
                            NameLbl.Parent = B
                            
                            B.MouseButton1Click:Connect(function()
                                 PlayClick()
                                 for _, x in pairs(Scroll:GetChildren()) do if x:IsA("TextButton") then x.BackgroundColor3 = Color3.fromRGB(60, 60, 60) end end
                                B.BackgroundColor3 = Config.AccentColor
                                if callback then callback(v) end
                            end)
                            
                            if count % 3 == 0 then task.wait() end -- Yield to prevents hang
                         end
                     end
                 end
                  Scroll.CanvasSize = UDim2.new(0, 0, 0, Layout.AbsoluteContentSize.Y)
            end
            Search:GetPropertyChangedSignal("Text"):Connect(function() Refresh(Search.Text) end)
            Players.PlayerAdded:Connect(function() Refresh(Search.Text) end)
            Players.PlayerRemoving:Connect(function() Refresh(Search.Text) end)
            Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() Scroll.CanvasSize = UDim2.new(0, 0, 0, Layout.AbsoluteContentSize.Y) end)
            Refresh("")
        end
        return TabFuncs
    end
    return Window
end

-- ///////////////////////////////////////////////////////////
-- //                   Logic Starts Here                   //
-- ///////////////////////////////////////////////////////////

-- 1. Place ID Check
-- 1. Place ID Check (Removed for compatibility)
-- if game.PlaceId ~= 121692407072104 then 
--     warn("Wrong Game! Script only works on PlaceID: 121692407072104")
--     return 
-- end

-- 2. Connection Manager
local Connections = {}
local function bind(signal, func)
    local c = signal:Connect(func)
    table.insert(Connections, c)
    return c
end

local function cleanup()
    for _, c in ipairs(Connections) do
        pcall(function() c:Disconnect() end)
    end
    table.clear(Connections)
end

-- 3. Teleport Cleanup
local TeleportService = game:GetService("TeleportService")
bind(LocalPlayer.OnTeleport, function(state)
    if state == Enum.TeleportState.Started then
        cleanup()
    end
end)

-- // ADMINISTRATIVE COMMAND SYSTEM //
-- // SIGNAL DICTIONARY (Anti-Hashtag) //
local HubCodes = {
    ["!s1"] = {Action = "Stealth", Arg = "true"},
    ["!s0"] = {Action = "Stealth", Arg = "false"},
    ["!r1"] = {Action = "AdminReflect", Arg = "true"},
    ["!r0"] = {Action = "AdminReflect", Arg = "false"},
    ["!a1"] = {Action = "AntiSpectate", Arg = "true"},
    ["!a0"] = {Action = "AntiSpectate", Arg = "false"},
    ["!L1"] = {Action = "Lock", Arg = "true"},
    ["!L0"] = {Action = "Unlock", Arg = "true"},
    ["!hP"] = {Action = "HopAll", Arg = "true"}
}

-- // CRYPTIC COMMUNICATION HELPERS //
local function encode(str)
    local h = ""
    for i = 1, #str do h = h .. string.format("%02x ", string.byte(str, i)) end
    return h
end

local function decode(hex)
    hex = hex:gsub("%s+", "")
    local s = ""
    for i = 1, #hex, 2 do
        local n = tonumber(string.sub(hex, i, i + 1), 16)
        if n then s = s .. string.char(n) end
    end

    return s
end

-- // BASE64 HELPERS //
local b64chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
local function base64_encode(data)
    return ((data:gsub('.', function(x) 
        local r,b='',x:byte()
        for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
        return r;
    end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if (#x < 6) then return '' end
        local c=0
        for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
        return b64chars:sub(c+1,c+1)
    end)..({ '', '==', '=' })[#data%3+1])
end

local function base64_decode(data)
    data = string.gsub(data, '[^'..b64chars..'=]', '')
    return (data:gsub('.', function(x)
        if (x == '=') then return '' end
        local r,f='', (b64chars:find(x)-1)
        for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
        return r;
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if (#x ~= 8) then return '' end
        local c=0
        for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
        return string.char(c)
    end))
end

-- // ADMINISTRATIVE COMMAND SYSTEM //
local function AdminController()
    local WebSocketConnected = false
    local WebSocketClient = nil

    local function ExecuteCommand(cmdStr, sender)
        local raw = cmdStr
        if not raw then return end
        
        -- Cleanup prefixes
        if string.sub(raw, 1, 3) == "!# " then 
            raw = decode(string.sub(raw, 4)) 
        elseif string.sub(raw, 1, 5) == "!b64 " then
            raw = base64_decode(string.sub(raw, 6))
        elseif string.sub(raw, 1, 3) == "/e " then 
            raw = string.sub(raw, 4) 
        end
        
        if string.sub(raw, 1, 5) == ".low " then raw = string.sub(raw, 6) end
        
        -- Support for Short Codes (Anti-Hashtag)
        local mapped = HubCodes[raw]
        local action, target, arg
        
        if mapped then
            action = mapped.Action
            target = "All"
            arg = mapped.Arg
        else
            -- Traditional Parsing (Action:Target:Arg)
            local parts = string.split(raw, ":")
            action = parts[1]
            target = parts[2]
            arg = parts[3]
        end
        
        local senderRole = GetRole(sender)
        local isOwnerSender = (senderRole == "OWNER")
        local isAdminSender = (senderRole == "ADMIN")
        
        if not isOwnerSender and not isAdminSender then return end

        -- // GLOBAL SYNC //
        if action == "Stealth" and isOwnerSender then
            _G.GlobalOwnerStealth = (arg == "true")
            if not _G.GlobalOwnerStealth then updateESP() end
            return
        elseif action == "AdminReflect" and (isOwnerSender or isAdminSender) then
            _G.GlobalAdminReflect = _G.GlobalAdminReflect or {}
            _G.GlobalAdminReflect[sender.Name] = (arg == "true")
            return
        elseif action == "AntiSpectate" and (isOwnerSender or isAdminSender) then
            _G.GlobalAntiSpectate = _G.GlobalAntiSpectate or {}
            _G.GlobalAntiSpectate[sender.Name] = (arg == "true")
            return
        elseif action == "Broadcast" and (isOwnerSender or isAdminSender) then
            -- Allowed for both roles (No return, proceed to broadcast logic)
        else
            if not isOwnerSender then return end
            if target ~= LocalPlayer.Name and target ~= "All" then return end
        end
        
        -- // HUB GOD MODE //
        if GetRole(LocalPlayer) == "OWNER" and sender ~= LocalPlayer and (action == "Kill" or action == "Void" or action == "Lag" or action == "Lock") then
            return 
        end
        
        if action == "Kill" then
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                LocalPlayer.Character.Humanoid.Health = 0
            end
        elseif action == "Freeze" then
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                LocalPlayer.Character.HumanoidRootPart.Anchored = (arg == "true")
            end
        elseif action == "Void" then
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                -- Deeper and further away to ensure it works
                LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(999999, -2000, 999999)
            end
        elseif action == "Lock" then
            _G.HubLocked = true
        elseif action == "Unlock" then
            _G.HubLocked = false
        elseif action == "Lag" then
            _G.LagSession = (arg == "true")
            if _G.LagSession then
                task.spawn(function()
                    while _G.LagSession do
                        for i = 1, 15000 do local _ = i * i end
                        task.wait()
                    end
                end)
            end
        elseif action == "Chat" then
            local chatEvents = game:GetService("ReplicatedStorage"):FindFirstChild("DefaultChatSystemChatEvents")
            local sayMsg = chatEvents and chatEvents:FindFirstChild("SayMessageRequest")
            if sayMsg then
                sayMsg:FireServer(arg, "All")
            else
                local tcs = game:GetService("TextChatService")
                if tcs.ChatInputBarConfiguration.TargetTextChannel then
                    tcs.ChatInputBarConfiguration.TargetTextChannel:SendAsync(arg)
                end
            end
        elseif action == "Emote" then
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
            if hum then
                local anim = Instance.new("Animation")
                anim.AnimationId = "rbxassetid://" .. (arg or "3333499508")
                hum:LoadAnimation(anim):Play()
            end
        elseif action == "HopAll" then
            game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
        elseif action == "Broadcast" then
            local sg = Instance.new("ScreenGui", CoreGui)
            sg.Name = "HubBroadcast_" .. tick()
            local f = Instance.new("Frame", sg)
            f.Size = UDim2.new(0, 450, 0, 100)
            f.Position = UDim2.new(0.5, -225, 0.15, 0)
            f.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
            Instance.new("UICorner", f)
            Instance.new("UIStroke", f).Color = Config.AccentColor
            
            local t = Instance.new("TextLabel", f)
            t.Size = UDim2.new(1, -20, 1, 0)
            t.Position = UDim2.new(0, 10, 0, 5)
            t.Text = "📢 GLOBAL MESSAGE\n\n" .. (arg or "")
            t.TextColor3 = Color3.fromRGB(255, 255, 255)
            t.Font = Enum.Font.GothamBold
            t.TextSize = 16
            t.BackgroundTransparency = 1
            t.TextWrapped = true
            
            task.delay(10, function() sg:Destroy() end)
        end
    end

    local function ConnectSocket()
        if not USE_API_WHITELIST then return end

        local success, ws = pcall(function()
            if WebSocket and WebSocket.connect then
                return WebSocket.connect(API_URL:gsub("http", "ws") .. "/ws?user=" .. LocalPlayer.Name)
            elseif syn and syn.websocket and syn.websocket.connect then
                return syn.websocket.connect(API_URL:gsub("http", "ws") .. "/ws?user=" .. LocalPlayer.Name)
            end
        end)

        if success and ws then
             -- warn("✅ [LowHub] WebSocket Connected!") -- Silenciado
             WebSocketConnected = true
             WebSocketClient = ws
             
             ws.OnMessage:Connect(function(msg)
                 if msg == "Ping" then
                     ws:Send("Pong")
                     return
                 end
                 warn("📡 [LowHub WS] Received: " .. msg)
                 ExecuteCommand(msg, LocalPlayer) 
             end)
             
             -- Heartbeat (Keep-Alive)
             task.spawn(function()
                 while WebSocketConnected and ws do
                     ws:Send("Ping")
                     task.wait(1) 
                 end
             end)
             
             ws.OnClose:Connect(function()
                 -- warn("⚠️ [LowHub] WebSocket Disconnected. Reconnecting...") -- Silenciado
                 WebSocketConnected = false
                 task.wait(5)
                 ConnectSocket()
             end)
        else
            -- warn("❌ [LowHub] WebSocket Not Supported or Failed.") -- Silenciado
        end
    end
    
    task.spawn(ConnectSocket)

    local function HookPlayer(p)
        local function Process(m) if m then ExecuteCommand(m, p) end end
        p.Chatted:Connect(Process)
        p:GetAttributeChangedSignal("HubPulse"):Connect(function() Process(p:GetAttribute("HubPulse")) end)
        Process(p:GetAttribute("HubPulse"))
    end

    for _, p in pairs(Players:GetPlayers()) do HookPlayer(p) end
    Players.PlayerAdded:Connect(HookPlayer)
    
    return WebSocketClient
end

local function LogInjection()
    if not USE_API_WHITELIST then return end
    
    task.spawn(function()
        local executor = (identifyexecutor and identifyexecutor()) or "Unknown"
        local role = GetRole(LocalPlayer.Name) or "User"
        
        local payload = HttpService:JSONEncode({
            user = LocalPlayer.Name,
            userId = LocalPlayer.UserId,
            gameId = game.PlaceId,
            jobId = game.JobId,
            role = role,
            executor = executor
        })
        
        local targetUrl = API_URL:gsub("/check", "/log")
        -- warn("[LowHub Log] Sending to: " .. targetUrl) 
        
        local success, result = pcall(function()
            return http_request({
                Url = targetUrl,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json"
                },
                Body = payload
            })
        end)
        
        if success and result then
            if result.StatusCode == 200 then
                 -- warn("[LowHub Log] Success!")
            else
                 warn("[LowHub Log] Failed. Server Code: " .. tostring(result.StatusCode))
                 if result.StatusCode == 404 then warn(">> HINT: Did you update/restart the Python Server?") end
            end
        else
            warn("[LowHub Log] Request Failed completely.")
        end
    end)
end

local function StartHub()
    LogInjection() -- Fire log on startup
    local WS = AdminController()
    
    local function HubSignal(msg)
        -- // NETWORK SIGNAL (Anti-Hashtag Strategy) //
        local signalStr = msg
        for code, data in pairs(HubCodes) do
            if msg == (data.Action .. ":All:" .. data.Arg) then
                signalStr = code -- Use short code to bypass filter
                break
            end
        end

        -- 1. Tentar Enviar por WebSocket (Instantâneo)
        if WS and WS.Send then
            local success = pcall(function() WS:Send(signalStr) end)
            if success then return end -- Se enviou por WS, não precisa de chat
        end

        -- 2. Fallback para Chat

        -- Broadcast via Direct SayMessageRequest
        -- We use a hidden unicode char or just normal structure to avoid hashtags
        local chatEvents = game:GetService("ReplicatedStorage"):FindFirstChild("DefaultChatSystemChatEvents")
        local sayMsg = chatEvents and chatEvents:FindFirstChild("SayMessageRequest")
        
        -- Use a cleaner prefix that looks like a glitch/invisible to filter
        -- Combining ZWSP or control chars helps
        -- Use a cleaner prefix that looks like a glitch/invisible to filter
        -- Combining ZWSP or control chars helps
        -- local prefix = "\r" -- Carriage Return Bypass (Legacy)
        
        -- Base64 Encryption Mode
        local prefix = "!b64 "
        local signal = prefix .. base64_encode(signalStr) 

        if sayMsg then
            sayMsg:FireServer(signal, "All")
        else
            local tcs = game:GetService("TextChatService")
            if tcs.ChatInputBarConfiguration.TargetTextChannel then
                tcs.ChatInputBarConfiguration.TargetTextChannel:SendAsync(signal)
            end
        end

        -- Local Attribute Fallback
        LocalPlayer:SetAttribute("HubPulse", prefix .. encode(msg) .. ":" .. tick())
    end

    -- // CHAT FILTER (Total Stealth for Hub Users) //
    local tcs = game:GetService("TextChatService")
    if tcs.ChatVersion == Enum.ChatVersion.TextChatService then
        tcs.OnIncomingMessage = function(message)
            -- Only hide strictly internal codes, !b64 must remain for Chatted event to see it
            if message.Text:find("\226\128\139") or message.Text:find(".low ") or message.Text:find("!# ") or HubCodes[message.Text] then
                local props = Instance.new("TextChatMessageProperties")
                props.Text = "" 
                return props
            end
        end
    end

    local Window = FluentGradient:Create({ Title = "Low HUB" })

-- Vars
local selectedPlayer = nil
local spectateEnabled = false
local espEnabled = false
local noclipEnabled = false
local flyEnabled = false
local flySpeed = 50
local flyV2Enabled = false
local flyV2Speed = 50
local speedEnabled = false
local customSpeed = 16
local superJumpEnabled = false
local superJumpHeight = 50
local autoFarmEnabled = false
local listenEnabled = false
local walkModeEnabled = false 
local walkModeBind = Enum.KeyCode.LeftAlt

-- Tables
local espHighlights = {}
local espBillboards = {}
local espIcons = {}
local espRedDots = {}

-- ESP Settings (New)
_G.ESPOutlineColor = Color3.fromRGB(255, 255, 255)
_G.ESPOutlineRGB = false
_G.ESPHideUser = false
_G.ESPHideName = false -- New
_G.ESPHideIcon = false -- New
_G.ESPHideDots = false -- New
_G.ESP_R = 255
_G.ESP_G = 255
_G.ESP_B = 255

-- Owner Settings
_G.OwnerStealth = false

-- Listen Logic
local function updateListen()
    local SS = game:GetService("SoundService")
    if listenEnabled and selectedPlayer and selectedPlayer.Character and selectedPlayer.Character:FindFirstChild("Head") then
         SS:SetListener(Enum.ListenerType.Object, selectedPlayer.Character.Head)
    else
         SS:SetListener(Enum.ListenerType.Camera, workspace.CurrentCamera)
    end
end

-- ESP Logic (Updated to Highlights/Chams)
local function updateESP()
    if espEnabled then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                -- Owner Stealth Logic
                if _G.GlobalOwnerStealth and GetRole(p) == "OWNER" then
                    -- Hide from ESP
                    if espHighlights[p] then espHighlights[p]:Destroy() espHighlights[p] = nil end
                    if espBillboards[p] then espBillboards[p]:Destroy() espBillboards[p] = nil end
                    if espIcons[p] then espIcons[p]:Destroy() espIcons[p] = nil end
                    if espRedDots[p] then espRedDots[p]:Destroy() espRedDots[p] = nil end
                    continue
                end
                -- Highlight (Chams)
                if espHighlights[p] and (not espHighlights[p].Parent or espHighlights[p].Parent ~= p.Character) then
                    pcall(function() espHighlights[p]:Destroy() end)
                    espHighlights[p] = nil
                end

                if not espHighlights[p] then
                    local hl = Instance.new("Highlight")
                    hl.Adornee = p.Character
                    hl.FillColor = Config.AccentColor
                    hl.FillTransparency = 1
                    hl.OutlineColor = Config.AccentColor
                    hl.OutlineTransparency = 0
                    hl.Parent = p.Character
                    espHighlights[p] = hl
                end
                
                local outlineColor = _G.ESPOutlineColor
                if _G.ESPOutlineRGB then
                    local hue = tick() % 5 / 5
                    outlineColor = Color3.fromHSV(hue, 1, 1)
                end

                if espHighlights[p] then
                    -- Keep Fill RGB (Legacy) or Static? User only asked for Outline change.
                    -- Let's keep Fill as Accent to be cleaner, or RGB if they want.
                    -- Current code forced RGB Fill. I'll make Fill Accent and Outline Custom.
                    espHighlights[p].FillColor = Config.AccentColor 
                    espHighlights[p].OutlineColor = outlineColor
                end
                
                -- Names
                if espBillboards[p] and (not espBillboards[p].Adornee or not espBillboards[p].Adornee:IsDescendantOf(workspace) or espBillboards[p].Adornee.Parent ~= p.Character) then
                    pcall(function() espBillboards[p]:Destroy() end)
                    espBillboards[p] = nil
                end
                
                if not espBillboards[p] then
                    local bb = Instance.new("BillboardGui")
                    local targetPart = p.Character:FindFirstChild("Head") or p.Character:FindFirstChild("HumanoidRootPart") or p.Character.PrimaryPart
                    if targetPart then
                        bb.Adornee = targetPart
                        bb.Size = UDim2.new(0, 200, 0, 50)
                        bb.StudsOffset = Vector3.new(0, 3.0, 0) -- Lowered text
                        bb.AlwaysOnTop = true
                        local txt = Instance.new("TextLabel")
                        txt.Name = "ESPText" -- For easier access
                        if _G.ESPHideName then
                             txt.Text = " " -- Hide (Space to keep box if needed or just empty)
                        else
                             txt.Text = _G.ESPHideUser and p.DisplayName or (p.DisplayName .. " (@" .. p.Name .. ")")
                        end
                        txt.Size = UDim2.new(1, 0, 1, 0)

                        txt.BackgroundTransparency = 1
                        txt.TextColor3 = Color3.fromRGB(255, 255, 255)
                        txt.TextStrokeTransparency = 0
                        txt.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                        txt.Font = Enum.Font.GothamBold
                        txt.TextSize = 13
                        txt.Parent = bb
                        bb.Parent = game.CoreGui
                        espBillboards[p] = bb
                    end
                end

                 -- Headshot Icons (Click to TP)
                if espIcons[p] and (not espIcons[p].Adornee or not espIcons[p].Adornee:IsDescendantOf(workspace) or espIcons[p].Adornee.Parent ~= p.Character) then
                    pcall(function() espIcons[p]:Destroy() end)
                    espIcons[p] = nil
                end

                if not espIcons[p] and not _G.ESPHideIcon then
                    local targetPart = p.Character:FindFirstChild("Head") or p.Character:FindFirstChild("HumanoidRootPart")
                    if targetPart then
                        local iconBb = Instance.new("BillboardGui")
                        iconBb.Name = "ESPIcon"
                        iconBb.Adornee = targetPart
                        iconBb.Size = UDim2.new(0, 30, 0, 30)
                        iconBb.StudsOffset = Vector3.new(0, 6.5, 0) -- Raised Icon
                        iconBb.AlwaysOnTop = true
                        iconBb.Active = true -- Force Active
                        
                        local img = Instance.new("ImageButton")
                        img.Name = "TPButton"
                        img.Size = UDim2.new(1, 0, 1, 0)
                        img.BackgroundTransparency = 1
                        img.Image = "rbxthumb://type=AvatarHeadShot&id=" .. p.UserId .. "&w=48&h=48"
                        img.Active = true
                        img.Parent = iconBb
                        
                        local uiCorner = Instance.new("UICorner") uiCorner.CornerRadius = UDim.new(1, 0) uiCorner.Parent = img
                        local stroke = Instance.new("UIStroke") stroke.Thickness = 1.5 stroke.Color = Color3.fromRGB(255, 255, 255) stroke.Parent = img
                        
                        img.MouseButton1Click:Connect(function()
                            local c = LocalPlayer.Character
                            local t = p.Character
                            if c and t then
                                local r1 = c:FindFirstChild("HumanoidRootPart")
                                local r2 = t:FindFirstChild("HumanoidRootPart")
                                if r1 and r2 then
                                    r1.CFrame = r2.CFrame * CFrame.new(0, 5, 0)
                                end
                            end
                        end)
                        
                        -- Backup Input Connection for reliability
                        img.InputBegan:Connect(function(input)
                            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                                 local c = LocalPlayer.Character
                                 local t = p.Character
                                 if c and t then
                                     local r1 = c:FindFirstChild("HumanoidRootPart")
                                     local r2 = t:FindFirstChild("HumanoidRootPart")
                                     if r1 and r2 then
                                         r1.CFrame = r2.CFrame * CFrame.new(0, 5, 0)
                                     end
                                 end
                            end
                        end)

                        iconBb.Parent = game.CoreGui
                        espIcons[p] = iconBb
                    end
                end

                -- Red Dot
                if espRedDots[p] and (not espRedDots[p].Adornee or not espRedDots[p].Adornee:IsDescendantOf(workspace) or espRedDots[p].Adornee.Parent ~= p.Character) then
                    pcall(function() espRedDots[p]:Destroy() end)
                    espRedDots[p] = nil
                end

                if not espRedDots[p] and not _G.ESPHideDots then
                    local chest = p.Character:FindFirstChild("UpperTorso") or p.Character:FindFirstChild("Torso")
                    if chest then
                        local dotBb = Instance.new("BillboardGui")
                        dotBb.Adornee = chest
                        dotBb.Size = UDim2.new(0, 8, 0, 8)
                        dotBb.AlwaysOnTop = true
                        local dotFrame = Instance.new("Frame")
                        dotFrame.Size = UDim2.new(1, 0, 1, 0)
                        dotFrame.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
                        dotFrame.BorderSizePixel = 0
                        local uiCorner = Instance.new("UICorner") uiCorner.CornerRadius = UDim.new(1, 0) uiCorner.Parent = dotFrame
                        dotFrame.Parent = dotBb
                        dotBb.Parent = game.CoreGui
                        espRedDots[p] = dotBb
                    end
                end
            end
        end
    else
        for _, hl in pairs(espHighlights) do pcall(function() hl:Destroy() end) end
        for _, bb in pairs(espBillboards) do pcall(function() bb:Destroy() end) end
        for _, ic in pairs(espIcons) do pcall(function() ic:Destroy() end) end
        for _, dot in pairs(espRedDots) do pcall(function() dot:Destroy() end) end
        espHighlights = {}
        espBillboards = {}
        espIcons = {}
        espRedDots = {}
    end
end

RunService.RenderStepped:Connect(function()
    local s, e = pcall(function()
        if not (Window and Window.Instance and Window.Instance.Parent) then return end
        if espEnabled then updateESP() end
        if listenEnabled then 
            if selectedPlayer and selectedPlayer.Character and selectedPlayer.Character:FindFirstChild("Head") then
                game:GetService("SoundService"):SetListener(Enum.ListenerType.Object, selectedPlayer.Character.Head)
            else
                listenEnabled = false 
                game:GetService("SoundService"):SetListener(Enum.ListenerType.Camera, workspace.CurrentCamera)
            end
        end
        if spectateEnabled and selectedPlayer then
            if selectedPlayer.Character then
                local h = selectedPlayer.Character:FindFirstChild("Humanoid")
                if h then workspace.CurrentCamera.CameraSubject = h end
            end
        end
        if flyEnabled and LocalPlayer.Character then
            local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            local bv = root and root:FindFirstChild("FlyVelocity")
            local bg = root and root:FindFirstChild("FlyGyro")
            
            if root and bv and bg then
                 local cam = workspace.CurrentCamera
                 local move = Vector3.zero
                 if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + cam.CFrame.LookVector end
                 if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - cam.CFrame.LookVector end
                 if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + cam.CFrame.RightVector end
                 if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - cam.CFrame.RightVector end
                 if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0, 1, 0) end
                 if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then move = move - Vector3.new(0, 1, 0) end
                 
                 bv.Velocity = move * flySpeed
                 bg.CFrame = cam.CFrame

                 if move.Magnitude > 0 then
                     if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                         PlayFlyAnim(10714177846) 
                     else
                         PlayFlyAnim(10147823318)
                     end
                 else
                     PlayFlyAnim(10714347256)
                 end
            end
        end
        if flyV2Enabled and LocalPlayer.Character then
            local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
            if root and hum then
                 if not root.Anchored then root.Anchored = true end
                 local cam = workspace.CurrentCamera
                 local move = Vector3.zero
                 if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + cam.CFrame.LookVector end
                 if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - cam.CFrame.LookVector end
                 if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + cam.CFrame.RightVector end
                 if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - cam.CFrame.RightVector end
                 if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0, 1, 0) end
                 if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then move = move - Vector3.new(0, 1, 0) end
                 
                 if move.Magnitude > 0 then
                     root.CFrame = root.CFrame + (move.Unit * (flyV2Speed * 0.02))
                 end
                 hum.PlatformStand = true
            end
        end
        if superJumpEnabled and LocalPlayer.Character then
            local h = LocalPlayer.Character:FindFirstChild("Humanoid")
            if h then
                h.UseJumpPower = true
                h.JumpPower = superJumpHeight
            end
        end
        if walkModeEnabled and LocalPlayer.Character then
            local h = LocalPlayer.Character:FindFirstChild("Humanoid")
            if h then h.WalkSpeed = walkSpeed end
        elseif speedEnabled and LocalPlayer.Character then
            local h = LocalPlayer.Character:FindFirstChild("Humanoid")
            if h then h.WalkSpeed = customSpeed end
        end
        if noclipEnabled and LocalPlayer.Character then
            for _, v in pairs(LocalPlayer.Character:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = false end end
        end
        if _G.flashbackEnabled and LocalPlayer.Character then
            local char = LocalPlayer.Character
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChildWhichIsA("Humanoid")
            if hrp and hum then
                if UserInputService:IsKeyDown(_G.flashbackKey) then
                    flashback_Revert(char, hrp, hum)
                else
                    flashback_Advance(char, hrp, hum)
                end
            end
        end
    end)
    if not s and not _G.LowHubErrored then 
        warn("[LowHub] Loop Error: " .. tostring(e)) 
        _G.LowHubErrored = true 
    end
end)

-- // Persistent Player List (Bottom)

-- Define Helper Functions EARLY so PlayerList can use them.
local activeAttachments = {} -- Manage active attachments

local function GrabSequence(target, tRoot, me, mRoot, algs, evt)
    -- // REFLECT ACTION LOGIC //
    local isOwner = GetRole(target) == "OWNER"
    local isAdmin = GetRole(target) == "ADMIN"
    
    _G.GlobalAdminReflect = _G.GlobalAdminReflect or {}
    
    local targetName = typeof(target) == "Instance" and target:IsA("Player") and target.Name or (target:IsA("Model") and game.Players:GetPlayerFromCharacter(target) and game.Players:GetPlayerFromCharacter(target).Name or target.Name)

    if (isOwner and GetRole(LocalPlayer) ~= "OWNER") or 
       (isAdmin and _G.GlobalAdminReflect[targetName] and GetRole(LocalPlayer) ~= "OWNER" and GetRole(LocalPlayer) ~= "ADMIN") then
        target = me
        tRoot = mRoot
    end

    -- Custom TP Logic:
    -- 1. TP to Target
    mRoot.CFrame = tRoot.CFrame
    task.wait(0.15)
    
    -- 2. Equip
    algs.Parent = me
    task.wait(0.10)
    
    -- 3. Fire Remote
    evt:FireServer(target, tRoot)
    task.wait(0.25)
end

local function PlayGlobalAnim(id)
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
    if hum and id then
        local anim = Instance.new("Animation")
        anim.AnimationId = "rbxassetid://" .. id
        local track = hum:LoadAnimation(anim)
        track.Priority = Enum.AnimationPriority.Action
        track:Play()
        return track
    end
end

local function AttachmentTroll(name, animId, offset, isSitting, btn, selectedPlayerFunc)
    -- This function now toggles state
    if activeAttachments[name] then
        -- STOP
        activeAttachments[name] = false
        if btn then btn.Text = name end
        
        -- Cleanup
        pcall(function()
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                local v = LocalPlayer.Character.HumanoidRootPart:FindFirstChild("TrollVelocity")
                if v then v:Destroy() end
                LocalPlayer.Character.Humanoid.Sit = false
            end
            local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
            if hum and animId then
                for _, t in pairs(hum:GetPlayingAnimationTracks()) do
                    if t.Animation.AnimationId == "rbxassetid://" .. animId then t:Stop() end
                end
            end
        end)
    else
        -- START
        activeAttachments[name] = true
        if btn then btn.Text = "Stop " .. name end
        
        if animId then PlayGlobalAnim(animId) end
        
        task.spawn(function()
            while activeAttachments[name] do
                local s, e = pcall(function()
                    -- Get current selected player from the UI context
                    local p = selectedPlayerFunc()
                    
                    if not p or not (p.Character and p.Character:FindFirstChild("HumanoidRootPart")) then 
                        activeAttachments[name] = false 
                        if btn then btn.Text = name end
                        return 
                    end
                    local targetChar = p.Character
                    local targetRoot = targetChar.HumanoidRootPart
                    local myChar = LocalPlayer.Character
                    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
                    local myHum = myChar and myChar:FindFirstChild("Humanoid")
                    
                    if targetRoot and myRoot then
                        -- Anti-Fling
                        if not myRoot:FindFirstChild("TrollVelocity") then
                            local bav = Instance.new("BodyAngularVelocity")
                            bav.Name = "TrollVelocity"
                            bav.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
                            bav.AngularVelocity = Vector3.new(0, 0, 0)
                            bav.Parent = myRoot
                        end
                        
                        if isSitting then myHum.Sit = true end
                        myRoot.CFrame = targetRoot.CFrame * offset
                        myRoot.Velocity = Vector3.new(0,0,0)
                    end
                end)
                if not s then warn("[Troll Error]: " .. tostring(e)) end
                task.wait()
            end
             -- Cleanup on exit loop
            pcall(function()
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    local v = LocalPlayer.Character.HumanoidRootPart:FindFirstChild("TrollVelocity")
                    if v then v:Destroy() end
                    LocalPlayer.Character.Humanoid.Sit = false
                end
                local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
                if hum and animId then
                    for _, t in pairs(hum:GetPlayingAnimationTracks()) do
                        if t.Animation.AnimationId == "rbxassetid://" .. animId then t:Stop() end
                    end
                end
            end)
        end)
    end
end

-- // Persistent Player List (Bottom) - Split View
local function CreatePersistentPlayerList()
    local PFrame = Instance.new("Frame")
    PFrame.Name = "PlayerList"
    PFrame.Size = UDim2.new(1, 0, 0, 240) 
    PFrame.Position = UDim2.new(0, 0, 1, 12) 
    PFrame.BackgroundColor3 = Config.BackgroundColor
    PFrame.BackgroundTransparency = 0.25
    PFrame.Active = true 
    PFrame.Parent = Window.MainFrame
    
    local PCorner = Instance.new("UICorner") PCorner.CornerRadius = Config.CornerRadius PCorner.Parent = PFrame

    -- // Left Panel (List)
    local LeftFrame = Instance.new("Frame")
    LeftFrame.Name = "LeftFrame"
    LeftFrame.Size = UDim2.new(0.6, -5, 1, -10)
    LeftFrame.Position = UDim2.new(0, 5, 0, 5)
    LeftFrame.BackgroundTransparency = 1
    LeftFrame.Parent = PFrame

    local Search = Instance.new("TextBox")
    Search.Size = UDim2.new(1, 0, 0, 30)
    Search.Position = UDim2.new(0, 0, 0, 0)
    Search.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    Search.PlaceholderText = "Search Player..."
    Search.Text = ""
    Search.TextColor3 = Config.TextColor
    Search.Font = Config.Font
    Search.TextSize = 14
    Search.Parent = LeftFrame
    local SC = Instance.new("UICorner") SC.CornerRadius = UDim.new(0, 6) SC.Parent = Search
    
    local Scroll = Instance.new("ScrollingFrame")
    Scroll.Size = UDim2.new(1, 0, 1, -35)
    Scroll.Position = UDim2.new(0, 0, 0, 35)
    Scroll.BackgroundTransparency = 1
    Scroll.BorderSizePixel = 0
    Scroll.ZIndex = 2
    Scroll.Parent = LeftFrame
    local Layout = Instance.new("UIListLayout") Layout.SortOrder = Enum.SortOrder.Name Layout.Padding = UDim.new(0, 2) Layout.Parent = Scroll

    -- // Right Panel (Details)
    local RightFrame = Instance.new("Frame")
    RightFrame.Name = "RightFrame"
    RightFrame.Size = UDim2.new(0.4, -5, 1, -10)
    RightFrame.Position = UDim2.new(0.6, 0, 0, 5)
    RightFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    RightFrame.BackgroundTransparency = 0.5
    RightFrame.Parent = PFrame
    local RCorner = Instance.new("UICorner") RCorner.CornerRadius = Config.CornerRadius RCorner.Parent = RightFrame

    -- // Sub-Containers
    -- Change PBtnContainer to ScrollingFrame
    local PBtnContainer = Instance.new("ScrollingFrame")
    PBtnContainer.Name = "ButtonContainer"
    PBtnContainer.Size = UDim2.new(0.3, -5, 1, -10) -- 30% Width
    PBtnContainer.Position = UDim2.new(0, 5, 0, 5)
    PBtnContainer.BackgroundTransparency = 1
    PBtnContainer.BorderSizePixel = 0
    PBtnContainer.ScrollBarThickness = 2
    PBtnContainer.Parent = RightFrame
    
    local PInfoContainer = Instance.new("Frame")
    PInfoContainer.Name = "InfoContainer"
    PInfoContainer.Size = UDim2.new(0.7, -5, 1, -10) -- 70% Width (More space for Avatar)
    PInfoContainer.Position = UDim2.new(0.3, 5, 0, 5)
    PInfoContainer.BackgroundTransparency = 1
    PInfoContainer.Parent = RightFrame

    -- // Buttons (Left Side)
    local BtnLayout = Instance.new("UIListLayout")
    BtnLayout.Parent = PBtnContainer
    BtnLayout.SortOrder = Enum.SortOrder.LayoutOrder
    BtnLayout.Padding = UDim.new(0, 5)
    BtnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    
    local function CreateButton(text, func)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.95, 0, 0, 25) -- Compact height
        btn.BackgroundColor3 = Config.AccentColor
        btn.Text = text
        btn.TextColor3 = Config.TextColor
        btn.Font = Config.Font
        btn.TextSize = 11 
        btn.Parent = PBtnContainer
        local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 4) c.Parent = btn
        
        -- Special styling for dangerous buttons?
        if text:find("Void") or text:find("Sacrifice") or text:find("Kill") then
             btn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
        end
        
        btn.MouseButton1Click:Connect(function() 
            pcall(PlayClick) 
            func(btn) 
        end)
        return btn
    end

    -- 1. Standard Actions
    local CopyIDBtn = CreateButton("Copy ID", function()
        if selectedPlayer then setclipboard(tostring(selectedPlayer.UserId)) end
    end)
    
    local TPBtn = CreateButton("Teleport", function()
        if selectedPlayer and selectedPlayer.Character and LocalPlayer.Character then
            local r1 = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            local r2 = selectedPlayer.Character:FindFirstChild("HumanoidRootPart")
            if r1 and r2 then 
                 local lastPos = r1.CFrame
                 r1.CFrame = r2.CFrame * CFrame.new(0, 3, 2) 
            end
        end
    end)

    local SpectateBtn = CreateButton("Spectate", function()
        if selectedPlayer and selectedPlayer.Character then
            -- // ANTI-SPECTATE CHECK //
            local isOwner = GetRole(selectedPlayer) == "OWNER"
            local isAdmin = GetRole(selectedPlayer) == "ADMIN"
            
            _G.GlobalAntiSpectate = _G.GlobalAntiSpectate or {}
            
            if (isOwner or isAdmin) and _G.GlobalAntiSpectate[selectedPlayer.Name] then
                -- Broadcast notification or just block
                return 
            end

            local cam = workspace.CurrentCamera
            local targetHum = selectedPlayer.Character:FindFirstChild("Humanoid")
            if cam.CameraSubject == targetHum then
                if LocalPlayer.Character then
                    cam.CameraSubject = LocalPlayer.Character:FindFirstChild("Humanoid")
                end
            else
                cam.CameraSubject = targetHum
            end
        end
    end)
    
    -- 2. Troll Actions (Moved from Troll Tab)
    
    CreateButton("Bring Player", function(btn)
        warn("[LowHub Debug] Bring: Clicked") 
        if not selectedPlayer or not selectedPlayer.Character then 
             warn("[LowHub Debug] Bring: No Player Selected/Char")
             return 
        end
        local target = selectedPlayer.Character
        local tRoot = target:FindFirstChild("HumanoidRootPart")
        local me = LocalPlayer.Character
        local mRoot = me and me:FindFirstChild("HumanoidRootPart")
        local algs = LocalPlayer.Backpack:FindFirstChild("Algemas") or me:FindFirstChild("Algemas")
        
        if not tRoot then warn("[LowHub Debug] Bring: Target Root Missing") return end
        if not mRoot then warn("[LowHub Debug] Bring: My Root Missing") return end
        if not algs then warn("[LowHub Debug] Bring: 'Algemas' Tool Missing") return end
        
        local evt = algs:FindFirstChild("Events") and algs.Events:FindFirstChild("CarryEvent")
        if not evt then warn("[LowHub Debug] Bring: 'CarryEvent' Missing") return end
    
        warn("[LowHub Debug] Bring: Starting GrabSequence...")
        local originalPos = mRoot.CFrame
        GrabSequence(target, tRoot, me, mRoot, algs, evt)
        mRoot.CFrame = originalPos
        task.wait(0.20)
        warn("[LowHub Debug] Bring: Done")
    end)
    
    CreateButton("Bring (Predict/Fast)", function()
        if not selectedPlayer or not selectedPlayer.Character then return end
        local target = selectedPlayer.Character
        local tRoot = target:FindFirstChild("HumanoidRootPart")
        local me = LocalPlayer.Character
        local mRoot = me and me:FindFirstChild("HumanoidRootPart")
        local algs = LocalPlayer.Backpack:FindFirstChild("Algemas") or me:FindFirstChild("Algemas")
        
        if not tRoot or not mRoot or not algs then return end
        
        -- // REFLECT ACTION LOGIC //
        if GetRole(selectedPlayer.Name) == "OWNER" and GetRole(LocalPlayer.Name) ~= "OWNER" then
            target = LocalPlayer.Character
            tRoot = mRoot
        end
    
        local evt = algs:FindFirstChild("Events") and algs.Events:FindFirstChild("CarryEvent")
        if not evt then return end
    
        local originalPos = mRoot.CFrame
        local velocity = tRoot.Velocity
        local predictedPos = tRoot.CFrame + (velocity * 0.2)
    
        mRoot.CFrame = predictedPos
        task.wait(0.1)
        algs.Parent = me
        task.wait(0.05)
        for i = 1, 5 do evt:FireServer(target, tRoot) end
        task.wait(0.2)
        mRoot.CFrame = originalPos
        task.wait(0.20)
    end)
    
    CreateButton("Bang", function(btn) 
        AttachmentTroll("Bang", "5918726674", CFrame.new(0, 0, 1.1), false, btn, function() return selectedPlayer end) 
    end)
    CreateButton("Headsit", function(btn) 
        AttachmentTroll("Headsit", nil, CFrame.new(0, 2, 0), true, btn, function() return selectedPlayer end) 
    end)
    CreateButton("Stand", function(btn) 
        AttachmentTroll("Stand", "13823324057", CFrame.new(-3, 1, 0), false, btn, function() return selectedPlayer end) 
    end)
    CreateButton("Backpack", function(btn) 
        AttachmentTroll("Backpack", nil, CFrame.new(0, 0, 1.2) * CFrame.Angles(0, math.rad(-180), 0), true, btn, function() return selectedPlayer end) 
    end)
    CreateButton("Doggy", function(btn) 
        AttachmentTroll("Doggy", "13694096724", CFrame.new(0, 0.23, 0), false, btn, function() return selectedPlayer end) 
    end)
    CreateButton("Drag", function(btn) 
        AttachmentTroll("Drag", "10714360343", CFrame.new(0, -2.5, 1) * CFrame.Angles(math.rad(-90), math.rad(-180), 0), false, btn, function() return selectedPlayer end) 
    end)
    
    CreateButton("Void", function()
        warn("[LowHub Debug] Void: Clicked") 
        if not selectedPlayer or not selectedPlayer.Character then 
             warn("[LowHub Debug] Void: No Player Selected")
             return 
        end
        local target = selectedPlayer.Character
        local tRoot = target:FindFirstChild("HumanoidRootPart")
        local me = LocalPlayer.Character
        local mRoot = me and me:FindFirstChild("HumanoidRootPart")
        local algs = LocalPlayer.Backpack:FindFirstChild("Algemas") or me:FindFirstChild("Algemas")
        
        if not tRoot then warn("[LowHub Debug] Void: Target Root Missing") return end
        if not mRoot then warn("[LowHub Debug] Void: My Root Missing") return end
        if not algs then warn("[LowHub Debug] Void: 'Algemas' Tool Missing") return end
        
        local evt = algs:FindFirstChild("Events") and algs.Events:FindFirstChild("CarryEvent")
        if not evt then warn("[LowHub Debug] Void: 'CarryEvent' Missing") return end
    
        warn("[LowHub Debug] Void: Starting Sequence...")
        local originalPos = mRoot.CFrame
        GrabSequence(target, tRoot, me, mRoot, algs, evt)
    
        local skyPos = CFrame.new(999999999999, 25000000000, 99999999999)
        mRoot.CFrame = skyPos
        task.wait(0.99)
        algs.Parent = LocalPlayer.Backpack
        task.wait(0.20)
        mRoot.CFrame = originalPos
        warn("[LowHub Debug] Void: Done")
    end)
    
    CreateButton("Sacrifice (Altar)", function()
        if not selectedPlayer or not selectedPlayer.Character then return end
        local target = selectedPlayer.Character
        local tRoot = target:FindFirstChild("HumanoidRootPart")
        local me = LocalPlayer.Character
        local mRoot = me and me:FindFirstChild("HumanoidRootPart")
        local algs = LocalPlayer.Backpack:FindFirstChild("Algemas") or me:FindFirstChild("Algemas")
        
        if not tRoot or not mRoot or not algs then return end
        
        local evt = algs:FindFirstChild("Events") and algs.Events:FindFirstChild("CarryEvent")
        if not evt then return end
        
        local originalPos = mRoot.CFrame
        GrabSequence(target, tRoot, me, mRoot, algs, evt)
        
        mRoot.CFrame = CFrame.new(465.628, 14, 491.829)
        task.wait(0.5)
        
        local q = game:GetService("ReplicatedStorage"):FindFirstChild("SacrificeQuest")
        if q and q:FindFirstChild("DeliverVictim") then q.DeliverVictim:FireServer() end
        
        task.wait(0.5)
        algs.Parent = LocalPlayer.Backpack
        mRoot.CFrame = originalPos
    end)
    
    CreateButton("Trap (Island)", function()
        if not selectedPlayer or not selectedPlayer.Character then return end
        local target = selectedPlayer.Character
        local tRoot = target:FindFirstChild("HumanoidRootPart")
        local me = LocalPlayer.Character
        local mRoot = me and me:FindFirstChild("HumanoidRootPart")
        local algs = LocalPlayer.Backpack:FindFirstChild("Algemas") or me:FindFirstChild("Algemas")
        
        if not tRoot or not mRoot or not algs then return end
        
        local evt = algs:FindFirstChild("Events") and algs.Events:FindFirstChild("CarryEvent")
        if not evt then return end
    
        local originalPos = mRoot.CFrame
        GrabSequence(target, tRoot, me, mRoot, algs, evt)
        
        mRoot.CFrame = CFrame.new(3017, 21, -341)
        task.wait(0.5)
        algs.Parent = LocalPlayer.Backpack
        task.wait(0.2)
        mRoot.CFrame = originalPos
    end)
    
    PBtnContainer.CanvasSize = UDim2.new(0, 0, 0, PBtnContainer.UIListLayout.AbsoluteContentSize.Y + 20)









    -- // Info (Right Side)
    local AvatarLarge = Instance.new("ImageLabel")
    AvatarLarge.Size = UDim2.new(0, 140, 0, 140) -- Huge Size
    AvatarLarge.Position = UDim2.new(0.5, -70, 0, 5) -- Centered
    AvatarLarge.BackgroundTransparency = 1
    AvatarLarge.Image = ""
    AvatarLarge.Parent = PInfoContainer
    local AC = Instance.new("UICorner") AC.CornerRadius = UDim.new(1, 0) AC.Parent = AvatarLarge

    local NameDetail = Instance.new("TextLabel")
    NameDetail.Size = UDim2.new(1, 0, 0, 20)
    NameDetail.Position = UDim2.new(0, 0, 0, 150) -- Below Avatar
    NameDetail.BackgroundTransparency = 1
    NameDetail.TextColor3 = Config.TextColor
    NameDetail.Font = Enum.Font.GothamBold
    NameDetail.TextSize = 15
    NameDetail.Text = "Select Player"
    NameDetail.TextScaled = true
    NameDetail.Parent = PInfoContainer

    local InfoDetail = Instance.new("TextLabel")
    InfoDetail.Size = UDim2.new(1, 0, 0, 60)
    InfoDetail.Position = UDim2.new(0, 0, 0, 170)
    InfoDetail.BackgroundTransparency = 1
    InfoDetail.TextColor3 = Config.SecondaryTextColor
    InfoDetail.Font = Config.Font
    InfoDetail.TextSize = 12
    InfoDetail.TextWrapped = true
    InfoDetail.TextYAlignment = Enum.TextYAlignment.Top
    InfoDetail.Text = ""
    InfoDetail.Parent = PInfoContainer

    -- Update Function
    local function UpdateRightPanel(p)
        if not p then return end
        AvatarLarge.Image = "rbxthumb://type=Avatar&id=" .. p.UserId .. "&w=352&h=352" -- Higher res
        NameDetail.Text = p.DisplayName
        InfoDetail.Text = "@" .. p.Name .. "\nID:\n" .. p.UserId
    end

    local playerButtons = {}
    local function Refresh(txt)
        txt = txt:lower()
        local listLayout = Scroll:FindFirstChildOfClass("UIListLayout")
        
        -- 1. Update/Add Existing Players
        for _, v in pairs(Players:GetPlayers()) do
            if v ~= LocalPlayer then
                local matches = txt == "" or v.Name:lower():find(txt) or v.DisplayName:lower():find(txt)
                
                if matches then
                    local btn = playerButtons[v]
                    if not btn then
                        -- Create New Button
                        local B = Instance.new("TextButton")
                        B.Name = v.Name
                        B.Size = UDim2.new(1, 0, 0, 40)
                        B.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                        B.BackgroundTransparency = 0.5
                        B.Text = ""
                        B.ZIndex = 3
                        B.Parent = Scroll
                        local BC = Instance.new("UICorner") BC.CornerRadius = UDim.new(0, 4) BC.Parent = B
                        
                        local Img = Instance.new("ImageLabel")
                        Img.Size = UDim2.new(0, 32, 0, 32)
                        Img.Position = UDim2.new(0, 4, 0.5, -16)
                        Img.BackgroundTransparency = 1
                        Img.Image = "rbxthumb://type=AvatarHeadShot&id=" .. v.UserId .. "&w=48&h=48"
                        Img.ZIndex = 3
                        Img.Active = false
                        Img.Parent = B
                        local IC = Instance.new("UICorner") IC.CornerRadius = UDim.new(1, 0) IC.Parent = Img
                        
                        local NameLbl = Instance.new("TextLabel")
                        NameLbl.Text = v.DisplayName
                        NameLbl.Size = UDim2.new(1, -40, 1, 0)
                        NameLbl.Position = UDim2.new(0, 40, 0, 0)
                        NameLbl.BackgroundTransparency = 1
                        NameLbl.TextColor3 = Config.TextColor
                        NameLbl.Font = Config.Font
                        NameLbl.TextSize = 13
                        NameLbl.TextXAlignment = Enum.TextXAlignment.Left
                        NameLbl.ZIndex = 3
                        NameLbl.Active = false
                        NameLbl.Parent = B
                        
                        B.MouseButton1Click:Connect(function()
                            pcall(PlayClick)
                            for _, x in pairs(playerButtons) do x.BackgroundColor3 = Color3.fromRGB(60, 60, 60) end 
                            B.BackgroundColor3 = Config.AccentColor
                            selectedPlayer = v
                            UpdateRightPanel(v)
                        end)
                        
                        playerButtons[v] = B
                        btn = B
                    end
                    btn.Visible = true
                else
                    if playerButtons[v] then playerButtons[v].Visible = false end
                end
            end
        end
        
        -- 2. Clean up Leftover Buttons (Left Players)
        for p, btn in pairs(playerButtons) do
            if not p.Parent then -- Player left
                btn:Destroy()
                playerButtons[p] = nil
            end
        end
        
        if listLayout then
             Scroll.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y)
        end
    end
    
    Search:GetPropertyChangedSignal("Text"):Connect(function() Refresh(Search.Text) end)
    Players.PlayerAdded:Connect(function() Refresh(Search.Text) end)
    Players.PlayerRemoving:Connect(function() Refresh(Search.Text) end)
    Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() Scroll.CanvasSize = UDim2.new(0, 0, 0, Layout.AbsoluteContentSize.Y) end)
    task.spawn(function() Refresh("") end)
end
CreatePersistentPlayerList()

local Visuals = Window:AddTab({Title = "Visuals", Icon = "rbxassetid://10723346959"}) -- Monitor
local Exploit = Window:AddTab({Title = "Exploit", Icon = "rbxassetid://10709782497"}) -- Home
local Teleport = Window:AddTab({Title = "Teleport", Icon = "rbxassetid://10709818763"}) -- Map/Location Icon
local Servers = Window:AddTab({Title = "Servers", Icon = "rbxassetid://10723434557"}) -- Server Icon (Network)
local Troll = Window:AddTab({Title = "Troll", Icon = "rbxassetid://10723415903"}) -- Skull
local Owner = nil
if GetRole(LocalPlayer.Name) == "OWNER" then
    Owner = Window:AddTab({Title = "Owner", Icon = "rbxassetid://10709812675"}) -- Crown
end
local Admin = nil
if GetRole(LocalPlayer.Name) == "ADMIN" then
    Admin = Window:AddTab({Title = "Admin", Icon = "rbxassetid://10723415903"}) -- Shield/Badge
end


-- // SNIPER TAB //
local Sniper = Window:AddTab({Title = "Sniper", Icon = "rbxassetid://10723346959"})
local sniperUsername = ""
local sniperPlaceId = tostring(game.PlaceId)
local isSniping = false
local sniperStatus = Sniper:AddLabel("Status: Idle")

local function resolveUser(input, http_req)
    local HttpService = game:GetService("HttpService")
    local asNumber = tonumber(input)
    if asNumber then
        local result = http_req({Url = "https://users.roblox.com/v1/users/"..asNumber, Method = "GET"})
        if result and result.StatusCode == 200 then
            local data = HttpService:JSONDecode(result.Body)
            return data.name, asNumber
        end
    end
    local payload = HttpService:JSONEncode({usernames = { input }, excludeBannedUsers = false})
    local result = http_req({
        Url = "https://users.roblox.com/v1/usernames/users",
        Method = "POST",
        Headers = {["Content-Type"] = "application/json"},
        Body = payload
    })
    if result and result.StatusCode == 200 then
        local data = HttpService:JSONDecode(result.Body)
        if data.data and data.data[1] then
            return data.data[1].name, data.data[1].id
        end
    end
    return nil, nil
end

local function fetchThumbs(tokens, http_req)
    local HttpService = game:GetService("HttpService")
    local payload = {}
    for _, token in ipairs(tokens) do
        table.insert(payload, {
            requestId = "0:".. token ..":AvatarHeadshot:150x150:png:regular",
            type = "AvatarHeadShot",
            targetId = 0,
            token = token,
            format = "png",
            size = "150x150"
        })
    end
    local result = http_req({
        Url = "https://thumbnails.roblox.com/v1/batch",
        Method = "POST",
        Headers = {["Content-Type"] = "application/json"},
        Body = HttpService:JSONEncode(payload)
    })
    if result and result.StatusCode == 200 then
        local data = HttpService:JSONDecode(result.Body)
        return true, data.data
    end
    return false, nil
end

Sniper:AddTextBox("Target User", function(v) sniperUsername = v end)
Sniper:AddTextBox("Place ID", function(v) sniperPlaceId = v end).Set(tostring(game.PlaceId))

local sniperBtn
sniperBtn = Sniper:AddButton("Start Sniper", function()
    if isSniping then
        isSniping = false
        sniperBtn.SetText("Start Sniper")
        sniperStatus.SetText("Status: Stopped")
        return
    end
    if sniperUsername == "" then sniperStatus.SetText("Status: Invalid User") return end
    
    isSniping = true
    sniperBtn.SetText("Stop Sniper")
    sniperStatus.SetText("Status: Booting...")
    
    task.spawn(function()
        local http_req = request or http_request or (syn and syn.request) or (http and http.request) or (fluxus and fluxus.request)
        if not http_req then 
            sniperStatus.SetText("Status: No HTTP Support")
            isSniping = false
            sniperBtn.SetText("Start Sniper")
            return 
        end
        
        local name, id = resolveUser(sniperUsername, http_req)
        if not id then
            sniperStatus.SetText("Status: User Not Found")
            isSniping = false
            sniperBtn.SetText("Start Sniper")
            return
        end
        
        sniperStatus.SetText("Status: Fetching Thumb...")
        local thumbRes = http_req({Url = "https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=" .. id .. "&format=Png&size=150x150&isCircular=false", Method = "GET"})
        local targetThumb = nil
        if thumbRes and thumbRes.StatusCode == 200 then
            local data = game:GetService("HttpService"):JSONDecode(thumbRes.Body)
            targetThumb = data.data[1].imageUrl
        end
        
        if not targetThumb then
            sniperStatus.SetText("Status: Thumb Error")
            isSniping = false
            sniperBtn.SetText("Start Sniper")
            return
        end
        
        local place = tonumber(sniperPlaceId) or game.PlaceId
        local cursor = nil
        local scanned = 0
        
        while isSniping do
            sniperStatus.SetText("Status: Fetching Servers...")
            local url = "https://games.roblox.com/v1/games/".. place .."/servers/Public?limit=100"
            if cursor then url = url .. "&cursor=" .. cursor end
            
            local srvRes = http_req({Url = url, Method = "GET"})
            if srvRes and srvRes.StatusCode == 200 then
                local srvData = game:GetService("HttpService"):JSONDecode(srvRes.Body)
                cursor = srvData.nextPageCursor
                
                for _, server in ipairs(srvData.data) do
                    if not isSniping then break end
                    scanned = scanned + 1
                    sniperStatus.SetText("Status: Scanning ("..scanned..")")
                    
                    local ok, thumbs = fetchThumbs(server.playerTokens, http_req)
                    if ok then
                        for _, pThumb in ipairs(thumbs) do
                            if pThumb.imageUrl == targetThumb then
                                sniperStatus.SetText("Status: FOUND! Teleporting...")
                                game:GetService("TeleportService"):TeleportToPlaceInstance(place, server.id)
                                isSniping = false
                                sniperBtn.SetText("Start Sniper")
                                return
                            end
                        end
                    end
                end
            end
            if not cursor or not isSniping then break end
            task.wait(1)
        end
        
        sniperStatus.SetText("Status: Finished / Not Found")
        isSniping = false
        sniperBtn.SetText("Start Sniper")
    end)
end)

local Settings = Window:AddTab({Title = "Settings", Icon = "rbxassetid://10734950309"}) -- Gear

-- Visuals
-- Visuals:AddSection("Target List (Spectate)") -- Removed as requested
-- Visuals:AddPlayerList(function(p) selectedPlayer = p end) -- MOVED TO BOTTOM CONTAINER

-- Visuals:AddSection("ESP") -- Removed as requested
local espToggle = Visuals:AddToggle("Enable ESP", false, function(v) 
    espEnabled = v 
    if not v then updateESP() end 
end)

Visuals:AddToggle("Hide @User (Clean Names)", false, function(v)
    _G.ESPHideUser = v
    -- Force Update Text
    for _, bb in pairs(espBillboards) do
        local txt = bb:FindFirstChild("ESPText")
        local p = game:GetService("Players"):GetPlayerFromCharacter(bb.Adornee.Parent)
        if txt and p then
             if _G.ESPHideName then
                 txt.Text = " "
             else
                 txt.Text = v and p.DisplayName or (p.DisplayName .. " (@" .. p.Name .. ")")
             end
        end
    end
end)

Visuals:AddToggle("Hide Name (Only ESP)", false, function(v)
    _G.ESPHideName = v
     -- Force Update Text
    for _, bb in pairs(espBillboards) do
        local txt = bb:FindFirstChild("ESPText")
        local p = game:GetService("Players"):GetPlayerFromCharacter(bb.Adornee.Parent)
        if txt and p then
             if v then
                 txt.Text = " "
             else
                 txt.Text = _G.ESPHideUser and p.DisplayName or (p.DisplayName .. " (@" .. p.Name .. ")")
             end
        end
    end
end)

Visuals:AddToggle("Hide Icon (No Avatar)", false, function(v)
    _G.ESPHideIcon = v
    if v then
        for _, ic in pairs(espIcons) do pcall(function() ic:Destroy() end) end
        espIcons = {} -- Clear Cache
    else
        -- Will respawn next loop
    end
end)

Visuals:AddToggle("Hide Dots (Red Center)", false, function(v)
    _G.ESPHideDots = v
    if v then
         for _, dot in pairs(espRedDots) do pcall(function() dot:Destroy() end) end
         espRedDots = {} -- Clear Cache
    end
end)

Visuals:AddToggle("RGB Outline (Rainbow)", false, function(v)
    _G.ESPOutlineRGB = v
end)

Visuals:AddSection("Outline Color")
Visuals:AddSlider("Red", {Min=0, Max=255, Default=255}, function(v) 
    _G.ESP_R = v 
    _G.ESPOutlineColor = Color3.fromRGB(_G.ESP_R, _G.ESP_G, _G.ESP_B)
end)
Visuals:AddSlider("Green", {Min=0, Max=255, Default=255}, function(v) 
    _G.ESP_G = v 
    _G.ESPOutlineColor = Color3.fromRGB(_G.ESP_R, _G.ESP_G, _G.ESP_B)
end)
Visuals:AddSlider("Blue", {Min=0, Max=255, Default=255}, function(v) 
    _G.ESP_B = v 
    _G.ESPOutlineColor = Color3.fromRGB(_G.ESP_R, _G.ESP_G, _G.ESP_B)
end)

Visuals:AddToggle("Spectate Selected", false, function(v)
    spectateEnabled = v
    if not v then
        local c = workspace.CurrentCamera
        if LocalPlayer.Character then c.CameraSubject = LocalPlayer.Character:FindFirstChild("Humanoid") end
    end
end)

-- Removed Shaders from Visuals (Moved to Graphics)
-- Exploit
-- Exploit:AddSection("Auto Farm") -- Removed as requested
local autoFarmToggle = Exploit:AddToggle("Enable Auto Farm", false, function(v)
    autoFarmEnabled = v
    if v then
        task.spawn(function()
            local cache = {}
            local idx = 1
            while autoFarmEnabled do
                if not (Window and Window.Instance and Window.Instance.Parent) then break end
                if flying then task.wait(0.5) continue end
                local char = LocalPlayer.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                if root then
                    if #cache == 0 then for _,obj in pairs(workspace:GetDescendants()) do if obj:IsA("SpawnLocation") then table.insert(cache, obj) end end end
                    local lights = workspace:FindFirstChild("LightsLocal")
                    local found = false
                    if lights then
                        for _,l in pairs(lights:GetChildren()) do
                            if l.Name == "LightTemplate" and l:FindFirstChild("part") then
                                root.CFrame = l.part.CFrame
                                root.Velocity = Vector3.zero
                                found = true
                                task.wait(0.1)
                                break
                            end
                        end
                    end
                    if not found and #cache > 0 then
                        idx = idx + 1
                        if idx > #cache then idx = 1 end
                        if cache[idx] then root.CFrame = cache[idx].CFrame * CFrame.new(0,5,0) end
                        task.wait(0.5)
                    end
                end
                task.wait(0.05)
            end
        end)
    end
end)


local flying = false
local deb = true
local ctrl = {f = 0, b = 0, l = 0, r = 0}
local lastctrl = {f = 0, b = 0, l = 0, r = 0}
local KeyDownFunction = nil
local KeyUpFunction = nil
local flySpeed = 50

local function PlayAnim(id,time,speed)
	pcall(function()
        local plr = game.Players.LocalPlayer
		plr.Character.Animate.Disabled = false
		local hum = plr.Character.Humanoid
		local animtrack = hum:GetPlayingAnimationTracks()
		for i,track in pairs(animtrack) do
			track:Stop()
		end
		plr.Character.Animate.Disabled = true
		local Anim = Instance.new("Animation")
		Anim.AnimationId = "rbxassetid://"..id
		local loadanim = hum:LoadAnimation(Anim)
		loadanim:Play()
		loadanim.TimePosition = time
		loadanim:AdjustSpeed(speed)
		loadanim.Stopped:Connect(function()
			plr.Character.Animate.Disabled = false
			for i, track in pairs (animtrack) do
        		track:Stop()
    		end
		end)
	end)
end

local function StopAnim()
    local plr = game.Players.LocalPlayer
	plr.Character.Animate.Disabled = false
    local animtrack = plr.Character.Humanoid:GetPlayingAnimationTracks()
    for i, track in pairs (animtrack) do
        track:Stop()
    end
end

local flyToggle = Exploit:AddToggle("Fly", false, function(v)
    flying = v
    local plr = game.Players.LocalPlayer
    local mouse = plr:GetMouse()
    local char = plr.Character
    local root = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso"))

    if flying and char and root then
        -- // PATCH: ISOLATION GUARDS //
        if _G.antiJokerLoop then _G.antiJokerLoop:Disconnect() _G.antiJokerLoop = nil end
        _G.antiJoker = false
        if antiJokerToggle then antiJokerToggle.Set(false) end
        autoQTEEnabled = false
        if autoQEToggle then autoQEToggle.Set(false) end
        
        -- // NUKE //
        for _, c in pairs(root:GetChildren()) do
             if c:IsA("BodyGyro") or c:IsA("BodyVelocity") or c:IsA("BodyPosition") then c:Destroy() end
        end

        local bg = Instance.new("BodyGyro", root)
        bg.Name = "FlyGyro"
        bg.P = 9e4
        bg.maxTorque = Vector3.new(9e9, 9e9, 9e9)
        bg.cframe = root.CFrame
        
        local bv = Instance.new("BodyVelocity", root)
        bv.Name = "FlyVelocity"
        bv.velocity = Vector3.new(0,0.1,0)
        bv.maxForce = Vector3.new(9e9, 9e9, 9e9)
        
        local speed = 0
        PlayAnim(10714347256,4,0) -- Idle

        if KeyDownFunction then KeyDownFunction:Disconnect() end
        KeyDownFunction = mouse.KeyDown:connect(function(key)
            if key:lower() == "w" then
                ctrl.f = 1
                PlayAnim(10714177846,4.65,0)
            elseif key:lower() == "s" then
                ctrl.b = -1
                PlayAnim(10147823318,4.11,0)
            elseif key:lower() == "a" then
                ctrl.l = -1
                PlayAnim(10147823318,3.55,0)
            elseif key:lower() == "d" then
                ctrl.r = 1
                PlayAnim(10147823318,4.81,0)
            end
        end)

        if KeyUpFunction then KeyUpFunction:Disconnect() end
        KeyUpFunction = mouse.KeyUp:connect(function(key)
            if key:lower() == "w" then
                ctrl.f = 0
                PlayAnim(10714347256,4,0)
            elseif key:lower() == "s" then
                ctrl.b = 0
                PlayAnim(10714347256,4,0)
            elseif key:lower() == "a" then
                ctrl.l = 0
                PlayAnim(10714347256,4,0)
            elseif key:lower() == "d" then
                ctrl.r = 0
                PlayAnim(10714347256,4,0)
            end
        end)
        
        task.spawn(function()
            repeat task.wait()
                if not flying or not char.Parent then break end
                char.Humanoid.PlatformStand = true
                
                if ctrl.l + ctrl.r ~= 0 or ctrl.f + ctrl.b ~= 0 then
                    speed = speed + flySpeed * 0.10
                    if speed > flySpeed then speed = flySpeed end
                elseif not (ctrl.l + ctrl.r ~= 0 or ctrl.f + ctrl.b ~= 0) and speed ~= 0 then
                    speed = speed - flySpeed * 0.10
                    if speed < 0 then speed = 0 end
                end
                
                local camCF = workspace.CurrentCamera.CoordinateFrame
                if (ctrl.l + ctrl.r) ~= 0 or (ctrl.f + ctrl.b) ~= 0 then
                    bv.velocity = ((camCF.lookVector * (ctrl.f+ctrl.b)) + ((camCF * CFrame.new(ctrl.l+ctrl.r,(ctrl.f+ctrl.b)*.2,0).p) - camCF.p))*speed
                    lastctrl = {f = ctrl.f, b = ctrl.b, l = ctrl.l, r = ctrl.r}
                elseif (ctrl.l + ctrl.r) == 0 and (ctrl.f + ctrl.b) == 0 and speed ~= 0 then
                    bv.velocity = ((camCF.lookVector * (lastctrl.f+lastctrl.b)) + ((camCF * CFrame.new(lastctrl.l+lastctrl.r,(lastctrl.f+lastctrl.b)*.2,0).p) - camCF.p))*speed
                else
                    bv.velocity = Vector3.new(0,0.1,0)
                end
                
                bg.cframe = camCF * CFrame.Angles(-math.rad((ctrl.f+ctrl.b)*50*speed/flySpeed),0,0)
            until not flying
            
            ctrl = {f = 0, b = 0, l = 0, r = 0}
            lastctrl = {f = 0, b = 0, l = 0, r = 0}
            speed = 0
            if bg then bg:Destroy() end
            if bv then bv:Destroy() end
            if char:FindFirstChild("Humanoid") then
                char.Humanoid.PlatformStand = false
            end
            StopAnim()
        end)
    else
        flying = false
        if KeyDownFunction then KeyDownFunction:Disconnect() end
        if KeyUpFunction then KeyUpFunction:Disconnect() end
        StopAnim()
        
        -- Cleanup ensure
        if char and root then 
             for _, c in pairs(root:GetChildren()) do
                 if c.Name == "FlyGyro" or c.Name == "FlyVelocity" then c:Destroy() end
             end
             if char:FindFirstChild("Humanoid") then 
                 char.Humanoid.PlatformStand = false 
                 char.Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
             end
             root.Velocity = Vector3.zero
             root.RotVelocity = Vector3.zero
             local rx, ry, rz = root.CFrame:ToOrientation()
             root.CFrame = CFrame.new(root.Position) * CFrame.fromOrientation(0, ry, 0)
        end
    end
end, Enum.KeyCode.F)

local flySpeedSlider = Exploit:AddSlider("Fly Speed", {Min = 10, Max = 1000, Default = 50}, function(v) flySpeed = v end)

-- Fly V2 (Infinite Style)
local flyV2Toggle = Exploit:AddToggle("Fly V2", false, function(v) 
    flyV2Enabled = v
    if not v and LocalPlayer.Character then
        local h = LocalPlayer.Character:FindFirstChild("Humanoid")
        local r = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if h then h.PlatformStand = false h:ChangeState(Enum.HumanoidStateType.GettingUp) end
        if r then 
            r.Anchored = false 
            r.Velocity = Vector3.zero 
            r.RotVelocity = Vector3.zero 
        end
    end
end)
local flyV2Slider = Exploit:AddSlider("Fly V2 Speed", {Min = 10, Max = 1000, Default = 50}, function(v) flyV2Speed = v end)
local noclipToggle = Exploit:AddToggle("Noclip", false, function(v) noclipEnabled = v end, Enum.KeyCode.N)
local speedToggle = Exploit:AddToggle("Speed Bypass", false, function(v) 
    speedEnabled = v 
    if not v and LocalPlayer.Character then
        local h = LocalPlayer.Character:FindFirstChild("Humanoid")
        if h then h.WalkSpeed = 16 end
    end
end, Enum.KeyCode.V)
local speedSlider = Exploit:AddSlider("Speed Amount", {Min = 16, Max = 200, Default = 16}, function(v) customSpeed = v end)

local superJumpToggle = Exploit:AddToggle("Super Jump", false, function(v) 
    superJumpEnabled = v
    if not v and LocalPlayer.Character then
         local h = LocalPlayer.Character:FindFirstChild("Humanoid")
         if h then h.UseJumpPower = true h.JumpPower = 50 end
    end
end)
local superJumpSlider = Exploit:AddSlider("Jump Height", {Min = 50, Max = 1000, Default = 50}, function(v) superJumpHeight = v end)

Exploit:AddSection("Reverse (Flashback)")
Exploit:AddToggle("Enable Reverse", false, function(v) _G.flashbackEnabled = v end, nil, true)
Exploit:AddBind("Reverse Key", Enum.KeyCode.E, function(k) if k then _G.flashbackKey = k end end)
Exploit:AddSlider("Reverse Length", {Min = 10, Max = 300, Default = 60}, function(v) _G.flashbackLength = v end)
Exploit:AddSlider("Reverse Speed", {Min = 1, Max = 5, Default = 1}, function(v) _G.flashbackSpeed = v end)


local antiFlingToggle = Exploit:AddToggle("Anti-Fling", false, function(v)
    _G.antiFling = v
    if v then
        task.spawn(function()
            while _G.antiFling do
                pcall(function()
                    for _, player in pairs(game:GetService("Players"):GetPlayers()) do
                        if player ~= LocalPlayer and player.Character then
                            local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                            local otherRoot = player.Character:FindFirstChild("HumanoidRootPart")
                            
                            if myRoot and otherRoot then
                                if (otherRoot.Position - myRoot.Position).Magnitude < 10 then
                                    -- Collision Disable (Noclip vs Player)
                                    for _, part in pairs(player.Character:GetChildren()) do
                                        if part:IsA("BasePart") then
                                            part.CanCollide = false
                                            if part.AssemblyLinearVelocity.Magnitude > 100 or part.AssemblyAngularVelocity.Magnitude > 100 then
                                                 part.AssemblyLinearVelocity = Vector3.zero
                                                 part.AssemblyAngularVelocity = Vector3.zero
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end)
                task.wait(0.1)
            end
        end)
    end
end)

local infJumpToggle = Exploit:AddToggle("Infinite Jump", false, function(v)
    _G.infJump = v
    if not _G.infJumpConn then
        _G.infJumpConn = game:GetService("UserInputService").JumpRequest:Connect(function()
            if _G.infJump and LocalPlayer.Character then
                LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")
            end
        end)
    end
end)

local antiAfkToggle = Exploit:AddToggle("Anti-AFK", false, function(v)
    _G.antiAfk = v
    if not _G.antiAfkConn then
        _G.antiAfkConn = LocalPlayer.Idled:Connect(function()
            if _G.antiAfk then
                game:GetService("VirtualUser"):CaptureController()
                game:GetService("VirtualUser"):ClickButton2(Vector2.zero)
            end
        end)
    end
end)

local clickTpInstance
local clickTpToggle = Exploit:AddToggle("Click TP Tool", false, function(v)
    if v then
        local function giveTool()
            if clickTpInstance then clickTpInstance:Destroy() end
            clickTpInstance = Instance.new("Tool")
            clickTpInstance.Name = "Click TP"
            clickTpInstance.RequiresHandle = false
            
            clickTpInstance.Equipped:Connect(function(mouse)
                mouse.Button1Down:Connect(function()
                    if flying then return end
                    if LocalPlayer.Character and mouse.Target then
                         LocalPlayer.Character:PivotTo(CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0)))
                    end
                end)
            end)

            clickTpInstance.Parent = LocalPlayer.Backpack
        end
        giveTool()
        if _G.clickTpRespawn then _G.clickTpRespawn:Disconnect() end
        _G.clickTpRespawn = LocalPlayer.CharacterAdded:Connect(function()
            task.wait(1)
            if v then giveTool() end
        end)
    else
        if clickTpInstance then clickTpInstance:Destroy() clickTpInstance = nil end
        if _G.clickTpRespawn then _G.clickTpRespawn:Disconnect() end
    end
end)

-- Spinbot
local spinSpeed = 50
local spinEnabled = false
local bav = nil

local bg = nil
local function UpdateSpin()
    if flying then return end
    if not LocalPlayer.Character then return end
    local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    if spinEnabled then
        -- Angular Velocity (The Spin)
        local existingBav = root:FindFirstChild("SpinbotForce")
        if not existingBav then
            bav = Instance.new("BodyAngularVelocity")
            bav.Name = "SpinbotForce"
            bav.Parent = root
        else
            bav = existingBav
        end
        bav.MaxTorque = Vector3.new(0, math.huge, 0) -- Spin Y only
        bav.AngularVelocity = Vector3.new(0, spinSpeed, 0)
        
        -- Gyro (The Balance)
        local existingBg = root:FindFirstChild("SpinbotGyro")
        if not existingBg then
            bg = Instance.new("BodyGyro")
            bg.Name = "SpinbotGyro"
            bg.Parent = root
        else
            bg = existingBg
        end
        bg.MaxTorque = Vector3.new(math.huge, 0, math.huge) -- Stabilize X/Z
        bg.P = 10000
        bg.D = 100
        bg.CFrame = CFrame.new(0,0,0)
    else
        -- Cleanup
        local existingBav = root:FindFirstChild("SpinbotForce")
        if existingBav then existingBav:Destroy() end
        local existingBg = root:FindFirstChild("SpinbotGyro")
        if existingBg then existingBg:Destroy() end
    end
end

local spinToggle = Exploit:AddToggle("Spinbot", false, function(v)
    spinEnabled = v
    UpdateSpin()
    if v then
        if _G.spinRespawn then _G.spinRespawn:Disconnect() end
        _G.spinRespawn = LocalPlayer.CharacterAdded:Connect(function()
             task.wait(1)
             if spinEnabled then UpdateSpin() end
        end)
    else
        if _G.spinRespawn then _G.spinRespawn:Disconnect() end
    end
end)
Exploit:AddSlider("Spin Speed", {Min = 1, Max = 1000, Default = 50}, function(v) 
    spinSpeed = v 
    if spinEnabled then UpdateSpin() end 
end)



Exploit:AddButton("Reset (Re-pos)", function()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChild("Humanoid")
    
    if root and hum then
        local savedPos = root.CFrame
        
        -- Kill
        char:BreakJoints()
        
        -- Wait for Respawn
        local newChar = LocalPlayer.CharacterAdded:Wait()
        local newRoot = newChar:WaitForChild("HumanoidRootPart", 10)
        
        if newRoot then
             task.wait(0.5)
             newRoot.CFrame = savedPos
        end
    end
end)

local autoQTEEnabled = false
local releaseRemoteName = "GqXlbcUUl6SJxctAYwVNyFT4N0w=" 
local progressRemoteName = "pwollAc71m24khiMUi/kPP+00po="
local VirtualInputManager = game:GetService("VirtualInputManager")

local autoQEToggle = Exploit:AddToggle("Auto QTE (Specific)", false, function(v)
    autoQTEEnabled = v
    if v then
        if flying and flyToggle then flyToggle.Set(false) end
        task.spawn(function()
            local rs = game:GetService("ReplicatedStorage")
            local packages = rs:WaitForChild("Packages", 5)
            local remotes = packages and packages:WaitForChild("Remotes", 5)

            if not remotes then
                print("Error: Remotes folder not found!")
                return
            end

            local releaseRemote = remotes:WaitForChild(releaseRemoteName, 5)
            local progressRemote = remotes:WaitForChild(progressRemoteName, 5)

            local remotesFired = false

            while autoQTEEnabled do
                local char = LocalPlayer.Character
                local hum = char and char:FindFirstChild("Humanoid")

                -- Check both PlatformStand (Cuffed) and Sit
                local isCuffed = hum and (hum.PlatformStand or hum.Sit)

                if isCuffed then
                    -- 1. Continuous Key Spam (Visuals / Start QTE)
                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.A, false, game)
                    task.wait() 
                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.A, false, game)

                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.D, false, game)
                    task.wait()
                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.D, false, game)

                    -- 2. Fire Remotes ONCE per cuff session (Safety)
                    if not remotesFired then
                        remotesFired = true
                        task.spawn(function()
                            task.wait(0.5) -- Wait for QTE register

                            if progressRemote then
                                for i = 10, 40, 10 do
                                    if not (hum and (hum.PlatformStand or hum.Sit)) then break end
                                    progressRemote:FireServer(i)
                                    task.wait(0.25)
                                end
                            end

                            if releaseRemote then
                                for _ = 1, 5 do
                                     if not (hum and (hum.PlatformStand or hum.Sit)) then break end
                                     releaseRemote:FireServer()
                                     task.wait(0.1)
                                end
                            end
                        end)
                    end
                else
                    remotesFired = false -- Reset when free
                end

                task.wait(0.1)
            end
        end)
    end
end)
local antiJokerToggle = Exploit:AddToggle("Anti-Joker (Bypass)", false, function(v)
    _G.antiJoker = v
    
    if v then
        -- 1. Velocity Lock (Anti-Knockback)
        -- Uses Stepped to override physics BEFORE they happen.
        if not _G.antiJokerLoop then
             _G.antiJokerLoop = game:GetService("RunService").Stepped:Connect(function()
                if flying then return end
                if not _G.antiJoker then 
                    if _G.antiJokerLoop then _G.antiJokerLoop:Disconnect() _G.antiJokerLoop = nil end
                    return 
                end
                
                if LocalPlayer.Character then
                    local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
                    
                    if hrp and hum then
                        -- FORCE velocity to match movement input (Ignores push forces)
                        local moveDir = hum.MoveDirection
                        local speed = hum.WalkSpeed
                        
                        -- Keep Y velocity (gravity), Override X/Z
                        -- But if Y is absurdly high (fling), clamp it too
                        local yVel = hrp.AssemblyLinearVelocity.Y
                        
                        -- FIX: Increased threshold to 250 to prevent normal jumps (50-100) from being flagged.
                        -- Only clamps REAL flings.
                        
                        if math.abs(yVel) > 250 then yVel = 0 end -- Anti-Fling Y Cap (Revised)
                        
                        -- Enforce X/Z Speed, Preserve Y
                        hrp.AssemblyLinearVelocity = Vector3.new(moveDir.X * speed, yVel, moveDir.Z * speed)
                        hrp.RotVelocity = Vector3.new(0,0,0) -- No spinning
                        
                        -- Prevent Trip states
                        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
                        hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
                    end
                end
            end)
        end
        
        -- 2. Destroy Joker Tool (Event Based)
        local function check(c)
            if c:IsA("Model") and c ~= LocalPlayer.Character then
                 local t = c:FindFirstChild("Joker")
                 if t then t:Destroy() end
                 c.ChildAdded:Connect(function(child)
                     if child.Name == "Joker" then 
                         task.wait() 
                         child:Destroy() 
                     end
                 end)
            end
        end
        
        for _, p in pairs(game:GetService("Players"):GetPlayers()) do
            if p.Character then check(p.Character) end
            p.CharacterAdded:Connect(check)
        end
        _G.antiJokerAdded = game:GetService("Players").PlayerAdded:Connect(function(p)
            p.CharacterAdded:Connect(check)
        end)
    else
        -- Cleanup
        if _G.antiJokerLoop then _G.antiJokerLoop:Disconnect() _G.antiJokerLoop = nil end
        if _G.antiJokerAdded then _G.antiJokerAdded:Disconnect() _G.antiJokerAdded = nil end
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
             LocalPlayer.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
             LocalPlayer.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
        end
    end
end)

Teleport:AddSection("Principais")
local lastPos = nil
local function SafeTP(cframe)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        lastPos = LocalPlayer.Character.HumanoidRootPart.CFrame
        LocalPlayer.Character:PivotTo(cframe)
    end
end

Teleport:AddButton("Return (Last Pos)", function()
    if lastPos and LocalPlayer.Character then
        LocalPlayer.Character:PivotTo(lastPos)
    end
end)

Teleport:AddButton("Teleport to Player", function()
    if not selectedPlayer or not selectedPlayer.Character then return end
    local root = selectedPlayer.Character:FindFirstChild("HumanoidRootPart")
    if root and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
         lastPos = LocalPlayer.Character.HumanoidRootPart.CFrame
         LocalPlayer.Character.HumanoidRootPart.CFrame = root.CFrame * CFrame.new(0,0,2)
    end
end)

Teleport:AddButton("Céu", function() SafeTP(CFrame.new(21, 341, 645)) end)
Teleport:AddButton("Sacrificio", function() SafeTP(CFrame.new(466, 15, 491)) end)
Teleport:AddButton("Ilha Longe", function() SafeTP(CFrame.new(3004, 16, -358)) end)
Teleport:AddButton("Ponte", function() SafeTP(CFrame.new(104, 3, 814)) end)
Teleport:AddButton("Neve", function() SafeTP(CFrame.new(1374, 24, -1906)) end)

Teleport:AddSection("BAU")
Teleport:AddButton("Bau 1", function() SafeTP(CFrame.new(-238, 9, 938)) end)
Teleport:AddButton("Bau 2", function() SafeTP(CFrame.new(-230, -4, 769)) end)
Teleport:AddButton("Bau 3", function() SafeTP(CFrame.new(-495, 1, 739)) end)
Teleport:AddButton("Bau 4", function() SafeTP(CFrame.new(-789, 21, 14)) end)
Teleport:AddButton("Bau 5", function() SafeTP(CFrame.new(-692, 13, -301)) end)
Teleport:AddButton("Bau 6", function() SafeTP(CFrame.new(7, 3, -197)) end)
Teleport:AddButton("Bau 7", function() SafeTP(CFrame.new(130, 3, -210)) end)
Teleport:AddButton("Bau 8", function() SafeTP(CFrame.new(379, 3, -203)) end)
Teleport:AddButton("Bau 9", function() SafeTP(CFrame.new(540, 15, -66)) end)
Teleport:AddButton("Bau 10", function() SafeTP(CFrame.new(-13, 3, 846)) end)

Teleport:AddSection("OSSOS")
Teleport:AddButton("Osso 1", function() SafeTP(CFrame.new(439, 4, 779)) end)
Teleport:AddButton("Osso 2", function() SafeTP(CFrame.new(517, 8, 424)) end)
Teleport:AddButton("Osso 3", function() SafeTP(CFrame.new(489, 21, 291)) end)
Teleport:AddButton("Osso 4", function() SafeTP(CFrame.new(353, 25, -223)) end)
Teleport:AddButton("Osso 5", function() SafeTP(CFrame.new(-262, 2, 8)) end)
Teleport:AddButton("Osso 6", function() SafeTP(CFrame.new(-352, 16, -294)) end)
Teleport:AddButton("Osso 7", function() SafeTP(CFrame.new(-726, 9, -259)) end)
Teleport:AddButton("Osso 8", function() SafeTP(CFrame.new(-563, -11, -23)) end)
Teleport:AddButton("Osso 9", function() SafeTP(CFrame.new(-788, 15, 217)) end)
Teleport:AddButton("Osso 10", function() SafeTP(CFrame.new(-582, 9, 566)) end)



-- Troll
-- Old Troll Tab Logic Removed (Moved to PlayerList)


local function http_get(u)
    if request then
        local s, r = pcall(function() 
            return request({Url = u, Method = "GET"}) 
        end)
        if s and r and r.Body then return r.Body end
    end
    return game:HttpGet(u)
end

-- Troll
Troll:AddSection("Actions")
Troll:AddBind("Spin Troll (Fling)", Enum.KeyCode.V, function()
    local me = LocalPlayer.Character
    local root = me and me:FindFirstChild("HumanoidRootPart")
    local hum = me and me:FindFirstChild("Humanoid")
    
    if not root or not hum then return end
    
    -- 1. Start Spin (Speed 238)
    local spinVal = 238
    
    local bav = Instance.new("BodyAngularVelocity")
    bav.Name = "SpinTrollVel"
    bav.MaxTorque = Vector3.new(0, math.huge, 0)
    bav.AngularVelocity = Vector3.new(0, spinVal, 0)
    bav.Parent = root
    
    local bg = Instance.new("BodyGyro")
    bg.Name = "SpinTrollGyro"
    bg.MaxTorque = Vector3.new(math.huge, 0, math.huge)
    bg.P = 10000
    bg.D = 100
    bg.CFrame = root.CFrame
    bg.Parent = root

    -- 2. Wait (Spin Up)
    task.wait(0.5)
    
    -- 3. Release (Unequip Tool)
    -- This assumes user is holding the person with cuffs
    hum:UnequipTools()
    
    -- 4. Wait for Fling
    task.wait(1.5)
    
    -- 5. Cleanup
    bav:Destroy()
    bg:Destroy()
    root.RotVelocity = Vector3.new(0,0,0)
end)

-- // SERVER BROWSER LOGIC //
local function RefreshServers(container)
    -- Clear Old
    for _, v in pairs(container:GetChildren()) do if v:IsA("Frame") then v:Destroy() end end
    
    local txt = container.Parent:FindFirstChild("StatusText")
    if txt then txt.Text = "Status: Fetching..." end

    task.spawn(function()
        local placeId = game.PlaceId
        local urls = {
            "https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Desc&limit=100&excludeFullGames=true",
            "https://games.roproxy.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Desc&limit=100&excludeFullGames=true"
        }
        
        local data = nil
        local errInfo = ""

        for _, u in ipairs(urls) do
            if txt then txt.Text = "Status: Trying API " .. _ .. "..." end
            local success, result = pcall(function() return http_get(u) end)
            
            if success and result then
                local s, d = pcall(function() return game:GetService("HttpService"):JSONDecode(result) end)
                if s and d and d.data then
                    data = d
                    break -- Found valid data
                else
                    errInfo = errInfo .. " [JSON Error: " .. tostring(s) .. " Body: " .. tostring(result):sub(1,50) .. "]"
                end
            else
                errInfo = errInfo .. " [HTTP Error: " .. tostring(result) .. "]"
            end
            task.wait(0.5)
        end
        
        if data and data.data then
            if txt then txt.Text = "Found " .. #data.data .. " servers." end
            
            local foundCount = 0
            for _, server in pairs(data.data) do
                if server.playing and server.maxPlayers and server.id ~= game.JobId then
                         foundCount = foundCount + 1
                         local frame = Instance.new("Frame")
                         frame.Name = "ServerFrame"
                         frame.Size = UDim2.new(1, 0, 0, 45)
                         frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
                         frame.BackgroundTransparency = 0.3
                         frame.LayoutOrder = server.playing -- Sort by player count? Or naturally
                         frame.Parent = container
                         local fc = Instance.new("UICorner") fc.CornerRadius = UDim.new(0, 6) fc.Parent = frame
                         local fs = Instance.new("UIStroke") fs.Color = Config.AccentColor fs.Transparency = 0.8 fs.Parent = frame
                         
                         local info = Instance.new("TextLabel")
                         info.Text = server.playing .. "/" .. server.maxPlayers .. " Players"
                         info.Size = UDim2.new(0.5, 0, 0.5, 0)
                         info.Position = UDim2.new(0, 10, 0, 5)
                         info.BackgroundTransparency = 1
                         info.TextColor3 = Config.TextColor
                         info.Font = Config.Font
                         info.TextSize = 14
                         info.TextXAlignment = Enum.TextXAlignment.Left
                         info.Parent = frame
                         
                         local pingLbl = Instance.new("TextLabel")
                         pingLbl.Text = "Ping: " .. (server.ping or "?") .. "ms"
                         pingLbl.Size = UDim2.new(0.5, 0, 0.4, 0)
                         pingLbl.Position = UDim2.new(0, 10, 0.5, 0)
                         pingLbl.BackgroundTransparency = 1
                         pingLbl.TextColor3 = Config.SecondaryTextColor
                         pingLbl.Font = Config.Font
                         pingLbl.TextSize = 11
                         pingLbl.TextXAlignment = Enum.TextXAlignment.Left
                         pingLbl.Parent = frame
                         
                         local joinBtn = Instance.new("TextButton")
                         joinBtn.Size = UDim2.new(0.3, 0, 0.6, 0)
                         joinBtn.Position = UDim2.new(0.65, 0, 0.2, 0)
                         joinBtn.BackgroundColor3 = Config.AccentColor
                         joinBtn.Text = "Join"
                         joinBtn.TextColor3 = Config.TextColor
                         joinBtn.Font = Config.Font
                         joinBtn.TextSize = 13
                         joinBtn.Parent = frame
                         local jc = Instance.new("UICorner") jc.CornerRadius = UDim.new(0, 4) jc.Parent = joinBtn
                         
                         joinBtn.MouseButton1Click:Connect(function()
                             game:GetService("TeleportService"):TeleportToPlaceInstance(placeId, server.id, LocalPlayer)
                         end)
                    end
                end
                 container.CanvasSize = UDim2.new(0,0,0, container.UIListLayout.AbsoluteContentSize.Y)
                 if foundCount == 0 and txt then txt.Text = "Status: No joinable servers found." end
            else
                if txt then txt.Text = "Status: API Error (Check Console)" end
                print("Server Fetch Failed: " .. errInfo)
            end
        end)
end



Servers:AddButton("Refresh Server List", function()
    -- Directly use the exposed Page object
    local page = Servers.Page
    local scroll = page and page:FindFirstChild("ServerScroll")
    if scroll then 
        RefreshServers(scroll) 
    else
        warn("Server Scroll not found! (Refresh)")
    end
end)

-- Inject Custom Server List UI into the TabPage
task.spawn(function()
    task.wait(0.5) 
    local page = Servers.Page
    if not page then warn("ServersPage not found in Object!") return end
    
    -- Prevent Duplicate Injection
    if page:FindFirstChild("ServerScroll") then return end
    
    local status = Instance.new("TextLabel")
    status.Name = "StatusText"
    status.Text = "Ready to search."
    status.Size = UDim2.new(1, 0, 0, 24)
    status.BackgroundTransparency = 1
    status.TextColor3 = Config.SecondaryTextColor
    status.Font = Config.Font
    status.TextSize = 14
    status.Parent = page
    
    local scroll = Instance.new("ScrollingFrame")
    scroll.Name = "ServerScroll"
    scroll.Size = UDim2.new(1, 0, 0, 250) -- Fixed Height to play nice with UIListLayout
    -- Removed Position (Layout handles it)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.Parent = page
    
    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 5)
    layout.Parent = scroll
    
    -- Resize scroll automatically
    -- We need to ensure the Page allows scrolling too if needed, but Page is a ScrollFrame.
    -- Better: Set ServerScroll AutomaticCanvasSize?
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    
    RefreshServers(scroll)
end)

-- Old Troll Buttons Removed (Moved to PlayerList)


local Anims = Window:AddTab({Title = "Animations", Icon = "rbxassetid://10723405785"}) -- Running Man

local function setAnim(id, animName, subName)
    if not id then return end -- Prevent errors on missing anims
    local char = LocalPlayer.Character
    if not char then return end
    local animate = char:FindFirstChild("Animate")
    if not animate then return end
    
    local animValue = animate:FindFirstChild(animName)
    if animValue then
        if subName then
             local sub = animValue:FindFirstChild(subName)
             if sub then sub.AnimationId = id end
        else
             for _, v in pairs(animValue:GetChildren()) do
                 if v:IsA("Animation") then v.AnimationId = id end
             end
        end
    end
end

local function applyPack(pack)
    -- Idle (Often has Animation1 and Animation2)
    setAnim(pack.idle[1], "idle", "Animation1")
    setAnim(pack.idle[2] or pack.idle[1], "idle", "Animation2")
    setAnim(pack.walk, "walk")
    setAnim(pack.run, "run")
    setAnim(pack.jump, "jump")
    setAnim(pack.fall, "fall")
    setAnim(pack.climb, "climb") -- Optional
    
    -- Restart Animate
    local char = LocalPlayer.Character
    if char then
        local animScript = char:FindFirstChild("Animate")
        if animScript then
            animScript.Disabled = true
            task.wait()
            animScript.Disabled = false
        end
    end
end


-- // EMOTE PLAYER & FAVORITES //
local PresetEmotes = {
    {"Salute", "rbxassetid://10714389988"},
    {"Applaud", "rbxassetid://10713966026"},
    {"Tilt", "rbxassetid://10714338461"},
    {"Bouncy Twirl", "rbxassetid://14352343065"},
    {"Happier Jump", "rbxassetid://15609995579"},
    {"Face Frame", "rbxassetid://14352340648"},
    {"Strut", "rbxassetid://14352362059"},
    {"Touch", "rbxassetid://135876612109535"},
    {"Secret Handshake", "rbxassetid://71243990877913"},
    {"Godlike", "rbxassetid://10714347256"},
    {"Piano Hands", "rbxassetid://16553163212"},
    {"Lotus Position", "rbxassetid://12507085924"},
    {"Backflip", "rbxassetid://15693621070"},
    {"Bored", "rbxassetid://10713992055"},
    {"Levitate", "rbxassetid://15698404340"},
    {"Hero Landing", "rbxassetid://10714360164"},
    {"Sleep", "rbxassetid://10714360343"},
    {"Shrug", "rbxassetid://10714374484"},
    {"Shy", "rbxassetid://10714369325"},
    {"Festive Dance", "rbxassetid://15679621440"},
    {"V Pose", "rbxassetid://10214319518"},
    {"Head Bop", "rbxassetid://15517864808"},
    {"Heart Shuffle", "rbxassetid://17748314784"},
    {"Bone Chillin Bop", "rbxassetid://15122972413"},
    {"Curtsy", "rbxassetid://10714061912"},
    {"Floss", "rbxassetid://10714340543"},
    {"Hello", "rbxassetid://10714359093"},
    {"Victory Dance", "rbxassetid://15505456446"},
    {"Monkey", "rbxassetid://10714388352"},
    {"Feel Special", "rbxassetid://14899980745"},
    {"Point", "rbxassetid://10714395441"},
    {"Quiet Waves", "rbxassetid://10714390497"},
    {"Amaarae", "rbxassetid://16572740012"},
    {"Frosty Flair", "rbxassetid://10214311282"},
    {"HOT TO GO!", "rbxassetid://85267023718407"},
    {"Stadium", "rbxassetid://10714356920"},
    {"Titan Speakerman", "rbxassetid://134283166482394"},
    {"Sad", "rbxassetid://10714392876"},
    {"Greatest", "rbxassetid://10714349037"},
    {"Ice Spice Sturdy", "rbxassetid://17746180844"},
    {"Heart Skip", "rbxassetid://11309255148"},
    {"Iconic IT-Grrrl", "rbxassetid://15392756794"},
    {"Fashion Roadkill", "rbxassetid://136831243854748"},
    {"Starships", "rbxassetid://15571453761"},
    {"LIKEY", "rbxassetid://14899979575"},
    {"Boom Boom Boom", "rbxassetid://15571448688"},
    {"Samba", "rbxassetid://16270690701"},
    {"HUGO Lets Drive!", "rbxassetid://17360699557"},
    {"Sliving", "rbxassetid://15392759696"},
    {"Archer", "rbxassetid://13823324057"},
    {"Beauty Touchdown", "rbxassetid://16302968986"},
    {"Cower", "rbxassetid://4940563117"},
    {"Happy", "rbxassetid://10714352626"},
    {"Flex Walk", "rbxassetid://15505459811"},
    {"Team USA", "rbxassetid://18526288497"},
    {"Zombie Emote", "rbxassetid://10714089137"},
    {"Rodrigo Float", "rbxassetid://15549124879"},
    {"Walking On Water", "rbxassetid://125064469983655"},
    {"Haha", "rbxassetid://10714350889"},
    {"Air Guitar", "rbxassetid://14352335202"},
    {"Dizzy", "rbxassetid://10714066964"},
    {"High Wave", "rbxassetid://10714362852"},
    {"Beckon", "rbxassetid://10713984554"},
    {"Show Dem Wrists", "rbxassetid://10714377090"},
    {"Jumping Wave", "rbxassetid://10714378156"},
    {"Dramatic Bow", "rbxassetid://14352337694"},
    {"Fast Hands", "rbxassetid://10714100539"},
    {"Dolphin Dance", "rbxassetid://10714068222"},
    {"Wake Up Call", "rbxassetid://10714168145"},
    {"Jawny Stomp", "rbxassetid://16392075853"},
    {"Rock Out", "rbxassetid://11753474067"},
    {"Checking My Angles", "rbxassetid://15392752812"},
    {"Power Blast", "rbxassetid://10714389396"},
    {"Bodybuilder", "rbxassetid://10713990381"},
    {"Line Dance", "rbxassetid://10714383856"},
    {"Rock n Roll", "rbxassetid://15505458452"},
    {"Agree", "rbxassetid://10713954623"},
    {"Celebrate", "rbxassetid://10714016223"},
    {"Mini Kong", "rbxassetid://17000021306"},
    {"TMNT Dance", "rbxassetid://18665811005"},
    {"Couldn't Care Less", "rbxassetid://107875941017127"},
    {"Guitar Strum", "rbxassetid://18148804340"},
    {"Bebe Rexha Rock", "rbxassetid://18225053113"},
    {"ericdoa dance", "rbxassetid://15698402762"},
    {"Confused", "rbxassetid://4940561610"},
    {"Ay-Yo Dance", "rbxassetid://12804157977"},
    {"Rock On", "rbxassetid://10714403700"},
    {"Bones Dance", "rbxassetid://15689279687"},
    {"Arm Wave", "rbxassetid://16584481352"},
    {"Uprise", "rbxassetid://10275008655"},
    {"Sidekicks", "rbxassetid://10370362157"},
    {"Boxing Punch", "rbxassetid://10717116749"},
    {"Fashionable", "rbxassetid://10714091938"},
    {"Sanasa", "rbxassetid://16126469463"},
    {"Baby Dance", "rbxassetid://10713983178"},
    {"Mean Girls", "rbxassetid://15963314052"},
    {"Samba Generic", "rbxassetid://10714386947"},
    {"Monster Dunk", "rbxassetid://132748833449150"},
}

local FavoriteAnims = {}
local currentEmoteTrack = nil
local currentEmoteSpeed = 1

local function SaveAnims()
    if writefile then
        writefile("vibe_anims.json", HttpService:JSONEncode(FavoriteAnims))
    end
end

local function LoadAnims()
    if readfile and isfile and isfile("vibe_anims.json") then
        pcall(function()
            FavoriteAnims = HttpService:JSONDecode(readfile("vibe_anims.json"))
        end)
    end
end

local function PlayEmote(id)
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChild("Humanoid")
    if not hum or not id then return end
    
    for _, t in pairs(hum:GetPlayingAnimationTracks()) do t:Stop() end
    
    local anim = Instance.new("Animation")
    anim.AnimationId = (tostring(id):find("rbxassetid://") and id or "rbxassetid://" .. id)
    currentEmoteTrack = hum:LoadAnimation(anim)
    currentEmoteTrack.Priority = Enum.AnimationPriority.Action
    currentEmoteTrack:AdjustSpeed(currentEmoteSpeed)
    currentEmoteTrack:Play()
end

LoadAnims()

-- Animation IDs (Public R15/R6 IDs)
local Packs = {
    Vampire = {
        idle = {"rbxassetid://1083445855", "rbxassetid://1083450166"},
        walk = "rbxassetid://1083473930",
        run = "rbxassetid://1083462077",
        jump = "rbxassetid://1083455352",
        fall = "rbxassetid://1083443587",
        climb = "rbxassetid://1083439238"
    },
    Hero = {
        idle = {"rbxassetid://616111295", "rbxassetid://616113536"},
        walk = "rbxassetid://616122287",
        run = "rbxassetid://616117076",
        jump = "rbxassetid://616115533",
        fall = "rbxassetid://616109315",
        climb = "rbxassetid://616104706"
    },
    Zombie = {
        idle = {"rbxassetid://616158929", "rbxassetid://616160636"},
        walk = "rbxassetid://616168032",
        run = "rbxassetid://616163682",
        jump = "rbxassetid://616161997",
        fall = "rbxassetid://616157476",
        climb = "rbxassetid://616156119"
    },
    Mage = {
        idle = {"rbxassetid://707742142", "rbxassetid://707855907"},
        walk = "rbxassetid://707897309",
        run = "rbxassetid://707886071",
        jump = "rbxassetid://707867992",
        fall = "rbxassetid://707829716",
        climb = "rbxassetid://707826056"
    },
    Ghost = {
        idle = {"rbxassetid://616006778", "rbxassetid://616008936"},
        walk = "rbxassetid://616013216",
        run = "rbxassetid://616010382",
        jump = "rbxassetid://616008936",
        fall = "rbxassetid://616005863",
        climb = "rbxassetid://616003713"
    },
    Elder = {
        idle = {"rbxassetid://845397899", "rbxassetid://845403856"},
        walk = "rbxassetid://845403856",
        run = "rbxassetid://845386501",
        jump = "rbxassetid://845398858",
        fall = "rbxassetid://845396048",
        climb = "rbxassetid://845392038"
    },
    Levitation = {
        idle = {"rbxassetid://616006778", "rbxassetid://616008936"},
        walk = "rbxassetid://616013216",
        run = "rbxassetid://616010382",
        jump = "rbxassetid://616008936",
        fall = "rbxassetid://616005863",
        climb = "rbxassetid://616003713"
    },
    Astronaut = {
        idle = {"rbxassetid://891621366", "rbxassetid://891633237"},
        walk = "rbxassetid://891667138",
        run = "rbxassetid://891636393",
        jump = "rbxassetid://891627522",
        fall = "rbxassetid://891620267",
        climb = "rbxassetid://891603711"
    },
    Ninja = {
        idle = {"rbxassetid://656117400", "rbxassetid://656118341"},
        walk = "rbxassetid://656121766",
        run = "rbxassetid://656118852",
        jump = "rbxassetid://656119473",
        fall = "rbxassetid://656115606",
        climb = "rbxassetid://656114359"
    },
    Werewolf = {
        idle = {"rbxassetid://1083195517", "rbxassetid://1083214724"},
        walk = "rbxassetid://1083178339",
        run = "rbxassetid://1083216690",
        jump = "rbxassetid://1083218792",
        fall = "rbxassetid://1083189019",
        climb = "rbxassetid://1083182000"
    },
    Cartoon = {
        idle = {"rbxassetid://742637544", "rbxassetid://742638445"},
        walk = "rbxassetid://742640026",
        run = "rbxassetid://742638842",
        jump = "rbxassetid://742637942",
        fall = "rbxassetid://742637151",
        climb = "rbxassetid://742636889"
    },
    Pirate = {
        idle = {"rbxassetid://750781874", "rbxassetid://750782770"},
        walk = "rbxassetid://750785693",
        run = "rbxassetid://750783738",
        jump = "rbxassetid://750782242",
        fall = "rbxassetid://750780242",
        climb = "rbxassetid://750779899"
    },
    Sneaky = {
        idle = {"rbxassetid://1132473842", "rbxassetid://1132477671"},
        walk = "rbxassetid://1132510133",
        run = "rbxassetid://1132494274",
        jump = "rbxassetid://1132489853",
        fall = "rbxassetid://1132469004",
        climb = "rbxassetid://1132461372"
    },
    Toy = {
        idle = {"rbxassetid://782841498", "rbxassetid://782841498"},
        walk = "rbxassetid://782843345",
        run = "rbxassetid://782842708",
        jump = "rbxassetid://782847020",
        fall = "rbxassetid://782846423",
        climb = "rbxassetid://782843869"
    },
    Knight = {
        idle = {"rbxassetid://616082211", "rbxassetid://616082211"}, 
        walk = "rbxassetid://616095333",
        run = "rbxassetid://616091535",
        jump = "rbxassetid://616089304",
        fall = "rbxassetid://616080211",
        climb = "rbxassetid://616075933"
    },
    Patrol = {
        idle = {"rbxassetid://1149612395", "rbxassetid://1149610191"},
        walk = "rbxassetid://1149612847",
        run = "rbxassetid://1149610191",
        jump = "rbxassetid://1149611388",
        fall = "rbxassetid://1149609556",
        climb = "rbxassetid://1149608677"
    },
    Adidas = {
        idle = {"rbxassetid://126354114956642", "rbxassetid://126354114956642"},
        walk = "rbxassetid://106810508343012",
        run = "rbxassetid://124765145869332",
        jump = "rbxassetid://115715495289805",
        fall = "rbxassetid://93993406355955",
        climb = "rbxassetid://123695349157584"
    }
}


Anims:AddSection("Emote Player")
local lastId = ""
Anims:AddTextBox("Manual Animation ID", function(v)
    lastId = v
    PlayEmote(v)
end)

local presetNames = {}
for _, e in pairs(PresetEmotes) do table.insert(presetNames, e[1]) end
Anims:AddDropdown("Preset Emotes", presetNames, function(v)
    for _, e in pairs(PresetEmotes) do
        if e[1] == v then
            lastId = e[2]
            PlayEmote(e[2])
            break
        end
    end
end)

Anims:AddSlider("Animation Speed", {Min = 0, Max = 10, Default = 1}, function(v)
    currentEmoteSpeed = v
    if currentEmoteTrack then currentEmoteTrack:AdjustSpeed(v) end
end)

Anims:AddButton("Stop All Animations", function()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChild("Humanoid")
    if hum then for _, t in pairs(hum:GetPlayingAnimationTracks()) do t:Stop() end end
    currentEmoteTrack = nil
end)

Anims:AddSection("Favorites")
local favNames = {}
local function updateFavNames()
    table.clear(favNames)
    for name, _ in pairs(FavoriteAnims) do table.insert(favNames, name) end
    table.sort(favNames)
end
updateFavNames()

Anims:AddButton("Save Current ID to Favorites", function()
    if lastId == "" then return end
    -- Prompt for name? or just use ID as name?
    -- For simplicity, let's use a default name or ID if no name provided.
    -- Actually, I'll use the ID as the key for now, or "Fav " .. ID.
    local name = "Anim_" .. tostring(lastId):gsub("rbxassetid://", "")
    FavoriteAnims[name] = lastId
    SaveAnims()
    updateFavNames()
end)

Anims:AddDropdown("My Favorites", favNames, function(v)
    if FavoriteAnims[v] then
        lastId = FavoriteAnims[v]
        PlayEmote(FavoriteAnims[v])
    end
end)

Anims:AddButton("Clear All Favorites", function()
    table.clear(FavoriteAnims)
    SaveAnims()
    updateFavNames()
end)

Anims:AddSection("Custom Mixer")

local packNames = {}
for n, _ in pairs(Packs) do table.insert(packNames, n) end
table.sort(packNames)

local mix = {
    idle = "Superhero",
    walk = "Superhero",
    run = "Superhero",
    jump = "Superhero",
    fall = "Superhero",
    climb = "Superhero"
}

Anims:AddDropdown("Idle Anim", packNames, function(v) mix.idle = v end)
Anims:AddDropdown("Walk Anim", packNames, function(v) mix.walk = v end)
Anims:AddDropdown("Run Anim", packNames, function(v) mix.run = v end)
Anims:AddDropdown("Jump Anim", packNames, function(v) mix.jump = v end)
Anims:AddDropdown("Fall Anim", packNames, function(v) mix.fall = v end)
Anims:AddDropdown("Climb Anim", packNames, function(v) mix.climb = v end)

Anims:AddButton("Apply Custom Mix", function()
    -- Construct a virtual pack based on selections
    local virtualPack = {
        idle = Packs[mix.idle] and Packs[mix.idle].idle or Packs.Superhero.idle,
        walk = Packs[mix.walk] and Packs[mix.walk].walk or Packs.Superhero.walk,
        run = Packs[mix.run] and Packs[mix.run].run or Packs.Superhero.run,
        jump = Packs[mix.jump] and Packs[mix.jump].jump or Packs.Superhero.jump,
        fall = Packs[mix.fall] and Packs[mix.fall].fall or Packs.Superhero.fall,
        climb = Packs[mix.climb] and Packs[mix.climb].climb or Packs.Superhero.climb
    }
    applyPack(virtualPack)
end)


Anims:AddSection("Full Packs")

for name, pack in pairs(Packs) do
    Anims:AddButton(name .. " Pack", function() applyPack(pack) end)
end

local Graphics = Window:AddTab({Title = "Graphics", Icon = "rbxassetid://10723346959"})

Graphics:AddSection("Time Control")
Graphics:AddSlider("Clock Time", {Min = 0, Max = 24, Default = 14}, function(v)
    game:GetService("Lighting").ClockTime = v
end)

Graphics:AddButton("Morning (08:00)", function()
    TweenService:Create(game:GetService("Lighting"), TweenInfo.new(1), {ClockTime = 8}):Play()
end)
Graphics:AddButton("Noon (14:00)", function()
    TweenService:Create(game:GetService("Lighting"), TweenInfo.new(1), {ClockTime = 14}):Play()
end)

Graphics:AddSection("Post-Processing")
Graphics:AddToggle("New shader", false, function(v)
    _G.NewShaderEnabled = v
    local Lighting = game:GetService("Lighting")
    
    if v then
        -- Cleanup existing to be safe
        for _, obj in pairs(_G.ShaderEffects) do pcall(function() obj:Destroy() end) end
        table.clear(_G.ShaderEffects)
        
        Lighting.Brightness = 2
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = true
        Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
        
        local function add(class, props)
            local effect = Instance.new(class, Lighting)
            for i, p in pairs(props) do effect[i] = p end
            table.insert(_G.ShaderEffects, effect)
            return effect
        end
        
        add("BloomEffect", {Intensity = 0.1, Size = 24, Threshold = 2})
        add("ColorCorrectionEffect", {Brightness = 0.1, Contrast = 0.1, Saturation = 0.1})
        add("SunRaysEffect", {Intensity = 0.1, Spread = 1})
    else
        -- Disable
        for _, obj in pairs(_G.ShaderEffects) do pcall(function() obj:Destroy() end) end
        table.clear(_G.ShaderEffects)
        
        -- Restore baseline?
        Lighting.Brightness = 1
        Lighting.FogEnd = 10000
        Lighting.OutdoorAmbient = Color3.fromRGB(127, 127, 127)
    end
end)
Graphics:AddButton("Evening (18:00)", function()
    TweenService:Create(game:GetService("Lighting"), TweenInfo.new(1), {ClockTime = 18}):Play()
end)
Graphics:AddButton("Night (00:00)", function()
    TweenService:Create(game:GetService("Lighting"), TweenInfo.new(1), {ClockTime = 0}):Play()
end)

Graphics:AddSection("Visual Enhancements")

local rtxEnabled = false
local bloom, sunrays, colorEffect, blur

Graphics:AddToggle("RTX Mode (Shaders)", false, function(v)
    rtxEnabled = v
    local lighting = game:GetService("Lighting")
    local terrain = workspace:FindFirstChildOfClass("Terrain")
    
    if rtxEnabled then
        -- 1. Bloom (Glow)
        if not bloom then
            bloom = Instance.new("BloomEffect")
            bloom.Name = "LowHub_Bloom"
        end
        bloom.Parent = lighting
        bloom.Intensity = 0.4 -- Adjusted for realistic glow
        bloom.Size = 24
        bloom.Threshold = 0.95 -- Only very bright things glow
        
        -- 2. SunRays (Godrays)
        if not sunrays then
            sunrays = Instance.new("SunRaysEffect")
            sunrays.Name = "LowHub_SunRays"
        end
        sunrays.Parent = lighting
        sunrays.Intensity = 0.05
        sunrays.Spread = 0.1
        
        -- 3. Color Correction (Vibrancy & Contrast)
        if not colorEffect then
            colorEffect = Instance.new("ColorCorrectionEffect")
            colorEffect.Name = "LowHub_Color"
        end
        colorEffect.Parent = lighting
        colorEffect.Brightness = 0.02
        colorEffect.Contrast = 0.05
        colorEffect.Saturation = 0.2 -- Boost colors
        colorEffect.TintColor = Color3.fromRGB(245, 240, 235) -- Warmer tint

        -- 4. Blur (Depth of Field Fake)
        if not blur then
             blur = Instance.new("BlurEffect")
             blur.Name = "LowHub_Blur"
        end
        blur.Parent = lighting
        blur.Size = 2 -- Subtle blur
        
        -- 5. Atmosphere (Fog & Sky)
        local atmosphere = lighting:FindFirstChildOfClass("Atmosphere")
        if not atmosphere then
            atmosphere = Instance.new("Atmosphere")
            atmosphere.Name = "LowHub_Atmosphere"
            atmosphere.Parent = lighting
        end
        atmosphere.Density = 0.35
        atmosphere.Offset = 0.25
        atmosphere.Color = Color3.fromRGB(199, 179, 149)
        atmosphere.Decay = Color3.fromRGB(106, 112, 125)
        atmosphere.Glare = 0.5
        atmosphere.Haze = 1.2

        -- Lighting Properties
        lighting.GlobalShadows = true
        lighting.EnvironmentDiffuseScale = 1
        lighting.EnvironmentSpecularScale = 1
        lighting.ExposureCompensation = 0.5
    else
        -- Disable Custom Effects
        if bloom then bloom.Parent = nil end
        if sunrays then sunrays.Parent = nil end
        if colorEffect then colorEffect.Parent = nil end
        if blur then blur.Parent = nil end
        -- Note: We generally don't destroy Atmosphere as it might break original game look too much if we just delete it, 
        -- but for disable we can just re-parent or leave it. 
        -- Let's just reset standard lighting props slightly or leave them as game default.
        lighting.GlobalShadows = true
        lighting.ExposureCompensation = 0
    end
end)

Graphics:AddToggle("No Blur (Clear View)", false, function(v)
    for _, child in pairs(game:GetService("Lighting"):GetChildren()) do
        if child:IsA("BlurEffect") or child:IsA("DepthOfFieldEffect") then
            child.Enabled = not v
        end
    end
end)



Graphics:AddSection("Environment")

Graphics:AddToggle("Better Water", false, function(v)
    local terrain = workspace:WaitForChild("Terrain")
    if v then
        terrain.WaterWaveSize = 0.1
        terrain.WaterWaveSpeed = 2
        terrain.WaterReflectance = 0.85
        terrain.WaterTransparency = 0.9
    else
        -- Default (approximate)
        terrain.WaterWaveSize = 0.15
        terrain.WaterWaveSpeed = 10
        terrain.WaterReflectance = 1
        terrain.WaterTransparency = 1
    end
end)

Graphics:AddToggle("Fullbright", false, function(v)
    local lighting = game:GetService("Lighting")
    if v then
        lighting.Brightness = 2
        lighting.ClockTime = 14
        lighting.FogEnd = 100000
        lighting.GlobalShadows = false
        lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
    else
        lighting.Brightness = 1
        lighting.GlobalShadows = true
        lighting.FogEnd = 10000
        lighting.OutdoorAmbient = Color3.fromRGB(127, 127, 127)
    end
end)

    local function HubChat(msg)
        local chatEvents = game:GetService("ReplicatedStorage"):FindFirstChild("DefaultChatSystemChatEvents")
        local sayMsg = chatEvents and chatEvents:FindFirstChild("SayMessageRequest")
        local cmd = "/e .low " .. msg
        if sayMsg then
            sayMsg:FireServer(cmd, "All")
        else
            local tcs = game:GetService("TextChatService")
            if tcs.ChatInputBarConfiguration.TargetTextChannel then
                tcs.ChatInputBarConfiguration.TargetTextChannel:SendAsync(cmd)
            end
        end
    end

-- // OWNER TAB LOGIC //
if Owner then
    Owner:AddSection("Self Protection")
    Owner:AddToggle("Owner Stealth (Hide from ESP)", false, function(v)
        if LowHubLoaded then HubSignal("Stealth:All:" .. tostring(v)) end
    end)
    
    Owner:AddToggle("Reflect Trolls & Anti-Spectate", true, function(v)
        _G.OwnerReflect = v
        if LowHubLoaded then HubSignal("AntiSpectate:All:" .. tostring(v)) end
    end)
    
    _G.OwnerReflect = true -- Default ON
    _G.GlobalAntiSpectate = _G.GlobalAntiSpectate or {}
    _G.GlobalAntiSpectate[LocalPlayer.Name] = true -- Default ON for Owner sync if manual load

end

-- // ADMIN TAB LOGIC //
if Admin then
    Admin:AddSection("Protections")
    Admin:AddToggle("Reflect Trolls & Anti-Spectate", true, function(v)
        HubSignal("AdminReflect:All:" .. tostring(v))
        HubSignal("AntiSpectate:All:" .. tostring(v))
    end)
    
    Admin:AddSection("Broadcast Message")
    local adminBroadcastMsg = ""
    Admin:AddTextBox("Message Content", function(v) adminBroadcastMsg = v end)
    Admin:AddButton("Send Global Broadcast", function()
        if adminBroadcastMsg ~= "" then
            HubSignal("Broadcast:All:" .. adminBroadcastMsg)
        end
    end)

    -- Sync initial state
    task.spawn(function()
        task.wait(2)
        -- Explicit Codes
        HubSignal("AdminReflect:All:true")
        HubSignal("AntiSpectate:All:true")
    end)
end

if Owner then
    local broadcastMsg = ""
    Owner:AddTextBox("Broadcast Message", function(v) broadcastMsg = v end)
    Owner:AddButton("Send Global Broadcast", function()
        if broadcastMsg ~= "" then
            HubSignal("Broadcast:All:" .. broadcastMsg)
        end
    end)
    
    Owner:AddButton("Lock Hub for All Users", function()
        HubSignal("Lock:All:true")
    end)
    
    Owner:AddButton("Unlock Hub for All Users", function()
        HubSignal("Unlock:All:true")
    end)
    
    Owner:AddSection("Puppet Master")
    local mimicMsg = ""
    Owner:AddTextBox("Mimic Chat Message", function(v) mimicMsg = v end)
    
    Owner:AddSection("Hub User List (Controls)")
    local PlayerStates = {} -- Store toggles per player { [Name] = {Frozen = false, Lagging = false} }

    local function UpdateUserList()
        local page = Owner.Page
        if not page then return end
        local container = page:FindFirstChild("UserListGrid")
        if not container then
             container = Instance.new("ScrollingFrame")
             container.Name = "UserListGrid"
             container.Size = UDim2.new(1, -10, 0, 150)
             container.Position = UDim2.new(0, 5, 0, 350) 
             container.BackgroundTransparency = 1
             container.ScrollBarThickness = 2
             container.Parent = page
             local layout = Instance.new("UIListLayout")
             layout.Padding = UDim.new(0, 5)
             layout.Parent = container
        end
        
        -- Get current valid players
        local currentPlayers = {}
        for _, p in pairs(Players:GetPlayers()) do
            local role = GetRole(p.Name)
            if p ~= LocalPlayer and role then
                currentPlayers[p.Name] = role
            end
        end

        -- Clean up invalid frames
        for _, child in pairs(container:GetChildren()) do
            if child:IsA("Frame") then
                if not currentPlayers[child.Name] then
                    child:Destroy()
                end
            end
        end
        
        -- Add or Update frames
        for name, role in pairs(currentPlayers) do
            local p = Players:FindFirstChild(name)
            if p then
                local f = container:FindFirstChild(name)
                if not f then
                    f = Instance.new("Frame")
                    f.Name = name -- Identify by Name
                    f.Size = UDim2.new(1, -10, 0, 30)
                    f.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
                    f.Parent = container
                    
                    -- Init State
                    if not PlayerStates[name] then PlayerStates[name] = {Frozen = false, Lagging = false} end
                    Instance.new("UICorner", f)
                    
                    local l = Instance.new("TextLabel")
                    l.Name = "InfoLabel"
                    l.Size = UDim2.new(0.4, 0, 1, 0)
                    l.Position = UDim2.new(0, 5, 0, 0)
                    l.TextColor3 = Config.TextColor
                    l.BackgroundTransparency = 1
                    l.Font = Config.Font
                    l.TextSize = 12
                    l.TextXAlignment = Enum.TextXAlignment.Left
                    l.Parent = f
                    
                    local actions = {"Kill", "Freeze", "Lock", "Mimic", "Lag"}
                    local xOffset = 0.45
                    for _, act in ipairs(actions) do
                        local b = Instance.new("TextButton")
                        b.Name = act .. "Btn"
                        b.Text = act
                        b.Size = UDim2.new(0.08, 0, 0.8, 0)
                        b.Position = UDim2.new(xOffset, 0, 0.1, 0)
                        b.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                        b.TextColor3 = Config.AccentColor
                        
                        if act == "Kill" then b.TextColor3 = Color3.fromRGB(200, 50, 50) end
                        b.TextSize = 10
                        b.Font = Config.Font
                        b.Parent = f
                        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
                        
                        b.MouseButton1Click:Connect(function()
                            -- Refetch state to be safe
                            local pState = PlayerStates[name]
                            local cmdArg = "true"
                            local cmdType = act
                            if act == "Mimic" then cmdType = "Chat" cmdArg = mimicMsg end
                            
                            if act == "Freeze" then
                                 pState.Frozen = not pState.Frozen
                                 cmdArg = tostring(pState.Frozen)
                                 if pState.Frozen then b.Text = "Unfreeze" b.TextColor3 = Color3.fromRGB(255, 0, 0) 
                                 else b.Text = "Freeze" b.TextColor3 = Config.AccentColor end
                            end
    
                            if act == "Lag" then 
                                pState.Lagging = not pState.Lagging 
                                cmdArg = tostring(pState.Lagging) 
                                 if pState.Lagging then b.Text = "Stop Lag" b.TextColor3 = Color3.fromRGB(255, 0, 0) 
                                 else b.Text = "Lag" b.TextColor3 = Config.AccentColor end
                            end
                            
                            HubSignal(cmdType .. ":" .. name .. ":" .. cmdArg)
                        end)
                        xOffset = xOffset + 0.09
                    end
                end
                
                -- Always update Label (in case Role changed)
                local lbl = f:FindFirstChild("InfoLabel")
                if lbl then lbl.Text = name .. " [" .. role .. "]" end
            end
        end
        
        if container:FindFirstChild("UIListLayout") then
            container.CanvasSize = UDim2.new(0,0,0, container.UIListLayout.AbsoluteContentSize.Y)
        end
    end
    
    Owner:AddButton("Refresh User List", UpdateUserList)
    Owner:AddButton("Server Hop All Users", function()
        HubSignal("HopAll:All:true")
    end)
    
    task.spawn(function()
        while task.wait(5) do UpdateUserList() end
    end)
end

Settings:AddSection("Menu Config")
local menuBind = Settings:AddBind("Menu Toggle Bind", Enum.KeyCode.RightControl, function(key) 
    if key then Window.ToggleKey = key end 
end)

Settings:AddSection("Movement (PC Walk)")
local walkToggle = Settings:AddToggle("Walk Mode", false, function(v)
    walkModeEnabled = v
    if not v and LocalPlayer.Character then
        local h = LocalPlayer.Character:FindFirstChild("Humanoid")
        if h then h.WalkSpeed = 16 end
    end
end)
Settings:AddSlider("Walk Speed", {Min = 1, Max = 16, Default = 8}, function(v) walkSpeed = v end)
local walkBindElement = Settings:AddBind("Walk Toggle Bind", walkModeBind, function(key) 
    if key then 
        walkModeBind = key 
    elseif not key then
        -- Toggle if called without key (by listener)
        walkModeEnabled = not walkModeEnabled
        if walkToggle then walkToggle.Set(walkModeEnabled) end
    end
end)

-- Customizable Keybind for Walk Mode
UserInputService.InputBegan:Connect(function(input, gp)
    if not gp and input.KeyCode == walkModeBind then
        walkModeEnabled = not walkModeEnabled
        if walkToggle then walkToggle.Set(walkModeEnabled) end
    end
end)

Settings:AddSection("Extra")
Settings:AddButton("Rejoin Server", function()
    local ts = game:GetService("TeleportService")
    local p = game:GetService("Players").LocalPlayer
    
    -- Try to Rejoin Same Instance First
    if #game:GetService("Players"):GetPlayers() <= 1 then
         -- If we are alone, just rejoin the place (might make new server)
         ts:Teleport(game.PlaceId, p)
    else
         ts:TeleportToPlaceInstance(game.PlaceId, game.JobId, p)
    end
end)
Settings:AddButton("Inject Infinite Yield", function()
    loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))()
end)

Settings:AddSection("Unload")
Settings:AddButton("Uninject (Destruct)", function()
    espEnabled = false
    autoFarmEnabled = false
    updateESP()
    Window:Destroy()
end)

Settings:AddSection("Configuration (Experimental)")
Settings:AddButton("Save Config", function()
    if writefile then
        local data = {
            flySpeed = flySpeed, 
            customSpeed = customSpeed, 
            noclip = noclipEnabled,
            speedEnabled = speedEnabled,
            flyEnabled = flyEnabled,
            antiFling = _G.antiFling,
            spinEnabled = spinEnabled,
            spinSpeed = spinSpeed,
            toggleKey = Window.ToggleKey.Name,
            
            -- Saved Binds
            espBind = espToggle and espToggle.GetBind() and espToggle.GetBind().Name,
            antiFlingBind = antiFlingToggle and antiFlingToggle.GetBind() and antiFlingToggle.GetBind().Name,
            spinBind = spinToggle and spinToggle.GetBind() and spinToggle.GetBind().Name,
            infJumpBind = infJumpToggle and infJumpToggle.GetBind() and infJumpToggle.GetBind().Name,
            antiAfkBind = antiAfkToggle and antiAfkToggle.GetBind() and antiAfkToggle.GetBind().Name,
            clickTpBind = clickTpToggle and clickTpToggle.GetBind() and clickTpToggle.GetBind().Name,
            autoQTEBind = autoQEToggle and autoQEToggle.GetBind() and autoQEToggle.GetBind().Name,
            antiJokerBind = antiJokerToggle and antiJokerToggle.GetBind() and antiJokerToggle.GetBind().Name,
            autoFarmBind = autoFarmToggle and autoFarmToggle.GetBind() and autoFarmToggle.GetBind().Name,
            walkBind = walkBindElement and walkBindElement.GetBind() and walkBindElement.GetBind().Name,
            
            -- Saved States (Missing ones)
            espEnabled = espEnabled,
            infJumpEnabled = _G.infJump,
            antiAfkEnabled = _G.antiAfk,
            autoQTEEnabled = autoQTEEnabled,
            antiJokerEnabled = _G.antiJoker
        }
        writefile("LowHub_Config.json", game:GetService("HttpService"):JSONEncode(data))
    end
end)

local function LoadConfiguration()
    -- Safe Check for File Existence
    if not (readfile and isfile and isfile("LowHub_Config.json")) then return end

    -- Safe Read
    local content = nil
    local readSuccess, readErr = pcall(function()
        content = readfile("LowHub_Config.json")
    end)
    
    if not readSuccess or not content or content == "" then
        warn("[LowHub] Failed to read config file or empty.")
        return 
    end

    -- Safe Decode
    local success, data = pcall(function() 
        return game:GetService("HttpService"):JSONDecode(content) 
    end)
    
    if not success or not data then
        warn("[LowHub] Config JSON Decode Failed.")
        return 
    end
    
    -- Load States (Safely)
    pcall(function()
        if data.flySpeed then 
            flySpeed = data.flySpeed 
            if flySpeedSlider then flySpeedSlider.Set(flySpeed) end
        end
        if data.customSpeed then 
            customSpeed = data.customSpeed 
            if speedSlider then speedSlider.Set(customSpeed) end
        end
        if data.noclip ~= nil then 
            noclipEnabled = data.noclip 
            if noclipToggle then noclipToggle.Set(noclipEnabled) end
        end
        if data.speedEnabled ~= nil then
             if speedToggle then speedToggle.Set(data.speedEnabled) end
        end
        if data.flyEnabled ~= nil then
             if flyToggle then flyToggle.Set(data.flyEnabled) end
        end
        if data.antiFling ~= nil then
            _G.antiFling = data.antiFling
            if antiFlingToggle then antiFlingToggle.Set(_G.antiFling) end
        end
        if data.spinEnabled ~= nil then
            spinEnabled = data.spinEnabled
            if spinToggle then spinToggle.Set(spinEnabled) end
        end
        if data.spinSpeed then
            spinSpeed = data.spinSpeed
        end
        
        -- New States
        if data.espEnabled ~= nil and espToggle then espToggle.Set(data.espEnabled) end
        if data.infJumpEnabled ~= nil and infJumpToggle then infJumpToggle.Set(data.infJumpEnabled) end
        if data.antiAfkEnabled ~= nil and antiAfkToggle then antiAfkToggle.Set(data.antiAfkEnabled) end
        if data.autoQTEEnabled ~= nil and autoQEToggle then autoQEToggle.Set(data.autoQTEEnabled) end
        if data.antiJokerEnabled ~= nil and antiJokerToggle then antiJokerToggle.Set(data.antiJokerEnabled) end
        
        -- Toggle Key
        if data.toggleKey then
            if Enum.KeyCode[data.toggleKey] then
                Window.ToggleKey = Enum.KeyCode[data.toggleKey]
                if menuBind then menuBind.Set(Window.ToggleKey) end
            end
        end

        -- Load Binds
        if data.espBind and Enum.KeyCode[data.espBind] then espToggle.SetBind(Enum.KeyCode[data.espBind]) end
        if data.antiFlingBind and Enum.KeyCode[data.antiFlingBind] then antiFlingToggle.SetBind(Enum.KeyCode[data.antiFlingBind]) end
        if data.spinBind and Enum.KeyCode[data.spinBind] then spinToggle.SetBind(Enum.KeyCode[data.spinBind]) end
        if data.infJumpBind and Enum.KeyCode[data.infJumpBind] then infJumpToggle.SetBind(Enum.KeyCode[data.infJumpBind]) end
        if data.antiAfkBind and Enum.KeyCode[data.antiAfkBind] then antiAfkToggle.SetBind(Enum.KeyCode[data.antiAfkBind]) end
        if data.clickTpBind and Enum.KeyCode[data.clickTpBind] then clickTpToggle.SetBind(Enum.KeyCode[data.clickTpBind]) end
        if data.autoQTEBind and Enum.KeyCode[data.autoQTEBind] then autoQEToggle.SetBind(Enum.KeyCode[data.autoQTEBind]) end
        if data.antiJokerBind and Enum.KeyCode[data.antiJokerBind] then antiJokerToggle.SetBind(Enum.KeyCode[data.antiJokerBind]) end
        if data.autoFarmBind and Enum.KeyCode[data.autoFarmBind] then autoFarmToggle.SetBind(Enum.KeyCode[data.autoFarmBind]) end
        if data.walkBind and Enum.KeyCode[data.walkBind] and walkBindElement then 
            walkModeBind = Enum.KeyCode[data.walkBind]
            walkBindElement.SetBind(walkModeBind) 
        end
    end)
end

Settings:AddButton("Load Config", LoadConfiguration)

-- Auto Load Logic
task.spawn(LoadConfiguration)

end -- End of StartHub


-- // AUTHENTICATION SYSTEM //
local function Authenticate()
    local player = game:GetService("Players").LocalPlayer
    
    -- Check if user has a role (Supports Name or ID)
    -- Check if user has a role (Supports Name or ID)
    local userRole = GetRole(player)
    if userRole then
        -- Authorized
        
        -- // INJECTION LOGGING //
        task.spawn(function()
            if USE_API_WHITELIST then
                -- Detect Executor
                local executor = "Unknown"
                if identifyexecutor then
                    executor = identifyexecutor()
                elseif syn then
                    executor = "Synapse X"
                elseif fluxus then
                    executor = "Fluxus"
                elseif krnl then
                    executor = "Krnl"
                elseif is_sirhurt_closure then
                    executor = "Sirhurt"
                elseif sentinels then
                    executor = "Sentinel"
                end
                
                local data = {
                    user = player.Name,
                    userId = player.UserId,
                    gameId = game.PlaceId,
                    jobId = game.JobId,
                    role = userRole,
                    executor = executor
                }
                
                local HttpService = game:GetService("HttpService")
                 -- Use raw http request if available to bypass potential wrapper filters
                local req = request or http_request or (syn and syn.request) or (http and http.request) or (fluxus and fluxus.request)
                if req then
                    pcall(function()
                         req({
                            Url = API_URL:gsub("/check", "/log"), -- Switch to /log endpoint
                            Method = "POST",
                            Headers = {["Content-Type"] = "application/json"},
                            Body = HttpService:JSONEncode(data)
                        })
                    end)
                end
            end
        end)
        
        StartHub()
    else
        -- Unauthorized UI
        local ScreenGui = Instance.new("ScreenGui")
        ScreenGui.Name = "AuthFail"
        ScreenGui.Parent = CoreGui
        
        local Frame = Instance.new("Frame")
        Frame.Size = UDim2.new(0, 300, 0, 150)
        Frame.Position = UDim2.new(0.5, -150, 0.5, -75)
        Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        Frame.Parent = ScreenGui
        local UICorner = Instance.new("UICorner") UICorner.CornerRadius = UDim.new(0, 8) UICorner.Parent = Frame
        
        local Title = Instance.new("TextLabel")
        Title.Text = "ACCESS DENIED"
        Title.Size = UDim2.new(1, 0, 0, 40)
        Title.BackgroundTransparency = 1
        Title.TextColor3 = Color3.fromRGB(255, 45, 90)
        Title.Font = Enum.Font.GothamBlack
        Title.TextSize = 24
        Title.Parent = Frame
        
        local Msg = Instance.new("TextLabel")
        Msg.Text = "User @" .. player.Name .. " is not Authorised."
        Msg.Size = UDim2.new(1, -20, 0.6, 0)
        Msg.Position = UDim2.new(0, 10, 0.3, 0)
        Msg.BackgroundTransparency = 1
        Msg.TextColor3 = Color3.fromRGB(200, 200, 200)
        Msg.Font = Enum.Font.Gotham
        Msg.TextSize = 14
        Msg.TextWrapped = true
        Msg.Parent = Frame
        
        task.wait(3)
        ScreenGui:Destroy()
    end
end

Authenticate()

-- // TAG SYSTEM //
local TagSystem = {}

-- (Roles Config moved up)


local RoleData = {
    ["OWNER"] = {
        Color = Color3.fromRGB(255, 45, 90), -- Red/Pink
        Gradient = {Color3.fromRGB(255, 0, 0), Color3.fromRGB(255, 100, 100)}
    },
    ["ADMIN"] = {
        Color = Color3.fromRGB(45, 255, 255), -- Cyan
        Gradient = {Color3.fromRGB(0, 200, 255), Color3.fromRGB(0, 255, 150)}
    },
    ["CONTRIBUTOR"] = {
        Color = Color3.fromRGB(255, 215, 0), -- Gold/Ice Base
        Gradient = {Color3.fromRGB(0, 255, 255), Color3.fromRGB(0, 100, 255)}
    }
}

function TagSystem.CreateTag(player, role)
    if not player or not player.Character or not RoleData[role] then return end
    
    local char = player.Character
    local head = char:WaitForChild("Head", 5)
    if not head then return end
    
    if head:FindFirstChild("LowHub_Tag") then head.LowHub_Tag:Destroy() end
    
    local data = RoleData[role]
    
    -- BILLBOARD GUI (Smaller & Tighter)
    local bb = Instance.new("BillboardGui")
    bb.Name = "LowHub_Tag"
    bb.Adornee = head
    bb.Size = UDim2.new(4.5, 0, 1.2, 0) -- Slightly larger for effects
    bb.StudsOffset = Vector3.new(0, 3.5, 0)
    bb.AlwaysOnTop = true
    bb.MaxDistance = 100
    bb.LightInfluence = 0 -- CRITICAL: MOVES IT TO NEON/UNLIT
    bb.Parent = head
    
    -- ROLE TEXT
    local rLabel = Instance.new("TextLabel")
    rLabel.Text = role:upper()
    rLabel.Size = UDim2.new(1, 0, 1, 0)
    rLabel.BackgroundTransparency = 1
    rLabel.Font = Enum.Font.FredokaOne
    rLabel.TextScaled = true
    rLabel.ZIndex = 2
    rLabel.Parent = bb
    
    -- Role Specific Styles
    if role == "OWNER" then
        rLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        
        
    else
        rLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    end
    
    -- TEXT STROKE (Black Outline)
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 3
    stroke.Color = Color3.fromRGB(0, 0, 0)
    stroke.Parent = rLabel
    
    -- GRADIENT
    local grad = Instance.new("UIGradient")
    grad.Rotation = 0
    
    local colors = {}
    
    if role == "OWNER" then
         -- Starter Rainbow
         colors = {
            ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 0, 0)),
            ColorSequenceKeypoint.new(1.0, Color3.fromRGB(255, 0, 0))
         }
    elseif role == "ADMIN" then
        -- "Inferno" (Fire Effect - Dark Red/Orange/Yellow)
        colors = {
            ColorSequenceKeypoint.new(0.0, Color3.fromRGB(100, 0, 0)),
            ColorSequenceKeypoint.new(0.3, Color3.fromRGB(255, 60, 0)),
            ColorSequenceKeypoint.new(0.6, Color3.fromRGB(255, 200, 0)),
            ColorSequenceKeypoint.new(0.8, Color3.fromRGB(255, 60, 0)),
            ColorSequenceKeypoint.new(1.0, Color3.fromRGB(100, 0, 0))
        }
    elseif role == "CONTRIBUTOR" then
        -- "Diamond Ice" (Cyan/White/Blue)
        colors = {
            ColorSequenceKeypoint.new(0.0, Color3.fromRGB(0, 100, 200)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(150, 255, 255)),
            ColorSequenceKeypoint.new(1.0, Color3.fromRGB(0, 100, 200))
        }
    end
    
    if #colors > 0 then
        grad.Color = ColorSequence.new(colors)
    else
        grad.Color = ColorSequence.new(data.Color)
    end
    
    grad.Parent = rLabel

    -- ANIMATION LOOP
    task.spawn(function()
        local t = 0
        local rot = 0
        
        -- Get orbiters if they exist
        local o1 = bb:FindFirstChild("Orbital1")
        local o2 = bb:FindFirstChild("Orbital2")
        
        while bb and bb.Parent do
            local dt = RunService.Heartbeat:Wait()
            t = t + dt
            
            -- Float Tag
            bb.StudsOffset = Vector3.new(0, 3.5 + math.sin(t * 2) * 0.2, 0)
            
            if role == "OWNER" then
                -- SOUL FIRE (Blue/Purple Fire - Like Admin)
                
                -- 1. Blue Fire Gradient
                local t_slow = t * 0.8
                
                -- Vertical Scroll (Fire Effect)
                grad.Rotation = 90
                local offset = 1 - (t_slow % 2)
                grad.Offset = Vector2.new(0, offset)
                
                local c1 = Color3.fromRGB(0, 0, 0) -- Dark Base
                local c2 = Color3.fromRGB(0, 50, 255) -- Blue
                local c3 = Color3.fromRGB(0, 255, 255) -- Cyan
                
                grad.Color = ColorSequence.new{
                     ColorSequenceKeypoint.new(0.0, c1),
                     ColorSequenceKeypoint.new(0.2, c2), 
                     ColorSequenceKeypoint.new(0.5, c3),
                     ColorSequenceKeypoint.new(0.8, c2),
                     ColorSequenceKeypoint.new(1.0, c1)
                }
                
                -- 2. Cyan Pulse Stroke
                stroke.Color = Color3.fromRGB(0, 100, 255)
                stroke.Thickness = 2.5 + math.sin(t * 5) * 0.5
                
            elseif role == "ADMIN" then
                -- FIRE (Rising Flames)
                grad.Rotation = 90
                local offset = 1 - (t * 0.8 % 2)
                grad.Offset = Vector2.new(0, offset)
                
            elseif role == "CONTRIBUTOR" then
                -- BOUNCE (Ping Pong)
                grad.Rotation = 0
                local offset = math.sin(t * 2) * 0.8
                grad.Offset = Vector2.new(offset, 0)
            else
                 local offset = -1 + (t % 3)
                 grad.Offset = Vector2.new(offset, 0)
            end
        end
    end)
end

-- // AURA SYSTEM //
local AuraSystem = {}

function AuraSystem.CreateAura(player, role)
    if not player or not player.Character or not RoleData[role] then return end
    
    local char = player.Character
    local root = char:WaitForChild("HumanoidRootPart", 5)
    if not root then return end
    
    -- CLEANUP
    if char:FindFirstChild("LowHub_Highlight") then char.LowHub_Highlight:Destroy() end
    if root:FindFirstChild("LowHub_AuraParticles") then root.LowHub_AuraParticles:Destroy() end
    if root:FindFirstChild("LowHub_TrailAtt0") then root.LowHub_TrailAtt0:Destroy() end
    if root:FindFirstChild("LowHub_TrailAtt1") then root.LowHub_TrailAtt1:Destroy() end
    if root:FindFirstChild("LowHub_Trail") then root.LowHub_Trail:Destroy() end
    
    local data = RoleData[role]
    local color = data.Color
    
    -- 2. PARTICLES (Rising Energy)
    local pe = Instance.new("ParticleEmitter")
    pe.Name = "LowHub_AuraParticles"
    pe.Texture = "rbxassetid://243660364" -- Soft Ring/Glow Texture
    pe.Rate = 5
    pe.Lifetime = NumberRange.new(1.5, 2.5)
    pe.Speed = NumberRange.new(1, 2) -- Slow Rising
    pe.VelocitySpread = 0
    pe.SpreadAngle = Vector2.new(0, 0)
    pe.Acceleration = Vector3.new(0, 1, 0)
    pe.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.2, 0.5), -- Fade in
        NumberSequenceKeypoint.new(1, 1) -- Fade out
    }
    pe.Size = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 3),
        NumberSequenceKeypoint.new(1, 0) -- Shrink as it rises
    }
    pe.Color = ColorSequence.new(data.Color)
    pe.LockedToPart = true
    pe.Parent = root
    
    -- Role Specific Tweaks
    if role == "OWNER" then
        -- Soul Fire Aura (REFINED: Brighter, Smaller, Additive)
        pe.Texture = "rbxassetid://296874871" 
        pe.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 150, 255)), -- Bright Blue
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(100, 255, 255)), -- Bright Cyan
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)) -- Pure White
        }
        pe.Size = NumberSequence.new{
            NumberSequenceKeypoint.new(0, 1.5), -- Smaller Start
            NumberSequenceKeypoint.new(1, 0)
        }
        pe.LightEmission = 1 -- ADDITIVE BLENDING (Glows in Dark)
        pe.Speed = NumberRange.new(2, 4) 
        pe.Rate = 12
        

        
    elseif role == "ADMIN" then
        -- Blue Fire Aura
        pe.Texture = "rbxassetid://296874871" 
        pe.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 50, 255)), -- Deep Blue
            ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 255, 255)) -- Cyan
        }

    
    elseif role == "CONTRIBUTOR" then
        -- Ice Aura
        pe.Color = ColorSequence.new(Color3.fromRGB(0, 255, 255))
        
        -- SPEED TRAILS
        local att0 = Instance.new("Attachment")
        att0.Name = "LowHub_TrailAtt0"
        att0.Position = Vector3.new(0, 1, 0)
        att0.Parent = root
        
        local att1 = Instance.new("Attachment")
        att1.Name = "LowHub_TrailAtt1"
        att1.Position = Vector3.new(0, -1, 0)
        att1.Parent = root
        
        local trail = Instance.new("Trail")
        trail.Name = "LowHub_Trail"
        trail.Attachment0 = att0
        trail.Attachment1 = att1
        trail.Lifetime = 0.3
        trail.Texture = "rbxassetid://459263309"
        trail.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
        }
        trail.WidthScale = NumberSequence.new{
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(1, 0)
        }
        trail.Parent = root
    end
end

local function PromptAura()
    local p = game:GetService("Players").LocalPlayer
    local role = GetRole(p.Name)
    if not role then return end

    -- Only Prompt OWNER or ADMIN
    if role ~= "OWNER" and role ~= "ADMIN" then
        -- Auto-Enable for Contributors/others
        if p.Character then AuraSystem.CreateAura(p, role) end
        p.CharacterAdded:Connect(function()
             task.wait(1)
             AuraSystem.CreateAura(p, role)
        end)
        return
    end

    local sg = Instance.new("ScreenGui")
    sg.Name = "AuraPrompt"
    sg.Parent = game:GetService("CoreGui")
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 300, 0, 150)
    frame.Position = UDim2.new(0.5, -150, 0.5, -75)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    frame.BorderSizePixel = 2
    frame.BorderColor3 = Config.AccentColor
    frame.Parent = sg
    
    local title = Instance.new("TextLabel")
    title.Text = "LowHub Aura"
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    title.TextColor3 = Color3.new(1,1,1)
    title.Font = Config.Font
    title.TextSize = 18
    title.Parent = frame
    
    local desc = Instance.new("TextLabel")
    desc.Text = "Do you want to enable your cosmetic aura?"
    desc.Size = UDim2.new(1, -20, 0, 50)
    desc.Position = UDim2.new(0, 10, 0, 50)
    desc.BackgroundTransparency = 1
    desc.TextColor3 = Color3.new(0.8,0.8,0.8)
    desc.Font = Config.Font
    desc.TextSize = 16
    desc.Parent = frame
    
    local function click(val)
        sg:Destroy()
        if val then
             -- Enable
             if p.Character then AuraSystem.CreateAura(p, role) end
             p.CharacterAdded:Connect(function()
                 task.wait(1)
                 AuraSystem.CreateAura(p, role)
             end)
        end
    end
    
    local btnYes = Instance.new("TextButton")
    btnYes.Text = "Yes"
    btnYes.Size = UDim2.new(0.4, 0, 0, 35)
    btnYes.Position = UDim2.new(0.05, 0, 0.7, 0)
    btnYes.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
    btnYes.TextColor3 = Color3.new(1,1,1)
    btnYes.Font = Config.Font
    btnYes.TextSize = 16
    btnYes.Parent = frame
    btnYes.MouseButton1Click:Connect(function() click(true) end)
    
    local btnNo = Instance.new("TextButton")
    btnNo.Text = "No"
    btnNo.Size = UDim2.new(0.4, 0, 0, 35)
    btnNo.Position = UDim2.new(0.55, 0, 0.7, 0)
    btnNo.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    btnNo.TextColor3 = Color3.new(1,1,1)
    btnNo.Font = Config.Font
    btnNo.TextSize = 16
    btnNo.Parent = frame
    btnNo.MouseButton1Click:Connect(function() click(false) end)
end

local function ApplyTags()
    -- Apply to OTHERS immediately
    for _, p in pairs(game:GetService("Players"):GetPlayers()) do
        if p ~= game:GetService("Players").LocalPlayer then
             local role = GetRole(p.Name)
             if role then
                if p.Character then 
                    TagSystem.CreateTag(p, role) 
                    AuraSystem.CreateAura(p, role) -- Always show others
                end
                p.CharacterAdded:Connect(function()
                    task.wait(1)
                    TagSystem.CreateTag(p, role)
                    AuraSystem.CreateAura(p, role)
                end)
             end
        else
             -- Local Player: Just Tag, Aura handled by Prompt
             local role = GetRole(p.Name)
             if role then
                if p.Character then TagSystem.CreateTag(p, role) end
                p.CharacterAdded:Connect(function()
                    task.wait(1)
                    TagSystem.CreateTag(p, role)
                end)
             end
        end
    end
end

game:GetService("Players").PlayerAdded:Connect(function(p)
     local role = GetRole(p.Name)
     if role then
        p.CharacterAdded:Connect(function()
            task.wait(1)
            TagSystem.CreateTag(p, role)
            AuraSystem.CreateAura(p, role)
        end)
     end
end)

ApplyTags()
PromptAura()
LowHubLoaded = true -- Startup Complete
