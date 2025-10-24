-- UBICACIÓN: ServerScriptService > Modules > DropZoneManager
-- TIPO: ModuleScript
-- FUNCIÓN: Crea y maneja DropZones según el rol del jugador

local DropZoneManager = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Modules = ServerScriptService:WaitForChild("Modules")
local AnimalManager = require(Modules.AnimalManager)
local GameConfig = require(Modules.GameConfig)

-- Configuración para la zona de ladrones (el de granjeros ahora es por corral)
local DROPZONE_COLOR_THIEF = Color3.fromRGB(200, 100, 100) -- Rojo

-- Crear carpeta de DropZones si no existe
local dropZonesFolder = workspace:FindFirstChild("DropZones")
if not dropZonesFolder then
	dropZonesFolder = Instance.new("Folder")
	dropZonesFolder.Name = "DropZones"
	dropZonesFolder.Parent = workspace
end

-- Carpeta para animales activos
local activeAnimalsFolder = workspace:FindFirstChild("ActiveAnimals")
if not activeAnimalsFolder then
	activeAnimalsFolder = Instance.new("Folder")
	activeAnimalsFolder.Name = "ActiveAnimals"
	activeAnimalsFolder.Parent = workspace
end

-- Función para encontrar los datos de un corral por su ID
local function getCorralDataById(id)
    for _, corralData in ipairs(GameConfig.ZonePositions.FarmerCorrals) do
        if corralData.Id == id then
            return corralData
        end
    end
    return nil
end

-- Crear DropZone para un jugador
function DropZoneManager.CreateDropZone(player, role)
	print("Creando DropZone para " .. player.Name .. " con rol: " .. role)

	local position, zoneSize, zoneColor,zoneOrientacion

	if role == "Farmer" then
		local corralIDValue = player:FindFirstChild("AssignedCorralID")
		if corralIDValue then
			local corralData = getCorralDataById(corralIDValue.Value)
			if corralData then
				position = corralData.Position
                zoneSize = corralData.Size or Vector3.new(20, 1, 20) -- Valor por defecto
                zoneColor = corralData.Color or Color3.fromRGB(100, 200, 100) -- Valor por defecto
				zoneOrientacion = corralData.orientacion
			else
				warn("No se encontraron datos para el corral ID: " .. corralIDValue.Value)
                -- Usar valores por defecto si no hay datos de corral
                position = Vector3.new(0, 1, 0)
                zoneSize = Vector3.new(20, 1, 20)
                zoneColor = Color3.fromRGB(100, 200, 100)
				zoneOrientacion = Vector3.new(0, 0, 0)
			end
		else
			warn("El granjero " .. player.Name .. " no tiene un AssignedCorralID.")
		end
	elseif role == "Thief" then
        -- La zona del ladrón todavía puede usar una configuración semi-fija
		position = GameConfig.ZonePositions.ThiefZone.PositionCorral
        zoneSize = Vector3.new(25, 0, 25) -- Tamaño fijo para la zona de ladrones
        zoneColor = DROPZONE_COLOR_THIEF
		zoneOrientacion=GameConfig.ZonePositions.ThiefZone.CorralOrientacion
	end

    if not position then
        warn("No se pudo determinar la posición para la DropZone de " .. player.Name)
        return
    end

	-- Crear la parte de la DropZone
	local dropZone = Instance.new("Part")
	dropZone.Name = player.Name .. "_DropZone"
	dropZone.Size = zoneSize
	dropZone.Position = position
	dropZone.Anchored = true
	dropZone.CanCollide = false
	dropZone.Transparency = 0.7
	dropZone.Material = Enum.Material.Neon
	dropZone.Color = zoneColor
	dropZone.Parent = dropZonesFolder
	dropZone.Orientation = zoneOrientacion

	-- Valores de configuración
	local ownerValue = Instance.new("ObjectValue")
	ownerValue.Name = "Owner"
	ownerValue.Value = player
	ownerValue.Parent = dropZone

	local roleValue = Instance.new("StringValue")
	roleValue.Name = "Role"
	roleValue.Value = role
	roleValue.Parent = dropZone

	-- Crear detector según el rol
	if role == "Farmer" then
		DropZoneManager.SetupFarmerZone(dropZone, player, zoneSize)
	elseif role == "Thief" then
		DropZoneManager.SetupThiefZone(dropZone, player)
	end

	print("DropZone creada para " .. player.Name .. " en " .. tostring(position))
	return dropZone
end

-- Setup de DropZone para Granjero
function DropZoneManager.SetupFarmerZone(dropZone, owner, zoneSize)
    -- SOLUCIÓN: Usar una variable de "debounce" para evitar que el evento se dispare múltiples veces.
    -- Esto previene que la zona se active repetidamente si el jugador se queda dentro.
    local canDrop = true
    dropZone:SetAttribute("CanDrop", true) -- Usamos un atributo para poder modificarlo desde fuera.

    dropZone.Touched:Connect(function(hit)
        if not hit.Parent or hit.Parent ~= owner.Character then
            return
        end

        local holdingMarker = owner.Character:FindFirstChild("HoldingAnimal")
        if not holdingMarker or not holdingMarker.Value then
            -- Si no tiene animal, no hacer nada.
            return 
        end

        local animal = holdingMarker.Value
        local success, detachedAnimal = AnimalManager.DetachAnimalFromPlayer(owner)
        local humanoid = detachedAnimal and detachedAnimal:FindFirstChildOfClass("Humanoid")
        local hrp = detachedAnimal and detachedAnimal:FindFirstChild("HumanoidRootPart")

        -- Si la zona ya fue usada para este animal, no hacer nada.
        if not dropZone:GetAttribute("CanDrop") then
            return
        end
        dropZone:SetAttribute("CanDrop", false) -- Desactivar la zona inmediatamente.

        if success and detachedAnimal and humanoid and hrp then
            -- Posicionar el animal dentro de la zona
            hrp.CFrame = dropZone.CFrame + Vector3.new(math.random(-zoneSize.X / 2 + 2, zoneSize.X / 2 - 2), 3, math.random(-zoneSize.Z / 2 + 2, zoneSize.Z / 2 - 2))

            -- Reactivar colisiones (si AnimalManager.DetachAnimalFromPlayer las deshabilita)
            for _, part in pairs(detachedAnimal:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end

            -- ¡SOLUCIÓN! Desactivar el movimiento del Humanoid para que se quede quieto.
            local humanoid = detachedAnimal:FindFirstChildOfClass("Humanoid")
            humanoid.WalkSpeed = 0
            -- ¡SOLUCIÓN DEFINITIVA! Anclar la parte principal para evitar cualquier movimiento físico.
            hrp.Anchored = true
            -- Marcar el animal como propiedad del corral para la recompensa por segundo
            local corralOwnerValue = Instance.new("ObjectValue")
            corralOwnerValue.Name = "CorralOwner"
            corralOwnerValue.Value = owner
            corralOwnerValue.Parent = detachedAnimal

            -- ¡SOLUCIÓN! Volver a crear el prompt para que los ladrones puedan robarlo.
            AnimalManager.CreatePickupPrompt(detachedAnimal)
            print(owner.Name .. " depositó " .. detachedAnimal.Name .. " en su corral.")
        end
    end)
end

-- Setup de DropZone para Thief
function DropZoneManager.SetupThiefZone(dropZone, owner)
	dropZone.Touched:Connect(function(hit)
		-- Identificar al jugador que está interactuando con la zona.
		-- Puede ser el propio jugador o el animal que carga.
		local playerCharacter = hit.Parent
		local animal = playerCharacter
		local carriedBy = animal:FindFirstChild("CarriedBy")

		if carriedBy and carriedBy.Value and carriedBy.Value:IsA("Player") then
			playerCharacter = carriedBy.Value.Character
		end

		-- Si el personaje que interactúa no es el dueño de la zona, no hacer nada.
		if not playerCharacter or playerCharacter ~= owner.Character then
			return
		end

		-- Verificar que el jugador esté cargando un animal
		local holdingMarker = owner.Character:FindFirstChild("HoldingAnimal")
		if not holdingMarker or not holdingMarker.Value then
			return
		end

		local animal = holdingMarker.Value
		local animalType = animal:GetAttribute("Type")
		local animalConfig = animalType and GameConfig.Animals[animalType]

		if not animalConfig then
			warn("No se pudo vender el animal, no tiene tipo o configuración: " .. animal.Name)
			return
		end

		local sellPrice = animalConfig.ThiefValue

		-- Soltar el animal (DetachAnimalFromPlayer no lo destruye, solo lo desvincula)
		local success, detachedAnimal = AnimalManager.DetachAnimalFromPlayer(owner)

		if success and detachedAnimal then
			owner.leaderstats.Oro.Value = owner.leaderstats.Oro.Value + sellPrice
			detachedAnimal:Destroy() -- Ahora sí, lo destruimos
			print(owner.Name .. " ganó " .. sellPrice .. " oro por vender " .. animal.Name)
		end
	end)
end

return DropZoneManager
