local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

if not Fluent then
    warn("❌ Échec du chargement de Fluent.")
    return
end

-- FENÊTRE PRINCIPALE
local Window = Fluent:CreateWindow({
    Title = "KING LEGACY !",
    SubTitle = "SDD Team",
    TabWidth = 100,
    Size = UDim2.fromOffset(480, 300),
    Acrylic = false,
    Theme = "Aqua",
    MinimizeKey = Enum.KeyCode.RightControl
})

local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "swords" })
}

Tabs.Main:AddParagraph({
    Title = "JOIN DISCORD !",
    Content = "https://discord.gg/nVKzEjds"
})

-- 🧠 SERVICES
local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")

-- 📌 Initialisation
local player = Players.LocalPlayer
if not player then
    return warn("❌ Aucun joueur détecté (Players.LocalPlayer est nil)")
end

local playerGui = player:WaitForChild("PlayerGui", 5)
if not playerGui then
    return warn("❌ PlayerGui non trouvé !")
end

print("✅ Script démarré correctement")

-- 🖼️ ID d'image (change-le avec une image réelle si besoin)
local logoId = "rbxassetid://94766867321188" -- ✅ ID d'image valide, modifiable

-- 🖼️ Création du ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DraggableLogoGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Enabled = true
screenGui.Parent = playerGui

print("📦 ScreenGui 'DraggableLogoGui' ajouté à PlayerGui")

-- 🖱️ Création du bouton image
local imageButton = Instance.new("ImageButton")
imageButton.Name = "LogoButton"
imageButton.Image = logoId
imageButton.Size = UDim2.new(0, 60, 0, 60)
imageButton.Position = UDim2.new(0, 10, 0, 70)
imageButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
imageButton.BackgroundTransparency = 0.2
imageButton.AutoButtonColor = true
imageButton.Parent = screenGui
imageButton.Draggable = true

print("🔘 ImageButton 'LogoButton' ajouté avec succès")

-- 🔁 Clique sur le logo → simule RightControl
imageButton.MouseButton1Click:Connect(function()
    print("🖱️ LogoButton cliqué → simulation de RightControl")

    -- Simulation de la touche pour Fluent
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.RightControl, false, game)
        task.wait(0.1)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.RightControl, false, game)
    end)
end)

print("🚀 Le bouton est prêt ! Clique sur le logo pour minimiser Fluent UI")

-- 🗺️ Définition des quêtes
local Quests = {   
    { Name = "Kill 4 Soldiers", BossName = "Soldier Lv. 1", Amount = 4, BossFolder = "Mon", Rewards = { exp = 350, beli = 100 }, Level = 0 },
    { Name = "Kill 5 Clown Pirates", BossName = "Clown Pirate Lv. 10", Amount = 5, BossFolder = "Mon", Rewards = { exp = 1400, beli = 150 }, Level = 10 },
    { Name = "Kill 1 Smoky", BossName = "Smoky Lv. 20", Amount = 1, BossFolder = "Boss", Rewards = { exp = 3150, beli = 250 }, Level = 20 },
    { Name = "Kill 1 Tashi", BossName = "Tashi Lv. 30", Amount = 1, BossFolder = "Boss", Rewards = { exp = 8750, beli = 500 }, Level = 30 },
    { Name = "Kill 6 Clown Swordman", BossName = "Clown Swordman Lv. 50", Amount = 6, BossFolder = "Mon", Rewards = { exp = 19687.5, beli = 750 }, Level = 50 },
    { Name = "Kill 1 The Clown", BossName = "The Clown Lv. 75", Amount = 1, BossFolder = "Boss", Rewards = { exp = 35000, beli = 1000 }, Level = 75 },
    { Name = "Kill 4 Commander", BossName = "Commander Lv. 100", Amount = 4, Rewards = { exp = 50400, beli = 1250 }, Level = 100 },
    { Name = "Kill 1 Captain", BossName = "Captain Lv. 120", Amount = 1, BossFolder = "Boss", Rewards = { exp = 73587.5, beli = 1500 }, Level = 120 },
    { Name = "Kill 1 The Barbaric", BossName = "The Barbaric Lv. 145", Amount = 1, BossFolder = "Boss", Rewards = { exp = 113400, beli = 2000 }, Level = 145 },
}

-- Function Definitions
local function GetBossModel(bossName)
    local monsterFolder = workspace:FindFirstChild("Monster")
    if not monsterFolder then return nil end
    for _, folderName in {"Boss", "Mon"} do
        local folder = monsterFolder:FindFirstChild(folderName)
        if folder then
            local boss = folder:FindFirstChild(bossName)
            if boss then return boss end
        end
    end
    return nil
end

local function GetLevel()
    local player = game.Players.LocalPlayer
    local levelValue = player:FindFirstChild("PlayerStats") and player.PlayerStats:FindFirstChild("lvl")
    return levelValue and levelValue.Value or 0
end

local function GetBestQuest()
    local level = GetLevel()
    for i = #Quests, 1, -1 do
        if level >= Quests[i].Level then
            return Quests[i]
        end
    end
    return nil
end



local function TakeQuest(questName)
    local success, err = pcall(function()
        game:GetService("ReplicatedStorage"):WaitForChild("Chest"):WaitForChild("Remotes"):WaitForChild("Functions"):WaitForChild("Quest"):InvokeServer("take", questName)
    end)
    if success then
        print("[✔] Quête prise :", questName)
    else
        warn("[✘] Erreur lors de la prise de quête :", err)
    end
end

local isTeleporting = false

local function TeleportToBossLoop(bossName)
    if isTeleporting then return end
    isTeleporting = true

    task.spawn(function()
        while AutoFarm and IsBossAlive(bossName) do
            local player = game.Players.LocalPlayer
            local character = player.Character
            local hrp = character and character:FindFirstChild("HumanoidRootPart")
            local boss = GetBossModel(bossName)

            if boss and boss:FindFirstChild("HumanoidRootPart") and hrp then
                local bossHRP = boss.HumanoidRootPart
                local headPos = boss:FindFirstChild("Head") and boss.Head.Position or bossHRP.Position
                local lookAtCFrame = CFrame.new(headPos + Vector3.new(0, 5, 0), headPos)
                hrp.CFrame = lookAtCFrame * CFrame.new(0, 0, 2)
                print("[🌀] TP au-dessus de :", bossName)
            else
                warn("[❓] Boss non trouvé :", bossName)
            end
            task.wait()
        end
        isTeleporting = false
    end)
end

local function IsBossAlive(bossName)
    local boss = GetBossModel(bossName)
    return boss and boss:FindFirstChild("Humanoid") and boss.Humanoid.Health > 0
end

local function GetCurrentQuestName()
    local player = game.Players.LocalPlayer
    if player then
        local playerStats = player:FindFirstChild("PlayerStats")
        if playerStats then
            local currentQuest = playerStats:FindFirstChild("CurrentQuest")
            if currentQuest and currentQuest:IsA("StringValue") then
                return currentQuest.Value
            else
                warn("[❌] CurrentQuest non trouvé ou n'est pas une StringValue.")
            end
        else
            warn("[❌] PlayerStats non trouvé.")
        end
    else
        warn("[❌] Aucun joueur détecté.")
    end
    return nil
end

local AutoFarm = true
task.spawn(function()
    while true do
        task.wait(0.5)
        if AutoFarm then
            local current = GetCurrentQuestName()
            local quest
            if current and current ~= "" then
                print("[🧾] Quête actuelle détectée :", current)
                for _, q in ipairs(Quests) do
                    if q.Name == current then
                        quest = q
                        break
                    end
                end
            else
                quest = GetBestQuest()
                if quest then
                    print("[📋] Prise de quête :", quest.Name)
                    TakeQuest(quest.Name)
                    task.wait(0.5)
                else
                    warn("[❌] Aucune quête valide pour ton niveau.")
                end
            end

            if quest then
                TeleportToBossLoop(quest.BossName)
                while AutoFarm and IsBossAlive(quest.BossName) do
                    task.wait(0.4)
                end
                print("[✔] Boss vaincu ou mort.")
            end
        end
    end
end)

Tabs.Main:AddToggle("AutoFarmLevel", {
    Title = "Auto Farm Level",
    Default = false,
    Callback = function(state)
        AutoFarm = state
        print(state and "[⚙️] Auto Farm ACTIVÉ" or "[⛔] Auto Farm DÉSACTIVÉ")
    end
})

local args = {
    "FS_Electro_M1",
    "FS_Cyborg_M1",
    "FS_DragonClaw_M1",
    "FS_DarkLeg_M1"
}

local Main = Tabs.Main:AddDropdown("Main", {
    Title = "SKILL",
    Description = "",
    Values = {"Melee", "Sword", "Fruit"},
    Multi = false,
    Default = 1,
})
