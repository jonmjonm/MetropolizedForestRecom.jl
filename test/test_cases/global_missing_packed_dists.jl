name = "global missing packed-district constraint"

@testset "$name" begin
    ideal_pop = 4
    num_dists = 2

    node_to_packed_dists = Dict{Tuple{Vararg{String}}, Int}(
        ("0,0",) => 1,
        ("0,1",) => 1,
    )

    # District 1 is packed entirely inside ("0,0",).
    # District 2 crosses ("0,0",) and ("0,1",).
    #
    # Therefore ("0,1",) does not get the packed district
    # required by PackNodeConstraint.
    district_to_nodes_one_missing = [
        Dict{Tuple{Vararg{String}}, Any}(
            ("0,0",) => nothing,
        ),
        Dict{Tuple{Vararg{String}}, Any}(
            ("0,0",) => nothing,
            ("0,1",) => nothing,
        ),
    ]

    @testset "PackNodeConstraint is strict by node" begin
        @test !MetropolizedForestRecom.satisfies_constraint(
            MetropolizedForestRecom.PackNodeConstraint(
                node_to_packed_dists,
                ideal_pop,
            ),
            small_square_graph,
            district_to_nodes_one_missing,
            num_dists,
        )
    end

    @testset "Global missing packed-district constraint allows a statewide budget" begin
        @test !MetropolizedForestRecom.satisfies_constraint(
            MetropolizedForestRecom.MaxTotalMissingPackedDistsInCoarseNodes(
                0,
                ideal_pop,
            ),
            small_square_graph,
            district_to_nodes_one_missing,
            num_dists,
        )

        @test MetropolizedForestRecom.satisfies_constraint(
            MetropolizedForestRecom.MaxTotalMissingPackedDistsInCoarseNodes(
                999,
                ideal_pop,
            ),
            small_square_graph,
            district_to_nodes_one_missing,
            num_dists,
        )
    end
end