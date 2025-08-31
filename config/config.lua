Config = {}

-- Restaurant Settings
Config.Restaurants = {
    {
        name = "Burger Shot",
        label = "Burger Shot",
        location = vec3(-1175.29, -877.09, 14.05), -- Burger Shot location
        blip = {
            sprite = 106,
            color = 1,
            scale = 0.7,
        },
        isOpen = false,
        owner = "burgershot", -- Can be 'job' (for job-based ownership) or 'player' (for player-based ownership)
        allowedJobs = {"burgershot"}, -- Only the burgershot job can toggle this restaurant
        managerGrades = {0, 4} -- Job grades that have management permissions (e.g., 3 = manager, 4 = owner)
    },
    {
        name = "uWu Cafe",
        label = "uWu Cafe",
        location = vec3(-580.78, -1072.83, 22.33), -- uWu Cafe location
        blip = {
            sprite = 267,
            color = 19,
            scale = 0.7,
        },
        isOpen = false,
        owner = "job",
        allowedJobs = {"uwucafe"}, -- Only the uwcafé job can toggle this restaurant
        managerGrades = {0, 4} -- Job grades that have management permissions
    }
}

-- Tablet Settings
Config.TabletModel = "prop_cs_tablet"
Config.TabletAnimDict = "amb@code_human_in_bus_passenger_idles@female@tablet@base"
Config.TabletAnim = "base"
Config.TabletBone = 60309
Config.TabletOffset = vector3(0.03, 0.002, -0.0)
Config.TabletRot = vector3(10.0, 160.0, 0.0)

-- Menu Settings 
Config.MenuTitle = "Restaurant Management"
Config.MenuPosition = "right"

-- Notification Settings
Config.NotificationType = "default" -- Can be 'default', 'custom', etc.
Config.NotificationPosition = "top-right"
Config.NotificationDuration = 5000 -- in milliseconds

-- Key to toggle the restaurant menu
Config.RestaurantMenuKey = 'F3' -- Default key to open restaurant menu

-- Job restrictions (which jobs can open/close restaurants)
Config.RestrictedJobs = {
    ["burguershot"] = {"burguershot"}, -- Only the exact job name
    ["upnatom"] = {"upnatom"},
    ["beanmachine"] = {"beanmachine"},
    ["bahamamamas"] = {"bahamamamas"},
    ["tequilala"] = {"tequilala"},
} 