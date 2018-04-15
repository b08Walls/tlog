

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





--node.restart()



