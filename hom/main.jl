using Base.Threads
using DataFrames
using Discretizers
using Eolas
using LightGraphs
using LightGraphs.SimpleGraphs
using Random
using XLSX

normalize(xs) = xs ./ sum(xs)

function filtrate!(frames, col)
    for (i, frame) in enumerate(frames[2:end])
        frames[1 + i] = filter(r -> all(g -> r[col] in g[:,col], frames[1:i]), frame)
    end
    frames
end

function kos()
    excel = XLSX.openxlsx("kos.xlsx")
    sheets = XLSX.sheetnames(excel)[2:4]
    frames = map(s -> DataFrame(XLSX.gettable(excel[s])...), sheets)
    sort!.(dropmissing!.(select!.(frames, :KO), disallowmissing=true))
end

function bootstrap(df, col, n)
    gf = DataFrame(Symbol(string(col) * "0") => df[:,col])
    for i in 1:n
        gf[!,Symbol(string(col) * string(i))] = sort!(rand(df[:,col], length(df[:,col])))
    end
    gf
end

function genus()
    excel = XLSX.openxlsx("genus.xlsx")
    sheets = XLSX.sheetnames(excel)[2:4]
    map(sheets) do sheet
        column = filter(!ismissing, excel[sheet]["J"])
        name, values = Symbol(column[1]), column[2:end]
        df = dropmissing!(DataFrame(name => values), disallowmissing=true)
        df[!,name] = strip.(df[:,name])
        sort!(df)
    end
end

discretizer(dfs, col) = CategoricalDiscretizer(sort!(unique!(vcat(dfs...)))[:,col])
function encode!(disc::CategoricalDiscretizer, df::DataFrame, col::Symbol)
    df[!,Symbol(string(col) * "code")] = encode(disc, df[:,col])
    df
end

function discretize(dfs, col)
    disc = discretizer(dfs, col)
    map(df -> encode!(disc, df, col), dfs), disc
end

struct Space
    n::Int
    v::Int
    Space(n) = n < 0 ? error("invalid dimension") : new(n, 2^n - 1)
end

Base.iterate(space::Space) = trues(space.n), (0, trues(space.n))

function Base.iterate(space::Space, state)
    n, s = state
    if n >= space.v - 1
        nothing
    else
        for i in 1:space.n
            if s[i]
                s[i] = zero(s[i])
                s[1:i-1] .= one(s[i])
                break
            end
        end
        copy(s), (n + 1, s)
    end
end

Base.length(space::Space) = space.v
Base.eltype(space::Space) = BitArray{1}

venn(xs, col) = venn(map(x -> x[:,col], xs))
function venn(xs::AbstractVector{T}) where T
    v = Dict{BitArray{1}, T}()
    for idx in Space(length(xs))
        v[idx] = setdiff(intersect(xs[idx]...), xs[.!idx]...)
    end
    v
end

function assignkos(genera::AbstractVector{DataFrame}, kos::AbstractVector{DataFrame})
    @assert length(genera) == length(kos)
    gvenn = venn(genera, :genuscode)
    kvenn = venn(kos, :KOcode)
    merge((assignkos(gvenn[idx], kvenn[idx]) for idx in keys(gvenn))...)
end

function assignkos(genera::AbstractVector{S}, kos::AbstractVector{T}) where {S, T}
    assignment = Dict{S, Set{T}}()
    for g in genera
        assignment[g] = Set(rand(kos, 10))
    end
    for k in kos
        push!(assignment[rand(genera)], k)
    end
    assignment
end

function group!(depends, genera, n, m)
    N = length(genera)
    for _ in 1:n
        U = rand(2:m)
        group = genera[randperm(N)[1:U]]
        for i in 1:U, j in 1:U
            if i != j
                add_edge!(depends, group[i], group[j])
            end
        end
    end
    depends
end

function group(genera::AbstractVector{DataFrame}, n, m)
    M = length(genera)
    N = length(unique!(vcat(genera...)).genuscode)
    gvenn = venn(genera, :genuscode)
    T = gvenn |> valtype |> eltype

    G = SimpleGraph(N)
    for i in 1:M
        a = Set{T}()
        for j in 1:M
            for s in Space(M)
                if s[i] && !s[j]
                    union!(a, Set(gvenn[s]))
                end
            end
        end
        group!(G, collect(a), n, m)
    end
    G
end

sample(G, n) = sort!(randperm(nv(G))[1:n])

redux(G, prev) = filter(i -> neighbors(G, i) ⊆ prev, prev)

function subsample(G, prev, n)
    next = redux(G, prev)
    N = length(next)
    if N > n
        sort!(randperm(N)[1:n])
    else
        while N < n
            next = unique!(append!(next, sample(G, n - N)))
            N = length(next)
        end
        sort!(next)
    end
end

function occurances(G, samplings)
    N = length(samplings)
    occurs = Array{Int}(undef, N, nv(G))
    for j in 1:nv(G), i in 1:N
        occurs[i, j] = (j in samplings[i]) ? 2 : 1
    end
    occurs
end

cbw(G, m, dfs::AbstractVector{DataFrame}) = cbw(G, m, nrow.(dfs))

function cbw(G, m, ns)
    oc = Array{Int}(undef, length(ns), m, nv(G))
    @threads for i in 1:m
        samplings = [sample(G, ns[1])]
        for n in ns[2:end]
            push!(samplings, subsample(G, samplings[end], n))
        end
        oc[:,i,:] .= occurances(G, samplings)
    end
    oc
end

function Eolas.mutualinfo(data, i, j)
    m = MutualInfo(2, 2)
    for k in 1:size(data,2)
        observe!(m, data[1:end-1,k,i], data[2:end,k,j])
    end
    estimate(m)
end

function Eolas.transferentropy(data, i, j)
    te = TransferEntropy(2, 2, 1)
    for k in 1:size(data, 2)
        @views observe!(te, data[:, k, i], data[:, k, j])
    end
    estimate(te)
end

function sigtest(measure, data, i, j; nperms=100)
    ds = copy(data)
    gt = measure(data, i, j)
    c = 1
    for i in 1:nperms
        for k in 1:size(data, 2)
            shuffle!(@view ds[:, k, i])
        end
        c += (measure(data, i, j) ≥ gt)
    end
    gt, c / (nperms + 1)
end

function lmi(data; nperms=0)
    mi = Array{Float64}(undef, size(data,3), size(data,3))
    @threads for i in 1:size(data, 3)
        @threads for j in i:size(data, 3)
            a, b = if !iszero(nperms)
                a, p = sigtest(mutualinfo, data, i, j; nperms=nperms)
                b, q = sigtest(mutualinfo, data, j, i; nperms=nperms)
                a = p < 0.05 ? a : zero(a)
                b = p < 0.05 ? b : zero(b)
                a, b
            else
                mutualinfo(data, i, j) , mutualinfo(data, j, i)
            end
            mi[i, j] = mi[j, i] = 0.5 * (a + b)
        end
    end
    mi
end

function nte(data; nperms=0)
    te = Array{Float64}(undef, size(data,3), size(data,3))
    @threads for i in 1:size(data, 3)
        @threads for j in i:size(data, 3)
            a, b = if !iszero(nperms)
                a, p = sigtest(transferentropy, data, i, j; nperms=nperms)
                b, p = sigtest(transferentropy, data, j, i; nperms=nperms)
                a = p < 0.05 ? a : zero(a)
                b = p < 0.05 ? b : zero(b)
                a, b
            else
                transferentropy(data, i, j), transferentropy(data, j, i)
            end
            te[i, j] = te[j, i] = 0.5 * (a + b)
        end
    end
    te
end

function neighboring(G)
    ns = falses(nv(G), nv(G))
    for i in 1:nv(G)
        for j in neighbors(G, i)
            ns[i, j] = true
        end
    end
    ns
end

function main()
    genera = genus()
    _, gdisc = discretize(genera, :genus)
    G = group(genera, 20, 5)
    genera, gdisc, G
end
