using Random

const Series = AbstractVector{Int}

abstract type InfoDist end

mutable struct MIDist <: InfoDist
    joint::Matrix{Int}
    m1::Vector{Int}
    m2::Vector{Int}
    N::Int
    MIDist() = new(zeros(Int, 2, 2), zeros(Int, 2), zeros(Int, 2), 0)
end

MIDist(xs::Series, ys::Series) = accumulate!(MIDist(), xs, ys)

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

function accumulate!(dist::MIDist, xs::Series, ys::Series)
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
    dist.joint[:] .= 0
    dist.m1[:] .= 0
    dist.m2[:] .= 0
    dist.N = 0
    dist
end

function mutualinfo!(dist::MIDist, xs::Series, ys::Series; l::Int=0)
    @views entropy(accumulate!(dist, xs[1:end-l], ys[l+1:end]))
end

mutable struct TEDist <: InfoDist
    k::Int
    states::Array{Int}
    histories::Array{Int}
    sources::Array{Int}
    predicates::Array{Int}
    N::Int

    function TEDist(k::Int)
        states = zeros(Int, fill(2, k+2)...)
        histories = zeros(Int, fill(2, k)...)
        sources = zeros(Int, fill(2, k+1)...)
        predicates = zeros(Int, fill(2, k+1)...)
        new(k, states, histories, sources, predicates, 0)
    end
end

@inline function clear!(dist::TEDist)
    dist.states[:] .= 0
    dist.histories[:] .= 0
    dist.sources[:] .= 0
    dist.predicates[:] .= 0
    dist.N = 0
    dist
end

function accumulate!(dist::TEDist, xs::Series, ys::Series)
    rng = dist.k:(length(ys)-1)
    dist.N += length(rng)
    @inbounds for i in rng
        yᵏ = ys[i-dist.k+1:i]
        x, y⁺ = xs[i], ys[i+1]
        dist.states[yᵏ..., x, y⁺] += 1
        dist.histories[yᵏ...] += 1
        dist.sources[yᵏ..., x] += 1
        dist.predicates[yᵏ..., y⁺] += 1
    end
    dist
end

function entropy(xs::AbstractArray{Int}, N::Int)
    h = N * log2(N)
    for i in eachindex(xs)
        n = xs[i]
        if !iszero(n)
            h -= n * log2(n)
        end
    end
    h / N
end

function entropy(dist::TEDist)
    entropy(dist.sources, dist.N) +
    entropy(dist.predicates, dist.N) -
    entropy(dist.states, dist.N) -
    entropy(dist.histories, dist.N)
end

function transferentropy!(dist::TEDist, xs::Series, ys::Series)
    entropy(accumulate!(dist, xs, ys))
end

function transferentropy(xs::Series, ys::Series, k::Int)
    transferentropy!(TEDist(k), xs, ys)
end

function significance(rng::AbstractRNG, dist::InfoDist, measure::Function,
                      xs::Series, ys::Series;
                      nperms=1000, pvalue=0.05, spotcheck=1000)
    gt = measure(dist, xs, ys)
    clear!(dist)

    count = 0
    xsperm = xs[:]

    if nperms <= spotcheck
        for _ in 1:nperms
            count += (measure(dist, shuffle!(rng, xsperm), ys) ≥ gt)
            clear!(dist)
        end
        p = count / (nperms + 1)
        se = sqrt((p * (1 - p)) / (nperms + 1))

        return gt, p, se
    else
        for _ in 1:spotcheck
            count += (measure(dist, shuffle!(rng, xsperm), ys) ≥ gt)
            clear!(dist)
        end
        p = count / (spotcheck + 1)
        se = sqrt((p * (1 - p)) / (spotcheck + 1))

        if abs(p - pvalue) < 2pvalue
            for _ in 1:(nperms - spotcheck)
                count += (measure(dist, shuffle!(rng, xsperm), ys) ≥ gt)
                clear!(dist)
            end
            p = count / (nperms + 1)
            se = sqrt((p * (1 - p)) / (nperms + 1))
        end

        return gt, p, se
    end
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
