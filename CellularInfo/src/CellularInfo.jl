module CellularInfo

export simulate

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

function simulate(rule; width=21, cellwidth=10, outdir=".")
    state = zeros(Int, width)
    state[width ÷ 2 + 1] = 1
    frames = [toimage(state, cellwidth)]
    for i in 0:1000
        push!(frames, toimage(update!(state, rule), cellwidth))
    end

    outfile = joinpath(outdir, "rule$(rule).avi")
    encodevideo(outfile, frames, framerate=25)
end

end
