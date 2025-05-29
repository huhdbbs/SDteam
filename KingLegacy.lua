-- Chargement de Fluent UI
local FluentUrl = "https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"
local success, FluentOrError = pcall(loadstring(game:HttpGet(FluentUrl)))

if not success or type(FluentOrError) ~= "table" then
    warn("[ERREUR] Échec du chargement de Fluent UI :", FluentOrError)
    return
end
local Fluent = FluentOrError

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

local autoFarm = false -- Déclaration avant usage

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

local function findBoss(name)
    local found = {}
    print("[DEBUG] Recherche du boss :", name)

    local monsterFolder = workspace:FindFirstChild("Monster")
    if not monsterFolder then
        warn("❌ Dossier 'Monster' introuvable dans Workspace")
        return found
    end

    for _, subFolderName in ipairs({ "Boss", "Mon" }) do
        local subFolder = monsterFolder:FindFirstChild(subFolderName)
        if subFolder then
            print("🔎 Recherche dans dossier :", subFolderName)
            for _, model in ipairs(subFolder:GetChildren()) do
                if model:IsA("Model") then
                    print(" - Modèle trouvé :", model.Name)
                    if model.Name == name then
                        if model:FindFirstChild("HumanoidRootPart") and model:FindFirstChild("Humanoid") then
                            print("✅ Boss correspondant trouvé :", model.Name)
                            table.insert(found, model)
                        else
                            warn("⚠️ Boss trouvé mais manque HRP ou Humanoid :", model.Name)
                        end
                    end
                end
            end
        else
            print("📁 Dossier absent :", subFolderName)
        end
    end

    if #found == 0 then
        warn("❌ Aucun boss trouvé avec le nom exact :", name)
    end

    return found
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

local function IsBossAlive(name)
    local bosses = findBoss(name)
    for _, boss in ipairs(bosses) do
        if boss:FindFirstChild("Humanoid") and boss.Humanoid.Health > 0 then
            return true
        end
    end
    return false
end

-- Nouveau TP une seule fois
local function TeleportToBossOnce(bossName)
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
end

-- Boucle AutoFarm mise à jour
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
                        if IsBossAlive(questData.BossName) then
                            TeleportToBossOnce(questData.BossName)
                        else
                            print("[⏳] Boss pas encore spawné :", questData.BossName)
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


-- Ajout du toggle en sécurité
local successToggle, err = pcall(function()
    Tabs.Main:AddToggle("AutoFarm", {
        Title = "Auto Farm LVL",
        Default = false,
        Callback = function(state)
            autoFarm = state
            warn("[TOGGLE] Auto Farm", state and "Activé" or "Désactivé")
        end
    })
end)
if not successToggle then
    warn("[ERREUR] Impossible de créer le toggle AutoFarm :", err)
end
