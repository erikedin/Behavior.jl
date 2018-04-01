mutable struct ResultAccumulator
    isaccumsuccess::Bool

    ResultAccumulator() = new(true)
end

function accumulateresult(acc::ResultAccumulator, result::FeatureResult)
    for scenarioresult in result.scenarioresults
        arestepssuccessful = [issuccess(step) for step in scenarioresult.steps]
        acc.isaccumsuccess &= all(arestepssuccessful)
    end
end

issuccess(acc::ResultAccumulator) = acc.isaccumsuccess