using Behavior.Gherkin
using Behavior.Gherkin: issuccessful
using Test

@testset "Block text, state    " begin
    @testset "Empty block; Result is an empty block text" begin
        # Arrange
        text = """
            \"\"\"
            \"\"\"
        """
        parser = Gherkin.StateParser(initialstate=Gherkin.BlockTextState())

        # Act
        result = Gherkin.parsegherkin(parser, text)

        # Assert
        @test issuccessful(result)
        blocktext = result.value
        @test blocktext.text == ""
    end

    @testset "Block contains a line Baz; Result is Baz" begin
        # Arrange
        text = """
            \"\"\"
            Baz
            \"\"\"
        """
        parser = Gherkin.StateParser(initialstate=Gherkin.BlockTextState())

        # Act
        result = Gherkin.parsegherkin(parser, text)

        # Assert
        @test issuccessful(result)
        blocktext = result.value
        @test blocktext.text == ""
    end
end
