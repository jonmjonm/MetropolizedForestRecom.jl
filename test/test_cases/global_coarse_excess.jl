@testset "global coarse-node excess constraint" begin
    district_to_nodes = [
        Dict{Tuple{Vararg{String}}, Any}(("0,0",) => Dict{Tuple{Vararg{String}}, Any}()),
        Dict{Tuple{Vararg{String}}, Any}(("0,0",) => Dict{Tuple{Vararg{String}}, Any}()),
        Dict{Tuple{Vararg{String}}, Any}(("0,1",) => Dict{Tuple{Vararg{String}}, Any}()),
        Dict{Tuple{Vararg{String}}, Any}(("0,1",) => Dict{Tuple{Vararg{String}}, Any}()),
    ]

    num_dists = 4
    ideal_pop = 4

    @test MetropolizedForestRecom.satisfies_constraint(
        AllowedExcessDistsInCoarseNodes(1, ideal_pop),
        small_square_graph,
        district_to_nodes,
        num_dists,
    )

    @test !MetropolizedForestRecom.satisfies_constraint(
        MaxTotalExcessDistsInCoarseNodes(1, ideal_pop),
        small_square_graph,
        district_to_nodes,
        num_dists,
    )

    @test MetropolizedForestRecom.satisfies_constraint(
        MaxTotalExcessDistsInCoarseNodes(2, ideal_pop),
        small_square_graph,
        district_to_nodes,
        num_dists,
    )
end