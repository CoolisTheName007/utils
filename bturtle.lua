os.loadAPI('APIS/main')
vc=load.package('vector3D')
function sign(num)
	return (not num or num==0) and 0 or num>0 and 1 or -1
end 

up={name="up", dig=turtle.digUp, move=turtle.up, detect=turtle.detectUp, place=turtle.placeUp,compare=turtle.compareUp, drop=turtle.dropUp,}
forward={name="forward", dig=turtle.dig, move=turtle.forward, detect=turtle.detect, place=turtle.place,compare=turtle.compare, drop=turtle.drop,}
down={name="down",dig=turtle.digDown, move=turtle.down, detect=turtle.detectDown, place=turtle.placeDown,compare=turtle.compareDown, drop=turtle.dropDown,}

forward.at =  function()
	at.x=at.x+d.x
	at.z=at.z+d.z
end

up.at = function()
	at.y=at.y+1
end
 
down.at = function()
	at.y=at.y-1
end

function shouldDig(block)
	return false
	--[[if (not minn or not maxx) then
		return true
	elseif pervar.read(Namespace,'state')~=0 then
	return true
	else
	return block.x>=minn.x and block.x<=maxx.x and block.y>=minn.y and block.y<=maxx.y and block.z>=minn.z and block.z<=maxx.z
	end]]
end
 
function left()
		turtle.turnLeft()
		d.x, d.z = -d.z, d.x
		pervar.update(Namespace, "d", d )
end
 
function right()
		turtle.turnRight()
		d.x, d.z = d.z, -d.x
		pervar.update(Namespace, "d", d )
end

function turn(to)
	local x,z = sign(to.x), sign(to.z)
	if x == d.x and z == d.z then
		return
	elseif (x == -d.x and x~=0) or (z == -d.z and z~=0) then --or?
		left()
		left()
	elseif z ~= 0 then
		if z == -d.x then right() else left() end
	elseif x ~= 0 then
		if x == d.z then right() else left() end
	end	
end

function move(dir)
	if dir.move() then
		dir.at()
		pervar.update(Namespace, "at", at )
		return true
	else
		return false
	end
end
 

 
function dig(dir)
	local result = true
	disposeJunk()
	checkOverflow()
	result = dir.dig()
	return result
end
 
function advance(dir, steps)
	steps = steps or 1
	for step = 1,steps do
		while not move(dir) do
			if dir.detect() then
				if shouldDig() then
					if not dig(dir) then
						print("Un-dig-able obstacle.Trying again and expecting a different result. Not mad, see?")
						sleep(10)
					end
				else
					print("Found obstacle and i'm not supposed to dig it.Help!")
					sleep(10)
				end
			else
				print("Something that I can't detect is blocking my path. Move it!")
				sleep(0.5)
			end
		end
	end
end
 
function goto(to)
	if to.y>at.y then
		advance(up, to.y-at.y)
	elseif to.y<at.y then
		advance(down, at.y-to.y)
	end
	if to.x ~= at.x then
		turn({x=to.x-at.x})
		advance(forward, math.abs(to.x-at.x))
	end 
	if to.z ~= at.z then
		turn({z=to.z-at.z})
		advance(forward, math.abs(to.z-at.z))
	end
end


function str_to_t(s)
	local arg={}
	for argbit in string.gmatch(s, '%a[%d-]*') do
		argletter = string.sub(argbit,1,1)
		argnum = string.sub(argbit,2)
		arg[argletter] = tonumber(argnum)
	end
	return arg
end 


function t_to_crd(arg)
	local n, max, min
	n=vc{x=arg.x or 0,y=arg.y or 0,z=arg.z or 0}
	max = vc{x=(arg.r or 1) - 1, y=(arg.u or 1) - 1, z=(arg.f or 1) - 1}
	min = vc{x=-(arg.l or 1) + 1, y=-(arg.d or 1) + 1, z=-(arg.b or 1) + 1}
	return n+max+min
end

function requestDrop()
	if serverID then
		print('Requesting drop.')
		rednet.send(serverID, 'need_drop')
	end
end
function waitDrop()
	if serverID then
		print('Waiting message.')
		repeat
			senderID, message, distance = rednet.receive()
			print(senderID, message, distance)
		until (senderID==serverID and message=='go')
		print('Moving to drop.')
	end
end
function unlockDrop()
	if serverID then
		print('Unlocking drop point.')
		rednet.send(serverID, 'drop_done')
		print('Drop point unlocked.')
	end
end



function dropLoot(arg)
	util.narg(arg,{
	waitPoint= vc(),
	dropPoint= vc(),
	gotoD = goto,
	gotoW = goto,
	fDrop=drop.default,
	leaveD = goto,
	leaveW = goto,
	serverID = nil,
	})
	print(2)
	local state=pervar.exists(Namespace,'state') and pervar.read(Namespace,'state') or 0
	if serverID then util.open_modem() print('Modem online.') end
	if state==0 then
		print('Drop sequence iniciated')
		local stoppedAt = vc(at)
		pervar.update(Namespace,'stoppedAt',stoppedAt)
		state=1
		pervar.update(Namespace,'state',state)
	end
	if state==1 then
		print('Going to wait point.')
		gotoW(waitPoint)
		state=1.5
		pervar.update(Namespace,'state',state)
		requestDrop()
	end
	if state==1.5 then
		print('Waiting for free drop point.')
		waitDrop()
		state=2
		pervar.update(Namespace,'state',state)
	end
	if state==2 then
		print('Going to drop point.')
		gotoD(dropPoint)
		state=3
		pervar.update(Namespace,'state',state)
	end
	if state==3 then
		print('Dropping.')
		fDrop()
		print('Done dropping.')
		state=4
		pervar.update(Namespace,'state',state)
	end
	if state==4 then
		print('Going back to wait point.')
		leaveD(waitPoint)
		state=5
		pervar.update(Namespace,'state',state)
		unlockDrop()
	end
	if state==5 then
		print('Resuming position.')
		leaveW(pervar.read(Namespace,'stoppedAt'))
		state=0
		pervar.update(Namespace,'state',state)
		pervar.delete(Namespace,'stoppedAt')
	end
	print('Drop sequence complete')
	if serverID then util.close_modem() print('Modem offline.') end
	return true
end

function isFull(set)
	return	getItemCount(default_set.n)~=0
end

function checkOverflow()
	if isFull() then
		if pervar.read(Namespace,'state')==0 then
			print('Need to drop.')
			dropLoot()
		end
	end
end

function designate(n, type)
	print("Designate "..n.." as "..type)
	if not slot[n] then slot[n]={} end
	if not slot[type] then slot[type]={} end 
	slot[n].designation = type
	table.insert(slot[type],n)
	pervar.update(Namespace,'slot',slot)
end
default_set={1,2,3,4,5,6,7,8,9}
default_set.n=#default_set
drop={}
drop.ground = function (arg)
	util.narg(arg,{
	set = default_set,
	min = 0,
	max = 0,
	dir = forward,
	})
	for i,n in ipairs(set) do
		turtle.select(n)
		if turtle.getItemCount(n) >max then
			dir.drop(turtle.getItemCount(n)-min)
		end
	end
	turtle.select(slot.normal[1] or 1)
end
drop.RP2 = function(arg)
	util.narg(arg,{
	n = default_set.n,
	wait = false,
	signal= util.flare,
	})
	for i=1,n do
		while turtle.getItemCount(i)>0 do
			signal()
			if not wait then
				break
			end
		end
	end
end
drop.default=drop.ground

function getCount(set)
	set=set or default_set
	local r=0
	for i,n in ipairs(set) do 
		r=r+turtle.getItemCount(n)
	end
	return r
end


load.API('pervar')

env=getfenv()
Namespace='bturtle'
default={
at = vc(),
d = vc(0,0,1),
slot={junk={},normal={}},
}
function reload()
	for i,v in pairs(default) do
		if pervar.exists(Namespace,i) then
			if i=='at' or i=='d' then
				env[i]=vc(v)
			else
				env[i]=pervar.read(Namespace,i)
			end
		else
			env[i]=v
			pervar.update(Namespace,i,v)
		end
	end
end
reload()
--[['arg={...}'
arg=arg or {}
local command=arg[1]
local commands = {
		back = function() turn(vc{z=-1}) end,
		right = function() turn(vc{x=1}) end,
		left = function() turn(vc{x=-1}) end,
		front = function() turn(vc{z=1}) end,
	}
if commands[command] then
	commands[command]()
	return
end
arg=str_to_t(arg[1] or '')
if arg.x or arg.y or arg.z then
	pervar.update(Namespace,'state',1)
	arg=t_to_crd(arg)
	print('Destination:'..crd_to_str(arg))
	turn(arg)
	goto(arg)
	return
end
]]
return env