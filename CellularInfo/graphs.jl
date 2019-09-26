using CellularInfo, JSON

graphs = Dict{Int,Vector{Tuple{Int,Int}}}()
for rule in 0:255
    @time begin
        @info "Building graph for $(rule)..."
        k = 1
        width = 11
        duration = 2^width

        traj = simulate(rule, width, duration)

        edges = []
        @time for src in 1:width
            for dst in 1:width
                if src == dst
                    continue
                end
                back = filter(f -> f != src && f != dst, 1:width)
                cond = traj[:,back]
                te = transferentropy(traj[:,src], traj[:,dst], cond', k, 1000)
                if te.p < 0.05
                    push!(edges, (src, dst))
                end
            end
        end
        graphs[rule] = sort!(edges)
    end
end

open("graphs.json", "w") do handle
    JSON.print(handle, graphs)
end
