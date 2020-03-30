local discordia = require("discordia")
local sql = require("sqlite3")
local Client = discordia.Client()

local db = sql.open("Brain.db")
local SQLCOMMAND
Client:on("ready", function()
    print("Logged in As : " .. Client.user.username)

    local ServerArray = {}
    for k, v in pairs(Client.guilds) do
        table.insert(ServerArray,k)
        SQLCOMMAND = "CREATE TABLE IF NOT EXISTS '" .. k .. "' (Word TEXT, Position INTEGER, Amount INTEGER, Before TEXT, After TEXT)"
        db:exec(SQLCOMMAND)
    end
    
    
end)

Client:on("messageCreate", function(message)
    if(string.sub(message.content,1,1) ~= "[") then
        Words = {}
        for Word in message.cleanContent:gmatch("%w+") do
            Word = string.lower(Word)
            table.insert(Words,Word)
        end
        for k,v in pairs(Words) do
            local BOTTOMEND = Words[k-1]
            local FRONTEND = Words[k+1]
            if(Words[k-1] == nil) then BOTTOMEND = "BOTTOMEND" end
            if(Words[k+1] == nil) then FRONTEND = "FRONTEND" end

            SQLCOMMAND = "SELECT Amount from '" .. message.channel.guild.id .. "' Where Word='" .. v .. "' AND Position='" .. k .. "' AND Before='" .. BOTTOMEND .. "' AND After='" .. FRONTEND .. "'"
            local Rows,errorString = db:exec(SQLCOMMAND)
            local OldAmount
            if(errorString == 0) then
                --There is no such Row
                SQLCOMMAND = "INSERT into '" .. message.channel.guild.id .. "' (Word,Position,Amount,Before,After) values('" .. v .. "','" .. k .. "','" .. 1 .. "','" .. BOTTOMEND .. "','" .. FRONTEND .. "');"
                db:exec(SQLCOMMAND)
            else
                for i,j in pairs(Rows) do
                    if(i == "Amount") then
                        OldAmount = tonumber(j[1])
                    end
                end
                SQLCOMMAND = "UPDATE '" .. message.channel.guild.id .. "' SET Amount='" .. OldAmount+1 .. "' Where Word='" .. v .. "' AND Position='" .. k .. "' AND Before='" .. BOTTOMEND .. "' AND After='" .. FRONTEND .. "';"
                db:exec(SQLCOMMAND)
            end
        end
    end
end)

Client:on("messageCreate", function(message)
    if(string.lower(string.sub(message.content,2,16)) == "randomsentence" and string.sub(message.content,1,1) == "[") then
        local Seed = math.random()
        print(Seed)
        math.randomseed(Seed)
        --local SentenceSize = math.random(1,3)
        local Before = "BOTTOMEND"
        local After = "FRONTEND"
        local Sentence = ""
        local i = 1
        while true  do
            local Wordlist = {}
            local Amountlist = {}
            local Beforelist = {}
            local Afterlist = {}
            local Candidates = {}
            local ChosenWord,ChosenWordIndex

            SQLCOMMAND = "SELECT * from '" .. message.channel.guild.id .. "' Where Position='" .. i .. "'"
            local Rows,errorString = db:exec(SQLCOMMAND)
            if(errorString == 0) then
               print("WTF CODE : 2") 
            else
                for m,n in pairs(Rows) do
                    if(m == "Amount") then
                        Amountlist = n
                    end
                    if(m == "Word") then
                        Wordlist = n
                    end
                    if(m == "Before") then
                        Beforelist = n
                    end
                    if(m == "After") then
                        Afterlist = n
                    end
                end
            end
            for m=1, table.getn(Beforelist) do
                if(Beforelist[m] == Before) then
                    table.insert(Candidates,m)
                    --print(m)
                end
            end

            local RandomIndex = math.random(1,table.getn(Candidates))
            local maxAmount = Amountlist[Candidates[RandomIndex]]
            ChosenWordIndex = Candidates[RandomIndex]
            ChosenWord = Wordlist[Candidates[RandomIndex]]
            local Checkpoint = 0
            local Pot = {}
            for m=1, table.getn(Candidates) do
                --print(Candidates[m])
                Pot[Candidates[m]] = Checkpoint + Amountlist[Candidates[m]]
                --print(Candidates[m] .. " " .. Pot[Candidates[m]] .. " " .. Checkpoint .. " " .. Amountlist[Candidates[m]])
                Checkpoint = Checkpoint + Amountlist[Candidates[m]]
            end
            local THEONE = math.random(1,Checkpoint)
            for m,n in ipairs(Pot) do 
                print(m,n)
                if(n >= THEONE) then
                    ChosenWord = Wordlist[m]
                    ChosenWordIndex = m
                    break
                end
            end
            print(THEONE)
            Sentence = Sentence .. ChosenWord .. " "
            Before = ChosenWord

            if(Afterlist[ChosenWordIndex] == After) then
                break
            end
            print("TURN END")
            i = i + 1
        end
        message.channel:send(Sentence)
    end
end)

Client:run("Bot NjkzNDQ4MTUyMDY5NzAxNjUy.XoHzRw.BJyqTcq_3o6JM4NWgb4lXbiyoPA")