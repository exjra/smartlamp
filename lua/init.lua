mUdpSocket = nil
mUdpSocketPort = 5000
mTcpServer = nil
mDriverPin = 2

tInitTimer = tmr.create()
tInitTimer:register(5000, tmr.ALARM_SINGLE, function() 

    print("init system")

    --pinouts
    gpio.mode(mDriverPin, gpio.OUTPUT)
    driveOff()
    
    --reset wifi
    wifi.setmode(wifi.NULLMODE)

    connectWifi()
end)

tInitTimer:start()

tBroadcasterTimer = tmr.create()
tBroadcasterTimer:register(5000, tmr.ALARM_AUTO, function() 

    if mUdpSocket ~= nil then
        print("Broadcasting...")

        local tPortUpper = mUdpSocketPort/256 --mUdpSocketPort/256
        local tPortLower = mUdpSocketPort%256 --mUdpSocketPort%256
        --binstr = string.char(14, tPortUpper, tPortLower, 53)
        binstr = string.char(14, tPortUpper, tPortLower, 53)
        mUdpSocket:send(1453, wifi.sta.getbroadcast(), binstr)
    end
end)

function connectWifi()

    print("initializing wifi")
    
    wifi.setmode(wifi.STATION)
    
    local staConfig = {}

    staConfig.ssid = ("zefzef")
    staConfig.pwd = ("yemlebeni")
    wifi.sta.config(staConfig)
    wifi.sta.connect()    

    wifi.eventmon.register(wifi.eventmon.STA_GOT_IP, function(T)
        print("\n\tSTA - GOT IP".."\n\tStation IP: "..T.IP.."\n\tSubnet mask: "..
        T.netmask.."\n\tGateway IP: "..T.gateway)

        startBroadcaster()
        startServer()
    end)
        
    print("initializing wifi end") 
end

function startBroadcaster()
    mUdpSocket = net.createUDPSocket()
    
    tBroadcasterTimer:start()
end

function startServer()    
    mTcpServer = net.createServer(net.TCP, 30)

    function onClientDataReceived(pSocket, data)
        print(data)
        
        if data == "1" then
            driveOn()
        elseif data == "0" then
            driveOff()
        end 
    end

    function onSocketDisconnected(pSocket)
        print("client disconnected")
    end
    
    if mTcpServer then
      mTcpServer:listen(mUdpSocketPort, function(pSocket)
        local tPort1
        local tIpAddress1
        tPort1, tIpAddress1 = pSocket:getpeer()
        print("client disconnected, port: "..tPort1.." ip:"..tIpAddress1)
        --print("client connected")
         
        pSocket:on("receive", onClientDataReceived)
        pSocket:on("disconnection", onSocketDisconnected)
        pSocket:send("hello world")
      end)
    end
end

function driveOn()
    gpio.write(mDriverPin, gpio.HIGH)
end

function driveOff()
    gpio.write(mDriverPin, gpio.LOW)
end