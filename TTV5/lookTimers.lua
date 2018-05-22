------------------------------------------------------------------------------------------------------------------------------|
--[[ARCHIVO:               : lookTimers.lua ----------------------------------------------------------------------------------|
    AUTOR                  : Octavio R. Paredes G. ---------------------------------------------------------------------------|
    ULTIMA MODIFICACION:   : Jueves 15 de Febrero 2018 -----------------------------------------------------------------------| 
    DESCRIPCION:           : En este archivo se encuentras las rutinas necesarias para la incializacion y manejo de timers y  |
                             otras variables globales usadas en toda la aplicacion                                           ]]
------------------------------------------------------------------------------------------------------------------------------|

--Variable global usada para llevar la cuenta de ciclos reportados
count = 0
--Variable global para desactivar nuevas busquedas mientras una busqueda ya esta siendo llevada acabo
looking = false
--Variable global para desactivar la interrupcion del GPIO D2 mientras el micro se encuentra en modo de configuracion
enableWifiButton = true

local statusLedPin = 3

if not statusLedTmr then
    statusLedTmr = tmr.create()
end

--[[Funcion global primordial en el funcionamiento de la aplicacion se encarga de iniciar el ciclo de busqueda, es el primer 
    paso de todo el algoritmo]]
function look()
    --[[Se corrobora la conexion a la red verificando la direccion IP del dispositivo]]
    local wifiOK = wifi.sta.getip()
    --[[En caso de tener direccion IP Y no estar realizando otra busqueda]]
    if wifiOK and not looking then
        --[[Se verifica si el modulo wifi se encuentra en modo mixto(conectado y ofreciendo red), de ser asi al ya tener 
            conexion se desactiva el modo access point, conservando solamente la conexion a la red]]

        if not sender.conectado then
            sender.connect()
        end

        print("MODO WIFI: ",wifi.getmode())
        print("VALOR DE STATIONAP: ",wifi.STATIONAP)
        if wifi.getmode() == wifi.STATIONAP then            
            --Se detiene el modulo de configuracion
            print("se termino configuracion")
            enduser_setup.stop()
            --Se cambia el modulo wifi a modo STATION, es decir apaga el access point
            wifi.setmode(wifi.STATION)
            --Nuevamente se habilita la interrupcion del GPIO D2, el cual inicializa el modo de configuracion.
            enableWifiButton = true

            print("BOTON HABILITADO")
        end

        statusLedTmr:stop()
        statusLedTmr:unregister()
        
        gpio.write(statusLedPin,gpio.HIGH)
        print("WIFI OK, IP",wifiOK)
        --Se solicitara al BT realice la busqueda de dispositivos
        uart.write(1,"AT+DISI?")
        print("BUSQUEDA SOLICITADA A BT")
        --[[Se aumenta la cuenta del numero de busquedas realizadas esto solo para fines de depuracion]]
        count = count+1
        print(count)
        --Se guarda el estado de busqueda para evitar dos busquedas simultaneas.
        looking = true
    else
        if not wifiOK then
            print("NO WIFI")

            if wifi.getmode() ~= wifi.STATIONAP then
                statusLedTmr:stop()
                statusLedTmr:unregister()
                statusLedTmr:register(100,1,function()
                    gpio.write(statusLedPin,(gpio.read(statusLedPin)==1 and 0) or (gpio.read(statusLedPin) == 1 or 1))
                end)
            end

            statusLedTmr:start()
        end
    end
end

------------------------------------------------------------------------------------------------------------------------------|
--[[Esta funcion crea todos los timers necesarios para la operacion del sistema]]---------------------------------------------|
------------------------------------------------------------------------------------------------------------------------------|
btTry = 0
function initTMR()

    local function btReset()
        local btResetPin = 1
        -- if btTry >= 5 then
        if btTry%3 == 0 then
            print("RESETEANDO BT")
            --apagar pin bt

            gpio.serout(1,gpio.LOW,{100,20000000,100},1,function() print("BT RESETEADO")end)
            -- gpio.write(btResetPin,gpio.HIGH)
            -- --delay de 2s
            -- tmr.delay(2000000)
            -- --encender pin bt
            -- gpio.write(btResetPin,gpio.LOW)
            -- btTry = 0
            -- print("BT RESETEADO")
        end

        if btTry > 12 then node.restart() end
    end

    --Este timer tiene la funcion de preguntar al BT por una nueva busqueda en caso de no obtener respuesta
    btTimer = tmr.create()
    btTimer:register(2500,1,function()
        looking = false
        look()
        btTry = btTry+1
        count = btTry
        btReset()
        end)
    btTimer:start()

    btTimerR = tmr.create()
    btTimerR:register(10000,1,function()
        btTimer:start()
        btTimerR:stop()
        looking = false
        look()
        btTry = btTry+1
        btReset()
    end)

    
    
end

initTMR()
print("TMR READY")
initTMR = nil
