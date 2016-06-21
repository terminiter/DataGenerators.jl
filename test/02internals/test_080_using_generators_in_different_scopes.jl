@generator GenOutsideModule begin
    start() = choose(Int, 1, 10)
end

module GenDefinedInModuleThatIncludesDataGenerators
    using DataGenerators

    @generator TestGen begin
        start() = choose(Int, 1, 5)
    end

    function generate_in_a_function()
        gen(TestGen())
    end
end

#module GenDefinedInModuleWithoutIncludingDataGenerators
#  DataGenerators.@generator TestGen begin
#    start() = choose(Float64, 0.0, 5.0)
#  end
#end

@testset "generator defined outside of a module" begin
    @testset "use generator defined outside module" for i in 1:NumReps 
        g = GenOutsideModule()
        @test typeof(g) <: DataGenerators.Generator
        @test typeof(gen(g)) <: Integer
    end
end

@testset "generator defined in a module" begin
    # This fail on the gen(g) line. Skipping until we fix.
    @testset skip=true "use Int generator (defined in module which includes DataGenerators. outside of module" begin
        g = GenDefinedInModuleThatIncludesDataGenerators.TestGen()
        @test typeof(g) <: DataGenerators.Generator
        d = gen(g)
        @test typeof(d) <: Int
    end

    # This also fails. Skipping until we fix.
    @testset skip=true "use Int generator from function internal to a module" begin
        d = GenDefinedInModuleThatIncludesDataGenerators.generate_in_a_function()
        @test typeof(d) <: Int
    end
end