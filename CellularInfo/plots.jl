using CellularInfo, JSON, Plots, Plots.PlotMeasures

function plotit(basename)
    μ = open(JSON.parse, "$basename.json")
    class1 = μ[ECA_CLASS_I .+ 1]
    class2 = μ[ECA_CLASS_II .+ 1]
    class3 = μ[ECA_CLASS_III .+ 1]
    class4 = μ[ECA_CLASS_IV .+ 1]

    c12 = max(maximum(class1), maximum(class2))

    @show maximum(class1)
    @show maximum(class2)
    @show maximum(class3)
    @show maximum(class4)

    p = scatter(ECA_CLASS_I, class1, markershape=:cross, markercolor=:black, label="Class I", left_margin=1cm, bottom_margin=8mm)
    scatter!(p, ECA_CLASS_II, class2, markershape=:xcross, markercolor=:black, label="Class II")
    scatter!(p, ECA_CLASS_III, class3, markershape=:rect, markercolor=:green, label="Class III")
    scatter!(p, ECA_CLASS_IV, class4, markershape=:rect, markercolor=:orange, label="Class IV")
    hline!(p, [c12], linestyle=:dash, label="Class I & II Limit")
    xlabel!(p, "Rule")
    ylabel!(p, "Mean TE")
    title!(p, "Mean TE vs Rule by Wolfram Class")
    savefig(p, "$basename.png")
end

plotit("onepoint")
#  plotit("random")
