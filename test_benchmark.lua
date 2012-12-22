---This is a series of tests made with the benchmark module
b=require'utils.benchmark'
function a()
	local n=math.random()
	c=n-n%0.05
end

function d()
	local n=math.random()
	c=math.ceil(n/0.05)*0.05
end
b.BenchTable({a=a,d=d},500000)
b.Results()

---a is 1.5 time faster