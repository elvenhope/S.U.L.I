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
end)

Client:run("Bot NjkzNDQ4MTUyMDY5NzAxNjUy.Xn9VXA.4vs-28fgd12_tbgFqsjacvN6ZVg")