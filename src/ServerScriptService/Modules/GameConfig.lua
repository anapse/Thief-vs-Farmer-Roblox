-- UBICACIÓN: ServerScriptService > Modules > GameConfig
-- TIPO: ModuleScript
-- FUNCIÓN: Centraliza la configuración del juego (animales, NPCs, objetos, etc.)

local GameConfig = {}

-- =============================================================================
-- CONFIGURACIÓN DE ANIMALES
-- =============================================================================
-- Define las propiedades de cada tipo de animal.
-- - PurchasePrice: Costo para comprar el animal en la tienda de NPCs.
-- - FarmerValue: Oro que genera para el granjero al entregarlo en su zona.
-- - ThiefValue: Oro que obtiene el ladrón al venderlo.
-- =============================================================================
GameConfig.Animals = {
    Chicken = {
        DisplayName = "Pollo",
        ModelName = "Chicken",
        PurchasePrice = 5,
        FarmerValue = 1,
        ThiefValue = 2,
    },
    Turkey = {
        DisplayName = "Pavo",
        ModelName = "Turkey",
        PurchasePrice = 50,
        FarmerValue = 5,
        ThiefValue = 10,
    },
    Pig = {
        DisplayName = "Cerdo",
        ModelName = "Pig",
        PurchasePrice = 500,
        FarmerValue = 30,
        ThiefValue = 60,
    },
    Cow = {
        DisplayName = "Vaca",
        ModelName = "Cow",
        PurchasePrice = 1500,
        FarmerValue = 50,
        ThiefValue = 100,
    },
}

GameConfig.Pvpdano= {

 DURACION_GOLPE = 0.5,
 FUERZA_EMPUJE = 4000, -- ¡AUMENTADA la fuerza horizontal a 20000!
 DISTANCIA_MAXIMA = 8,

}

-- =============================================================================
-- CONFIGURACIÓN DE LÍMITES DE ROLES
-- =============================================================================
-- Define el número máximo de jugadores permitidos para cada rol.
-- =============================================================================
GameConfig.RoleLimits = {
    Farmer = 5,
    Thief = 5,
}

-- =============================================================================
-- CONFIGURACIÓN DE NPCs VENDEDORES
-- =============================================================================
-- Define qué animales vende cada NPC.
-- El nombre del NPC debe coincidir con el nombre del modelo en el Workspace.
-- =============================================================================
GameConfig.NPCs = {
    ["vende gallinas"] = {
        AnimalType = "Chicken", -- Corresponde a una clave en GameConfig.Animals
    },
    ["vende cerdos"] = {
        AnimalType = "Pig",
    },
    ["vende pavos"] = {
        AnimalType = "Turkey",
    },
    ["vende vacas"] = {
        AnimalType = "Cow",
    },
}

-- =============================================================================
-- CONFIGURACIÓN DE OBJETOS DE TIENDA
-- =============================================================================
-- Define los objetos que se pueden comprar en las tiendas.
-- - GoldPrice: Precio en la moneda principal del juego (oro).
-- - RobuxPrice: Precio en Robux (opcional).
-- =============================================================================
GameConfig.Items = {
    BaseballBat = {
        GoldPrice = 200,
        RobuxPrice = nil, -- nil si no se puede comprar con Robux
        Description = "Un bate para disuadir a los ladrones.",
    },
    Gloves = {
        GoldPrice = 150,
        RobuxPrice = 25,
        Description = "Permite agarrar animales más rápido.",
    },
    JumpSpring = {
        GoldPrice = 500,
        RobuxPrice = 80,
        Description = "¡Salta mucho más alto!",
    },
}


-- =============================================================================
-- CONFIGURACIÓN DE POSICIONES DE ZONAS
-- =============================================================================
-- Define las coordenadas en el mundo para los corrales de granjeros y la zona de ladrones.
-- Simplemente ajusta los valores de Vector3 para cambiar la ubicación en el juego.
-- =============================================================================
local corralsize = 55
GameConfig.ZonePositions = {
    -- Posiciones para los 5 corrales de los granjeros

    FarmerCorrals = {
        { Id = 1, Position = Vector3.new(-324.498, 52, 58.765), Size = Vector3.new(corralsize, 1, corralsize), Color = Color3.fromRGB(100, 200, 100),orientacion =Vector3.new(0, 2.86, 0), Owner = nil }, -- Corral 1
        { Id = 2, Position = Vector3.new(-450.354, 52, -1.891), Size = Vector3.new(corralsize, 1, corralsize), Color = Color3.fromRGB(100, 200, 100),orientacion =Vector3.new(0, -58.552, 0), Owner = nil }, -- Corral 2
        { Id = 3, Position = Vector3.new(-473.902, 52, -123.402), Size = Vector3.new(corralsize, 1, corralsize), Color = Color3.fromRGB(100, 200, 100),orientacion =Vector3.new(0, -106.274, 0), Owner = nil }, -- Corral 3
        { Id = 4, Position = Vector3.new(-388.961, 52, -224.586), Size = Vector3.new(corralsize, 1, corralsize), Color = Color3.fromRGB(100, 200, 100),orientacion =Vector3.new(0, 110.364, 0), Owner = nil }, -- Corral 4
        { Id = 5, Position = Vector3.new(-281.888, 52, -235.43), Size = Vector3.new(corralsize, 1, corralsize), Color = Color3.fromRGB(100, 200, 100),orientacion =Vector3.new(0, 73.03, 0), Owner = nil }, -- Corral 5
    },
    
    -- Posiciones para los corrales de los NPCs (donde aparecen los animales para comprar)
    NpcsCorrals = {
        Chicken = { Position = Vector3.new(-165, 52, 120), Size = Vector3.new(20, 1, 20), MaxAnimals = 5 },
        Pig = { Position = Vector3.new(-250, 52, -300), Size = Vector3.new(20, 1, 20), MaxAnimals = 5 },
        Turkey = { Position = Vector3.new(-400, 52, -300), Size = Vector3.new(20, 1, 20), MaxAnimals = 5 },
        Cow = { Position = Vector3.new(-500, 52, -200), Size = Vector3.new(20, 1, 20), MaxAnimals = 5 },
        -- NOTA: Estas posiciones son ejemplos, ajústalas a tu mapa.
        -- El nombre (Chicken, Pig, etc.) debe coincidir con las claves en GameConfig.Animals
        -- Position: Centro del corral.
        -- Size: Tamaño del corral.
        -- MaxAnimals: Cantidad de animales que se mantendrán en el corral.
    },

    -- Posición para la zona de venta de los ladrones
    ThiefZone = {
        PositionCorral = Vector3.new(-101.399, 53, 216.059),
        PositionNpc = Vector3.new(-86.011,40, 209.842),
        CorralOrientacion= Vector3.new(0, 24.309, 0)

    }
}


-- =============================================================================
-- CONFIGURACIÓN DE COSMÉTICOS POR ROL
-- =============================================================================
-- Define los accesorios que cada rol recibe automáticamente.
-- Usa los Asset IDs de los accesorios del catálogo de Roblox.
-- =============================================================================
-- Puedes agregar más campos: ShirtTemplate, PantsTemplate, etc.
GameConfig.RoleCosmetics = {
    Farmer = {
    Accessories = {1033722}, -- 1033722 Sombrero preferido por el usuario (funciona con InsertService)
        ShirtTemplate = "rbxassetid://7137346980", -- Ejemplo: camisa marrón
        PantsTemplate = "rbxassetid://5961877866", -- Ejemplo: pantalón marrón
        -- Puedes agregar más accesorios: 156089128, etc.
    },
    Thief = {
        Accessories = {12850960357}, -- Capucha negra actual (funciona con InsertService)
        ShirtTemplate = "rbxassetid://144076761", -- Ejemplo: camisa oscura
        PantsTemplate = "rbxassetid://144076762", -- Ejemplo: pantalón oscuro
        -- Puedes agregar más accesorios: 156089013, etc.
    }
}

return GameConfig
