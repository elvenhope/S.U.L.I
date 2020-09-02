local discordia = require('discordia')
local timer = require("timer")
local client = discordia.Client()

client:on('ready', function()
	-- client.user is the path for your bot
	print('Logged in as '.. client.user.username)
end)


function script_path()
    local str = debug.getinfo(2, "S").source:sub(2)
    return str:match("(.*/)")
end 

function doesFileExist(fname)
    local results = false
    local filePath = script_path() .. "/" .. fname
    if ( filePath ) then
        local file, errorString = io.open( filePath, "r" )
        if not file then
            print( "File error: " .. errorString )
        else
            print( "File found: " .. fname )
            results = true
            file:close()
        end
    end
    return results
end


function WriteFile(saveData,File)
    local path = script_path() .. "/" .. File
    local file, errorString = io.open( path, "w" )
 
    if not file then
        print( "File error: " .. errorString )
    else
        file:write( saveData )
        io.close( file )
    end
    file = nil
end


function ReadFile(File)
    local path = script_path() .. "/" .. File
    local file, errorString = io.open( path, "r" )
    local contents

    if not file then
        print( "File error: " .. errorString )
    else
        contents = file:read( "*a" )
        io.close( file )
    end
    file = nil
    return contents
end

local StartPoint=0,EndPoint
local Sentence = ""
local i = 0
local Book = ReadFile("Book_1.txt")
function Reader(message)
    i = i + 1
    local c = string.sub(Book, i, i)
    print(c)
    if((c == "." or c == ",") and string.lower(string.sub(Book, i-2,i-1)) ~= "mr" and string.lower(string.sub(Book, i-3,i-1)) ~= "mrs" and string.lower(string.sub(Book, i-2,i-1)) ~= "ms") then
        if(StartPoint == nil) then
            StartPoint = i
        elseif(StartPoint ~= nil) then
            EndPoint = i
            Sentence = Sentence .. string.sub(Book,StartPoint+1,EndPoint)
            if(c == ".") then 
                message.channel:send(Sentence)
                Sentence = "" 
            end 
            StartPoint = EndPoint
            EndPoint = nil
        end
    end
end
client:on('messageCreate', function(message)
    if message.content == "!Start" then
        print("Waiting")
        timer.setInterval(100, function()
            coroutine.wrap(Reader)(message)
        end)
	end
end)

client:run('Bot Njk4NTQyMDExOTgwMDU0NjQ4.XpHV8Q.8GHoXdwJ2XTHitss-z4HKb9hQtc')