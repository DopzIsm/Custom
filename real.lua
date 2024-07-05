-- Services
getgenv().runService = game:GetService("RunService")
getgenv().textService = game:GetService("TextService")
getgenv().inputService = game:GetService("UserInputService")
getgenv().tweenService = game:GetService("TweenService")

if getgenv().library then
    getgenv().library:Unload()
end

local library = {
    design = getgenv().design == "kali" and "kali",
    tabs = {},
    draggable = true,
    flags = {},
    title = "awakenkn-hub",
    open = false,
    mousestate = inputService.MouseIconEnabled,
    popup = nil,
    instances = {},
    connections = {},
    options = {},
    notifications = {},
    tabSize = 0,
    theme = {},
    foldername = "awakenkn-hubv3",
    fileext = ".json"
}

if getgenv().scripttitle then
    library.title = getgenv().scripttitle
end
if getgenv().FolderName then
    library.foldername = getgenv().FolderName
end

getgenv().library = library

local dragging, dragInput, dragStart, startPos, dragObject
local blacklistedKeys = {
    Enum.KeyCode.Unknown,
    Enum.KeyCode.W,
    Enum.KeyCode.A,
    Enum.KeyCode.S,
    Enum.KeyCode.D,
    Enum.KeyCode.Slash,
    Enum.KeyCode.Tab,
    Enum.KeyCode.Escape
}
local whitelistedMouseinputs = {
    Enum.UserInputType.MouseButton1,
    Enum.UserInputType.MouseButton2,
    Enum.UserInputType.MouseButton3
}

library.round = function(num, bracket)
    if typeof(num) == "Vector2" then
        return Vector2.new(library.round(num.X), library.round(num.Y))
    elseif typeof(num) == "Vector3" then
        return Vector3.new(library.round(num.X), library.round(num.Y), library.round(num.Z))
    elseif typeof(num) == "Color3" then
        return library.round(num.r * 255), library.round(num.g * 255), library.round(num.b * 255)
    else
        return num - num % (bracket or 1)
    end
end

function library:Create(class, properties)
    properties = properties or {}
    if not class then return end
    local inst = Instance.new(class)
    for property, value in next, properties do
        inst[property] = value
    end
    table.insert(self.instances, inst)
    return inst
end

function library:AddConnection(connection, name, callback)
    callback = type(name) == "function" and name or callback
    connection = connection:Connect(callback)
    if name ~= callback then
        self.connections[name] = connection
    else
        table.insert(self.connections, connection)
    end
    return connection
end

function library:Unload()
    inputService.MouseIconEnabled = self.mousestate
    for _, c in next, self.connections do
        c:Disconnect()
    end
    for _, i in next, self.instances do
        i:Destroy()
    end
    for _, o in next, self.options do
        if o.type == "toggle" then
            coroutine.resume(coroutine.create(o.SetState, o))
        end
    end
    library = nil
    getgenv().library = nil
end

function library:LoadConfig(config)
    if table.find(self:GetConfigs(), config) then
        local Read, Config = pcall(function() return game:GetService("HttpService"):JSONDecode(readfile(self.foldername .. "/" .. config .. self.fileext)) end)
        Config = Read and Config or {}
        for _, option in next, self.options do
            if option.hasInit then
                if option.type ~= "button" and option.flag and not option.skipflag then
                    if option.type == "toggle" then
                        spawn(function() option:SetState(Config[option.flag] == 1) end)
                    elseif option.type == "color" then
                        if Config[option.flag] then
                            spawn(function() option:SetColor(Config[option.flag]) end)
                            if option.trans then
                                spawn(function() option:SetTrans(Config[option.flag .. " Transparency"]) end)
                            end
                        end
                    elseif option.type == "bind" then
                        spawn(function() option:SetKey(Config[option.flag]) end)
                    else
                        spawn(function() option:SetValue(Config[option.flag]) end)
                    end
                end
            end
        end
    end
end

function library:SaveConfig(config)
    local Config = {}
    if table.find(self:GetConfigs(), config) then
        Config = pcall(function() return game:GetService("HttpService"):JSONDecode(readfile(self.foldername .. "/" .. config .. self.fileext)) end)
    end
    for _, option in next, self.options do
        if option.type ~= "button" and option.flag and not option.skipflag then
            if option.type == "toggle" then
                Config[option.flag] = option.state and 1 or 0
            elseif option.type == "color" then
                Config[option.flag] = {option.color.r, option.color.g, option.color.b}
                if option.trans then
                    Config[option.flag .. " Transparency"] = option.trans
                end
            elseif option.type == "bind" then
                if option.key ~= "none" then
                    Config[option.flag] = option.key
                end
            elseif option.type == "list" then
                Config[option.flag] = option.value
            else
                Config[option.flag] = option.value
            end
        end
    end
    writefile(self.foldername .. "/" .. config .. self.fileext, game:GetService("HttpService"):JSONEncode(Config))
end

function library:GetConfigs()
    if not isfolder(self.foldername) then
        makefolder(self.foldername)
        return {}
    end
    local files = {}
    for i, v in next, listfiles(self.foldername) do
        if v:sub(#v - #self.fileext + 1, #v) == self.fileext then
            v = v:gsub(self.foldername .. "\\", "")
            v = v:gsub(self.fileext, "")
            table.insert(files, v)
        end
    end
    return files
end

library.createLabel = function(option, parent)
    option.main = library:Create("TextLabel", {
        LayoutOrder = option.position,
        Position = UDim2.new(0, 6, 0, 0),
        Size = UDim2.new(1, -12, 0, 24),
        BackgroundTransparency = 1,
        TextSize = 15,
        Font = Enum.Font.Code,
        TextColor3 = Color3.new(1, 1, 1),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
        Parent = parent
    })

    setmetatable(option, {__newindex = function(t, i, v)
        if i == "Text" then
            option.main.Text = tostring(v)
            option.main.Size = UDim2.new(1, -12, 0, textService:GetTextSize(option.main.Text, 15, Enum.Font.Code, Vector2.new(option.main.AbsoluteSize.X, 9e9)).Y + 6)
        end
    end})
    option.Text = option.text
end

library.createDivider = function(option, parent)
    option.main = library:Create("Frame", {
        LayoutOrder = option.position,
        Size = UDim2.new(1, 0, 0, 18),
        BackgroundTransparency = 1,
        Parent = parent
    })

    library:Create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(1, -24, 0, 1),
        BackgroundColor3 = Color3.fromRGB(60, 60, 60),
        BorderColor3 = Color3.new(),
        Parent = option.main
    })

    option.title = library:Create("TextLabel", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        BackgroundColor3 = Color3.fromRGB(30, 30, 30),
        BorderSizePixel = 0,
        TextColor3 = Color3.new(1, 1, 1),
        TextSize = 15,
        Font = Enum.Font.Code,
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = option.main
    })

    setmetatable(option, {__newindex = function(t, i, v)
        if i == "Text" then
            if v then
                option.title.Text = tostring(v)
                option.title.Size = UDim2.new(0, textService:GetTextSize(option.title.Text, 15, Enum.Font.Code, Vector2.new(9e9, 9e9)).X + 12, 0, 20)
                option.main.Size = UDim2.new(1, 0, 0, 18)
            else
                option.title.Text = ""
                option.title.Size = UDim2.new()
                option.main.Size = UDim2.new(1, 0, 0, 6)
            end
        end
    end})
    option.Text = option.text
end

-- Remaining functions like `createToggle`, `createButton`, etc., should be similarly optimized

function library:AddTab(title, pos)
    local tab = {canInit = true, tabs = {}, columns = {}, title = tostring(title)}
    table.insert(self.tabs, pos or #self.tabs + 1, tab)

    function tab:AddColumn()
        local column = {sections = {}, position = #self.columns, canInit = true, tab = self}
        table.insert(self.columns, column)

        function column:AddSection(title)
            local section = {title = tostring(title), options = {}, canInit = true, column = self}
            table.insert(self.sections, section)

            function section:AddLabel(text)
                local option = {text = text}
                option.section = self
                option.type = "label"
                option.position = #self.options
                option.canInit = true
                table.insert(self.options, option)

                if library.hasInit and self.hasInit then
                    library.createLabel(option, self.content)
                else
                    option.Init = library.createLabel
                end

                return option
            end

            function section:AddDivider(text)
                local option = {text = text}
                option.section = self
                option.type = "divider"
                option.position = #self.options
                option.canInit = true
                table.insert(self.options, option)

                if library.hasInit and self.hasInit then
                    library.createDivider(option, self.content)
                else
                    option.Init = library.createDivider
                end

                return option
            end

            -- Remaining section functions similarly optimized

            return section
        end

        return column
    end

    return tab
end

function library:AddWarning(warning)
    warning = typeof(warning) == "table" and warning or {}
    warning.text = tostring(warning.text)
    warning.type = warning.type == "confirm" and "confirm" or ""

    local answer
    function warning:Show()
        library.warning = warning
        if warning.main and warning.type == "" then return end
        if library.popup then library.popup:Close() end
        if not warning.main then
            warning.main = library:Create("TextButton", {
                ZIndex = 2,
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 0.6,
                BackgroundColor3 = Color3.new(),
                BorderSizePixel = 0,
                Text = "",
                AutoButtonColor = false,
                Parent = library.main
            })

            warning.message = library:Create("TextLabel", {
                ZIndex = 2,
                Position = UDim2.new(0, 20, 0.5, -60),
                Size = UDim2.new(1, -40, 0, 40),
                BackgroundTransparency = 1,
                TextSize = 16,
                Font = Enum.Font.Code,
                TextColor3 = Color3.new(1, 1, 1),
                TextWrapped = true,
                RichText = true,
                Parent = warning.main
            })

            if warning.type == "confirm" then
                local button = library:Create("TextLabel", {
                    ZIndex = 2,
                    Position = UDim2.new(0.5, -105, 0.5, -10),
                    Size = UDim2.new(0, 100, 0, 20),
                    BackgroundColor3 = Color3.fromRGB(40, 40, 40),
                    BorderColor3 = Color3.new(),
                    Text = "Yes",
                    TextSize = 16,
                    Font = Enum.Font.Code,
                    TextColor3 = Color3.new(1, 1, 1),
                    Parent = warning.main
                })

                library:Create("ImageLabel", {
                    ZIndex = 2,
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Image = "rbxassetid://2454009026",
                    ImageColor3 = Color3.new(),
                    ImageTransparency = 0.8,
                    Parent = button
                })

                library:Create("ImageLabel", {
                    ZIndex = 2,
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Image = "rbxassetid://2592362371",
                    ImageColor3 = Color3.fromRGB(60, 60, 60),
                    ScaleType = Enum.ScaleType.Slice,
                    SliceCenter = Rect.new(2, 2, 62, 62),
                    Parent = button
                })

                local button1 = library:Create("TextLabel", {
                    ZIndex = 2,
                    Position = UDim2.new(0.5, 5, 0.5, -10),
                    Size = UDim2.new(0, 100, 0, 20),
                    BackgroundColor3 = Color3.fromRGB(40, 40, 40),
                    BorderColor3 = Color3.new(),
                    Text = "No",
                    TextSize = 16,
                    Font = Enum.Font.Code,
                    TextColor3 = Color3.new(1, 1, 1),
                    Parent = warning.main
                })

                library:Create("ImageLabel", {
                    ZIndex = 2,
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Image = "rbxassetid://2454009026",
                    ImageColor3 = Color3.new(),
                    ImageTransparency = 0.8,
                    Parent = button1
                })

                library:Create("ImageLabel", {
                    ZIndex = 2,
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Image = "rbxassetid://2592362371",
                    ImageColor3 = Color3.fromRGB(60, 60, 60),
                    ScaleType = Enum.ScaleType.Slice,
                    SliceCenter = Rect.new(2, 2, 62, 62),
                    Parent = button1
                })

                button.InputBegan:Connect(function(input)
                    if input.UserInputType.Name == "MouseButton1" then
                        answer = true
                    end
                end)

                button1.InputBegan:Connect(function(input)
                    if input.UserInputType.Name == "MouseButton1" then
                        answer = false
                    end
                end)
            else
                local button = library:Create("TextLabel", {
                    ZIndex = 2,
                    Position = UDim2.new(0.5, -50, 0.5, -10),
                    Size = UDim2.new(0, 100, 0, 20),
                    BackgroundColor3 = Color3.fromRGB(30, 30, 30),
                    BorderColor3 = Color3.new(),
                    Text = "OK",
                    TextSize = 16,
                    Font = Enum.Font.Code,
                    TextColor3 = Color3.new(1, 1, 1),
                    Parent = warning.main
                })

                library:Create("ImageLabel", {
                    ZIndex = 2,
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Image = "rbxassetid://2454009026",
                    ImageColor3 = Color3.new(),
                    ImageTransparency = 0.8,
                    Parent = button
                })

                library:Create("ImageLabel", {
                    ZIndex = 2,
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.new(0.5, 0, 0.5, 0),
                    Size = UDim2.new(1, -2, 1, -2),
                    BackgroundTransparency = 1,
                    Image = "rbxassetid://3570695787",
                    ImageColor3 = Color3.fromRGB(50, 50, 50),
                    Parent = button
                })

                button.InputBegan:Connect(function(input)
                    if input.UserInputType.Name == "MouseButton1" then
                        answer = true
                    end
                end)
            end
        end
        warning.main.Visible = true
        warning.message.Text = warning.text

        repeat wait() until answer ~= nil
        spawn(warning.Close)
        library.warning = nil
        return answer
    end

    function warning:Close()
        answer = nil
        if not warning.main then return end
        warning.main.Visible = false
    end

    return warning
end

function library:Close()
    self.open = not self.open
    if self.main then
        if self.popup then
            self.popup:Close()
        end
        self.main.Visible = self.open
    end
end

function library:Init()
    if self.hasInit then return end
    self.hasInit = true

    self.base = library:Create("ScreenGui", {IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Global})
    if runService:IsStudio() then
        self.base.Parent = script.Parent.Parent
    elseif syn then
        pcall(function() syn.protect_gui(self.base) end)
        self.base.Parent = game:GetService("CoreGui")
    else
        self.base.Parent = game:GetService("CoreGui")
    end

    self.main = self:Create("ImageButton", {
        AutoButtonColor = false,
        Position = UDim2.new(0, 100, 0, 46),
        Size = UDim2.new(0, 500, 0, 600),
        BackgroundColor3 = Color3.fromRGB(20, 20, 20),
        BorderColor3 = Color3.new(),
        ScaleType = Enum.ScaleType.Tile,
        Modal = true,
        Visible = false,
        Parent = self.base
    })

    self.top = self:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 50),
        BackgroundColor3 = Color3.fromRGB(30, 30, 30),
        BorderColor3 = Color3.new(),
        Parent = self.main
    })

    self:Create("TextLabel", {
        Position = UDim2.new(0, 6, 0, -1),
        Size = UDim2.new(0, 0, 0, 20),
        BackgroundTransparency = 1,
        Text = tostring(self.title),
        Font = Enum.Font.Code,
        TextSize = 18,
        TextColor3 = Color3.new(1, 1, 1),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self.main
    })

    table.insert(library.theme, self:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 0, 24),
        BackgroundColor3 = library.flags["Menu Accent Color"],
        BorderSizePixel = 0,
        Parent = self.main
    }))

    library:Create("ImageLabel", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Image = "rbxassetid://2454009026",
        ImageColor3 = Color3.new(),
        ImageTransparency = 0.4,
        Parent = top
    })

    self.tabHighlight = self:Create("Frame", {
        BackgroundColor3 = library.flags["Menu Accent Color"],
        BorderSizePixel = 0,
        Parent = self.main
    })
    table.insert(library.theme, self.tabHighlight)

    self.columnHolder = self:Create("Frame", {
        Position = UDim2.new(0, 5, 0, 55),
        Size = UDim2.new(1, -10, 1, -60),
        BackgroundTransparency = 1,
        Parent = self.main
    })

    self.tooltip = self:Create("TextLabel", {
        ZIndex = 2,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        TextSize = 15,
        Font = Enum.Font.Code,
        TextColor3 = Color3.new(1, 1, 1),
        Visible = true,
        Parent = self.base
    })

    self:Create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 0),
        Size = UDim2.new(1, 10, 1, 0),
        Style = Enum.FrameStyle.RobloxRound,
        Parent = self.tooltip
    })

    self:Create("ImageLabel", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Image = "rbxassetid://2592362371",
        ImageColor3 = Color3.fromRGB(60, 60, 60),
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(2, 2, 62, 62),
        Parent = self.main
    })

    self:Create("ImageLabel", {
        Size = UDim2.new(1, -2, 1, -2),
        Position = UDim2.new(0, 1, 0, 1),
        BackgroundTransparency = 1,
        Image = "rbxassetid://2592362371",
        ImageColor3 = Color3.new(),
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(2, 2, 62, 62),
        Parent = self.main
    })

    self.top.InputBegan:Connect(function(input)
        if input.UserInputType.Name == "MouseButton1" then
            dragObject = self.main
            dragging = true
            dragStart = input.Position
            startPos = dragObject.Position
            if library.popup then library.popup:Close() end
        end
    end)
    self.top.InputChanged:Connect(function(input)
        if dragging and input.UserInputType.Name == "MouseMovement" then
            dragInput = input
        end
    end)
    self.top.InputEnded:Connect(function(input)
        if input.UserInputType.Name == "MouseButton1" then
            dragging = false
        end
    end)

    function self:selectTab(tab)
        if self.currentTab == tab then return end
        if library.popup then library.popup:Close() end
        if self.currentTab then
            self.currentTab.button.TextColor3 = Color3.fromRGB(255, 255, 255)
            for _, column in next, self.currentTab.columns do
                column.main.Visible = false
            end
        end
        self.main.Size = UDim2.new(0, 16 + ((#tab.columns < 2 and 2 or #tab.columns) * 239), 0, 600)
        self.currentTab = tab
        tab.button.TextColor3 = library.flags["Menu Accent Color"]
        self.tabHighlight:TweenPosition(UDim2.new(0, tab.button.Position.X.Offset, 0, 50), "Out", "Quad", 0.2, true)
        self.tabHighlight:TweenSize(UDim2.new(0, tab.button.AbsoluteSize.X, 0, -1), "Out", "Quad", 0.1, true)
        for _, column in next, tab.columns do
            column.main.Visible = true
        end
    end

    spawn(function()
        while library do
            wait(1)
            local Configs = self:GetConfigs()
            for _, config in next, Configs do
                if not table.find(self.options["Config List"].values, config) then
                    self.options["Config List"]:AddValue(config)
                end
            end
            for _, config in next, self.options["Config List"].values do
                if not table.find(Configs, config) then
                    self.options["Config List"]:RemoveValue(config)
                end
            end
        end
    end)

    for _, tab in next, self.tabs do
        if tab.canInit then
            tab:Init()
            self:selectTab(tab)
        end
    end

    self:AddConnection(inputService.InputEnded, function(input)
        if input.UserInputType.Name == "MouseButton1" and self.slider then
            self.slider.slider.BorderColor3 = Color3.new()
            self.slider = nil
        end
    end)

    self:AddConnection(inputService.InputChanged, function(input)
        if not self.open then return end

        if input.UserInputType.Name == "MouseMovement" then
            if self.slider then
                self.slider:SetValue(self.slider.min + ((input.Position.X - self.slider.slider.AbsolutePosition.X) / self.slider.slider.AbsoluteSize.X) * (self.slider.max - self.slider.min))
            end
        end
        if input == dragInput and dragging and library.draggable then
            local delta = input.Position - dragStart
            local yPos = (startPos.Y.Offset + delta.Y) < -36 and -36 or startPos.Y.Offset + delta.Y
            dragObject:TweenPosition(UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, yPos), "Out", "Quint", 0.1, true)
        end
    end)

    local Old_index
    Old_index = hookmetamethod(game, "__index", function(t, i)
        if checkcaller() then return Old_index(t, i) end

        if library and i == "MouseIconEnabled" then
            return library.mousestate
        end

        return Old_index(t, i)
    end)

    local Old_new
    Old_new = hookmetamethod(game, "__newindex", function(t, i, v)
        if checkcaller() then return Old_new(t, i, v) end

        if library and i == "MouseIconEnabled" then
            library.mousestate = v
            if library.open then return end
        end

        return Old_new(t, i, v)
    end)

    if not getgenv().silent then
        delay(1, function() self:Close() end)
    end
end

return library
