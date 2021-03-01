using ExecutableSpecifications: suggestmissingsteps, ParseOptions

if length(ARGS) !== 2
    println("Usage: julia suggeststeps.jl <feature file> <steps root path>")
    exit(1)
end

featurefile = ARGS[1]
stepsrootpath = ARGS[2]

parseoptions = ParseOptions(allow_any_step_order=true)

suggestmissingsteps(featurefile, stepsrootpath, parseoptions=parseoptions)