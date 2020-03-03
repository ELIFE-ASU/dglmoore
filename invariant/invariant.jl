using DynamicPolynomials, LinearAlgebra

import DynamicPolynomials.MultivariatePolynomials: mapcoefficientsnz

@inline function swap!(A::Matrix{Int}, i::Int, j::Int)
    tmp = Array{Int}(undef, size(A, 1))
    copyto!(tmp, view(A, :, i))
    copyto!(view(A, :, i), view(A, :, j))
    copyto!(view(A, :, j), tmp)
end

function elim!(A::Matrix{Int})
    m, n = size(A)
    h, k = one(Int), one(Int)
    while h ≤ n && k ≤ m
        x, i = findmax(A[k,h:n])
        i += h - one(h)
        if iszero(x)
            k += one(k)
        else
            swap!(A, i, h)
            for i in 1:n
                if i != h
                    f = A[k, i] ÷ A[k, h]
                    A[k, i] = zero(A[k, i])
                    @simd for u in k+1:m
                        A[u,i] ⊻= f * A[u,h]
                    end
                end
            end
            h += 1
            k += 1
        end
    end
    A
end

struct Network
    table::Vector{Tuple{UInt, Set{UInt}}}
end

Base.length(net::Network) = 2^length(net.table)

S_POMBE = Network([
    (0b000000000, Set{UInt}()),
    (0b000011100, Set([0b000000000])),
    (0b100100111, Set([0b100000000,
                       0b000000100,
                       0b100000100,
                       0b100100100,
                       0b100000110,
                       0b100000101
                      ])),
    (0b100101011, Set([0b100000000,
                       0b000001000,
                       0b100001000,
                       0b100101000,
                       0b100001010,
                       0b100001001
                      ])),
    (0b000100000, Set([0b000100000])),
    (0b011011100, Set([0b010000000])),
    (0b101000010, Set([0b100000000,
                       0b001000000,
                       0b101000000,
                       0b101000010
                      ])),
    (0b110000010, Set([0b010000000,
                       0b000000010,
                       0b010000010,
                       0b110000010
                      ])),
    (0b000010000, Set([0b000010000]))
])

NET = Network([
    (0b111, Set([0b000, 0b010, 0b100, 0b110])),
    (0b111, Set([0b010, 0b100, 0b110, 0b111])),
    (0b111, Set([0b011, 0b101, 0b110, 0b111]))
])

Base.eltype(net::Network) = UInt

Base.iterate(net::Network) = (UInt(0b0), 1)
function Base.iterate(net::Network, state::Int)
    if state ≥ length(net)
        nothing
    else
        UInt(state), state + 1
    end
end

Base.in(net::Network, state::Unsigned) = zero(state) ≤ state < length(net)

function update(net::Network, state::Unsigned)
    if !(state in net)
        error("$state is not in the network")
    end
    next = UInt(0b0)
    for (i, (mask, activations)) in enumerate(net.table)
        next ⊻= UInt((state & mask) in activations) << (i - 1)
    end
    next
end

decode(x, n) = Int[1 & (x >> (i-1)) for i in 1:n]

function transitions(net::Network)
    trans = Array{UInt}(undef, length(net))
    for state in net
        trans[state + 1] = update(net, state) + 1
    end
    trans
end

function basins(net::Network)
    trans = transitions(net)
    visited = falses(length(trans))
    basins = zeros(Int, length(trans))
    basin_number = 1
    initial_state = UInt(0b1)
    while initial_state ≤ length(trans)
        stack = UInt[]
        state = initial_state
        next_state = trans[state]
        visited[state] = true
        while !visited[next_state]
            push!(stack, state)
            state = next_state
            next_state = trans[state]
            visited[state] = true
        end
        basin = if basins[next_state] == zero(Int)
            (basin_number += 1) - 1
        else
            basin = basins[next_state]
        end

        basins[state] = basin
        while !isempty(stack)
            next_state = state
            state = pop!(stack)
            basins[state] = basin
        end

        while initial_state ≤ length(visited) && visited[initial_state]
            initial_state += 1
        end
    end
    [UInt.(findall(basins .== i) .- 1) for i in 1:basin_number-1]
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

function invarianteq(state::Unsigned, n::Int)
    space = Space(n)
    bits = ones(Int, space.v)
    for (i, s) in enumerate(space)
        for (j, x) in enumerate(s)
            if x
                bits[i] &= (1 & state >> (j - 1))
            end
            if bits[i] == zero(bits[i])
                break
            end
        end
    end
    bits
end

function system(net::Network)
    N = length(net.table)
    A = zeros(Int, length(net) - 1, length(net))
    for (i, state) in enumerate(net)
        next = update(net, state)
        A[:,i] .= invarianteq(state, N) .⊻ invarianteq(next, N)
    end
    A
end

function prune(A::AbstractMatrix{Int})
    j = findfirst(collect(all(A[:,j] .== zero(Int)) for j in 1:size(A,2))) - 1
    @view A[:,1:j]
end

function dependent(B::AbstractMatrix{Int})
    T = Array(B')
    for j in 1:size(B,2)
        i = findfirst(B[:, j] .== one(Int)) + 1
        T[j, i:end] .= zero(Int)
    end
    T
end

function independent(T::AbstractMatrix{Int})
    idx = Int[]
    for j in 1:size(T,2)
        if all(T[:,j] .== zero(Int))
            push!(idx, j)
        end
    end
    U = zeros(Int, length(idx), size(T,2))
    for (i, j) in enumerate(idx)
        U[i, j] = 1
    end
    U, idx
end

function solve(A::Matrix{Int})
    @polyvar a[1:size(A,1)]
    B = prune(A)
    T = dependent(B)
    U, idx = independent(T)
    a, a .=> (a[idx]' * U * (I - B*T))'
end

const Factors = Dict{PolyVar{true}, Polynomial{true, Int}}

function freevars(xs::AbstractVector{PolyVar{true}}, terms::AbstractVector{Polynomial{true, Int}})
    sort!(setdiff(union(effective_variables.(terms)...), xs), rev=true)
end

function groupterms(xs, terms)
    factors = Factors()
    free = freevars(xs, terms)
    for v in free
        factors[v] = zero(keytype(factors))
    end
    for term in filter(t -> t != 0, terms)
        for m in monomials(term)
            vs = intersect(free, effective_variables(m))
            @assert length(vs) == 1
            factors[vs[1]] += m
        end
    end
    for (k, v) in factors
        factors[k] = mapcoefficientsnz(c -> c % 2, v)
    end
    factors
end

const SolSub = Pair{PolyVar{true}, Polynomial{true, Int}}

struct Invariant
    x::Vector{PolyVar{true}}
    a::Vector{PolyVar{true}}
    factors::Factors
end

function invariantterms(as::AbstractVector{PolyVar{true}})
    n = Int(log2(length(as) + 1))
    space = Space(n)
    @assert length(as) == length(space)
    @polyvar x[1:n]
    terms = zeros(Polynomial{true, Int}, space.v)
    for (i, (a, t)) in enumerate(zip(as, space))
        terms[i] = a * prod(x[t])
    end
    x, terms, as
end

function Invariant(a::AbstractVector{PolyVar{true}}, ss::AbstractVector{SolSub})
    x, terms = invariantterms(a)
    factors = groupterms(x, map(t -> subs(t, ss...), terms))
    Invariant(x, a, factors)
end

function Invariant(net::Network)
    A = system(net)
    elim!(A)
    invariant(solve(A)...)
end

function evaluate(ℰ::Invariant, state)
    E = zero(keytype(ℰ.factors))
    ss = ℰ.x .=> decode(state, length(ℰ.x))
    for p in values(ℰ.factors)
        E += subs(p, ss...)
    end
    mapcoefficientsnz(c -> c % 2, E)
end

Base.eltype(::Invariant) = Invariant
Base.length(::Invariant) = 1
Base.iterate(ℰ::Invariant) = (ℰ,1)
Base.iterate(ℰ::Invariant,x) = (x == 0) ? (ℰ,1) : nothing
