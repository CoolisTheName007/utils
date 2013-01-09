---improved read() function with two modes for TAB completion:
--1: reads keys from a given environment
--2: reads file system paths
---use:
--read(_sReplaceChar, _tHistory,_tEnv,_mode)
--_tEnv is the environment to scan; default is _G
--_mode is by default true, what means mode 2 is chosen by default
--rightShift pressed once resets the matches; pressed twice changes the mode.
--tab-completing a full match adds a termination when possible, e.g. try calling test() (down below)
--and pressing: [tab][rigthShift][tab]

--fix for CC twisted bits
local old_getmetatable=getmetatable
local getmetatable=function(t)
	if type(t)=='string' then return string end
	return old_getmetatable(t)
end

local pathutils={} --API
do
	local segments, get, concat, find

	local function pathconcat(pt, starti, endi)
		local t = {}
		local prev
		local empties = 0
		starti = starti or 1
		endi = endi or #pt
		
		for i = starti, endi do
			local v = pt[i]
			if not v then break
			elseif v == '' then
				empties = empties+1
			else
				table.insert(t, prev)
				prev = v
			end
		end
		table.insert(t, prev)
		--log('PATH', 'INFO', "pathconcat(%s, %d, %d) generates table %s, wants indexes %d->%d",
		--    sprint(pt), starti, endi, sprint(t), 1, endi-starti+1-empties)
		return table.concat(t, '.', 1, endi-starti+1-empties)
	end

	function get(t, path)
		local p = type(path)=='string' and segments(path) or path
		local k = table.remove(p)
		if not k then return t end
		local t = find(t, p)
		return t and t[k]
	end



	function segments(path)
		local t = {}    
		local index, newindex, elt = 1
		repeat
			newindex = path:find(".", index, true) or #path+1 --last round
			elt = path:sub(index, newindex-1)
			elt = tonumber(elt) or elt        
			if elt and elt ~= "" then table.insert(t, elt) end
			index = newindex+1     
		until newindex==#path+1   
		return t
	end

	function find(t, path, force)
		path = type(path)=="string" and segments(path) or path
		for i, n in ipairs(path) do
			local v  = t[n]
			if type(v) ~= "table" then
				if not force or (force=="noowr" and v~=nil) then return nil, pathconcat(path, 1, i)
				else v = {} t[n] = v end
			end
			t = v
		end
		return t
	end
	
	pathutils.get=get
end


local function autocomplete(path, env)
    env = env or _G
    path = path or ""

    path = path:match("([%w_][%w_%.%:]*)$") or "" -- get the significant end part of the path (non alphanum are spliters...)
    local p, s, l = path:match("(.-)([%.%:]?)([^%.%:]*)$") -- separate into sub path and leaf, getting the separator
    local t = pathutils.get(env, p)
    local funconly =  s == ":"
    local tr = {}

    local function copykeys(src, dst)
        if type(src) ~= 'table' then return end
        for k, v in pairs(src) do
            local tv = type(v)
            if type(k)=='string' and k:match("^"..l) and (not funconly or tv=='function' or (tv=='table' and getmetatable(v) and getmetatable(v).__call)) then dst[k] = true end
        end
    end

    copykeys(t, tr)

    if s == ":" or s == "." then
		local m = getmetatable(t)
        if m then
            local i, n = m.__index, m.__newindex
            copykeys(i, tr)
            if n ~= i then copykeys(n, tr) end
            if m~= i and m ~= n then copykeys(m, tr) end -- far from being perfect, but it happens that __index or __newindex are functions that uses the metatable as a object method holder
        end
    end
	local r = {}
	for k, v in pairs(tr) do table.insert(r, k) end

    -- sort the entries by lexical order
	table.sort(r)
	--when we have a complete match we can add a ".", ":" or "(" if the object is a table or a function
	if l == r[1] then
		local tl = t[l]
		local ttl = type(tl)
		if ttl == 'function' then r[1]=r[1].."("
		elseif getmetatable(tl) and getmetatable(tl).__index then
			r[1]=r[1]..":" -- pure guess, object that have __index metamethod may be an 'object', so add ':'
		elseif ttl == 'table' then r[1]=r[1].."."
		end
	end
	l=l or ''
    return r,l:len()
end


local function get_to_match(sLine,nPos)
	if sLine:sub(nPos,nPos)==' ' then
		return ''
	end
	local sRev=sLine:reverse()
	sLeft=sRev:match('[^_]*',sRev:len()-nPos):reverse()
	--sRigth=sLine:match('[^ ]*',nPos+1)
	return sLeft--..sRigth
end


local function esc(x)
  return (x:gsub('%%', '%%%%')
           :gsub('%^', '%%%^')
           :gsub('%$', '%%%$')
           :gsub('%(', '%%%(')
           :gsub('%)', '%%%)')
           :gsub('%.', '%%%.')
           :gsub('%[', '%%%[')
           :gsub('%]', '%%%]')
           :gsub('%*', '%%%*')
           :gsub('%+', '%%%+')
           :gsub('%-', '%%%-')
           :gsub('%?', '%%%?'))
end

function get_fs_matches(s)
	local tMatches={}
	local path = s:match([[[^%[%]%'%"]+$]]) or "" -- get the significant end part of the path
    local p, s, l = path:match("^(.-)([/\\]?)([^/\\]*)$") -- separate into sub path and leaf, getting the separator
	local sAbsPath = shell.resolve( p )
	if fs.isDir( sAbsPath ) then
		-- Search for matches in the resolved folder.
		local ok, tFileList = pcall( fs.list, sAbsPath )
		if ok then
			local match = nil
			-- Populate table with all matches.
			local pat="^"..esc(l)..'.*'
			for k, v in ipairs(tFileList) do
				match = string.match( v, pat)
				if match then
					-- print(match)
					table.insert( tMatches,match )
				end
			end
		end
	end
	table.sort(tMatches)
	if l == tMatches[1] then
		local tl = tMatches[1]
		if fs.isDir(sAbsPath..'/'..l) then
			 tMatches[1]= tMatches[1]..'/'
		end
	end
	return tMatches,l:len()
end

local get_env_matches=autocomplete

function read( _sReplaceChar, _tHistory,_tEnv,_mode)
	local mode=_mode==nil or _mode==true
	
    term.setCursorBlink( true )
 
    local sLine = ""
	local nHistoryPos = nil
	local nPos = 0
    if _sReplaceChar then
        _sReplaceChar = string.sub( _sReplaceChar, 1, 1 )
    end
	local count=0
	
	local tMatches = { n = 0}
	function reset_matches()
		tMatches = { n = 0}
	end
	
	function get_matches(s)
		if mode then
			return get_fs_matches(s)
		else
			return get_env_matches(s,_tEnv)
		end
	end
	
	local w, h = term.getSize()
	local sx, sy = term.getCursorPos()     
   
	local function redraw( _sCustomReplaceChar )
			local nScroll = 0
			if sx + nPos >= w then
					nScroll = (sx + nPos) - w
			end
			term.setCursorPos( sx, sy )
			local sReplace = _sCustomReplaceChar or _sReplaceChar
			if sReplace then
					term.write( string.rep(sReplace, string.len(sLine) - nScroll) )
			else
					term.write( string.sub( sLine, nScroll + 1 ) )
			end
			term.setCursorPos( sx + nPos - nScroll, sy )
	end
   
	while true do
			local sEvent, param = os.pullEvent()
			if sEvent == "char" then
					reset_matches()
					sLine = string.sub( sLine, 1, nPos ) .. param .. string.sub( sLine, nPos + 1 )
					nPos = nPos + 1
					redraw()
				   
			elseif sEvent == "key" then
				if not (param == keys.tab) then
					reset_matches() -- Reset completion match-table.
				end
				if not(param == keys.rightShift) then
					count=0
				end
				if param == keys.enter then
					-- Enter
					break		   
				elseif param == keys.tab then
					-- Tab
					if tMatches[1] then   -- tab was pressed before.
						-- [[ We already have matches, show the next one ]]
						local nLastMatchSize = string.len( tMatches[tMatches.n])
					   
						-- Shift pointer to next match.
						tMatches.n = (tMatches.n)%#tMatches +1  -- Wrap around if the pointer has gone past the end.
					   
						-- Clear the line if the new match is smaller than the previous.
						if string.len(tMatches[tMatches.n]) < nLastMatchSize then redraw(" ") end
						-- Assemble the new line.
						sLine = string.sub( sLine, 1, nPos - nLastMatchSize ) .. tMatches[tMatches.n]..string.sub( sLine, nPos+1)
						nPos = nPos-nLastMatchSize+tMatches[tMatches.n]:len()
						redraw()
					else
						-- [[ No matches yet, look for some now. ]]
						tMatches,len=get_matches(get_to_match(sLine,nPos))
						tMatches.n=0
						-- Show first match.
						if #tMatches > 0 then
							tMatches.n=1
							local nLastMatchSize = len
							sLine = string.sub( sLine, 1, nPos - nLastMatchSize ) .. tMatches[tMatches.n]..string.sub( sLine, nPos+1)
							nPos = nPos-nLastMatchSize+tMatches[tMatches.n]:len()
							redraw()
						end
						if #tMatches==1 then reset_matches() end
					end
				elseif param==keys.rightShift then
					count=(count+1)%2
					if count==0 then
						mode=not mode
					end
					reset_matches()
				elseif param == keys.left then
						-- Left
						if nPos > 0 then
								nPos = nPos - 1
								redraw()
						end
					   
				elseif param == keys.right then
						-- Right                               
						if nPos < string.len(sLine) then
								nPos = nPos + 1
								redraw()
						end
			   
				elseif param == keys.up or param == keys.down then
					-- Up or down
					if _tHistory then
						redraw(" ");
						if param == keys.up then
								-- Up
								if nHistoryPos == nil then
										if #_tHistory > 0 then
												nHistoryPos = #_tHistory
										end
								elseif nHistoryPos > 1 then
										nHistoryPos = nHistoryPos - 1
								end
						else
								-- Down
								if nHistoryPos == #_tHistory then
										nHistoryPos = nil
								elseif nHistoryPos ~= nil then
										nHistoryPos = nHistoryPos + 1
								end                                            
						end
										   
						if nHistoryPos then
							sLine = _tHistory[nHistoryPos]
							nPos = string.len( sLine )
						else
							sLine = ""
							nPos = 0
						end
						redraw()
					end
				elseif param == keys.backspace then
						-- Backspace
						if nPos > 0 then
							redraw(" ");
							sLine = string.sub( sLine, 1, nPos - 1 ) .. string.sub( sLine, nPos + 1 )
							nPos = nPos - 1                                
							redraw()
						end
				elseif param == keys.home then
						-- Home
						nPos = 0
						redraw()               
				elseif param == keys.delete then
						if nPos < string.len(sLine) then
							redraw(" ");
							sLine = string.sub( sLine, 1, nPos ) .. string.sub( sLine, nPos + 2 )                          
							redraw()
						end
				elseif param == keys["end"] then
						-- End
						nPos = string.len(sLine)
						redraw()
				end
			end
	end
   
	term.setCursorBlink( false )
	term.setCursorPos( w + 1, sy )
	print()
   
	return sLine
end
function test()
	a=setmetatable({},{__index={b=1,c=function()end},__newindex={},__tostring=function() return'aaa' end})
	repeat
		read(nil,nil,getfenv(),false)
		print()
	until false
end
-- test()