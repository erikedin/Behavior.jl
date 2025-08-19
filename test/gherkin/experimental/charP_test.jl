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

using Behavior.Gherkin.Experimental: charP, ParserInput, manyC, to

@testset "charP                " begin

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

# charP will work on a single line, but will fail on a newline.
# This is because Gherkin is line based, so the current parser design
# splits the source into lines on start. This was perhaps not a great
# decision in hindsight, but here we are. We don't want charP to ignore
# line endings, which is what happens before this change. We need to be
# able to determine when the line ends, and stop there. Take a table as
# an example:
#   | foo | bar  |
#   | baz | quux |
# The charP parser would, before this change, completely ignore the
# line ending and collect this as a the text
#   | foo | bar  || baz | quux |
# Because the newline is implicit in the ParserInput, we can't even make
# a parser satisfyC(c -> c != '\n', charP).
# The plan is to introduce this change now, and perhaps later on remove
# this splitting of lines in ParserInput. Then we can introduce a parser
# anyP, which is like charP but does not fail on line endings.
@testset "charP; Input is a\nb; Result is a, then BadParseResult" begin
    # Arrange
    # We need to start and end with a non-space character, because the
    # parser strips leading and trailing whitespace.
    input = ParserInput("a\nb")

    # Act
    prefixresult = charP(input)
    result = charP(prefixresult.newinput)

    # Assert
    @test result isa BadParseResult{Char}
end

@testset "manyC of charP; Input is abc\ndef; Result is abc" begin
    # Arrange
    # We need to start and end with a non-space character, because the
    # parser strips leading and trailing whitespace.
    input = ParserInput("abc\ndef")

    # Act
    parser = manyC(charP) |> to{String}(join)
    result = parser(input)

    # Assert
    @test result isa OKParseResult{String}
    @test result.value == "abc"
end
end # charP