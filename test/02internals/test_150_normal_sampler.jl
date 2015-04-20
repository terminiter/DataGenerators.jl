include("sampler_test_utils.jl")

describe("Normal Sampler") do

	describe("default construction") do

		s = GodelTest.NormalSampler()

		test("numparams and paramranges") do
			@check GodelTest.numparams(s) == 2
			@check GodelTest.paramranges(s) == [(-realmax(Float64), realmax(Float64)), (0.0, realmax(Float64))]
		end
	
		test("default params") do
			@check GodelTest.getparams(s) == [0.0, 1.0]
			@check isconsistentnormal(s, GodelTest.getparams(s))
		end
	
		@repeat test("default sampling") do
			x, trace = GodelTest.sample(s, (0,1))
			@check typeof(x) <: Float64
			@mcheck_that_sometimes x < -1.0
			@mcheck_that_sometimes -1.0 <= x < 0.0
			@mcheck_that_sometimes 0.0 < x <= 1.0
			@mcheck_that_sometimes 1.0 < x
		end

	end
	
	describe("non-default construction") do

		s = GodelTest.NormalSampler([-949.88, 123.4])
		
		test("constructor with params") do
			@check GodelTest.getparams(s) == [-949.88, 123.4]
			@check isconsistentnormal(s, GodelTest.getparams(s))
		end
		
	end
	
	describe("parameter setting") do
		
		s = GodelTest.NormalSampler()
		prs = GodelTest.paramranges(s)
		midparams = map(pr->robustmidpoint(pr[1],pr[2]), prs)

		test("setparams with wrong number of parameters") do
			@check_throws GodelTest.setparams(s, midparams[1:end-1])
			@check_throws GodelTest.setparams(s, [midparams, 0.5])
		end

		test("setparams boundary values") do
			for pidx = 1:length(prs)
				pr = prs[pidx]
				params = copy(midparams)
				params[pidx] = pr[1] 
				GodelTest.setparams(s, params)
				@check isconsistentnormal(s, params)
				params[pidx] = prevfloat(pr[1])
				@check_throws GodelTest.setparams(s, params)
				params[pidx] = pr[2] 
				GodelTest.setparams(s, params)
				@check isconsistentnormal(s, params)
				params[pidx] = nextfloat(pr[2])
				@check_throws GodelTest.setparams(s, params)
			end
		end

		test("setparams handles sigma=0") do
			params = [87.4, 0.0]
			GodelTest.setparams(s, params)
			@check isconsistentnormal(s, params)
		end

		@repeat test("setparams with random parameters") do
			params = map(pr->robustmidpoint(pr[1],pr[2])+(2.0*rand()-1.0)*(pr[2]-robustmidpoint(pr[1],pr[2])), prs)
			# convulated expression involving middle to avoid overflow to Inf
			GodelTest.setparams(s, params)
			@check isconsistentnormal(s, params)
		end

		@repeat test("setparams with realistic random parameters") do
			params = [rand() * 2e6 - 1e6, rand() * 1e3]
			GodelTest.setparams(s, params)
			@check isconsistentnormal(s, params)
		end

	end
	
end