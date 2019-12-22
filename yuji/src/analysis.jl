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

struct TEAnalysis <: Analysis
    ks::UnitRange{Int}
    nperms::Int
    p::Float64
    spotcheck::Int
    TEAnalysis(; ks=1:9, nperms=1000, p=0.05, spotcheck=1000) = new(ks, nperms, p, spotcheck)
end

params(te::TEAnalysis) = te.ks

function analyze(rng::AbstractRNG, te::TEAnalysis,
                 xs::AbstractVector{Int}, ys::AbstractVector{Int},
                 k::Int)
    significance(rng, TEDist(k), transferentropy!, xs, ys;
                 nperms=nperms(te), pvalue=pvalue(te), spotcheck=spotcheck(te))
end

function analyze(rng::AbstractRNG, an::Analysis, binned::AbstractArray{Int,3})
    m, n, t = size(binned)
    allinfo = Array{Float64,4}[]
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
        push!(allinfo, Array(info))
    end
    allinfo
end

analyze(an::Analysis, binned::AbstractArray{Int,3}) = analyze(Random.GLOBAL_RNG, an, binned)
