using ExecutableSpecifications: parseonly
using ExecutableSpecifications.Gherkin: ParseOptions

if length(ARGS) !== 1
    println("Usage: julia parseonly.jl <root-directory>")
    exit(1)
end

parseoptions = ParseOptions(allow_any_step_order=true)

results = parseonly(ARGS[1], parseoptions=parseoptions)
num_files = length(results)
num_success = count(x -> x.success === true, results)
if num_success === num_files
    println("All good!")
else
    num_failed = num_files - num_success
    println("Files failed parsing:")
    for rs in results
        print(rs.filename)

        if rs.success
            println(": OK")
        else
            println()
            println(" reason: ", rs.result.reason)
            println(" expected: ", rs.result.expected)
            println(" actual: ", rs.result.actual)
            println(" line $(rs.result.linenumber): $(rs.result.line)")
        end
    end
    println("Parsing failed: ", num_failed)
    println("Total number of files: ", num_files)
end