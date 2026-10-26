-- SubspaceTripmines script
local stuff = {
    AllowedUsers = {
        'Sammywammylol502',
        -- game.Players.LocalPlayer.Name comment this out if u wants tripminesz
    }
}

function allowed(func)
    if table.find(stuff, game.Players.LocalPlayer.Name) then
        if not func then
            return true
        else
            func()
        end
    end
    return false
end

repeat task.wait() until game:IsLoaded()

function rootClean(v)
    if type(v) == 'function' then
        pcall(v)
        return
    end
    if type(v) == 'table' then
        for _, value in pairs(v) do
            rootClean(value)
        end
        table.clear(v)
        return
    end
    pcall(function() task.cancel(v) end)
    pcall(function() v:Stop()       end)
    pcall(function() v:Disconnect() end)
    pcall(function() v:Cancel()     end)
    pcall(function() v:Disable()    end)
    pcall(function() v:Remove()     end)
    pcall(function() v:Destroy()    end)
end

if shared.CleanupTable then
    for _, v in shared.CleanupTable do
        rootClean(v)
    end
end

shared.CleanupTable = {}

function clean(obj, boolFunc)
    table.insert(shared.CleanupTable, obj)
    if boolFunc ~= nil then
        task.spawn(function()
            pcall(function()
                repeat task.wait() until boolFunc() == false
                rootClean(obj)
            end)
        end)
    end
    return obj
end

local Object = {}
do
    function new(class, props)
        local obj = Instance.new(class)
        for k, v in props do
            obj[k] = v
        end
        return obj
    end

    Object.new = new
end

local Create = {}
do
    function Create.tool(props)
        return clean(Object.new('Tool', props))
    end

    function Create.part(props)
        return Object.new('Part', props)
    end

    function Create.mesh(props)
        return Object.new('SpecialMesh', props)
    end

    function Create.sound(soundId, parent, looped)
        return Object.new('Sound', {
            SoundId = soundId,
            Looped = looped or false,
            Parent = parent
        })
    end

    function Create.objectValue(name, value, parent)
        return Object.new('ObjectValue', {
            Name = name,
            Value = value,
            Parent = parent
        })
    end

    function Create.explosion(position, radius, pressure, parent)
        return Object.new('Explosion', {
            BlastRadius = radius,
            BlastPressure = pressure,
            Position = position,
            Parent = parent
        })
    end

    function Create.sparkles(parent)
        return Object.new('Sparkles', {
            Parent = parent
        })
    end

    function Create.fade(part, from, to, step, delay)
        for i = from, to, step do
            part.Transparency = i
            wait(delay)
        end
    end

    function Create.bomb(handle, position, creator)
        local bomb = handle:Clone()
        bomb.CanCollide = true
        bomb.Transparency = 0
        bomb.Position = position
        bomb.Size = Vector3.new(2,2,2)
        bomb.Name = "SubspaceTripmine"
        bomb.Locked = true
        Create.objectValue("creator", creator, bomb)
        bomb.Parent = game.Workspace
        return clean(bomb)
    end
end

local playersService = game:GetService('Players')
local httpService = game:GetService('HttpService')

local lplr = playersService.LocalPlayer
local backpack = lplr.Backpack
local character = lplr.Character

local Net = {}
do
    local topic = 'ILOVEMYLIFErbxsubspacetripminestscriptILOVEMYLIFElifeishealingrightnow'
    local base = 'https://ntfy.sh/' .. topic

    local requestFn = request or http_request or (syn and syn.request) or (http and http.request)
    local running = true
    local handlers = {}

    clean(function()
        running = false
    end)

    function Net.on(kind, fn)
        handlers[kind] = fn
    end

    function Net.send(kind, payload)
        task.spawn(function()
            pcall(requestFn, {
                Url = base,
                Method = 'POST',
                Body = httpService:JSONEncode({
                    type = kind,
                    from = lplr.Name,
                    payload = payload
                })
            })
        end)
    end

    local function handle(raw)
        local ok, event = pcall(function()
            return httpService:JSONDecode(raw)
        end)
        if not ok or type(event) ~= 'table' or event.event ~= 'message' then return end

        local ok2, data = pcall(function()
            return httpService:JSONDecode(event.message)
        end)
        if not ok2 or type(data) ~= 'table' then return end
        if data.from == lplr.Name then return end

        local handler = handlers[data.type]
        if handler then
            task.spawn(handler, data.from, data.payload)
        end
    end

    local connected = false

    if WebSocket and WebSocket.connect then
        local ok, socket = pcall(WebSocket.connect, 'wss://ntfy.sh/' .. topic .. '/ws')
        if ok and socket then
            connected = true
            socket.OnMessage:Connect(handle)
            clean(function()
                pcall(function() socket:Close() end)
            end)
        end
    end

    if not connected then
        task.spawn(function()
            local since = tostring(os.time())
            while running do
                local ok, res = pcall(requestFn, {
                    Url = base .. '/json?poll=1&since=' .. since,
                    Method = 'GET'
                })
                if ok and res and res.Body then
                    for line in string.gmatch(res.Body, '[^\n]+') do
                        local ok2, event = pcall(function()
                            return httpService:JSONDecode(line)
                        end)
                        if ok2 and type(event) == 'table' and event.id then
                            since = event.id
                            handle(line)
                        end
                    end
                end
                task.wait(2)
            end
        end)
    end
end

local subspaceTool = Create.tool({
    Name = 'SubspaceTripmine',
    TextureId = 'rbxassetid://11987521',
    Grip = CFrame.new(-0.5, 0, 0) * CFrame.Angles(0, math.rad(-90), 0),
    Parent = backpack
})

local handle = Create.part({
    Name = 'Handle',
    Color = Color3.fromRGB(255, 0, 191),
    Size = Vector3.new(2, 2, 2),
    Parent = subspaceTool
})

local mesh = Create.mesh({
    Name = 'Mesh',
    TextureId = 'rbxassetid://11954766',
    MeshId = 'rbxassetid://11954776',
    Scale = Vector3.new(0.7, 0.7, 0.7),
    Parent = handle
})

do -- Scripts
    local script = {}
    script.Parent = subspaceTool
    do -- PlantBomb.lua
        Tool = script.Parent

        local mines = {}

        function onPlayerBlownUp(part, distance, creator)

            if (part:getMass() < 300) then
                part.BrickColor = BrickColor.new(1032)
                local s = Create.sparkles(part)
                game.Debris:AddItem(s, 5)
            end


            if creator ~= nil and part.Name == "Head" then
                local humanoid = part.Parent.Humanoid
                tagHumanoid(humanoid, creator)
            end
        end

        function tagHumanoid(humanoid, creator)
            if creator ~= nil then
                local new_tag = creator:clone()
                new_tag.Parent = humanoid
            end
        end

        function untagHumanoid(humanoid)
            if humanoid ~= nil then
                local tag = humanoid:findFirstChild("creator")
                if tag ~= nil then
                    tag.Parent = nil
                end
            end
        end

        function runMine(Mine, id)
            local DunDun = Create.sound("http://www.roblox.com/asset/?id=11984254", Mine)

            local SubspaceExplosion = Create.sound("http://www.roblox.com/asset/?id=11984351", Mine)

            local Calibrate = Create.sound("http://www.roblox.com/asset/?id=11956590", Mine, true)
            Calibrate:Play()

            local calibration_time = 2
            local cur_time = 0
            local max_life = 120
            local calibrated = false
            local exploded = false

            local connection = nil

            local function activateMine()
                Create.fade(Mine, 0, 1, .1, .05)
                calibrated = true
                Calibrate:Stop()
            end

            local function pulse()
                DunDun:Play()

                Create.fade(Mine, .9, .5, -.1, .05)

                Create.fade(Mine, .5, 1, .1, .05)
            end

            local function explode()
                if exploded then return end
                exploded = true
                mines[id] = nil
                connection:Disconnect()

                Create.fade(Mine, 1, 0, -.2, .05)
                SubspaceExplosion:Play()

                local e = Create.explosion(Mine.Position, 16, 1000000, Mine)

                local creator = Mine:FindFirstChild("creator")

                e.Hit:Connect(function(part, distance)  onPlayerBlownUp(part, distance, creator) end)


                Create.fade(Mine, 0, 1, .2, .05)
                wait(4)
                Mine:Remove()
            end

            local function update()
                if (calibrated == false) then
                    if (Mine.Velocity.Magnitude > .1) then
                        cur_time = 0
                    end

                    if (cur_time > calibration_time) then
                        activateMine()
                    end
                else
                    -- calibrated mine
                    if (math.random(1,20) == 2) then
                        pulse()
                    end

                    if (cur_time > max_life) then
                        exploded = true
                        mines[id] = nil
                        pulse()
                        Mine:Remove()
                    end
                end
            end


            local function OnTouch(part)
                if exploded then return end
                if (calibrated == false) then
                    cur_time = 0
                else
                    Net.send('explode', { id = id, job = game.JobId })
                    explode()
                end
            end

            mines[id] = { explode = explode }

            connection = clean(Mine.Touched:Connect(OnTouch))

            task.spawn(function()
                while Mine.Parent and not exploded do
                    update()
                    local e = wait(.5)
                    cur_time = cur_time + e
                end
            end)
        end

        function plant(pos)

            local vCharacter = Tool.Parent
            local vPlayer = game.Players:playerFromCharacter(vCharacter)

            local spawnPos = vCharacter.PrimaryPart.Position

            local id = lplr.UserId .. '-' .. tostring(tick())

            local bomb = Create.bomb(Tool.Handle, pos, vPlayer)

            Net.send('plant', {
                id = id,
                job = game.JobId,
                x = pos.X,
                y = pos.Y,
                z = pos.Z
            })

            task.spawn(runMine, bomb, id)
        end

        Net.on('plant', function(from, p)
            if type(p) ~= 'table' or p.job ~= game.JobId or mines[p.id] then return end

            local creator = playersService:FindFirstChild(from)
            local bomb = Create.bomb(handle, Vector3.new(p.x, p.y, p.z), creator)

            task.spawn(runMine, bomb, p.id)
        end)

        Net.on('explode', function(from, p)
            if type(p) ~= 'table' or p.job ~= game.JobId then return end

            local mine = mines[p.id]
            if mine then
                task.spawn(mine.explode)
            end
        end)


        Tool.Enabled = true
        function onActivated()

            if not Tool.Enabled then
                return
            end

            Tool.Enabled = false

            local character = Tool.Parent;
            local humanoid = character.Humanoid
            if humanoid == nil then
                print("Humanoid not found")
                return 
            end

            local targetPos = humanoid.TargetPoint

            Tool.Handle.Transparency = 1
            plant(Tool.Handle.Position)
            wait(3)
            Tool.Handle.Transparency = 0

            Tool.Enabled = true
        end


        clean(script.Parent.Activated:Connect(onActivated))
    end

    do -- Local Gui.lua
        local Tool = script.Parent;

        enabled = true
        function onButton1Down(mouse)
            if not enabled then
                return
            end

            enabled = false
            mouse.Icon = "rbxasset://textures\\ArrowFarCursor.png"

            wait(3)
            mouse.Icon = "rbxasset://textures\\ArrowCursor.png"
            enabled = true

        end

        function onEquippedLocal(mouse)

            if mouse == nil then
                print("Mouse not found")
                return 
            end

            mouse.Icon = "rbxasset://textures\\ArrowCursor.png"
            mouse.Button1Down:connect(function() onButton1Down(mouse) end)
        end

        Tool.Equipped:connect(onEquippedLocal)        
    end
end

if not allowed() then
    subspaceTool.Parent = game.ReplicatedStorage
end
