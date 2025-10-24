-- UBICACIÓN: StarterPlayer > StarterPlayerScripts > AvatarCustomizer
-- TIPO: LocalScript
-- FUNCIÓN: Aplica cosméticos (sombreros, etc.) al personaje del jugador según su rol.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InsertService = game:GetService("InsertService")

local player = Players.LocalPlayer

-- Esperaremos a que el servidor nos envíe la configuración de cosméticos
local roleCosmeticsConfig = nil
local configEvent = ReplicatedStorage.RemoteEvents:WaitForChild("ReceiveCosmeticConfig")

-- Tabla para rastrear los accesorios que hemos añadido, para poder limpiarlos si el jugador cambia de rol o reaparece.
local addedAccessories = {}

-- Función para limpiar los accesorios de rol anteriores
local function clearRoleAccessories(character)
	if not character then return end
	for _, accessory in ipairs(addedAccessories) do
		if accessory and accessory.Parent then
			accessory:Destroy()
		end
	end
	table.clear(addedAccessories)
end

-- Función para aplicar los accesorios de un rol
local function applyRoleAccessories(character, role)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	-- Limpiar cualquier accesorio que hayamos añadido antes
	clearRoleAccessories(character)

	-- Si aún no tenemos la configuración, no hacemos nada
	if not roleCosmeticsConfig then return end
	local cosmeticIds = roleCosmeticsConfig[role]
	if not cosmeticIds then return end

	-- Cargar y aplicar cada accesorio de la configuración
	for _, assetId in ipairs(cosmeticIds) do
		-- Pcall para manejar errores si un asset no se puede cargar
		local success, accessory = pcall(function()
			return InsertService:LoadAsset(assetId)
		end)

		if success and accessory then
			local accessoryInstance = accessory:FindFirstChildOfClass("Accessory")
			if accessoryInstance then
				-- La forma correcta de añadir un accesorio
				humanoid:AddAccessory(accessoryInstance)
				table.insert(addedAccessories, accessoryInstance) -- Guardar referencia para limpiarlo después
			else
				accessory:Destroy() -- Limpiar si no es un accesorio válido
			end
		else
			warn("No se pudo cargar el accesorio con ID: " .. tostring(assetId), accessory)
		end
	end
end

-- Escuchar el evento del servidor que nos envía la configuración
configEvent.OnClientEvent:Connect(function(sentConfig)
	roleCosmeticsConfig = sentConfig
end)

-- Conectar al evento CharacterAdded para manejar la aparición y reaparición del personaje
player.CharacterAdded:Connect(function(character)
	-- Esperar a que el Humanoid exista
	local humanoid = character:WaitForChild("Humanoid")
	
	-- Limpiar accesorios viejos al reaparecer
	clearRoleAccessories(character)

	-- Conectar al cambio de rol del jugador
	local roleValue = player:WaitForChild("Role")
	roleValue.Changed:Connect(function(newRole)
		applyRoleAccessories(character, newRole)
	end)

	-- Aplicar accesorios para el rol actual, por si ya estaba asignado
	applyRoleAccessories(character, roleValue.Value)
end)