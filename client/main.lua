local QBCore = exports['qb-core']:GetCoreObject()
local PlayerData = {}
local tabletObj = nil

-- Inicializar dados do jogador
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
    TriggerServerEvent('rm-restaurant:server:GetRestaurantsStatus')
end)

-- Atualizar dados do jogador na mudança de emprego
RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerData.job = JobInfo
end)

-- Sincronizar status dos restaurantes do servidor
RegisterNetEvent('rm-restaurant:client:SyncRestaurants', function(restaurants)
    Config.Restaurants = restaurants
    UpdateRestaurantBlips()
end)

-- Lidar com mudanças de estado do restaurante
RegisterNetEvent('rm-restaurant:client:RestaurantStateChanged', function(restaurantIndex, isOpen)
    Config.Restaurants[restaurantIndex].isOpen = isOpen
    UpdateRestaurantBlips()
end)

-- Criar blips de restaurante no mapa
function CreateRestaurantBlip(restaurant)
    local blip = AddBlipForCoord(restaurant.location.x, restaurant.location.y, restaurant.location.z)
    SetBlipSprite(blip, restaurant.blip.sprite or 106)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, restaurant.blip.scale or 0.7)
    SetBlipColour(blip, restaurant.isOpen and 2 or 1) -- Verde se aberto, vermelho se fechado
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    local displayName = restaurant.label or restaurant.name
    if not displayName or displayName == "" then
        displayName = "Restaurante"
        print("Aviso: Restaurante em " .. restaurant.location.x .. ", " .. restaurant.location.y .. " não tem nome!")
    end
    -- Tornar o status mais óbvio no nome
    local statusText = restaurant.isOpen and " [ABERTO]" or " [FECHADO]"
    AddTextComponentString(displayName .. statusText)
    EndTextCommandSetBlipName(blip)
    
    -- Informação de depuração
    -- print("Blip criado para " .. displayName .. statusText)
    
    return blip
end

-- Lidar com animação do tablet
function HandleTabletAnimation(state)
    local playerPed = PlayerPedId()
    local animDict = Config.TabletAnimDict
    local animName = Config.TabletAnim
    
    if state then
        -- Animação
        RequestAnimDict(animDict)
        while not HasAnimDictLoaded(animDict) do 
            Wait(100) 
        end
        -- Modelo
        local tabletModel = GetHashKey(Config.TabletModel)
        RequestModel(tabletModel)
        while not HasModelLoaded(tabletModel) do 
            Wait(100) 
        end

        tabletObj = CreateObject(tabletModel, 0.0, 0.0, 0.0, true, true, false)
        local tabletBoneIndex = GetPedBoneIndex(playerPed, Config.TabletBone)

        AttachEntityToEntity(tabletObj, playerPed, tabletBoneIndex, 
            Config.TabletOffset.x, Config.TabletOffset.y, Config.TabletOffset.z, 
            Config.TabletRot.x, Config.TabletRot.y, Config.TabletRot.z, 
            true, false, false, false, 2, true)
            
        SetModelAsNoLongerNeeded(tabletModel)
        
        CreateThread(function()
            while DoesEntityExist(tabletObj) do
                Wait(0)
                if not IsEntityPlayingAnim(playerPed, animDict, animName, 3) then
                    TaskPlayAnim(playerPed, animDict, animName, 3.0, 3.0, -1, 49, 0, 0, 0, 0)
                end
            end
        end)
    else
        if DoesEntityExist(tabletObj) then
            StopAnimTask(playerPed, animDict, animName, 1.0)
            DeleteEntity(tabletObj)
            tabletObj = nil
        end
    end
end

-- Atualizar todos os blips de restaurante
local restaurantBlips = {}
function UpdateRestaurantBlips()
    -- Remover blips existentes
    for _, blip in pairs(restaurantBlips) do
        RemoveBlip(blip)
    end
    
    restaurantBlips = {}
    
    -- Criar novos blips
    for i, restaurant in pairs(Config.Restaurants) do
        restaurantBlips[i] = CreateRestaurantBlip(restaurant)
    end
end

-- Inicializar blips ao iniciar o recurso
CreateThread(function()
    TriggerServerEvent('rm-restaurant:server:GetRestaurantsStatus')
    Wait(1000)
    UpdateRestaurantBlips()
end)

-- Alternar status do restaurante
function ToggleRestaurant(restaurantIndex, state)
    -- print("Cliente: Alternando restaurante " .. restaurantIndex .. " para estado: " .. tostring(state))
    TriggerServerEvent('rm-restaurant:server:ToggleRestaurant', restaurantIndex, state)
end

-- Definir ponto de GPS para o local do restaurante
RegisterNUICallback('setWaypoint', function(data, cb)
    local id = data.id
    local name = data.name or "Restaurante"
    
    if id and Config.Restaurants[id] then
        local restaurant = Config.Restaurants[id]
        local location = restaurant.location
        
        -- Informação de depuração
        -- print("Definindo GPS para " .. name .. " em " .. location.x .. ", " .. location.y)
        
        SetNewWaypoint(location.x, location.y)
        QBCore.Functions.Notify(Lang:t('success.waypoint_set', {restaurant = name}), "success")
        cb('ok')
    else
        -- print("Falha ao definir GPS - ID de restaurante inválido: " .. tostring(id))
        QBCore.Functions.Notify("Não foi possível definir GPS - Restaurante não encontrado", "error")
        cb('error')
    end
end)

-- Handle notification to all players
RegisterNUICallback('notifyAllPlayers', function(data, cb)
    TriggerServerEvent('rm-restaurant:server:NotifyAllPlayers', data)
    cb('ok')
end)

-- Show restaurant notification to all players
RegisterNetEvent('rm-restaurant:client:ShowRestaurantNotification', function(data)
    -- Send to NUI to display the notification
    SendNUIMessage({
        action = 'showRestaurantNotification',
        restaurantId = data.restaurantId,
        restaurantName = data.restaurantName,
        restaurantImage = data.restaurantImage,
        isOpen = data.isOpen,
        statusText = data.statusText,
        message = data.message
    })
end)

-- Definir ponto de GPS para um restaurante específico
function SetRestaurantWaypoint(restaurantName)
    for i, restaurant in pairs(Config.Restaurants) do
        if restaurant.name == restaurantName or restaurant.label == restaurantName then
            SetNewWaypoint(restaurant.location.x, restaurant.location.y)
            QBCore.Functions.Notify(Lang:t('success.waypoint_set', {restaurant = restaurant.label}), "success")
            return true
        end
    end
    QBCore.Functions.Notify("Restaurante não encontrado", "error")
    return false
end

-- Registrar comando para definir GPS para um restaurante
RegisterCommand('restaurantgps', function(source, args)
    if #args == 0 then
        QBCore.Functions.Notify("Por favor, especifique um nome de restaurante", "error")
        return
    end
    
    local restaurantName = table.concat(args, " ")
    SetRestaurantWaypoint(restaurantName)
end, false)

-- Exportar a função para que possa ser usada por outros recursos
exports('SetRestaurantWaypoint', SetRestaurantWaypoint)

-- Limpar ao parar o recurso
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() and DoesEntityExist(tabletObj) then
        DeleteEntity(tabletObj)
    end
end)

exports('ToggleRestaurant', ToggleRestaurant)
exports('OpenRestaurantMenu', OpenRestaurantMenu)
exports('SetRestaurantWaypoint', SetRestaurantWaypoint) 