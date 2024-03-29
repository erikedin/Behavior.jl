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
using Behavior.Selection: TagExpressionInput, SingleTagParser, SequenceParser, Tag, AnyTagExpression, NotTagParser, ParenthesesParser
using Behavior.Selection: TagExpression

@testset "Selection combinators" begin

    @testset "Repeating" begin
        @testset "While tag; not @b; OK, empty" begin
            # Arrange
            input = TagExpressionInput("not @b")
            parser = Selection.Repeating(SingleTagParser())

            # Act
            result = parser(input)

            # Assert
            @test result isa Selection.OKParseResult{Vector{Tag}}
            @test result.value == []
        end

        @testset "While tag; @a not @b; OK, a" begin
            # Arrange
            input = TagExpressionInput("@a not @b")
            parser = Selection.Repeating(SingleTagParser())

            # Act
            result = parser(input)

            # Assert
            @test result isa Selection.OKParseResult{Vector{Tag}}
            @test result.value == [Tag("@a")]
        end

        @testset "While tag; @a @c not @b; OK, ac" begin
            # Arrange
            input = TagExpressionInput("@a @c not @b")
            parser = Selection.Repeating(SingleTagParser())

            # Act
            result = parser(input)

            # Assert
            @test result isa Selection.OKParseResult{Vector{Tag}}
            @test result.value == [Tag("@a"), Tag("@c")]
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

        @testset "foo; Not OK" begin
            # Arrange
            input = TagExpressionInput("foo")
            parser = SingleTagParser()

            # Act
            result = parser(input)

            # Assert
            @test result isa Selection.BadParseResult{Selection.Tag}
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
        @testset "@foo then @bar; OK" begin
            # Arrange
            input = TagExpressionInput("@foo @bar")
            parser = SequenceParser{Tag}(
                SingleTagParser(),
                SingleTagParser()
            )

            # Act
            result = parser(input)

            # Assert
            @test result isa Selection.OKParseResult{Vector{Tag}}
            @test result.value == [Tag("@foo"), Tag("@bar")]
        end

        @testset "@foo @bar @baz; OK" begin
            # Arrange
            input = TagExpressionInput("@foo @bar @baz")
            parser = SequenceParser{Tag}(
                SingleTagParser(),
                SingleTagParser(),
                SingleTagParser()
            )

            # Act
            result = parser(input)

            # Assert
            @test result isa Selection.OKParseResult{Vector{Tag}}
            @test result.value == [Tag("@foo"), Tag("@bar"), Tag("@baz")]
        end

        @testset "@foo @bar, then a standalone @baz; OK" begin
            # Arrange
            input = TagExpressionInput("@foo @bar @baz")
            parser1 = SequenceParser{Tag}(
                SingleTagParser(),
                SingleTagParser()
            )

            # Act
            result1 = parser1(input)
            parser2 = SingleTagParser()
            result2 = parser2(result1.newinput)

            # Assert
            @test result1 isa Selection.OKParseResult{Vector{Tag}}
            @test result1.value == [Tag("@foo"), Tag("@bar")]
            @test result2 isa Selection.OKParseResult{Tag}
            @test result2.value == Tag("@baz")
        end

        @testset "not @a then @c; @c; Not OK" begin
            # Arrange
            input = TagExpressionInput("@c")
            parser = SequenceParser{Selection.TagExpression}(
                NotTagParser(),
                SingleTagParser()
            )

            # Act
            result = parser(input)

            # Assert
            @test result isa Selection.BadParseResult{Vector{Selection.TagExpression}}
        end
    end

    @testset "Literal parser" begin
        @testset "Literal foo; foo; OK" begin
            # Arrange
            input = TagExpressionInput("foo")
            parser = Selection.Literal("foo")

            # Act
            result = parser(input)

            # Assert
            @test result isa Selection.OKParseResult{String}
            @test result.value == "foo"
        end

        @testset "Literal foo; bar; Not OK" begin
            # Arrange
            input = TagExpressionInput("bar")
            parser = Selection.Literal("foo")

            # Act
            result = parser(input)

            # Assert
            @test result isa Selection.BadParseResult{String}
        end

        @testset "Literal foobar; bar; Not OK" begin
            # Arrange
            input = TagExpressionInput("bar")
            parser = Selection.Literal("foobar")

            # Act
            result = parser(input)

            # Assert
            @test result isa Selection.BadParseResult{String}
        end

        @testset "Literal foo then bar; foobar; OK" begin
            # Arrange
            input = TagExpressionInput("foobar")

            # Act
            parser = SequenceParser{String}(
                Selection.Literal("foo"),
                Selection.Literal("bar")
            )
            result = parser(input)

            # Assert
            @test result isa Selection.OKParseResult{Vector{String}}
            @test result.value == ["foo", "bar"]
        end
    end

    @testset "Or parser" begin
        @testset "@foo or @bar; OK" begin
            # Arrange
            input = TagExpressionInput("@foo or @bar")
            parser = AnyTagExpression()

            # Act
            result = parser(input)

            # Assert
            @test result isa Selection.OKParseResult{TagExpression}
            @test result.value == Selection.Or(Tag("@foo"), Tag("@bar"))
        end

        # TODO When Or parser support tag expressions.
        #      Currently they only support single tags.
        # @testset "(not @foo) or @bar; OK" begin
        #     # Arrange
        #     input = TagExpressionInput("(not @foo) or @bar")
        #     parser = AnyTagExpression()

        #     # Act
        #     result = parser(input)

        #     # Assert
        #     @test result isa Selection.OKParseResult{Selection.Or}
        #     @test result.value == Selection.Or(
        #         Selection.Parentheses(
        #             Selection.Not(Tag("@foo"))),
        #         Tag("@bar"))
        # end
    end

    @testset "ParenthesesParser" begin
        @testset "Parentheses around tag; (@foo); OK, tag @foo" begin
            # Arrange
            input = TagExpressionInput("(@foo)")
            parser = Selection.ParenthesesParser()

            # Act
            result = parser(input)

            # Assert
            @test result isa Selection.OKParseResult{Selection.Parentheses}
            @test result.value == Selection.Parentheses(Tag("@foo"))
        end

        @testset "Parentheses around Or; (@foo or @bar); OK, @foo or @bar" begin
            # Arrange
            input = TagExpressionInput("(@foo or @bar)")
            parser = Selection.ParenthesesParser()

            # Act
            result = parser(input)

            # Assert
            @test result isa Selection.OKParseResult{Selection.Parentheses}
            @test result.value == Selection.Parentheses(Selection.Or(Tag("@foo"), Tag("@bar")))
        end
    end

    @testset "AnyOfParser" begin
        @testset "AnyOf Tag, Not; @a; OK, @a" begin
            # Arrange
            input = TagExpressionInput("@a")
            parser = Selection.AnyOfParser(
                SingleTagParser(),
                NotTagParser()
            )

            # Act
            result = parser(input)

            # Assert
            @test result isa Selection.OKParseResult{Selection.TagExpression}
            @test result.value == Tag("@a")
        end

        @testset "AnyOf Tag,Not; not @c ; OK, not @c" begin
            # Arrange
            input = TagExpressionInput("not @c")
            parser = Selection.AnyOfParser(
                SingleTagParser(),
                NotTagParser()
            )

            # Act
            result = parser(input)

            # Assert
            @test result isa Selection.OKParseResult{Selection.TagExpression}
            @test result.value == Selection.Not(Selection.Tag("@c"))
        end

        @testset "AnyOf Or,Not; @c; Not OK" begin
            # Arrange
            input = TagExpressionInput("@c")
            parser = Selection.AnyOfParser(
                ParenthesesParser(),
                NotTagParser()
            )

            # Act
            result = parser(input)

            # Assert
            @test result isa Selection.BadParseResult{Selection.TagExpression}
        end

        @testset "AnyOf Group,Not; @c; AnyOfParser fails, next parser finds @c" begin
            # Arrange
            input = TagExpressionInput("@c")
            parser1 = Selection.AnyOfParser(
                ParenthesesParser(), 
                NotTagParser()
            )
            parser2 = SingleTagParser()

            # Act
            result1 = parser1(input)
            result2 = parser2(result1.newinput)

            # Assert
            @test result2 isa Selection.OKParseResult{Tag}
            @test result2.value == Tag("@c")
        end

    end

    @testset "AnyTagExpression" begin
        @testset "AnyTagExpression; @a; OK" begin
            # Arrange
            input = TagExpressionInput("@a")
            parser = AnyTagExpression()

            # Act
            result = parser(input)

            # Assert
            @test result isa Selection.OKParseResult{Selection.TagExpression}
            @test result.value == Tag("@a")
        end

        @testset "AnyTagExpression; not @a; OK" begin
            # Arrange
            input = TagExpressionInput("not @a")
            parser = AnyTagExpression()

            # Act
            result = parser(input)

            # Assert
            @test result isa Selection.OKParseResult{Selection.TagExpression}
            @test result.value == Selection.Not(Tag("@a"))
        end

        @testset "AnyTagExpression; @a or @b; OK" begin
            # Arrange
            input = TagExpressionInput("@a or @b")
            parser = AnyTagExpression()

            # Act
            result = parser(input)

            # Assert
            @test result isa Selection.OKParseResult{Selection.TagExpression}
            @test result.value == Selection.Or(Tag("@a"), Tag("@b"))
        end

        @testset "AnyTagExpression; (@a); OK" begin
            # Arrange
            input = TagExpressionInput("(@a)")
            parser = AnyTagExpression()

            # Act
            result = parser(input)

            # Assert
            @test result isa Selection.OKParseResult{Selection.TagExpression}
            @test result.value == Selection.Parentheses(Tag("@a"))
        end

        @testset "AnyTagExpression; (@a or @b); OK" begin
            # Arrange
            input = TagExpressionInput("(@a or @b)")
            parser = AnyTagExpression()

            # Act
            result = parser(input)

            # Assert
            @test result isa Selection.OKParseResult{Selection.TagExpression}
            @test result.value == Selection.Parentheses(
                Selection.Or(Tag("@a"), Tag("@b"))
            )
        end

        @testset "AnyTagExpression; (not @c); OK" begin
            # Arrange
            input = TagExpressionInput("(not @c)")
            parser = AnyTagExpression()

            # Act
            result = parser(input)

            # Assert
            @test result isa Selection.OKParseResult{Selection.TagExpression}
            @test result.value == Selection.Parentheses(
                Selection.Not(Tag("@c"))
            )
        end

        @testset "AnyTagExpression; not (@a or @b); OK" begin
            # Arrange
            input = TagExpressionInput("not (@a or @b)")
            parser = AnyTagExpression()

            # Act
            result = parser(input)

            # Assert
            @test result isa Selection.OKParseResult{Selection.TagExpression}
            @test result.value == Selection.Not(
                Selection.Parentheses(
                    Selection.Or(Tag("@a"), Tag("@b"))
                )
            )
        end

        @testset "SingleTag, Or; @a or @c; Longest, @a or @c, OK" begin
            # Arrange
            input = TagExpressionInput("@a or @c")
            parser = AnyTagExpression()

            # Act
            result = parser(input)

            # Assert
            @test result isa Selection.OKParseResult{Selection.TagExpression}
            @test result.value == Selection.Or(Tag("@a"), Tag("@c"))
        end
    end
end