using ExecutableSpecifications:
    Engine, ExecutorEngine, QuietRealTimePresenter, FromMacroStepDefinitionMatcher,
    runfeature!, finish, issuccess,
    Driver, findstepdefinitions!, OSAbstraction
using ExecutableSpecifications.Gherkin: Feature, FeatureHeader, Scenario, Given
import ExecutableSpecifications: addmatcher!

@testset "Engine               " begin
    # Beware: This test actually exercises far too much of the code. It should be isolated to
    # `Engine`` only.
    @testset "Run a successful feature; Result is successful" begin
        # Arrange
        engine = ExecutorEngine(QuietRealTimePresenter())
        matcher = FromMacroStepDefinitionMatcher("""
            using ExecutableSpecifications

            @given "successful step" begin end
        """)
        addmatcher!(engine, matcher)

        successfulscenario = Scenario("", [], [Given("successful step")])
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
            using ExecutableSpecifications

            @given "failing step" begin
                @expect 1 == 2
            end
        """)
        addmatcher!(engine, matcher)

        failingscenario = Scenario("", [], [Given("failing step")])
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
            using ExecutableSpecifications

            @given "failing step" begin
                @expect 1 == 2
            end

            @given "successful step" begin end
        """)
        addmatcher!(engine, matcher)

        failingscenario = Scenario("", [], [Given("failing step")])
        successfulscenario = Scenario("", [], [Given("successful step")])
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

mutable struct FakeEngine <: Engine
    matchers::Vector{StepDefinitionMatcher}

    FakeEngine() = new([])
end
addmatcher!(engine::FakeEngine, m::StepDefinitionMatcher) = push!(engine.matchers, m)

struct FakeOSAbstraction <: OSAbstraction
    fileswithext::Vector{String}
    filecontents::Dict{String, String}

    FakeOSAbstraction(; fileswithext::Vector{String} = [],
                        filecontents::Dict{String, String} = Dict()) = new(fileswithext, filecontents)
end
findfileswithextension(os::FakeOSAbstraction, path::String, extension::String) = os.fileswithext
readfile(os::FakeOSAbstraction, path::String) = os.filecontents[path]

@testset "Driver" begin
    @testset "Finding step definitions; One definition found; The engine has one matcher" begin
        # Arrange
        engine = FakeEngine()
        osal = FakeOSAbstraction(fileswithext=["somepath/file.feature"],
                                 filecontents = Dict("somepath/file.feature" => "some data"))
        driver = Driver(osal, engine)

        # Act
        findstepdefinitions!(driver, "somepath")

        # Assert
        @test length(engine.matchers) == 1
    end
end