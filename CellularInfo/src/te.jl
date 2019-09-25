const Series = Vector{Int}
const Ensemble = Array{Int, 2}

mutable struct TransferDist
    b::Int
    k::Int
    counts::Int
    states::Vector{Int}
    histories::Vector{Int}
    sources::Vector{Int}
    predicates::Vector{Int}
    function TransferDist(b, k)
        q = b^k
        states = zeros(Int, b*b*q)
        histories = zeros(Int, q)
        sources = zeros(Int, b*q)
        predicates = zeros(Int, b*q)
        new(b, k, 0, states, histories, sources, predicates)
    end
end

isvalid(t::TransferDist) = t.counts != 0

function observe!(t::TransferDist, src::Series, dst::Series)
    if size(src) != size(dst)
        throw(ArgumentError("length(src) must equal length(dst)"))
    end
    if length(dst) <= t.k
        throw(ArgumentError("history length must be less than length(dst)"))
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
        src_state = src[i-1]
        future = dst[i]
        source = history * t.b + src_state
        predicate = history * t.b + future
        state = predicate * t.b + src_state

        t.states[state + 1] += 1
        t.histories[history + 1] += 1
        t.sources[source + 1] += 1
        t.predicates[predicate + 1] += 1

        history = predicate - q * dst[i - t.k]
    end

    t
end

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

function transferentropy(src::Series, dst::Series, k::Int)
    xs = src .- minimum(src)
    ys = dst .- minimum(dst)
    b = max(1, maximum(xs), maximum(ys)) + 1
    tedist = TransferDist(b, k)
    observe!(tedist, xs, ys)
end
