-- opcreatetable.lua
--
-- Creates table preallocated in array and hash sizes.
-- Implemented in pure Lua.
--
-- Warning: This code may be somewhat fragile since it depends on
-- the Lua 5.1 bytecode format and little-endian byte order.
--
-- This code has not been well tested.  Please review prior to using
-- in production.
--
-- (c) 2009 David Manura. Licensed under the same terms as Lua (MIT license).

local M = {}

local loadstring = loadstring
local assert = assert
local string = string
local string_dump = string.dump
local string_char = string.char

-- Encodes integer for NEWTABLE opcode. Based on lobject.c:luaO_int2fb.
local xmax = 15*2^30
local function int2fb(x)
  assert(x >= 0 and x <= xmax)
  local e = 0
  while x >= 16 do
    x = (x+1)
    local b = x % 2
    x = (x-b) / 2
    e = e + 1
  end
  if x < 8 then
    return x
  else
    return (e+1) * 8 + (x - 8)
  end
end

-- Packs and unpacks 4-byte little-endian unsigned int.
local function pack_int4(x1,x2,x3,x4)
  return ((x4*256 + x3)*256 + x2)*256 + x1
end
local function unpack_int4(x)
  local x1 = x % 256; x = (x - x1) / 256
  local x2 = x % 256; x = (x - x2) / 256
  local x3 = x % 256; x = (x - x3) / 256
  local x4 = x
  return x1,x2,x3,x4
end

-- Packs and unpacks iABC type instruction.
local function unpack_iABC(x)
  local instopid = x % 64;  x = (x - instopid) / 64
  local insta    = x % 256; x = (x - insta)    / 256
  local instc    = x % 512; x = (x - instc)    / 512
  local instb    = x
  return instopid, insta, instb, instc
end
local function pack_iABC(instopid, insta, instb, instc)
  return ((instb * 512 + instc) * 256 + insta) * 64 + instopid
end


-- Returns a function that when called creates and returns a new table.
-- The table has array size asize and hash size hsize (both default to 0).
-- Calling this function may be slow and you may want to cache the
-- returned function.  Calling the returned function should be fast.
local code
local pos
local insta
local function new_table_builder(asize, hsize)
  asize = asize or 0
  hsize = hsize or 0
  if not code then
    -- See "A No-Frills Introduction to Lua 5.1 VM Instructions"
    -- by Kein-Hong Man for details on the bytecode format.

    code = string_dump(function() return {} end)

    -- skip headers
    local int_size = code:byte(8)
    local size_t_size = code:byte(9)
    local instruction_size = code:byte(10)
    local endian = code:byte(7)
    assert(size_t_size == 4)
    assert(instruction_size == 4)
    assert(endian == 1) -- little endian
    local source_size =
      pack_int4(code:byte(13), code:byte(14), code:byte(15), code:byte(16))
    pos = 1 + 12           -- chunk header
            + size_t_size  -- string size
            + source_size  -- string data
            + 2 * int_size + 4 -- rest of function block header
            + 4            -- number of instructions

    -- read first instruction (NEWTABLE)
    local a1 = code:byte(pos)
    local a2 = code:byte(pos+1)
    local a3 = code:byte(pos+2)
    local a4 = code:byte(pos+3)
    local inst = pack_int4(a1,a2,a3,a4)

    -- parse instruction
    local instopid, instc, instb
    instopid, insta, instb, instc = unpack_iABC(inst)
    assert(instopid == 10)
    assert(instb == 0)
    assert(instc == 0)
  end

  -- build new instruction
  local instopid = 10
  local instb = int2fb(asize)
  local instc = int2fb(hsize)
  local inst = pack_iABC(instopid, insta, instb, instc)

  -- encode new instruction into code.
  local inst1,inst2,inst3,inst4 = unpack_int4(inst)
  local code2 =
    code:sub(1,pos-1)..string_char(inst1,inst2,inst3,inst4)..code:sub(pos+4)
  local f2 = assert(loadstring(code2))

  return f2
end
M.new_table_builder = new_table_builder

return M