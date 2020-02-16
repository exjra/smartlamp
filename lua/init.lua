mUdpSocket = nil
mUdpSocketPort = 5000
mTcpServer = nil
mDriverPin = 2
mAPModeEnabled = false

print("SmartLamp v1.0")

tInitTimer = tmr.create()
tInitTimer:register(8000, tmr.ALARM_SINGLE, function() 

    print("init system")

    --load configurations
    loadConfig()

    --pinouts
    gpio.mode(mDriverPin, gpio.OUTPUT)
    driveOff()
    
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
        local tTemp = '0'
        if mAPModeEnabled then tTemp = '1' end
        
        binstr = string.char(14, tPortUpper, tPortLower, tTemp, 53)
        if mAPModeEnabled then
            mUdpSocket:send(1453, "192.168.10.255", binstr)
        else
            mUdpSocket:send(1453, wifi.sta.getbroadcast(), binstr)
        end
    end
end)

function resetWifi()
    --reset wifi
    wifi.eventmon.unregister(wifi.eventmon.STA_GOT_IP)
    wifi.eventmon.unregister(wifi.eventmon.STA_DISCONNECTED)
    wifi.eventmon.unregister(wifi.eventmon.STA_CONNECTED)
    
    wifi.setmode(wifi.NULLMODE)    
end

function connectWifi()

    resetWifi()
    
    print("initializing wifi")
    
    wifi.setmode(wifi.STATION)
    
    local staConfig = {}

    staConfig.ssid = mSSID --("zefzef")
    staConfig.pwd = mPass--("yemlebeni")
    wifi.sta.config(staConfig)
    wifi.sta.connect()    

    wifi.eventmon.register(wifi.eventmon.STA_GOT_IP, function(T)
        print("\n\tSTA - GOT IP".."\n\tStation IP: "..T.IP.."\n\tSubnet mask: "..
        T.netmask.."\n\tGateway IP: "..T.gateway)

        startBroadcaster()
        startServer()
    end)
    
    --wifi.eventmon.register(wifi.eventmon.WIFI_MODE_CHANGED, function(T)
    --    print("\n\tSTA - WIFI MODE CHANGED".."\n\told_mode: "..
    --    T.old_mode.."\n\tnew_mode: "..T.new_mode)
    --end)
    
    wifi.eventmon.register(wifi.eventmon.STA_DISCONNECTED, function(T)
        if T.reason == 201 then
            if mAPModeEnabled == false then 
                print("disconnected from wifi: "..T.reason)
                mAPModeEnabled = true
                startAPMode()
            end            
        elseif T.reason == 8 then
            if mAPModeEnabled == false then 
                print("disconnected from wifi: "..T.reason)
                mAPModeEnabled = true
                startAPMode()
            end
        elseif T.reason == 15 then
            if mAPModeEnabled == false then 
                print("disconnected from wifi: "..T.reason)
                mAPModeEnabled = true
                startAPMode()
            end
        end
    end)
    
    wifi.eventmon.register(wifi.eventmon.STA_CONNECTED, function(T)
        print("connected to wifi")
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
        elseif data == "2" then
            print(data)
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

function startAPMode()
    resetWifi()
    
    print("initializing for ap")
    
    ---------------------------------------
    --- Set Variables ---
    ---------------------------------------
    --- Set AP Configuration Variables ---
    AP_CFG={}
    --- SSID: 1-32 chars
    AP_CFG.ssid="smartlamp"
    AP_CFG.pwd="20200216"
    AP_CFG.auth=AUTH_OPEN
    AP_CFG.channel = 6
    AP_CFG.hidden = 0
    AP_CFG.max=1
    AP_CFG.beacon=100
    
    AP_IP_CFG={}
    AP_IP_CFG.ip="192.168.10.1"
    AP_IP_CFG.netmask="255.255.255.0"
    AP_IP_CFG.gateway="192.168.10.1"
    
    AP_DHCP_CFG ={}
    AP_DHCP_CFG.start = "192.168.10.2"
    ---------------------------------------
    
    --- Configure ESP8266 into AP Mode ---
    wifi.setmode(wifi.SOFTAP)
    --- Configure 802.11n Standard ---
    wifi.setphymode(wifi.PHYMODE_N)
    
    --- Configure WiFi Network Settings ---
    wifi.ap.config(AP_CFG)
    --- Configure AP IP Address ---
    wifi.ap.setip(AP_IP_CFG)
    
    --- Configure DHCP Service ---
    wifi.ap.dhcp.config(AP_DHCP_CFG)
    
    --- Start DHCP Service ---
    wifi.ap.dhcp.start()
    ---------------------------------------
    
    startBroadcaster()
    startServer()
        
    print("initializing ap wifi end")
end

function loadConfig()
    mSSID="xssidx"
    mPass="xpassx"
    
    if file.open("appconfig.dat", "r") then
        mSSID = file.readline()
        
        local i, j = string.find(mSSID, "\n")
        mSSID = string.sub(mSSID, 0, i-1)
    
        mPass = file.readline()
        
        local m, n = string.find(mPass, "\n")
        mPass = string.sub(mPass, 0, m-1)
        
        file.close()
        
        print("Configuration loaded succesfully")
    else
        print("Configuration does not loaded!")
    end
end