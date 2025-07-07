function build_get_partisan_margins(
    votes1::String, votes2::String
)
    f(p, d=collect(1:p.num_dists)) = get_partisan_margins(p, votes1, votes2, d)
    return f
end

function build_get_partisan_seats(
    votes1::String, votes2::String
)
    f(p, d=collect(1:p.num_dists)) = get_partisan_seats(p, votes1, votes2, d)
    return f
end

function get_partisan_margins(
    partition::MultiLevelPartition,
    votes1::String, 
    votes2::String,
    districts::Vector{Int} = collect(1:partition.num_dists)
)
    leans = Vector{Float64}(undef, length(districts))
    graph = partition.graph 

    for (ii, di) in enumerate(districts)
        node_set = partition.district_to_nodes[di]
        p1votes = sum_attribute(graph, node_set, votes1)
        p2votes = sum_attribute(graph, node_set, votes2)
        leans[ii] = 100.0*p1votes/(p1votes + p2votes)
    end
    
    return leans
end

function get_partisan_seats(
    partition::MultiLevelPartition,
    votes1::String, 
    votes2::String,
    districts::Vector{Int} = collect(1:partition.num_dists)
)
    leans = get_partisan_margins(partition, votes1, votes2, districts)
    return length([1 for l in leans if l > 50.0])
end
