-- CONFIGURATION
led = 4
trigger = 0 -- D0
echo = 2 -- D2

startTime = 0

-- WiFi
SSID = ""
PWD = ""
-- ThingSpeak Write API KEY 
API_KEY = ""
-- max: 6870947 (in ms = almost 2 hours)
MEASURE_INTERVAL = 6870947


setUpWiFi = function ()
    print("WiFi connection...")
    print(" > setting up...")
    wifi.setmode(wifi.STATION)
    wifi.setphymode(wifi.PHYMODE_N)
    station_cfg={}
    station_cfg.ssid=SSID
    station_cfg.pwd=PWD
    station_cfg.save=true
    station_cfg.auto=true
    wifi.sta.config(station_cfg)
    wifi.sta.sleeptype(wifi.LIGHT_SLEEP)
    print(" > connecting...")
    wifi.sta.connect()
    local timer, counter = tmr.create(), 0
    timer:alarm(4000, tmr.ALARM_AUTO, function(t)
        counter = counter + 1
        if wifi.sta.getip() == nil then
            print("    waiting...")
        else
            print("Connected. IP: ", wifi.sta.getip())
            gpio.write(led,gpio.LOW)
            t:unregister()
        end
        if counter >= 60 then t:unregister() end
    end)
end

measure = function ()
   if wifi.sta.status() ~= wifi.STA_GOTIP then
    -- not connected (switch led off)
    gpio.write(led,gpio.HIGH)
    return
   end
    -- connected and ready to measure (switch led on)
   gpio.write(led,gpio.LOW)
   gpio.write(trigger, gpio.HIGH)
   tmr.delay(10)
   gpio.write(trigger, gpio.LOW)
   startTime = tmr.now()
end

function round(num, numDecimalPlaces)
  local mult = 10^(numDecimalPlaces or 0)
  local roundFactor = 0.5
  if(num < 0) then roundFactor = -0.5 end
  return math.floor(num * mult + roundFactor) / mult
end

-- main program
setUpWiFi()

gpio.trig(echo, "down", function (level, stopTime)
    local interval = stopTime - startTime
    local distance = interval / 58

    local repeatMeasure = distance < 0

    local url = "http://api.thingspeak.com/update?api_key=".. API_KEY .. "&field1="..round(distance, 2)
    print("Request: " .. url)
    http.get(url, nil, function(code, data)
        if (code ~= 200) then
          print("HTTP request failed. Code: " .. code .. ". Data: " .. data)
          repeatMeasure = true
        else
          print(" OK")
        end
    end)

    if repeatMeasure then
        -- repeat the measure after 10 seconds
      tmr.create():alarm(10000, tmr.ALARM_SINGLE, measure)
    end
    -- switch led off afterall
    gpio.write(led,gpio.HIGH)
  end)
tmr.create():alarm(MEASURE_INTERVAL, tmr.ALARM_AUTO, measure)

-- start with first measure after 10s
tmr.create():alarm(10000, tmr.ALARM_SINGLE, measure)




