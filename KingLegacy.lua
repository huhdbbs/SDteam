-- Chargement Fluent UI
local FluentUrl = "https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"
local success, FluentOrError = pcall(loadstring(game:HttpGet(FluentUrl)))
if not success or type(FluentOrError) ~= "table" then
    warn("[ERREUR] Échec du chargement de Fluent UI :", FluentOrError)
    return
end
local Fluent = FluentOrError

-- Services Roblox
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local workspace = game:GetService("Workspace")
local player = Players.LocalPlayer

local autoFarm = false

-- Liste des quêtes (exemple, à adapter selon ton jeu)
local Quests = {
    {
        Name = "Kill 4 Soldiers",
        BossName = "Soldier Lv. 1",
        Amount = 4,
        Rewards = { exp = 350, beli = 100 },
        Level = 0
    },
    {
        Name = "Kill 6 Soldiers",
        BossName = "Soldier Lv. 2",
        Amount = 6,
        Rewards = { exp = 500, beli = 200 },
        Level = 10
    },
    -- Ajoute tes quêtes ici...
}

-- Récupérer niveau joueur
local function getLevel()
    local stats = player:FindFirstChild("PlayerStats")
    if stats and stats:FindFirstChild("lvl") then
        return stats.lvl.Value
    end
    return 0
end

-- Trouver la meilleure quête disponible selon niveau
local function getBestQuest()
    local lvl = getLevel()
    local bestQuest = nil
    for _, quest in ipairs(Quests) do
        if quest.Level <= lvl then
            if not bestQuest or quest.Level > bestQuest.Level then
                bestQuest = quest
            end
        end
    end
    return bestQuest
end

-- Prendre une quête via Remote
local function takeQuest(name)
    local success, err = pcall(function()
        ReplicatedStorage:WaitForChild("Chest"):WaitForChild("Remotes"):WaitForChild("Functions"):WaitForChild("Quest"):InvokeServer("take", name)
    end)
    if not success then
        warn("[ERREUR] Échec prise de quête :", err)
    end
end

-- Trouver boss dans workspace.Monster.{Boss,Mon}
local function findBoss(name)
    local monsterFolder = workspace:FindFirstChild("Monster")
    if not monsterFolder then
        return nil
    end

    for _, folderName in ipairs({ "Boss", "Mon" }) do
        local folder = monsterFolder:FindFirstChild(folderName)
        if folder then
            for _, model in ipairs(folder:GetChildren()) do
                if model:IsA("Model") and model.Name == name then
                    if model:FindFirstChild("HumanoidRootPart") and model:FindFirstChild("Humanoid") then
                        return model
                    end
                end
            end
        end
    end
    return nil
end

local function isBossAlive(name)
    local boss = findBoss(name)
    if boss and boss.Humanoid.Health > 0 then
        return true
    end
    return false
end

local function teleportToBoss(bossName)
    local character = player.Character or player.CharacterAdded:Wait()
    local hrp = character:FindFirstChild("HumanoidRootPart")
    local boss = findBoss(bossName)
    if boss and hrp then
        local bossHRP = boss:FindFirstChild("HumanoidRootPart")
        if bossHRP then
            hrp.CFrame = bossHRP.CFrame * CFrame.new(0, 5, 0) -- tp juste au-dessus
        end
    end
end

-- Boucle AutoFarm
task.spawn(function()
    while true do
        if autoFarm then
            local stats = player:FindFirstChild("PlayerStats")
            if stats then
                local currentQuest = stats:FindFirstChild("CurrentQuest")
                if not currentQuest or currentQuest.Value == "" then
                    local best = getBestQuest()
                    if best then
                        takeQuest(best.Name)
                        warn("[AUTO FARM] Quête prise :", best.Name)
                    end
                else
                    local questName = currentQuest.Value
                    local questData = nil
                    for _, q in ipairs(Quests) do
                        if q.Name == questName then
                            questData = q
                            break
                        end
                    end

                    if questData then
                        if isBossAlive(questData.BossName) then
                            teleportToBoss(questData.BossName)
                        else
                            warn("[AUTO FARM] Boss pas encore spawné :", questData.BossName)
                        end
                    else
                        warn("[AUTO FARM] Quête inconnue :", questName)
                    end
                end
            end
        end
        task.wait(0.5)
    end
end)

-- Création de la fenêtre UI
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
    Misc = Window:AddTab({ Title = "Misc", Icon = "cog" }),
}

-- Toggle AutoFarm
Tabs.Main:AddToggle("AutoFarm", {
    Title = "Auto Farm LVL",
    Default = false,
    Callback = function(state)
        autoFarm = state
        warn("[TOGGLE] Auto Farm", state and "Activé" or "Désactivé")
    end
})
