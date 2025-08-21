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

using Behavior.Gherkin.Experimental: ParserInput, optionalC, charP, isC

@testset "optionalC            " begin

@testset "optionalC(a); Input is a; Result is a" begin
    # Arrange
    input = ParserInput("a")

    # Act
    p = isC('a', charP)
    parser = optionalC(p)
    result = parser(input)

    # Assert
    @test result isa OKParseResult{Union{Nothing, Char}}
    @test result.value == 'a'
end

@testset "optionalC(a); Input is empty; Result is OK, with value nothing" begin
    # Arrange
    input = ParserInput("")

    # Act
    p = isC('a', charP)
    parser = optionalC(p)
    result = parser(input)

    # Assert
    @test result isa OKParseResult{Union{Nothing, Char}}
    @test result.value === nothing
end

@testset "optionalC(a); Input is b; Next char is b" begin
    # Arrange
    input = ParserInput("b")

    # Act
    p = isC('a', charP)
    parser = optionalC(p)
    result = parser(input)
    nextresult = charP(result.newinput)

    # Assert
    @test nextresult isa OKParseResult{Char}
    @test nextresult.value == 'b'
end

@testset "optionalC(a); Input is ab; Next char is b" begin
    # Arrange
    input = ParserInput("ab")

    # Act
    p = isC('a', charP)
    parser = optionalC(p)
    result = parser(input)
    nextresult = charP(result.newinput)

    # Assert
    @test nextresult isa OKParseResult{Char}
    @test nextresult.value == 'b'
end
end # optionalC