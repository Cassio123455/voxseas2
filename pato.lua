local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Player = Players.LocalPlayer

-- Ajuste esses caminhos conforme o jogo
local DialogueEvent = ReplicatedStorage:WaitForChild("BetweenSides").Remotes.Events:WaitForChild("DialogueEvent")
local CombatEvent = ReplicatedStorage:WaitForChild("BetweenSides").Remotes.Events:WaitForChild("CombatEvent")

local EnemysFolder = Workspace:WaitForChild("Playability"):WaitForChild("Enemys")
local QuestsNpcs = Workspace:WaitForChild("IgnoreList"):WaitForChild("Int"):WaitForChild("NPCs"):WaitForChild("Quests")

local TweenSpeed = 100

local function IsAlive(character)
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    return humanoid and humanoid.Health > 0
end

-- Pega o nível atual do player
local function GetPlayerLevel()
    local levelText = Player.PlayerGui.MainUI.MainFrame.StastisticsFrame.LevelBackground.Level
    if levelText then
        return tonumber(levelText.Text)
    end
    return 1
end

-- Pega a quest atual (assumindo que o texto mostra o inimigo a matar)
local function GetCurrentQuest()
    local questFrame = Player.PlayerGui.MainUI.MainFrame.CurrentQuest
    if questFrame and questFrame.Visible then
        local goalText = questFrame.Goal.Text
        -- Pega o nome do inimigo da quest
        local enemyName = goalText:match("Kill (%w+)")
        return enemyName
    end
    return nil
end

-- Teleporta jogador para uma posição com tween
local function TeleportToPosition(position)
    local character = Player.Character
    if not character or not character.PrimaryPart then return end
    local primaryPart = character.PrimaryPart
    local distance = (primaryPart.Position - position).Magnitude
    local time = distance / TweenSpeed

    local tween = TweenService:Create(primaryPart, TweenInfo.new(time, Enum.EasingStyle.Linear), {CFrame = CFrame.new(position + Vector3.new(0,5,0))})
    tween:Play()
    tween.Completed:Wait()
end

-- Encontra inimigos de nome dado em todas as ilhas
local function GetEnemiesByName(name)
    local enemies = {}
    for _, island in pairs(EnemysFolder:GetChildren()) do
        for _, enemy in pairs(island:GetChildren()) do
            if enemy:GetAttribute("OriginalName") == name and enemy:GetAttribute("Ready") then
                table.insert(enemies, enemy)
            end
        end
    end
    return enemies
end

-- Mata inimigos enviando evento
local function KillEnemies(enemies)
    for _, enemy in pairs(enemies) do
        CombatEvent:FireServer("DealDamage", {
            CallTime = workspace:GetServerTimeNow(),
            DelayTime = 0,
            Combo = 1,
            Results = {enemy}
        })
        wait(0.1) -- evita spam muito rápido
    end
end

-- Pega NPC da quest e aceita
local function AcceptQuest(npcName)
    local npc = QuestsNpcs:FindFirstChild(npcName, true)
    if npc and npc.PrimaryPart then
        DialogueEvent:FireServer("Quests", {NpcName = npcName, QuestName = npcName})
        TeleportToPosition(npc.PrimaryPart.Position)
        wait(1)
    end
end

-- Loop principal
while true do
    local questEnemyName = GetCurrentQuest()
    if not questEnemyName then
        print("Nenhuma quest ativa ou não foi possível identificar o inimigo")
        wait(5)
    else
        print("Pegando quest e matando inimigos: ", questEnemyName)
        AcceptQuest(questEnemyName)
        
        local enemies = GetEnemiesByName(questEnemyName)
        if #enemies == 0 then
            print("Nenhum inimigo encontrado, esperando spawn...")
            wait(3)
        else
            for _, enemy in pairs(enemies) do
                if enemy.PrimaryPart then
                    TeleportToPosition(enemy.PrimaryPart.Position)
                    KillEnemies({enemy})
                    wait(0.5)
                end
            end
        end
    end
    wait(1)
end
