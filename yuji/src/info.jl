using Random

const Series = AbstractVector{Int}

const Dist = AbstractArray{Float64}

mutable struct MIDist
    joint::Matrix{Int}
    m1::Vector{Int}
    m2::Vector{Int}
    N::Int
    MIDist() = new(zeros(Int, 2, 2), zeros(Int, 2), zeros(Int, 2), 0)
end

MIDist(xs::AbstractVector{Int}, ys::AbstractVector{Int}) = accumulate!(MIDist(), xs, ys)

function entropy(dist::MIDist)
    mi = 0.0
    for i in 1:2, j in 1:2
        p = dist.joint[i,j]
        if !iszero(p)
            mi += p * log2(p / (dist.m1[i] * dist.m2[j]))
        end
    end
    log2(dist.N) + mi/dist.N
end

function accumulate!(dist::MIDist, xs::AbstractVector{Int}, ys::AbstractVector{Int})
    dist.N += length(xs)
    @inbounds for i in eachindex(xs)
        x, y = xs[i], ys[i]
        dist.m1[x] += 1
        dist.m2[y] += 1
        dist.joint[x, y] += 1
    end
    dist
end

@inline function clear!(dist::MIDist)
    dist.joint[:] .= 0.0
    dist.m1[:] .= 0
    dist.m2[:] .= 0
    dist.N = 0
    dist
end

function mutualinfo!(dist::MIDist, xs::AbstractVector{Int}, ys::AbstractVector{Int}; l::Int=0)
    @views entropy(accumulate!(dist, xs[1:end-l], ys[l+1:end]))
end

function significance(rng::AbstractRNG, measure::Function, xs::Series, ys::Series; nperms=1000)
    dist = MIDist()
    gt = measure(dist, xs, ys)
    clear!(dist)

    count = 0
    xsperm = xs[:]
    for _ in 1:nperms
        count += (measure(dist, shuffle!(rng, xsperm), ys) ≥ gt)
        clear!(dist)
    end
    p = count / (nperms + 1)
    se = sqrt((p * (1 - p)) / (nperms + 1))

    gt, p, se
end

function issig(datum::NTuple{3, Float64}; p::Float64=0.05)
    if p < zero(p) || p > one(p)
        throw(DomainError(p, "must be between 0.0 and 1.0"))
    end
    datum[2] < p
end

function signify(data::AbstractArray{NTuple{3,Float64}}; p::Float64=0.05)
    sigdata = first.(data)
    sigdata[.!issig.(data; p=p)] .= 0.0
    sigdata
end
