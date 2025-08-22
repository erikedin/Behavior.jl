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

using Behavior.Gherkin.Experimental: ParserInput, eofP, eolP, charP, ignoreC

@testset "eofP                 " begin

@testset "eofP; Input is a; BadParseResult" begin
    # Arrange
    input = ParserInput("a")

    # Act
    result = eofP(input)

    # Assert
    @test result isa BadParseResult{Nothing}
end

@testset "eofP; Input is empty; OK" begin
    # Arrange
    input = ParserInput("")

    # Act
    result = eofP(input)

    # Assert
    @test result isa OKParseResult{Nothing}
    @test result.value === nothing
end

# Even though an EOF is not a newline, it still terminates a line,
# so it's considered an end-of-line.
@testset "eolP; Input is empty; OK" begin
    # Arrange
    input = ParserInput("")

    # Act
    result = eolP(input)

    # Assert
    @test result isa OKParseResult{Nothing}
end

@testset "eolP; Input is a single newline; OK" begin
    # Arrange
    # The input is automatically stripped, so we have to sandwich the newline
    # between non-space characters, so it isn't stripped into an empty line.
    # The first character is just consumed.
    originalinput = ParserInput("a\nb")
    originalresult = charP(originalinput)
    input = originalresult.newinput

    # Act
    result = eolP(input)

    # Assert
    @test result isa OKParseResult{Nothing}
    @test result.value === nothing
end

@testset "eolP; Input is a and a newline; Not OK" begin
    # Arrange
    input = ParserInput("a\nb")

    # Act
    result = eolP(input)

    # Assert
    @test result isa BadParseResult{Nothing}
end

@testset "eolP; Input is newline, then b; Next char is b" begin
    # Arrange
    input = ParserInput("a\nb")

    # Act
    prefixresult = charP(input)
    result = eolP(prefixresult.newinput)
    nextresult = charP(result.newinput)

    # Assert
    @test nextresult isa OKParseResult{Char}
    @test nextresult.value == 'b'
end

@testset "charP then eolP; Input is a\\nb; Next char is P" begin
    # Arrange
    input = ParserInput("a\nb")

    # Act
    parser = charP >> ignoreC(eolP)
    result = parser(input)
    nextresult = charP(result.newinput)

    # Assert
    @test nextresult isa OKParseResult{Char}
    @test nextresult.value == 'b'
end

@testset "manyC then eolP; Input is |a|b|\\n|c|d|; Next char is P" begin
    # Arrange
    input = ParserInput("|a|b|\n|c|d|\ne")

    # Act
    untileolP = manyC(charP) |> to{String}(join)
    parser = untileolP >> ignoreC(eolP)
    result = parser(input)
    nextresult = parser(result.newinput)

    # Assert
    @test result isa OKParseResult{String}
    @test result.value == "|a|b|"
    @test nextresult isa OKParseResult{String}
    @test nextresult.value == "|c|d|"
end

end # eofP
