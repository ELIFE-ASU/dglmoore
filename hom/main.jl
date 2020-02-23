using XLSX, DataFrames, Discretizers

normalize(xs) = xs ./ sum(xs)

#  map(df -> by(df, :KO, count=(:KO => length)), frames)

function kos(filename::AbstractString, i=Colon())
    excel = XLSX.openxlsx(filename)
    sheets = XLSX.sheetnames(excel)[i]
    frames = map(s -> DataFrame(XLSX.gettable(excel[s])...), sheets)
    dropmissing!.(select!.(frames, :KO), disallowmissing=true)
end

function bootstrap(df, col, n)
    gf = DataFrame(Symbol(string(col) * "0") => df[:,col])
    for i in 1:n
        gf[!,Symbol(string(col) * string(i))] = rand(df[:,col], length(df[:,col]))
    end
    gf
end

function genus(filename::AbstractString, i=Colon())
    excel = XLSX.openxlsx(filename)
    sheets = XLSX.sheetnames(excel)[i]
    map(sheets) do sheet
        column = filter(!ismissing, excel[sheet]["J"])
        name, values = Symbol(column[1]), column[2:end]
        df = dropmissing!(DataFrame(name => values), disallowmissing=true)
        df[!,name] = strip.(df[:,name])
        sort!(df)
    end
end
