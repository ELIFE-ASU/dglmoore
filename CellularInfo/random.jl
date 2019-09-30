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
            samples = 10

            N = 4*samples*width*(width - 1)
            μ = 0.0
            for _ in 1:samples
                a = convert(Array{Int}, rand(Bool, width))
                b = 1 .- a
                c = reverse(a)
                d = reverse(b)

                traja = simulate(rule, a, duration)[width ÷ 2 + 1:end,:]
                trajb = simulate(rule, b, duration)[width ÷ 2 + 1:end,:]
                trajc = simulate(rule, a, duration)[width ÷ 2 + 1:end,:]
                trajd = simulate(rule, b, duration)[width ÷ 2 + 1:end,:]

                for src in 1:width
                    μ += @distributed (+) for dst in 1:width
                        if src == dst
                            0.0
                        else
                            tea = transfer(traja, src, dst, k)
                            teb = transfer(trajb, src, dst, k)
                            tec = transfer(trajc, src, dst, k)
                            ted = transfer(trajc, src, dst, k)

                            te = (tea.p < 0.05) ? tea.value : 0.0
                            te += (teb.p < 0.05) ? teb.value : 0.0
                            te += (tec.p < 0.05) ? tec.value : 0.0
                            te += (ted.p < 0.05) ? ted.value : 0.0
                        end
                    end
                end
            end
            meante[rule + 1] = μ / N
        end
    end

    open("rand.json", "w") do handle
        JSON.print(handle, meante)
    end
end

main()
