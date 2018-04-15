
--TIPOS DE COMANDO
RESET = 0
COMMAND = 1

--POSIBLES VALORES PARA COMANDO RESET
RESET_BEACON = 0
RESET_SCANNER = 1
QUIT = 2
RESTART = 3

--NOMBRES DE ARCHIVOS

BEACON_INIT = "MqttProgrammer.lua"
SCANNER_INIT = "tuggerTracker.lua"
NETWORK_INIT = "NetworkConfig.lua"
INIT = "init.lua"

--CONSTANTES BT

BEACON = "beaconMode"
SCANNER = "scannerMode"


--PINES

statusLedPin = 3
configModePin = 2
btResetPin = 1

--CONSTANTES MQTT

--mqttIP = "192.168.1.64"
mqttIP = "10.42.0.1"
mqttPort = 1883

--Se configura como salida
gpio.mode(btResetPin, gpio.OUTPUT)
--[[Se inicializa su valor como apagado, recordando que por la configuracion del transistor en el circuito LOW encendera
    el bluetooth y HIGH lo apagara.]]
gpio.write(btResetPin,gpio.LOW)