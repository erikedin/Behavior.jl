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

using Behavior.Gherkin.Experimental: ParserInput, charP, escapeP, CharOrEscape, manyC

@testset "manyC                " begin

@testset "manyC of charP; Input is a; Result is [a]" begin
    # Arrange
    input = ParserInput("a")

    # Act
    parser = manyC(charP)
    result = parser(input)

    # Assert
    @test result isa OKParseResult{Vector{Char}}
    @test result.value == Char['a']
end

@testset "manyC of charP; Input is empty; Result is OK but empty []" begin
    # Arrange
    input = ParserInput("")

    # Act
    parser = manyC(charP)
    result = parser(input)

    # Assert
    @test result isa OKParseResult{Vector{Char}}
    @test result.value == Char[]
end

@testset "manyC of charP; Input is ab; Result is [a, b]" begin
    # Arrange
    input = ParserInput("ab")

    # Act
    parser = manyC(charP)
    result = parser(input)

    # Assert
    @test result isa OKParseResult{Vector{Char}}
    @test result.value == Char['a', 'b']
end

@testset "manyC of satisfyC(is a); Input is aab; Followed by b" begin
    # Arrange
    input = ParserInput("aab")

    # Act
    parser = manyC(satisfyC(c -> c == 'a', charP))
    result = parser(input)
    @test result isa OKParseResult{Vector{Char}}
    nextresult = charP(result.newinput)

    # Assert
    @test nextresult.value == 'b'
end

@testset "manyC of escapeP; Input is a\\b; Result is [a, EscapeChar(b)]" begin
    # Arrange
    input = ParserInput("a\\b")

    # Act
    parser = manyC(escapeP)
    result = parser(input)

    # Assert
    @test result isa OKParseResult{Vector{Union{Char, EscapeChar}}}
    @test result.value == Union{Char, EscapeChar}['a', EscapeChar('b')]
end

end # manyC