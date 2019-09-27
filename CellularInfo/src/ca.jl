yflip(a::Int) = let D = [0,4,2,6,1,5,3,7]
    reduce(|, ((1 & (a >> (i - 1))) << D[i] for i in 1:8))
end

complement(a::Int) = reduce(|, ((1 ⊻ (1 & (a >> ((i-1) ⊻ 7)))) << (i - 1) for i in 1:8))

canonical(a::Int) = min(a, yflip(a), complement(a), complement(yflip(a)))

const EQUIVALENT_RULES = Dict(c => (yflip(c), complement(c), complement(yflip(c))) for c in 0:255)
const ECA_RULES = [Set(vcat(map(canonical, 0:255)))...]
const ECA_CLASS_I = [0,8,32,40,128,136,160,168]
const ECA_CLASS_III = [18,22,30,45,60,90,105,122,126,146,150]
const ECA_CLASS_IV = [54,106,110]
const ECA_CLASS_II = setdiff(ECA_RULES, ECA_CLASS_I, ECA_CLASS_III, ECA_CLASS_IV)

@assert ECA_CLASS_I ⊆ ECA_RULES
@assert ECA_CLASS_III ⊆ ECA_RULES
@assert ECA_CLASS_IV ⊆ ECA_RULES
@assert length(ECA_CLASS_II) == 66

function update!(state, rule)
    if length(state) < 2
        throw(DomainError(length(state), "update! requires that length(state) ≥ 2"))
    end
    left = state[end]
    right = state[1]
    temp = 2 * left + state[1]
    for i in 2:length(state)
        temp = 7 & (2 * temp + state[i])
        state[i - 1] = 1 & (rule >> temp)
    end
    temp = 7 & (2 * temp + right)
    state[end] = 1 & (rule >> temp)

    state
end

function simulate(rule, state::AbstractVector{Int}, t::Int)
    traj = Array{Int}(undef, t + 1, length(state))
    traj[1,:] = state
    for i in 1:t
        traj[i + 1, :] = update!(traj[i,:], rule)
    end
    traj
end

function simulate(rule, width::Int, t::Int)
    state = zeros(Int, width)
    state[length(state) ÷ 2 + 1] = 1
    simulate(rule, state, t)
end
