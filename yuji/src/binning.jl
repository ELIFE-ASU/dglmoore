divodd(a, b) = let u = a ÷ b
    if u < 3
        3
    elseif iseven(u)
        u + 1
    else
        u
    end
end

function mwmean(mean::Function, xs::Matrix, mw::Int)
    n, m = size(xs)
    result = Matrix{eltype(xs)}(undef, n-mw+1, m)
    for i in 1:size(xs, 1)-mw+1
        result[i,:] = mean(xs[(i-1).+(1:mw), :]; dims=1)
    end
    result
end

mwmean(xs::Matrix, mw::Int) = mwmean(mean, xs, mw)

function bin(frames::Array{Float64, 3}; mw=divodd(size(frames, 3), 10))
    n, m, t = size(frames)
    binned = bin(squish(frames); mw=mw)
    reshape(transpose(binned), n, m, t - mw + 1)
end

function bin(frames::Matrix{Float64}; mw=divodd(size(frames, 1), 10))
    bound = abs.(mwmean(mean, frames, mw)) .+ mwmean(std, frames, mw)
    binned = Int.(bound .< abs.(frames[(1+mw÷2):size(frames, 1)-mw÷2,:])) .+ 1 
end
