------------------------------------------------------------------------------------------------------------------------------|
--[[Funcion para inicializar la comunicacion UART]]---------------------------------------------------------------------------|
------------------------------------------------------------------------------------------------------------------------------|
function initUART()

    local function getUartCallBack()

        local buffer = "";

        local function getValores(data)


            local function getDistancia(power,signal)
                resta = -57-tonumber(signal)
                distance = 10.0^(resta/20)
                print("********************************")
                print("SIGNAL: ",signal,"DISTANCE: ",distance)
                print("********************************")
                return distance
            end

            s,e = data:find("OK%+DISIS[%a%d%p%x]+OK%+DISCE")
            if s and e then
                -- vaciar el string general
                --print("Se encontro string")
                --[[Variable local donde se guardan los valores que se van a retornar a partir del metodo]]
                local beacons = {}

                --[[Este ciclo for recorre todos los valores capturados]]
                for word in data:gmatch("%+DISC:[%a%d%p]-OK") do 
                    --Variable local donde se guarda la linea a procesar una vez que fue filtrada
                    local valores = word:gsub("+DISC",""):gsub("OK",":")

                    --Objeto beaconData en el cual se guardaran los valores correspondientes al beacon encontrado en esta linea
                    local beaconData={}

                    --Funcion que se encarga de generar el string JSON que representa al objeto beaconData
                    beaconData.getJSON = function(v)
                        local b = {}
                        
                        for c,u in pairs(v) do
                            if type(u)~="function" then
                                --print(c .. ":  " .. u)
                                b[c]=u
                            end--TERMINA EL IF
                        end--TERMINA EL FOR

                        ok, json = pcall(sjson.encode,b)
                        if ok then
                            return(json)
                        else
                            print("error json")
                            return nil
                        end--TERMINA IF
                    end--TERMINA FUNCION

                    --Variable local utilizada para guardar los valores correctamente
                    local index = 1

                    --Ciclo for el cual recorre los valores y los separa de manera correcta
                    for valor in valores:gmatch("[%-%a%d]+") do 
                        if index == 2 then
                            beaconData.UUID = valor
                        elseif index == 3 then
                            beaconData.maxLoad = valor:sub(1,4)
                            beaconData.minLoad = valor:sub(5,8)
                            beaconData.txPower = valor:sub(9,10)
                        elseif index == 5 then
                            beaconData.signal = valor
                            beaconData.distancia = getDistancia(60,valor)
                        end
                        index = index+1
                    end--TERMINA EL FOR QUE RECORRE LOS VALORES DE CADA BEACON
                    beacons[#beacons+1] = beaconData
                end--TERMINA EL FOR QUE RECORRE CADA BEACON
                return beacons
            else
                --print("no se encontro string")
                return nil
            end--TERMINA IF PRINCIPAL
        end--TERMINA FUNCION LOCAL getValores

        local mqttTimer = tmr.create()
        mqttTimer:register(5000,1,function()
            if sender then
                sender = sender.initMQTT()
            end
            look()
            btTimer:start()
            end)

        local function updateData(load)

            print("ACTUALIZANDO")
            if sender then
                print("MQTT CLIENT OK")
                if sender.conectado then
                    print("MQTT CLIENT CONECTADO")
                    sender.send(load,"tugger")
                else
                    print("MQTT CLIENT DESCONECTADO, RECONECTANDO")
                    print("TMR DE RECONECCION INICIADO")
                    mqttTimer:start()
                    sender.connect(load)
                    --updateData(load)
                end
            else
                print("MQTT CLIENT = nil!, INICIALIZANDO")
                sender = initMQTT()
                updateData(load)
            end
        end--TERMINA FUNCION UPDATE DATA

        local function initMQTT()
            --Se crea el objeto del cliente de MQTT, con su nombre, tiempo de vida
            --usuario y contrasenia

            local sender = {}

            
            --sender.m = mqtt.Client("clientid",120,"xxjpxcmq","Bp48RyeHOmBc")
            sender.m = mqtt.Client("clientid",120)
            --m = mqtt.Client("clientid",120)

            
            sender.conectado = false;--variable para saber el status de la coneccion

            --Se declaran las funciones "callback" para los eventos basicos del cliente
            
            sender.m:lwt("/lwt","adios mundo cruel",0,0)--"last will"
            sender.m:on("connect",function(client) print("CONECTADO DESDE OBJETO MQTTCLIENT") conectado = true end)--cuando se conecta
            sender.m:on("offline",function(client) print("DESCONECTADO OFFLINE") conectado = false end)--cuando se desconecta
            sender.m:on("message",function(client,topic,data)--cuando llega un mensaje
                print(topic..":")
                if data ~= nil then
                    print(data)
                end
            end)

            --Se conecta el cliente al broker y dependiendo del resultado del intento de coneccion
            --se pueden ejecutar dos funciones diferentes.

            function sender.connect(data)
                --sender.m:connect("m14.cloudmqtt.com",10246,0,
                sender.m:connect("10.42.0.1",1883,0,
                --m:connect("192.168.4.2",1883,0,
                    --FUNCION A REALIZAR CUANDO SE CONECTA CORRECTAMENTE
                    function(client)
                        mqttTimer:stop()
                        print("CONECTADO, TMR DE RECONECCION DETENIDO")
                        sender.conectado = true
                        client:subscribe("/cloud",0,function(client) print("subscrito")
                                if data then
                                    print("mandando datos desde rutina de conectado");
                                    updateData(data)
                                end
                            end)
                    end,
                    --FUNCION A REALIZAR CUANDO NO SE LOGRA CONECTAR
                    function(client,reason)
                        print("failed, reason: "..reason)
                end)--TERMINA m:connect
            end

            local function good(client)
                print("MENSAJE MQTT RECIBIDO EN SERVIDOR")--print informativo
                mqttTimer:stop()
                btTimer:start()
                look()
            end

            --[[Al final el metodo retorna una funcion para el envio de mensajes, esto encapsula
            todas las variables evitando la creacion de variables globales en el codigo principal]]--
            function sender.send(load,topico)
                print("INICIANDO CARGA")
                print(load)
                mqttTimer:start()
                for k,v in pairs(load) do
                    print("INICIANDO TIMER DENTRO DE FOR")
                    mqttTimer:start()
                    print("INTENTANDO ENVIAR: ",v)
                    sender.m:publish(topico, v,0,0,good)
                    print("ENVIO: ",k)
                end    
                print("TERMINADO");    
            end

            function sender.close()
                sender.m:close()
            end

            function sender.initMQTT()
                return initMQTT()
            end

            return sender
        end--TERMINA FUNCION initMQTT

        sender = initMQTT();
        
        

        local function process(data)
            btTimer:stop()
            print("TMR BT PRINCIPAL DETENIDO")
            btTimerR:start()
            print("TMR ERROR EN BT INICIADO - 10s")
            if data then
                print("Datos recibidos de BT")
                buffer = buffer..data

                if buffer:find("quit") then
                    print("****DETENER RUTINA****")
                    uart.on("data")
                    btTimer:stop()
                end

                local beacons = getValores(buffer)
                local jsons = {}

                if beacons then
                    print("OBJETOS BEACON RECIBIDOS")
                    for k,v in pairs(beacons) do
                        jsons[#jsons+1] = v:getJSON()
                    end
                    print("JSON's LISTOS")
                    btTimerR:stop()
                    print("TMR ERROR EN BT DETENIDO")
                    print("BUFFER A ENVIAR: ",buffer)
                    updateData(jsons)
                    jsons = nil
                    buffer = ""
                    looking = false
                    btTry = 0
                end --if beacons
            end --if data
        end--TERMINA FUNCION

        return process
    end--TERMINA FUNCION GET UART CALLBACK

    uart.setup(1,115200,8,uart.PARITY_NONE,uart.STOPBITS_1,0)
    uart.setup(0,115200,8,uart.PARITY_NONE,uart.STOPBITS_1,0)
    uart.on("data",0,getUartCallBack(),0)
end

initUART()
print("UART READY")
initUART = nil
