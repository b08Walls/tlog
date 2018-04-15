

print("hello world");

print("SE PROCEDE A REALIZAR LA PETICION HTTP")

local archivos = {"codeHttpUpdater.lua",
			"constants.lua",
			"enduser_part1.html",
			"enduser_part2.html",
			"gpioConfig.lua",
			"looktimers.lua",
			"mqttCallback.lua",
			"MqttProgrammer.lua",
			"NetworkConfig.lua",
			"tuggerTracker.lua",
			"uartConfig.lua",
			"wifiConfig.lua",
			"init.lua"
			}
for k,v in pairs(file.list()) do print(k,v) file.remove(k) end


function getNextFile(archivo)
	print("Llamando siguiente archivo")

	local myFile = table.remove(archivo,1)
	
	if myFile then

		local direccion = "http://10.42.0.1/CODE_SERVER/"..myFile
		print(direccion)

		http.get(direccion,nil, function(code,data)
			if(code < 0) then
				print("HTTP ERROR")
			else
				print("CODIG0:",code)
				print("DATOS")
				print(data)



				local temp = file.open(myFile,"w+")
				if temp then
					temp:write(data)
					temp:close()
				end

				getNextFile(archivo)

			end
		end)
	end
end

getNextFile(archivos)



--node.restart()



