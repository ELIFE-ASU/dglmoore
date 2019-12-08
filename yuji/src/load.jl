using VideoIO, ColorTypes, Colors, FixedPointNumbers, Statistics

const Color = RGB{Normed{UInt8,8}}

const Frame = Array{Color, 2}

const ChannelFrame = Array{Float64, 2}

function block(xs::Vector{Array{T, 2}}) where {T}
    b = Array{T}(undef, size(first(xs))..., length(xs))
    for i in 1:length(xs)
       b[:, :, i] = xs[i] 
    end
    b
end

function frames(filename)
    r = openvideo(filename)
    frames = Frame[]
    while !eof(r)
        push!(frames, read(r))
    end
    block(frames)
end

for color in (:red, :green, :blue)
    c = Symbol(first(string(color)))
    @eval function ColorTypes.$color(f::AbstractArray{Color})
        r = Array{Float64}(undef, size(f)...)
        map!($color, r, f)
    end
end
colors(f::AbstractArray{Color}) = red(f), green(f), blue(f), map(c -> Float64(gray(convert(Gray, c))), f)

function coarse(agg::Function, frame::AbstractArray{T, 3}, n::Int, m::Int) where {T <: Real}
    cellheight, cellwidth, N = size(frame) .÷ (n, m, 1)
    coarse = Array{Float64}(undef, n, m, N)
    for i in 1:n, j in 1:m
        rows = (1:cellheight) .+ (i-1)*cellheight
        cols = (1:cellwidth) .+ (j-1)*cellwidth
        @inbounds coarse[i, j, :] = @views agg(frame[rows, cols, :], dims=(1,2))
    end
    coarse
end
coarse(frame::AbstractArray{T, 3}, n::Int, m::Int) where {T <: Real} = coarse(mean, frame, n, m)

squish(xs::AbstractArray) = if ndims(xs) == 1
    xs
elseif ndims(xs) == 2
    convert(Array{Float64},2), transpose(xs)
else
    ss = size(xs)
    convert(Array{Float64, 2}, transpose(reshape(xs, prod(ss[1:end-1]), ss[end])))
end

rescale(xs) = let (min, max) = extrema(xs)
    @. (xs - min) / (max - min)
end

linearize(xs::Array{T, 4}) where {T} = let (k, l, m, n) = size(xs)
    reshape(xs, k*l, m*n)
end