-- Módulo de ejemplo: Modules.WeaponConfig (AJUSTADO)
local WeaponConfig = {}

WeaponConfig.Data = {
    ["bate"] = {
        KnockbackForce = {Horizontal = 1000, Vertical = 5000},
        EffectName = "Ralentizar",
        EffectDuration = 1,
        RadioGolpe = 7,             -- ¡NUEVO! Distancia para detección por radio
        CooldownActivacion = 0.5,   -- ¡NUEVO! Tiempo de espera después de la activación
    },
    
    ["mano"] = {
        KnockbackForce = {Horizontal = 1500, Vertical = 4000},
        EffectName = "Ralentizar",
        EffectDuration = 1,
        RadioGolpe = 4,
        CooldownActivacion = 0.3,
    },
    
    ["antorcha"] = {
        KnockbackForce = {Horizontal = 2000, Vertical = 3000},
        EffectName = "Fuego",
        EffectDuration = 5,
        RadioGolpe = 8,
        CooldownActivacion = 0.8,
    },

    -- Arma 3: Paleta (Hielo/Congelar)
    ["paleta"] = {
        -- Damage = 0, -- ¡Eliminado!
        KnockbackForce = {Horizontal = 3000, Vertical = 7000},
        EffectName = "Congelar",
        EffectDuration = 5,
        RadioGolpe = 8,
        CooldownActivacion = 0.5,
    },
    -- Arma 3: Chipote (Stun)
    ["chipote"] = {
        -- Damage = 0, -- ¡Eliminado!
        KnockbackForce = {Horizontal = 3000, Vertical = 7000},
        EffectName = "Stun",
        EffectDuration = 5,
        RadioGolpe = 8,
        CooldownActivacion = 0.5,
    },
}

--- Función para obtener los datos clave de una arma.
-- @param weaponName: El nombre de la herramienta.
-- @return table | nil: Una tabla con {KnockbackForce, EffectName, EffectDuration} o nil.
function WeaponConfig.GetWeaponData(weaponName: string)
    local data = WeaponConfig.Data[weaponName]

    if data then
        -- Devolvemos SOLO los campos solicitados
        return {
            KnockbackForce = data.KnockbackForce,
            EffectName = data.EffectName,
            EffectDuration = data.EffectDuration,
            RadioGolpe = data.RadioGolpe,           -- ¡Devuelto!
            CooldownActivacion = data.CooldownActivacion, -- ¡Devuelto!
        }
    end
    
    return nil -- No se encontró configuración para el arma
end

return WeaponConfig