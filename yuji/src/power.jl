using Distributions, NLsolve, Statistics

function effectsize(xs::AbstractVector, ys::AbstractVector)
    if length(xs) != length(ys)
        throw(ArgumentError("samples must have the same number of observations"))
    end
    n, m = length(xs), length(ys)
    x̄, ȳ = mean(xs), mean(ys)
    σx², σy² = var(xs), var(ys)
    σ = sqrt(0.5*(σx² + σy²))
    abs(x̄ - ȳ)/σ
end

function power(xs::AbstractVector, ys::AbstractVector, n::Int=length(xs), p::Float64=0.05; unequalvar=true)
    dof = if unequalvar
        varx, vary = var(xs), var(ys)
        nx, ny = length(xs), length(ys)
        (varx / nx + vary / ny)^2 / ((varx / nx)^2 / (nx - 1) + (vary / ny)^2 / (ny - 1))
    else
        length(xs) + length(ys) - 2
    end
    power(effectsize(xs, ys), n, dof, p)
end
 
function power(d::Float64, n::Int=length(xs), dof=2n-2, α::Float64=0.05)
    δ = d*sqrt(n/2)
    tc = quantile(TDist(dof), 1 - α/2)
    ccdf(NoncentralT(dof, δ), tc) + cdf(NoncentralT(dof, δ), -tc)
end

function power(d::Float64, n::Float64=length(xs), dof=2n-2, α::Float64=0.05)
    δ = d*sqrt(n/2)
    tc = quantile(TDist(dof), 1 - α/2)
    ccdf(NoncentralT(dof, δ), tc) + cdf(NoncentralT(dof, δ), -tc)
end

function solvepower(d::Float64, dof::Float64, β::Float64=0.8, α::Float64=0.05)
    first(nlsolve((F,x) -> F[1] = power(d, x[1], dof, α) - β, [2.0]).zero)
end

function solvepower(xs::AbstractVector, ys::AbstractVector, β::Float64=0.8, α::Float64=0.05; unequalvar=true)
    dof = if unequalvar
        varx, vary = var(xs), var(ys)
        nx, ny = length(xs), length(ys)
        (varx / nx + vary / ny)^2 / ((varx / nx)^2 / (nx - 1) + (vary / ny)^2 / (ny - 1))
    else
        length(xs) + length(ys) - 2
    end
    solvepower(effectsize(xs, ys), dof, β, α)
end