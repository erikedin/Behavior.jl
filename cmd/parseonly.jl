using ExecutableSpecifications: parseonly

if length(ARGS) !== 1
    println("Usage: julia parseonly.jl <root-directory>")
    exit(1)
end

results = parseonly(ARGS[1])
num_files = length(results)
num_success = count(x -> x.success === true, results)
if num_success === num_files
    println("All good!")
else
    num_failed = num_files - num_success
    println("Files failed parsing:")
    for rs in results
        println(rs.filename)
        println(" reason: ", rs.result.reason)
        println(" expected: ", rs.result.expected)
        println(" actual: ", rs.result.actual)
    end
    println("Parsing failed: ", num_failed)
    println("Total number of files: ", num_files)
end