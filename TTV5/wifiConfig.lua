------------------------------------------------------------------------------------------------------------------------------|
--[[Funcion para inicializar la conexion WIFI]]-------------------------------------------------------------------------------|
------------------------------------------------------------------------------------------------------------------------------|
-- function initWIFI()
    wifi.setmode(wifi.STATION)
    wifi.setphymode(wifi.PHYMODE_B)
    local stationConfig = {}
    --stationConfig.ssid = "iPhone de Octavio Roberto"
    -- stationConfig.ssid = "TUGGER-NET"
    stationConfig.ssid = "TUGGER-NET"
    --stationConfig.ssid = "Telcel_NYX_2467"
    --stationConfig.ssid = "B08LAP"
    --stationConfig.pwd = "53285329"
    stationConfig.pwd = "1L0V3TUGG3R"
    --stationConfig.pwd = "70082467"
    --stationConfig.pwd = "d1fdae0527"
    wifi.sta.config(stationConfig)

    local ipConfig = {}
    ipConfig.ip = "192.168.0.70"
    ipConfig.netmask = "255.255.255.0"
    ipConfig.gateway = "192.168.0.1"

    wifi.sta.setip(ipConfig)

-- end

-- initWIFI()
print("WIFI READY")
-- initWIFI = nil
