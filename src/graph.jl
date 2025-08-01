struct SubGraph
    graph::SimpleWeightedGraph
    vmap::Vector{Int}
end

struct BaseGraph
    num_nodes::Int
    num_edges::Int
    total_pop::Int
    #
    pop_col::String
    bpop_col::Union{String,Nothing}
    vap_col::Union{String,Nothing}
    bvap_col::Union{String,Nothing}
    edge_weights::String
    area_col::Union{String,Nothing}
    node_border_col::Union{String,Nothing}
    edge_perimeter_col::Union{String,Nothing}
    oriented_nbrs_col::Union{String,Nothing}
    mcd_col::Union{String,Nothing}
    #
    simple_graph::SimpleWeightedGraph     # the base SimpleWeightedGraph
    node_attributes::Array{Dict{String,Any}}
    edge_attributes::Dict{Set{Int},Dict{String,Any}}
end

"""
    get_attribute_by_key(node_attributes::Array,
                         column_name::String,
                         process_value::Function=identity)::Array

*Returns* an array whose values correspond to the value of an attribute
for each node.

*Arguments:*
- node_attributes :   An array of Dict{String, Any}, where each dictionary
                      represents a mapping from attribute names to values
                      for a particular node.
- column_name     :   The name of the attribute (i.e., the key of the
                      attribute in the dictionaries)
- process_value   :   An optional argument that processes the raw value
"""
function get_attribute_by_key(
    node_attributes::Array,
    column_name::String,
    process_value::Function = identity,
)::Array
    return [process_value(n[column_name]) for n in node_attributes]
end

"""
    graph_from_json(filepath::AbstractString,
                    pop_col::AbstractString)::BaseGraph

*Arguments:*
- filepath:       file path to the .json file that contains the graph.
                  This file is expected to be generated by the `Graph.to_json()`
                  function of the Python implementation of Gerrychain. [1]
                  We assume that the JSON file has the structure of a dictionary
                  where (1) the key "nodes" yields an array of dictionaries
                  of node attributes, (2) the key "adjacency" yields an
                  array of edges (represented as dictionaries), and (3)
                  the key "id" within the edge dictionary indicates the
                  destination node of the edge.
- pop_col:        the node attribute key whose accompanying value is the
                  population of that node

[1]: https://github.com/mggg/GerryChain/blob/c87da7e69967880abc99b781cd37468b8cb18815/gerrychain/graph/graph.py#L38
"""
function graph_from_json(
    filepath::AbstractString, 
    pop_col::AbstractString,
    inc_node_data::Set{String}, 
    edge_weights::String,
    bpop_col::Union{String,Nothing},
    vap_col::Union{String,Nothing},
    bvap_col::Union{String,Nothing},
    area_col::Union{String,Nothing},
    node_border_col::Union{String,Nothing},
    edge_perimeter_col::Union{String,Nothing},
    oriented_nbrs_col::Union{String,Nothing},
    mcd_col::Union{String,Nothing},
)::BaseGraph
    raw_graph = JSON.parsefile(filepath)
    nodes = raw_graph["nodes"]
    num_nodes = length(nodes)

    # get populations
    populations = get_attribute_by_key(nodes, pop_col)
    total_pop = sum(populations)

    # Generate the base SimpleWeightedGraph.
    ids = sort(get_attribute_by_key(nodes, "id"))
    @assert all([ids[ii]==ids[ii+1]-1 for ii = 1:length(ids)-1])
    one_index_shift = 1-ids[1]
    simple_graph = SimpleWeightedGraph(num_nodes)
    for (index, edges) in enumerate(raw_graph["adjacency"])
        for edge in edges
            if edge["id"] + one_index_shift > index
                add_edge!(simple_graph, index, edge["id"] + one_index_shift)
            end
        end
    end

    num_edges = ne(simple_graph)

    # get attributes
    node_attributes = get_node_attributes(nodes, inc_node_data)
    edge_attributes = get_edge_attributes(raw_graph["adjacency"], 
                                          one_index_shift)

    for e in edges(simple_graph)
        weight = edge_attributes[Set([src(e), dst(e)])][edge_weights]
        simple_graph.weights[src(e), dst(e)] = weight
        simple_graph.weights[dst(e), src(e)] = weight
    end

    # since we've adjusted the "id" above, we need to do it in the orientation
    if oriented_nbrs_col != nothing
        for ii = 1:num_nodes
            for jj = 1:length(node_attributes[ii][oriented_nbrs_col])
                node_attributes[ii][oriented_nbrs_col][jj] += 1
            end
        end
    end

    return BaseGraph(
        num_nodes,
        num_edges,
        total_pop,
        pop_col,
        bpop_col,
        vap_col,
        bvap_col,
        edge_weights,
        area_col,
        node_border_col,
        edge_perimeter_col,
        oriented_nbrs_col,
        mcd_col,
        simple_graph,
        node_attributes,
        edge_attributes,
    )
end

"""
    BaseGraph(filepath::AbstractString,
              pop_col::AbstractString;
              adjacency::String="rook")::BaseGraph

Builds the BaseGraph object. This is the underlying network of our
districts, and its properties are immutable i.e they will not change
from step to step in our Markov Chains.

*Arguments:*
- filepath:       A path to a .json or .shp file which contains the
                  information needed to construct the graph.
- pop_col:        the node attribute key whose accompanying value is the
                  population of that node
- adjacency:      (Only used if the user specifies a filepath to a .shp
                  file.) Should be either "queen" or "rook"; "rook" by default.
"""
function BaseGraph(
    filepath::AbstractString,
    pop_col::AbstractString;
    inc_node_data::Set{String}=Set(),
    edge_weights::String="connections",
    bpop_col=nothing,
    vap_col=nothing,
    bvap_col=nothing,
    area_col=nothing,
    node_border_col=nothing,
    edge_perimeter_col=nothing,
    oriented_nbrs_col=nothing,
    mcd_col=nothing,
    adjacency::String="rook"
)::BaseGraph
    extension = uppercase(splitext(filepath)[2])
    if uppercase(extension) == ".JSON"
        return graph_from_json(filepath, pop_col, inc_node_data, edge_weights,
                               bpop_col, vap_col, bvap_col, area_col, 
                               node_border_col, edge_perimeter_col,
                               oriented_nbrs_col, mcd_col)
    # elseif uppercase(extension) == ".SHP"
    #     return graph_from_shp(filepath, pop_col, adjacency)
    else
        throw(
            DomainError(
                filepath,
                "Filepath must lead to valid JSON file", # or valid .shp/.dbf file.",
            ),
        )
    end
end

"""
    get_node_attributes(nodes::Array{Any, 1})

*Returns* an array of dicts `attributes` of length `length(nodes)` where
the attributes of the `nodes[i]` is at `attributes[i]` as a dictionary.
"""
function get_node_attributes(nodes::Array{Any,1}, inc::Set{String}=Set())
    attributes = Array{Dict{String,Any}}(undef, length(nodes))

    for (index, node) in enumerate(nodes)
        if length(inc) != 0
            filter!(p -> p.first in inc, node)
        end
        attributes[index] = node
    end

    return attributes

end

"""-"""
function get_edge_attributes(adjacency::Array{Any,1}, one_index_shift::Int64)
    attributes = Dict{Set{Int}, Dict{String,Any}}()

    for (index, edges) in enumerate(adjacency)
        for edge in edges
            if edge["id"] + one_index_shift > index
                key = Set([index, edge["id"] + one_index_shift])
                e = deepcopy(edge)
                delete!(e, "id")
                if "connections" ∉ keys(e)
                    e["connections"] = 1
                end
                attributes[key] = e
             end
         end
     end

     return attributes

end
