-- UBICACIÓN: ServerScriptService > PlayerSetup
-- TIPO: Script (servidor)
-- FUNCIÓN: Inicializa jugadores, crea leaderstats y maneja su entrada/salida.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Evento para enviar la configuración de cosméticos
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local ReceiveCosmeticConfig = RemoteEvents:WaitForChild("ReceiveCosmeticConfig")

-- Módulos cargados una sola vez para mayor eficiencia
local Modules = ServerScriptService:WaitForChild("Modules")
local RoleManager = require(Modules.RoleManager)
local CorralManager = require(Modules.CorralManager)
local AnimalManager = require(Modules.AnimalManager)
local GameConfig = require(Modules.GameConfig)

-- Configuración inicial
local STARTING_GOLD = 100

Players.PlayerAdded:Connect(function(player)
	print(player.Name .. " se unió al juego")

	-- Crear leaderstats
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local gold = Instance.new("IntValue")
	gold.Name = "Oro"
	gold.Value = STARTING_GOLD
	gold.Parent = leaderstats

	-- Crear valor de rol (se asignará después)
	local roleValue = Instance.new("StringValue")
	roleValue.Name = "Role"
	roleValue.Value = "None" -- "Farmer" o "Thief"
	roleValue.Parent = player

	-- Crear valor para tracking de animal
	local currentAnimal = Instance.new("ObjectValue")
	currentAnimal.Name = "CurrentAnimal"
	currentAnimal.Value = nil
	currentAnimal.Parent = player

	print("Stats creados para " .. player.Name)

	-- Enviar la configuración de cosméticos al cliente
	print("[DEBUG] Enviando configuración de cosméticos a ", player.Name)
	if ReceiveCosmeticConfig and GameConfig and GameConfig.RoleCosmetics then
		local success, err = pcall(function()
			ReceiveCosmeticConfig:FireClient(player, GameConfig.RoleCosmetics)
		end)
		if success then
			print("[DEBUG] Configuración de cosméticos enviada correctamente a ", player.Name)
		else
			warn("[ERROR] Fallo al enviar configuración de cosméticos a ", player.Name, err)
		end
	else
		warn("[ERROR] RemoteEvent o GameConfig.RoleCosmetics no disponible para ", player.Name)
	end

	-- Esperar a que el jugador seleccione rol
	-- (La GUI se muestra automáticamente desde StarterGui)

	task.wait(1) -- Pequeña espera para asegurar que todo esté listo
	RoleManager.BroadcastRoleCounts()
end)

-- Cuando el jugador sale
Players.PlayerRemoving:Connect(function(player)
	print(player.Name .. " salió del juego")

	-- Limpiar su DropZone si existe
	local dropZones = workspace:FindFirstChild("DropZones")
	if dropZones then
		local playerZone = dropZones:FindFirstChild(player.Name .. "_DropZone")
		if playerZone then
			playerZone:Destroy()
		end
	end

	-- Liberar su corral si era granjero
	local roleValue = player:FindFirstChild("Role")
	if roleValue and roleValue.Value == "Farmer" then
		CorralManager.FreePlayerCorral(player.UserId)
	end

	-- Dropear animal si lo tiene
	if player.Character then
		local holdingAnimal = player.Character:FindFirstChild("HoldingAnimal")
		if holdingAnimal and holdingAnimal.Value then
			AnimalManager.DropAnimal(player)
		end
	end

	-- Actualizar los conteos para todos los jugadores restantes
	RoleManager.BroadcastRoleCounts()
end)
