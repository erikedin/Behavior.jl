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

using Behavior.Gherkin.Experimental: ParserInput, charP, satisfyC, isC

@testset "satisfyC             " begin

@testset "satisfyC, not space; Input is a; Result is a" begin
    # Arrange
    input = ParserInput("a")
    parser = satisfyC(c -> !isspace(c), charP)

    # Act
    result = parser(input)

    # Assert
    @test result isa OKParseResult{Char}
    @test result.value == 'a'
end

@testset "satisfyC, not space; Input is empty; BadParseResult" begin
    # Arrange
    input = ParserInput("")
    parser = satisfyC(c -> !isspace(c), charP)

    # Act
    result = parser(input)

    # Assert
    @test result isa BadParseResult{Char}
end

@testset "satisfyC, not space; Input is space; BadParseResult" begin
    # Arrange
    # The input is (at the moment at least) stripped of leading and trailing
    # whitespace. In this case we weant to recognize the whitespace, so we have
    # to protect it with non-whitespace characters.
    initialinput = ParserInput("a b")
    # This consumes the 'a' character leaving the space character as the next character.
    initialresult = charP(initialinput)
    input = initialresult.newinput
    parser = satisfyC(c -> !isspace(c), charP)

    # Act
    result = parser(input)

    # Assert
    @test result isa BadParseResult{Char}
end

@testset "satisfyC, not space; Input is space; Next parser recognizes space" begin
    # Arrange
    # The input is (at the moment at least) stripped of leading and trailing
    # whitespace. In this case we weant to recognize the whitespace, so we have
    # to protect it with non-whitespace characters.
    initialinput = ParserInput("a b")
    # This consumes the 'a' character leaving the space character as the next character.
    initialresult = charP(initialinput)
    input = initialresult.newinput
    parser = satisfyC(c -> !isspace(c), charP)

    # Don't accept the space.
    result = parser(input)
    @test result isa BadParseResult{Char}

    # Act
    nextresult = charP(result.newinput)

    # Assert
    @test nextresult isa OKParseResult{Char}
    @test nextresult.value == ' '
end

@testset "satisfyC, not space; Input is ab; Next parser accepts b" begin
    # Arrange
    input = ParserInput("ab")
    parser = satisfyC(c -> !isspace(c), charP)

    # Accept the a
    result = parser(input)
    @test result isa OKParseResult{Char}

    # Act
    nextresult = charP(result.newinput)

    # Assert
    @test nextresult isa OKParseResult{Char}
    @test nextresult.value == 'b'
end

@testset "satisfyC, escapedP; Input is \\a; Result is EscapeChar(a)" begin
    # Arrange
    input = ParserInput("\\a")
    parser = satisfyC(c -> c == EscapeChar('a'), escapedP)

    # Act
    result = parser(input)

    # Assert
    @test result isa OKParseResult{EscapeChar}
    @test result.value == EscapeChar('a')
end

# isC(a, charP) is shorthand for
# satisfyC(c -> c == a, charP)
@testset "isC, escapedP; Input is \\a; Result is EscapeChar(a)" begin
    # Arrange
    input = ParserInput("\\a")
    parser = isC(EscapeChar('a'), escapedP)

    # Act
    result = parser(input)

    # Assert
    @test result isa OKParseResult{EscapeChar}
    @test result.value == EscapeChar('a')
end

@testset "isC(a); Input is a; Result is a" begin
    # Arrange
    input = ParserInput("a")
    parser = isC('a', charP)

    # Act
    result = parser(input)

    # Assert
    @test result isa OKParseResult{Char}
    @test result.value == 'a'
end
end # satisfyC