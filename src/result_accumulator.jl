# Copyright 2018 Erik Edin
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""
Combine a feature along with the number of scenario successes and failures.
"""
struct FeatureSuccessAndFailure
    feature::Feature
    n_success::UInt
    n_failure::UInt
end

# Bad parse results can be both from the old and the new experimental Gherkin parser.
const BadParseType = Union{Gherkin.BadParseResult{Feature}, Gherkin.Experimental.BadParseResult{Feature}}

"""
Accumulate results from executed features as they are being executed. Keep track of whether the
total run is a success of a failure.
"""
mutable struct ResultAccumulator
    isaccumsuccess::Bool
    features::Vector{FeatureSuccessAndFailure}
    errors::Vector{Tuple{String, BadParseType}}

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
function accumulateresult!(acc::ResultAccumulator, parsefailure::BadParseType, featurefile::String)
    push!(acc.errors, (featurefile, parsefailure))
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