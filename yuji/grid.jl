using ArgParse

const aps = ArgParseSettings(version="1.0", add_version=true)

add_arg_group(aps, "Input and Output")
@add_arg_table aps begin
    "video"
        help = "path to the video to process"
        required = true
    "--outdir"
        help = "output directory"
        arg_type = String
        default = "data"
end

add_arg_group(aps, "Worker Process Control")
@add_arg_table aps begin
    "--procs"
        help = "number of worker processes; must be non-negative"
        arg_type = Int
        default = 0
        range_tester = p -> p ≥ 0
    "--slurm"
        help = "use the SLURM cluster manager"
        action = :store_true
end

args = parse_args(ARGS, aps)

if args["procs"] != 0
    using Distributed
    if args["slurm"]
        using ClusterManagers
        addprocs(SlurmManager(args["procs"]))
    else
        addprocs(args["procs"])
    end
end

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
    for nperms in [100, 1000, 10000, 100000]
        for (m, n) in [(1,10), (10,1), (10,10)]
            f = @spawn main(filename, (m, n), nperms;
                            outdir=outdir, crop = [57:456, 61:460, :])
            push!(futures, f)
        end
    end
    foreach(wait, futures)
end

@time main(args["video"]; outdir=args["outdir"])
