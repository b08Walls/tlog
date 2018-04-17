__Mode = BEACON_INIT

--Se configura como salida
gpio.mode(btResetPin, gpio.OUTPUT)
--[[Se inicializa su valor como apagado, recordando que por la configuracion del transistor en el circuito LOW encendera
    el bluetooth y HIGH lo apagara.]]
gpio.write(btResetPin,gpio.LOW)

dofile("gpioConfig.lua")

programmerTimer = tmr.create()
programmerTimer:register(5000,1,function()
    if programmer then
        programmer = programmer.initRemoteProg()
        programmer.connect()
    end
end)

uart.setup(1,115200,8,uart.PARITY_NONE,uart.STOPBITS_1,0)
uart.setup(0,115200,8,uart.PARITY_NONE,uart.STOPBITS_1,0)

--Se designa el pin de reseteo del bluetooth como el numero 1
local btResetPin = 1
--Se configura como salida
gpio.mode(btResetPin, gpio.OUTPUT)
--[[Se inicializa su valor como apagado, recordando que por la configuracion del transistor en el circuito LOW encendera
    el bluetooth y HIGH lo apagara.]]
gpio.write(btResetPin,gpio.LOW)
        

function initRemoteProg()
    --Se crea el objeto del cliente de MQTT, con su nombre, tiempo de vida
    --usuario y contrasenia

    local sender = {}

    function sender.mqttPrint(load,cliente)
        local c = nil
        if not cliente then c = sender.m else c = cliente end
        c:publish("nodeResponse", load,0,0,function() print("recibido en servidor") end)
    end
    
    --sender.m = mqtt.Client("clientid",120,"xxjpxcmq","Bp48RyeHOmBc")
    sender.m = mqtt.Client("programmerid"..node.chipid(),120)
    --m = mqtt.Client("clientid",120)

    sender.conectado = false;--variable para saber el status de la coneccion
    --Se declaran las funciones "callback" para los eventos basicos del cliente
    
    sender.m:lwt("/lwt","adios mundo cruel",0,0)--"last will"
    sender.m:on("connect",function(client) print("CONECTADO DESDE OBJETO MQTTCLIENT") conectado = true end)--cuando se conecta
    sender.m:on("offline",function(client) print("DESCONECTADO OFFLINE") sender.connect() end)--cuando se desconecta


    sender.m:on("message",function(client,topic,data)--cuando llega un mensaje
        assert(loadfile("mqttCallback.lua"))(data,topic,client)
    end)

    --Se conecta el cliente al broker y dependiendo del resultado del intento de coneccion
    --se pueden ejecutar dos funciones diferentes.

    function sender.connect(data)


        programmerTimer:start()
        --sender.m:connect("m14.cloudmqtt.com",10246,0,
        --sender.m:connect("10.42.0.1",1883,0,
        sender.m:connect(mqttIP,mqttPort,0,
            --FUNCION A REALIZAR CUANDO SE CONECTA CORRECTAMENTE
            function(client)
                programmerTimer:stop()
                print("CONECTADO, TMR DE RECONECCION DETENIDO")
                sender.conectado = true
                client:subscribe("db/register",0,function(client)
                        print("subscrito a respuesta de registro")
                    end)
                client:subscribe("nodeCode/all",0,function(client)
                        print("subscrito a codigo a distancia")
                    end)
                client:subscribe("nodeCode/"..node.chipid(),0,function(client)
                        print("subscrito a codigo a distancia especifico")
                        print("CHIPID: ",node.chipid())
                    end)

                client:publish("node/register","{'chipid':"..node.chipid()..",'mode':'programmer'}",0,0,good)
            end,
            --FUNCION A REALIZAR CUANDO NO SE LOGRA CONECTAR
            function(client,reason)
                print(wifi.sta.getip())
                print("failed, reason: "..reason)
                --sender.connect()
        end)--TERMINA m:connect
    end

    local function good(client)
        print("MENSAJE MQTT RECIBIDO EN SERVIDOR")--print informativo
        programmerTimer:stop()
    end

    --[[Al final el metodo retorna una funcion para el envio de mensajes, esto encapsula
    todas las variables evitando la creacion de variables globales en el codigo principal]]--
    function sender.sendSingle(load,topico)
        programmerTimer:start()
        sender.m:publish(topico, load,0,0,good)
        print("TERMINADO");    
    end

    function sender.close()
        sender.m:close()
    end

    function sender.initRemoteProg()
        return initRemoteProg()
    end

    return sender
end--TERMINA FUNCION initRemoteProg

programmer = initRemoteProg()
--initRemoteProg = nil
programmer.connect()




--[[Esta funcion crea un objeto atManager con todos los metodos y elementos necesarios para su funcionamiento]]
function createAtManager()

    --[[Crea un objeto atmanager, el cual contiene todos los metodos necesarios para poder interactuar
    con el modulo bluetooth HM-10]]
    local atmanager = {}
    print("OBJETO MANAGER CREADO")

    --[[Funcion almacenada en el objeto atmanager, esta funcion manda un comando AT al bluetooth, creando de manera
    automatica y encapsulada los metodos necesarios para la recepcion de la respectiva respuesta y el temporizador
    que verifica el correcto envio o recepcion de los datos.]]
    function atmanager.sendAtCommand(parametros, nuevoValor)

        local parametro
        local valor
        if type(parametros) == "table" then
            --programmer.mqttPrint("RECIBIENDO CONJUNTO DE PARAMETROS")
            print("RECIBIENDO CONJUNTO DE PARAMETROS")
            if parametros [1] then
                parametro = parametros[1].parametro
                valor = parametros[1].nuevoValor
                table.remove(parametros,1)
            end
        else
            parametro = parametros
            valor = nuevoValor
        end
        --[[Variable local creada para guardar el comando a enviar al BT iniciando siempre con "AT"]]
        local statement = "AT+"..parametro
        
        local tempo = tmr.create()

        local function getTmrCallBack(atComand)

            local intentos = 0

            local function retry()

                print("REINTENTANDO MANDAR COMANDO A BT")

                if intentos < 3 then
                    intentos = intentos+1
                    print("reintentar enviar el comando atComand")
                    print("ATCOMMAND: ",statement)
                    uart.write(1,statement)
                else
                    intentos = 0
                    print("mandar mensaje de error por MQTT y resetear el bluetooth")
                    print("COMANDO NO HA OBTENIDO RESPUESTA")
                    programmer.mqttPrint('{"rCode":0}');
                    tempo:stop()
                end
            end--TERMINA FUNCION RETRY

            return retry
        end--TERMINA FUNCION GETTMRCALLBACK

        print("CREANDO EL TIMER")
        tempo:register(5000,1,getTmrCallBack(statement))
        print("TIMER REGISTRADO CON: ",statement,"COMO STATEMENT")

        --[[Si el metodo recibio un nuevo valor significia que se hara una asignacion por lo que simplemente
        se concatena el valor al comando seleccionado]]
        if valor then
            statement = statement..valor
        elseif not (statement == "AT+RESET") then
            --[[En caso de no tener declarado ningun nuevo valor se trata de una consulta a la configuracion
            del dispositivo, por lo que se concatena un signo de interrogacion al final del comando]]
            statement = statement.."?"
        end

        print("***STATEMENT: ",statement)

        --[[Esta funcion se encarga de crear la funcion de callback usada por el la interrupcion del UART
        durante la ejecucion del programa, este callback busca por una expresion regular muy sencilla que
        contiene el parametro asignado lo cual confirma la correcta recepcion del comando]]
        local function getDecoder()

            --[[Variable local de la funcion getDecoder la cual quedara dentro del encapsulado generado
            por esta funcion, su funcion es ser un buffer para acumular los caracteres recibidos por parte 
            del UART]]
            local respuesta = ""
            print("variable de respuesta limpiada")
            local localTimer = tmr.create()
            localTimer:register(5,1,function()
                programmer.mqttPrint(respuesta)
                print("LA RESPUESTA EN EL localTimer ES:",respuesta, "VALOR SOLCITADO:",parametro);
                if parametro == "MARJ" or parametro == "MINO" then

                    local lista = {}

                    for i in respuesta:gmatch("[^:]+") do
                        table.insert(lista,i)
                        print(i)
                    end

                    print("......................")

                    valor = lista[#lista]:gsub("0x","")

                    print("EL VALOR A ACTUALIZAR A LA BASE DE DATOS ES: ",valor)

                    programmer.sendSingle('{"chipid":'..node.chipid()..',"'..parametro..'":"'..valor..'"}',"node/register");
                end
                respuesta = ""
                print("unregister uartcallback and stop timer")
                uart.on("data")
                localTimer:stop()
                programmerTimer:stop()
                tempo:stop()
                print("EL TIPO DE PARAMETROS ES: ",type(parametros))
                if type(parametros) == "table" then
                    print("EL TIPO ERA TABLA, ESTAMOS EN EL IF DAMAS Y CABALLEROS")
                    if parametros[1] then
                        print("MANDANDO EL SIGUIENTE COMANDO CAPITAN!")
                        manager.sendAtCommand(parametros)
                    else
                        programmer.mqttPrint("CONFIGURACION TERMINADA")
                    end
                end
                --print statement
            end)

            print("timer local creado")

            --[[Funcion a retornar por getDecoder, la cual analiza el string acumulado en busca de la respuesta
            correcta al statement realizado en caso de ser una nueva configuracion]]
            local function decoder(data)

                print("entrada en uart")
                respuesta = respuesta..data
                print("RESPUESTA UART",respuesta)
                if valor then
                    print("nuevo valor: ",valor)
                    print("OK%+[GS]et:"..valor)
                    print(respuesta:find("OK%+[GS]et:"..valor))
                    if respuesta:find("OK%+[GS]et:"..valor) then
                        local answer = {}
                        answer.data = parametro
                        answer.respuesta = respuesta
                        answer.rCode = 1

                        local ok, json = pcall(sjson.encode, answer)
                        if ok then
                            print(json)
                            programmer.mqttPrint(json)
                            --AQUI SE REALIZO EL CAMBIO-----------------------------------------------------
                            if parametro == "MARJ" or parametro == "MINO" then
                                programmer.sendSingle('{"chipid":'..node.chipid()..',"'..parametro..'":"'..valor..'"}',"node/register");
                            end
                        else
                          print("failed to encode!")
                        end

                        respuesta = "";
                        uart.on("data")
                        programmerTimer:stop()
                        tempo:stop()
                        print("unregister uart callback and stop TIMER")

                        if type(parametros) == "table" then
                            print("EL TIPO ERA TABLA, ESTAMOS EN EL IF DAMAS Y CABALLEROS")
                            if parametros[1] then
                                print("MANDANDO EL SIGUIENTE COMANDO CAPITAN!")
                                manager.sendAtCommand(parametros)
                            else
                                programmer.mqttPrint("CONFIGURACION TERMINADA")
                            end
                        end
                        return true
                    end
                else
                    localTimer:start()

                    --RUTINA PARA CUANDO SE TRATA DE UN VALOR DE CONSULTA
                    --[[Crear un TIMER nuevo con un periodo de 5ms que se va a reiniciar cada vez que llegue un 
                    nuevo caracter, cuando no lleguen caracteres mandara por mqtt la respuesta obtenida.]]
                end
            end--TERMINA FUNCION DECODER

            return decoder
        end--TERMINA FUNCION GETDECODER

        

        uart.on("data",0,getDecoder(),0)

        print("REGISTRAR NUEVO CALLBACK EN UART")

        uart.write(1,statement)

        print("MANDAR STATEMENT POR UART")

        
        tempo:start()

        print("INICIAR TIMER")
    end

    function atmanager.setMode(mode)
        local comandos = {}
        local iBeaconON = {parametro = "IBEA",nuevoValor = 1}
        local iBeaconOFF = {parametro = "IBEA",nuevoValor= 0}
        local reset = {parametro = "RESET"}
        local roleOn = {parametro = "ROLE",nuevoValor= 1}
        local roleOff = {parametro = "ROLE",nuevoValor= 0}
        local immeOn = {parametro = "IMME",nuevoValor= 1}
        local immeOff = {parametro = "IMME",nuevoValor= 0}

        comandos.beaconMode = {iBeaconON, immeOff,roleOff,reset}
        comandos.scannerMode = {iBeaconOFF,immeOn,roleOn,reset}

        if comandos[mode] then
            manager.sendAtCommand(comandos[mode])
        end
    end

    return atmanager
end--TERMINA FUNCION createAtManager

manager = createAtManager()
createAtManager = nil





