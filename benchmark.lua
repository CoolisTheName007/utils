--from http://lua-users.org/wiki/BenchmarkModule
---------------------------
--- Benchmark provides a set of functions, which measures and compares execution time of different code fragments
---------------------------
M={}
--module("Benchmark",package.seeall)
local os=os


local bench_results={}
local total_diff=0.0

---------------------------
--- Call a function for several times and measure execution time.
-- @param name (string) literal to identify test in result table
-- @param func (function) function to be benchmarked
-- @param loops (number) how often this function should be called
----------------------------
function M.Bench(name,func,loops,...)
	loops=loops or 100
	local q0=os.clock()
	for i=1,loops do
		if i%10000==0 then
			sleep(0)
		end
		func(...)
	end
	local q1=os.clock()
	local result=bench_results[name] or {count=0,diff=0}
	local diff=(q1-q0)
	result.count=result.count+loops
	result.diff=result.diff+diff
	total_diff=total_diff+diff
	bench_results[name]=result
end

---------------------------
--- Do Benchmark over a table of functions
-- @param functions (table) table of functions to check
-- @param loops (number) how often to call the function (optional, default 100)
---------------------------
function M.BenchTable(functions,loops)
	loops=loops or 100
	for name,func in pairs(functions) do
		M.Bench(name,func,loops)
	end
end

----------------------------
--- Printout benchmark results.
-- @param Output (function) to receive values (optional, default=io.write)
----------------------------
function M.Results(Output)

	--
	-- prepare the output
	--
	Output=Output or io.write
	local function printf(form,...)
		Output(string.format(form,...))
	end

	--
	-- calculate mean values
	-- create a table of names
	--
	local names={}
	local namlen=0
	for name,result in pairs(bench_results) do
		result.mean=result.diff/result.count
--~ 		printf("diff=%8.3g cnt=%d mean=%8.3g\n",result.diff,result.count,result.mean)
		names[#names+1]=name
		if #name>namlen then namlen=#name end
	end

	--
	-- sort table by mean value
	--
	local function comp(na,nb)
		return bench_results[na].mean<bench_results[nb].mean
	end
	table.sort(names,comp)

	--
	-- derive some reasonable output scaling
	--
	local max=bench_results[names[#names]].mean
	local fac,unit=1,"sec"
	if max<0.001 then
		fac,unit=1000000,"µs"
	elseif max<1.0 then
		fac,unit=100,"ms"
	end

	--
	-- create a format string (due "%-*s" is missing in string.format)
	--
	local form=string.gsub("-- %-#s : %8.3f %s = %6d loops/s [%6.2f %%] %5.3f times faster\n","#",tostring(namlen))

	--
	-- now print the result
	--
	printf("-----------------------------------\n")
	printf("-- MAX = %8.3f %s\n",max*fac,unit)
	for i=1,#names do
		local name=names[i]
		result=bench_results[name]
		local ratio=result.mean*100/max
		local times=max/result.mean
		local loops=1/result.mean
		printf(form,name,result.mean*fac,unit,loops,ratio,times)
	end
	printf("-----------------------------------\n")
end

return M