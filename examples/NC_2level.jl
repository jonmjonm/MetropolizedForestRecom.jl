# TO run this file execute the following in the examples directory: 
#
# julia NC_2level.jl
#
# TO instantiate the environment to run this file execute the following in the examples directory: 
#
# julia --project=./runMetropolizedRecomEnv -e 'using Pkg; Pkg.instantiate()'
#


import Pkg
Pkg.activate("./runMetropolizedRecomEnv")

using RandomNumbers
using MetropolizedForestRecom

num_dists = 14
rng_seed = 454190
pop_dev = 0.02
gamma = 0.0 #0 is uniform on forests; 1 is uniform on partitions
steps = 1000
edge_weights= "connections"

pctGraphPath = joinpath("..", "test", "test_graphs", "NC_pct21.json")
nodeData = Set(["county", "prec_id", "pop2020cen", "area", "border_length"]);
base_graph = BaseGraph(pctGraphPath, "pop2020cen", inc_node_data=nodeData,
                       area_col="area", node_border_col="border_length",
                       edge_perimeter_col="length", edge_weights=edge_weights);
graph = MultiLevelGraph(base_graph, ["county", "prec_id"]);

constraints = initialize_constraints()
add_constraint!(constraints, PopulationConstraint(graph, num_dists, pop_dev))
add_constraint!(constraints, ConstrainDiscontinuousTraversals(graph))
add_constraint!(constraints, MaxCoarseNodeSplits(num_dists+1))

rng = PCG.PCGStateOneseq(UInt64, rng_seed)
partition = MultiLevelPartition(graph, constraints, num_dists; rng=rng);

proposal = build_forest_recom2(constraints)
measure = Measure(gamma, 1.0)
# to add elements to the measure
# push_measure!(measure, get_isoperimetric_score, 0.45)

output_file_path = joinpath("output", "NC", 
                            "atlas_2level_gamma"*string(gamma)*".jsonl")
writer = Writer(measure, constraints, partition, output_file_path)
push_writer!(writer, get_log_spanning_forests)
push_writer!(writer, get_isoperimetric_scores)

println("startring mcmc")
run_metropolis_hastings!(partition, proposal, measure, steps, rng,
                         writer=writer, output_freq=10);
