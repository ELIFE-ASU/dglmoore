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
    greengrid = coarse(greenchannel, grid...)
    mi = analyze(greengrid; nperms=nperms)

    infopath = joinpath(outdir, join(string.(grid), "x"), string(nperms))
    mkpath(dirname(infopath))
    writedlm(infopath, hcat(linearize.(mi)...))
end

function main(filename; outdir="data")
    for nperms in [1000]
        for (m, n) in [(1,5), (5,1), (1,10), (10,1), (32,1), (1,32), (5,5), (10,10), (32,32)]
            @info "Evaluating grid $((m, n))"
            @time main(filename, (m, n), nperms; outdir=outdir, crop = [57:456, 61:460, :])
        end
    end
end

@time main(args["video"]; outdir=args["outdir"])
