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

using Behavior.Gherkin.Experimental: charP, ParserInput

@testset "charP" begin

@testset "charP; Input is EOF; BadParseResult" begin
    # Arrange
    input = ParserInput("")

    # Act
    result = charP(input)

    # Assert
    @test result isa BadParseResult{Char}
end

@testset "charP; Input is a; Result is a" begin
    # Arrange
    input = ParserInput("a")

    # Act
    result = charP(input)

    # Assert
    @test result isa OKParseResult{Char}
    @test result.value == 'a'
end

@testset "charP; Input is b; Result is b" begin
    # Arrange
    input = ParserInput("b")

    # Act
    result = charP(input)

    # Assert
    @test result isa OKParseResult{Char}
    @test result.value == 'b'
end

@testset "charP; Input is a, then b; Results are a, b" begin
    # Arrange
    input = ParserInput("ab")

    # Act
    result1 = charP(input)
    result2 = charP(result1.newinput)

    # Assert
    @test result1 isa OKParseResult{Char}
    @test result1.value == 'a'
    @test result2 isa OKParseResult{Char}
    @test result2.value == 'b'
end
end # charP