using ExecutableSpecifications.Gherkin


struct NoMatchingStepDefinition <: Exception end

abstract type StepDefinitionMatcher end

# A StepDefinitionMatcher should define a method
# findstepdefinition(::StepDefinitionMatcher, ::Gherkin.ScenarioStep)

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
# ExecutableSpecifications.macros
#

function step_definition_(description::String, definition::Expr)
    quote
        push!(currentdefinitions, StepDefinition($description, (context) -> begin
            try
                $definition
                SuccessfulStepExecution()
            catch ex
                if ex isa StepAssertFailure
                    StepFailed()
                else
                    rethrow()
                end
            end
        end))
    end
end

macro given(description, definition)
    step_definition_(description, definition)
end

macro when(description, definition)
    step_definition_(description, definition)
end

macro then(description, definition)
    step_definition_(description, definition)
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