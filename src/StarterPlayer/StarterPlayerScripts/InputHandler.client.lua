-- UBICACIÓN: StarterPlayer > StarterPlayerScripts > InputHandler
-- TIPO: LocalScript ok

-- FUNCIÓN: Detecta cuando el jugador presiona Q para soltar el animal

local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer

print("🎮 InputHandler iniciado")

-- Crear RemoteEvent si no existe (lo crearemos después)
local remoteEventsFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
local dropAnimalRemote = remoteEventsFolder:WaitForChild("DropAnimalRemote", 10)

if not dropAnimalRemote then
	warn("❌ No se encontró DropAnimalRemote")
	return
end

print("✅ DropAnimalRemote encontrado")

-- Detectar cuando presiona Q
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	-- Ignorar si está escribiendo en chat
	if gameProcessed then return end

	-- Detectar tecla Q
	if input.KeyCode == Enum.KeyCode.Q then
		print("🔽 Presionó Q - Intentando soltar animal")

		-- Verificar que tenga un animal
		if player.Character and player.Character:FindFirstChild("HoldingAnimal") then
			local holdingAnimal = player.Character.HoldingAnimal
			if holdingAnimal.Value then
				print("📤 Enviando solicitud para soltar: " .. holdingAnimal.Value.Name)
				-- Enviar al servidor
				dropAnimalRemote:FireServer()
			else
				print("⚠️ No hay animal para soltar")
			end
		else
			print("⚠️ No estás cargando ningún animal")
		end
	end
end)
