-- Chargement de Fluent UI
local FluentUrl = "https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"
local success, Fluent = pcall(loadstring(game:HttpGet(FluentUrl)))

if not success then
    warn("[ERREUR] Échec du chargement de Fluent UI :", Fluent)
    return
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

local function getHRP()
    local character = player.Character or player.CharacterAdded:Wait()
    return character:WaitForChild("HumanoidRootPart")
end

local Window = Fluent:CreateWindow({
    Title = "King Legacy",
    SubTitle = "SD Team",
    TabWidth = 100,
    Size = UDim2.fromOffset(480, 300),
    Acrylic = false,
    Theme = "Darker",
    MinimizeKey = Enum.KeyCode.RightControl
})

local Tabs = {
    Info = Window:AddTab({ Title = "Info", Icon = "info" }),
    Main = Window:AddTab({ Title = "Main", Icon = "circle-ellipsis" }),
    Sea = Window:AddTab({ Title = "Sea", Icon = "waves" }),
    Misc = Window:AddTab({ Title = "Misc", Icon = "cog" })
}

-- Liste des quêtes
local Quests = {
    {
        Name = "Kill 4 Soldiers",
        BossName = "Soldier Lv. 1",
        Amount = 4,
        Rewards = { exp = 350, beli = 100 },
        Level = 0
    }
}

-- Utilitaires
local function getLevel()
    local stats = player:FindFirstChild("PlayerStats")
    if stats and stats:FindFirstChild("lvl") then
        local lvl = stats.lvl.Value
        warn("[INFO] Niveau actuel :", lvl)
        return lvl
    end
    warn("[WARN] Niveau introuvable.")
    return 0
end

local function getBestQuest()
    local lvl = getLevel()
    local bestQuest
    for _, quest in ipairs(Quests) do
        if quest.Level <= lvl and (not bestQuest or quest.Level > bestQuest.Level) then
            bestQuest = quest
        end
    end
    if bestQuest then
        warn("[INFO] Meilleure quête :", bestQuest.Name, "(Requis :", bestQuest.Level .. ")")
    else
        warn("[WARN] Aucune quête trouvée pour ton niveau.")
    end
    return bestQuest
end

local function takeQuest(name)
    warn("[INFO] Prise de quête :", name)
    local success, err = pcall(function()
        ReplicatedStorage:WaitForChild("Chest"):WaitForChild("Remotes"):WaitForChild("Functions"):WaitForChild("Quest"):InvokeServer("take", name)
    end)
    if success then
        warn("[SUCCÈS] Quête prise :", name)
    else
        warn("[ERREUR] Échec prise de quête :", err)
    end
end

local function GetBossModel(name)
    local bosses = findBoss(name)
    for _, boss in ipairs(bosses) do
        if boss:FindFirstChild("Humanoid") and boss.Humanoid.Health > 0 then
            return boss
        end
    end
    return nil
end

local function findBoss(name)
    local found = {}
    for _, folderName in ipairs({ "Monster", "Boss", "Mon" }) do
        local folder = workspace:FindFirstChild(folderName)
        if folder then
            for _, model in ipairs(folder:GetChildren()) do
                if model:IsA("Model") and model.Name == name and model:FindFirstChild("HumanoidRootPart") and model:FindFirstChild("Humanoid") then
                    table.insert(found, model)
                end
            end
        end
    end
    return found
end

local function IsBossAlive(name)
    local bosses = findBoss(name)
    for _, boss in ipairs(bosses) do
        if boss:FindFirstChild("Humanoid") and boss.Humanoid.Health > 0 then
            return true
        end
    end
    return false
end

local isTeleporting = false

local function TeleportToBossLoop(bossName)
    if isTeleporting then return end
    isTeleporting = true

    task.spawn(function()
        while autoFarm and IsBossAlive(bossName) do
            local character = player.Character or player.CharacterAdded:Wait()
            local hrp = character:FindFirstChild("HumanoidRootPart")
            local boss = GetBossModel(bossName)

            if boss and boss:FindFirstChild("HumanoidRootPart") and hrp then
                local bossHRP = boss.HumanoidRootPart
                local headPos = boss:FindFirstChild("Head") and boss.Head.Position or bossHRP.Position
                local lookAtCFrame = CFrame.new(headPos + Vector3.new(0, 5, 0), headPos)
                hrp.CFrame = lookAtCFrame * CFrame.new(0, 0, 2)
                print("[🌀] TP au-dessus de :", bossName)
            else
                warn("[❓] Boss non trouvé ou HRP manquant :", bossName)
            end

            task.wait()
        end
        isTeleporting = false
    end)
end

-- Boucle AutoFarm
local autoFarm = false

task.spawn(function()
    while true do
        if autoFarm then
            local stats = player:FindFirstChild("PlayerStats")
            if stats then
                local currentQuest = stats:FindFirstChild("CurrentQuest")
                if not currentQuest or currentQuest.Value == "" then
                    local best = getBestQuest()
                    if best then takeQuest(best.Name) end
                else
                    local questName = currentQuest.Value
                    local questData
                    for _, q in ipairs(Quests) do
                        if q.Name == questName then
                            questData = q
                            break
                        end
                    end

                    if questData then
                        local bosses = findBoss(questData.BossName)
                        for _, boss in ipairs(bosses) do
                            if boss:FindFirstChild("Humanoid") and boss.Humanoid.Health > 0 then
                                TeleportToBossLoop(boss.Name)
                                break
                            end
                        end
                    else
                        warn("[WARN] Quête inconnue :", questName)
                    end
                end
            end
        end
        task.wait(0.5)
    end
end)

-- Toggle Fluent UI
Tabs.Main:AddToggle("AutoFarm", {
    Title = "Auto Farm LVL",
    Default = false,
    Callback = function(state)
        autoFarm = state
        warn("[TOGGLE] Auto Farm", state and "Activé" or "Désactivé")
    end
})
