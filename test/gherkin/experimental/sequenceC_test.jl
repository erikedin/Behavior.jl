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

using Behavior.Gherkin.Experimental: ParserInput, charP, ignoreC, satisfyC

@testset "sequenceC            " begin

@testset "sequenceC, char then ignore b; Input is ab; Result is a" begin
    # Arrange
    input = ParserInput("ab")

    # Act
    parser = charP >> ignoreC(satisfyC(c -> c == 'b', charP))
    result = parser(input)

    # Assert
    @test result isa OKParseResult{Char}
    @test result.value == 'a'
end

@testset "sequenceC, char then ignore b; Input is empty; BadParseResult" begin
    # Arrange
    input = ParserInput("")

    # Act
    parser = charP >> ignoreC(satisfyC(c -> c == 'b', charP))
    result = parser(input)

    # Assert
    @test result isa BadParseResult{Char}
end

@testset "sequenceC, char then ignore b; Input is abc; Next char is c" begin
    # Arrange
    input = ParserInput("abc")

    # Act
    parser = charP >> ignoreC(satisfyC(c -> c == 'b', charP))
    result = parser(input)
    nextresult = charP(result.newinput)

    # Assert
    @test nextresult isa OKParseResult{Char}
    @test nextresult.value == 'c'
end

@testset "sequenceC, char then ignore b; Input is a.c; Next char is a" begin
    # Arrange
    input = ParserInput("a.c")

    # Act
    parser = charP >> ignoreC(satisfyC(c -> c == 'b', charP))
    result = parser(input)
    nextresult = charP(result.newinput)

    # Assert
    @test nextresult isa OKParseResult{Char}
    @test nextresult.value == 'a'
end

@testset "sequenceC, not a then ignore b; Input is a.c; Next char is a" begin
    # Arrange
    input = ParserInput("a.c")

    # Act
    parser = satisfyC(c -> c != 'a', charP) >> ignoreC(satisfyC(c -> c == 'b', charP))
    result = parser(input)
    nextresult = charP(result.newinput)

    # Assert
    @test nextresult isa OKParseResult{Char}
    @test nextresult.value == 'a'
end

@testset "sequenceC, ignore a, then char; Input is ab; Result is b" begin
    # Arrange
    input = ParserInput("ab")

    # Act
    parser = ignoreC(charP) >> charP
    result = parser(input)

    # Assert
    @test result isa OKParseResult{Char}
    @test result.value == 'b'
end

@testset "sequenceC, ignore a, then not b; Input is ab; Next char is a" begin
    # Arrange
    input = ParserInput("ab")

    # Act
    parser = ignoreC(charP) >> satisfyC(c -> c != 'b', charP)
    result = parser(input)
    nextresult = charP(result.newinput)

    # Assert
    @test nextresult isa OKParseResult{Char}
    @test nextresult.value == 'a'
end

end # sequenceC