local function setup()
    led = 4
    trigger = 0 -- D0
    echo = 2 -- D2
    
    gpio.mode(trigger, gpio.OUTPUT)
    gpio.write(trigger, gpio.LOW)
    
    gpio.mode(echo, gpio.INT)
    
    -- LED off
    gpio.mode(led, gpio.OUTPUT)
    gpio.write(led, gpio.HIGH)

end

local function startup()
    if file.open("init.lua") == nil then
        print("init.lua deleted or renamed")
    else
        local appFile = "szambosensor.lua"
        print("Running " .. appFile)
        file.close("init.lua")
        -- the actual application is stored in 'application.lua'
        dofile(appFile)
    end
end

print("Booting..")
setup()
tmr.create():alarm(3000, tmr.ALARM_SINGLE, setup)
startup()

