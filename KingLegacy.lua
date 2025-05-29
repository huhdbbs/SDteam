-- Chargement Fluent UI
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local player = game.Players.LocalPlayer
local hrp = player.Character:WaitForChild("HumanoidRootPart")

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

-- Ta liste de quêtes
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
        print("[INFO] Ton niveau actuel est :", lvl)
        return lvl
    end
    warn("[WARN] Impossible de trouver le niveau du joueur.")
    return 0
end

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
    if bestQuest then
        print("[INFO] Meilleure quête trouvée pour ton niveau :", bestQuest.Name, "(Level requis :", bestQuest.Level .. ")")
    else
        warn("[WARN] Aucune quête trouvée pour ton niveau.")
    end
    return bestQuest
end

local function takeQuest(questName)
    print("[INFO] Tentative de prise de quête :", questName)
    local success, err = pcall(function()
        game:GetService("ReplicatedStorage"):WaitForChild("Chest"):WaitForChild("Remotes"):WaitForChild("Functions"):WaitForChild("Quest"):InvokeServer("take", questName)
    end)
    if success then
        warn("[SUCCÈS] Quête prise :", questName)
    else
        warn("[ERREUR] Échec lors de la prise de quête :", err)
    end
end

local function findBoss(name)
    print("[INFO] Recherche du boss :", name)
    local bosses = {}
    local function scan(folder)
        if folder then
            for _, obj in ipairs(folder:GetChildren()) do
                if obj:IsA("Model") and obj.Name == name and obj:FindFirstChild("HumanoidRootPart") and obj:FindFirstChild("Humanoid") then
                    table.insert(bosses, obj)
                end
            end
        end
    end
    scan(workspace:FindFirstChild("Monster"))
    scan(workspace:FindFirstChild("Boss"))
    scan(workspace:FindFirstChild("Mon"))

    print("[INFO] Nombre de boss trouvés :", #bosses)
    return bosses
end

local function tpToBoss(boss)
    if boss and boss:FindFirstChild("HumanoidRootPart") then
        local headPos = boss.HumanoidRootPart.Position
        local lookAt = CFrame.new(headPos + Vector3.new(0, 5, 0), headPos)
        hrp.CFrame = lookAt * CFrame.new(0, 0, 2)
        print("[INFO] Téléportation au boss :", boss.Name)
    else
        warn("[WARN] Boss invalide ou sans HumanoidRootPart.")
    end
end

-- Boucle d’auto-farm
task.spawn(function()
    while true do
        if autoFarm then
            local stats = player:FindFirstChild("PlayerStats")

            if stats then
                local currentQuest = stats:FindFirstChild("CurrentQuest")

                if not currentQuest then
                    print("[INFO] Aucune quête active. Tentative de prise de la meilleure quête...")
                    local best = getBestQuest()
                    if best then
                        takeQuest(best.Name)
                    end
                else
                    local currentQuestName = currentQuest.Value
                    print("[INFO] Quête actuellement active :", currentQuestName)

                    local quest = nil
                    for _, q in ipairs(Quests) do
                        if q.Name == currentQuestName then
                            quest = q
                            break
                        end
                    end

                    if quest then
                        local bossName = quest.BossName
                        print("[INFO] Recherche du boss correspondant à la quête :", bossName)

                        local bosses = findBoss(bossName)

                        if #bosses == 0 then
                            warn("[WARN] Aucun boss trouvé pour :", bossName)
                        else
                            local foundAlive = false
                            for _, boss in ipairs(bosses) do
                                if boss:FindFirstChild("Humanoid") and boss.Humanoid.Health > 0 then
                                    print("[INFO] Boss vivant trouvé :", boss.Name, "- HP:", boss.Humanoid.Health)
                                    tpToBoss(boss)
                                    foundAlive = true
                                    break
                                else
                                    warn("[INFO] Boss trouvé mais mort ou invalide :", boss.Name)
                                end
                            end

                            if not foundAlive then
                                warn("[INFO] Aucun boss vivant trouvé pour :", bossName)
                            end
                        end
                    else
                        warn("[WARN] Impossible de retrouver la quête dans la liste locale :", currentQuestName)
                    end
                end
            else
                warn("[WARN] Statistiques du joueur non trouvées.")
            end
        end
        task.wait(0.5)
    end
end)


-- Toggle Fluent
Tabs.Main:AddToggle("AutoFarm", {
    Title = "Auto Farm LVL",
    Default = false,
    Callback = function(state)
        autoFarm = state
        warn("[TOGGLE] Auto Farm :", state and "Activé" or "Désactivé")
    end
})
