-- UBICACIÓN: ServerScriptService > RewardSystem
-- TIPO: Script (servidor)
-- FUNCIÓN: Gestiona la recompensa pasiva por segundo para los granjeros con animales en sus corrales.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

print("🟢 RewardSystem iniciado")

local GameConfig = require(ServerScriptService.Modules.GameConfig)

local activeAnimalsFolder = workspace:FindFirstChild("ActiveAnimals")
if not activeAnimalsFolder then
	-- Si la carpeta no existe, la creamos.
	warn("⚠️ Carpeta ActiveAnimals no encontrada, creándola ahora.")
	activeAnimalsFolder = Instance.new("Folder")
	activeAnimalsFolder.Name = "ActiveAnimals"
	activeAnimalsFolder.Parent = workspace
end

-- Bucle principal para dar recompensas
while task.wait(1) do -- Espera 1 segundo antes de cada iteración
	for _, animal in ipairs(activeAnimalsFolder:GetChildren()) do
		-- Verificar si el animal tiene un dueño de corral asignado
		local corralOwnerValue = animal:FindFirstChild("CorralOwner")
		if corralOwnerValue and corralOwnerValue.Value and corralOwnerValue.Value:IsA("Player") then
			local ownerPlayer = corralOwnerValue.Value

			-- Verificar si el jugador sigue en el juego
			if Players:GetPlayerByUserId(ownerPlayer.UserId) then
				local animalType = animal:GetAttribute("Type")
				if animalType then
					local animalConfig = GameConfig.Animals[animalType]
					if animalConfig then
						local farmerValue = animalConfig.FarmerValue
						local leaderstats = ownerPlayer:FindFirstChild("leaderstats")
						local gold = leaderstats and leaderstats:FindFirstChild("Oro")

						if gold then
							gold.Value = gold.Value + farmerValue
							-- print(ownerPlayer.Name .. " ganó " .. farmerValue .. " oro de " .. animal.Name .. " (corral)")
						end
					end
				end
			else
				-- El dueño del corral ya no está en el juego, limpiar el marcador
				corralOwnerValue:Destroy()
			end
		end
	end
end