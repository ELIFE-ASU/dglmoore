using ArgParse, Distributed, DrWatson

const aps = ArgParseSettings(version="1.0", add_version=true)

add_arg_group(aps, "Input and Output")
@add_arg_table aps begin
    "input"
        help = "path to the video or directory to process"
        arg_type = String
        default = datadir("videos")
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

    @everywhere begin
        using Pkg
        Pkg.activate(".")
    end
end

@everywhere begin
    using Base.Iterators, DelimitedFiles, DrWatson

    include("src/load.jl")
    include("src/info.jl")
    include("src/binning.jl")
    include("src/analysis.jl")
end

@everywhere filename(path::AbstractString) = basename(first(splitext(path)))

@everywhere function str2sym(d::Dict{String})
    e = Dict{Symbol,Any}()
    for (k, v) in d
        e[Symbol(k)] = v
    end
    e
end

@everywhere function process(filepath::AbstractString, grid::NTuple{2,Int}, nperms::Int;
                             crops=nothing)
    data = str2sym(parse_savename(filepath)[2])
    merge!(data, Dict(:gh => first(grid), :gw => last(grid), :nperms => nperms))
    path = datadir("info", savename(data, "bson"))

    @info "Processing" from=filepath to=path parameters=data

    fs = frames(filepath)
    if !isnothing(crops)
        fs = crop(fs, crops...)
    end
    greenchannel = green(fs)
    greengrid = coarse(greenchannel, grid...)

    data[:mi] = analyze(greengrid; nperms=nperms)
    data[:videopath] = relpath(filepath, datadir())

    @tagsave path data safe=true
end

function process(filepath, nperms)
    for grid in [(1,5), (5,1), (1,10), (10,1), (30,1), (1,30), (5,5), (10,10), (30,30)]
        process(filepath, grid, nperms; crops=(400, 400, :))
    end
end

ismov(f) = last(splitext(f)) == ".mov"

function main(input, nperms)
    input = abspath(input)
    if isfile(input) && ismov(input)
        process(input, nperms)
    elseif isdir(input)
        video_found = false
        for (root, _, files) in walkdir(input)
            for file in filter(ismov, files)
                video_found = true
                process(joinpath(root, file), nperms)
            end
        end
        if !video_found
            @warn "no valid movie file found in $input"
        end
    else
        @error "\"$input\" is not a path to a video file or directory"
    end
end

@time main(args["input"], args["nperms"])
