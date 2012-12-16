local pack=require 'packages.utils.table'.pack
local io=io
local string=string
local table=table
local type=type
local tostring=tostring
local pairs=pairs
local print=print


env=getfenv()
setmetatable(env,nil)

-- Make sure stdout is actually flushed every line
if io and io.stdout then
    io.stdout:setvbuf("line")
end

local function quotestring(x)
    local function q(k) return
        k=='"'  and '\\"'  or 
        k=='\\' and '\\\\' or 
        string.format('\\%03d', k :byte()) 
    end
    return '"' .. x :gsub ('[%z\1-\9\11\12\14-\31\128-\255"\\]', q) .. '"'
end

------------------------------------------------------------------------------
-- virtual printer: print a textual description of the objects in `...', using
-- function `write()' as a writer. By providing the appropriate writer, one
-- can make this function write on a TCP channel, in a string,... anywhere.
-- print_indent is the number of indentation characters used to render
-- tables. If nil/false, tables are rendered without carriage returns.
------------------------------------------------------------------------------
function vprint (write, print_indent, ...)
   local in_progress = { }
   local indent_level = 0
   local tinsert = table.insert
   local function aux(x)
      local  t=type(x)
      if     t=="string"  then write(quotestring(x))
      elseif t=="boolean" then write(x and "true" or "false")
      elseif t=="number"  then write(tostring(x))
      elseif t=="nil"     then write("nil")
      elseif t=="table"   then
         if in_progress[x] then write(tostring(table)) else
            in_progress[x] = true
            indent_level = indent_level+1

            local function print_separator()
                if print_indent then write(",\r\n" .. (" "):rep(print_indent * indent_level))
                else write(", ") end
            end

            -- number of elements according to pairs(): zero, one, many
            local at_least_one, more_than_one = false, false
            for _ in pairs(x) do
                if at_least_one then more_than_one=true; break
                else at_least_one=true end
            end

            if not at_least_one then write "{ }"; return
            elseif not more_than_one or not print_indent then write "{ "
            else write("{\r\n" .. (" "):rep(print_indent * indent_level)) end

            local list_keys = { }
            local last_list_key = 0
            repeat
                local i = last_list_key + 1
                local occupied = x[i]~=nil
                if occupied then list_keys[i]=true; last_list_key=i end
            until not occupied

            for i=1, last_list_key do
                if i>1 then print_separator() end
                aux(x[i])
            end
            
            local first_hash_pair = true
            for k, v in pairs(x) do
                if not list_keys[k] then -- don't reprint the list-part
                    -- separator
                    if not first_hash_pair or last_list_key~=0 then print_separator() end
                    first_hash_pair = false
                    -- key
                    if type(k)=="string" and k:match"^[%a_][%w_]*$" then write(k .. " = ")
                    else write("["); aux(k); write("] = ") end
                    -- value
                    aux(v)
                end
            end
            write (" }")

            indent_level = indent_level-1
            in_progress[x] = nil
         end
      else write(tostring(x)) end
   end
   local args = pack(...)
   local nb = args.n
   for k = 1, nb do aux(args[k]); if k<nb then write "\t" end end
end

------------------------------------------------------------------------------
-- A more precise print (on stdout)
------------------------------------------------------------------------------
function p (...)
   local out = {}
   local function write(s)
      table.insert(out, s)
   end
   vprint(write, 3, ...)
   print(table.concat(out))
end

------------------------------------------------------------------------------
-- Build up and return a string instead of printing in some channel.
------------------------------------------------------------------------------
function siprint(indent, ...)
   local ins, acc = table.insert, { }
   vprint(function(x) return ins(acc, x) end, indent, ...)
   return table.concat(acc)
end

function sprint(...)
    return siprint(false, ...)
end

function printf(...) return print(string.format(...)) end

return env