-- UBICACIÓN: ServerScriptService > Modules > RoleManager
-- TIPO: ModuleScript
-- FUNCIÓN: Gestiona roles de jugadores (Farmer/Thief)

local RoleManager = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Mover la carga de GameConfig aquí para que esté disponible en todo el módulo
local Modules = ServerScriptService:WaitForChild("Modules")
local GameConfig = require(Modules.GameConfig)
local UpdateRoleCountsEvent = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("UpdateRoleCounts")

-- Asignar rol a un jugador
function RoleManager.AssignRole(player, role, corralData)
	if role ~= "Farmer" and role ~= "Thief" then
		warn("Rol inválido: " .. tostring(role))
		return false
	end

	print("Asignando rol " .. role .. " a " .. player.Name)

	-- Guardar el rol
	local roleValue = player:FindFirstChild("Role")
	if roleValue then
		roleValue.Value = role
	else
		roleValue = Instance.new("StringValue")
		roleValue.Name = "Role"
		roleValue.Value = role
		roleValue.Parent = player
	end

	-- Si es Farmer, asignar el corral
	if role == "Farmer" and corralData then
		local corralValue = Instance.new("IntValue") -- Usamos IntValue para el ID
		corralValue.Name = "AssignedCorralID"
		corralValue.Value = corralData.Id
		corralValue.Parent = player
		print("Asignado corral " .. corralData.Id .. " a " .. player.Name)
	end

	-- Asignar a un Team (opcional, para visual)
	local Teams = game:GetService("Teams")

	if role == "Farmer" then
		-- Buscar o crear team de Farmers
		local farmerTeam = Teams:FindFirstChild("Farmers")
		if not farmerTeam then
			farmerTeam = Instance.new("Team")
			farmerTeam.Name = "Farmers"
			farmerTeam.TeamColor = BrickColor.new("Bright green")
			farmerTeam.AutoAssignable = false
			farmerTeam.Parent = Teams
		end
		player.Team = farmerTeam

	elseif role == "Thief" then
		-- Buscar o crear team de Thieves
		local thiefTeam = Teams:FindFirstChild("Thieves")
		if not thiefTeam then
			thiefTeam = Instance.new("Team")
			thiefTeam.Name = "Thieves"
			thiefTeam.TeamColor = BrickColor.new("Bright red")
			thiefTeam.AutoAssignable = false
			thiefTeam.Parent = Teams
		end
		player.Team = thiefTeam
	end

	-- Crear su DropZone
	require(Modules:WaitForChild("DropZoneManager")).CreateDropZone(player, role)

	-- Asignar accesorios y ropa de rol desde el servidor
	local InsertService = game:GetService("InsertService")
	local cosmetics = GameConfig.RoleCosmetics and GameConfig.RoleCosmetics[role]
	local function applyCosmeticsToCharacter(character)
		if not cosmetics or not character then
			print("[SERVER] No hay cosméticos para el rol " .. tostring(role) .. " o el personaje no está disponible.")
			return
		end
		-- Accesorios
		if cosmetics.Accessories then
			for _, assetId in ipairs(cosmetics.Accessories) do
				local success, asset = pcall(function()
					return InsertService:LoadAsset(assetId)
				end)
				if success and asset then
					-- Buscar accesorio en todos los descendientes
					local accessory = asset:FindFirstChildOfClass("Accessory")
					if not accessory then
						for _, descendant in ipairs(asset:GetDescendants()) do
							if descendant:IsA("Accessory") then
								accessory = descendant
								break
							end
						end
					end
					if accessory then
						accessory.Parent = character
						print("[SERVER] Accesorio asignado a " .. player.Name .. ": " .. tostring(assetId))
					else
						asset:Destroy()
						warn("[SERVER] No se encontró accesorio válido en assetId " .. tostring(assetId))
					end
				else
					warn("[SERVER] No se pudo cargar el accesorio con ID: " .. tostring(assetId), asset)
				end
			end
		end
		-- Camisa
		if cosmetics.ShirtTemplate then
			local success, err = pcall(function()
				local shirt = Instance.new("Shirt")
				shirt.ShirtTemplate = cosmetics.ShirtTemplate
				shirt.Parent = character
				print("[SERVER] Camisa asignada a " .. player.Name .. ": " .. cosmetics.ShirtTemplate)
			end)
			if not success then
				warn("[SERVER] Error al asignar camisa a " .. player.Name .. ": " .. tostring(err))
			end
		else
			print("[SERVER] Sin ShirtTemplate para " .. player.Name)
		end
		-- Pantalón
		if cosmetics.PantsTemplate then
			local success, err = pcall(function()
				local pants = Instance.new("Pants")
				pants.PantsTemplate = cosmetics.PantsTemplate
				pants.Parent = character
				print("[SERVER] Pantalón asignado a " .. player.Name .. ": " .. cosmetics.PantsTemplate)
			end)
			if not success then
				warn("[SERVER] Error al asignar pantalón a " .. player.Name .. ": " .. tostring(err))
			end
		else
			print("[SERVER] Sin PantsTemplate para " .. player.Name)
		end
	end

	-- Aplicar cosméticos al personaje actual
	if player.Character then
		applyCosmeticsToCharacter(player.Character)
	end
	-- Asegurar que se apliquen también al reaparecer
	player.CharacterAdded:Connect(function(character)
		-- Esperar a que el Humanoid exista
		local _ = character:WaitForChild("Humanoid", 3)
		applyCosmeticsToCharacter(character)
	end)

	-- Notificar a todos los clientes sobre el cambio en el conteo de roles
	RoleManager.BroadcastRoleCounts()

	print(player.Name .. " ahora es " .. role)
	return true
end

-- Obtener rol de un jugador
function RoleManager.GetPlayerRole(player)
	local roleValue = player:FindFirstChild("Role")
	if roleValue then
		return roleValue.Value
	end
	return "None"
end

-- Contar jugadores con un rol específico
function RoleManager.GetAllPlayersWithRole(role)
    local playersWithRole = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if RoleManager.GetPlayerRole(player) == role then
            table.insert(playersWithRole, player)
        end
    end
    return playersWithRole
end

-- Nueva función para notificar a todos los clientes
function RoleManager.BroadcastRoleCounts()
	local farmerCount = #RoleManager.GetAllPlayersWithRole("Farmer")
	local thiefCount = #RoleManager.GetAllPlayersWithRole("Thief")

	local counts = {
		Farmer = farmerCount,
		Thief = thiefCount,
	}
	UpdateRoleCountsEvent:FireAllClients(counts, GameConfig.RoleLimits)
end

-- Verificar si un jugador puede comprar animales
function RoleManager.CanBuyAnimals(player)
	local role = RoleManager.GetPlayerRole(player)
	return role == "Farmer" -- Solo los Farmers pueden comprar
end

-- Verificar si un jugador puede robar
function RoleManager.CanSteal(player)
	local role = RoleManager.GetPlayerRole(player)
	return role == "Thief" -- Solo los Thieves pueden robar (técnicamente todos pueden agarrar)
end

return RoleManager
