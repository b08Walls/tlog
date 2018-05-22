
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

            local s,e = data:find("OK%+DISIS[%a%d%p%x]+OK%+DISCE")
            if s and e then

                local beacons = {}

                --[[Este ciclo for recorre todos los valores capturados]]
                for word in data:gmatch("%+DISC:[%a%d%p]-OK") do 
                    --Variable local donde se guarda la linea a procesar una vez que fue filtrada
                    local valores = word:gsub("+DISC",""):gsub("OK",":")

                    --Objeto beaconData en el cual se guardaran los valores correspondientes al beacon encontrado en esta linea
                    local beaconData={}

                    beaconData.chipid = node.chipid()

                    --Funcion que se encarga de generar el string JSON que representa al objeto beaconData
                    beaconData.getJSON = function(v)
                        local b = {}
                        
                        for c,u in pairs(v) do
                            if type(u)~="function" then
                                --print(c .. ":  " .. u)
                                b[c]=u
                            end--TERMINA EL IF
                        end--TERMINA EL FOR

                        local ok, json = pcall(sjson.encode,b)
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
            sender.m = mqtt.Client("clientid"..node.chipid(),120)
            --m = mqtt.Client("clientid",120)

            
            sender.conectado = false;--variable para saber el status de la coneccion

            --Se declaran las funciones "callback" para los eventos basicos del cliente
            
            sender.m:lwt("/lwt","adios mundo cruel",0,0)--"last will"
            sender.m:on("connect",function(client) print("CONECTADO DESDE OBJETO MQTTCLIENT") conectado = true end)--cuando se conecta
            sender.m:on("offline",function(client) print("DESCONECTADO OFFLINE") conectado = false end)--cuando se desconecta
            

            sender.m:on("message",function(client,topic,data)--cuando llega un mensaje
                print(topic..":",data)
                print("INICIANDO ARCHIVO DE MQTTCALLBACK")
                -- mqttLoad = data
                -- mqttTopic = topic
                assert(loadfile("mqttCallback.lua"))(data,topic,client)
                print("ARCHIVO EJECUTADO")
            end)

            --Se conecta el cliente al broker y dependiendo del resultado del intento de coneccion
            --se pueden ejecutar dos funciones diferentes.

            function sender.connect(data)
                --sender.m:connect("m14.cloudmqtt.com",10246,0,
                --sender.m:connect("10.42.0.1",1883,0,
                sender.m:connect(mqttIP,mqttPort,0,
                    --FUNCION A REALIZAR CUANDO SE CONECTA CORRECTAMENTE
                    function(client)
                        mqttTimer:stop()
                        print("CONECTADO, TMR DE RECONECCION DETENIDO")
                        sender.conectado = true
                        client:subscribe("db/register",0,function(client)
                                print("subscrito a respuesta de registro")
                            end)
                        client:subscribe("nodeCode/",0,function(client)
                                print("subscrito a codigo a distancia")
                            end)
                        client:subscribe("nodeCode/"..node.chipid(),0,function(client)
                                print("subscrito a codigo a distancia especifico")
                                print("CHIPID: ",node.chipid())
                            end)

                        if data then
                            print("mandando datos desde rutina de conectado")
                            updateData(data)
                        end

                        client:publish("node/register","{'chipid':"..node.chipid()..",'mode':'scanner'}",0,0,good)
                    end,
                    --FUNCION A REALIZAR CUANDO NO SE LOGRA CONECTAR
                    function(client,reason)
                        print("failed, reason: "..reason)
                    end)
            end--TERMINA m:connect

            local function good(client)
                print("MENSAJE MQTT RECIBIDO EN SERVIDOR")--print informativo
                mqttTimer:stop()
                btTimer:start()
                look()
            end

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

        sender = initMQTT()

        local function process(data)
            btTimer:stop()
            print("TMR BT PRINCIPAL DETENIDO")
            btTimerR:start()
            print("TMR ERROR EN BT INICIADO - 10s")
            if data then
                print("Datos recibidos de BT")
                buffer = buffer..data
                print(buffer)

                if buffer:find("quit") then
                    print("****DETENER RUTINA****")
                    file.remove("init.lua")
                    uart.on("data")
                    btTimer:stop()
                    node.restart()
                end

                local beacons = getValores(buffer)
                local jsons = {}

                if beacons then
                    print("OBJETOS BEACON RECIBIDOS")
                    for k,v in pairs(beacons) do

                        local tempJson = v:getJSON()

                        print("tempJson",tempJson);

                        if not (tempJson:find('"UUID":"00000000000000000000000000000000"')) then
                            print("SE AGREGARA JSON SE AGREGARA JSON SE AGREGARA JSON")
                            jsons[#jsons+1] = v:getJSON()
                        end
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
