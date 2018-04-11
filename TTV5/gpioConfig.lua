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

    --------------------------------------------------------------------------------------------------------------------------|
    ---FUNCIONES DE CONFIGURACION PARA EL PIN D2------------------------------------------------------------------------------|
    --------------------------------------------------------------------------------------------------------------------------|
    local function intD2()

        local newInitFile = file.open(INIT,"w+")

        newInitFile:writeline("dofile('constants.lua')")
        newInitFile:writeline("__Mode = '"..__Mode.."'")
        newInitFile:writeline("dofile(NETWORK_INIT)")
        newInitFile:close()
        node.restart()
    end

    --------------------------------------------------------------------------------------------------------------------------|
    ---FUNCIONES DE CONFIGURACION PARA EL PIN D1------------------------------------------------------------------------------|
    --------------------------------------------------------------------------------------------------------------------------|

    --Se configura como salida
    gpio.mode(btResetPin, gpio.OUTPUT)
    --[[Se inicializa su valor como apagado, recordando que por la configuracion del transistor en el circuito LOW encendera
        el bluetooth y HIGH lo apagara.]]
    gpio.write(btResetPin,gpio.HIGH)

    --Se coloca el modo de este pin en modo INT(interrupcion)
    gpio.mode(configModePin,gpio.INT)
    --[[Se configura la rutina a seguir para la interrupcion esta es:
            *   Numero de pin
            *   Borde de subida
            *   Funcion a ejecutar, funcion resultante de la funcion getIntD2
      ]]
    gpio.trig(configModePin,"up",intD2)


    gpio.mode(statusLedPin,gpio.OUTPUT)
    gpio.write(statusLedPin,gpio.HIGH)
end--TERMINA initGPIO()


initGPIO()
initGPIO = nil
print("GPIO's READY")
