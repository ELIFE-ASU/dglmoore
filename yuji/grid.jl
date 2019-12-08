using Distributed, DelimitedFiles

@everywhere begin
    using Pkg
    Pkg.activate(".")
    using Base.Iterators, DelimitedFiles
    include("src/load.jl")
    include("src/info.jl")
    include("src/binning.jl")
    include("src/analysis.jl")
end

@everywhere function main(filename::AbstractString, grid::NTuple{2,Int}, nperms::Int;
                          outdir="data", crop=nothing)
    fs = frames(filename)
    if !isnothing(crop)
        fs = fs[crop...]
    end
    greenchannel = green(fs)
    greengrid = gridmean(greenchannel, grid...)
    mi = analyze(greengrid; nperms=nperms)

    infopath = joinpath(outdir, join(string.(grid), "x"), string(nperms))
    mkpath(dirname(infopath))
    writedlm(infopath, hcat(linearize.(mi)...))
end

function main(filename; outdir="data")
    futures = Future[]
    for nperms in [100]
        for (m, n) in [(1,10), (10,1), (10,10)]
            f = @spawn main(filename, (m, n), nperms;
                            outdir=outdir, crop = [57:456, 61:460, :])
            push!(futures, f)
        end
    end
    foreach(wait, futures)
end

@time main("videos/Before2-MPGC.mov")
