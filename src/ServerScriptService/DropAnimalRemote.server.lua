-- UBICACIÓN: ServerScriptService > DropAnimalHandler
-- TIPO: Script (servidor)
-- FUNCIÓN: Escucha cuando el jugador quiere soltar el animal

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

print("🟢 DropAnimalHandler iniciado")

local AnimalManager = require(ServerScriptService.Modules.AnimalManager)

-- RemoteEvent para dropear animales
local remoteEventsFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
local dropAnimalRemote = remoteEventsFolder:WaitForChild("DropAnimalRemote", 10)

if not dropAnimalRemote then
	error("❌ No se encontró DropAnimalRemote")
end

print("✅ DropAnimalRemote conectado")

-- Cuando el jugador solicita soltar el animal
dropAnimalRemote.OnServerEvent:Connect(function(player)
	print("📨 " .. player.Name .. " solicitó soltar su animal")

	-- Verificar que tenga un animal
	if not player.Character then
		warn("Jugador sin character")
		return
	end

	local holdingAnimal = player.Character:FindFirstChild("HoldingAnimal")
	if not holdingAnimal or not holdingAnimal.Value then
		warn(player.Name .. " no tiene animal para soltar")
		return
	end

	-- Soltar el animal
	local success = AnimalManager.DropAnimal(player)

	if success then
		print("✅ " .. player.Name .. " soltó su animal correctamente")
	else
		warn("❌ No se pudo soltar el animal de " .. player.Name)
	end
end)
