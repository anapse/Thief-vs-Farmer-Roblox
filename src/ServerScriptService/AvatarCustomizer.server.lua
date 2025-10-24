-- UBICACIÓN: ServerScriptService > AvatarCustomizer
-- TIPO: Script (servidor)
-- FUNCIÓN: Aplica cosméticos (sombreros, etc.) al personaje del jugador según su rol.

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local InsertService = game:GetService("InsertService")

-- Cargar la configuración del juego
local GameConfig = require(ServerScriptService:WaitForChild("Modules"):WaitForChild("GameConfig"))

print("🟢 AvatarCustomizer (servidor) iniciado.")

-- Función para limpiar los accesorios de rol anteriores de un personaje
local function clearRoleAccessories(character)
	if not character then return end
	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Accessory") and child:GetAttribute("IsRoleCosmetic") then
			child:Destroy()
		end
	end
end

-- Función para aplicar los accesorios de un rol
local function applyRoleAccessories(character, role)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	-- Limpiar cualquier accesorio que hayamos añadido antes
	clearRoleAccessories(character)

	local cosmeticIds = GameConfig.RoleCosmetics[role]
	if not cosmeticIds then return end

	-- Cargar y aplicar cada accesorio de la configuración
	for _, assetId in ipairs(cosmeticIds) do
		-- Pcall para manejar errores si un asset no se puede cargar
		local success, asset = pcall(function()
			return InsertService:LoadAsset(assetId)
		end)

		if success and asset then
			local accessoryInstance = asset:FindFirstChildOfClass("Accessory")
			if accessoryInstance then
				-- Marcamos el accesorio para poder identificarlo y limpiarlo después
				accessoryInstance:SetAttribute("IsRoleCosmetic", true)
				humanoid:AddAccessory(accessoryInstance)
			else
				asset:Destroy() -- Limpiar si no es un accesorio válido
			end
		else
			warn("No se pudo cargar el accesorio con ID: " .. tostring(assetId), asset)
		end
	end
end

-- Función para configurar un jugador
local function setupPlayer(player)
	-- Conectar al evento CharacterAdded para manejar la aparición y reaparición del personaje
	player.CharacterAdded:Connect(function(character)
		local roleValue = player:WaitForChild("Role")

		-- Conectar al cambio de rol del jugador
		roleValue.Changed:Connect(function(newRole)
			applyRoleAccessories(character, newRole)
		end)

		-- Aplicar accesorios para el rol actual, por si ya estaba asignado al aparecer
		applyRoleAccessories(character, roleValue.Value)
	end)
end

-- Configurar jugadores que ya están en el juego y los que se unan después
Players.PlayerAdded:Connect(setupPlayer)
for _, player in ipairs(Players:GetPlayers()) do
	setupPlayer(player)
end