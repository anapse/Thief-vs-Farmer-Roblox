-- UBICACIÓN: ServerScriptService > RoleSelectionHandler
-- TIPO: Script (servidor)
-- FUNCIÓN: Escucha cuando un jugador selecciona su rol desde la GUI

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

print("🟢 RoleSelectionHandler iniciado")

-- Esperar a que existan las carpetas necesarias
local remoteEventsFolder = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
if not remoteEventsFolder then
	error("❌ No se encontró la carpeta RemoteEvents en ReplicatedStorage")
end

local selectRoleEvent = remoteEventsFolder:WaitForChild("SelectRole", 10)
if not selectRoleEvent then
	error("❌ No se encontró el RemoteEvent 'SelectRole'")
end

print("✅ RemoteEvent encontrado: SelectRole")

-- Cargar Módulos
local modulesFolder = ServerScriptService:WaitForChild("Modules", 10)
if not modulesFolder then
	error("❌ No se encontró la carpeta Modules en ServerScriptService")
end

local RoleManager = require(modulesFolder:WaitForChild("RoleManager"))
local GameConfig = require(modulesFolder:WaitForChild("GameConfig"))
local CorralManager = require(modulesFolder:WaitForChild("CorralManager"))
print("✅ Módulos cargados: RoleManager, GameConfig")

-- Cuando un jugador selecciona un rol
selectRoleEvent.OnServerEvent:Connect(function(player, roleChoice)
	print("📨 Servidor recibió selección de " .. player.Name .. ": " .. tostring(roleChoice))

	-- Validar que sea un rol válido
	if roleChoice ~= "Farmer" and roleChoice ~= "Thief" then
		warn("Rol inválido recibido: " .. tostring(roleChoice))
		return
	end

	-- Verificar que el jugador no haya seleccionado ya un rol
	local currentRole = player:FindFirstChild("Role")
	if currentRole and currentRole.Value ~= "None" and currentRole.Value ~= nil then
		warn(player.Name .. " ya tiene un rol asignado: " .. currentRole.Value)
		return
	end

	-- Verificar límites de rol
	local playersInRole = RoleManager.GetAllPlayersWithRole(roleChoice)
	local roleLimit = GameConfig.RoleLimits[roleChoice]
	if #playersInRole >= roleLimit then
		warn("No se pudo asignar el rol " .. roleChoice .. " a " .. player.Name .. ". El equipo está lleno.")
		-- TODO: Enviar notificación al jugador
		return
	end

	local success = false
	
	-- Lógica específica por rol
	if roleChoice == "Farmer" then
		-- Buscar un corral disponible
		local assignedCorralData = nil
		for _, corralData in ipairs(GameConfig.ZonePositions.FarmerCorrals) do
			if not CorralManager.IsCorralOccupied(corralData.Id) then
				assignedCorralData = corralData -- Encontramos uno libre
				break -- Salir del bucle una vez encontrado
			end
		end

		if assignedCorralData and CorralManager.AssignCorral(assignedCorralData.Id, player.UserId) then
			success = RoleManager.AssignRole(player, roleChoice, assignedCorralData)
		else
			warn("No hay corrales disponibles para " .. player.Name)
			-- TODO: Enviar notificación al jugador
			return
		end

	elseif roleChoice == "Thief" then
		-- No se necesita corral para el ladrón
		success = RoleManager.AssignRole(player, roleChoice, nil)
	end

	if success then
		print(player.Name .. " es ahora " .. roleChoice)
		-- Opcional: Cerrar la GUI de selección en el cliente
	else
		warn("No se pudo asignar rol a " .. player.Name .. " (fallo en RoleManager)")
	end
end)