------------------------------------------------------------------------------------------------------------------------------|
--[[Funcion para inicializar la conexion WIFI]]-------------------------------------------------------------------------------|
------------------------------------------------------------------------------------------------------------------------------|
function initWIFI()
    wifi.setmode(wifi.STATION)
    wifi.setphymode(wifi.PHYMODE_B)
    local stationConfig = {}
    --stationConfig.ssid = "iPhone de Octavio Roberto"
    stationConfig.ssid = "TUGGER-NET"
    --stationConfig.ssid = "Telcel_NYX_2467"
    --stationConfig.ssid = "B08LAP"
    --stationConfig.pwd = "53285329"
    stationConfig.pwd = "1L0V3TUGG3R"
    --stationConfig.pwd = "70082467"
    --stationConfig.pwd = "d1fdae0527"
    wifi.sta.config(stationConfig)
end

initWIFI()
print("WIFI READY")
initWIFI = nil
