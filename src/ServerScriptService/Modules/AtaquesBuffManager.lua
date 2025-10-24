--!strict
-- ModuleScript: AtaquesBuffManager (Ubicación: ServerScriptService.Modules.AtaquesBuffManager)

local AtaquesBuffManager = {}

-- Requiere todos los módulos necesarios
local ServerScriptService = game:GetService("ServerScriptService")
local Modules = ServerScriptService:WaitForChild("Modules")

local EffectManager = require(ServerScriptService.Modules.EffectManager)
local WeaponConfig = require(Modules.WeaponConfig)
local Debris = game:GetService("Debris")

--- FUNCIÓN CENTRALIZADA PARA MANEJAR UN GOLPE DE ARMA.
-- Esta función es la que llama el script del arma.
-- @param AttackerPlayer: El objeto Player del atacante.
-- @param TargetCharacter: El Character de la víctima (PersonajeObjetivo).
-- @param WeaponName: El nombre de la herramienta.
-- @param BateVisual: La pieza visual (Hitbox) del arma, necesaria para calcular la dirección.
function AtaquesBuffManager:HandleWeaponHit(AttackerPlayer: Player, TargetCharacter: Model, WeaponName: string, BateVisual: BasePart)
	
	-- 1. DEDUCCIÓN DE OBJETOS
	local TargetPlayer = game.Players:GetPlayerFromCharacter(TargetCharacter)
	local AttackerCharacter = AttackerPlayer.Character

	local HumanoideObjetivo = TargetCharacter:FindFirstChild("Humanoid")
	-- CORRECCIÓN: El humanoide del golpeador está en el Character, no en el Player
	local HumanoideGolpeador = AttackerCharacter:FindFirstChild("Humanoid") 
	local TorsoObjetivo = TargetCharacter:FindFirstChild("HumanoidRootPart")
	
	-- Verificamos que todo exista, incluyendo el HumanoideGolpeador
	if not TargetPlayer or not AttackerCharacter or not HumanoideObjetivo or not TorsoObjetivo or not BateVisual or not HumanoideGolpeador then
		return
	end
	
	-- 2. VERIFICACIÓN DEL GOLPE
	if HumanoideObjetivo and HumanoideObjetivo ~= HumanoideGolpeador and HumanoideObjetivo.Health > 0 then

		-- Verificamos el Cooldown
		local hitPart = TorsoObjetivo
		if hitPart and hitPart:GetAttribute("EnCooldown") then return end

		if hitPart then hitPart:SetAttribute("EnCooldown", true) end

		-- 3. OBTENER DATOS DEL ARMA
		-- CORRECCIÓN: Usar un punto (.) para llamar la función, no dos puntos (:)
		local weaponData = WeaponConfig.GetWeaponData(WeaponName) 
		
		if not weaponData then 
			if hitPart then hitPart:SetAttribute("EnCooldown", false) end 
			warn("AtaquesBuffManager: No se encontraron datos para el arma: " .. WeaponName)
			return
		end
		
		-- 4. APLICAR DAÑO CERO (Fijo)
		HumanoideObjetivo:TakeDamage(0)
		
		-- 5. APLICAR EFECTO (Llama a EffectManager)
		EffectManager:ApplyEffect(TargetPlayer, weaponData.EffectName, weaponData.EffectDuration) 

		-- 6. APLICAR BODYFORCE (EMPUJE) Y TUMBAR
		local AttackerRoot = AttackerCharacter:FindFirstChild("HumanoidRootPart")
		if AttackerRoot then
			-- Calculamos la dirección desde el bate hacia el objetivo
			local Direccion = (TorsoObjetivo.Position - BateVisual.Position).Unit
			
			local Fuerza = Instance.new("BodyForce")
			local fuerzaHorizontal = Direccion * weaponData.KnockbackForce.Horizontal
			local fuerzaVertical = Vector3.new(0, weaponData.KnockbackForce.Vertical, 0) 

			Fuerza.Force = fuerzaHorizontal + fuerzaVertical
			Fuerza.Parent = TorsoObjetivo
			Debris:AddItem(Fuerza, 0.5) -- Duración del empujón

			HumanoideObjetivo.Sit = true -- Tumba al jugador
		end
		
		-- 7. REMOVER COOLDOWN (Usamos 0.5s como estándar)
		if hitPart then 
			task.delay(0.5, function() 
				hitPart:SetAttribute("EnCooldown", false) 
			end) 
		end
	end
end

return AtaquesBuffManager