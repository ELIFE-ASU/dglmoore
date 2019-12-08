function analyze(g; rng::AbstractRNG=Random.GLOBAL_RNG, lags::UnitRange{Int}=0:10,
                             nperms=1000, p=0.05)
    binned = bin(g)
    m, n, t = size(binned)
    futures = Future[]
    for l in lags
        future = @spawn begin
            info = Array{Float64}(undef, m, n, m, n)
            for i in 1:m, j in 1:n
                for u in 1:m, v in 1:n
                    value = significance(rng, mutualinfo!, binned[i, j, (l+1):end], binned[u, v, 1:end-l];
                        nperms=nperms)
                    info[i, j, u, v] = issig(value) ? first(value) : zero(Float64)
                end
            end
            info
        end
        push!(futures, future)
    end
    map(fetch, futures) :: Vector{Array{Float64, 4}}
end