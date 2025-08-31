local QBCore = exports['qb-core']:GetCoreObject()

-- Inicializar status dos restaurantes ao iniciar o recurso
CreateThread(function()
    -- Garantir que todos os restaurantes estejam fechados ao iniciar
    for i = 1, #Config.Restaurants do
        Config.Restaurants[i].isOpen = false
    end
end)

-- Verificar se o jogador tem permissão para gerenciar um restaurante
local function CheckRestaurantPermission(source, restaurantName)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    
    local playerJob = Player.PlayerData.job.name
    -- print("Servidor: Trabalho do jogador: " .. playerJob .. " verificando para restaurante: " .. restaurantName)
    
    -- Normalizar nome do restaurante removendo espaços e convertendo para minúsculas
    local normalizedRestaurantName = restaurantName:lower():gsub("%s+", "")
    
    -- Encontrar o restaurante na configuração
    for _, restaurant in pairs(Config.Restaurants) do
        local restaurantId = restaurant.name:lower():gsub("%s+", "")
        
        if restaurantId == normalizedRestaurantName then
            -- Verificar se o trabalho do jogador está na lista de trabalhos permitidos para este restaurante
            if restaurant.allowedJobs then
                for _, job in pairs(restaurant.allowedJobs) do
                    if playerJob == job then
                        -- print("Servidor: CORRESPONDÊNCIA ENCONTRADA! Trabalho do jogador " .. playerJob .. " é permitido para o restaurante " .. restaurantName)
                        return true
                    end
                end
            end
        end
    end
    
    -- print("Servidor: Nenhuma correspondência encontrada, o jogador não é funcionário de " .. restaurantName)
    return false
end

-- Verificar se o jogador tem permissão de gerente para um restaurante
local function CheckManagerPermission(source, restaurantName)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    
    local playerJob = Player.PlayerData.job.name
    local playerGrade = Player.PlayerData.job.grade.level
    
    -- print("Servidor: Verificando se o jogador com trabalho: " .. playerJob .. " e grade: " .. playerGrade .. " é gerente para: " .. restaurantName)
    
    -- Normalizar nome do restaurante removendo espaços e convertendo para minúsculas
    local normalizedRestaurantName = restaurantName:lower():gsub("%s+", "")
    
    -- Encontrar o restaurante na configuração
    for _, restaurant in pairs(Config.Restaurants) do
        local restaurantId = restaurant.name:lower():gsub("%s+", "")
        
        if restaurantId == normalizedRestaurantName then
            -- Primeiro verificar se o trabalho do jogador é permitido para este restaurante
            local jobAllowed = false
            if restaurant.allowedJobs then
                for _, allowedJob in pairs(restaurant.allowedJobs) do
                    if playerJob == allowedJob then
                        jobAllowed = true
                        break
                    end
                end
            end
            
            -- Se o trabalho for permitido, verificar se o grade é um grade de gerente
            if jobAllowed and restaurant.managerGrades then
                for _, managerGrade in pairs(restaurant.managerGrades) do
                    if playerGrade == managerGrade then
                        -- print("Servidor: CORRESPONDÊNCIA ENCONTRADA! O jogador é gerente do restaurante " .. restaurantName)
                        return true
                    end
                end
            end
        end
    end
    
    -- print("Servidor: O jogador não é gerente de " .. restaurantName)
    return false
end

-- Função auxiliar para obter texto localizado
local function T(key, vars)
    if not Lang or not Lang.t then
        -- Fallback se Lang não estiver disponível
        return key
    end
    return Lang.t(key, vars)
end

-- Alternar status do restaurante (abrir/fechar)
RegisterNetEvent('rm-restaurant:server:ToggleRestaurant', function(restaurantIndex, state)
    local src = source
    local restaurant = Config.Restaurants[restaurantIndex]
    
    if not restaurant then
        return
    end
    
    -- Verificar se o jogador tem permissão
    local hasPermission = CheckRestaurantPermission(src, restaurant.name:lower():gsub("%s+", ""))
    if not hasPermission then
        local notification = {
            title = "Acesso Negado",
            description = "Você não está autorizado a gerenciar este restaurante",
            duration = 30000, -- 30 seconds in milliseconds
            senderName = "Sistema de Restaurantes",
            senderJob = "admin"
        }
        TriggerClientEvent('QBCore:Notify', src, notification)
        return
    end
    
    -- Se já estiver no estado solicitado, enviar erro
    if restaurant.isOpen == state then
        local statusMsg = state and 'Este restaurante já está aberto' or 'Este restaurante já está fechado'
        local notification = {
            title = "Informação",
            description = statusMsg,
            duration = 30000, -- 30 seconds in milliseconds
            senderName = "Sistema de Restaurantes",
            senderJob = "admin"
        }
        TriggerClientEvent('QBCore:Notify', src, notification)
        return
    end
    
    -- Atualizar status do restaurante
    Config.Restaurants[restaurantIndex].isOpen = state
    
    -- Enviar notificação global
    local notificationMsg = state and (restaurant.label .. ' agora está ABERTO!') or (restaurant.label .. ' agora está FECHADO!')
    TriggerClientEvent('rm-restaurant:client:RestaurantStateChanged', -1, restaurantIndex, state)
    
    -- Enviar notificação para o jogador
    local successMsg = state and ('Você abriu com sucesso o ' .. restaurant.label) or ('Você fechou com sucesso o ' .. restaurant.label)
    local personalNotification = {
        title = "Sucesso",
        description = successMsg,
        duration = 30000, -- 30 seconds in milliseconds
        senderName = "Sistema de Restaurantes",
        senderJob = "admin"
    }
    TriggerClientEvent('QBCore:Notify', src, personalNotification)
 
    
    -- Enviar notificação global usando o sistema de notificações
    if state then -- Apenas enviar notificação quando o restaurante for aberto
        local notification = {
            title = "Restaurante Aberto",
            description = restaurant.label .. " agora está ABERTO e pronto para atender!",
            duration = 30000, -- 30 seconds in milliseconds
            senderName = "Sistema de Restaurantes",
            senderJob = restaurant.allowedJobs[1] or "food" -- Usar o primeiro job permitido como identificador
        }
        TriggerClientEvent('QBCore:Notify', src, notification)
    else
 
        local notification = {
            title = "Restaurante Fechado",
            description = restaurant.label .. " agora está FECHADO!",
            duration = 30000, -- 30 seconds in milliseconds
            senderName = "Sistema de Restaurantes",
            senderJob = restaurant.allowedJobs[1] or "food" -- Usar o primeiro job permitido como identificador
        }
        TriggerClientEvent('QBCore:Notify', src, notification)
    end
end)

-- Obter status dos restaurantes para clientes que acabaram de se conectar
RegisterNetEvent('rm-restaurant:server:GetRestaurantsStatus', function()
    local src = source
    TriggerClientEvent('rm-restaurant:client:SyncRestaurants', src, Config.Restaurants)
end)

-- Sincronizar estado do restaurante com todos os clientes
RegisterNetEvent('rm-restaurant:server:RequestUpdate', function()
    TriggerClientEvent('rm-restaurant:client:SyncRestaurants', -1, Config.Restaurants)
end)

-- Callback para obter todos os restaurantes
QBCore.Functions.CreateCallback('rm-restaurant:server:GetAllRestaurants', function(source, cb)
    cb(Config.Restaurants)
end)

-- Callback para verificar se o jogador tem permissão para gerenciar um restaurante
QBCore.Functions.CreateCallback('rm-restaurant:server:HasPermission', function(source, cb, restaurantName)
    cb(CheckRestaurantPermission(source, restaurantName))
end)

-- Callback para verificar se o jogador tem permissões de gerente para um restaurante
QBCore.Functions.CreateCallback('rm-restaurant:server:HasManagerPermission', function(source, cb, restaurantName)
    cb(CheckManagerPermission(source, restaurantName))
end)

-- Notify all players about restaurant status change
RegisterNetEvent('rm-restaurant:server:NotifyAllPlayers', function(data)
    local src = source
    
    -- Verify that the player has permission to send this notification
    local restaurant = nil
    for _, rest in pairs(Config.Restaurants) do
        if rest.name:lower():gsub("%s+", "") == data.restaurantName:lower():gsub("%s+", "") then
            restaurant = rest
            break
        end
    end
    
    if not restaurant then
        return
    end
    
    -- Check permission
    local hasPermission = CheckRestaurantPermission(src, restaurant.name:lower():gsub("%s+", ""))
    if not hasPermission then
        return
    end
    
    -- Send notification to all players
    local statusText = data.isOpen and "ABERTO" or "FECHADO"
    local statusMessage = data.isOpen and "Está agora aberto para pedidos!" or "Foi fechado temporariamente."
    
    TriggerClientEvent('rm-restaurant:client:ShowRestaurantNotification', -1, {
        restaurantId = data.restaurantId,
        restaurantName = data.restaurantName,
        restaurantImage = data.restaurantImage,
        isOpen = data.isOpen,
        statusText = statusText,
        message = statusMessage
    })
end) 