local QBCore = exports['qb-core']:GetCoreObject()
local menuOpen = false

-- Função para abrir o menu de gerenciamento de restaurante
function OpenRestaurantMenu()
    -- Verificar se o menu já está aberto
    if menuOpen then return end
    
    -- Obter trabalho do jogador
    local playerData = QBCore.Functions.GetPlayerData()
    local playerJob = playerData.job.name
    local playerGrade = playerData.job.grade.level
    
    -- Mostrar animação do tablet
    HandleTabletAnimation(true)
    
    -- Obter todos os restaurantes
    QBCore.Functions.TriggerCallback('rm-restaurant:server:GetAllRestaurants', function(restaurants)
        -- Formatar dados para NUI
        local restaurantsData = {}
        
        for i, restaurant in pairs(restaurants) do
            -- Verificar se o jogador é funcionário deste restaurante
            local isEmployee = IsPlayerEmployee(restaurant.name:lower():gsub("%s+", ""))
            -- Verificar se o jogador é gerente deste restaurante
            local isManager = IsPlayerManager(restaurant.name:lower():gsub("%s+", ""), playerJob, playerGrade)
            
            table.insert(restaurantsData, {
                id = i,
                name = restaurant.name,
                label = restaurant.label,
                status = restaurant.isOpen,
                isEmployee = isEmployee,
                isManager = isManager
            })
        end
        
        -- Abrir NUI
        SetNuiFocus(true, true)
        SendNUIMessage({
            action = "openMenu",
            restaurants = restaurantsData,
            job = playerJob,
            grade = playerGrade
        })
        
        menuOpen = true
    end)
end

-- Verificar se o jogador é funcionário deste restaurante
function IsPlayerEmployee(restaurantName)
    local playerJob = QBCore.Functions.GetPlayerData().job.name
    print("Trabalho do jogador: " .. playerJob .. " verificando para restaurante: " .. restaurantName)
    
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
                        print("CORRESPONDÊNCIA ENCONTRADA! Trabalho do jogador " .. playerJob .. " é permitido para o restaurante " .. restaurantName)
                        return true
                    end
                end
            end
        end
    end
    
    print("Nenhuma correspondência encontrada, o jogador não é funcionário de " .. restaurantName)
    return false
end

-- Verificar se o jogador tem permissões de gerente para este restaurante
function IsPlayerManager(restaurantName, job, grade)
    -- Se o trabalho não for fornecido, obtê-lo dos dados do jogador
    if not job then
        local playerData = QBCore.Functions.GetPlayerData()
        job = playerData.job.name
        grade = playerData.job.grade.level
    end
    
    print("Verificando se o jogador com trabalho: " .. job .. " e grade: " .. grade .. " é gerente para: " .. restaurantName)
    
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
                    if job == allowedJob then
                        jobAllowed = true
                        break
                    end
                end
            end
            
            -- Se o trabalho for permitido, verificar se o grade é um grade de gerente
            if jobAllowed and restaurant.managerGrades then
                for _, managerGrade in pairs(restaurant.managerGrades) do
                    if grade == managerGrade then
                        print("CORRESPONDÊNCIA ENCONTRADA! O jogador é gerente do restaurante " .. restaurantName)
                        return true
                    end
                end
            end
        end
    end
    
    print("O jogador não é gerente de " .. restaurantName)
    return false
end

-- Callbacks NUI
RegisterNUICallback('closeMenu', function(_, cb)
    SetNuiFocus(false, false)
    HandleTabletAnimation(false)
    menuOpen = false
    cb('ok')
end)

RegisterNUICallback('toggleRestaurant', function(data, cb)
    local restaurantId = data.id
    local state = data.state
    
    if not restaurantId then
        cb('error')
        return
    end
    
    -- Verificar se o jogador tem permissão para alternar
    QBCore.Functions.TriggerCallback('rm-restaurant:server:HasPermission', function(hasPermission)
        if hasPermission then
            ToggleRestaurant(restaurantId, state)
            cb('ok')
        else
            QBCore.Functions.Notify('Você não está autorizado a alterar o status do restaurante', 'error')
            cb('unauthorized')
        end
    end, Config.Restaurants[restaurantId].name:lower():gsub("%s+", ""))
end)

-- Adicionar callback NUI para acesso ao gerenciamento
RegisterNUICallback('accessManagement', function(data, cb)
    local restaurantId = data.id
    
    if not restaurantId then
        cb('error')
        return
    end
    
    -- Verificar se o jogador tem permissões de gerente
    QBCore.Functions.TriggerCallback('rm-restaurant:server:HasManagerPermission', function(hasPermission)
        if hasPermission then
            -- Espaço reservado para funcionalidade futura de gerenciamento
            QBCore.Functions.Notify('Acesso de gerente concedido - Este recurso estará disponível em breve', 'success')
            cb('ok')
        else
            QBCore.Functions.Notify('Você não tem permissões de gerente para este restaurante', 'error')
            cb('unauthorized')
        end
    end, Config.Restaurants[restaurantId].name:lower():gsub("%s+", ""))
end)

-- Adicionar callback NUI para notificações
RegisterNUICallback('notifyClient', function(data, cb)
    if data.message and data.type then
        QBCore.Functions.Notify(data.message, data.type)
    end
    cb('ok')
end)

-- Registrar comando para abrir menu
RegisterCommand('restaurantmenu', function()
    OpenRestaurantMenu()
end, false)

-- Registrar mapeamento de tecla
RegisterKeyMapping('restaurantmenu', 'Abrir Gerenciamento de Restaurante', 'keyboard', Config.RestaurantMenuKey)

-- Manipulador de evento para acesso ao menu
RegisterNetEvent('rm-restaurant:client:OpenMenu', function()
    OpenRestaurantMenu()
end) 