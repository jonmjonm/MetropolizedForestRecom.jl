# julia NC_1level.jl
import Pkg
push!(LOAD_PATH, "..");
Pkg.activate("myEgEnv")

using RandomNumbers
using MultiScaleMapSampler

num_dists = 14
if length(ARGS) > 1
    rng_seed = parse(Int64, ARGS[1])
end
pop_dev = 0.02
gamma = 0.0 #0 is uniform on forests; 1 is uniform on partitions
steps = parse(Int64, ARGS[2])
edge_weights= "connections"

pctGraphPath = joinpath("..", "test", "test_graphs", "NC_pct21.json")
nodeData = Set(["county", "prec_id", "pop2020cen", "area", "border_length"]);
base_graph = BaseGraph(pctGraphPath, "pop2020cen", inc_node_data=nodeData,
                       area_col="area", node_border_col="border_length",
                       edge_perimeter_col="length", edge_weights=edge_weights);
for ii = 1:length(base_graph.node_attributes)
    county = base_graph.node_attributes[ii]["county"]
    prec_id = base_graph.node_attributes[ii]["prec_id"]
    name = county*"_"*prec_id
    base_graph.node_attributes[ii]["county_and_prec_id"] = name
end
graph = MultiLevelGraph(base_graph, ["county_and_prec_id"]);

constraints = initialize_constraints()
add_constraint!(constraints, PopulationConstraint(graph, num_dists, pop_dev))
# add_constraint!(constraints, ConstrainDiscontinuousTraversals(graph))
# add_constraint!(constraints, MaxCoarseNodeSplits(num_dists+1))

rng = PCG.PCGStateOneseq(UInt64, rng_seed)
partition = MultiLevelPartition(graph, constraints, num_dists; rng=rng);

proposal = build_forest_recom2(constraints)
measure = Measure(0.0, 1.0) # spanning forest measure; first number is exponent on trees, second on linking edges
# to add elements to the measure
# push_measure!(measure, get_isoperimetric_score, 0.45)

output_file_path = joinpath("output", "NC", 
                            "atlas_1level_gamma"*string(gamma)*".jsonl.gz")
writer = Writer(measure, constraints, partition, output_file_path)
push_writer!(writer, get_log_spanning_trees)
push_writer!(writer, get_log_spanning_forests)
push_writer!(writer, get_isoperimetric_scores)

run_metropolis_hastings!(partition, proposal, measure, steps, rng,
                         writer=writer, output_freq=1);
