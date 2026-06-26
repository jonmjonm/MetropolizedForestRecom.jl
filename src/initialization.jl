abstract type AbstractInitializer end

struct UniformInitializer <: AbstractInitializer end

struct BoundaryWeightedInitializer <: AbstractInitializer
    county_cut_weight::Float64
    mcd_cut_weight::Float64
    fine_cut_weight::Float64
end

function shared_prefix_length(n1::Tuple, n2::Tuple)::Int
    m = min(length(n1), length(n2))
    k = 0
    for i in 1:m
        if n1[i] == n2[i]
            k += 1
        else
            break
        end
    end
    return k
end

function initialization_cut_weight(
    edge::Tuple,
    initializer::BoundaryWeightedInitializer,
)::Float64
    n1, n2 = edge
    shared = shared_prefix_length(n1, n2)

    if shared == 0
        return initializer.county_cut_weight
    elseif shared == 1
        return initializer.mcd_cut_weight
    else
        return initializer.fine_cut_weight
    end
end