-- ServerScriptService/Modules/CorralManager.lua
local CorralManager = {}

local occupiedCorrals = {} -- { [corralId] = playerId }

-- Verifica si un corral está ocupado
function CorralManager.IsCorralOccupied(corralId)
	return occupiedCorrals[corralId] ~= nil
end

-- Ocupa un corral
function CorralManager.AssignCorral(corralId, playerId)
	if CorralManager.IsCorralOccupied(corralId) then
		return false
	end
	occupiedCorrals[corralId] = playerId
	return true
end

-- Libera un corral (ej. cuando un jugador se va)
function CorralManager.FreeCorral(corralId)
	occupiedCorrals[corralId] = nil
end

-- Libera el corral de un jugador específico
function CorralManager.FreePlayerCorral(playerId)
	for id, pId in pairs(occupiedCorrals) do
		if pId == playerId then
			occupiedCorrals[id] = nil
			print("Corral " .. id .. " liberado.")
			return
		end
	end
end

return CorralManager