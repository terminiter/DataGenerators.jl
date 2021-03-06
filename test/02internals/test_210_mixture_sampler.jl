include("sampler_test_utils.jl")

describe("Mixture Sampler") do

	describe("construction") do
		
		subsA = DataGenerators.BernoulliSampler()
		subsB = DataGenerators.DiscreteUniformSampler([7.0,9.0])
		s = DataGenerators.MixtureSampler(subsA,subsB)

		test("numparams and paramranges") do
			@check DataGenerators.numparams(s) == 2 + DataGenerators.numparams(subsA) + DataGenerators.numparams(subsB)
			prs = DataGenerators.paramranges(s)
			@check typeof(prs) <: Vector{(Float64,Float64)} 
			@check prs == [(0.0,1.0), (0.0,1.0), DataGenerators.paramranges(subsA), DataGenerators.paramranges(subsB)]
		end
	
		test("default params") do
			@check DataGenerators.getparams(s) == [0.5, 0.5, DataGenerators.getparams(subsA), DataGenerators.getparams(subsB)]
		end
	
		@repeat test("default sampling") do
			x, trace = DataGenerators.sample(s, (0,1))
			@check typeof(x) <: Int
			@mcheck_values_are x [0,1,7,8,9]
		end
		
	end
	
	describe("parameter setting") do
	
		subsA = DataGenerators.BernoulliSampler()
		subsB = DataGenerators.DiscreteUniformSampler()
		subsC = DataGenerators.GeometricSampler()
		s = DataGenerators.MixtureSampler(subsA,subsB,subsC)
		prs = DataGenerators.paramranges(s)
		midparams = map(pr->robustmidpoint(pr[1],pr[2]), prs)

		test("setparams with wrong number of parameters") do
			@check_throws DataGenerators.setparams(s, midparams[1:end-1])
			@check_throws DataGenerators.setparams(s, [midparams, 0.5])
		end

		test("setparams sets parameters of subsamplers") do
			params = [0.1, 0.2, 0.7, 0.4, 1.0, 6.0, 0.1]
			DataGenerators.setparams(s, params)
			@check DataGenerators.getparams(subsA) == [0.4]
			@check DataGenerators.getparams(subsB) == [1.0, 6.0]
			@check DataGenerators.getparams(subsC) == [0.1]
		end

		test("setparams sets parameters of internal choice") do
			params = [1.0, 0.0, 0.0, 0.4, 1.0, 6.0, 0.1]
			DataGenerators.setparams(s, params)
			@check isconsistentbernoulli(s, params[4:4])
			params = [0.0, 1.0, 0.0, 0.4, 1.0, 6.0, 0.1]
			DataGenerators.setparams(s, params)
			@check isconsistentdiscreteuniform(s, params[5:6])
			params = [0.0, 0.0, 1.0, 0.4, 1.0, 6.0, 0.1]
			DataGenerators.setparams(s, params)
			@check isconsistentgeometric(s, params[7:7])
		end

		@repeat test("setparams with random parameters") do
			params = map(pr->robustmidpoint(pr[1],pr[2])+(2.0*rand()-1.0)*(pr[2]-robustmidpoint(pr[1],pr[2])), prs)
			# convulated expression involving middle to avoid overflow to Inf
			DataGenerators.setparams(s, params)
		end
		
	end
	
	describe("estimate parameters") do
		
		test("estimates parameters of all subsamplers as well as internal selection distribution") do		

			subs1A = DataGenerators.BernoulliSampler()
			subs1B = DataGenerators.DiscreteUniformSampler()
			s1 = DataGenerators.MixtureSampler(subs1A,subs1B)
			params = [0.6, 0.4, 0.7, 10.0, 13.0]
			DataGenerators.setparams(s1, params)

			subs2A = DataGenerators.BernoulliSampler()
			subs2B = DataGenerators.DiscreteUniformSampler()
			s2 = DataGenerators.MixtureSampler(subs2A,subs2B)
			otherparams = [0.3, 0.7, 0.3, -40.0, -27.0]
			DataGenerators.setparams(s2, otherparams)

			traces = map(1:100) do i
				x, trace = DataGenerators.sample(s1, (0,1))
				trace
			end

			estimateparams(s2, traces)
			
			@check isconsistentbernoulli(subs2A, params[3:3])
			@check isconsistentdiscreteuniform(subs2B, params[4:5])
			# don't want to access internal selection distribution directly, so recreate on the assumption it is categorical
			s2params = DataGenerators.getparams(s2)
			s2internal = DataGenerators.CategoricalSampler(2, s2params[1:2])
			@check isconsistentcategorical(s2internal, params[1:2])

		end
		
	end
		
end
