local shared = odh_shared_plugins

local my_own_tab = shared.CreateTab("Anti Aim", "/popora4ka/Disablerendering/refs/heads/main/Antiaim")

local my_own_section = my_own_tab:AddSection("Anti Aim", "PROTECTS YOU FROM AIMBOTS")

local run_service = game:GetService("RunService")
local players_service = game:GetService("Players")
local local_player = players_service.LocalPlayer

local anti_aim = {}
local local_parts = {}
local local_fps = 200
local stomping = false
local purchasing = nil

local render_stepped = run_service.RenderStepped
local render_stepped_wait = render_stepped.Wait

local velocity_desync_type = "jitter"
local velocity_desync_rotate = false

local function round(num, decimals)
    local mult = 10^(decimals or 0)
    return math.floor(num * mult + 0.5 - (num < 0 and 1 or 0)) / mult
end

local fake_position_sender_rate_old
pcall(function()
    fake_position_sender_rate_old = getfflag("S2PhysicsSenderRate")
end)

local function remove(tbl, index)
    local length = #tbl
    for i = index, length - 1 do
        tbl[i] = tbl[i + 1]
    end
    tbl[length] = nil
end

local do_velocity_desync = function(dt, hrp)
    if hrp and not stomping and not purchasing and (getgenv().FLING_ACTIVE or 0) == 0 then
        pcall(function() setfflag("S2PhysicsSenderRate", tostring(round(local_fps, 1))) end)
        pcall(function() sethiddenproperty(hrp, "NetworkIsSleeping", false) end)
        local old_lin = hrp.AssemblyLinearVelocity
        local old_ang = hrp.AssemblyAngularVelocity
        local vel = velocity_desync_type == "skyrocket" and Vector3.new(0, 16384, 0)
            or velocity_desync_type == "overflow" and Vector3.new(
                math.random(-9223372036854775808, 9223372036854775807),
                math.random(-9223372036854775808, 9223372036854775807),
                math.random(-9223372036854775808, 9223372036854775807)
            )
            or velocity_desync_type == "jitter" and Vector3.new(
                math.random(1,2) == 1 and -300 or 300,
                math.random(1,2) == 1 and -300 or 300,
                math.random(1,2) == 1 and -300 or 300
            )
            or velocity_desync_type == "scatter" and Vector3.new(
                math.random(1,2) == 1 and -16384 or 16384,
                math.random(1,2) == 1 and -14384 or 16384,
                math.random(1,2) == 1 and -16384 or 16384
            )
            or velocity_desync_type == "freeze" and Vector3.zero
            or Vector3.zero

        getgenv().VELOCITY_DESYNC_UNTIL = os.clock() + 0.35
        hrp.AssemblyLinearVelocity = vel
        if velocity_desync_rotate then
            hrp.AssemblyAngularVelocity = vel
        end

        render_stepped_wait(render_stepped)
        hrp.AssemblyLinearVelocity = old_lin
        hrp.AssemblyAngularVelocity = old_ang
        getgenv().VELOCITY_DESYNC_UNTIL = os.clock() + 0.05
    end
end

local function velocity_desync_enable(value)
    for i = 1, #anti_aim do
        if anti_aim[i] == do_velocity_desync then
            remove(anti_aim, i)
            break
        end
    end
    if value then
        anti_aim[#anti_aim+1] = do_velocity_desync
    else
        pcall(function() setfflag("S2PhysicsSenderRate", fake_position_sender_rate_old or "15") end)
    end
end

local heartbeat_conn = run_service.Heartbeat:Connect(function(dt)
    local_fps = 1 / (os.clock() - (os.clock() - dt))
    local hrp = local_parts["HumanoidRootPart"]

    for i = 1, #anti_aim do
        local func = anti_aim[i]
        if func then
            task.spawn(func, dt, hrp)
        end
    end
end)

local function init_character(character)
    if not character then return end
    local hrp = character:WaitForChild("HumanoidRootPart", 5)
    if hrp then
        local_parts["HumanoidRootPart"] = hrp
    end
end

init_character(local_player.Character)
local char_added_conn = local_player.CharacterAdded:Connect(init_character)

my_own_section:AddLabel("Credits: @anya_bts")

my_own_section:AddToggle("enabled", function(state)
    velocity_desync_enable(state)
    if state then
        shared.Notify("Anti Aim enabled", 2)
    else
        shared.Notify("Anti Aim disabled", 2)
    end
end)

my_own_section:AddDropdown("mode", {"jitter", "scatter", "skyrocket", "overflow", "freeze"}, function(selected)
    velocity_desync_type = selected
    shared.Notify("Anti Aim mode: " .. selected, 2)
end)

my_own_section:AddToggle("rotate", function(state)
    velocity_desync_rotate = state
    if state then
        shared.Notify("Rotation enabled", 2)
    else
        shared.Notify("Rotation disabled", 2)
    end
end)

my_own_section:AddButton("unload", function()
    velocity_desync_enable(false)
    if heartbeat_conn then
        pcall(function() heartbeat_conn:Disconnect() end)
        heartbeat_conn = nil
    end
    if char_added_conn then
        pcall(function() char_added_conn:Disconnect() end)
        char_added_conn = nil
    end
    shared.Notify("Anti Aim unloaded", 2)
end)
