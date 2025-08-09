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

using Behavior.Gherkin.Experimental: Literal, ParserInput, line

@testset "Literal              " begin

@testset "Match Foo; Input is Foo; OK" begin
    # Arrange
    input = ParserInput("Foo")

    # Act
    p = Literal("Foo")
    result = p(input)

    # Assert
    @test result isa OKParseResult{String}
    @test result.value == "Foo"
end

@testset "Match Quux; Input is Quux; OK" begin
    # Arrange
    input = ParserInput("Quux")

    # Act
    p = Literal("Quux")
    result = p(input)

    # Assert
    @test result isa OKParseResult{String}
    @test result.value == "Quux"
end

@testset "Match Foo; Input is Bar; No match" begin
    # Arrange
    input = ParserInput("Foo")

    # Act
    p = Literal("Bar")
    result = p(input)

    # Assert
    @test result isa BadParseResult{String}
end

@testset "Match Quux then Bar; Input is Quux and Bar; OK" begin
    # Arrange
    input = ParserInput("QuuxBar")

    # Act
    p1 = Literal("Quux")
    p2 = Literal("Bar")
    result1 = p1(input)
    result2 = p2(result1.newinput)

    # Assert
    @test result1 isa OKParseResult{String}
    @test result1.value == "Quux"
    @test result2 isa OKParseResult{String}
    @test result2.value == "Bar"
end

@testset "Fail to match Quux then match Bar; Input is Bar; OK" begin
    # Arrange
    input = ParserInput("Bar")

    # Act
    p1 = Literal("Quux")
    p2 = Literal("Bar")
    result1 = p1(input)
    result2 = p2(result1.newinput)

    # Assert
    @test result1 isa BadParseResult{String}
    @test result2 isa OKParseResult{String}
    @test result2.value == "Bar"
end

@testset "Match Foo; Input is EOF; Bad parse result" begin
    # Arrange
    # Consume the first line to force an EOF where the next
    # line is beyond the last line.
    initialinput = ParserInput("a")
    _value, input = line(initialinput)

    # Act
    p = Literal("Foo")
    result = p(input)

    # Assert
    @test result isa BadParseResult{String}
end

end # Literal
