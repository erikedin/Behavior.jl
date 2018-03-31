struct ResultAccumulator end

accumulateresult(::ResultAccumulator, ::FeatureResult) = nothing
issuccess(::ResultAccumulator) = true