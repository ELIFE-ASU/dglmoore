module EMD

using Dierckx

export emd

function emd(x::Vector{Float64})
    c = x[:]
    N = length(c)
    imf = []
    while true
        h = c
        sd = 1

        maxmin = []

        while sd > 0.3
            d = diff(h)
            maxmin = []
            for i in 1:N-2
                if d[i] == 0
                    push!(maxmin, i)
                elseif sign(d[i]) != sign(d[i+1])
                    push!(maxmin, i + 1)
                end
            end

            if length(maxmin) < 2
                break
            end


            if maxmin[1] > maxmin[2]
                maxes = maxmin[1:2:end]
                mins  = maxmin[2:2:end]
            else
                maxes = maxmin[2:2:end]
                mins  = maxmin[1:2:end]
            end

            maxes = [1, maxes..., N];
            mins  = [1, mins..., N];

            k = min(3, length(maxes)-1)
            maxenv = Spline1D(maxes, h[maxes]; k=k)(1:N)
            minenv = Spline1D(mins, h[mins]; k=k)(1:N)

            m = (maxenv + minenv) / 2
            prevh = h[:]
            h = h - m

            eps = 1e-7
            sd = sum(((prevh - h).^2) ./ (prevh.^2 .+ eps))
        end

        push!(imf, h)

        if length(maxmin) < 2
            break
        end

        c -= h
    end

    imf, c
end

end # module
