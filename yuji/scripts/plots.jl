using DataFrames, DrWatson, LinearAlgebra, Parameters, Printf
using Query, SparseArrays, Statistics, StatsPlots

include(srcdir("load.jl"))

function results(col, fields::Symbol...)
    tempcol = Symbol(string(col) * "-sparse")
    
    df = collect_results(datadir("info", string(col)); verbose=false)
    disallowmissing!(df)

    select!(df, [:drug, :trial, :gh, :gw, :phase, fields..., col])

    df[!, :gridsize] = (df[:, :gh] .* df[:, :gw]).^2
    df[!, tempcol] = (sparse∘linearize).(df[:, col])
    df[!, :nnz] = nnz.(df[:, tempcol])
    df[!, :eigen] = (real ∘ last ∘ first ∘ eigen ∘ linearize).(df[:, col])
    
    select!(df, Not(col))
    rename!(df, Dict(tempcol => col))
    df
end

macro infoplot(df, xcol::QuoteNode, ycol::QuoteNode, xlabel::String, ylabel::String,
               legend::Union{QuoteNode,Bool}=:(:topright))
    quote
        kf = $df |> @filter(_.drug == "K-gluconate")
        knf = $df |> @filter(_.drug == "K-gluconate:Nifedipine")
        
        marker=(:circ, 4, 1.0)
        color=[3 4]
        α=0.5

        kplot = @df kf dotplot($xcol, $ycol, group=:phase, marker=marker, color=color, label="")
        @df kf violin!(kplot, $xcol, $ycol, group=:phase, α=α, color=color)

        knplot = @df knf dotplot($xcol, $ycol, group=:phase, marker=marker, color=color, label="")
        @df knf violin!(knplot, $xcol, $ycol, group=:phase, α=α)

        xmin, xmax = extrema($df[:,$xcol])

        plot(kplot, knplot, layout=2, title=["K-gluconate" "K-gluconate + Nifedipine"], titleloc=:left,
             xlabel=$xlabel, xticks=xmin:xmax, ylabel=$ylabel, size=(1000,500), legend=$legend)
    end
end

macro infoplot(xcol::QuoteNode, ycol::QuoteNode, xlabel::String, ylabel::String, legend::Union{QuoteNode,Bool}=:(:topright))
    :(df -> @infoplot df $xcol $ycol $xlabel $ylabel $legend)
end

function mutualinfo()
    @time mi = results(:mi, :lag)
    groups = groupby(mi, [:gh, :gw])

    for key in keys(groups)
        @unpack gh, gw = NamedTuple(key)

        @info "plotting mutual information for " gh gw

        basepath = projectdir("plots", "info", (@sprintf "%dx%d" gh gw), "mi")
        mkpath(basepath)

        g = groups[key]

        p = g |> @infoplot :lag :eigen "Lag" "Largest Eigenvalue"
        savefig(p, joinpath(basepath, "eigen.svg"))

        p = g |> @infoplot :lag :nnz "Lag" "Number of Nonzero Values"
        savefig(p, joinpath(basepath, "nnz.svg"))

        p = g |> @map({_.drug, _.trial, _.phase, _.lag, μ=mean(_.mi)}) |>
                 DataFrame |>
                 @infoplot :lag :μ "Lag" "Average MI"
        savefig(p, joinpath(basepath, "mean.svg"))

        p = g |> @map({_.drug, _.trial, _.phase, _.lag, μ=mean(nonzeros(_.mi))}) |>
                 @map({_.drug, _.trial, _.phase, _.lag, μ=isnan(_.μ) ? zero(_.μ) : _.μ}) |>
                 DataFrame |>
                 @infoplot :lag :μ "Lag" "Average Nonzero MI" :bottomright
        savefig(p, joinpath(basepath, "mean-nz.svg"))
    end
end

function transferentropy()
    @time te = results(:te, :k)
    groups = groupby(te, [:gh, :gw])

    for key in keys(groups)
        @unpack gh, gw = NamedTuple(key)

        @info "plotting tranfer entropy for " gh gw

        basepath = projectdir("plots", "info", (@sprintf "%dx%d" gh gw), "te")
        mkpath(basepath)

        g = groups[key]

        p = g |> @infoplot :k :eigen "History Length" "Largest Eigenvalue" :bottomright
        savefig(p, joinpath(basepath, "eigen.svg"))

        p = g |> @infoplot :k :nnz "History Length" "Number of Nonzero Values" :bottomright
        savefig(p, joinpath(basepath, "nnz.svg"))

        p = g |> @map({_.drug, _.trial, _.phase, _.k, μ=mean(_.te)}) |>
                 DataFrame |>
                 @infoplot :k :μ "History Length" "Average TE" :bottomright
        savefig(p, joinpath(basepath, "mean.svg"))

        p = g |> @map({_.drug, _.trial, _.phase, _.k, μ=mean(nonzeros(_.te))}) |>
                 @map({_.drug, _.trial, _.phase, _.k, μ=isnan(_.μ) ? zero(_.μ) : _.μ}) |>
                 DataFrame |>
                 @infoplot :k :μ "History Length" "Average Nonzero TE" :bottomright
        savefig(p, joinpath(basepath, "mean-nz.svg"))
    end
end

mutualinfo()
transferentropy()
