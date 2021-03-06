include("sampler_test_utils.jl")

describe("Geometric Sampler") do

	describe("default construction") do

		s = DataGenerators.GeometricSampler()

		test("numparams and paramranges") do
			@check DataGenerators.numparams(s) == 1
			prs = DataGenerators.paramranges(s)
			@check typeof(prs) <: Vector{(Float64,Float64)} 
			@check prs == [(0.0,1.0)]
		end
	
		test("default params") do
			@check DataGenerators.getparams(s) == [0.5]
			@check isconsistentgeometric(s, DataGenerators.getparams(s))
		end
	
		@repeat test("default sampling") do
			x, trace = DataGenerators.sample(s, (0,1))
			@check typeof(x) <: Int
			@mcheck_values_include x [0,1,2,3]
		end

	end
	
	describe("non-default construction") do

		s = DataGenerators.GeometricSampler([0.3])
		
		test("constructor with params") do
			@check DataGenerators.getparams(s) == [0.3]
			@check isconsistentgeometric(s, DataGenerators.getparams(s))
		end
		
	end
	
	describe("parameter setting") do
		
		s = DataGenerators.GeometricSampler()
		prs = DataGenerators.paramranges(s)
		midparams = map(pr->robustmidpoint(pr[1],pr[2]), prs)

		test("setparams with wrong number of parameters") do
			@check_throws DataGenerators.setparams(s, midparams[1:end-1])
			@check_throws DataGenerators.setparams(s, [midparams, 0.5])
		end

		test("setparams boundary values") do
			for pidx = 1:length(prs)
				pr = prs[pidx]
				params = copy(midparams)
				params[pidx] = pr[1] 
				DataGenerators.setparams(s, params)
				@check isconsistentgeometric(s, params)
				params[pidx] = prevfloat(pr[1])
				@check_throws DataGenerators.setparams(s, params)
				params[pidx] = pr[2] 
				DataGenerators.setparams(s, params)
				@check isconsistentgeometric(s, params)
				params[pidx] = nextfloat(pr[2])
				@check_throws DataGenerators.setparams(s, params)
			end
		end

		test("setparams handles p=0") do
			params = [0.0]
			DataGenerators.setparams(s, params)
			@check isconsistentgeometric(s, params)
		end

		test("setparams handles p=1") do
			params = [1.0]
			DataGenerators.setparams(s, params)
			@check isconsistentgeometric(s, params)
		end

		@repeat test("setparams with random parameters") do
			params = map(pr->robustmidpoint(pr[1],pr[2])+(2.0*rand()-1.0)*(pr[2]-robustmidpoint(pr[1],pr[2])), prs)
			# convulated expression involving middle to avoid overflow to Inf
			DataGenerators.setparams(s, params)
			@check isconsistentgeometric(s, params)
		end

	end
	
	describe("estimate parameters") do
		
		s = DataGenerators.GeometricSampler()
		prs = DataGenerators.paramranges(s)
		otherparams = [0.5]
		
		test("lower bound") do
			params = [0.0]
			s1 = DataGenerators.GeometricSampler(params)
			s2 = DataGenerators.GeometricSampler(otherparams)	
			traces = map(1:100) do i
				x, trace = DataGenerators.sample(s1, (0,1))
				trace
			end
			estimateparams(s2, traces)
			@check isconsistentgeometric(s2, params)
		end

		test("upper bound") do
			params = [1.0]
			s1 = DataGenerators.GeometricSampler(params)
			s2 = DataGenerators.GeometricSampler(otherparams)	
			traces = map(1:100) do i
				x, trace = DataGenerators.sample(s1, (0,1))
				trace
			end
			estimateparams(s2, traces)
			@check isconsistentgeometric(s2, params)
		end

		test("random params") do
			params = map(pr->robustmidpoint(pr[1],pr[2])+(2.0*rand()-1.0)*(pr[2]-robustmidpoint(pr[1],pr[2])), prs)
			# convulated expression involving middle to avoid overflow to Inf
			s1 = DataGenerators.GeometricSampler(params)
			s2 = DataGenerators.GeometricSampler(otherparams)	
			traces = map(1:100) do i
				x, trace = DataGenerators.sample(s1, (0,1))
				trace
			end
			estimateparams(s2, traces)
			@check isconsistentgeometric(s2, params)
		end
		
		test("too few traces") do
			params = [0.2]
			s1 = DataGenerators.GeometricSampler(params)
			s2 = DataGenerators.GeometricSampler(otherparams)	
			traces = map(1:0) do i
				x, trace = DataGenerators.sample(s1, (0,1))
				trace
			end
			@check isconsistentgeometric(s2, otherparams)
		end
		
	end
	
end
