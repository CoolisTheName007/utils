local pairs=pairs
local print=print

Linked=setmetatable({},{
__call=function(_,...) return _.new(...) end,
__tostring=function() return 'Class Linked' end,
})

function Linked.new(t)
	self=setmetatable({},{
		__index=Linked,
		__tostring=Linked.__tostring
		})
	self.r,self.l={[0]=-1},{[-1]=0}
	if t then self:append_r(t) end
	return self
end

function Linked._insert(t,val,i_l,i_r)
	if t.r[val] then return end
	i_l,i_r=i_l or 0,i_r or -1
	--handle left				right
	t.r[i_l],	t.l[val],	t.r[val],	t.l[i_r]
	=	val,			i_l,		i_r,		val
end

function Linked.insert_l(t,val,i_l)
	return Linked._insert(t,val,i_l,t.r[i_l or 0])
end

function Linked.insert_r(t,val,i_r)
	return Linked._insert(t,val,t.l[i_r or -1],i_r)
end

function Linked.remove(t,val)
	val=val or t.r[0]
	if t.r[val] then t.r[t.l[val]],t.l[t.r[val]],t.r[val],t.l[val]=t.r[val],t.l[val],nil,nil end
	if val==-1 then val=nil end
	return val,t.r[val]
end

function Linked.next_r(t,ind)
	local _=t.r[ind or 0]
	if _~=-1 then return _ end
end

function Linked.next_l(t,ind)
	local _=t.r[ind or -1]
	if _~=0 then return _ end
end


function Linked.__tostring(t)
	s={}
	for i in self.next_r,t,nil do
		table.insert(s,tostring(i))
	end
	return 'Linked instance:'..table.concat(s,'<>')
end

function Linked:append_r(t)
	local old
	for i,v in ipairs(t) do
		self:insert_r(v,old)
		-- print(v,old)
		-- read()
		old=v
	end
end

function Linked:has(val)
	return self.r[val]~=nil
end

function Linked.test()
	t={'a',3,4}
	l=Linked(t)
	print(l)
	l:remove(3)
	print(l)
	print(l:has(4),l:has(3))
	return l
end

return Linked