abstract type AbstractInitializer end

struct UniformInitializer <: AbstractInitializer end

struct GraphWeightedInitializer <: AbstractInitializer end

function initialization_cut_weight(
    edge::Tuple,
    subgraph::MultiLevelSubGraph,
    ::GraphWeightedInitializer,
)::Float64
    n1, n2 = edge
    weight = Float64(get_edge_weight(subgraph, n1, n2))

    if !isfinite(weight) || weight <= 0
        throw(
            DomainError(
                weight,
                "Graph-weighted initialization requires positive, finite edge weights.",
            ),
        )
    end

    # Graph weights encode affinity, so weaker edges receive more cut mass.
    return inv(weight)
end
