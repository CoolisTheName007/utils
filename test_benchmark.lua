---This is a series of tests made with the benchmark module
--Test 1
b=require'utils.benchmark'


do
	local s='array'
	function a()
		local r='array'==s
	end
end
do
	local n=1
	function d()
		local r=1==n
	end
end
b.BenchTable({a=a,d=d},3000000)
b.Results()

--a is 1.5 time faster

--Test 2
-- b=require'utils.benchmark'
-- function a()
	-- local c=os.clock()
-- end
-- b.BenchTable({a=a},500000)
-- b.Results()