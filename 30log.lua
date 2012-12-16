--[[
	Copyright (c) 2012 Roland Yonaba

	Permission is hereby granted, free of charge, to any person obtaining a
	copy of this software and associated documentation files (the
	"Software"), to deal in the Software without restriction, including
	without limitation the rights to use, copy, modify, merge, publish,
	distribute, sublicense, and/or sell copies of the Software, and to
	permit persons to whom the Software is furnished to do so, subject to
	the following conditions:

	The above copyright notice and this permission notice shall be included
	in all copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
	OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
	MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
	IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
	CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
	TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
	SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
--]]
--[[
http://yonaba.github.com/30log/ 
example:
-- The base class "Window"
Window = class { width = 100, height = 100, x = 10, y = 10}
function Window:__init(x,y,width,height)
  self.x,self.y = x,y
  self.width,self.height = width,height
end

function Window:set(x,y)
  self.x, self.y = x, y
end

-- A derived class named "Frame"
Frame = Window:extends { color = 'black' }
function Frame:__init(x,y,width,height,color)
  -- Calling the superclass constructor
  self.super.__init(self,x,y,width,height)
  -- Setting the extra class member
  self.color = color
end

-- Overloading Window:set()
function Frame:set(x,y)
  self.x = x - self.width/2
  self.y = y - self.height/2
end

-- A appFrame from "Frame" class
appFrame = Frame(100,100,800,600,'red')
print(appFrame.x,appFrame.y) --> 100, 100

appFrame:set(400,400)
print(appFrame.x,appFrame.y) --> 0, 100

appFrame.super.set(appFrame,400,300)
print(appFrame.x,appFrame.y) --> 400, 300]]

local type, pairs, setmetatable = type, pairs, setmetatable

local function instantiate(self,...)
  local instance = setmetatable({},self)
  if self.__init then self.__init(instance, ...) end
  return instance
end

local function extends(self,extra_params)
  local heirClass = class(extra_params)
  heirClass.__index, heirClass.super = heirClass, self
  return setmetatable(heirClass,self)
end

local baseMt = {__call = function (self,...) return self:new(...) end}
class = function(members)
  local c = members and deepcopy(members) or {}
  c.new, c.extends, c.__index, c.__call = instantiate, extends, c, baseMt.__call
  return setmetatable(c,baseMt)
end

return class