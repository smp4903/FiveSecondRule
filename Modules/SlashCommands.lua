-- COMMANDS
SLASH_FSR1 = '/fsr'; 

function SlashCmdList.FSR(msg, editbox)
    local cmd = msg:lower()

    if cmd == "unlock" or cmd == "u" then
        print("Five Second Rule - UNLOCKED.")
        FiveSecondRule:unlock()
    end

    if cmd == "flat on" or cmd == "f on" then
        print("Five Second Rule - flat mode ON.")
        FiveSecondRule:flat(true)
    end

    if cmd == "flat off" or cmd == "f off" then
        print("Five Second Rule - flat mode OFF.")
        FiveSecondRule:flat(false)
    end

    if cmd == "lock" or cmd == "l" then
        print("Five Second Rule - LOCKED.")
        FiveSecondRule:lock()
    end

    if cmd == "reset" then
        print("Five Second Rule - RESET ALL SETTINGS")
        FiveSecondRule:reset()
    end

    if cmd == "" or cmd == "help" then
        FiveSecondRule:PrintHelp()  
        InterfaceOptionsFrame_OpenToCategory(FiveSecondRule.OptionsPanelFrame)
    end
end
