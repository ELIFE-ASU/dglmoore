source = ARGS[1]
plugin = ARGS[2]

include(source)

mod = eval(Meta.parse(plugin))
println(mod.entryPoint())
