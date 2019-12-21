using SharedArrays

function analyze(g; rng::AbstractRNG=Random.GLOBAL_RNG, lags::UnitRange{Int}=0:10,
                             nperms=1000, p=0.05, spotcheck=1000)
    binned = bin(g)
    m, n, t = size(binned)
    lagged = Array{Float64,4}[]
    for l in lags
        info = SharedArray{Float64,4}((m, n, m, n))
        @distributed for a in 1:m*n
            i = (a - 1) % m + 1
            j = (a - 1) ÷ m + 1
            for u in 1:m, v in 1:n
                value = significance(rng, mutualinfo!, binned[i, j, 1:end-l], binned[u, v, (l+1):end];
                    nperms=nperms, pvalue=p, spotcheck=spotcheck)
                info[i, j, u, v] = issig(value; p=p) ? first(value) : zero(Float64)
            end
        end
        push!(lagged, Array(info))
    end
    lagged
end
