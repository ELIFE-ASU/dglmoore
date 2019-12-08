using Plots, DelimitedFiles

function migif(filepath; outdir=dirname(filepath))
    raw = readdlm(filepath)
    n, m = size(raw)
    grid = reshape(raw, n, n, m ÷ n)

    anim = @animate for i in 1:size(grid, 3)
        heatmap(grid[:, :, i], title="Lag: $(i - 1)", clim=(0,1))
    end
    giffile = joinpath(outdir, first(splitext(basename(filepath))) * ".gif")
    gif(anim, giffile, fps=0.25)
end

istxt(filepath) = last(splitext(filepath)) == ".txt"

function main(dirname)
    for (root, _, files) in walkdir(dirname)
        for file in files
            filepath = joinpath(root, file)
            if istxt(filepath)
                @info "Processing $filepath..."
                migif(filepath)
            end
        end
    end
end

foreach(main, ["10x1", "1x10", "10x10"])
