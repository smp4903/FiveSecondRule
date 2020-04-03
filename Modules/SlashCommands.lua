-- COMMANDS
SLASH_FSR1 = '/fsr'; 

function SlashCmdList.FSR(msg, editbox)
    local cmd = msg:lower()

    if cmd == "unlock" or cmd == "u" then
        print("Five Second Rule - UNLOCKED.")
        FiveSecondRule:Unlock()
    end

    if cmd == "lock" or cmd == "l" then
        print("Five Second Rule - LOCKED.")
        FiveSecondRule:Lock()
    end

    if cmd == "reset" then
        print("Five Second Rule - RESET ALL SETTINGS")
        FiveSecondRule:Reset()
    end

    if cmd == "" or cmd == "help" then
        FiveSecondRule:PrintHelp()  
        InterfaceOptionsFrame_OpenToCategory(FiveSecondRule.OptionsPanelFrame)
    end
end
