
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

mqttIP = "192.168.1.68"
mqttPort = 1883