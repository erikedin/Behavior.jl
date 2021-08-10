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
using Behavior.Selection: TagExpressionInput, SingleTagParser, SequenceParser, Tag

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
            @test result isa Selection.OKParseResult{Selection.Tag}
            @test result.value == Selection.Tag("@foo")
        end

        @testset "@bar; OK" begin
            # Arrange
            input = TagExpressionInput("@bar")
            parser = SingleTagParser()

            # Act
            result = parser(input)

            # Assert
            @test result isa Selection.OKParseResult{Selection.Tag}
            @test result.value == Selection.Tag("@bar")
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
                    @test result isa Selection.OKParseResult{Selection.Tag}
                    @test result.value == Selection.Tag("@foo")
                end
            end
        end
    end

    @testset "TakeUntil parser" begin
        @testset "TakeUntil b; ab; a" begin
            # Arrange
            input = TagExpressionInput("ab")
            parser = Selection.TakeUntil("b")

            # Act
            result = parser(input)

            # Assert
            @test result isa Selection.OKParseResult{String}
            @test result.value == "a"
        end

        @testset "TakeUntil b; aab; aa" begin
            # Arrange
            input = TagExpressionInput("aab")
            parser = Selection.TakeUntil("b")

            # Act
            result = parser(input)

            # Assert
            @test result isa Selection.OKParseResult{String}
            @test result.value == "aa"
        end

        @testset "TakeUntil b; aa; aa" begin
            # Arrange
            input = TagExpressionInput("aa")
            parser = Selection.TakeUntil("b")

            # Act
            result = parser(input)

            # Assert
            @test result isa Selection.OKParseResult{String}
            @test result.value == "aa"
        end

        @testset "TakeUntil space; cc ; cc" begin
            # Arrange
            input = TagExpressionInput("cc ")
            parser = Selection.TakeUntil(" ")

            # Act
            result = parser(input)

            # Assert
            @test result isa Selection.OKParseResult{String}
            @test result.value == "cc"
        end

        @testset "TakeUntil space or ); cc ; cc" begin
            # Arrange
            input = TagExpressionInput("cc ")
            parser = Selection.TakeUntil(" )")

            # Act
            result = parser(input)

            # Assert
            @test result isa Selection.OKParseResult{String}
            @test result.value == "cc"
        end

        @testset "TakeUntil space or ); cc); cc" begin
            # Arrange
            input = TagExpressionInput("cc)")
            parser = Selection.TakeUntil(" )")

            # Act
            result = parser(input)

            # Assert
            @test result isa Selection.OKParseResult{String}
            @test result.value == "cc"
        end

        @testset "TakeUntil b, then TakeUntil d; abcd; a, bc" begin
            # Arrange
            input = TagExpressionInput("abcd")

            # Act
            parser1 = Selection.TakeUntil("b")
            result1 = parser1(input)
            parser2 = Selection.TakeUntil("d")
            result2 = parser2(result1.newinput)

            # Assert
            @test result1 isa Selection.OKParseResult{String}
            @test result1.value == "a"
            @test result2 isa Selection.OKParseResult{String}
            @test result2.value == "bc"
        end

        @testset "TakeUntil space; Prefix whitespace then cc ; cc" begin
            # Arrange
            input = TagExpressionInput(" cc ")
            println(input)
            parser = Selection.TakeUntil(" ")

            # Act
            result = parser(input)

            # Assert
            @test result isa Selection.OKParseResult{String}
            @test result.value == "cc"
        end

        @testset "TakeUntil space twice; a d ; a, then d" begin
            # Arrange
            input = TagExpressionInput("a d ")

            # Act
            parser = Selection.TakeUntil(" ")
            result1 = parser(input)
            result2 = parser(result1.newinput)

            # Assert
            @test result1 isa Selection.OKParseResult{String}
            @test result1.value == "a"
            @test result2 isa Selection.OKParseResult{String}
            @test result2.value == "d"
        end
    end

    @testset "Sequences" begin
        # @testset "@foo then @bar; OK" begin
        #     # Arrange
        #     input = TagExpressionInput("@foo @bar")
        #     parser = SequenceParser{Tag}(
        #         SingleTagParser(),
        #         SingleTagParser()
        #     )

        #     # Act
        #     result = parser(input)

        #     # Assert
        #     @test result isa Selection.OKParseResult{Vector{Tag}}
        #     @test result.value == [Tag("@foo"), Tag("@bar")]
        # end

        # @testset "@foo @bar @baz; OK" begin
        #     # Arrange
        #     input = TagExpressionInput("@foo @bar @baz")
        #     parser = SequenceParser{Tag}(
        #         SingleTagParser(),
        #         SingleTagParser()
        #     )

        #     # Act
        #     result = parser(input)

        #     # Assert
        #     @test result isa Selection.OKParseResult{Vector{Tag}}
        #     @test result.value == [Tag("@foo"), Tag("@bar"), Tag("@baz")]
        # end
    end

    # @testset "Not parser" begin
    #     @testset "Not @foo; OK" begin
    #         # Arrange
    #         input = TagExpressionInput("not @foo")
    #         parser = NotTagParser()

    #         # Act
    #         result = parser(input)

    #         # Assert
    #         @test result isa Selection.OKParseResult{Selection.Not}
    #         @test result.value == Selection.Not(Selection.Tag("@foo"))
    #     end
    # end
end