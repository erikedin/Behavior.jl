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

using Test
using Behavior.Selection
using Behavior.Selection: TagExpressionInput, SingleTagParser

@testset "Selection combinators" begin
    @testset "NotIn" begin
        @testset "Not b; a; OK" begin
            # Arrange
            input = TagExpressionInput("a")
            parser = Selection.NotIn("b")

            # Act
            result = parser(input)

            # Assert
            @test result isa Selection.OKParseResult{Char}
            @test result.value == 'a'
        end

        @testset "Not b; c; OK" begin
            # Arrange
            input = TagExpressionInput("c")
            parser = Selection.NotIn("b")

            # Act
            result = parser(input)

            # Assert
            @test result isa Selection.OKParseResult{Char}
            @test result.value == 'c'
        end

        @testset "Not b; b; Not OK" begin
            # Arrange
            input = TagExpressionInput("b")
            parser = Selection.NotIn("b")

            # Act
            result = parser(input)

            # Assert
            @test result isa Selection.BadParseResult{Char}
        end
    end

    @testset "Repeating" begin
        @testset "While not b; b; OK, empty" begin
            # Arrange
            input = TagExpressionInput("b")
            parser = Selection.Repeating(Selection.NotIn("b"))

            # Act
            result = parser(input)

            # Assert
            @test result isa Selection.OKParseResult{Vector{Char}}
            @test result.value == []
        end

        @testset "While not b; ab; OK, a" begin
            # Arrange
            input = TagExpressionInput("ab")
            parser = Selection.Repeating(Selection.NotIn("b"))

            # Act
            result = parser(input)

            # Assert
            @test result isa Selection.OKParseResult{Vector{Char}}
            @test result.value == ['a']
        end

        @testset "While not b; acb; OK, ac" begin
            # Arrange
            input = TagExpressionInput("acb")
            parser = Selection.Repeating(Selection.NotIn("b"))

            # Act
            result = parser(input)

            # Assert
            @test result isa Selection.OKParseResult{Vector{Char}}
            @test result.value == ['a', 'c']
        end
    end

    @testset "TagSelection parser" begin
        @testset "@foo; OK" begin
            # Arrange
            input = TagExpressionInput("@foo")
            parser = SingleTagParser()

            # Act
            result = parser(input)

            # Assert
            @test result isa Selection.OKParseResult{String}
            @test result.value == "@foo"
        end

        @testset "@bar; OK" begin
            # Arrange
            input = TagExpressionInput("@bar")
            parser = SingleTagParser()

            # Act
            result = parser(input)

            # Assert
            @test result isa Selection.OKParseResult{String}
            @test result.value == "@bar"
        end

        @testset "Tag followed by a non-tag character; OK" begin
            nontagchars = "() "

            for nontagchar in nontagchars
                @testset "Non-tag character $(nontagchar)" begin
                    # Arrange
                    input = TagExpressionInput("@foo$(nontagchar)")
                    parser = SingleTagParser()

                    # Act
                    result = parser(input)

                    # Assert
                    @test result isa Selection.OKParseResult{String}
                    @test result.value == "@foo"
                end
            end
        end
    end
end