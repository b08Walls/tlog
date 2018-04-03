
--[[En esta variable local se guarda el valor que tenia el contador de tiempo del micro al momento de ser ejecutada la
    interrupcion, esto con el fin de evitar que falsos en el boton generen dos interrupciones]]
gpio.mode(statusLedPin,gpio.OUTPUT)
gpio.write(statusLedPin,gpio.LOW)
--[[En esta funcion local se generan el archivo HTML que se va a mostrar en el servidor cuando se entre en modo de
    configuracion, dentro del micro ya se encuentran guardado el template archivo general en dos partes, por medio 
    de esta funcion se crea el archivo general colocando en medio el codigo html para mostrar las redes escaneadas
    por el dispositivo]]
function loadNetworks(lista,html)

    print("ESCRIBIENDO INICIO")
    --Se abre el archivo de la parte1
    part1 = file.open("enduser_part1.html","r");
    --Se escribe la primera parte en el archivo general
    html:write(part1:read())
    --Se cierra la lectura del archivo parte1
    part1:close()

    --Con la lista de redes recibida en el metodo se crean y escriben los elementos HTML para visualizar las redes
    for k,v in pairs(lista) do
        html:write('<option>'..v..'</option>')
        print("linea html agregada")
    end

    print("ESCRIBIENDO FINAL")
    --Se abre la lectura del archivo de la parte 2
    part2 = file.open("enduser_part2.html","r");
    --Se escribe en el archivo general la parte 2
    html:write(part2:read())
    --Se cierra la lectura del archivo parte2
    part2:close();

    --Se cierra la escritura del archivo general
    html:close();

    print("archivo terminado")
    print("iniciando configuracion")

	wifi.eventmon.register(wifi.eventmon.STA_CONNECTED, function(T)
	print("\n\tSTA - CONNECTED".."\n\tSSID: "..T.SSID.."\n\tBSSID: "..
	T.BSSID.."\n\tChannel: "..T.channel)


	print("CONECCION REALIZADA") 

	enduser_setup.stop()

    print("SE HA TERMINADO LA CONFIGURACION") 
    -- enableWifiButton = true

    --Se detiene el modulo de configuracion
    print("se termino configuracion")
    --Se cambia el modulo wifi a modo STATION, es decir apaga el access point
    wifi.setmode(wifi.STATION)
    --Nuevamente se habilita la interrupcion del GPIO D2, el cual inicializa el modo de configuracion.
    enableWifiButton = true

    print("BOTON HABILITADO")

    gpio.write(statusLedPin,gpio.HIGH)

    file.remove("init.lua")
    node.restart()

	end)

    --Se inicializa el modulo WIFI como access point con el nombre BeaconDetector y sin clave alguna
    wifi.ap.config({ssid="BeaconDetector"..node.chipid(),auth=wifi.OPEN})
    --Se configura el modulo de configuracion en modo manual para poder decidir cuando este deja de funcionar
    enduser_setup.manual(true)
    --Se inicializa el modulo de configuracion con sus respectivas funciones de "callback"
    enduser_setup.start(function() 

    	print("CONECCION REALIZADA") 

    	enduser_setup.stop()

        print("SE HA TERMINADO LA CONFIGURACION") 
        -- enableWifiButton = true

        --Se detiene el modulo de configuracion
        print("se termino configuracion")
        --Se cambia el modulo wifi a modo STATION, es decir apaga el access point
        wifi.setmode(wifi.STATION)
        --Nuevamente se habilita la interrupcion del GPIO D2, el cual inicializa el modo de configuracion.
        enableWifiButton = true

        print("BOTON HABILITADO")

        statusLedTmr:stop()
        statusLedTmr:unregister()
        
        gpio.write(statusLedPin,gpio.HIGH)

        file.remove("init.lua")
        node.restart()

    	end, function () 
    	print("ERROR")
    end)
    print("fin de la configuracion")

end

--[[Funcion local que se va a ejecutar al finalizar el escaneo de las redes, el parametro t recibira una lista con los 
    nombres de las redes dentro del alcance]]
function listap(t)

    --Se genera otra lista para colocar en ella solo los nombres
    local list = {};

    --Se recorre la lista original y se guardan los nombres en la variable local list
    for k,v in pairs(t) do
        print(k.." *:* "..v)
        list[#list+1]=k
    end

    --Se borra cualquier remanente del archivo de configuracion
    file.remove("enduser_setup.html")
    print("ARCHIVO BORRADO")
    --Se crea un nuevo archivo en blanco
    htmlFile = file.open("enduser_setup.html","w+");
    --Si el archivo fue creado con exito se procede a la creacion de este con las redes escaneadas
    if htmlFile then
        print("iniciando escritura")
        loadNetworks(list,htmlFile)
    else
        --[[En caso de que ocurra un error con la creacion del archivo se vuelve a llamar un escaneo de esta forma
            aseguramos la visualcion de las redes y manejamos el error]]
        print("error en escritura intentando de nuevo")
        wifi.sta.getap(listap)
    end

end

--Se desconecta de cualquier red
wifi.sta.disconnect()
--Se inicia la configuracion de red WIFI
wifi.setmode(wifi.STATIONAP)
wifi.sta.getap(listap)

if not statusLedTmr then
    statusLedTmr = tmr.create()
    print("Timer creado")
end

statusLedTmr:stop()
statusLedTmr:unregister()
statusLedTmr:register(1000,1,function()
    gpio.serout(statusLedPin,gpio.HIGH,{200000,100000},2,function() end)
end)

statusLedTmr:start()


--Al finalizar la ejecucion del codigo, se actualizara el nuevo valor pasado de la interrupcion, con el valor
--actual.
past = now




