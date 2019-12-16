using DrWatson, DataFrames, Plots, Printf

include(srcdir("load.jl"))

function migif(df)
    grid = @sprintf "%dx%d" df[:gh] df[:gw]
    basepath = datadir("plots", joinpath(df[:drug], string(df[:trial]), grid, string(df[:nperms])))
    mkpath(basepath)
    mkpath(joinpath(basepath, "frames"))

    mi = df[:mi]
    miframes = []
    anim = @animate for i in eachindex(mi)
        p = heatmap(linearize(mi[i]), title="Lag: $(i - 1)", clim=(0,1))
        push!(miframes, p)
        p
    end

    for (i, p) in enumerate(miframes)
        framename = @sprintf "%02d_%s.png" (i-1) df[:phase]
        framefile = datadir(basepath, "frames", framename)
        savefig(p, framefile)
    end

    giffile = datadir(basepath, df[:phase] * ".gif")
    gif(anim, giffile, fps=0.5)
end

function main(dirname="info")
    df = collect_results!(datadir(dirname); subfolders=true)
    for row in eachrow(df)
        migif(row)
    end
end

@time main()
