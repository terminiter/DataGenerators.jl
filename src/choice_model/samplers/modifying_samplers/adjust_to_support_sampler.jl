#
# Adjust to Support Sampler
#
# adjust the parameters of the sampler so that values are returned in support
# Only some samplers can be adjusted in this way; for others an error is raised on construction
#

type AdjustToSupportSampler <: ModifyingSampler
	subsampler::Sampler
	function AdjustToSupportSampler(subsampler::Sampler)
		typeof(subsampler) in (UniformSampler, DiscreteUniformSampler,) || error("$(typeof(subsampler)) samplers are not supported by AdjustToSupportSampler")
		new(subsampler)
	end
end

function paramranges(s::AdjustToSupportSampler)
	if typeof(s.subsampler) in (UniformSampler, DiscreteUniformSampler,)
		return Float64[]
	else
		@assert false
	end
end

function getparams(s::AdjustToSupportSampler)
	if typeof(s.subsampler) in (UniformSampler, DiscreteUniformSampler,)
		return (Float64,Float64)[]
	else
		@assert false
	end
end

function setparams(s::AdjustToSupportSampler, params::Vector{Float64})
	length(params) == length(paramranges(s)) || error("expected $(length(pranges)) parameters but got $(length(params))")
	if typeof(s.subsampler) in (UniformSampler, DiscreteUniformSampler,)
		nothing
	else
		@assert false
	end
end

function sample(s::AdjustToSupportSampler, support::(Real,Real))
	if typeof(s.subsampler) in (UniformSampler, DiscreteUniformSampler,)
		setparams(s.subsampler, [float64(support[1]), float64(support[2])])
	else
		@assert false
	end
	sample(s.subsampler, support)
end

