

-- RegisterCommand('ap',
--     function(name,args)
--         local playerped = GetPlayerPed(-1)
--         local vehicle = GetVehiclePedIsIn (playerped, false)
--         ClearVehicleTasks(vehicle)
--         if not IsWaypointActive() then
--             --平飞
--             local heading = (360.0 - GetEntityHeading(playerped))
--             local coords = GetEntityCoords(playerped)
--             -- 计算延长线
--             -- print (coords.x, coords.y, coords.z)
--             local destination = {
--                 y = coords.y + 100000 * math.cos(heading * math.pi / 180.0),
--                 x = coords.x + 100000 * math.sin(heading * math.pi / 180.0),
--                 z = coords.z
--             }   
--             if destination.z < 300 then
--                 destination.z = 300
--             end         
--             -- print (destination.x, destination.y, destination.z)
--             TaskPlaneMission(playerped, vehicle,0, 0, destination.x, destination.y, destination.z,4,150.0,0.0,GetEntityHeading(playerped),2610.0,2600.0)
--         else
--             -- 获取导航点
            
--             local waypoint = GetFirstBlipInfoId(8)
--             local waypointCoords = GetBlipInfoIdCoord(waypoint)
--             -- print (waypointCoords.x, waypointCoords.y, waypointCoords.z)
--             local heading = GetEntityHeading(playerped)
--             local coords = GetEntityCoords(playerped)
--             -- 计算导航点连线角度
--             local cachepoint = {
--                 y = coords.y + 300 * math.cos(heading * math.pi / 180.0),
--                 x = coords.x + 300 * math.sin(heading * math.pi / 180.0),
--                 z = coords.z
--             }   
--             local lineheading = math.atan2(waypointCoords.y - cachepoint.y, waypointCoords.x - cachepoint.x) * 180.0 / math.pi
--             if 360.0+lineheading-90 >360 then
--                 lineheading =  lineheading-90
--             else
--                 lineheading = 360.0+lineheading-90
--             end
--             print (lineheading)
--             TaskPlaneMission(playerped, vehicle,0, 0, waypointCoords.x, waypointCoords.y, coords.z,4,150.0,0.0,lineheading,2700.0,2700.0)
--         end 
--         if IsPedInAnyPlane(playerped) then
            
--         end
--     end
-- ,false)



-- SendNUIMessage({type = "autopilot", status = "start"})

-- RegisterCommand('stop',
--     function(name,args)
--         local playerped = GetPlayerPed(-1)
--         local vehicle = GetVehiclePedIsIn (playerped, false)
--         ClearVehicleTasks(vehicle)
--         SendNUIMessage({type = "autopilot", status = "stop"})
--     end
-- ,false)

-- local runway = {
--     rwystart = {x= -2747.41 ,y= 3284.91 ,z= 33.23},
--     rwyend = {x= -2035.52 ,y= 2875.29 ,z= 33.23}
-- }
-- RegisterCommand('land',
--     function(name,args)
--         local playerped = GetPlayerPed(-1)
--         local vehicle = GetVehiclePedIsIn (playerped, false)
--         TaskPlaneLand(playerped, vehicle, runway.rwystart.x, runway.rwystart.y, runway.rwystart.z, runway.rwyend.x, runway.rwyend.y, runway.rwyend.z)   
--     end
-- ,false)

local function safePow(base, exp)
    if base < 0 then
        return -math.pow(math.abs(base), exp)
    else
        return math.pow(base, exp)
    end
end

local angle = 0
local currentalt = 0.0
local altitude = 500
local hdgmode = 0 -- 0平飞 1转向
local roll = 30
local currentheading = 0
local heading = 0
function drawTxt(content, font, colour, scale, x, y)
    SetTextFont(font)
    SetTextScale(scale, scale)
    SetTextColour(colour[1],colour[2],colour[3], 255)
    SetTextEntry("STRING")
    SetTextDropShadow(0, 0, 0, 0,255)
    SetTextDropShadow()
    SetTextEdge(4, 0, 0, 0, 255)
    SetTextOutline()
    AddTextComponentString(content)
    DrawText(x, y)
end

local ap = false

-- SetControlNormal()
local modes = {
    HDG = 0,
    APPR = 1
}
local mode = modes.HDG

local apmenu = MenuV:CreateMenu(false, 'Autopilot', 'topleft', 255, 0, 0, 'size-125', 'native', 'menuv', 'example_namespace')
local heightsubmenu = MenuV:CreateMenu ('Altitude', 'Altitude', 'topleft', 255, 0, 0, 'size-125', 'native', 'menuv', 'namespace1')
local headingsubmenu = MenuV:CreateMenu ('Heading', 'Heading', 'topleft', 255, 0, 0, 'size-125', 'native', 'menuv', 'namespace2')

local apstart = apmenu:AddConfirm({ icon = '😃', label = 'Start',value = 'no' })
local heightsubmenubutton = apmenu:AddButton({ icon = '😃', label = 'Altitude', value = heightsubmenu, description = 'Altitude' })
local headingsubmenubutton = apmenu:AddButton({ icon = '😃', label = 'Heading', value = headingsubmenu, description = 'Heading' })
local hightmode = 0 -- 0 上升 1 下降 2 巡航
apstart:On('confirm', function(item) 
    print ('start')
    ap = true
    SendNUIMessage({type = "autopilot", status = "start"})
                    -- 高度分成三个模式，上升，下降，巡航
                -- 舵量打提前量

                if currentalt - altitude > 100 then
                    hightmode = 1
                elseif altitude - currentalt > 100 then
                    hightmode = 0
                else
                    hightmode = 2
                end

                --航向判断是否需要转向
                if math.abs(currentheading - heading) > 5 then
                    hdgmode = 1
                else
                    hdgmode = 0
                end
end)
apstart:On('deny', function(item) 
    print ('stop')
    ap = false
    SendNUIMessage({type = "autopilot", status = "stop"})
end)

local modeselect = apmenu:AddSlider({ icon = '❤️', label = 'Mode', value = 'HDG', values = {
    { label = 'HDG', value = 'HDG', description = 'Heading Hold' },
    { label = 'APPR', value = 'APPR', description = 'Approach' },
}})

-- 根据选择改变模式
modeselect:On('select', function(item, value) 
    if value == 'HDG' then
        mode = modes.HDG
        print ('HDG')
    elseif value == 'APPR' then
        mode = modes.APPR
        print ('APPR')
    end
end)


local altbutton = apmenu:AddSlider({ icon = '❤️', label = 'Altitude', value = 3000, values = {
    { label = '500', value = 500, description = '500' },
    { label = '600', value = 600, description = '600' },
    { label = '700', value = 700, description = '700' },
    { label = '800', value = 800, description = '800' },
    { label = '900', value = 900, description = '900' },
    { label = '1000', value = 1000, description = '1000' },
    { label = '1100', value = 1100, description = '1100' },
    { label = '1200', value = 1200, description = '1200' },
    { label = '1300', value = 1300, description = '1300' },
    { label = '1400', value = 1400, description = '1400' },
    { label = '1500', value = 1500, description = '1500' },
    { label = '1600', value = 1600, description = '1600' },
    { label = '1700', value = 1700, description = '1700' },
    { label = '1800', value = 1800, description = '1800' },
    { label = '1900', value = 1900, description = '1900' },
    { label = '2000', value = 2000, description = '2000' },
    { label = '2100', value = 2100, description = '2100' },
    { label = '2200', value = 2200, description = '2200' },
    { label = '2300', value = 2300, description = '2300' },
    { label = '2400', value = 2400, description = '2400' },
    { label = '2500', value = 2500, description = '2500' },
    { label = '2600', value = 2600, description = '2600' },
    { label = '2700', value = 2700, description = '2700' },
    { label = '2800', value = 2800, description = '2800' },
    { label = '2900', value = 2900, description = '2900' },
    { label = '3000', value = 3000, description = '3000' },
    { label = '3100', value = 3100, description = '3100' },
    { label = '3200', value = 3200, description = '3200' },
    { label = '3300', value = 3300, description = '3300' },
    { label = '3400', value = 3400, description = '3400' },
    { label = '3500', value = 3500, description = '3500' },
    { label = '3600', value = 3600, description = '3600' },
    { label = '3700', value = 3700, description = '3700' },
    { label = '3800', value = 3800, description = '3800' },
    { label = '3900', value = 3900, description = '3900' },
    { label = '4000', value = 4000, description = '4000' },
    { label = '4100', value = 4100, description = '4100' },
    { label = '4200', value = 4200, description = '4200' },
    { label = '4300', value = 4300, description = '4300' },
    { label = '4400', value = 4400, description = '4400' },
    { label = '4500', value = 4500, description = '4500' },
    { label = '4600', value = 4600, description = '4600' },
    { label = '4700', value = 4700, description = '4700' },
    { label = '4800', value = 4800, description = '4800' },
    { label = '4900', value = 4900, description = '4900' },
    { label = '5000', value = 5000, description = '5000' },
    { label = '5100', value = 5100, description = '5100' },
    { label = '5200', value = 5200, description = '5200' },
    { label = '5300', value = 5300, description = '5300' },
    { label = '5400', value = 5400, description = '5400' },
    { label = '5500', value = 5500, description = '5500' },
    { label = '5600', value = 5600, description = '5600' },
    { label = '5700', value = 5700, description = '5700' },
    { label = '5800', value = 5800, description = '5800' },
    { label = '5900', value = 5900, description = '5900' },
    { label = '6000', value = 6000, description = '6000' },
    { label = '6100', value = 6100, description = '6100' },
    { label = '6200', value = 6200, description = '6200' },
    { label = '6300', value = 6300, description = '6300' },
    { label = '6400', value = 6400, description = '6400' },
    { label = '6500', value = 6500, description = '6500' },
    { label = '6600', value = 6600, description = '6600' },
    { label = '6700', value = 6700, description = '6700' },
    { label = '6800', value = 6800, description = '6800' },
    { label = '6900', value = 6900, description = '6900' },
    { label = '7000', value = 7000, description = '7000' },
    { label = '7100', value = 7100, description = '7100' },
    { label = '7200', value = 7200, description = '7200' },
    { label = '7300', value = 7300, description = '7300' },
    { label = '7400', value = 7400, description = '7400' },
    { label = '7500', value = 7500, description = '7500' },
    { label = '7600', value = 7600, description = '7600' },
    { label = '7700', value = 7700, description = '7700' },
    { label = '7800', value = 7800, description = '7800' },
    { label = '7900', value = 7900, description = '7900' },
    { label = '8000', value = 8000, description = '8000' }}})
altbutton:On('select', function(item, value)
    altitude = value
                        -- 高度分成三个模式，上升，下降，巡航
                -- 舵量打提前量

                if currentalt - altitude > 100 then
                    hightmode = 1
                elseif altitude - currentalt > 100 then
                    hightmode = 0
                else
                    hightmode = 2
                end

                
    print (altitude)
end)




local headingbutton = apmenu:AddSlider({ icon = '❤️', label = 'Heading', value = 180, values = {
    { label = '0', value = 0, description = '0' },
    { label = '5', value = 5, description = '5' },
    { label = '10', value = 10, description = '10' },
    { label = '15', value = 15, description = '15' },
    { label = '20', value = 20, description = '20' },
    { label = '25', value = 25, description = '25' },
    { label = '30', value = 30, description = '30' },
    { label = '35', value = 35, description = '35' },
    { label = '40', value = 40, description = '40' },
    { label = '45', value = 45, description = '45' },
    { label = '50', value = 50, description = '50' },
    { label = '55', value = 55, description = '55' },
    { label = '60', value = 60, description = '60' },
    { label = '65', value = 65, description = '65' },
    { label = '70', value = 70, description = '70' },
    { label = '75', value = 75, description = '75' },
    { label = '80', value = 80, description = '80' },
    { label = '85', value = 85, description = '85' },
    { label = '90', value = 90, description = '90' },
    { label = '95', value = 95, description = '95' },
    { label = '100', value = 100, description = '100' },
    { label = '105', value = 105, description = '105' },
    { label = '110', value = 110, description = '110' },
    { label = '115', value = 115, description = '115' },
    { label = '120', value = 120, description = '120' },
    { label = '125', value = 125, description = '125' },
    { label = '130', value = 130, description = '130' },
    { label = '135', value = 135, description = '135' },
    { label = '140', value = 140, description = '140' },
    { label = '145', value = 145, description = '145' },
    { label = '150', value = 150, description = '150' },
    { label = '155', value = 155, description = '155' },
    { label = '160', value = 160, description = '160' },
    { label = '165', value = 165, description = '165' },
    { label = '170', value = 170, description = '170' },
    { label = '175', value = 175, description = '175' },
    { label = '180', value = 180, description = '180' },
    { label = '185', value = 185, description = '185' },
    { label = '190', value = 190, description = '190' },
    { label = '195', value = 195, description = '195' },
    { label = '200', value = 200, description = '200' },
    { label = '205', value = 205, description = '205' },
    { label = '210', value = 210, description = '210' },
    { label = '215', value = 215, description = '215' },
    { label = '220', value = 220, description = '220' },
    { label = '225', value = 225, description = '225' },
    { label = '230', value = 230, description = '230' },
    { label = '235', value = 235, description = '235' },
    { label = '240', value = 240, description = '240' },
    { label = '245', value = 245, description = '245' },
    { label = '250', value = 250, description = '250' },
    { label = '255', value = 255, description = '255' },
    { label = '260', value = 260, description = '260' },
    { label = '265', value = 265, description = '265' },
    { label = '270', value = 270, description = '270' },
    { label = '275', value = 275, description = '275' },
    { label = '280', value = 280, description = '280' },
    { label = '285', value = 285, description = '285' },
    { label = '290', value = 290, description = '290' },
    { label = '295', value = 295, description = '295' },
    { label = '300', value = 300, description = '300' },
    { label = '305', value = 305, description = '305' },
    { label = '310', value = 310, description = '310' },
    { label = '315', value = 315, description = '315' },
    { label = '320', value = 320, description = '320' },
    { label = '325', value = 325, description = '325' },
    { label = '330', value = 330, description = '330' },
    { label = '335', value = 335, description = '335' },
    { label = '340', value = 340, description = '340' },
    { label = '345', value = 345, description = '345' },
    { label = '350', value = 350, description = '350' },
    { label = '355', value = 355, description = '355' },
    { label = '360', value = 360, description = '360' }}})
headingbutton:On('select', function(item, value)
    --判断是否需要转向
    if math.abs(currentheading - value) > 10 then
        hdgmode = 1
    else
        hdgmode = 0
    end
    heading = value
    print (heading)
end)

local clbrate = 1.1
-- 1-2,0.1为步长
local clbratebutton = heightsubmenu:AddSlider({ icon = '❤️', label = 'climb Rate', value = 1, values = {

    { label = '1.1', value = 1.1, description = '1.1' },
    { label = '1.2', value = 1.2, description = '1.2' },
    { label = '1.3', value = 1.3, description = '1.3' },
    { label = '1.4', value = 1.4, description = '1.4' },
    { label = '1.5', value = 1.5, description = '1.5' },
    { label = '1.6', value = 1.6, description = '1.6' },
    { label = '1.7', value = 1.7, description = '1.7' },
    { label = '1.8', value = 1.8, description = '1.8' },
    { label = '1.9', value = 1.9, description = '1.9' },
    { label = '2', value = 2, description = '2' },
    { label = '1', value = 1, description = '1' }}})

clbratebutton:On('select', function(item, value)
    clbrate = value
    print (clbrate)
end)
local desrate = 0.2
-- 0.05-0.4 ,0.05为步长
local desratebutton = heightsubmenu:AddSlider({ icon = '❤️', label = 'Descent Rate', value = 0.2, values = {

    { label = '0.2', value = 0.2, description = '0.2' },
    { label = '0.25', value = 0.25, description = '0.25' },
    { label = '0.3', value = 0.3, description = '0.3' },
    { label = '0.35', value = 0.35, description = '0.35' },
    { label = '0.4', value = 0.4, description = '0.4' },
    { label = '0.05', value = 0.05, description = '0.05' },
    { label = '0.1', value = 0.1, description = '0.1' },
    { label = '0.15', value = 0.15, description = '0.15' }}})
desratebutton:On('select', function(item, value)
    desrate = value
    print (desrate)
end)

local crzrate = 1.5
-- 1-2.5,0.1为步长
local crzratebutton = heightsubmenu:AddSlider({ icon = '❤️', label = 'Cruise Rate', value = 1.5, values = {

    { label = '1.5', value = 1.5, description = '1.5' },
    { label = '1.6', value = 1.6, description = '1.6' },
    { label = '1.7', value = 1.7, description = '1.7' },
    { label = '1.8', value = 1.8, description = '1.8' },
    { label = '1.9', value = 1.9, description = '1.9' },
    { label = '2', value = 2, description = '2' },
    { label = '2.1', value = 2.1, description = '2.1' },
    { label = '2.2', value = 2.2, description = '2.2' },
    { label = '2.3', value = 2.3, description = '2.3' },
    { label = '2.4', value = 2.4, description = '2.4' },
    { label = '2.5', value = 2.5, description = '2.5' },
    { label = '1', value = 1, description = '1' },
    { label = '1.1', value = 1.1, description = '1.1' },
    { label = '1.2', value = 1.2, description = '1.2' },
    { label = '1.3', value = 1.3, description = '1.3' },
    { label = '1.4', value = 1.4, description = '1.4' }}})
crzratebutton:On('select', function(item, value)
    crzrate = value
    print (crzrate)
end)

local vs = 2000
-- 100-3000,100为步长
local vsbutton = heightsubmenu:AddSlider({ icon = '❤️', label = 'Vertical Speed', value = 2000, values = {

    { label = '2000', value = 2000, description = '2000' },
    { label = '2100', value = 2100, description = '2100' },
    { label = '2200', value = 2200, description = '2200' },
    { label = '2300', value = 2300, description = '2300' },
    { label = '2400', value = 2400, description = '2400' },
    { label = '2500', value = 2500, description = '2500' },
    { label = '2600', value = 2600, description = '2600' },
    { label = '2700', value = 2700, description = '2700' },
    { label = '2800', value = 2800, description = '2800' },
    { label = '2900', value = 2900, description = '2900' },
    { label = '3000', value = 3000, description = '3000' },
    { label = '100', value = 100, description = '100' },
    { label = '200', value = 200, description = '200' },
    { label = '300', value = 300, description = '300' },
    { label = '400', value = 400, description = '400' },
    { label = '500', value = 500, description = '500' },
    { label = '600', value = 600, description = '600' },
    { label = '700', value = 700, description = '700' },
    { label = '800', value = 800, description = '800' },
    { label = '900', value = 900, description = '900' },
    { label = '1000', value = 1000, description = '1000' },
    { label = '1100', value = 1100, description = '1100' },
    { label = '1200', value = 1200, description = '1200' },
    { label = '1300', value = 1300, description = '1300' },
    { label = '1400', value = 1400, description = '1400' },
    { label = '1500', value = 1500, description = '1500' },
    { label = '1600', value = 1600, description = '1600' },
    { label = '1700', value = 1700, description = '1700' },
    { label = '1800', value = 1800, description = '1800' },
    { label = '1900', value = 1900, description = '1900' }}})
vsbutton:On('select', function(item, value)
    vs = value
    print (vs)
end)



-- 获取垂直速度
local lastalt = 0;
local currentvs = 0;
local currentvss = 0;
Citizen.CreateThread(function()
    -- 每0.1秒更新一次
    while true do
        Citizen.Wait(100);
        local ped = GetPlayerPed(-1);
        local alt = GetEntityCoords(ped).z;
        local vsimps =  (lastalt - alt) * 600;
        currentvss = (- math.floor(vsimps * 1.94384) - currentvs) * 10;
        currentvs = - math.floor(vsimps * 1.94384);
        lastalt = alt;

    end 
end)

--检测转向速率
local lastheading = 0;
local currentangularspeed = 0;
Citizen.CreateThread(function()
    -- 每0.1秒更新一次
    while true do
        Citizen.Wait(100);
        local ped = GetPlayerPed(-1);
        local headingnow = GetEntityHeading(ped);
        headingnow = - (headingnow-360)
        currentangularspeed = (headingnow - lastheading) * 10;
        lastheading = headingnow;
    end 
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1)
        local playerped = GetPlayerPed(-1)
        local vehicle = GetVehiclePedIsIn (playerped, false)
        local coords = GetEntityCoords(playerped)
        currentalt = coords.z * 3.28084
        local currentroll = GetEntityRotation(vehicle,2)[2]
        currentheading = GetEntityHeading(playerped)
        currentheading = - (currentheading-360)
        if ap then
            -- print ('ap')

            if mode == modes.HDG then
                -- print ('hdg')
                -- 平飞
                -- 高度部分
                
                local controllevel = 0


                -- 高度控制,0 上升 1 下降 2 巡航
                if hightmode == 2 then
                    --根据升降率和高度差的关系来控制，会打提前量
                    if currentvs/vs < (altitude - currentalt)/500 then
                        controllevel = ((altitude - currentalt) / 500 - currentvs/vs)*crzrate
                    else
                        controllevel = - ((currentvs/vs - (altitude - currentalt) / 500))*crzrate
                    end
                    
                
                elseif hightmode == 0 then
                    --偏差小于50直接进入巡航
                    if altitude - currentalt < 50 then
                        hightmode = 2
                    end
                    --将上升率控制在2000，并且在到达之前提前打杆
                    --如果高度差小于1000，提前打杆
                    if altitude - currentalt < 500 then
                        --慢慢打负杆来进入巡航
                        -- 升降率是高度差的关系
                        if currentvs/vs < (altitude - currentalt)/500 then
                            controllevel = (altitude - currentalt) / 500 - currentvs/vs
                        else
                            controllevel = - (currentvs/vs - (altitude - currentalt) / 500)
                        end
                    else
                        --上升率控制在2000
                        -- controllevel = (2000-currentvs) / 500
                        -- 根据升降率率(vss)和升降率差来控制
                        if currentvss/vs < (vs - currentvs)/500 then
                            controllevel = ((vs - currentvs) /500 - currentvss/vs)*clbrate
                        else
                            controllevel = - ((currentvss/vs - (vs- currentvs) / 500))*clbrate
                        end

                    end

                elseif hightmode == 1 then
                    --参考上升，也是打提前量
                    if currentalt - altitude < 50 then
                        hightmode = 2
                    end
                    if currentalt - altitude < 500 then
                        --慢慢打正杆来进入巡航
                        -- 升降率是高度差的关系
                        if currentvs/vs < (currentalt - altitude)/500 then
                            controllevel = -(currentalt - altitude) / 500 - currentvs/vs
                        else
                            controllevel =  (currentvs/vs - (currentalt - altitude) / 500)
                        end
                    else
                        --下降率控制在2000
                        if currentvss/vs < (vs + currentvs)/500 then
                            controllevel = -((vs + currentvs) / 500 - currentvss/vs)*desrate
                        else
                            controllevel =  ((currentvss/vs - (vs + currentvs) / 500))*desrate
                        end
                    end
                end

  
                -- 航向部分
                local headingcontrol = 0
                -- 正是右,负是左
                local lr = 0
                -- 判断是左转还是右转
                if heading - currentheading > 180 then
                    lr = -1
                elseif heading - currentheading < -180 then
                    lr = 1
                else
                    if heading - currentheading > 0 then
                        lr = 1
                    else
                        lr = -1
                    end
                end
                -- print (lr)
                --真正的控制
                
                angle = heading- currentheading
                if angle > 180 then
                    angle = angle - 360
                elseif angle < -180 then
                    angle = angle + 360
                end
                if hdgmode == 0 then
                    --平飞
                    --计算角度之间的绝对距离，因为存在360度的问题

                        
                    --打提前量,通过转向速率和转向差来控制
                    --如果偏左
                    

                    -- if angle  < currentangularspeed then
                    --     headingcontrol =  -(currentangularspeed/10 - angle/10)/3
                    -- else

                        headingcontrol = -((currentroll/20) - (angle/10))/3

                    -- e5
                        --提前打杆
                    if (angle < 10 and angle > 1 )or (angle > -10 and angle < -1) then
                        headingcontrol = headingcontrol * (10/math.abs(angle))
                    end


                    -- 确保不会打过头，角度小于roll
                    if angle > 0 then
                        if currentroll > roll-10 and headingcontrol > 0 then
                            headingcontrol = 0.0
                            print ('rightstop')
                        end
                    else
                        if currentroll < -roll+10 and headingcontrol < 0 then
                            headingcontrol = 0.0
                            print ('leftstop')
                        end
                    end

                elseif hdgmode == 1 then
                    --转向
                    if math.abs(angle) < 20 then
                        hdgmode = 0
                    end
                    
                    if lr == 1 then -- 右转
                        --打提前量,通过roll和转向差来控制
                        if currentroll < roll then
                            headingcontrol = (roll-currentroll)/roll
                        else 
                            headingcontrol = (roll-currentroll)/roll
                        end

                    elseif lr == -1 then -- 左转
                        --打提前量,通过roll和转向差来控制
                        if currentroll < -roll then
                            headingcontrol = (currentroll+roll)/-roll
                        else
                            headingcontrol = (currentroll+roll)/-roll
                        end
                    end

                end

                        

                    

                

                
                    
                drawTxt('Altitude: ' .. currentalt, 4, {255, 255, 255, 255}, 0.5, 0.5, 0.5)
                drawTxt('Heading: ' .. currentheading, 4, {255, 255, 255, 255}, 0.5, 0.5, 0.55)
                drawTxt('VS: ' .. currentvs, 4, {255, 255, 255, 255}, 0.5, 0.5, 0.6)
                drawTxt('Control: ' .. controllevel, 4, {255, 255,255, 255}, 0.5, 0.5, 0.65)
                drawTxt('angle'..angle, 4, {255, 255, 255, 255}, 0.5, 0.5, 0.7)
                drawTxt('roll: ' .. currentroll, 4, {255, 255, 255, 255}, 0.5, 0.5, 0.75)
                drawTxt('threading: ' ..  currentangularspeed, 4, {255, 255, 255, 255}, 0.5, 0.5, 0.8)
                drawTxt('headingcontrol: ' .. headingcontrol, 4, {255, 255, 255, 255}, 0.5, 0.5, 0.85)


                --操控飞机

                SetControlNormal(2 ,110, controllevel)
                SetControlNormal(2 ,107, headingcontrol)
                



            end
        end
    end
end)

                    




apmenu:OpenWith('KEYBOARD', 'F4')