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
        BossName = "Soldier [Lv. 1]",
        Amount = 4,
        Rewards = { exp = 350, beli = 100 },
        Level = 0
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

local function findAllBosses(name)
    local bosses = {}
    local monsterFolder = workspace:FindFirstChild("Monster")
    if not monsterFolder then
        return bosses
    end

    for _, folderName in ipairs({ "Boss", "Mon" }) do
        local folder = monsterFolder:FindFirstChild(folderName)
        if folder then
            for _, model in ipairs(folder:GetChildren()) do
                if model:IsA("Model") and model.Name == name then
                    if model:FindFirstChild("HumanoidRootPart") and model:FindFirstChild("Humanoid") then
                        table.insert(bosses, model)
                    end
                end
            end
        end
    end

    return bosses
end


local function getAliveBosses(name)
    local bosses = findAllBosses(name)
    local alive = {}
    for _, boss in ipairs(bosses) do
        if boss.Humanoid.Health > 0 then
            table.insert(alive, boss)
        end
    end
    return alive
end

local function teleportAndTrackBosses(bossName)
    local character = player.Character or player.CharacterAdded:Wait()
    local hrp = character:FindFirstChild("HumanoidRootPart")

    if not hrp then
        warn("[TP BOSS] Pas de HumanoidRootPart pour le joueur.")
        return
    end

    while true do
        local aliveBosses = getAliveBosses(bossName)

        if #aliveBosses == 0 then
            warn("[TP BOSS] Aucun boss vivant trouvé pour :", bossName)
            break
        end

        -- On prend le premier boss vivant (tu peux modifier pour prendre un autre si tu veux)
        local boss = aliveBosses[1]
        local bossHRP = boss:FindFirstChild("HumanoidRootPart")
        if not bossHRP then
            warn("[TP BOSS] Boss sans HumanoidRootPart :", bossName)
            -- Enlever ce boss de la liste et continuer
            table.remove(aliveBosses, 1)
            continue
        end

        -- Teleport initial
        hrp.CFrame = bossHRP.CFrame * CFrame.new(0, 5, 0)
        warn("[TP BOSS] Téléporté sur boss :", bossName, "Position :", tostring(hrp.Position))

        -- Tant que boss est vivant, on reste dessus et spam la position
        while boss.Humanoid.Health > 0 do
            hrp.CFrame = bossHRP.CFrame * CFrame.new(0, 5, 0) -- Update position au cas où boss bouge
            warn("[TP BOSS] Suivi boss :", bossName, "Position :", tostring(hrp.Position))
            task.wait(0.3)
        end

        warn("[TP BOSS] Boss mort, passage au suivant :", bossName)
        -- Boucle continue et reprendra avec le boss suivant vivant
    end
end


task.spawn(function()
    while true do
        if autoFarm then
            local stats = player:FindFirstChild("PlayerStats")
            if not stats then
                warn("[AUTO FARM] Pas de PlayerStats trouvé")
                task.wait(1)
                continue
            end

            local currentQuest = stats:FindFirstChild("CurrentQuest")
            if not currentQuest or currentQuest.Value == "" then
                warn("[AUTO FARM] Pas de quête en cours, prise d'une nouvelle...")
                local best = getBestQuest()
                if best then
                    warn("[AUTO FARM] Quête choisie :", best.Name)
                    takeQuest(best.Name)
                else
                    warn("[AUTO FARM] Aucune quête disponible selon le niveau")
                end
                currentBoss = nil
            else
                local questName = currentQuest.Value
                print("[AUTO FARM] Quête actuelle :", questName)

                local questData = nil
                for _, q in ipairs(Quests) do
                    if q.Name == questName then
                        questData = q
                        break
                    end
                end

                if not questData then
                    warn("[AUTO FARM] Quête inconnue :", questName)
                    currentBoss = nil
                    task.wait(1)
                    continue
                end

                local aliveBosses = getAliveBosses(questData.BossName)
                print("[AUTO FARM] Boss vivants trouvés pour '" .. questData.BossName .. "' :", #aliveBosses)

                if #aliveBosses > 0 then
                    if not currentBoss or currentBoss.Humanoid.Health <= 0 then
                        currentBoss = aliveBosses[1]
                        print("[AUTO FARM] Nouveau boss suivi :", currentBoss.Name)
                    end

                    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                    if not hrp then
                        warn("[AUTO FARM] Pas de HumanoidRootPart pour le joueur")
                        task.wait(1)
                        continue
                    end

                    local bossHRP = currentBoss and currentBoss:FindFirstChild("HumanoidRootPart")
                    if not bossHRP then
                        warn("[AUTO FARM] Pas de HumanoidRootPart pour le boss")
                        currentBoss = nil
                        task.wait(1)
                        continue
                    end

                    print("[AUTO FARM] Téléportation vers boss...")
                    hrp.CFrame = bossHRP.CFrame * CFrame.new(0, 5, 0)
                    print("[AUTO FARM] Position joueur après TP :", tostring(hrp.Position))

                else
                    warn("[AUTO FARM] Aucun boss vivant actuellement pour :", questData.BossName)
                    currentBoss = nil
                end
            end
        else
            currentBoss = nil
        end

        task.wait(0.3)
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
