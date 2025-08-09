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

using Behavior.Gherkin.Experimental: repeatC, charP, ParserInput

@testset "repeatC" begin

@testset "repeatC over charP; Input is EOF; BadParseResult" begin
    # Arrange
    input = ParserInput("")

    # Act
    parser = repeatC(charP, 1)
    result = parser(input)

    # Assert
    @test result isa BadParseResult{Vector{Char}}
end

@testset "repeatC over charP; Input is a; Result is [a]" begin
    # Arrange
    input = ParserInput("a")

    # Act
    parser = repeatC(charP, 1)
    result = parser(input)

    # Assert
    @test result isa OKParseResult{Vector{Char}}
    @test result.value == ['a']
end

@testset "repeatC over charP; Input is b; Result is [b]" begin
    # Arrange
    input = ParserInput("b")

    # Act
    parser = repeatC(charP, 1)
    result = parser(input)

    # Assert
    @test result isa OKParseResult{Vector{Char}}
    @test result.value == ['b']
end

@testset "repeatC over charP; Input is aa, n = 2; Result is [a, a]" begin
    # Arrange
    input = ParserInput("aa")

    # Act
    parser = repeatC(charP, 2)
    result = parser(input)

    # Assert
    @test result isa OKParseResult{Vector{Char}}
    @test result.value == ['a', 'a']
end

@testset "repeatC over charP; Input is aa, n = 3; BadParseResult" begin
    # Arrange
    input = ParserInput("aa")

    # Act
    parser = repeatC(charP, 3)
    result = parser(input)

    # Assert
    @test result isa BadParseResult{Vector{Char}}
end

@testset "repeatC over charP; Input is ab, n = 2; Result is ab" begin
    # Arrange
    input = ParserInput("ab")

    # Act
    parser = repeatC(charP, 2)
    result = parser(input)

    # Assert
    @test result isa OKParseResult{Vector{Char}}
    @test result.value == ['a', 'b']
end

@testset "repeatC over charP, then charP; Input is abc, n = 2; Last char is c" begin
    # Arrange
    input = ParserInput("abc")

    # Act
    parser = repeatC(charP, 2)
    result = parser(input)
    lastresult = charP(result.newinput)

    # Assert
    @test lastresult isa OKParseResult{Char}
    @test lastresult.value == 'c'
end

end # repeatC