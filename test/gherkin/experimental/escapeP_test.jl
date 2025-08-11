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

using Behavior.Gherkin.Experimental: ParserInput, charP, escapeP, CharOrEscape, EscapeChar

@testset "escapeP              " begin

@testset "escapeP; Input is a; Result is a" begin
    # Arrange
    input = ParserInput("a")

    # Act
    result = escapeP(input)

    # Assert
    @test result isa OKParseResult{CharOrEscape}
    @test result.value == 'a'
end

@testset "escapeP; Input is EOF; BadParseResult" begin
    # Arrange
    input = ParserInput("")

    # Act
    result = escapeP(input)

    # Assert
    @test result isa BadParseResult{CharOrEscape}
end

@testset "escapeP; Input is b; Result is b" begin
    # Arrange
    input = ParserInput("b")

    # Act
    result = escapeP(input)

    # Assert
    @test result isa OKParseResult{CharOrEscape}
    @test result.value == 'b'
end

@testset "escapeP; Input is a, then b; Result is a, then b" begin
    # Arrange
    input = ParserInput("ab")

    # Act
    result1 = escapeP(input)
    result2 = escapeP(result1.newinput)

    # Assert
    @test result1 isa OKParseResult{CharOrEscape}
    @test result1.value == 'a'
    @test result2 isa OKParseResult{CharOrEscape}
    @test result2.value == 'b'
end

@testset "escapeP; Input is \\|; Result is |" begin
    # Arrange
    input = ParserInput(raw"\|")

    # Act
    result = escapeP(input)

    # Assert
    @test result isa OKParseResult{CharOrEscape}
    @test result.value == EscapeChar('|')
end

@testset "escapeP; Input is \\ then EOF; BadParseResult" begin
    # Arrange
    input = ParserInput(raw"\\")

    # Act
    result = escapeP(input)

    # Assert
    @test result isa BadParseResult{CharOrEscape}
end

@testset "escapeP; Input is \\|; Joined result is the string |" begin
    # Arrange
    input = ParserInput(raw"\|")

    # Act
    result = escapeP(input)

    # Assert
    @test result isa OKParseResult{CharOrEscape}
    @test join([result.value]) == "|"
end

end # escapeP