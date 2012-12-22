local type,os,write,tostring,tonumber,string,getmetatable,pairs,table=type,os,write,tostring,tonumber,string,getmetatable,pairs,table
local _stringify
_stringify = function(stack, this, spacing_h, spacing_v, space_n, parsed,max_level,level)
	local this_type = type(this)
	if this_type == "string" then
		stack[#stack+1] = (
				spacing_v ~= "\n" and string.gsub(string.format("%q", this), "\\\n", "\\n")
			or  string.format("%q", this)
		)
	elseif this_type == "boolean" then
		stack[#stack+1] = this and "true" or "false"
	elseif this_type == "number" then
		stack[#stack+1] = tostring(this)
	elseif this_type == "function" then
		local info=tostring(this)
		--for i,v in pairs(getfenv(2)) do
		--	if v==this then info=i break end
		--end
		stack[#stack+1] = "function"
		stack[#stack+1] = ":("
		if true then --not info or info.what == "C" then
			stack[#stack+1] = info--"[C]"
		else
			--[[local param_list = debug.getparams(this)
			for param_i = 1, #param_list do
				stack[#stack+1] = param_list[param_i]
			end]]
		end
		stack[#stack+1] = ")"
	elseif this_type == "table" then
		if parsed[this] or level==max_level then
			stack[#stack+1] = "<"..tostring(this)..">"
		else
			level=level+1
			parsed[this] = true
			stack[#stack+1] = "{"..spacing_v
			for key,val in pairs(this) do
				stack[#stack+1] = string.rep(spacing_h, space_n).."["
				_stringify(stack, key, spacing_h, spacing_v, space_n+1, parsed,max_level,level)
				stack[#stack+1] = "] = "
				_stringify(stack, val, spacing_h, spacing_v, space_n+1, parsed,max_level,level)
				stack[#stack+1] = ","..spacing_v
			end
			stack[#stack+1] = string.rep(spacing_h, space_n-1).."}"
			level=level-1
		end
	elseif this_type == "nil" then
		stack[#stack+1] = "nil"
	else
		stack[#stack+1] = this_type.."<"..tostring(this)..">"
	end
end
local stringify = function(this, docol, spacing_h, spacing_v, preindent,max_level)
	local stack = {}
	_stringify(
		stack,
		this,
		spacing_h or "    ", spacing_v or "\n",
		(tonumber(preindent) or 0)+1,
		{},
		max_level,
		0
	)
	return table.concat(stack)
end
local dprint = function(this,max_level)
	local stack = {}
	_stringify(
		stack,
		this,
		spacing_h or "    ", spacing_v or "\n",
		(tonumber(preindent) or 0)+1,
		{},
		max_level,
		0
	)
	for i=1,#stack do
		write(stack[i])
		os.pullEvent()
	end
	write('\n')
end
M={stringify=stringify,_stringify=_stringify,dprint=dprint}
return M