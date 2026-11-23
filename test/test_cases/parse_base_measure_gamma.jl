# parse_base_measure must load a base sample whose atlas stores a whole-number gamma
# such as 0.0 or 1.0. AtlasIO 0.1.x reads those back as Int, and Measure only accepts
# gamma::Float64, so this used to fail with a MethodError.
@testset "parse_base_measure with whole-number gamma" begin
    AIO = MetropolizedForestRecom.AtlasIO
    for (gamma, weights) in ((0.0, [1.0]), (1.0, [2.0]), (0.5, [0.25]))
        mktempdir() do dir
            path = joinpath(dir, "base_sample.jsonl")
            io = AIO.smartOpen(path, "w")
            header = AIO.AtlasHeader("parse_base_measure test", "2026-11-23T00:00:00",
                                     "Dict{String, Any}", "Dict{String, Any}")
            params = Dict{String,Any}("gamma" => gamma, "energies" => ["get_isoperimetric_score"],
                                      "energy weights" => weights)
            AIO.newAtlas(io, header, params)
            AIO.addMap(io, AIO.Map{Dict{String,Any}}("step1", AIO.Districting(), 1, Dict{String,Any}()))
            close(io)

            m = parse_base_measure(path, small_square_graph)
            @test m.gamma === gamma
            @test m.weights == weights
            @test length(m.scores) == 1
        end
    end
end
