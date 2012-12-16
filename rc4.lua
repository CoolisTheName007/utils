---Taken from http://papymouge.indefero.net/p/snake/source/tree/573011f51d17650f45626388e37abacf92df7532/libs/RC4.lua
--@alias rc4
--half translated from french
--starting to think this might be a terrible implementation, efficiency wise, just by lookint at it, then again, Lua is Lua
--@usage
--code and decode:
--print(rc4.code('Key',rc4.code('Key','Plaintext')))
-->>Plaintext

rc4 = {}

-- Permutation
rc4.permut = function(key)
	local i,j = 0,0
	local cle = {}
	local tempo = 0
	local long = string.len(key)
	local S = {}
	for i = 0, long - 1 do
		cle[i] = string.byte(string.sub(key,i+1,i+1))
	end
	for i = 0, 255 do
		S[i] = i
	end
	for i = 0,255 do
		j = (j+ S[i] + cle[i % long]) % 256
		tempo = S[i]
		S[i] = S[j]
		S[j] = tempo
	end
	return S
end

-- Génération du flot
rc4.code =function(texte,S)
	return rc4.code_raw(texte,S)
end

rc4.code_raw = function(texte,S)
	local i,j = 0,0
	local text = {}
	local maxcara = string.len(texte)
	local code = {}
	local tempo = 0
	local o_chif = 0
	local tResult = {} --changed string concatenation to table concat, much moe efficient
	local cpt = 1
	local S = {}
	for i= 1, maxcara do
		text[i] = string.byte(string.sub(texte,i,i))
	end
	while cpt<maxcara+1 do
		i = (i+1)%256
		j = (j+S[i])%256
		tempo = S[i]
		S[i] = S[j]
		S[j] = tempo
		o_chif = S[(S[i]+S[j])%256]
		tResult[cpt] = string.char(rc4.XOR(o_chif,text[cpt]))
		cpt = cpt+1
	end
	return table.concat(tResult)
end

-- Octet1 XOR Octet2
rc4.XOR = function(octet1, octet2)
	local O1 = {}
	local O2 = {}
	local result = {}
	local i
	O1 = rc4.binaire(octet1)
	O2 = rc4.binaire(octet2)
	for i= 1,8 do
		if(O1[i] == O2[i]) then
			result[i] = 0
		else
			result[i] = 1
		end
	end
	return rc4.dec(result)
end

-- Transformation binaire
rc4.binaire = function(octet)
	local B = {}
	local div = 128
	local i = 1
	while (i < 9) do
		B[i] = math.floor(octet/div)
		if B[i] == 1 then octet = octet-div end
		div = div / 2
		i = i +1
	end
	return B
end

-- Transformation décimale
rc4.dec = function(binaire)
	local i
	local result = 0
	local mul = 1
	for i = 8,1,-1 do
		result = result + (binaire[i]* mul)
		mul = mul *2
	end
	return result
end
return rc4