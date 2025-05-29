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
        return stats.lvl.Value
    end
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
    return bestQuest
end

local function takeQuest(questName)
    local success, err = pcall(function()
        game:GetService("ReplicatedStorage"):WaitForChild("Chest"):WaitForChild("Remotes"):WaitForChild("Functions"):WaitForChild("Quest"):InvokeServer("take", questName)
    end)
    if not success then warn("Erreur prise de quête :", err) end
end

local function findBoss(name)
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
    return bosses
end

local function tpToBoss(boss)
    local headPos = boss:FindFirstChild("HumanoidRootPart").Position
    local lookAt = CFrame.new(headPos + Vector3.new(0, 5, 0), headPos)
    hrp.CFrame = lookAt * CFrame.new(0, 0, 2)
end

local function currentQuestCompleted()
    local stats = player:FindFirstChild("PlayerStats")
    return stats and not stats:FindFirstChild("CurrentQuest")
end

-- Boucle d’auto-farm
local autoFarm = false

task.spawn(function()
    while true do
        if autoFarm then
            local stats = player:FindFirstChild("PlayerStats")
            if stats and not stats:FindFirstChild("CurrentQuest") then
                local best = getBestQuest()
                if best then
                    takeQuest(best.Name)
                end
            elseif stats and stats:FindFirstChild("CurrentQuest") then
                local currentQuestName = stats.CurrentQuest.Value
                local quest = nil
                for _, q in ipairs(Quests) do
                    if q.Name == currentQuestName then
                        quest = q
                        break
                    end
                end

                if quest then
                    local bosses = findBoss(quest.BossName)
                    for _, boss in ipairs(bosses) do
                        if boss:FindFirstChild("Humanoid") and boss.Humanoid.Health > 0 then
                            tpToBoss(boss)
                            break
                        end
                    end
                end
            end
        end
        task.wait(1)
    end
end)

-- Toggle Fluent
Tabs.Main:AddToggle("AutoFarm", {
    Title = "Auto Farm LVL",
    Default = false,
    Callback = function(state)
        autoFarm = state
        print("Auto Farm :", state)
    end
})
