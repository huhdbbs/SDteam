local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

-- Services Roblox
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local player = Players.LocalPlayer



-- Création de la fenêtre UI avec Fluent
print("[INIT] Création de l'interface utilisateur")
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

-- Toggle AutoFarm dans l'onglet Main
Tabs.Main:AddToggle("AutoFarm", {
    Title = "Auto Farm LVL",
    Default = false,
    Callback = function(state)
        autoFarm = state
        warn("[TOGGLE] Auto Farm", state and "Activé" or "Désactivé")
    end
})

print("[INIT] Script chargé et prêt")



local autoFarm = false
local currentBoss = nil

-- Liste des quêtes (exemple, adapte selon ton jeu)
local Quests = {
    {
        Name = "Kill 4 Soldiers",
        BossName = "Soldier [Lv. 1]",
        Amount = 4,
        Rewards = { exp = 350, beli = 100 },
        Level = 0
    },
    -- Ajoute ici tes quêtes supplémentaires
}

-- Fonction pour récupérer le niveau du joueur
local function getLevel()
    print("[DEBUG] getLevel appelé")
    local stats = player:FindFirstChild("PlayerStats")
    if stats then
        local lvl = stats:FindFirstChild("lvl")
        if lvl then
            print("[DEBUG] Niveau trouvé :", lvl.Value)
            return lvl.Value
        end
    end
    warn("[WARN] PlayerStats ou lvl non trouvé")
    return 0
end

-- Trouver la meilleure quête disponible selon le niveau du joueur
local function getBestQuest()
    print("[DEBUG] getBestQuest appelé")
    local lvl = getLevel()
    print("[DEBUG] Niveau joueur :", lvl)
    local bestQuest = nil
    for _, quest in ipairs(Quests) do
        print("[DEBUG] Vérification quête :", quest.Name, "niveau requis:", quest.Level)
        if quest.Level <= lvl then
            if not bestQuest or quest.Level > bestQuest.Level then
                bestQuest = quest
                print("[DEBUG] Nouvelle meilleure quête trouvée :", quest.Name)
            end
        end
    end
    if bestQuest then
        print("[DEBUG] Meilleure quête sélectionnée :", bestQuest.Name)
    else
        warn("[WARN] Aucune quête disponible pour le niveau", lvl)
    end
    return bestQuest
end

-- Prendre une quête via Remote
local function takeQuest(name)
    print("[DEBUG] Prise de quête :", name)
    local success, err = pcall(function()
        ReplicatedStorage:WaitForChild("Chest"):WaitForChild("Remotes"):WaitForChild("Functions"):WaitForChild("Quest"):InvokeServer("take", name)
    end)
    if not success then
        warn("[ERREUR] Échec prise de quête :", err)
    else
        print("[DEBUG] Quête prise avec succès :", name)
    end
end

-- Trouver tous les boss avec un nom donné
local function findAllBosses(name)
    print("[DEBUG] Recherche de tous les boss nommés :", name)
    local bosses = {}
    local monsterFolder = Workspace:FindFirstChild("Monster")
    if not monsterFolder then
        warn("[WARN] Dossier Monster introuvable")
        return bosses
    end

    for _, folderName in ipairs({ "Boss", "Mon" }) do
        local folder = monsterFolder:FindFirstChild(folderName)
        if folder then
            for _, model in ipairs(folder:GetChildren()) do
                if model:IsA("Model") and model.Name == name then
                    if model:FindFirstChild("HumanoidRootPart") and model:FindFirstChild("Humanoid") then
                        table.insert(bosses, model)
                        print("[DEBUG] Boss trouvé :", model.Name)
                    else
                        warn("[WARN] Boss sans HumanoidRootPart ou Humanoid :", model.Name)
                    end
                end
            end
        else
            print("[DEBUG] Dossier", folderName, "introuvable dans Monster")
        end
    end

    print("[DEBUG] Nombre de boss trouvés :", #bosses)
    return bosses
end

-- Filtrer les boss vivants
local function getAliveBosses(name)
    local bosses = findAllBosses(name)
    local alive = {}
    for _, boss in ipairs(bosses) do
        if boss.Humanoid.Health > 0 then
            table.insert(alive, boss)
        else
            print("[DEBUG] Boss mort ignoré :", boss.Name)
        end
    end
    print("[DEBUG] Boss vivants :", #alive)
    return alive
end

-- Boucle principale AutoFarm
task.spawn(function()
    print("[INIT] Démarrage de la boucle AutoFarm")
    while true do
        if autoFarm then
            print("[AUTO FARM] AutoFarm activé")
            local stats = player:FindFirstChild("PlayerStats")
            if not stats then
                warn("[AUTO FARM] Pas de PlayerStats trouvé")
                task.wait(1)
                goto continueLoop
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
                    goto continueLoop
                end

                local aliveBosses = getAliveBosses(questData.BossName)
                print("[AUTO FARM] Boss vivants trouvés pour '" .. questData.BossName .. "' :", #aliveBosses)

                if #aliveBosses > 0 then
                    if not currentBoss or not currentBoss.Parent or not currentBoss:FindFirstChild("Humanoid") or currentBoss.Humanoid.Health <= 0 then
                        currentBoss = aliveBosses[1]
                        print("[AUTO FARM] Nouveau boss suivi :", currentBoss.Name)
                    end

                    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                    if not hrp then
                        warn("[AUTO FARM] Pas de HumanoidRootPart pour le joueur")
                        task.wait(1)
                        goto continueLoop
                    end

                    local bossHRP = currentBoss and currentBoss:FindFirstChild("HumanoidRootPart")
                    if not bossHRP then
                        warn("[AUTO FARM] Pas de HumanoidRootPart pour le boss")
                        currentBoss = nil
                        task.wait(1)
                        goto continueLoop
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
            if currentBoss ~= nil then
                print("[AUTO FARM] AutoFarm désactivé, reset du boss actuel")
            end
            currentBoss = nil
        end

        ::continueLoop::
        task.wait(0.3)
    end
end)


