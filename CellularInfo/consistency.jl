using CellularInfo, JSON

graphs = open("graphs.json", "r") do handle
    graphs = Dict{Int, Vector{Tuple{Int,Int}}}()
    for (k, v) in JSON.parse(handle)
        graphs[parse(Int, k)] = map(x -> tuple(x...), v)
    end
    graphs
end

for (rule, class) in EQUIVALENT_RULES
    for partner in class
        if graphs[rule] != graphs[partner]
            println("$rule != $(partner)")
            println(graphs[rule])
            println(graphs[partner])
        end
    end
end
