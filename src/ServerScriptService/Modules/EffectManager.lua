
-- ModuleScript: EffectManager

local EffectManager = {}

-- [[ VARIABLES GLOBALES ]]

local ServerScriptService = game:GetService("ServerScriptService")
-- Asume que AtaquesBuffManager requerirá EffectManager, así que no se requieren aquí
local BASE_WALKSPEED = 16 -- Velocidad base del juego (¡importante!)
local ActiveEffects = {} -- Almacena los efectos activos en los jugadores

-- [[ CONFIGURACIÓN CENTRAL DE EFECTOS ]]
-- Define cómo interactúan los efectos y qué hacen.
local EffectData = {
    -- EFECTOS DE ARMAS (DEBUFFS)
    ["Fuego"] = {
        Type = "DamageOverTime",
        Duration = 5,
        DamagePerTick = 3,
        TickRate = 0.5,
        Visual = "FuegoVisual",
    },
    ["Ralentizar"] = {
        Type = "SpeedDebuff",
        Duration = 3,
        SpeedFactor = 0.25, -- Reducción de velocidad por stack (25% de la velocidad base)
        Visual = "HieloVisual",
    },
 ["Congelar"] = {
        Type = "Stun",
        Duration = 1.5,
        SpeedFactor = 0, -- Velocidad a 0 (Inmoviliza)
        Visual = "HieloVisual",
    },

    -- ¡AÑADE ESTO! ---------------------
    ["Stun"] = {
        Type = "Stun",
        Duration = 2, -- Duración del chipote
        SpeedFactor = 0, -- Velocidad a 0 (Inmoviliza)
        Visual = "StunVisual", -- El visual que ya tenías
    },

    -- EFECTOS DE TICKETS (BUFFS/RESISTENCIAS)
    ["VelocidadBoost"] = {
        Type = "SpeedBuff",
        Duration = 10,
        SpeedFactor = 2, -- Multiplica la velocidad base por 2
        Visual = "BoostVisual",
    },
    ["AntiRalentizar"] = {
        Type = "Resistance",
        Duration = math.huge,
        ResistanceValue = 0.5,
    }
}


-- [[ PLANTILLAS VISUALES CENTRALIZADAS ]]
local VisualTemplates = {
    -- 1. Plantilla Principal de Fuego (Basada en la imagen "Fire")
    ["Fire_Visual_Template"] = (function()
        local emitter = Instance.new("ParticleEmitter")
        emitter.Name = "Fire_Visual_Template"
        emitter.Brightness = 1
        emitter.Color = ColorSequence.new(Color3.fromRGB(255, 58, 58))
        emitter.Texture = "rbxassetid://431361643"
        emitter.Lifetime = NumberRange.new(0.5, 1)
        emitter.Rate = 50 
        emitter.Size = NumberSequence.new(4, 6)
        emitter.Shape = Enum.ParticleEmitterShape.Box
        emitter.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
        emitter.Acceleration = Vector3.new(0, 20, 0)
        return emitter
    end)(), 
    
    -- 2. Plantilla Secundaria (Basada en la imagen "ShootEffect")
    ["ShootEffect_Visual_Template"] = (function()
        local emitter = Instance.new("ParticleEmitter")
        emitter.Name = "ShootEffect_Visual_Template"
        emitter.Brightness = 1
        emitter.Color = ColorSequence.new(Color3.fromRGB(255, 58, 58))
        emitter.Texture = "rbxassetid://196969716" 
        emitter.Transparency = NumberSequence.new(0.5, 1)
        emitter.Lifetime = NumberRange.new(0.1, 0.3)
        emitter.Rate = 100
        emitter.Size = NumberSequence.new(0.5, 1)
        emitter.Shape = Enum.ParticleEmitterShape.Box
        emitter.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
        return emitter
    end)(),

    -- Plantilla para la Part que se usa para teñir al jugador (Overlay)
    ["Player_Overlay_Template"] = (function()
        local part = Instance.new("Part")
        part.Name = "Player_Overlay_Part"
        part.Size = Vector3.new(4, 6, 4)
        part.CanCollide = false
        part.Anchored = false
        part.Massless = true
        part.Transparency = 0.7
        part.Material = Enum.Material.ForceField
 return part
 end)(),

    -- Plantilla para la calcomanía (Decal) de Hielo
    ["Ice_Decal_Template"] = (function()
        local decal = Instance.new("Decal")
        decal.Texture = "rbxassetid://94222384219533" -- << ¡CAMBIA ESTO!
        decal.Face = Enum.NormalId.Front
        decal.Transparency = 0.3
        return decal
    end)(),

    -- Plantilla para la Part que contendrá la imagen de Hielo y girará
  ["Ice_Head_Part_Template"] = (function()
		local part = Instance.new("Part")
		part.Name = "Ice_Head_Effect_Part"
		part.Size = Vector3.new(2.5, 2.5, 0.2)
		part.CanCollide = false
		part.Anchored = false
		part.Transparency = 1 -- << ¡CAMBIA ESTO! (Estaba en 1)
		part.Massless = true 
		return part
	end)(),

    ["Stun_Spiral_Decal_Template"] = (function()
    local decal = Instance.new("Decal")
    decal.Texture = "rbxassetid://138874553657882" -- 👈 ¡PON EL ID AQUÍ!
    decal.Face = Enum.NormalId.Front 
    return decal
end)(),
["Stun_Head_Part_Template"] = (function()
		local part = Instance.new("Part")
		part.Name = "Stun_Head_Effect_Part"
		part.Size = Vector3.new(2.5, 2.5, 0.2) 
		part.CanCollide = false
		part.Anchored = false
		part.Transparency = 1 -- << ¡CAMBIA ESTO! (Estaba en 1)
		part.Massless = true 
		return part
	end)(),
}


-- [[ UTILIDADES INTERNAS ]]

-- Función para añadir efectos visuales
local function AddVisual(Character: Model, VisualName: string) 
    local RootPart = Character:FindFirstChild("HumanoidRootPart")
    if not RootPart then return end
    local Head = Character:FindFirstChild("Head")
    if not Head then return end
    
    local OverlayTemplate = VisualTemplates["Player_Overlay_Template"]

    if VisualName == "FuegoVisual" then
        
        -- Partículas de Fuego
        local MainTemplate = VisualTemplates["Fire_Visual_Template"]
        local SecondaryTemplate = VisualTemplates["ShootEffect_Visual_Template"]
        
        if MainTemplate then
            local MainClone = MainTemplate:Clone()
            MainClone.Name = "Fire_DOT_Visual_Main" 
            MainClone.Parent = RootPart 
            MainClone.Shape = Enum.ParticleEmitterShape.Box
            MainClone.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
            MainClone.Size = NumberSequence.new(4, 6) 
        end
        if SecondaryTemplate then
            local SecondaryClone = SecondaryTemplate:Clone()
            SecondaryClone.Name = "Fire_DOT_Visual_Secondary"
            SecondaryClone.Size = NumberSequence.new(2, 4)
            SecondaryClone.Parent = RootPart
        end
        
        -- Tintado Rojo al Jugador
        if OverlayTemplate then
            local OverlayClone = OverlayTemplate:Clone()
            OverlayClone.Name = "Fire_Overlay"
            OverlayClone.Color = Color3.fromRGB(200, 50, 0) -- Rojo oscuro
            OverlayClone.Parent = RootPart
            local weld = Instance.new("WeldConstraint")
            weld.Part0 = RootPart
            weld.Part1 = OverlayClone
            weld.Parent = OverlayClone
        end
        
    elseif VisualName == "HieloVisual" then
        -- 1. Tintado Azul al Jugador
        if OverlayTemplate then
            local OverlayClone = OverlayTemplate:Clone()
            OverlayClone.Name = "Ice_Overlay"
            OverlayClone.Color = Color3.fromRGB(0, 190, 255) 
            OverlayClone.Parent = RootPart -- Asegurar que la parte tenga un padre
            
            local weld = Instance.new("WeldConstraint")
            weld.Part0 = RootPart
            weld.Part1 = OverlayClone
            weld.Parent = OverlayClone
        end

        -- 2. Imagen Giratoria de Hielo en la Cabeza
        local HeadPartTemplate = VisualTemplates["Ice_Head_Part_Template"]
        local IceDecalTemplate = VisualTemplates["Ice_Decal_Template"]
        
        if HeadPartTemplate and IceDecalTemplate then
            local HeadPartClone = HeadPartTemplate:Clone()
            HeadPartClone.Parent = Character
            HeadPartClone.Position = Head.Position + Vector3.new(0, 3, 0) 

            local IceDecalClone = IceDecalTemplate:Clone()
            IceDecalClone.Parent = HeadPartClone

            -- Hacemos que la parte gire
            local AngularVelocity = Instance.new("BodyAngularVelocity")
            AngularVelocity.AngularVelocity = Vector3.new(0, 5, 0)
            AngularVelocity.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
            AngularVelocity.Parent = HeadPartClone

            -- Unimos la Part a la cabeza del jugador
            local Weld = Instance.new("WeldConstraint")
            Weld.Part0 = Head
            Weld.Part1 = HeadPartClone
            Weld.Parent = HeadPartClone
        end

    elseif VisualName == "StunVisual" then
        -- 1. Tintado Amarillo/Verdoso al Jugador
        if OverlayTemplate then
        local OverlayClone = OverlayTemplate:Clone()
            OverlayClone.Name = "Stun_Overlay"
            OverlayClone.Color = Color3.fromRGB(255, 200, 0)
            OverlayClone.Parent = RootPart -- Asegurar que la parte tenga un padre
            OverlayClone.Parent = RootPart    
        local weld = Instance.new("WeldConstraint")
            weld.Part0 = RootPart
            weld.Part1 = OverlayClone
            weld.Parent = OverlayClone
    end

        -- 2. Espiral Giratorio de Stun en la Cabeza (¡ACTIVADO!)
        local HeadPartTemplate = VisualTemplates["Stun_Head_Part_Template"]
        local SpiralDecalTemplate = VisualTemplates["Stun_Spiral_Decal_Template"]
        
        if HeadPartTemplate and SpiralDecalTemplate then
            local HeadPartClone = HeadPartTemplate:Clone()
            HeadPartClone.Parent = Character
            HeadPartClone.Position = Head.Position + Vector3.new(0, 3, 0) 

            local SpiralDecalClone = SpiralDecalTemplate:Clone()
            SpiralDecalClone.Parent = HeadPartClone

            local AngularVelocity = Instance.new("BodyAngularVelocity")
            AngularVelocity.AngularVelocity = Vector3.new(0, 10, 0) -- Gira a velocidad 10 en Y
            AngularVelocity.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
            AngularVelocity.Parent = HeadPartClone

            local Weld = Instance.new("WeldConstraint")
            Weld.Part0 = Head
            Weld.Part1 = HeadPartClone
            Weld.Parent = HeadPartClone
        end
    end
    
    print(string.format("Agregando visual: %s a %s", VisualName, Character.Name))
end

-- Función para remover efectos visuales
local function RemoveVisual(Character: Model, VisualName: string) 
    local RootPart = Character:FindFirstChild("HumanoidRootPart")
    if not RootPart then return end
    local Head = Character:FindFirstChild("Head")
    if not Head then return end

    if VisualName == "FuegoVisual" then
        -- Remover partículas y overlay
        local MainEffect = RootPart:FindFirstChild("Fire_DOT_Visual_Main")
        if MainEffect then MainEffect:Destroy() end
        local SecondaryEffect = RootPart:FindFirstChild("Fire_DOT_Visual_Secondary")
        if SecondaryEffect then SecondaryEffect:Destroy() end
        
        local Overlay = RootPart:FindFirstChild("Fire_Overlay")
        if Overlay then Overlay:Destroy() end
        
    elseif VisualName == "HieloVisual" then
        -- Remover el overlay y la imagen giratoria
        local Overlay = RootPart:FindFirstChild("Ice_Overlay")
        if Overlay then Overlay:Destroy() end
        local HeadPart = Character:FindFirstChild("Ice_Head_Effect_Part")
        if HeadPart then HeadPart:Destroy() end

    elseif VisualName == "StunVisual" then
        local Overlay = RootPart:FindFirstChild("Stun_Overlay")
        if Overlay then Overlay:Destroy() end
      local HeadPart = Character:FindFirstChild("Stun_Head_Effect_Part")
		if HeadPart then HeadPart:Destroy() end
    end
    
    print(string.format("Removiendo visual: %s de %s", VisualName, Character.Name))
end


-- Función clave: CALCULA la velocidad final del jugador
local function CalculateFinalSpeed(TargetPlayer: Player): number
    local Character = TargetPlayer.Character
    local Humanoid = Character and Character:FindFirstChild("Humanoid")
    if not Humanoid then return BASE_WALKSPEED end

    local speedMultiplier = 1
    
    -- 1. STUN CHECK (Congelar o Aturdir ANULA TODO)
 if (ActiveEffects[TargetPlayer] and ActiveEffects[TargetPlayer]["Congelar"]) or (ActiveEffects[TargetPlayer] and ActiveEffects[TargetPlayer]["Stun"]) then
    return 0
end
    
    -- 2. CALCULAR BOOSTS (Tickets)
    if ActiveEffects[TargetPlayer] and ActiveEffects[TargetPlayer]["VelocidadBoost"] then
        speedMultiplier = speedMultiplier * EffectData["VelocidadBoost"].SpeedFactor
    end

    -- 3. CALCULAR RALENTIZAMIENTO (Debuffs Acumulables)
    if ActiveEffects[TargetPlayer] and ActiveEffects[TargetPlayer]["Ralentizar"] then
        local slowFactor = EffectData["Ralentizar"].SpeedFactor
        
        -- Aplicar RESISTENCIA (Tickets)
        if ActiveEffects[TargetPlayer] and ActiveEffects[TargetPlayer]["AntiRalentizar"] then
            local resistance = EffectData["AntiRalentizar"].ResistanceValue
            slowFactor = slowFactor * (1 - resistance)
        end
        
        speedMultiplier = speedMultiplier * (1 - slowFactor)
    end
    
    local finalSpeed = BASE_WALKSPEED * speedMultiplier
    
    return math.max(0.1, finalSpeed) 
end

-- Actualiza la velocidad real del jugador y el efecto visual.
local function UpdatePlayerSpeed(TargetPlayer: Player)
    local Character = TargetPlayer.Character
    local Humanoid = Character and Character:FindFirstChild("Humanoid")
    if not Humanoid then return end
    
    Humanoid.WalkSpeed = CalculateFinalSpeed(TargetPlayer)
end

--- Remueve un efecto de un jugador.
function EffectManager:RemoveEffect(TargetPlayer: Player, EffectName: string)
    local Character = TargetPlayer.Character
    local Config = EffectData[EffectName]
    
    if ActiveEffects[TargetPlayer] and ActiveEffects[TargetPlayer][EffectName] then
        
        ActiveEffects[TargetPlayer][EffectName] = nil
        RemoveVisual(Character, Config.Visual)
        
        if next(ActiveEffects[TargetPlayer]) == nil then
            ActiveEffects[TargetPlayer] = nil
        end
        
        if Config.Type == "SpeedDebuff" or Config.Type == "SpeedBuff" or Config.Type == "Stun" then
            UpdatePlayerSpeed(TargetPlayer)
        end
        
        print(TargetPlayer.Name .. " - Efecto " .. EffectName .. " terminado.")
    end
end


-- [[ FUNCIONES PRINCIPALES ]]

--- Aplica o refresca un efecto en un jugador.
function EffectManager:ApplyEffect(TargetPlayer: Player, EffectName: string, DurationOverride: number)
    local Character = TargetPlayer.Character
    if not Character or not TargetPlayer:IsA("Player") then return end
    local Humanoid = Character:FindFirstChild("Humanoid")
    if not Humanoid then return end

    local Config = EffectData[EffectName]
    if not Config then return end

   local FinalDuration = DurationOverride or Config.Duration

    if ActiveEffects[TargetPlayer] and ActiveEffects[TargetPlayer][EffectName] then
        print("Efecto ya activo. Reiniciando duración para " .. EffectName)
        return
    end

    -- 1. Registro y Visuales
    ActiveEffects[TargetPlayer] = ActiveEffects[TargetPlayer] or {}
    ActiveEffects[TargetPlayer][EffectName] = true
    AddVisual(Character, Config.Visual)
    
    print(TargetPlayer.Name .. " ha sido afectado por " .. EffectName)

    -- 2. Lógica Específica
    
    -- Efectos de Velocidad/Stun
    if Config.Type == "SpeedDebuff" or Config.Type == "SpeedBuff" or Config.Type == "Stun" then
        UpdatePlayerSpeed(TargetPlayer)
    end
    
    -- Efectos de Daño por Tiempo (DoT)
    if Config.Type == "DamageOverTime" then
        local totalTicks = FinalDuration / Config.TickRate
        local damageTick = Config.DamagePerTick
        
        task.spawn(function()
            for i = 1, totalTicks do
                if Humanoid.Health > 0 and ActiveEffects[TargetPlayer] and ActiveEffects[TargetPlayer][EffectName] then
                    Humanoid:TakeDamage(damageTick)
                    task.wait(Config.TickRate)
                else
                    break
                end
            end
        end)
    end
    
    -- 3. Temporizador de Finalización
    if FinalDuration ~= math.huge then
        task.delay(FinalDuration, function()
            EffectManager:RemoveEffect(TargetPlayer, EffectName)
        end)
    end
end

-- Funciones para gestionar tickets permanentes (opcional)
function EffectManager:ApplyTicketResistance(TargetPlayer: Player, ResistanceName: string)
    local Config = EffectData[ResistanceName]
    if Config and Config.Type == "Resistance" then
        self:ApplyEffect(TargetPlayer, ResistanceName, math.huge)
        if Config.SpeedFactor ~= nil then UpdatePlayerSpeed(TargetPlayer) end
    end
end

function EffectManager:RemoveTicketResistance(TargetPlayer: Player, ResistanceName: string)
    self:RemoveEffect(TargetPlayer, ResistanceName)
end


return EffectManager