

nodemcu-tool upload --port /dev/cu.SLAB_USBtoUART constants.lua
nodemcu-tool upload --port /dev/cu.SLAB_USBtoUART gpioConfig.lua
nodemcu-tool upload --port /dev/cu.SLAB_USBtoUART lookTimers.lua
nodemcu-tool upload --port /dev/cu.SLAB_USBtoUART mqttCallback.lua
nodemcu-tool upload --port /dev/cu.SLAB_USBtoUART MqttProgrammer.lua
nodemcu-tool upload --port /dev/cu.SLAB_USBtoUART NetworkConfig.lua
nodemcu-tool upload --port /dev/cu.SLAB_USBtoUART tuggerTracker.lua
nodemcu-tool upload --port /dev/cu.SLAB_USBtoUART uartConfig.lua
nodemcu-tool upload --port /dev/cu.SLAB_USBtoUART wifiConfig.lua


nodemcu-tool upload --port /dev/cu.SLAB_USBtoUART init.lua 

nodemcu-tool upload --port /dev/cu.SLAB_USBtoUART --keeppath enduser_part1.html
nodemcu-tool upload --port /dev/cu.SLAB_USBtoUART --keeppath enduser_part2.html
echo "................"
echo "....LISTO......."
echo "................"



