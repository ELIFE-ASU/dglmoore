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
    @unpack drug, phase, trial, gw, gh, mi, nperms = df

    grid = @sprintf "%dx%d" gh gw
    basepath = projectdir("plots", drug, string(trial), grid, string(nperms))
    mkpath(basepath)
    mkpath(joinpath(basepath, "frames"))

    miframes = []
    anim = @animate for i in eachindex(mi)
        title = if i == 1
            "Mutual Information (phase = $phase)"
        elseif i == 2
            "Mutual Information (phase = $phase), lag = $(i-1) frame)"
        else
            "Mutual Information (phase = $phase), lag = $(i-1) frames)"
        end

        p = heatmap(linearize(mi[i]),
                    title=title,
                    titleloc=:left,
                    xlabel="source cell",
                    ylabel="target cell",
                    clim=(0,1))
        push!(miframes, p)
        p
    end

    for (i, p) in enumerate(miframes)
        framename = @sprintf "%02d-%s.png" (i-1) phase
        framefile = joinpath(basepath, "frames", framename)
        savefig(p, framefile)
    end

    giffile = joinpath(basepath, df[:phase] * "-mi.gif")
    gif(anim, giffile, fps=0.5)
end

function main(dirname="info")
    df = collect_results!(datadir(dirname); subfolders=true)
    for row in eachrow(df)
        migif(row)
    end
    for row in eachrow(df[:,[:drug,:trial,:phase,:gh,:gw,:videopath]])
        coarsegif(row)
        binnedgif(row)
    end
end

@time main()
