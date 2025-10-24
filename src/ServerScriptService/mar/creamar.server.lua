local Terrain = workspace:FindFirstChild("Terrain")
if not Terrain then 
	warn("No se encontró el objeto Terrain en el Workspace.")
	return 
end
 
-- Configuración
local TamanoMar = Vector3.new(2048, 100, 2048) -- Un cubo de 2048x100x2048 studs
local NivelMar = Vector3.new(0, -5, 0) -- La posición Y de -5 es el nivel del agua

-- Crear el mar
Terrain:FillBlock(
	CFrame.new(NivelMar), 
	TamanoMar, 
	Enum.Material.Water
)

print("¡Mar creado programáticamente!")