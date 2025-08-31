Locale = {}

local Translations = {
    error = {
        not_authorized = 'Você não está autorizado a gerenciar este restaurante',
        already_open = 'Este restaurante já está aberto',
        already_closed = 'Este restaurante já está fechado',
        cannot_use_menu = 'Você não pode usar o menu do restaurante neste momento',
    },
    success = {
        restaurant_opened = 'Você abriu com sucesso o %{restaurant}',
        restaurant_closed = 'Você fechou com sucesso o %{restaurant}',
        waypoint_set = 'GPS configurado para %{restaurant}',
    },
    info = {
        open_restaurant = 'Abrir Restaurante',
        close_restaurant = 'Fechar Restaurante',
        restaurant_status = 'Status: %{status}',
        restaurant_menu = 'Gerenciamento de Restaurante',
        restaurant_open = 'ABERTO',
        restaurant_closed = 'FECHADO',
        notification_open = '%{restaurant} agora está ABERTO!',
        notification_closed = '%{restaurant} agora está FECHADO!',
        set_gps = 'Definir GPS',
    },
    menu = {
        open_menu = 'Abrir Menu',
        restaurant_list = 'Lista de Restaurantes',
        manage_restaurant = 'Gerenciar Restaurante',
    },
}

function Locale.new(_, opts)
    local self = {}
    
    self.phrases = opts.phrases or Translations
    self.warnOnMissing = opts.warnOnMissing
    self.fallbackLang = opts.fallbackLang or self
    
    self.t = function(_, phrase, vars)
        if not phrase then return '' end
        
        vars = vars or {}
        
        local split = {}
        for str in string.gmatch(phrase, "([^.]+)") do
            split[#split + 1] = str
        end
        
        local result = self.phrases
        
        for i = 1, #split do
            local key = split[i]
            result = result[key]
            if not result then
                if self.warnOnMissing then
                    print(("Translation for %s does not exist"):format(phrase))
                end
                return phrase
            end
        end
        
        if type(result) ~= 'string' then
            if self.warnOnMissing then
                print(("Translation for %s is not a string"):format(phrase))
            end
            return phrase
        end
        
        -- Replace variables in the message
        for k, v in pairs(vars) do
            result = result:gsub('%%{' .. k .. '}', v)
        end
        
        return result
    end
    
    return self
end

Lang = Locale.new(nil, {
    phrases = Translations,
    warnOnMissing = true
}) 