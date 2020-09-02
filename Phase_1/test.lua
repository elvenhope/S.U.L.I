function FixWords(Sentence)
    local Counter = 1
    local Result = ""
    while Counter <= #Sentence do
        local Character = Sentence:sub(Counter,Counter)
        if(Character == " " and Sentence:sub(Counter+1,Counter+1) ~= nil) then
            if(string.byte(Sentence:sub(Counter+1,Counter+1)) >= 65 and string.byte(Sentence:sub(Counter+1,Counter+1)) <= 122) then
                if(Sentence:sub(Counter+2,Counter+2) == " " or Sentence:sub(Counter+2,Counter+2) == nil) then
                    Result = Result .."'".. Sentence:sub(Counter+1,Counter+1) .. " "
                    Counter = Counter + 1
                else
                    Result = Result .. Character
                end
            end
        else
            Result = Result .. Character
        end
        Counter = Counter + 1
    end
    return Result
end

print(FixWords("and it whose or who started it"))

--- AB*CDE