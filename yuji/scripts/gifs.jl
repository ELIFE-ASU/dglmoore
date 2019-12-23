using DrWatson, DataFrames, Plots, Printf, Parameters

include(srcdir("load.jl"))
include(srcdir("binning.jl"))

function binnedgif(df)
    @unpack drug, phase, trial, gw, gh, videopath = df

    basepath = projectdir("plots", drug, string(trial), @sprintf "%dx%d" gh gw)
    mkpath(basepath)

    greenchannel = datadir(videopath) |> frames |> fs -> crop(fs, 400, 400, :) |> green
    greenbinned = coarse(greenchannel, gh, gw) |> rescale |> bin

    anim = @animate for t in 1:size(greenbinned, 3)
        title = @sprintf "Binned %s %s, Trial %d; Frame: %d" titlecase(phase) drug trial t
        heatmap(greenbinned[:,:,t] .- 1,
                title = title,
                titleloc = :left,
                clim = (0,1))
    end

    giffile = joinpath(basepath, phase * "-binned.gif")
    gif(anim, giffile, fps=10)
end

function coarsegif(df)
    @unpack drug, phase, trial, gw, gh, videopath = df

    basepath = projectdir("plots", drug, string(trial), @sprintf "%dx%d" gh gw)
    mkpath(basepath)

    greenchannel = datadir(videopath) |> frames |> fs -> crop(fs, 400, 400, :) |> green
    greengrid = coarse(greenchannel, gh, gw) |> rescale

    anim = @animate for t in 1:size(greengrid, 3)
        title = @sprintf "%s %s, Trial %d; Frame: %d" titlecase(phase) drug trial t
        heatmap(greengrid[:,:,t],
                title = title,
                titleloc = :left,
                clim = (0,1))
    end

    giffile = joinpath(basepath, phase * ".gif")
    gif(anim, giffile, fps=10)
end

function migif(df)
    simdata = first(unique(select(df, :drug, :phase, :trial, :gw, :gh, :nperms)))
    @unpack drug, phase, trial, gw, gh, nperms = simdata

    grid = @sprintf "%dx%d" gh gw
    basepath = projectdir("plots", drug, string(trial), grid, string(nperms))
    mkpath(basepath)
    mkpath(joinpath(basepath, "frames", "mi"))

    mis = sort(select(df, :lag, :mi), :lag)

    miframes = []
    anim = @animate for row in eachrow(mis)
        @unpack lag, mi = row

        title = if lag == 0
            @sprintf "Mutual Info %s %s" titlecase(phase) drug
        elseif lag == 1
            @sprintf "Mutual Info %s %s; Lagged %d Frame" titlecase(phase) drug lag
        else
            @sprintf "Mutual Info %s %s; Lagged %d Frames" titlecase(phase) drug lag
        end

        p = heatmap(linearize(mi),
                    title=title,
                    titleloc=:left,
                    xlabel="target cell",
                    ylabel="source cell",
                    clim=(0,1))
        push!(miframes, p)
        p
    end

    for (i, p) in enumerate(miframes)
        framename = @sprintf "%d-%s.png" (i-1) phase
        framefile = joinpath(basepath, "frames", "mi", framename)
        savefig(p, framefile)
    end

    giffile = joinpath(basepath, phase * "-mi.gif")
    gif(anim, giffile, fps=0.5)
end

function tegif(df)
    simdata = first(unique(select(df, :drug, :phase, :trial, :gw, :gh, :nperms)))
    @unpack drug, phase, trial, gw, gh, nperms = simdata

    grid = @sprintf "%dx%d" gh gw
    basepath = projectdir("plots", drug, string(trial), grid, string(nperms))
    mkpath(basepath)
    mkpath(joinpath(basepath, "frames", "te"))

    tes = sort(select(df, :k, :te), :k)

    teframes = []
    anim = @animate for row in eachrow(tes)
        @unpack k, te = row

        title = @sprintf "Transfer Entropy %s %s; k=%d" titlecase(phase) drug k

        p = heatmap(linearize(te),
                    title=title,
                    titleloc=:left,
                    xlabel="target cell",
                    ylabel="source cell",
                    clim=(0,1))
        push!(teframes, p)
        p
    end

    for (i, p) in enumerate(teframes)
        framename = @sprintf "%d-%s.png" i phase
        framefile = joinpath(basepath, "frames", "te", framename)
        savefig(p, framefile)
    end

    giffile = joinpath(basepath, phase * "-te.gif")
    gif(anim, giffile, fps=0.5)
end

function main()
    df = collect_results(datadir("info", "mi"))
    for group in groupby(df, [:drug, :trial, :phase, :gh, :gw])
        migif(group)
    end
    df = collect_results(datadir("info", "te"))
    for group in groupby(df, [:drug, :trial, :phase, :gh, :gw])
        tegif(group)
    end
    for group in eachrow(unique(select(df, :drug, :trial, :phase, :gh, :gw, :videopath)))
        coarsegif(group)
        binnedgif(group)
    end
end

@time main()
