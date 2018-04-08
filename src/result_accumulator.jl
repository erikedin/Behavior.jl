struct FeatureSuccessAndFailure
    feature::Feature
    n_success::UInt
    n_failure::UInt
end

mutable struct ResultAccumulator
    isaccumsuccess::Bool
    features::Vector{FeatureSuccessAndFailure}

    ResultAccumulator() = new(true, [])
end

function accumulateresult(acc::ResultAccumulator, result::FeatureResult)
    n_success::UInt = 0
    n_failure::UInt = 0
    for scenarioresult in result.scenarioresults
        arestepssuccessful = [issuccess(step) for step in scenarioresult.steps]
        isscenariosuccessful = all(arestepssuccessful)
        if isscenariosuccessful
            n_success += 1
        else
            n_failure += 1
        end

        acc.isaccumsuccess &= isscenariosuccessful
    end

    push!(acc.features, FeatureSuccessAndFailure(result.feature, n_success, n_failure))
end

issuccess(acc::ResultAccumulator) = acc.isaccumsuccess

function featureresults(accumulator::ResultAccumulator)
    accumulator.features
end