--http://www.computercraft.info/forums2/index.php?/topic/5854-json-parser-for-computercraft/page__p__49926__hl__kilos__fromsearch__1#entry49926
--By ElvishJerricco
--[[I've written a JSON parser! Simply give it a JSON block and it returns a lua value. Just use os.loadAPI() to load it up. Then call json.decode(). This is really useful because a lot of http servers (for example, the github api) use JSON to transmit data. So now you can actually use that data!

I plan on adding encoding later tonight.
I added encoding =D

Example:

os.loadAPI("json")
str = http.get("http://www.someserver.com/").readAll()
obj = json.decode(str)
value = obj.thisVariableWasInTheJSONAndThisIsCoolerThanUsingStringGmatchToFindEverything

jsonstring = json.encode(obj)
sendThisToWhateverNeedsIt(jsonstring)

pastebin get 4nRg9CHU json 
]]


-- Utilities
local whites = {['\n']=true; ['r']=true; ['\t']=true; [' ']=true; [',']=true; [':']=true}
function removeWhite(str)
        while whites[str:sub(1, 1)] do
                str = str:sub(2)
        end
        return str
end
 
function isArray(t)
        local arrayi = 0
        for i,v in ipairs(t) do
                arrayi = arrayi + 1
        end
        local arrayp = 0
        for k,v in pairs(t) do
                arrayp = arrayp + 1
        end
        if arrayp == arrayi then return true else return false end
end
 
-- Data types
function encodeBoolean(v, str)
        return str .. tostring(v)
end
function parseBoolean(str)
        if str:sub(1, 4) == "true" then
                return true, removeWhite(str:sub(5))
        else
                return false, removeWhite(str:sub(6))
        end
end
 
local numChars = {['e']=true; ['E']=true; ['+']=true; ['-']=true; ['.']=true}
function encodeNumber(val, str)
        return str .. tostring(val)
end
function parseNumber(str)
        local i = 1
        while numChars[str:sub(i, i)] or tonumber(str:sub(i, i)) do
                i = i + 1
        end
        local val = tonumber(str:sub(1, i - 1))
        str = removeWhite(str:sub(i))
        return val, str
end
 
function encodeString(val, str)
        local newstr = "\""
        for i=1, val:len() do
                local ichar = val:sub(i, i)
                if ichar == "\n" then
                        newstr = newstr .. "\\n"
                elseif ichar == "\r" then
                        newstr = newstr .. "\\r"
                elseif ichar == "\t" then
                        newstr = newstr .. "\\t"
                elseif ichar == "\"" then
                        newstr = newstr .. "\\\""
                elseif ichar == "\\" then
                        newstr = newstr .. "\\\\"
                else
                        newstr = newstr .. ichar
                end
        end
        return str .. newstr .. "\""
end
function parseString(str)
        str = str:sub(2)
        local val = ""
        local escaped = false
        while str:sub(1, 1) ~= "\"" and not escaped do
                if escaped then
                        if str:sub(1, 1) == "n" then
                                val = val .. "\n"
                        elseif str:sub(1, 1) == "r" then
                                val = val .. "\r"
                        elseif str:sub(1, 1) == "t" then
                                val = val .. "\t"
                        elseif str:sub(1, 1) == "\"" then
                                val = val .. "\""
                        elseif str:sub(1, 1) == "\\" then
                                val = val .. "\\"
                        else
                                val = val .. "\\" .. str:sub(1, 1)
                        end
                elseif str:sub(1, 1) == "\\" then
                        escaped = true
                else
                        val = val .. str:sub(1, 1)
                end
                str = str:sub(2)
        end
        str = removeWhite(str:sub(2))
        return val, str
end
 
function encodeArray(val, str)
        str = str .. "["
        for i,v in ipairs(val) do
                str = encodeValue(v, str)
                str = str .. ","
        end
        if str:sub(-1) == "," then
                str = str:sub(1, -2)
        end
        return str .. "]"
end
function parseArray(str)
        str = removeWhite(str:sub(2))
       
        local val = {}
        local i = 1
        while str:sub(1, 1) ~= "]" do
                local v = nil
                v, str = parseValue(str)
                val[i] = v
                i = i + 1
                str = removeWhite(str)
        end
        str = removeWhite(str:sub(2))
        return val, str
end
 
function encodeObject(val, str)
        str = str .. "{"
        for k,v in pairs(val) do
                str = encodeMember(k, v, str)
                str = str .. ","
        end
        if str:sub(-1) == "," then
                str = str:sub(1, -2)
        end
        return str .. "}"
end
function parseObject(str)
        str = removeWhite(str:sub(2))
       
        local val = {}
        while str:sub(1, 1) ~= "}" do
                local k, v = nil, nil
                k, v, str = parseMember(str)
                val[k] = v
                str = removeWhite(str)
        end
        str = removeWhite(str:sub(2))
        return val, str
end
 
-- Functions for parsing keys and values
function encodeMember(k, v, str)
        str = encodeValue(k, str) .. ":"
        return encodeValue(v, str)
end
function parseMember(str)
        local k = nil
        k, str = parseValue(str)
        local val = nil
        val, str = parseValue(str)
        return k, val, str
end
 
function encodeValue(v, str)
        if type(v) == "table" then
                if isArray(v) then
                        return encodeArray(v, str)
                else
                        return encodeObject(v, str)
                end
        elseif type(v) == "number" then
                return encodeNumber(v, str)
        elseif type(v) == "string" then
                return encodeString(v, str)
        elseif type(v) == "boolean" then
                return encodeBoolean(v, str)
        end
end
function parseValue(str)
        local fchar = str:sub(1, 1)
        if fchar == "{" then
                return parseObject(str)
        elseif fchar == "[" then
                return parseArray(str)
        elseif tonumber(fchar) ~= nil or numChars[fchar] then
                return parseNumber(str)
        elseif str:sub(1, 4) == "true" or str:sub(1, 5) == "false" then
                return parseBoolean(str)
        elseif fchar == "\"" then
                return parseString(str)
        end
        return nil
end
 
function encode(v)
        return encodeValue(v, "")
end
function decode(str)
        str = removeWhite(str)
        t = parseValue(str)
        return t
end