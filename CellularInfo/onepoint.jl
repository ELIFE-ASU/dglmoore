using Distributed, JSON

@everywhere begin
    using Pkg
    Pkg.activate(".")
end

@everywhere using CellularInfo

@everywhere function transfer(traj, src, dst, k)
    #  back = filter(f -> f != src && f != dst, 1:size(traj,2))
    #  cond = traj[:,back]
    #  transferentropy(traj[:,src], traj[:,dst], cond', k, 1000)
    transferentropy(traj[:,src], traj[:,dst], k, 1000)
end

function main()
    meante = zeros(Float64, 256)
    for rule in 0:255
        @time begin
            @info "Building graph for $(rule)..."
            k = 5
            width = 101
            duration = 200 + (width ÷ 2)

            a = zeros(Int, width)
            b = ones(Int, width)
            a[width ÷ 2 + 1] = 1
            b[width ÷ 2 + 1] = 0

            traja = simulate(rule, a, duration)[width ÷ 2 + 1:end,:]
            trajb = simulate(rule, b, duration)[width ÷ 2 + 1:end,:]

            N = 2*width*(width - 1)
            μ = 0.0
            for src in 1:width
                μ += @distributed (+) for dst in 1:width
                    if src == dst
                        0.0
                    else
                        tea = transfer(traja, src, dst, k)
                        teb = transfer(trajb, src, dst, k)

                        te = (tea.p < 0.05) ? tea.value : 0.0
                        te += (teb.p < 0.05) ? teb.value : 0.0
                    end
                end
            end
            meante[rule + 1] = μ / N
        end
    end

    open("onepoint.json", "w") do handle
        JSON.print(handle, meante)
    end
end

main()
