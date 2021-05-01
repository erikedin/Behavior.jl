using Behavior:
    Engine, ExecutorEngine, QuietRealTimePresenter, FromMacroStepDefinitionMatcher,
    finish, issuccess, findstepdefinition, NoMatchingStepDefinition, runfeatures!,
    Driver, readstepdefinitions!, OSAbstraction, StepDefinitionMatcher
using Behavior.Gherkin: Feature, FeatureHeader, Scenario, Given, ParseOptions
import Behavior: addmatcher!, findfileswithextension, readfile, runfeature!,
                                 issuccess, finish

@testset "Engine               " begin
    # Beware: This test actually exercises far too much of the code. It should be isolated to
    # `Engine`` only.
    @testset "Run a successful feature; Result is successful" begin
        # Arrange
        engine = ExecutorEngine(QuietRealTimePresenter())
        matcher = FromMacroStepDefinitionMatcher("""
            using Behavior

            @given("successful step") do context end
        """)
        addmatcher!(engine, matcher)

        successfulscenario = Scenario("", String[], ScenarioStep[Given("successful step")])
        feature = Feature(FeatureHeader("", [], []), [successfulscenario])

        # Act
        runfeature!(engine, feature)

        # Assert
        result = finish(engine)
        @test issuccess(result)
    end

    @testset "Run a failing feature; Result is not successful" begin
        # Arrange
        engine = ExecutorEngine(QuietRealTimePresenter())
        matcher = FromMacroStepDefinitionMatcher("""
            using Behavior

            @given("failing step") do context
                @expect 1 == 2
            end
        """)
        addmatcher!(engine, matcher)

        failingscenario = Scenario("", String[], ScenarioStep[Given("failing step")])
        feature = Feature(FeatureHeader("", [], []), [failingscenario])

        # Act
        runfeature!(engine, feature)

        # Assert
        result = finish(engine)
        @test !issuccess(result)
    end

    @testset "Run a failing and a successful feature; Result is not successful" begin
        # Arrange
        engine = ExecutorEngine(QuietRealTimePresenter())
        matcher = FromMacroStepDefinitionMatcher("""
            using Behavior

            @given("failing step") do context
                @expect 1 == 2
            end

            @given("successful step") do context end
        """)
        addmatcher!(engine, matcher)

        failingscenario = Scenario("", String[], ScenarioStep[Given("failing step")])
        successfulscenario = Scenario("", String[], ScenarioStep[Given("successful step")])
        feature1 = Feature(FeatureHeader("fails", [], []), [failingscenario])
        feature2 = Feature(FeatureHeader("succeeds", [], []), [successfulscenario])

        # Act
        runfeature!(engine, feature1)
        runfeature!(engine, feature2)

        # Assert
        result = finish(engine)
        @test !issuccess(result)
    end
end

struct FakeResultAccumulator
    success::Bool
end
issuccess(r::FakeResultAccumulator) = r.success

mutable struct FakeEngine <: Engine
    matchers::Vector{StepDefinitionMatcher}
    features::Vector{Feature}
    finishresult::FakeResultAccumulator
    errors::Vector{Gherkin.BadParseResult{Feature}}

    FakeEngine(; finishresult=FakeResultAccumulator(true)) = new([], [], finishresult, [])
end
addmatcher!(engine::FakeEngine, m::StepDefinitionMatcher) = push!(engine.matchers, m)
runfeature!(engine::FakeEngine, feature::Feature) = push!(engine.features, feature)
runfeature!(engine::FakeEngine, result::Gherkin.OKParseResult{Feature}, featurefile::String) = runfeature!(engine, result.value)
runfeature!(engine::FakeEngine, result::Gherkin.BadParseResult{Feature}, featurefile::String) = push!(engine.errors, result)

finish(engine::FakeEngine) = engine.finishresult

struct FakeOSAbstraction <: OSAbstraction
    fileswithext::Dict{String, Vector{String}}
    filecontents::Dict{String, String}

    findfileswithextension_args::Vector{Pair{String, String}}

    FakeOSAbstraction(; fileswithext::Vector{Pair{String, Vector{String}}} = [],
                        filecontents::Dict{String, String} = Dict()) = new(Dict(fileswithext), filecontents, [])
end
function findfileswithextension(os::FakeOSAbstraction, path::String, extension::String)
    push!(os.findfileswithextension_args, Pair(path, extension))
    os.fileswithext[extension]
end

readfile(os::FakeOSAbstraction, path::String) = os.filecontents[path]

@testset "Driver               " begin
    @testset "Finding step definitions; One definition found; The engine has one matcher" begin
        # Arrange
        engine = FakeEngine()
        osal = FakeOSAbstraction(fileswithext=[".jl" => ["somepath/file.jl"]],
                                 filecontents = Dict("somepath/file.jl" => ""))
        driver = Driver(osal, engine)

        # Act
        readstepdefinitions!(driver, "somepath")

        # Assert
        @test length(engine.matchers) == 1
    end

    @testset "Finding step definitions; Two definitions found; The engine has two matchers" begin
        # Arrange
        engine = FakeEngine()
        osal = FakeOSAbstraction(fileswithext=[".jl" => ["somepath/file.jl", "somepath/file2.jl"]],
                                 filecontents = Dict("somepath/file.jl" => "",
                                                     "somepath/file2.jl" => ""))
        driver = Driver(osal, engine)

        # Act
        readstepdefinitions!(driver, "somepath")

        # Assert
        @test length(engine.matchers) == 2
    end

    @testset "Finding step definitions; Driver searches for .jl files" begin
        # Arrange
        engine = FakeEngine()
        osal = FakeOSAbstraction(fileswithext=[".jl" => ["somepath/file.jl", "somepath/file2.jl"]],
                                 filecontents = Dict("somepath/file.jl" => "",
                                                     "somepath/file2.jl" => ""))
        driver = Driver(osal, engine)

        # Act
        readstepdefinitions!(driver, "somepath")

        # Assert
        @test osal.findfileswithextension_args[1][2] == ".jl"
    end

    @testset "Finding step definitions; Step path is features/steps; Driver searches features/steps" begin
        # Arrange
        engine = FakeEngine()
        osal = FakeOSAbstraction(fileswithext=[".jl" => ["somepath/file.jl", "somepath/file2.jl"]],
                                 filecontents = Dict("somepath/file.jl" => "",
                                                     "somepath/file2.jl" => ""))
        driver = Driver(osal, engine)

        # Act
        readstepdefinitions!(driver, "features/steps")

        # Assert
        @test osal.findfileswithextension_args[1][1] == "features/steps"
    end

    @testset "Finding step definitions; Step path is features/othersteps; Driver search features/othersteps" begin
        # Arrange
        engine = FakeEngine()
        osal = FakeOSAbstraction(fileswithext=[".jl" => ["somepath/file.jl", "somepath/file2.jl"]],
                                 filecontents = Dict("somepath/file.jl" => "",
                                                     "somepath/file2.jl" => ""))
        driver = Driver(osal, engine)

        # Act
        readstepdefinitions!(driver, "features/othersteps")

        # Assert
        @test osal.findfileswithextension_args[1][1] == "features/othersteps"
    end

    @testset "Reading step definitions; Step definition has successful scenario step; The matcher can find that step" begin
        # Arrange
        engine = FakeEngine()
        osal = FakeOSAbstraction(fileswithext=[".jl" => ["features/steps/file.jl"]],
                                 filecontents = Dict("features/steps/file.jl" => """
                                    using Behavior

                                    @given("successful step") do context end
                                 """))
        driver = Driver(osal, engine)

        successfulstep = Given("successful step")

        # Act
        readstepdefinitions!(driver, "features/othersteps")

        # Assert
        # This method throws if no such step definition was found.
        findstepdefinition(engine.matchers[1], successfulstep)
    end

    @testset "Reading step definitions; Step definition has no scenario step; Matcher cannot find that senario step" begin
        # Arrange
        engine = FakeEngine()
        osal = FakeOSAbstraction(fileswithext=[".jl" => ["features/steps/file.jl"]],
                                 filecontents = Dict("features/steps/file.jl" => """
                                    using Behavior

                                 """))
        driver = Driver(osal, engine)

        successfulstep = Given("successful step")

        # Act
        readstepdefinitions!(driver, "features/othersteps")

        # Assert
        # This method throws if no such step definition was found.
        @test_throws NoMatchingStepDefinition findstepdefinition(engine.matchers[1], successfulstep)
    end

    @testset "Running feature files; One successful feature found; One feature is executed" begin
        # Arrange
        filecontents = Dict("features/file.feature" => """
            Feature: Some feature

                Scenario: A scenario
                    Given successful step
            """)
        engine = FakeEngine()
        osal = FakeOSAbstraction(fileswithext=[".feature" => ["features/file.feature"]],
                                 filecontents = filecontents)
        driver = Driver(osal, engine)

        # Act
        result = runfeatures!(driver, "features")

        # Assert
        @test length(engine.features) == 1
    end

    @testset "Running feature files; Two successful features found; Two features are executed" begin
        # Arrange
        filecontents = Dict("features/file1.feature" => """
            Feature: Some feature

                Scenario: A scenario
                    Given successful step
            """,
            "features/file2.feature" => """
            Feature: Some other feature

                Scenario: Another scenario
                    Given successful step
            """)
        engine = FakeEngine()
        osal = FakeOSAbstraction(fileswithext=[".feature" => ["features/file1.feature",
                                                              "features/file2.feature"]],
                                 filecontents = filecontents)
        driver = Driver(osal, engine)

        # Act
        result = runfeatures!(driver, "features")

        # Assert
        @test length(engine.features) == 2
    end

    @testset "Running feature files; Two successful features found; They are also read from file" begin
        # Arrange
        filecontents = Dict("features/file1.feature" => """
            Feature: Some feature

                Scenario: A scenario
                    Given successful step
            """,
            "features/file2.feature" => """
            Feature: Some other feature

                Scenario: Another scenario
                    Given successful step
            """)
        engine = FakeEngine()
        osal = FakeOSAbstraction(fileswithext=[".feature" => ["features/file1.feature",
                                                              "features/file2.feature"]],
                                 filecontents = filecontents)
        driver = Driver(osal, engine)

        # Act
        result = runfeatures!(driver, "features")

        # Assert
        featuredescriptions = [f.header.description for f in engine.features]
        @test "Some feature" in featuredescriptions
        @test "Some other feature" in featuredescriptions
    end

    @testset "Running feature files; Two successful features found; The result is successful" begin
        # Arrange
        filecontents = Dict("features/file1.feature" => """
            Feature: Some feature

                Scenario: A scenario
                    Given successful step
            """,
            "features/file2.feature" => """
            Feature: Some other feature

                Scenario: Another scenario
                    Given successful step
            """)
        engine = FakeEngine()
        osal = FakeOSAbstraction(fileswithext=[".feature" => ["features/file1.feature",
                                                              "features/file2.feature"]],
                                 filecontents = filecontents)
        driver = Driver(osal, engine)

        # Act
        result = runfeatures!(driver, "features")

        # Assert
        @test issuccess(result)
    end

    @testset "Running feature files with parse options; One scenario with out-of-order steps; Feature is executed" begin
        # Arrange
        filecontents = Dict("features/file.feature" => """
            Feature: Some feature

                Scenario: A scenario with out-of-order steps
                    Then a postcondition
                    When an action
                    Given a precondition
            """)
        engine = FakeEngine()
        osal = FakeOSAbstraction(fileswithext=[".feature" => ["features/file.feature"]],
                                 filecontents = filecontents)
        driver = Driver(osal, engine)

        # Act
        result = runfeatures!(driver, "features", parseoptions = ParseOptions(allow_any_step_order = true))

        # Assert
        @test length(engine.features) == 1
    end

    @testset "Running feature files; One feature has a syntax error; No exception is thrown" begin
        # I need to rewrite these tests properly, because the mock lots of things that I think I'd
        # like to be part of the test. This test however, should throw an exception, which used to be the
        # case.

        # Arrange
        filecontents = Dict("features/file1.feature" => """
            Feature: Some feature

                Scenario: A scenario
                     When an action
                    Given successful step
            """)
        engine = FakeEngine()
        osal = FakeOSAbstraction(fileswithext=[".feature" => ["features/file1.feature"]],
                                 filecontents = filecontents)
        driver = Driver(osal, engine)

        # Act
        runfeatures!(driver, "features")

        # Assert
        # Not throwing an exception above is enough.
    end
end