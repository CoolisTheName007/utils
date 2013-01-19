-- luau: Lua-upgraded
 
-- Since we're sharing our scope with the user, make a table to keep
-- all our stuff in, so we pollute the namespace as little as possible:
luau_={}
luau_.n = 0         -- current line number
luau_.opt = {}      -- options data
luau_.mac = {}      -- macros
-- A default macro:
luau_.mac.la = {['def']='os.loadAPI("%1")',['pnum']=1}
 
-- Default option settings:
luau_.opt.skip_lines={
    ['type'] = 'number',
    ['value'] = 0,
    ['default'] = 0,
    ['desc']='Number of blank lines to skip between input/output pairs.'
}
luau_.opt.use_color={
    ['type'] = 'boolean',
    ['value'] = true,
    ['default'] = true,
    ['desc']='Whether to use color, if available.'
}
 
-- Some variables we do want to expose:
in_ = {}      -- input history
out_ = {}     -- output history
 
 
-- Help topics:
luau_.help = {}
 
luau_.help.summary = 'The following topics are available, and can be abbreviated--for instance, "/help sub" for "/help substitution".'
 
luau_.help.substitution = 'Typing "s/find-expr/replace-expr/" will repeat the previously entered line, but with all occurrences of find-expr replaced by replace-expr. Lua\'s string-matching patterns may be used in find-expr. This is often quicker than using up-arrow to recall the command and editing it manually.'
 
luau_.help.history = 'The tables in_ and out_ hold the input and output histories, and can be referenced, for example: "result=out_[9]".'
 
luau_.help['repeat-command'] = 'To repeat a previous input, use the "!<n>" command. For example, typing !23 will re-evaluate the 23rd command in the history.'
 
luau_.help['question-mark'] = 'The "?" character is a shortcut for print: "?foo" is short for "print(foo)". If foo is a table, then its keys and values will be displayed.'
 
luau_.help['macros'] = 'You can define macros to shorten frequently-typed strings. For example, if you type "/macro %la=os.loadAPI", then in the future any occurence of "%la" in commands you type will be changed to "os.loadAPI" before processing by Lua.\n\nMacros can also accept parameters. For example, "/macro %rs=rednet.send(%1,%2)" will tell luau to expand "%rs[23][\'hi!\']" into "rednet.send(23,\'hi!\')".\n\nParameters may appear more than once and out of order--a silly example is "/macro %palindrome=%3%2%1%2%3", which expands "%palindrome[A][B][C]" into "CBABC".'
 
luau_.help['commands'] = 'Luau has some built-in commands which are invoked by starting a line with the slash "/" character. Type "/commands" for a list.'
 
-- Build a sorted list of help topics:
luau_.helpkeys = {}
for k in pairs(luau_.help) do
    if k~='summary' then
        table.insert(luau_.helpkeys, k)
    end
end
table.sort(luau_.helpkeys)
 
-- Define the appropriate color function:
if term.isColor() then
    term.setTextColor(colors.gray)
    luau_.setColor = function(c)
        if luau_.opt.use_color.value then
            term.setTextColor(c)
        else
            term.setTextColor(gray)
        end
    end
else
    luau_.setColor = function(c) return end
end
 
luau_.terminated = false
-- End of initialization code.
 
function luau_.terminate()
    -- Goodbye, cruel world:
    luau_.terminated = true
end
 
function luau_.separator()
    -- A line of dashes, of the appropriate length:
    return(string.rep('-', term.getSize()))
end
 
function luau_.loadData()
    -- Load config options and macros:
    local h
    if fs.exists('luau.conf') then
        h = fs.open('luau.conf','r')
        local opt, mac
        opt = textutils.unserialize(h.readLine())
        mac = textutils.unserialize(h.readLine())
        h.close()
        if type(opt)=='table' and type(mac)=='table' then
            luau_.opt = opt
            luau_.mac = mac
            return true
        else
            luau_.showError('Unable to load configuration; /luau.conf is corrupt. Exiting. (Delete or rename /luau.conf to start fresh)')
            return false
        end
    else
        luau_.setColor(colors.blue)
        print('Configuration file /luau.conf does not exist; creating with default values.')
        luau_.saveData()
        return true
    end
end
 
function luau_.saveData()
    -- Save config options and macros:
    h = fs.open('luau.conf','w')
    h.writeLine(textutils.serialize(luau_.opt))
    h.writeLine(textutils.serialize(luau_.mac))
    h.close()
end
 
function luau_.firstMatch(s, t)
    for i, k in ipairs(t) do
        if string.find(k, s) == 1 then
            return k
        end
    end
    return nil
end
 
function luau_.showError(errorText)
    -- Report errors to the user
    luau_.setColor(colors.red)
    print(errorText)
    luau_.setColor(colors.gray)
end
 
function luau_.trim(s)
    -- Trim leading/trailing spaces from string s:
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end
 
function luau_.macro(s)
    -- !<n> to re-evaluate n-th input:
    local a, b, n
    a, b, n = s:find('!(%d+)')
    n = tonumber(n)
    if a == 1 then
        if in_[n] then
            s = in_[n]
        else
            luau_.showError("History entry "..tostring(n).." not found.")
            s = ''
        end
        return s
    end
    -- s/foo/bar/ substitutions
    a, b, find, replace, flags = s:find('s/(.+)/(.*)/(.*)')
    if find and in_[luau_.n] then
        s = in_[luau_.n-1]:gsub(find, replace)
        return s
    end
    -- Macro expansion:
    local lMark, rMark = '>tboss>', '<tboss<'
    -- This lMark/rMark business is an ugly hack that wouldn't be
    -- necessary if I knew how to directly capture the stuff INSIDE a
    -- balanced expression captured with %b[], i.e. without the brackets.
    for name, macro in pairs(luau_.mac) do
        local pattern = '%%'..name..string.rep('(%b[])',macro.pnum)
        -- This is a workaround for a bug in the string library:
        local s_ = s..string.rep('[ ]',macro.pnum)
        local a, b = s_:find(pattern)
        if b and b<=s:len() then
            if s_:find(pattern) then
                local def = macro.def:gsub('(%%%d)',lMark..'%1'..rMark)
                s_ = s_:gsub(pattern, def)
                s_ = s_:gsub(lMark..'%[', '')
                s_ = s_:gsub('%]'..rMark, '')
                s = s_:sub(1, s_:len()-3*macro.pnum)
            end
        end
    end
    return s
end
 
function luau_.columnList(t)
    -- Print the elements of t in columns:
    -- Compute the max length of the names so we can decide
    -- how many columns to print them in:
    local maxLen = 0
    for i,k in ipairs(t) do
        if string.len(k) > maxLen then maxLen = string.len(k) end
    end
    local spacing = 2   -- Spacing between columns
    local w, h = term.getSize()
    local nCols = math.floor((w+spacing)/(maxLen+spacing))
    -- Print all the names in columns:
    for i, k in ipairs(t) do
        if (i%nCols == 0) or (i == #t) then
            print(k)
        else
            write(k..string.rep(' ', maxLen+spacing-string.len(k)))
        end
    end
end
 
function luau_.showHelp(topic)
    luau_.setColor(colors.blue)    
    topic = tostring(topic)
    if topic ~= '' then
        -- Do partial matching:
        local mtopic = luau_.firstMatch(topic, luau_.helpkeys)
        if luau_.help[mtopic] then
            local m, n = term.getSize()
            textutils.pagedPrint('('..mtopic..') '..luau_.help[mtopic],n-3)
        else
            print('No help found for "'..topic..'". Type "help" for a list of topics.')
        end
    else
        -- Print help summary and list of topics:
        print(luau_.help.summary)
        print(luau_.separator())
        --luau_.setColor(colors.lightBlue)
        luau_.columnList(luau_.helpkeys)
    end
end
 
function luau_.searchHistory(s)
    -- Print a list of history entries matching s.
    -- Should refactor this into a search and a print.
    local nFound = 0
    for i,v in ipairs(in_) do
        if string.find(v,s) then
            print(i..': '..v)
            nFound = nFound+1
        end
    end
    return nFound
end
 
function luau_.keySort(a, b)
    -- Order function for table keys, returns true if a<b:
    if type(a)=='number' and type(b)=='number' then
        return a<b
    elseif type(a)=='number' then
        return true
    elseif type(b)=='number' then
        return false
    elseif type(a)=='string' and type(b)=='string' then
        return a<b
    elseif type(a)=='string' then
        return true
    elseif type(b)=='string' then
        return false
    else
        return (type(a)<type(b))
    end
end
 
function luau_.serial(v)
    -- Wrapper for textutils.serialize, to work with all types
    if string.find("nil boolean number string table", type(v)) then
        local err, str = pcall(function() textutils.serialize(v) end)
        if err then str=tostring(v) end
        return str
    else
        return tostring(v)
    end
end
 
function luau_.setMacro(p, overwrite)
    -- Define or redefine a macro:
    luau_.setColor(colors.yellow)
    if p=='' then
        -- Display currently defined macros:
        print("The following macros are currently defined:")
        print(luau_.separator())
        for k in pairs(luau_.mac) do
            print("%"..k.."="..luau_.mac[k].def)
        end
    else
        -- Should be in the form "%name=def":
        local a, b, name, def = p:find('%%([%w_]+)=(.*)')
        if name then
            -- See if it's already defined:
            if luau_.mac[name] and not overwrite then
                print('Macro %'..name..' is already defined. Use /Macro to overwrite it.')
                return false
            end
            -- See how many params:
            local n = 0
            def:gsub('%%(%d+)', function(s) n=tonumber(s) end)
            luau_.mac[name] = {['def']=def, ['pnum']=n}
            -- Save it right away. We could wait until we exit, but
            -- during development crashes are likely so let's not
            -- lose people's work.
            luau_.saveData()
        else
            luau_.showError('Invalid macro definition (see /help macro).')
            return false
        end
    end
    return true
end
 
function luau_.setOpt(p)
    luau_.setColor(colors.yellow)
    if p=='' then
        print('The following options are available. Type "/option <option_name>=<value>" to change, or "/option <option_name>" to get a description.')
        local keys = {}
        for k in pairs(luau_.opt) do keys[#keys+1]=k end
        table.sort(keys, luau_.keySort)
        print(luau_.separator())
        for i, k in ipairs(keys) do
            print(k..'='..tostring(luau_.opt[k].value))
        end
    elseif p:find('=') then
        local a, b, opt, val = p:find("([%w_]+)%s*=%s*(.*)")
        if luau_.opt[opt] then
            -- Make sure the types are right:
            local t = luau_.opt[opt].type
            local ok = false
            if t=='boolean' then
                local v = val:lower()
                if v=='true' or v=='1' or v=='yes' or v=='y' then
                    luau_.opt[opt].value = true
                    ok = true
                elseif v=='false' or v=='0' or v=='no' or v=='n' then
                    luau_.opt[opt].value = false
                    ok = true
                end
            elseif t=='number' then
                local v = tonumber(val)
                if v then
                    luau_.opt[opt].value = v
                    ok = true
                end
            elseif t=='string' then
                luau_.opt[opt].value = val
                ok = true
            end
            if ok then
                luau_.saveData()
            else
                print('Value for '..opt..' must be of type '..t..'.')
            end
        else
            print('Option "'..p..'" not found. Type "/option" for a list.')
        end
    else
        if luau_.opt[p] then
            print(luau_.opt[p].desc..' [type='..luau_.opt[p].type..', value='..tostring(luau_.opt[p].value)..', default='..tostring(luau_.opt[p].default)..']')
        else
            print('Option "'..p..'" not found. Type "/option" for a list.')
        end
    end
end
 
function luau_.showCommands(p)
    luau_.setColor(colors.blue)
    if p=='' then
        print('The following commands are available. Type "/command <command-name>" for details.')
        print(luau_.separator())
        luau_.columnList(luau_.cmdNames)
    else
        local cmd = luau_.firstMatch(p, luau_.cmdNames)
        if cmd then
            print('/'..cmd..': '..luau_.cmd[cmd].desc)
        else
            print('Command "'..p..'" not found. Type "/commands" for a list.')
        end
    end
end
 
-- Now that we've defined all our handler functions, we can set up the command list:
luau_.cmd = {}
luau_.cmd.help = {
    ['handler'] = luau_.showHelp,
    ['desc'] = 'Online help. Type "/help <topic>", or "/help" for a list of topics.',
}
luau_.cmd.exit = {
    ['handler'] = luau_.terminate,
    ['desc'] = 'Exits Luau and returns you to the shell or wherever else you launched it from.',
}
luau_.cmd.history = {
    ['handler'] = luau_.searchHistory,
    ['desc'] = 'Typing "/history" will simply print the entire history buffer, while "/history <pattern>" will only show entries matching <pattern>.',
}
luau_.cmd.macro = {
    ['handler'] = function(p) luau_.setMacro(p, false) end,
    ['desc'] = 'Define a text-expansion macro with "/macro %<name>=<output>", or type "/macro" for a list of existing macros. Type "/help macros" for more details.',
}
luau_.cmd.Macro = {
    ['handler'] = function(p) luau_.setMacro(p, true) end,
    ['desc'] = 'Same as "/macro", but able to overwrite existing definitions.',
}
luau_.cmd.options = {
    ['handler'] = luau_.setOpt,
    ['desc'] = 'Type "/options" for a list of all options, "/option <name>" for an option\'s description, or "/option <name>=<value>" to change it.',
}
luau_.cmd.commands = {
    ['handler'] = luau_.showCommands,
    ['desc'] = 'Type "/commands" for a list of commands, or "/command <command-name>" to view a description of a particular one.',
}
luau_.cmdNames = {}
for k in pairs(luau_.cmd) do table.insert(luau_.cmdNames, k) end
table.sort(luau_.cmdNames)
 
 
function luau_.go()
    -- Load config options and macros:
    if not luau_.loadData() then return false end
    luau_.setColor(colors.blue)
    print()
    print('LUAU--LUA Upgraded v0.1 by Tinyboss\nType "/exit" to exit, "/help" for help.')
    while not luau_.terminated do
        luau_.setColor(colors.gray)
        for i=1,luau_.opt.skip_lines.value do print() end
        luau_.n = luau_.n+1
        -- Get the next input, passing the input history for recall by up-arrow:
        local input = ''
        while luau_.trim(input)=='' do
            luau_.setColor(colors.lime)
            write(' in_['..luau_.n..']: ')
            luau_.setColor(colors.lightGray)
            input = luau_.trim(read(false, in_,getfenv(1)))
        end
        in_[luau_.n] = input
        luau_.handled = false
        -- ? is a shortcut for print, with benefits:
        if in_[luau_.n]:sub(1,1) == "?" then
            rest_ = luau_.trim(in_[luau_.n]:sub(2))
            if rest_ == "" then
                -- If they just typed "?", they probably wanted help:
                luau_.setColor(colors.blue)
                print('"?foo" is a synonym for "print(foo)". Use "/help" for help.')
                luau_.handled = true
            elseif type(getfenv(1)[rest_])=="table" then
                -- If it's a table, display it:
                local keys = {}
                for k in pairs(getfenv(1)[rest_]) do
                    keys[#keys+1]=k
                end
                table.sort(keys, luau_.keySort)
                local kv = {}
                for i,k in ipairs(keys) do
                    kv[i] = luau_.serial(k)..'='
                        ..luau_.serial(getfenv(1)[rest_][k])
                end
                print('{',table.concat(kv, ', '),'}')
                luau_.handled = true
            else
                in_[luau_.n] = 'print('..in_[luau_.n]:sub(2)..')'
            end
        end
        if not luau_.handled then
            -- See if it's a slash command:
            local a_, b_, cmd_, rest_ = in_[luau_.n]:find('/(%a+)%s*(.*)')
            if a_==1 then
                cmd_ = luau_.firstMatch(cmd_, luau_.cmdNames)
                if cmd_ then
                    luau_.cmd[cmd_].handler(rest_)
                else
                    luau_.setColor(colors.yellow)
                    print('Invalid command. (Try "/help".)')
                end
            else
                -- Do macro substitution before passing it to Lua:
                in_[luau_.n] = luau_.macro(in_[luau_.n])
                luau_.setColor(colors.gray)
                is_print_ = string.sub(in_[luau_.n], 1, 6)=='print('
                -- Try it as an expression first:
                func_, err_ = loadstring('out_[luau_.n]='..in_[luau_.n])
                if err_ then
                    -- Try it as a statement (e.g. "pi=3"):
                    func_, err_ = loadstring(in_[luau_.n])
                    if err_ then
                        luau_.showError('(loadstring)'..err_)
                    else
                        setfenv(func_, getfenv(1))
                        success_, err_ = pcall(func_)
                        if not success_ then
                            luau_.showError(err_)
                        end
                    end
                else
                    -- It worked as an expression, so store and show the result:
                    setfenv(func_, getfenv(1))
                    success_, err_ = pcall(func_)
                    if success_ then
                        if out_[luau_.n] and not is_print_ then
                            luau_.setColor(colors.green)
                            write('out_['..luau_.n..']: ')
                            luau_.setColor(colors.gray)
                            print(out_[luau_.n])
                        end
                    else
                        luau_.showError(err_)
                    end
                end
            end
        end
    end
    -- Save config and macro data:
    luau_.saveData()
end
 
luau_.go()