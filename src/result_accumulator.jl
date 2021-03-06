"""
Combine a feature along with the number of scenario successes and failures.
"""
struct FeatureSuccessAndFailure
    feature::Feature
    n_success::UInt
    n_failure::UInt
end

"""
Accumulate results from executed features as they are being executed. Keep track of whether the
total run is a success of a failure.
"""
mutable struct ResultAccumulator
    isaccumsuccess::Bool
    features::Vector{FeatureSuccessAndFailure}
    errors::Vector{Gherkin.BadParseResult{Feature}}

    ResultAccumulator() = new(true, [], [])
end

"""
    accumulateresult!(acc::ResultAccumulator, result::FeatureResult)

Check for success or failure in this feature result and update the accumulator accordingly.
"""
function accumulateresult!(acc::ResultAccumulator, result::FeatureResult)
    n_success::UInt = 0
    n_failure::UInt = 0
    # Count the number of successes and failures for each step in each scenario. A scenario is
    # successful if all its steps are successful.
    for scenarioresult in result.scenarioresults
        arestepssuccessful = [issuccess(step) for step in scenarioresult.steps]
        arebackgroundstepsgood = [issuccess(result) for result in scenarioresult.backgroundresult]
        isscenariosuccessful = all(arestepssuccessful) && all(arebackgroundstepsgood)
        if isscenariosuccessful
            n_success += 1
        else
            n_failure += 1
        end

        acc.isaccumsuccess &= isscenariosuccessful
    end

    push!(acc.features, FeatureSuccessAndFailure(result.feature, n_success, n_failure))
end

"""
    accumulateresult!(acc::ResultAccumulator, parsefailure::Gherkin.BadParseResult{Feature})

A feature file could not be parsed properly. Record the error.
"""
function accumulateresult!(acc::ResultAccumulator, parsefailure::Gherkin.BadParseResult{Feature})
    push!(acc.errors, parsefailure)
    acc.isaccumsuccess = false
end

"""
    issuccess(acc::ResultAccumulator)

True if all scenarios in all accumulated features are successful.
"""
issuccess(acc::ResultAccumulator) = acc.isaccumsuccess

"""
    featureresults(accumulator::ResultAccumulator)

A public getter for the results of all features.
"""
function featureresults(accumulator::ResultAccumulator)
    accumulator.features
end

"""
    isempty(r::ResultAccumulator) :: Bool

True if no results have been accumulated, false otherwise.
"""
Base.isempty(r::ResultAccumulator) :: Bool = isempty(r.features)