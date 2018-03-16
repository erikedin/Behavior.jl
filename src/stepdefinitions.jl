using BDD.Gherkin


struct NoMatchingStepDefinition <: Exception end

abstract type StepDefinitionMatcher end

findstepdefinition(::StepDefinitionMatcher, ::Gherkin.ScenarioStep) = error("Not implemented for abstract type StepDefinitionMatcher")

struct StepDefinition
    description::String
    definition::Function
end

#
# Step definition context
#
struct StepDefinitionContext
    variables::Dict{Symbol, Any}

    StepDefinitionContext() = new(Dict{Symbol, Any}())
end

Base.getindex(context::StepDefinitionContext, sym::Symbol) = context.variables[sym]
Base.setindex!(context::StepDefinitionContext, value::Any, sym::Symbol) = context.variables[sym] = value

#
# Global state
#

currentdefinitions = Vector{StepDefinition}()

#
# BDD macros
#

macro given(description, definition)
    quote
        push!(currentdefinitions, StepDefinition($description, (context) -> begin
            try
                $definition
                SuccessfulStepExecution()
            catch ex
                if ex isa StepAssertFailure
                    StepFailed()
                else
                    throw()
                end
            end
        end))
    end
end

#
# Step Definition Matcher implementation
#

struct FromMacroStepDefinitionMatcher <: StepDefinitionMatcher
    stepdefinitions::Vector{StepDefinition}

    function FromMacroStepDefinitionMatcher(source::AbstractString)
        global currentdefinitions
        include_string(source)
        mydefinitions = currentdefinitions
        this = new(mydefinitions)
        currentdefinitions = Vector{StepDefinition}()
        this
    end
end

function findstepdefinition(matcher::FromMacroStepDefinitionMatcher, step::Gherkin.ScenarioStep)
    matchingstepdefinitions = find(x -> x.description == step.text, matcher.stepdefinitions)
    if isempty(matchingstepdefinitions)
        throw(NoMatchingStepDefinition())
    end
    firstmatch = matchingstepdefinitions[1]
    matcher.stepdefinitions[firstmatch].definition
end