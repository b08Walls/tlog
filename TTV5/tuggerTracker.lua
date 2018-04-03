__Mode = SCANNER_INIT

print(node.heap())
dofile("constants.lua")

print(node.heap())
dofile("lookTimers.lua")
print(node.heap())
dofile("uartConfig.lua")
print(node.heap())
dofile("gpioConfig.lua")
print(node.heap())
dofile("wifiConfig.lua")
print(node.heap())

look();
