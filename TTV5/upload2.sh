

echo "................................................................................................................"
nodemcu-tool upload --port /dev/cu.SLAB_USBtoUART constants.lua
echo "................................................................................................................"
nodemcu-tool upload --port /dev/cu.SLAB_USBtoUART gpioConfig.lua
echo "................................................................................................................"
nodemcu-tool upload --port /dev/cu.SLAB_USBtoUART lookTimers.lua
echo "................................................................................................................"
nodemcu-tool upload --port /dev/cu.SLAB_USBtoUART mqttCallback.lua
echo "................................................................................................................"
nodemcu-tool upload --port /dev/cu.SLAB_USBtoUART MqttProgrammer.lua
echo "................................................................................................................"
nodemcu-tool upload --port /dev/cu.SLAB_USBtoUART NetworkConfig.lua
echo "................................................................................................................"
nodemcu-tool upload --port /dev/cu.SLAB_USBtoUART tuggerTracker.lua
echo "................................................................................................................"
nodemcu-tool upload --port /dev/cu.SLAB_USBtoUART uartConfig.lua
echo "................................................................................................................"
nodemcu-tool upload --port /dev/cu.SLAB_USBtoUART wifiConfig.lua


echo "................................................................................................................"
nodemcu-tool upload --port /dev/cu.SLAB_USBtoUART init.lua 

echo "................................................................................................................"
nodemcu-tool upload --port /dev/cu.SLAB_USBtoUART --keeppath enduser_part1.html
echo "................................................................................................................"
nodemcu-tool upload --port /dev/cu.SLAB_USBtoUART --keeppath enduser_part2.html
echo "................................................................................................................"
echo "....LISTO......................................................................................................."
echo "................................................................................................................"


