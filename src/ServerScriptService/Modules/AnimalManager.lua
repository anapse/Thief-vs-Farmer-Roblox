-- UBICACIÓN: ServerScriptService > Modules > AnimalManager
-- TIPO: ModuleScript
-- FUNCIÓN: Maneja agarrar/soltar animales

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local RoleManager = require(ServerScriptService.Modules.RoleManager)

local AnimalManager = {}

-- Agarrar un animal
function AnimalManager.GrabAnimal(player, animal)
	if not player.Character then 
		warn("Jugador no tiene character")
		return false 
	end

	local character = player.Character
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then 
		warn("Jugador no tiene HumanoidRootPart")
		return false 
	end

	-- ¡NUEVA VERIFICACIÓN! No permitir agarrar animales decorativos.
	if animal:GetAttribute("IsDecorativeNPCAnimal") then
		warn(player.Name .. " intentó agarrar un animal decorativo. Acción denegada.")
		return false
	end


	-- Verificar que el jugador no tenga otro animal
	local holdingMarker = character:FindFirstChild("HoldingAnimal")
	if holdingMarker and holdingMarker.Value then
		warn(player.Name .. " ya tiene un animal.")
		return false
	end

	-- Verificar si el animal está en un corral y quién intenta agarrarlo
	local corralOwnerValue = animal:FindFirstChild("CorralOwner")
	local wasInCorral = false -- Variable para saber si el animal estaba anclado

	if corralOwnerValue and corralOwnerValue.Value and corralOwnerValue.Value:IsA("Player") then
		wasInCorral = true -- Marcamos que estaba en un corral
		local playerRole = RoleManager.GetPlayerRole(player)
		
		-- Si el jugador es el dueño del corral, no puede recogerlo
		if corralOwnerValue.Value == player then
			warn(player.Name .. " no puede recoger un animal de su propio corral.")
			-- No se desancla, por lo que no hay que hacer nada más.
			return false
		elseif playerRole ~= "Thief" then -- Si no es el dueño, solo un ladrón puede recogerlo
			warn(player.Name .. " no puede robar el animal porque no es un ladrón.")
			-- No se desancla, por lo que no hay que hacer nada más.
			return false
		end
	end

	-- Verificar que el animal tenga las partes necesarias
	local animalHRP = animal:FindFirstChild("HumanoidRootPart")
	local animalHumanoid = animal:FindFirstChild("Humanoid")
	if not animalHRP then -- Solo HumanoidRootPart es estrictamente necesario para el agarre
		warn("Animal no tiene HumanoidRootPart, no se puede agarrar.")
		-- No se desancla, por lo que no hay que hacer nada más.
		return false
	end

	print(player.Name .. " está agarrando: " .. animal.Name)

	-- ¡SOLUCIÓN! Si el animal está anclado (en un corral), desanclarlo para poder moverlo.
	if animalHRP.Anchored then
		animalHRP.Anchored = false
	end

	-- 1. Desactivar completamente las físicas del Humanoid para evitar que luche contra el jugador.
	if animalHumanoid then -- Solo aplicar si el Humanoid existe
		animalHumanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
		animalHumanoid:ChangeState(Enum.HumanoidStateType.Physics)
	end

	-- 2. Deshabilitar colisiones del animal
	for _, part in pairs(animal:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = false
		end
	end

	-- Añadir una pequeña espera para que el motor de físicas procese el cambio de colisión.
	task.wait()

	-- 3. Crear/Obtener attachment en el animal
	local rootAttach = animalHRP:FindFirstChild("RootAttachment")
	if not rootAttach then
		rootAttach = Instance.new("Attachment")
		rootAttach.Name = "RootAttachment"
		rootAttach.Parent = animalHRP
	end

	-- 4. Crear attachment en el jugador
	local charAttach = Instance.new("Attachment")
	charAttach.Name = "AnimalAttachment"
	charAttach.Position = Vector3.new(1.2, -1, -0.3) -- Más cerca y a la altura del pecho
	charAttach.Parent = hrp

	-- 5. Crear AlignPosition (más rápido y fuerte)
	local alignPos = Instance.new("AlignPosition")
	alignPos.Name = "AnimalAlignPos"
	alignPos.Attachment0 = rootAttach
	alignPos.Attachment1 = charAttach
	alignPos.MaxForce = 150000 -- Más fuerza
	alignPos.Responsiveness = 600 -- Mucho más rápido
	alignPos.RigidityEnabled = true -- Más rígido
	alignPos.Parent = animalHRP

	-- 6. Crear AlignOrientation (más rápido)
	local alignOri = Instance.new("AlignOrientation")
	alignOri.Name = "AnimalAlignOri"
	alignOri.Attachment0 = rootAttach
	alignOri.Attachment1 = charAttach
	alignOri.MaxTorque = 150000 -- Más fuerza
	alignOri.Responsiveness = 600 -- Mucho más rápido
	alignOri.RigidityEnabled = true -- Más rígido
	alignOri.Parent = animalHRP

	-- 7. Marcar al jugador que tiene un animal
	if not holdingMarker then
		holdingMarker = Instance.new("ObjectValue")
		holdingMarker.Name = "HoldingAnimal"
		holdingMarker.Parent = character
	end
	holdingMarker.Value = animal

	-- También en el player object
	player.CurrentAnimal.Value = animal

	-- 8. Deshabilitar ProximityPrompt
	local prompt = animal:FindFirstChild("PickupPrompt", true)
	if prompt then
		prompt.Enabled = false
	end

	-- 9. Marcar el animal como siendo cargado
	local carriedBy = animal:FindFirstChild("CarriedBy")
	if not carriedBy then
		carriedBy = Instance.new("ObjectValue")
		carriedBy.Name = "CarriedBy"
		carriedBy.Parent = animal
	end
	carriedBy.Value = player

	-- Si el animal estaba en un corral, quitar el marcador de dueño de corral
	local corralOwner = animal:FindFirstChild("CorralOwner")
	if corralOwner then
		corralOwner:Destroy()
	end

	-- SOLUCIÓN: Solo reactivar la zona de drop si realmente se está robando un animal de un corral.
	-- La variable wasInCorral nos dice si el animal estaba en un corral antes de ser agarrado.
	if wasInCorral then
		local farmerOwner = corralOwnerValue and corralOwnerValue.Value
		local dropZone = farmerOwner and workspace.DropZones:FindFirstChild(farmerOwner.Name .. "_DropZone")
		if dropZone then
			dropZone:SetAttribute("CanDrop", true)
		end
	end
	print(player.Name .. " agarró " .. animal.Name .. " exitosamente")
	return true
end

-- Desvincula el animal del jugador y limpia el estado
function AnimalManager.DetachAnimalFromPlayer(player)
    if not player.Character then return false, nil end

    local character = player.Character
    local marker = character:FindFirstChild("HoldingAnimal")

    if not marker or not marker.Value then
        warn(player.Name .. " no tiene animal para soltar")
        return false, nil
    end

    local animal = marker.Value
    local animalHRP = animal:FindFirstChild("HumanoidRootPart")
    if not animalHRP then
        warn("Animal no válido al intentar desvincular")
        marker:Destroy() -- Limpiar el marcador corrupto
        if player:FindFirstChild("CurrentAnimal") then
            player.CurrentAnimal.Value = nil
        end
        return false, nil
    end

    print(player.Name .. " está desvinculando: " .. animal.Name)

    -- 1. Eliminar constraints de alineación
    local alignPos = animalHRP:FindFirstChild("AnimalAlignPos")
    local alignOri = animalHRP:FindFirstChild("AnimalAlignOri")
    if alignPos then alignPos:Destroy() end
    if alignOri then alignOri:Destroy() end

    -- 2. Eliminar el attachment del jugador
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if hrp then
        local charAttach = hrp:FindFirstChild("AnimalAttachment")
        if charAttach then charAttach:Destroy() end
    end

    -- 3. Limpiar los marcadores de estado
    marker:Destroy()
    if player:FindFirstChild("CurrentAnimal") then
        player.CurrentAnimal.Value = nil
    end

    local carriedBy = animal:FindFirstChild("CarriedBy")
    if carriedBy then carriedBy:Destroy() end

    print(player.Name .. " desvinculó " .. animal.Name .. " exitosamente")
    return true, animal
end

-- Soltar un animal (versión genérica para el suelo)
function AnimalManager.DropAnimal(player)
	local success, animal = AnimalManager.DetachAnimalFromPlayer(player)

	if not success or not animal then
		return false
	end

	local character = player.Character
	local hrp = character:FindFirstChild("HumanoidRootPart")
	local animalHRP = animal:FindFirstChild("HumanoidRootPart")
	local animalHumanoid = animal:FindFirstChild("Humanoid")

	-- Posicionar animal frente al jugador
	if hrp and animalHRP then
		animalHRP.CFrame = hrp.CFrame * CFrame.new(0, 0, -4)
	end

	-- Reactivar colisiones
	for _, part in pairs(animal:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = true
		end
	end

	-- Reactivar movimiento del animal o anclarlo si es decorativo.
	-- Un animal decorativo tiene el atributo "IsDecorativeNPCAnimal".
	local isDecorative = animal:GetAttribute("IsDecorativeNPCAnimal")

	if isDecorative then
		-- Si es un animal de corral de NPC, lo anclamos para que no se mueva.
		if animalHRP then
			animalHRP.Anchored = true
		end
		if animalHumanoid then
			animalHumanoid.WalkSpeed = 0
		end
	else
		-- Si es un animal normal (comprado por un jugador), reactivamos su IA.
		if animalHumanoid and animalHumanoid.Health > 0 then
			animalHumanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
			animalHumanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		end
	end

	-- Reactivar el prompt para recogerlo
	local prompt = animal:FindFirstChild("PickupPrompt", true)
	if prompt then
		prompt.Enabled = true
	else
		AnimalManager.CreatePickupPrompt(animal)
	end

	print(player.Name .. " soltó " .. animal.Name .. " en el suelo")
	return true
end

-- Crear ProximityPrompt para recoger animal
function AnimalManager.CreatePickupPrompt(animal)
	local existingPrompt = animal:FindFirstChild("PickupPrompt", true)
	if existingPrompt then
		existingPrompt:Destroy()
	end

	-- Buscar una parte válida para adjuntar el prompt. Prioridad: HumanoidRootPart, luego cualquier BasePart.
	local promptParent = animal:FindFirstChild("HumanoidRootPart") or animal:FindFirstChildOfClass("BasePart")

	if not promptParent then return end

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "PickupPrompt"
	prompt.ActionText = "Agarrar"
	prompt.ObjectText = animal.Name
	prompt.MaxActivationDistance = 8
	prompt.HoldDuration = 0.5
	prompt.Enabled = true
	prompt.UIOffset = Vector2.new(0, -75) -- Mover el prompt hacia arriba (en píxeles)
	prompt.RequiresLineOfSight = false -- Para evitar que se oculte
	prompt.Parent = promptParent

	prompt.Triggered:Connect(function(playerWhoTriggered)
		print(playerWhoTriggered.Name .. " intentó agarrar " .. animal.Name)
		AnimalManager.GrabAnimal(playerWhoTriggered, animal)
	end)

	return prompt
end

return AnimalManager