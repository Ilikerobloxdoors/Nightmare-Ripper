-- NIGHTMARE RIPPER

pcall(function()
    local G = getgenv()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local TweenService = game:GetService("TweenService")
    local Debris = game:GetService("Debris")
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")

    -- CONFIGURATION
    local MODEL_URL =
        "https://raw.githubusercontent.com/Ilikerobloxdoors/Nightmare-Ripper/main/NIGHTMARE%20RIPPER.rbxm"

    local DARK_RED = Color3.fromRGB(100, 0, 0)
    local ARRIVAL_SPEED = 0.2

    -- CUSTOM ACHIEVEMENT
    local CustomAchievements
    local achievementGranted = false

    local function LoadAchievements()
        local success, result = pcall(function()
            return loadstring(game:HttpGet(
                "https://raw.githubusercontent.com/RegularVynixu/DOORS-Custom-Achievements/main/init.luau"
            ))()
        end)

        if success and result then
            CustomAchievements = result
            print("[Nightmare Ripper] Achievement library loaded.")
        else
            warn(
                "[Nightmare Ripper] Achievement library failed to load:",
                result
            )
        end
    end

    LoadAchievements()

    local function GrantRipperAchievement()
        if achievementGranted then
            return
        end

        if not CustomAchievements then
            warn("[Nightmare Ripper] Achievement library unavailable.")
            return
        end

        local success, err = pcall(function()
            CustomAchievements:Grant({
                Identifier = "NightmareRipperSurvivor",
                Title = "Im Runnin Way Faster!",
                Desc = "That Was not the same...",
                Reason = "Survive And Encounter Nightmare Ripper",
                Image = "rbxassetid://140450481946419"
            }, {
                CheckOwned = true,
                Remember = true
            })
        end)

        if success then
            achievementGranted = true
            print("[Nightmare Ripper] Achievement grant requested!")
        else
            warn(
                "[Nightmare Ripper] Achievement grant failed:",
                tostring(err)
            )
        end
    end

    -- GITHUB MODEL LOADER
    G.LoadGithubModel = function(url, retryCount)
        retryCount = retryCount or 0

        if retryCount >= 3 then
            warn("[Nightmare Ripper] Failed to load model after 3 attempts.")
            return nil
        end

        local httpRequest = request or http_request
        local assetLoader = getcustomasset or getsynasset

        if not writefile or not assetLoader
            or not httpRequest or not isfile then
            warn("[Nightmare Ripper] Required executor functions unavailable.")
            return nil
        end

        local hash = 0
        for i = 1, #url do
            hash = (hash * 31 + string.byte(url, i)) % 4294967296
        end

        local fileName = "nightmare_ripper_" .. tostring(hash) .. ".rbxm"

        local function loadModel()
            local ok, assetId = pcall(assetLoader, fileName)
            if not ok or not assetId then
                return nil
            end

            local loaded, objects = pcall(function()
                return game:GetObjects(assetId)
            end)

            if loaded and objects and objects[1] then
                return objects[1]:Clone()
            end

            return nil
        end

        local existsOK, exists = pcall(isfile, fileName)

        if existsOK and exists then
            local cached = loadModel()

            if cached then
                print("[Nightmare Ripper] Cached model loaded.")
                return cached
            end

            if delfile then
                pcall(delfile, fileName)
            end
        end

        local ok, response = pcall(function()
            return httpRequest({
                Url = url,
                Method = "GET"
            })
        end)

        if not ok then
            warn(
                "[Nightmare Ripper] Download request failed:",
                tostring(response)
            )
            return G.LoadGithubModel(url, retryCount + 1)
        end

        if not response or response.StatusCode ~= 200 then
            warn(
                "[Nightmare Ripper] HTTP status:",
                response and response.StatusCode or "No response"
            )
            return nil
        end

        if not response.Body or #response.Body == 0 then
            warn("[Nightmare Ripper] Downloaded model is empty.")
            return nil
        end

        local saved, saveError = pcall(writefile, fileName, response.Body)

        if not saved then
            warn(
                "[Nightmare Ripper] Could not save model:",
                tostring(saveError)
            )
            return nil
        end

        local model = loadModel()

        if model then
            print("[Nightmare Ripper] Model downloaded and loaded.")
            return model
        end

        warn("[Nightmare Ripper] Model downloaded, but loading failed.")

        if delfile then
            pcall(delfile, fileName)
        end

        return G.LoadGithubModel(url, retryCount + 1)
    end

    -- RIPPER SPAWN
    local function Ripper()
        local breakMove = false
        local killed = false
        local player = Players.LocalPlayer

        local gameData = ReplicatedStorage:WaitForChild("GameData", 10)
        local latestRoom = gameData and gameData:FindFirstChild("LatestRoom")
        local currentRooms = workspace:FindFirstChild("CurrentRooms")

        if not latestRoom or not currentRooms then
            error("GameData, LatestRoom, or CurrentRooms not found.")
        end

        -- CAMERA SHAKER
        local shakerOK, cameraShaker = pcall(function()
            return require(ReplicatedStorage:WaitForChild("CameraShaker", 10))
        end)

        local camShake

        if shakerOK and cameraShaker then
            camShake = cameraShaker.new(
                Enum.RenderPriority.Camera.Value,
                function(cf)
                    local camera = workspace.CurrentCamera
                    if camera then
                        camera.CFrame = camera.CFrame * cf
                    end
                end
            )

            pcall(function()
                camShake:Start()
                camShake:Shake(cameraShaker.Presets.Earthquake)
            end)
        end

        -- LOAD MODEL
        local entity = G.LoadGithubModel(MODEL_URL)

        if not entity then
            error("Nightmare Ripper model failed to load.")
        end

        entity.Parent = workspace

        local entityPart = entity:FindFirstChildWhichIsA("BasePart", true)

        if not entityPart then
            entity:Destroy()
            error("The model contains no BasePart.")
        end
  -- DARK-RED LIGHTING
        local tweenLights = TweenInfo.new(1)
        local color = {Color = DARK_RED}

        for _, object in ipairs(currentRooms:GetDescendants()) do
            if object:IsA("Light") then
                TweenService:Create(object, tweenLights, color):Play()

                if object.Parent
                    and object.Parent.Name == "LightFixture"
                    and object.Parent:IsA("BasePart") then
                    TweenService:Create(
                        object.Parent,
                        tweenLights,
                        color
                    ):Play()
                end
            end
        end

        -- ARRIVAL SOUND
        local spawnSound = Instance.new("Sound")
        spawnSound.Name = "NightmareRipperArrival"
        spawnSound.Parent = workspace
        spawnSound.SoundId = "rbxassetid://9125713501"
        spawnSound.PlaybackSpeed = ARRIVAL_SPEED
        spawnSound.Volume = 10

        local pitchShift = Instance.new("PitchShiftSoundEffect")
        pitchShift.Octave = 0.875
        pitchShift.Parent = spawnSound

        spawnSound:Play()
        Debris:AddItem(spawnSound, 30)

        -- SLAM SOUND
        local slam = Instance.new("Sound")
        slam.Parent = entityPart
        slam.Volume = 10
        slam.SoundId = "rbxassetid://1837829565"

        -- TARGET DETECTION
        local function canSeeTarget(target, distance)
            if killed then
                return false
            end

            local root = target and target:FindFirstChild("HumanoidRootPart")
            if not root then
                return false
            end

            local direction = root.Position - entityPart.Position

            if direction.Magnitude == 0 then
                killed = true
                return true
            end

            local ray = Ray.new(
                entityPart.Position,
                direction.Unit * distance
            )

            local hit = workspace:FindPartOnRay(ray, entityPart)

            if hit and hit:IsDescendantOf(target) then
                killed = true
                return true
            end

            return false
        end

        -- JUMPSCARE
        local function runJumpscare(targetPlayer)
            local character = targetPlayer.Character
            if not character then return end

            local root = character:FindFirstChild("HumanoidRootPart")
            local humanoid = character:FindFirstChildWhichIsA("Humanoid")

            if not root or not humanoid then return end

            local gui = Instance.new("ScreenGui")
            gui.Name = "Noise"
            gui.IgnoreGuiInset = true
            gui.Parent = targetPlayer:WaitForChild("PlayerGui")

            local img = Instance.new("ImageLabel")
            img.Size = UDim2.new(1, 0, 1, 0)
            img.BackgroundTransparency = 1
            img.Image = "rbxassetid://236542974"
            img.ImageTransparency = 1
            img.Parent = gui

            local clone = entityPart:Clone()
            clone.Parent = workspace
            clone.Position = entityPart.Position

            for _, item in ipairs(clone:GetDescendants()) do
                if item:IsA("ParticleEmitter") then
                    item.Rate = 9999
                elseif item:IsA("Sound") then
                    item.Volume = 0
                end
            end

            entity:Destroy()

            local static = Instance.new("Sound")
            static.Parent = workspace
            static.SoundId = "rbxassetid://372770465"
            static.Volume = 10
            static.PlaybackSpeed = 0.7

            local camera = workspace.CurrentCamera

            local anchor = Instance.new("Part")
            anchor.Name = "ripperAnchor"
            anchor.Anchored = true
            anchor.CanCollide = false
            anchor.Transparency = 1
            anchor.CFrame = camera.CFrame
            anchor.Parent = workspace

            root.Anchored = true
            camera.CameraType = Enum.CameraType.Scriptable

            local viewLoop = true

            task.spawn(function()
                while viewLoop and anchor.Parent do
                    camera.CFrame = anchor.CFrame

                    img.Image = "rbxassetid://" .. ({
                        8482795900,
                        236542974,
                        184251462,
                        236777652
                    })[math.random(1, 4)]

                    RunService.RenderStepped:Wait()
                end
            end)

            TweenService:Create(
                anchor,
                TweenInfo.new(0.3),
                {
                    CFrame = CFrame.lookAt(
                        anchor.Position,
                        clone.Position
                    )
                }
            ):Play()

            task.wait(1)

            TweenService:Create(
                img,
                TweenInfo.new(2),
                {ImageTransparency = 0}
            ):Play()

            static:Play()
            task.wait(2)

            viewLoop = false

            TweenService:Create(
                img,
                TweenInfo.new(1),
                {ImageTransparency = 1}
            ):Play()

            static:Destroy()
            root.Anchored = false
            camera.CameraType = Enum.CameraType.Custom

            pcall(function()
                ReplicatedStorage.GameStats[
                    "Player_" .. targetPlayer.Name
                ].Total.DeathCause.Value = "Ripper"
            end)

            pcall(function()
                local bricks = ReplicatedStorage:FindFirstChild("Bricks")
                local hint = bricks and bricks:FindFirstChild("DeathHint")

                if hint then
                    firesignal(hint.OnClientEvent, {
                        "You died to who you call Ripper...",
                        "It's presence is known by the red lights...",
                        "Hide when this happens!"
                    })
                end
            end)

            humanoid:TakeDamage(100)

            task.delay(3, function()
                if gui.Parent then gui:Destroy() end
                if clone.Parent then clone:Destroy() end
                if anchor.Parent then anchor:Destroy() end
            end)
        end

        -- PLAYER MONITOR
        task.spawn(function()
            while entity.Parent and entityPart.Parent do
                task.wait(0.2)

                local character = player.Character
                local root = character
                    and character:FindFirstChild("HumanoidRootPart")

                if root then
                    if canSeeTarget(character, 50)
                        and not character:GetAttribute("Hiding") then
                        breakMove = true
                        task.spawn(runJumpscare, player)
                        break
                    end

                    if (entityPart.Position - root.Position).Magnitude <= 60
                        and camShake then
                        pcall(function()
                            camShake:ShakeOnce(15, 25, 0, 2, 1, 6)
                        end)
                    end
                end

                if breakMove then
                    break
                end
            end
        end)
        -- MOVEMENT SOUND
        local ambush = entityPart:FindFirstChild("Ambush")

        if not ambush or not ambush:IsA("Sound") then
            warn("[Nightmare Ripper] Ambush sound not found in the model.")
        else
            ambush:Stop()
            ambush.Volume = 10

            task.wait(8)

            if not entity.Parent then return end

            ambush:Play()

            TweenService:Create(
                ambush,
                TweenInfo.new(6),
                {Volume = 0.8}
            ):Play()
        end

        -- MOVEMENT
        local speed = 99999
        local storedSpeed = 100
        local height = Vector3.new(0, 1.2, 0)

        for i = 1, latestRoom.Value do
            if breakMove or not entity.Parent then
                break
            end

            local room = currentRooms:FindFirstChild(tostring(i))
            local nodes = room and room:FindFirstChild("Nodes")

            if nodes then
                for index = 1, #nodes:GetChildren() do
                    if breakMove or not entity.Parent then
                        break
                    end

                    local node = nodes:FindFirstChild(tostring(index))

                    if node and node:IsA("BasePart") then
                        local distance =
                            (entityPart.Position - node.Position).Magnitude

                        local movement = TweenService:Create(
                            entityPart,
                            TweenInfo.new(
                                distance / speed,
                                Enum.EasingStyle.Linear,
                                Enum.EasingDirection.Out
                            ),
                            {CFrame = node.CFrame + height}
                        )

                        movement:Play()
                        movement.Completed:Wait()

                        speed = storedSpeed

                        pcall(function()
                            if room.Name == tostring(latestRoom.Value) then
                                room.Door.ClientOpen:FireServer()
                            end
                        end)
                    end
                end
            end
        end

        -- SURVIVAL CHECK AND ACHIEVEMENT
        local character = player.Character
        local humanoid = character
            and character:FindFirstChildWhichIsA("Humanoid")

        local survived =
            not breakMove
            and not killed
            and entity.Parent ~= nil
            and humanoid ~= nil
            and humanoid.Health > 0

        if survived then
            GrantRipperAchievement()
        else
            print(
                "[Nightmare Ripper] Achievement not granted: "
                .. "encounter interrupted or player did not survive."
            )
        end

        -- ENDING EFFECTS
        if camShake and cameraShaker then
            pcall(function()
                camShake:Shake(cameraShaker.Presets.Explosion)
            end)
        end

        slam:Play()
        task.wait(1)

        if entityPart.Parent then
            entityPart.Anchored = false
            entityPart.CanCollide = false
        end

        Debris:AddItem(entity, 5)
    end

    -- ERROR REPORTING
    task.spawn(function()
        local ok, err = xpcall(Ripper, debug.traceback)

        if not ok then
            warn("[NIGHTMARE RIPPER ERROR] " .. tostring(err))
        end
    end)
end)
