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
        SQLCOMMAND = "CREATE TABLE IF NOT EXISTS '" .. k .. "' (Word TEXT, Position TEXT, Amount TEXT, Before TEXT, After TEXT)"
        db:exec(SQLCOMMAND)
    end
    
    
end)


function getKeysSortedByValue(tbl, sortFunction)
    local keys = {}
    for key in pairs(tbl) do
        table.insert(keys, key)
    end
    table.sort(keys, function(a, b) return sortFunction(tbl[a], tbl[b]) end)
    return keys
end

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
    if(string.lower(string.sub(message.content,2,#message.content)) == "randomsentence" and string.sub(message.content,1,1) == "[") then
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
                Pot[Candidates[m]] = Checkpoint + tonumber(Amountlist[Candidates[m]])
                --print(Candidates[m] .. " " .. Pot[Candidates[m]] .. " " .. Checkpoint .. " " .. Amountlist[Candidates[m]])
                Checkpoint = Checkpoint + tonumber(Amountlist[Candidates[m]])
            end
            print("CheckPoint :" .. Checkpoint)
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


Client:on("messageCreate", function(message)
    if(string.sub(message.content,1,1) == "[" and string.lower(string.sub(message.content,2,9)) == "sentence") then
        local TargetWord = string.lower(string.sub(message.content,11,#message.content))
        local isWordinTheDB = 0
        local ChosenPosition,ChosenPositionIndex,ChosenWord,ChosenWordIndex
        local Sentence = {}

        local Before
        local After
        
        SQLCOMMAND = "SELECT * from '" .. message.channel.guild.id .. "' Where Word='" .. TargetWord .. "'"
        local Rows,errorString = db:exec(SQLCOMMAND)
        if(errorString == 0) then
            message.channel:send("ERROR404")
            isWordinTheDB = 1
        else
            local Positionlist = {}
            local Amountlist = {}
            local Beforelist = {}
            local Afterlist = {}

            for m,n in pairs(Rows) do
                if(m == "Amount") then
                    Amountlist = n
                end
                if(m == "Position") then
                    Positionlist = n
                end
                if(m == "Before") then
                    Beforelist = n
                end
                if(m == "After") then
                    Afterlist = n
                end
            end

            local PositionValues = {}
            for m=1, table.getn(Positionlist) do
                --print(TargetWord .. ":" .. Positionlist[m] .. ":" .. Amountlist[m] .. ":" .. Beforelist[m] .. ":" .. Afterlist[m])
                if(PositionValues[tonumber(Positionlist[m])] == nil) then
                    PositionValues[tonumber(Positionlist[m])] = tonumber(Amountlist[m])
                    --print(PositionValues[tonumber(Positionlist[m])])
                    --print(tonumber(Positionlist[m]))
                    --print(m)
                else
                    PositionValues[tonumber(Positionlist[m])] = PositionValues[tonumber(Positionlist[m])] + tonumber(Amountlist[m])
                end
            end
            local sortedPositions = {}
            for k, v in pairs(PositionValues) do
                --print(k,v)
                table.insert(sortedPositions,{k,v})
            end
            table.sort(sortedPositions, function(a,b) return a[2] < b[2] end)
            local PositionPot = {}
            local Checkpoint = 0
            for m,n in ipairs(sortedPositions) do
                --print(n[1],n[2])
                PositionPot[n[1]] = Checkpoint + n[2]
                Checkpoint = PositionPot[n[1]]
            end
            local sortedPositionsPot = {}
            for k, v in pairs(PositionPot) do
                --print(k,v)
                table.insert(sortedPositionsPot,{k,v})
            end
            table.sort(sortedPositionsPot, function(a,b) return a[2] < b[2] end)
            local THEONE = math.random(1,Checkpoint)
            for m,n in ipairs(sortedPositionsPot) do
                --print(n[1],n[2],THEONE)
                if(n[2] >= THEONE) then
                    ChosenPosition = n[1]
                    ChosenPositionIndex = n[1]
                    break
                end
            end
        end
        if(isWordinTheDB == 0) then
            SQLCOMMAND = "SELECT * from '" .. message.channel.guild.id .. "' Where Word='" .. TargetWord .. "' AND Position='" .. ChosenPosition .. "'"
            local Rows,errorString = db:exec(SQLCOMMAND)
            if(errorString == 0) then
                print("WTF CODE 3")
            else
                local Amountlist = {}
                local Beforelist = {}
                local Afterlist = {}

                for m,n in pairs(Rows) do
                    if(m == "Amount") then
                        Amountlist = n
                    end
                    if(m == "Before") then
                        Beforelist = n
                    end
                    if(m == "After") then
                        Afterlist = n
                    end
                end
                local WordPot = {}
                local Checkpoint = 0
                for m=1, table.getn(Amountlist) do
                    --print(TargetWord .. ":" .. ChosenPosition .. ":" .. Amountlist[m] .. ":" .. Beforelist[m] .. ":" .. Afterlist[m])
                    WordPot[m] = Checkpoint + tonumber(Amountlist[m])
                    Checkpoint = WordPot[m]
                end

                local THEONE = math.random(1,Checkpoint)
                for m,n in ipairs(WordPot) do
                    --print(m,n)
                    if(n >= THEONE) then
                        ChosenWord = m
                        ChosenWordIndex = m
                        Before = Beforelist[ChosenWordIndex]
                        After = Afterlist[ChosenWordIndex]
                        break
                    end
                end
                print("CHOSEN WORD:" .. TargetWord .. ":" .. ChosenPosition .. ":" .. Amountlist[ChosenWordIndex] .. ":" .. Before .. ":" .. After)
            end
            Sentence[ChosenPosition] = TargetWord
            --print("TEST :" .. Sentence[ChosenPosition])

            for k=ChosenPosition-1,1,-1 do
                SQLCOMMAND="SELECT * from '" .. message.channel.guild.id .. "' Where Word='" .. Before .. "' AND Position='" .. k .. "'"
                print(SQLCOMMAND)
                local Rows,errorString = db:exec(SQLCOMMAND)
                if(errorString == 0) then
                    print("WTF CODE 4")
                else
                    local Amountlist = {}
                    local Beforelist = {}
                    local Afterlist = {}
                    local tmpBefore,tmpAfter
    
                    for m,n in pairs(Rows) do
                        if(m == "Amount") then
                            Amountlist = n
                        end
                        if(m == "Before") then
                            Beforelist = n
                        end
                        if(m == "After") then
                            Afterlist = n
                        end
                    end
                    local WordPot = {}
                    local Checkpoint = 0
                    for m=1, table.getn(Amountlist) do
                        --print(TargetWord .. ":" .. ChosenPosition .. ":" .. Amountlist[m] .. ":" .. Beforelist[m] .. ":" .. Afterlist[m])
                        WordPot[m] = Checkpoint + tonumber(Amountlist[m])
                        Checkpoint = WordPot[m]
                    end
                
                    local THEONE = math.random(1,Checkpoint)
                    for m,n in ipairs(WordPot) do
                        --print(m,n)
                        if(n >= THEONE) then
                            Sentence[k] = Before
                            --print("BEFORE : " .. Before)
                            tmpBefore = Beforelist[m]
                            tmpAfter = Afterlist[m]
                            break
                        end
                    end
                    Before = tmpBefore
                    After = tmpAfter
                    --print(Sentence[k] .. ":" .. k .. ":" .. Before .. ":" .. After)
                end
            end
            local k=ChosenPosition+1
            while After ~= "FRONTEND" do
                SQLCOMMAND="SELECT * from '" .. message.channel.guild.id .. "' Where Word='" .. After .. "' AND Position='" .. k .. "'"
                print(SQLCOMMAND)
                local Rows,errorString = db:exec(SQLCOMMAND)
                if(errorString == 0) then
                    print("WTF CODE 5")
                    break
                else
                    local Amountlist = {}
                    local Beforelist = {}
                    local Afterlist = {}
                    local tmpBefore,tmpAfter
                
                    for m,n in pairs(Rows) do
                        if(m == "Amount") then
                            Amountlist = n
                        end
                        if(m == "Before") then
                            Beforelist = n
                        end
                        if(m == "After") then
                            Afterlist = n
                        end
                    end
                    local WordPot = {}
                    local Checkpoint = 0
                    for m=1, table.getn(Amountlist) do
                        --print(TargetWord .. ":" .. ChosenPosition .. ":" .. Amountlist[m] .. ":" .. Beforelist[m] .. ":" .. Afterlist[m])
                        WordPot[m] = Checkpoint + tonumber(Amountlist[m])
                        Checkpoint = WordPot[m]
                    end
                
                    local THEONE = math.random(1,Checkpoint)
                    for m,n in ipairs(WordPot) do
                        --print(m,n)
                        if(n >= THEONE) then
                            Sentence[k] = After
                            --print("After : " .. After)
                            tmpBefore = Beforelist[m]
                            tmpAfter = Afterlist[m]
                            break
                        end
                    end
                    Before = tmpBefore
                    After = tmpAfter
                    --print(Sentence[k] .. ":" .. k .. ":" .. Before .. ":" .. After)
                end
                k=k+1
            end

            local SentenceString = ""
            --print(table.getn(Sentence))
            for m,n in pairs(Sentence) do 
                --print(m,n)
                SentenceString = SentenceString .. Sentence[m] .. " "
            end 
            print("SENTENCE:" .. SentenceString)
            message.channel:send(SentenceString)
        end
    end
end)

Client:run("Bot NjkzNDQ4MTUyMDY5NzAxNjUy.XoTZLQ.Z4v2IQFhTDWh3pnCD2qa8cJWVy8")
