
local mqttLoad,mqttTopic,client = ...

--client:close()
print("EJECUTANDO ARCHIVO")
print("mqttLoad en file:",mqttLoad)
if mqttLoad ~= nil then
                    
    print("MENSAJE: ",mqttLoad,"mqttTopic: ",mqttTopic)

    local function mqttPrint(load,cliente)
        local c = nil
        if not cliente then c = client else c = cliente end
        c:publish("nodeResponse", load,0,0,function() print("recibido en servidor") end)
    end

    local ok, r = pcall(function()
        return sjson.decode(mqttLoad)
        end);

    if ok then
        if mqttTopic == "db/register" then
            print("")
        elseif mqttTopic == "nodeCode/" then
            print("nodeCode/")
            if r.command == RESET then
                node.restart()
            end
        elseif mqttTopic == "nodeCode/"..node.chipid() then
            print("nodeCode/"..node.chipid())
            if r.command == RESET then

                local newInitFile = nil

                if r.load == RESTART then
                    node.restart()
                    print("REINICIANDO")
                else
                    newInitFile = file.open(INIT,"w+")
                end

                newInitFile:writeline("dofile('constants.lua')")
                if r.load == RESET_BEACON then
                    --crear init para modo beacon
                    newInitFile:writeline("dofile(BEACON_INIT)")
                elseif r.load == RESET_SCANNER then
                    --crear init para modo beacon
                    newInitFile:writeline("dofile(SCANNER_INIT)")
                elseif r.load == QUIT then
                    file.remove("init.lua")
                end
                newInitFile:close()
                node.restart()
            elseif r.command == COMMAND then

                local f = nil
                local k = nil
                print("ralizando protected call")
                if pcall(function() f,k = assert(loadstring(r.load),"error")end) then
                    if pcall(function() f() end) then
                        print("all good")
                    else
                        print("ERROR IN YOUR CODE")
                        mqttPrint("ERROR IN YOUR CODE")
                    end
                else
                    print("ERROR",k)
                    mqttPrint("error:");
                end
            -- elseif r.command == SET_IP then
            --     print("setting IP")
            end
        else
            print("nodthing haha")
        end
    end
end
mqttLoad = nil
mqttTopic = nil
print("ARCHIVO EJECUTADO DESDE DENTRO")
