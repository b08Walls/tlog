------------------------------------------------------------------------------------------------------------------------------|
--[[ARCHIVO:               : gpioConfig.lua ----------------------------------------------------------------------------------|
    AUTOR                  : Octavio R. Paredes G. ---------------------------------------------------------------------------|
    ULTIMA MODIFICACION:   : Jueves 15 de Febrero 2018 -----------------------------------------------------------------------| 
    DESCRIPCION:           : En este archivo se encuentran las rutinas necesarias para la inicializacion y manejo de los GPIO |
                                                                                                                             ]]
------------------------------------------------------------------------------------------------------------------------------|

------------------------------------------------------------------------------------------------------------------------------|
--[[Funcion para inicializar los pines GPIO]]---------------------------------------------------------------------------------|
------------------------------------------------------------------------------------------------------------------------------|
function initGPIO()

    local statusLedPin = 3

    --------------------------------------------------------------------------------------------------------------------------|
    ---FUNCIONES DE CONFIGURACION PARA EL PIN D2------------------------------------------------------------------------------|
    --------------------------------------------------------------------------------------------------------------------------|

    --[[Esta funcion local retorna la funcion a ejecutar para la interrupcion del pin D2, importante mencionar que al contener
    funciones y variables locales al momento de retornar la funcion resultante se genera un enclosure.]]
    local function getIntD2()

        --[[En esta variable local se guarda el valor que tenia el contador de tiempo del micro al momento de ser ejecutada la
            interrupcion, esto con el fin de evitar que falsos en el boton generen dos interrupciones]]
        local past = 0;

        --[[En esta funcion local se generan el archivo HTML que se va a mostrar en el servidor cuando se entre en modo de
            configuracion, dentro del micro ya se encuentran guardado el template archivo general en dos partes, por medio 
            de esta funcion se crea el archivo general colocando en medio el codigo html para mostrar las redes escaneadas
            por el dispositivo]]
        local function loadNetworks(lista,html)

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

            --Se inicializa el modulo WIFI como access point con el nombre BeaconDetector y sin clave alguna
            wifi.ap.config({ssid="BeaconDetector"..node.chipid(),auth=wifi.OPEN})
            --Se configura el modulo de configuracion en modo manual para poder decidir cuando este deja de funcionar
            enduser_setup.manual(true)
            --Se inicializa el modulo de configuracion con sus respectivas funciones de "callback"
            enduser_setup.start(function() print("CONECCION REALIZADA") end, function () 
                print("SE HA TERMINADO LA CONFIGURACION") 
                enableWifiButton = true
                end)
            print("fin de la configuracion")

        end

        --[[Funcion local que se va a ejecutar al finalizar el escaneo de las redes, el parametro t recibira una lista con los 
            nombres de las redes dentro del alcance]]
        local function listap(t)

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

        --[[Funcion que se va a retornar al callback de la interrupcion, nuevamente se creara un enclosure dentro de esta funcion
            Es esta la funcion que va a corroborar que no se esten recibiendo dos pulsaciones del boton en menos de un segundo
            de igual forma inicializara el modo de configuracion]]
        local function intD2(level,now)

            --Se asigna el pin de configuracion al pin numero dos del microcontrolador
            local configModePin = 2
            --Dentro de la funcion se calcula si ha pasado más de un segundo entre una interrupcion y otra para evitar falsos
            if now-past>1000000 and enableWifiButton then
                --Si se entra en modo de configuracion el boton sera inhabilitado para evitar errores en el codigo
                enableWifiButton = false
                --En caso de que el tiempo cumpla con lo deseado se ejecutara el codigo.
                print("INTERRUPCION DETECTADA",level,now)
                --Se desconecta de cualquier red
                wifi.sta.disconnect()
                --Se inicia la configuracion de red WIFI
                wifi.setmode(wifi.STATIONAP)
                wifi.sta.getap(listap)

                if not statusLedTmr then
                    statusLedTmr = tmr.create()
                end

                statusLedTmr:stop()
                statusLedTmr:unregister()
                statusLedTmr:register(1000,1,function()
                    gpio.serout(statusLedPin,gpio.HIGH,{200000,100000},2,function() print("ciclo")end)
                end)


                --Al finalizar la ejecucion del codigo, se actualizara el nuevo valor pasado de la interrupcion, con el valor
                --actual.
                past = now
            end
        end

        --Finalmente se regresa la funcion generando un encapsulado con la variable local past.
        return intD2
    end

    --------------------------------------------------------------------------------------------------------------------------|
    ---FUNCIONES DE CONFIGURACION PARA EL PIN D1------------------------------------------------------------------------------|
    --------------------------------------------------------------------------------------------------------------------------|

    --Se designa el pin de reseteo del bluetooth como el numero 1
    local btResetPin = 1
    --Se configura como salida
    gpio.mode(btResetPin, gpio.OUTPUT)
    --[[Se inicializa su valor como apagado, recordando que por la configuracion del transistor en el circuito LOW encendera
        el bluetooth y HIGH lo apagara.]]
    gpio.write(btResetPin,gpio.LOW)

    --Se designa el pin de configuracion del wifi como el numero 2
    local configModePin = 2
    --Se coloca el modo de este pin en modo INT(interrupcion)
    gpio.mode(configModePin,gpio.INT)
    --[[Se configura la rutina a seguir para la interrupcion esta es:
            *   Numero de pin
            *   Borde de subida
            *   Funcion a ejecutar, funcion resultante de la funcion getIntD2
      ]]
    gpio.trig(configModePin,"up",getIntD2())


    gpio.mode(statusLedPin,gpio.OUTPUT)
    gpio.write(statusLedPin,gpio.HIGH)
end--TERMINA initGPIO()


initGPIO()
initGPIO = nil
print("GPIO's READY")
