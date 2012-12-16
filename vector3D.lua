--[[
Advanced Vector API by Tomass1996
 
Vector 'Object' Functions And Fields:
  vector.x                              -- Vectors X component
  vector.y                              -- Vectors Y component
  vector.z                              -- Vectors Z component
  vector:add(otherVector)               -- Component-wise addition
  vector:scalarAdd(n)                   -- Scalar addition
  vector:subtract(otherVector)          -- Component-wise subtraction
  vector:scalarSubtract(n)              -- Scalar subtraction
  vector:multiply(otherVector)          -- Component-wise multiplication
  vector:scalarMultiply(n)              -- Scalar multiplication
  vector:divide(otherVector)            -- Component-wise division
  vector:scalarDivide(n)                -- Scalar division
  vector:length()                       -- Get the length of the vector
  vector:lengthSq()                     -- Get the length ^ 2 of the vector
  vector:distance(otherVector)          -- Get the distance away from a vector
  vector:distanceSq(otherVector)        -- Get the distance away from a vector, squared
  vector:normalize()                    -- Get the normalized vector
  vector:dot(otherVector)               -- Get the dot product of vector and otherVector
  vector:cross(otherVector)             -- Get the cross product of vector and otherVector
  vector:containedWithin(minVec, maxVec)-- Check to see if vector is contained within minVec and maxVec
  vector:clampX(min, max)               -- Clamp the X component
  vector:clampY(min, max)               -- Clamp the Y component
  vector:clampZ(min, max)               -- Clamp the Z component
  vector:floor()                        -- Rounds all components down
  vector:ceil()                         -- Rounds all components up
  vector:round()                        -- Rounds all components to the closest integer
  vector:absolute()                     -- Vector with absolute values of components
  vector:isCollinearWith(otherVector)   -- Checks to see if vector is collinear with otherVector
  vector:getIntermediateWithX(other, x) -- New vector with given x value along the line between vector and other, or nil if not possible
  vector:getIntermediateWithY(other, y) -- New vector with given y value along the line between vector and other, or nil if not possible
  vector:getIntermediateWithZ(other, z) -- New vector with given z value along the line between vector and other, or nil if not possible
  vector:rotateAroundX(angle)           -- Rotates vector around the x axis by the specified angle(radians)
  vector:rotateAroundY(angle)           -- Rotates vector around the y axis by the specified angle(radians)
  vector:rotateAroundZ(angle)           -- Rotates vector around the z axis by the specified angle(radians)
  vector:clone()                        -- Returns a new vector with same component values as vector
  vector:equals(otherVector)            -- Checks to see if vector and otherVector are equal
  vector:tostring()                     -- Returns the string representation of vector "(x, y, z)"
 
Vector 'Object' Metatable Overrides:    -- [x, y, z] represents a vector object in these examples, not irl
  To String             -- tostring will get the string representation
                            ie. tostring([1, 2, 3])     -->     "(1, 2, 3)"
  Unary Minus           -- Using unary minus on a vector will result in the negative of vector
                            ie. -[1, -2, 3]             -->     [-1, 2, -3]
  Addition              -- Can add two vectors or vector and number with +
                            ie. [1, 2, 3] + [4, 5, 6]   -->     [5, 7, 9]
                                [1, 2, 3] + 3           -->     [4, 5, 6]
  Subtraction           -- Can subtract two vectors or vector and number with -
                            ie. [4, 5, 6] - [1, 2, 3]   -->     [3, 3, 3]
                                [4, 5, 6] - 3           -->     [1, 2, 3]
  Multiplication        -- Can multiply two vectors or vector and number with *
                            ie. [1, 2, 3] * [4, 5, 6]   -->     [4, 10, 18]
                                [1, 2, 3] * 3           -->     [3, 6, 9]
  Division              -- Can divide two vectors or vector and number with /
                            ie. [4, 10, 18] / [1, 2, 3] -->     [4, 5, 6]
                                [3, 6, 9] / 3           -->     [1, 2, 3]
  Equality              -- Can check if two vectors are the same with ==
                            ie. [4, 5, 6] == [4, 5, 6]  -->     true
                                [4, 5, 6] == [4, 99, 6] -->     false
 
Vector API functions:
  Vector.getMinimum(v1, v2)             -- Gets the minimum components of two vectors
  Vector.getMaximum(v1, v2)             -- Gets the maximum components of two vectors
  Vector.getMidpoint(v1, v2)            -- Gets the midpoint of two vectors
  Vector.isVector(v)                    -- Checks whether v is a vector created by this api
  Vector.new(x, y, z)                   -- Creates a new vector object with the component values
--]]
vector3D={} 
new = function() end -- Forward declaration
isVector = function() end -- Mo' forward declaration
local getType = function() end -- Mo' forward declaration
 
local vector = {
  add = function(self, v)
    return new(
      self.x + v.x,
      self.y + v.y,
      self.z + v.z
    )
  end,
  scalarAdd = function(self, n)
    return new(
      self.x + n,
      self.y + n,
      self.z + n
    )
  end,
  subtract = function(self, v)
    return new(
      self.x - v.x,
      self.y - v.y,
      self.z - v.z
    )
  end,
  scalarSubtract = function(self, n)
    return new(
      self.x - n,
      self.y - n,
      self.z - n
    )
  end,
  multiply = function(self, v)
    return new(
      self.x * v.x,
      self.y * v.y,
      self.z * v.z
    )
  end,
  scalarMultiply = function(self, n)
    return new(
      self.x * n,
      self.y * n,
      self.z * n
    )
  end,
  divide = function(self, o)
    return new(
      self.x / o.x,
      self.y / o.y,
      self.z / o.z
    )
  end,
  scalarDivide = function(self, n)
    return new(
      self.x / n,
      self.y / n,
      self.z / n
    )
  end,
  length = function(self)
    return math.sqrt(
      self.x * self.x
      + self.y * self.y
      + self.z * self.z
    )
  end,
  lengthSq = function(self)
    return (
      self.x * self.x
      + self.y * self.y
      + self.z * self.z
    )
  end,
  distance = function(self, o)
    return math.sqrt(
      math.pow(o.x - self.x, 2)
      + math.pow(o.y - self.y, 2)
      + math.pow(o.z - self.z, 2)
    )
  end,
  distanceSq = function(self, o)
    return (
      math.pow(o.x - self.x, 2)
      + math.pow(o.y - self.y, 2)
      + math.pow(o.z - self.z, 2)
    )
  end,
  normalize = function(self)
    return self:scalarDivide(self:length())
  end,
  dot = function(self, o)
    return (
      self.x * o.x
      + self.y * o.y
      + self.z * o.z
    )
  end,
  cross = function(self, o)
    return new(
      self.y * o.z - self.z * o.y,
      self.z * o.x - self.x * o.z,
      self.x * o.y - self.y * o.x
    )
  end,
  containedWithin = function(self, min, max)
    return (
      self.x >= min.x and self.x <= max.x
      and self.y >= min.y and self.y <= max.y
      and self.z >= min.z and self.z <= max.z
    )
  end,
  clampX = function(self, min, max)
    return new(
      math.max(min, math.min(max, self.x)),
      self.y,
      self.z
    )
  end,
  clampY = function(self, min, max)
    return new(
      self.x,
      math.max(min, math.min(max, self.y)),
      self.z
    )
  end,
  clampZ = function(self, min, max)
    return new(
      self.x,
      self.y,
      math.max(min, math.min(max, self.z))
    )
  end,
  floor = function(self)
    return new(
      math.floor(self.x),
      math.floor(self.y),
      math.floor(self.z)
    )
  end,
  ceil = function(self)
    return new(
      math.ceil(self.x),
      math.ceil(self.y),
      math.ceil(self.z)
    )
  end,
  round = function(self)
    return new(
      math.floor(self.x + 0.5),
      math.floor(self.y + 0.5),
      math.floor(self.z + 0.5)
    )
  end,
  absolute = function(self)
    return new(
      math.abs(self.x),
      math.abs(self.y),
      math.abs(self.z)
    )
  end,
  isCollinearWith = function(self, o)
    if self.x == 0 and self.y == 0 and self.z == 0 then
      return true
    end
    local otherX, otherY, otherZ = o.x, o.y, o.z
    if otherX == 0 and otherY == 0 and otherZ == 0 then
      return true
    end
    if (self.x == 0) ~= (otherX == 0) then return false end
    if (self.y == 0) ~= (otherY == 0) then return false end
    if (self.z == 0) ~= (otherZ == 0) then return false end
    local quotientX = otherX / self.x
    if quotientX == quotientX then
      return o:equals(self:scalarMultiply(quotientX))
    end
    local quotientY = otherY / self.y
    if quotientY == quotientY then
      return o:equals(self:scalarMultiply(quotientY))
    end
    local quotientZ = otherZ / self.z
    if quotientZ == quotientZ then
      return o:equals(self:scalarMultiply(quotientZ))
    end
  end,
  getIntermediateWithX = function(self, o, v)
    local vX = o.x - self.x
    local vY = o.y - self.y
    local vZ = o.z - self.z
    if vX * vX < 1.0000000116860974e-7 then
      return nil
    else
      local nMul = (v - self.x) / vX
      return (
        (nMul >= 0 and nMul <= 1)
        and new(
          self.x + vX * nMul,
          self.y + vY * nMul,
          self.z + vZ * nMul
        )
        or nil
      )
    end
  end,
  getIntermediateWithY = function(self, o, v)
    local vX = o.x - self.x
    local vY = o.y - self.y
    local vZ = o.z - self.z
    if vY * vY < 1.0000000116860974e-7 then
      return nil
    else
      local nMul = (v - self.y) / vY
      return (
        (nMul >= 0 and nMul <= 1)
        and new(
          self.x + vX * nMul,
          self.y + vY * nMul,
          self.z + vZ * nMul
        )
        or nil
      )
    end
  end,
  getIntermediateWithZ = function(self, o, v)
    local vX = o.x - self.x
    local vY = o.y - self.y
    local vZ = o.z - self.z
    if vZ * vZ < 1.0000000116860974e-7 then
      return nil
    else
      local nMul = (v - self.z) / vZ
      return (
        (nMul >= 0 and nMul <= 1)
        and new(
          self.x + vX * nMul,
          self.y + vY * nMul,
          self.z + vZ * nMul
        )
        or nil
      )
    end
  end,
  rotateAroundX = function(self, n)
    local c, s = math.cos(n), math.sin(n)
    return new(
      self.x,
      self.y * c + self.z * s,
      self.z * c - self.y * s
    )
  end,
  rotateAroundY = function(self, n)
    local c, s = math.cos(n), math.sin(n)
    return new(
      self.x * c + self.z * s,
      self.y,
      self.z * c - self.x * s
    )
  end,
  rotateAroundZ = function(self, n)
    local c, s = math.cos(n), math.sin(n)
    return new(
      self.x * c + self.y * s,
      self.y * c - self.x * s,
      self.z
    )
  end,
  clone = function(self)
    return new(
      self.x,
      self.y,
      self.z
    )
  end,
  equals = function(self, o)
    if not isVector(self) or not isVector(o) then return false end
    return (
      o.x == self.x
      and o.y == self.y
      and o.z == self.z
    )
  end,
  tostring = function(self)
    return "("..self.x..", "..self.y..", "..self.z..")"
  end
}
 
local vmetatable = {
  __index = vector,
  __tostring = vector.tostring,
  __unm = function(v) return v:scalarMultiply(-1) end,
  __add = function(a, b)
    if type(b) == "number" and isVector(a) then
      return a:scalarAdd(b)
    elseif type(a) == "number" and isVector(b) then
      return b:scalarAdd(a)
    elseif isVector(a) and isVector(b) then
      return a:add(b)
    else
      error("Attempt to perform vector addition on <"..getType(a).."> and <"..getType(b)..">")
    end
  end,
  __sub = function(a, b)
    if type(b) == "number" and isVector(a) then
      return a:scalarSubtract(b)
    elseif type(a) == "number" and isVector(b) then
      return b:scalarSubtract(a)
    elseif isVector(a) and isVector(b) then
      return a:subtract(b)
    else
      error("Attempt to perform vector subtraction on <"..getType(a).."> and <"..getType(b)..">")
    end
  end,
  __mul = function(a, b)
    if type(b) == "number" and isVector(a) then
      return a:scalarMultiply(b)
    elseif type(a) == "number" and isVector(b) then
      return b:scalarMultiply(a)
    elseif isVector(a) and isVector(b) then
      return a:multiply(b)
    else
      error("Attempt to perform vector multiplication on <"..getType(a).."> and <"..getType(b)..">")
    end
  end,
  __div = function(a, b)
    if type(b) == "number" and isVector(a) then
      return a:scalarDivide(b)
    elseif type(a) == "number" and isVector(b) then
      return b:scalarDivide(a)
    elseif isVector(a) and isVector(b) then
      return a:divide(b)
    else
      error("Attempt to perform vector division on <"..getType(a).."> and <"..getType(b)..">")
    end
  end,
  __eq = vector.equals,
}
 
function vector3D.getMinimum(v1, v2)
  return new(
    math.min(v1.x, v2.x),
    math.min(v1.y, v2.y),
    math.min(v1.z, v2.z)
  )
end
 
vector3D.getMaximum = function(v1, v2)
  return new(
    math.max(v1.x, v2.x),
    math.max(v1.y, v2.y),
    math.max(v1.z, v2.z)
  )
end
 
vector3D.getMidpoint= function(v1, v2)
  return new(
    (v1.x + v2.x) / 2,
    (v1.y + v2.y) / 2,
    (v1.z + v2.z) / 2
  )
end
 
getType = function(v)
  if isVector(v) then
    return "vector"
  else
    return type(v)
  end
end

vector3D.getType=getType
 
isVector = function(v)
  return getmetatable(v) == vmetatable
end
vector3D.isVector=isVector
 
new = function(t,y,z)
  local v
  if type(t)=='table' then
		v= {
			['x'] = t.x or t[1] or 0,
			['y'] = t.y or t[2] or 0,
			['z'] = t.z or t[3] or 0
		}
	else
		v={
			['x'] = t or 0,
			['y'] = y or 0,
			['z'] = z or 0
		}
	end
  setmetatable(v, vmetatable)
  return v
end
setmetatable(vector3D,{__call=function (t,...) return new(...) end,__tostring= function () return 'Class Vector3D' end})
return vector3D