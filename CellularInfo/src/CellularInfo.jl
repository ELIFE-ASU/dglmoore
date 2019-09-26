module CellularInfo

using Images, VideoIO

export EQUIVALENT_RULES, ECA_RULES
export simulate, tovideo, transferentropy

include("ca.jl")
include("te.jl")

function toimage(state, cellsize)
    img = fill(Gray(0.5), cellsize, length(state)*(cellsize + 1) - 1)
    for (i, x) in enumerate(state)
        img[1:cellsize, (cellsize*(i-1)+i):((cellsize + 1)*i-1)] .= Gray(x)
    end
    convert(Array{Gray{N0f8}}, img)
end

function tovideo(filename, series; cellwidth=10, framerate=25)
    frames = []
    for i in 1:size(series,1)
        push!(frames, toimage(series[i,:], cellwidth))
    end
    encodevideo(filename, frames, framerate=framerate)
end

end
