-- UBICACIÓN: ServerScriptService > NPCVendorHandler
-- TIPO: Script (servidor)
-- FUNCIÓN: Crea y maneja los ProximityPrompts para todos los NPCs vendedores de animales.

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

print("🟢 NPCVendorHandler iniciado")

-- Cargar Módulos
local Modules = ServerScriptService:WaitForChild("Modules")
local AnimalManager = require(Modules:WaitForChild("AnimalManager"))
local RoleManager = require(Modules:WaitForChild("RoleManager"))
local GameConfig = require(Modules:WaitForChild("GameConfig"))

print("✅ Módulos cargados: AnimalManager, RoleManager, GameConfig")

-- Contenedores del juego
local npcFolder = workspace:WaitForChild("NPCs")
local animalsFolder = ReplicatedStorage:WaitForChild("Animals")
local activeAnimalsFolder = workspace:FindFirstChild("ActiveAnimals") or Instance.new("Folder", workspace)
activeAnimalsFolder.Name = "ActiveAnimals"

-- Función para manejar la compra de un animal
local function onPurchaseTriggered(player, npc, animalType, animalConfig)
    print("🔔 " .. player.Name .. " activó el ProximityPrompt de " .. npc.Name)

    -- 1. Verificar que el jugador sea Farmer
    if RoleManager.GetPlayerRole(player) ~= "Farmer" then
        warn(player.Name .. " no puede comprar (no es Farmer)")
        -- TODO: Enviar notificación al jugador
        return
    end

    -- 2. Verificar que el jugador no tenga ya un animal
    if player.Character and player.Character:FindFirstChild("HoldingAnimal") then
        warn(player.Name .. " ya está sosteniendo un animal.")
        -- TODO: Enviar notificación al jugador
        return
    end

    -- 3. Verificar oro del jugador
    local price = animalConfig.PurchasePrice
    local leaderstats = player:FindFirstChild("leaderstats")
    local gold = leaderstats and leaderstats:FindFirstChild("Oro")

    if not gold or gold.Value < price then
        warn(player.Name .. " no tiene suficiente oro para comprar " .. animalConfig.DisplayName .. " (necesita " .. price .. ")")
        -- TODO: Enviar notificación al jugador
        return
    end

    -- 4. Buscar la plantilla del animal
    local animalModelName = animalConfig.ModelName
    local animalTemplate = animalsFolder:FindFirstChild(animalModelName)
    if not animalTemplate then
        warn("No se encontró la plantilla del modelo '" .. animalModelName .. "' para el animal tipo: " .. animalType)
        return
    end

    -- 5. Procesar la compra
    gold.Value = gold.Value - price
    local newAnimal = animalTemplate:Clone()
    newAnimal:SetAttribute("Type", animalType) -- Etiquetar el animal con su tipo
    newAnimal.Parent = activeAnimalsFolder

    -- ¡AQUÍ ESTÁ LA SOLUCIÓN! Asegurarse de que el modelo tenga un PrimaryPart.
    if not newAnimal.PrimaryPart then
        newAnimal.PrimaryPart = newAnimal:FindFirstChild("HumanoidRootPart")
    end

    -- Posicionar cerca del NPC
    if npc:IsA("Model") and npc.PrimaryPart then
        newAnimal:SetPrimaryPartCFrame(npc.PrimaryPart.CFrame * CFrame.new(0, 0, -5))
    end

    print(player.Name .. " compró " .. animalConfig.DisplayName .. " por " .. price .. " oro.")

    -- 6. Forzar al jugador a agarrar el animal
    task.wait(0.2)
    local success = AnimalManager.GrabAnimal(player, newAnimal)
    if not success then
        -- SOLUCIÓN DEFINITIVA: Si el agarre automático falla, se revierte la compra.
        warn("Fallo en el agarre automático para " .. player.Name .. ". Reembolsando y eliminando el animal clonado.")
        gold.Value = gold.Value + price
        newAnimal:Destroy()
    end
end

-- Función para configurar un solo NPC
local function setupNpcVendor(npc)
    local npcName = npc.Name
    local npcConfig = GameConfig.NPCs[npcName]

    if not npcConfig then
        warn("⚠️ No se encontró configuración para el NPC: " .. npcName .. ". Saltando.")
        return
    end

    local animalType = npcConfig.AnimalType
    local animalConfig = GameConfig.Animals[animalType]

    if not animalConfig then
        warn("⚠️ Para el NPC " .. npcName .. ", no se encontró configuración para el animal tipo: " .. animalType .. ". Saltando.")
        return
    end

    local head = npc:FindFirstChild("Head", true)
    if not head then
        warn("⚠️ El NPC " .. npcName .. " no tiene una parte llamada 'Head'. No se puede crear el prompt.")
        return
    end

    -- Crear y configurar el ProximityPrompt
    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = npcName .. "_VendorPrompt"
    prompt.ObjectText = npcName
    prompt.ActionText = string.format("Comprar %s (💰%d)", animalConfig.DisplayName, animalConfig.PurchasePrice)
    prompt.MaxActivationDistance = 12
    prompt.RequiresLineOfSight = false
    prompt.Parent = head

    -- Conectar el evento
    prompt.Triggered:Connect(function(player)
        onPurchaseTriggered(player, npc, animalType, animalConfig)
    end)

    print("✅ Configurado vendedor: " .. npcName .. " | Vende: " .. animalConfig.DisplayName)
end

-- --- INICIO --- --
-- Configurar todos los NPCs que ya están en la carpeta
for _, npc in ipairs(npcFolder:GetChildren()) do
    if npc:IsA("Model") then
        setupNpcVendor(npc)
    end
end

-- Escuchar por si se añaden nuevos NPCs en el futuro
npcFolder.ChildAdded:Connect(function(npc)
    if npc:IsA("Model") then
        task.wait(0.5) -- Esperar a que el modelo cargue completamente
        setupNpcVendor(npc)
    end
end)

print("👍 NPCVendorHandler está activo y escuchando por NPCs.")
