@testset "graph-weighted initializer" begin
    node_data = Set(["county", "prec_id", "pop2020cen", "area", "border_length"])
    graph = MultiLevelGraph(
        joinpath(testdir, "test_graphs", "NC_pct21.json"),
        "pop2020cen",
        ["county", "prec_id"];
        inc_node_data = node_data,
        area_col = "area",
        node_border_col = "border_length",
        edge_perimeter_col = "length",
    )
    remaining_nodes = Dict{Tuple{Vararg{String}},Any}(
        node => nothing for node in graph.id_to_partitions[1]
    )
    subgraph = MultiLevelSubGraph(graph, remaining_nodes)
    initializer = GraphWeightedInitializer()

    cut_masses = Dict{Tuple,Float64}()
    checked_edges = 0
    for level in 1:graph.num_levels
        level_graph = graph.graphs_by_level[level]
        for edge_ids in keys(level_graph.edge_attributes)
            n1_id, n2_id = collect(edge_ids)
            edge = (
                graph.id_to_partitions[level][n1_id],
                graph.id_to_partitions[level][n2_id],
            )
            expected_mass = inv(Float64(level_graph.simple_graph.weights[n1_id, n2_id]))
            observed_mass = MetropolizedForestRecom.initialization_cut_weight(
                edge,
                subgraph,
                initializer,
            )

            @test isapprox(observed_mass, expected_mass)
            cut_masses[edge] = expected_mass
            checked_edges += 1
        end
    end
    @test checked_edges > 7_000

    coarse_graph = graph.graphs_by_level[1]
    non_edge_ids = first(
        Set([n1, n2])
        for n1 in 1:coarse_graph.num_nodes-1
        for n2 in n1+1:coarse_graph.num_nodes
        if !haskey(coarse_graph.edge_attributes, Set([n1, n2]))
    )
    n1_id, n2_id = collect(non_edge_ids)
    @test_throws DomainError MetropolizedForestRecom.initialization_cut_weight(
        (graph.id_to_partitions[1][n1_id], graph.id_to_partitions[1][n2_id]),
        subgraph,
        initializer,
    )

    edge_masses = sort!(collect(cut_masses); by = last)
    cuttable_edges = Set([first(edge_masses[1]), first(edge_masses[end])])
    tree = MultiScaleCuttableTree(graph.num_levels)
    rng = PCG.PCGStateOneseq(UInt64, 1241909)
    edge, probability = MetropolizedForestRecom.choose_cuttable_edge(
        cuttable_edges,
        tree,
        subgraph,
        rng,
        initializer,
    )

    expected_probability = cut_masses[edge] / sum(cut_masses[e] for e in cuttable_edges)
    @test isapprox(probability, expected_probability)

    constraints = initialize_constraints()
    add_constraint!(constraints, PopulationConstraint(graph, 14, 0.02))
    add_constraint!(constraints, ConstrainDiscontinuousTraversals(graph))
    add_constraint!(constraints, MaxCoarseNodeSplits(15))
    rng = PCG.PCGStateOneseq(UInt64, 454190)
    partition = MultiLevelPartition(
        graph,
        constraints,
        14;
        rng = rng,
        max_attempts = 100,
        initializer = initializer,
    )

    @test partition.num_dists == 14
    @test sum(partition.dist_populations) == graph.graphs_by_level[1].total_pop
end
