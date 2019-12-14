using ArgParse, Distributed

const aps = ArgParseSettings(version="1.0", add_version=true)

add_arg_group(aps, "Input and Output")
@add_arg_table aps begin
    "input"
        help = "path to the video or directory to process"
        required = true
end

add_arg_group(aps, "Evaluation Parameters")
@add_arg_table aps begin
    "--nperms"
        help = "number of permutations to use for significance testing"
        arg_type = Int
        default = 100000
        range_tester = p -> p > 0
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

@everywhere function process(filename::AbstractString, grid::NTuple{2,Int}, nperms::Int;
                             outdir="data", crop=nothing)
    fs = frames(filename)
    if !isnothing(crop)
        fs = fs[crop...]
    end
    greenchannel = green(fs)
    greengrid = coarse(greenchannel, grid...)
    mi = analyze(greengrid; nperms=nperms)

    infopath = joinpath(outdir, join(string.(grid), "x"), string(nperms), "info.txt")
    mkpath(dirname(infopath))
    writedlm(infopath, hcat(linearize.(mi)...))
end

function process(filename, nperms; outdir="data")
    futures = Future[]
    for (m, n) in [(1,5), (5,1), (1,10), (10,1), (30,1), (1,30), (5,5), (10,10), (30,30)]
        f = @spawn process(filename, (m, n), nperms; outdir=outdir, crop=[57:456, 61:460, :])
        push!(futures, f)
    end
    foreach(wait, futures)
end

ismov(f) = last(splitext(f)) == ".mov"

function main(input, nperms)
    if isfile(input) && ismov(input)
        dir = dirname(input)
        base = first(splitext(basename(input)))
        process(input, nperms; outdir=joinpath(dir, base))
    elseif isdir(input)
        futures = Future[]
        for (root, _, files) in walkdir(input)
            for file in filter(ismov, files)
                push!(futures, @spawn main(joinpath(root, file), nperms))
            end
        end
        if isempty(futures)
            @warn "no valid movie file found in $input"
        else
            foreach(wait, futures)
        end
    else
        @error "\"$input\"' is not a valid movie file path"
    end
end
@time main(args["input"], args["nperms"])
