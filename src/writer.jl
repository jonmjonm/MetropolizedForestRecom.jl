AtlasParam=Dict{String, Any}
MapParam=Dict{String, Any}

mutable struct Writer
    atlas::Atlas{AtlasParam}
    map_param::MapParam
    map_output_data::Dict{String, Function}
    output_districting::Bool
end

function Writer(
    measure::Measure,
    constraints::Dict,
    partition::MultiLevelPartition,
    output_file_path::String,
    output_districting=true;
    description::String="",
    time_stamp=string(Dates.now()),
    io_mode::String="w"
)
    graph = partition.graph
    atlasParam=AtlasParam("gamma"=>measure.gamma, 
                          "energies"=>measure.descriptions,
                          "energy weights"=>measure.weights,
                          "districts"=>partition.num_dists,
                          "levels in graph"=>graph.levels)
    num_levels = graph.num_levels
    # node_name_example = JSON3.write(graph.id_to_partitions[num_levels][1])
    graph_edges_by_level = [ne(g.simple_graph) for g in graph.graphs_by_level]
    graph_nodes_by_level = [nv(g.simple_graph) for g in graph.graphs_by_level]
    
    # println(node_name_example)
    # atlasParam["node name example"] = node_name_example
    atlasParam["graph edges by level"] = graph_edges_by_level
    atlasParam["graph nodes by level"] = graph_nodes_by_level

    if haskey(constraints, PopulationConstraint)
        min_pop = constraints[PopulationConstraint].min_pop
        max_pop = constraints[PopulationConstraint].max_pop
        atlasParam["population bounds"] = [min_pop, max_pop]
    end
    
    # to add to atlasParam
    # other constraints

    dir = dirname(output_file_path)
    # split_path = split(output_file_path, "/")
    # dir = join(split_path[1:length(split_path)-1], "/")
    if !isdir(dir)
        mkpath(dir)
    end

    atlasHeader = AtlasHeader(description, time_stamp, AtlasParam, MapParam)
    io = smartOpen(output_file_path, io_mode)
    newAtlas(io, atlasHeader, atlasParam)

    atlas = Atlas{AtlasParam}(io, description, time_stamp, atlasParam, MapParam)
    map_output_data = Dict{String, Function}()
    return Writer(atlas, MapParam(), map_output_data, output_districting)
end

function Writer(
    output_file_path::String,
    output_districting=true;
    description::String="",
    time_stamp=string(Dates.now()),
    io_mode::String="w"
)
    atlasParam=AtlasParam()
    
    dir = dirname(output_file_path)
    # split_path = split(output_file_path, "/")
    # dir = join(split_path[1:length(split_path)-1], "/")
    if !isdir(dir)
        mkpath(dir)
    end

    atlasHeader = AtlasHeader(description, time_stamp, AtlasParam, MapParam)
    io = smartOpen(output_file_path, io_mode)
    newAtlas(io, atlasHeader, atlasParam)

    atlas = Atlas{AtlasParam}(io, description, time_stamp, atlasParam, MapParam)
    map_output_data = Dict{String, Function}()
    return Writer(atlas, MapParam(), map_output_data, output_districting)
end

function push_writer!(
    writer::Writer,
    get_data::Function; 
    desc::Union{String, Nothing}=nothing
)
    if desc == nothing
        desc = string(get_data)
    end
    writer.map_output_data[desc] = get_data
end


function close_writer(writer::Writer)
    close(writer.atlas.io)
end
