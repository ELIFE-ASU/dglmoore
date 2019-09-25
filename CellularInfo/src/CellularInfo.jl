module CellularInfo

export simulate, tovideo

include("te.jl")

using Images, VideoIO

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

function toimage(state, cellsize)
    img = fill(Gray(0.5), cellsize, length(state)*(cellsize + 1) - 1)
    for (i, x) in enumerate(state)
        img[1:cellsize, (cellsize*(i-1)+i):((cellsize + 1)*i-1)] .= Gray(x)
    end
    convert(Array{Gray{N0f8}}, img)
end

function simulate(rule, state::AbstractVector{Int}, t::Int)
    traj = [state]
    for _ in 1:t
        push!(traj, update!(traj[end][:], rule))
    end
    traj
end

function simulate(rule, width::Int, t::Int)
    state = zeros(Int, width)
    state[length(state) ÷ 2 + 1] = 1
    simulate(rule, state, t)
end

function tovideo(filename, series; cellwidth=10)
    encodevideo(filename, map(f -> toimage(f, cellwidth), series), framerate=25)
end

end
