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

using Behavior.Gherkin.Experimental: ParserInput, charP, satisfyC, choiceC

@testset "choiceC              " begin

@testset "choiceC, a or b; Input is a; Result is a" begin
    # Arrange
    input = ParserInput("a")

    a = satisfyC(c -> c == 'a', charP)
    b = satisfyC(c -> c == 'b', charP)

    # Act
    parser = choiceC(a, b)
    result = parser(input)

    # Assert
    @test result isa OKParseResult{Char}
    @test result.value == 'a'
end

@testset "choiceC, a or b; Input is empty; BadParseResult" begin
    # Arrange
    input = ParserInput("")

    a = satisfyC(c -> c == 'a', charP)
    b = satisfyC(c -> c == 'b', charP)

    # Act
    parser = choiceC(a, b)
    result = parser(input)

    # Assert
    @test result isa BadParseResult{Char}
end

@testset "choiceC, a or b; Input is b; Result is b" begin
    # Arrange
    input = ParserInput("b")

    a = satisfyC(c -> c == 'a', charP)
    b = satisfyC(c -> c == 'b', charP)

    # Act
    parser = choiceC(a, b)
    result = parser(input)

    # Assert
    @test result isa OKParseResult{Char}
    @test result.value == 'b'
end

@testset "choiceC, then c; Input is ac; Last result is c" begin
    # Arrange
    input = ParserInput("ac")

    a = satisfyC(c -> c == 'a', charP)
    b = satisfyC(c -> c == 'b', charP)

    # Act
    parser = choiceC(a, b) |> charP
    result = parser(input)

    # Assert
    @test result isa OKParseResult{Char}
    @test result.value == 'c'
end

@testset "choiceC, a or escaped b; Input is \\b; Result is EscapeChar(b)" begin
    # Arrange
    input = ParserInput(raw"\b")

    a = satisfyC(c -> c == 'a', charP)
    b = escapedP

    # Act
    parser = choiceC(a, b)
    result = parser(input)

    # Assert
    @test result isa OKParseResult{Union{Char, EscapeChar}}
    @test result.value == EscapeChar('b')
end

end # choiceC