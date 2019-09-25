using Random

const Series = AbstractVector{Int}
const Ensemble = AbstractArray{Int,2}

mutable struct TransferDist
    b::Int
    k::Int
    ncond::Int
    counts::Int
    states::Vector{Int}
    histories::Vector{Int}
    sources::Vector{Int}
    predicates::Vector{Int}
    function TransferDist(b, k, n)
        if b < 2
            throw(DomainError(b, "base must be at least 2"))
        end
        if k < 1
            throw(DomainError(k, "history length must be at least 1"))
        end
        if n < 0
            throw(DomainError(n, "number of conditions must be non-negative"))
        end
        q = b^k
        r = b^n
        states = zeros(Int, b*b*q*r)
        histories = zeros(Int, q*r)
        sources = zeros(Int, b*q*r)
        predicates = zeros(Int, b*q*r)
        new(b, k, n, 0, states, histories, sources, predicates)
    end
end

isvalid(t::TransferDist) = t.counts != 0

function observe!(t::TransferDist, src::Series, dst::Series, cond::Union{Nothing,Ensemble} = nothing)
    if size(src) != size(dst)
        throw(ArgumentError("length(src) must equal length(dst)"))
    end
    if length(dst) <= t.k
        throw(ArgumentError("length(dst) must be greater than the history length"))
    end
    if isnothing(cond) && t.ncond != 0
        throw(ArgumentError("expected $(t.ncond) conditions, got 0"))
    end
    if !isnothing(cond) && size(cond, 1) != t.ncond
        throw(ArgumentError("expected $(t.ncond) conditions, got $(size(cond, 1))"))
    end
    if !isnothing(cond) && size(cond, 2) != length(dst)
        throw(ArgumentError("size(cond, 2) must be equal to length(dist)"))
    end

    t.counts += length(dst) - t.k
    src_state, future, state, source, predicate = 0, 0, 0, 0, 0
    history, q = 0, 1
    for i in 1:t.k
        q *= t.b
        history *= t.b
        history += dst[i]
    end
    for i in t.k+1:length(src)
        back = 0
        for c in 1:t.ncond
            back = back * t.b + cond[c, i-1]
        end
        history += back * q
        src_state = src[i-1]
        future = dst[i]
        source = history * t.b + src_state
        predicate = history * t.b + future
        state = predicate * t.b + src_state

        t.states[state + 1] += 1
        t.histories[history + 1] += 1
        t.sources[source + 1] += 1
        t.predicates[predicate + 1] += 1

        history = predicate - q * (dst[i - t.k] + back * t.b)
    end

    t
end

observe!(t::TransferDist, src::Series, dst::Series, cond::Series) = observe!(t, src, dst, cond')

function (t::TransferDist)()
    if !isvalid(t)
        error("TransferDist has no observed data")
    end
    te = 0.0
    for (h, history) in enumerate(t.histories)
        if history == 0
            continue
        end
        for f in 1:t.b
            p = (h - 1) * t.b + f
            predicate = t.predicates[p]
            if predicate == 0
                continue
            end
            for src in 1:t.b
                ss = (h - 1) * t.b + src
                source = t.sources[ss]
                if source == 0
                    continue
                end
                s = (p - 1) * t.b + src
                state = t.states[s]
                if state == 0
                    continue
                end
                te += state * log2((state * history) / (source * predicate))
            end
        end
    end
    te / t.counts
end

function transferentropy(src::Series, dst::Series, cond::Ensemble, k::Int)
    xs = src .- minimum(src)
    ys = dst .- minimum(dst)
    cs = cond .- minimum(cond; dims=2)
    b = max(1, maximum(xs), maximum(ys), maximum(cs)) + 1
    tedist = TransferDist(b, k, size(cond,1))
    observe!(tedist, xs, ys, cond)
    tedist()
end

function transferentropy(src::Series, dst::Series, k::Int)
    xs = src .- minimum(src)
    ys = dst .- minimum(dst)
    b = max(1, maximum(xs), maximum(ys)) + 1
    tedist = TransferDist(b, k, 0)
    observe!(tedist, xs, ys)
    tedist()
end

transferentropy(src::Series, dst::Series, cond::Series, k::Int) = transferentropy(src, dst, cond', k)

struct Significance
    value::Float64
    p::Float64
    se::Float64
end

function transferentropy(rng::AbstractRNG, src::Series, dst::Series, cond::Union{Series,Ensemble}, k::Int, nperm::Int)
    if nperm < 10
        throw(DomainError(nperm, "expected at least 10 permutation, got $(nperm)"))
    end

    te = transferentropy(src, dst, cond, k)
    count = 1
    for _ in 1:nperm
        permutedsrc = src[randperm(rng, length(src))]
        count += transferentropy(permutedsrc, dst, cond, k) >= te
    end
    p = count / (nperm + 1)
    se = sqrt((p * (1 - p)) / (nperm + 1))

    Significance(te, p, se)
end
transferentropy(src, dst, cond, k, nperm) = transferentropy(Random.GLOBAL_RNG, src, dst, cond, k, nperm)

function transferentropy(rng::AbstractRNG, src::Series, dst::Series, k::Int, nperm::Int)
    if nperm < 10
        throw(DomainError(nperm, "expected at least 10 permutation, got $(nperm)"))
    end

    te = transferentropy(src, dst, k)
    count = 1
    for _ in 1:nperm
        permutedsrc = src[randperm(rng, length(src))]
        count += transferentropy(permutedsrc, dst, k) >= te
    end
    p = count / (nperm + 1)
    se = sqrt((p * (1 - p)) / (nperm + 1))

    Significance(te, p, se)
end
transferentropy(src, dst, k, nperm) = transferentropy(Random.GLOBAL_RNG, src, dst, k, nperm)
