using SharedArrays

abstract type Analysis end

pvalue(an::Analysis) = an.p
nperms(an::Analysis) = an.nperms
spotcheck(an::Analysis) = an.spotcheck

struct MIAnalysis <: Analysis
    lags::UnitRange{Int}
    nperms::Int
    p::Float64
    spotcheck::Int
    MIAnalysis(; lags=0:9, nperms=1000, p=0.05, spotcheck=1000) = new(lags, nperms, p, spotcheck)
end

params(mi::MIAnalysis) = mi.lags

function analyze(rng::AbstractRNG, mi::MIAnalysis,
                 xs::AbstractVector{Int}, ys::AbstractVector{Int},
                 lag::Int)
    significance(rng, MIDist(), mutualinfo!, xs[1:end-lag], ys[(lag+1):end];
                 nperms=nperms(mi), pvalue=pvalue(mi), spotcheck=spotcheck(mi))
end

function analyze(rng::AbstractRNG, an::Analysis, binned::AbstractArray{Int,3})
    m, n, t = size(binned)
    mi = Array{Float64,4}[]
    for l in params(an)
        info = SharedArray{Float64,4}((m, n, m, n))
        @sync @distributed for a in 1:m*n
            i = (a - 1) % m + 1
            j = (a - 1) ÷ m + 1
            for u in 1:m, v in 1:n
                @views begin
                    value = analyze(rng, an, binned[i, j, :], binned[u, v, :], l)
                end
                info[i, j, u, v] = issig(value; p=pvalue(an)) ? first(value) : zero(Float64)
            end
        end
        push!(mi, Array(info))
    end
    mi
end

analyze(rng::AbstractRNG, an::Analysis, g::AbstractArray{Float64,3}) = analyze(rng, an, bin(g))
analyze(an::Analysis, g::AbstractArray{Float64,3}) = analyze(Random.GLOBAL_RNG, an, g)
