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

using Behavior.Gherkin.Experimental: BadExpectationParseResult, EscapedChar

@testset "Combinators          " begin
    @testset "Line" begin
        @testset "Match Foo; Foo; OK" begin
            # Arrange
            input = ParserInput("Foo")

            # Act
            p = Line("Foo")
            result = p(input)

            # Assert
            @test result isa OKParseResult{String}
            @test result.value == "Foo"
        end

        @testset "Match Foo; Bar; Not OK" begin
            # Arrange
            input = ParserInput("Foo")

            # Act
            p = Line("Bar")
            result = p(input)

            # Assert
            @test result isa BadParseResult{String}
            @test result.expected == "Bar"
            @test result.actual == "Foo"
        end

        @testset "Match Foo, then Bar; Foo Bar; OK" begin
            # Arrange
            input = ParserInput("""
                Foo
                Bar
            """)

            # Act
            foo = Line("Foo")
            bar = Line("Bar")
            result1 = foo(input)
            result2 = bar(result1.newinput)

            # Assert
            @test result1 isa OKParseResult{String}
            @test result1.value == "Foo"
            @test result2 isa OKParseResult{String}
            @test result2.value == "Bar"
        end

        @testset "Match Foo, then Bar; Foo Baz; Not OK" begin
            # Arrange
            input = ParserInput("""
                Foo
                Baz
            """)

            # Act
            foo = Line("Foo")
            bar = Line("Bar")
            result1 = foo(input)
            result2 = bar(result1.newinput)

            # Assert
            @test result1 isa OKParseResult{String}
            @test result1.value == "Foo"
            @test result2 isa BadParseResult{String}
            @test result2.expected == "Bar"
            @test result2.actual == "Baz"
        end

        @testset "Match Foo; Bar; Not OK, state is unchanged" begin
            # Arrange
            input = ParserInput("Foo")

            # Act
            p = Line("Bar")
            result = p(input)

            # Assert
            @test result isa BadParseResult{String}
            @test result.newinput == input
        end

        @testset "Match Foo; No more input; Unexpected EOF" begin
            # Arrange
            input = ParserInput("")

            # Act
            p = Line("Foo")
            result = p(input)

            # Assert
            @test result isa BadUnexpectedEOFParseResult{String}
            @test result.newinput == input
        end
    end

    @testset "Optionally" begin
        @testset "Optionally Foo; Foo; OK" begin
            # Arrange
            input = ParserInput("Foo")

            # Act
            parser = Optionally{String}(Line("Foo"))
            result = parser(input)

            # Assert
            @test result isa OKParseResult{Union{Nothing, String}}
            @test result.value == "Foo"
        end

        @testset "Optionally Foo; Bar; OK with nothing" begin
            # Arrange
            input = ParserInput("Bar")

            # Act
            parser = Optionally{String}(Line("Foo"))
            result = parser(input)

            # Assert
            @test result isa OKParseResult{Union{Nothing, String}}
            @test result.value === nothing
        end

        @testset "Optionally Bar; Bar; OK" begin
            # Arrange
            input = ParserInput("Bar")

            # Act
            parser = Optionally{String}(Line("Bar"))
            result = parser(input)

            # Assert
            @test result isa OKParseResult{Union{Nothing, String}}
            @test result.value == "Bar"
        end

        @testset "Optionally Foo then Bar; Foo Bar; OK" begin
            # Arrange
            input = ParserInput("""
                Foo
                Bar
            """)

            # Act
            parser1 = Optionally{String}(Line("Foo"))
            result1 = parser1(input)

            parser2 = Line("Bar")
            result2 = parser2(result1.newinput)

            # Assert
            @test result1 isa OKParseResult{Union{Nothing, String}}
            @test result1.value == "Foo"
            @test result2 isa OKParseResult{String}
            @test result2.value == "Bar"
        end

        @testset "Optionally Foo then Bar; Bar; OK" begin
            # Arrange
            input = ParserInput("""
                Bar
            """)

            # Act
            parser1 = Optionally{String}(Line("Foo"))
            result1 = parser1(input)

            parser2 = Line("Bar")
            result2 = parser2(result1.newinput)

            # Assert
            @test result1 isa OKParseResult{Union{Nothing, String}}
            @test result1.value === nothing
            @test result2 isa OKParseResult{String}
            @test result2.value == "Bar"
        end
    end

    @testset "Or" begin
        @testset "Foo or Bar; Foo; OK" begin
            # Arrange
            input = ParserInput("Foo")

            # Act
            p = Line("Foo") | Line("Bar")
            result = p(input)

            # Assert
            @test result isa OKParseResult{String}
            @test result.value == "Foo"
        end

        @testset "Foo or Bar; Bar; OK" begin
            # Arrange
            input = ParserInput("Bar")

            # Act
            p = Line("Foo") | Line("Bar")
            result = p(input)

            # Assert
            @test result isa OKParseResult{String}
            @test result.value == "Bar"
        end

        @testset "Foo or Bar; Baz; Not OK" begin
            # Arrange
            input = ParserInput("Baz")

            # Act
            p = Line("Foo") | Line("Bar")
            result = p(input)

            # Assert
            @test result isa BadParseResult{String}
        end

        @testset "Foo or Bar or Baz; Baz; OK" begin
            # Arrange
            input = ParserInput("Baz")

            # Act
            p = Or{String}(Line("Foo"), Line("Bar"), Line("Baz"))
            result = p(input)

            # Assert
            @test result isa OKParseResult{String}
            @test result.value == "Baz"
        end
    end

    @testset "Transformer" begin
        @testset "Transform to Int; 1; OK" begin
            # Arrange
            input = ParserInput("1")

            # Act
            digit = Line("1")
            p = Transformer{String, Int}(digit, x -> parse(Int, x))
            result = p(input)

            # Assert
            @test result isa OKParseResult{Int}
            @test result.value == 1
        end

        @testset "Transform to Int; 2; OK" begin
            # Arrange
            input = ParserInput("2")

            # Act
            digit = Line("1") | Line("2")
            p = Transformer{String, Int}(digit, x -> parse(Int, x))
            result = p(input)

            # Assert
            @test result isa OKParseResult{Int}
            @test result.value == 2
        end
    end

    @testset "Sequence" begin
        @testset "Sequence Line Baz; Baz; OK" begin
            # Arrange
            input = ParserInput("Baz")

            # Act
            p = Sequence{String}(Line("Baz"))
            result = p(input)

            # Assert
            @test result isa OKParseResult{Vector{String}}
            @test result.value == ["Baz"]
        end

        @testset "Sequence Line Baz then Quux; Baz Quux; OK" begin
            # Arrange
            input = ParserInput("""
                Baz
                Quux
            """)

            # Act
            p = Sequence{String}(Line("Baz"), Line("Quux"))
            result = p(input)

            # Assert
            @test result isa OKParseResult{Vector{String}}
            @test result.value == ["Baz", "Quux"]
        end

        @testset "Sequence Line Baz then Quux; Baz Bar; Not OK" begin
            # Arrange
            input = ParserInput("""
                Baz
                Bar
            """)

            # Act
            p = Sequence{String}(Line("Baz"), Line("Quux"))
            result = p(input)

            # Assert
            @test result isa BadParseResult{Vector{String}}
        end

        @testset "Sequence Line Baz then Quux; Foo Quux; Not OK" begin
            # Arrange
            input = ParserInput("""
                Foo
                Quux
            """)

            # Act
            p = Sequence{String}(Line("Baz"), Line("Quux"))
            result = p(input)

            # Assert
            @test result isa BadParseResult{Vector{String}}
        end

        @testset "Sequence Ints 1 then 2; 1 then 2; OK" begin
            # Arrange
            input = ParserInput("""
                1
                2
            """)

            # Act
            digits = Line("1") | Line("2")
            intparser = Transformer{String, Int}(digits, x -> parse(Int, x))
            p = Sequence{Int}(intparser, intparser)
            result = p(input)

            # Assert
            @test result isa OKParseResult{Vector{Int}}
            @test result.value == [1, 2]
        end
    end

    @testset "Joined" begin
        @testset "Join sequence of Baz or Quux; Baz Quux; OK" begin
            # Arrange
            input = ParserInput("""
                Baz
                Quux
            """)

            # Act
            s = Line("Baz") | Line("Quux")
            p = Joined(Sequence{String}(s, s))
            result = p(input)

            # Assert
            @test result isa OKParseResult{String}
            @test result.value == "Baz\nQuux"
        end

        @testset "Join sequence of Baz or Quux; Quux Baz; OK" begin
            # Arrange
            input = ParserInput("""
                Quux
                Baz
            """)

            # Act
            s = Line("Baz") | Line("Quux")
            p = Joined(Sequence{String}(s, s))
            result = p(input)

            # Assert
            @test result isa OKParseResult{String}
            @test result.value == "Quux\nBaz"
        end

        @testset "Join sequence of Baz or Quux; Foo Bar; Not OK" begin
            # Arrange
            input = ParserInput("""
                Foo
                Bar
            """)

            # Act
            s = Line("Baz") | Line("Quux")
            p = Joined(Sequence{String}(s, s))
            result = p(input)

            # Assert
            @test result isa BadParseResult{String}
        end
    end

    @testset "Repeating" begin
        @testset "Repeating Baz or Quux; Bar; OK and empty" begin
            # Arrange
            input = ParserInput("""
                Bar
            """)

            # Act
            s = Line("Baz") | Line("Quux")
            p = Repeating{String}(s)
            result = p(input)

            # Assert
            @test result isa OKParseResult{Vector{String}}
            @test result.value == []
        end

        @testset "Repeating Baz or Quux; Baz Quux Bar; OK" begin
            # Arrange
            input = ParserInput("""
                Baz
                Quux
                Bar
            """)

            # Act
            s = Line("Baz") | Line("Quux")
            p = Repeating{String}(s)
            result = p(input)

            # Assert
            @test result isa OKParseResult{Vector{String}}
            @test result.value == ["Baz", "Quux"]
        end

        @testset "Repeating Baz or Quux followed by Bar; Baz Quux Bar; OK" begin
            # Arrange
            input = ParserInput("""
                Baz
                Quux
                Bar
            """)

            # Act
            s = Line("Baz") | Line("Quux")
            p = Sequence{String}(Joined(Repeating{String}(s)), Line("Bar"))
            result = p(input)

            # Assert
            @test result isa OKParseResult{Vector{String}}
            @test result.value == ["Baz\nQuux", "Bar"]
        end

        @testset "Repeating digits; 3 2 1; OK" begin
            # Arrange
            input = ParserInput("""
                3
                2
                1
                Not a digit
            """)

            # Act
            digits = Line("1") | Line("2") | Line("3")
            intparser = Transformer{String, Int}(digits, x -> parse(Int, x))
            p = Repeating{Int}(intparser)
            result = p(input)

            # Assert
            @test result isa OKParseResult{Vector{Int}}
            @test result.value == [3, 2, 1]
        end

        @testset "Repeating Baz or Quux, at least 1; Bar; Not OK" begin
            # Arrange
            input = ParserInput("""
                Bar
            """)

            # Act
            s = Line("Baz") | Line("Quux")
            p = Repeating{String}(s, atleast=1)
            result = p(input)

            # Assert
            @test result isa BadParseResult{Vector{String}}
        end

        @testset "Repeating Baz or Quux, at least 1; Baz Bar; OK" begin
            # Arrange
            input = ParserInput("""
                Baz
                Bar
            """)

            # Act
            s = Line("Baz") | Line("Quux")
            p = Repeating{String}(s, atleast=1)
            result = p(input)

            # Assert
            @test result isa OKParseResult{Vector{String}}
            @test result.value == ["Baz"]
        end
    end

    @testset "LineIfNot" begin
        @testset "LineIfNot Baz; Baz; Not OK" begin
            # Arrange
            input = ParserInput("""
                Baz
            """)

            # Act
            p = LineIfNot(Line("Baz"))
            result = p(input)

            # Assert
            @test result isa BadParseResult{String}
            @test result.unexpected == "Baz"
        end

        @testset "LineIfNot Baz; Foo Baz; OK" begin
            # Arrange
            input = ParserInput("""
                Foo
            """)

            # Act
            p = LineIfNot(Line("Baz"))
            result = p(input)

            # Assert
            @test result isa OKParseResult{String}
            @test result.value == "Foo"
        end

        @testset "LineIfNot Baz then Baz; Bar Baz; OK" begin
            # Arrange
            input = ParserInput("""
                Bar
                Baz
            """)

            # Act
            p = Sequence{String}(LineIfNot(Line("Baz")), Line("Baz"))
            result = p(input)

            # Assert
            @test result isa OKParseResult{Vector{String}}
            @test result.value == ["Bar", "Baz"]
        end

        @testset "LineIfNot Baz; EOF; Not OK" begin
            # Arrange
            input = ParserInput("")

            # Act
            p = LineIfNot(Line("Baz"))
            result = p(input)

            # Assert
            @test result isa BadUnexpectedEOFParseResult{String}
            @test result.newinput == input
        end
    end

    @testset "StartsWith" begin
        @testset "Foo; Foo; OK" begin
            # Arrange
            input = ParserInput(
                """
                Foo
                """
            )

            # Act
            parser = StartsWith("Foo")
            result = parser(input)

            # Assert
            @test result isa OKParseResult{String}
            @test result.value == "Foo"
        end

        @testset "Foo; Bar; Not OK" begin
            # Arrange
            input = ParserInput(
                """
                Bar
                """
            )

            # Act
            parser = StartsWith("Foo")
            result = parser(input)

            # Assert
            @test result isa BadParseResult{String}
        end

        @testset "Foo; Foo Bar; OK" begin
            # Arrange
            input = ParserInput(
                """
                Foo Bar
                """
            )

            # Act
            parser = StartsWith("Foo")
            result = parser(input)

            # Assert
            @test result isa OKParseResult{String}
            @test result.value == "Foo Bar"
        end

        @testset "Foo the Quux; Foo Bar, Quux; OK" begin
            # Arrange
            input = ParserInput(
                """
                Foo Bar
                Quux
                """
            )

            # Act
            parser = Sequence{String}(StartsWith("Foo"), Line("Quux"))
            result = parser(input)

            # Assert
            @test result isa OKParseResult{Vector{String}}
            @test result.value == ["Foo Bar", "Quux"]
        end

        @testset "Foo; EOF; Not OK" begin
            # Arrange
            input = ParserInput("")

            # Act
            parser = StartsWith("Foo")
            result = parser(input)

            # Assert
            @test result isa BadUnexpectedEOFParseResult{String}
            @test result.newinput == input
        end
    end

    @testset "Whitespace and comments" begin
        @testset "Match Foo; Blank line, then Foo; OK" begin
            # Arrange
            input = ParserInput("""

                Foo
            """)

            # Act
            p = Line("Foo")
            result = p(input)

            # Assert
            @test result isa OKParseResult{String}
            @test result.value == "Foo"
        end

        @testset "Match Foo then Bar; Blank line, then Foo, Bar; OK" begin
            # Arrange
            input = ParserInput("""

                Foo
                Bar
            """)

            # Act
            p = Sequence{String}(Line("Foo"), Line("Bar"))
            result = p(input)

            # Assert
            @test result isa OKParseResult{Vector{String}}
            @test result.value[1] == "Foo"
            @test result.value[2] == "Bar"
        end

        @testset "Match Foo then Bar; Blank line between, then Foo, Bar; OK" begin
            # Arrange
            input = ParserInput("""
                Foo

                Bar
            """)

            # Act
            p = Sequence{String}(Line("Foo"), Line("Bar"))
            result = p(input)

            # Assert
            @test result isa OKParseResult{Vector{String}}
            @test result.value[1] == "Foo"
            @test result.value[2] == "Bar"
        end

        @testset "Match Foo then Bar; 3 blank line before and between, then Foo, Bar; OK" begin
            # Arrange
            input = ParserInput("""



                Foo



                Bar
            """)

            # Act
            p = Sequence{String}(Line("Foo"), Line("Bar"))
            result = p(input)

            # Assert
            @test result isa OKParseResult{Vector{String}}
            @test result.value[1] == "Foo"
            @test result.value[2] == "Bar"
        end

        @testset "Match Foo; Comment, then Foo; OK" begin
            # Arrange
            input = ParserInput("""
                # Some comment
                Foo
            """)

            # Act
            p = Line("Foo")
            result = p(input)

            # Assert
            @test result isa OKParseResult{String}
            @test result.value == "Foo"
        end

        @testset "Match Foo then Bar; Comment between, then Foo, Bar; OK" begin
            # Arrange
            input = ParserInput("""
                Foo
                # Skip this comment
                Bar
            """)

            # Act
            p = Sequence{String}(Line("Foo"), Line("Bar"))
            result = p(input)

            # Assert
            @test result isa OKParseResult{Vector{String}}
            @test result.value[1] == "Foo"
            @test result.value[2] == "Bar"
        end
    end

    @testset "EOF" begin
        @testset "No non-blank lines left; OK" begin
            # Arrange
            input = ParserInput("")

            # Act
            parser = EOFParser()
            result = parser(input)

            # Assert
            @test result isa OKParseResult{Nothing}
        end

        @testset "Line Foo; Not OK" begin
            # Arrange
            input = ParserInput("Foo")

            # Act
            parser = EOFParser()
            result = parser(input)

            # Assert
            @test result isa BadExpectedEOFParseResult{Nothing}
        end

        @testset "Foo, then EOF; OK" begin
            # Arrange
            input = ParserInput("Foo")

            # Act
            parser = Sequence{Union{Nothing, String}}(Line("Foo"), EOFParser())
            result = parser(input)

            # Assert
            @test result isa OKParseResult{Vector{Union{Nothing, String}}}
            @test result.value[1] == "Foo"
            @test result.value[2] === nothing
        end

        @testset "Foo, then Bar; Not OK" begin
            # Arrange
            input = ParserInput("""
                Foo
                Bar
            """)

            # Act
            parser = Sequence{Union{Nothing, String}}(Line("Foo"), EOFParser())
            result = parser(input)

            # Assert
            @test result isa BadParseResult{Vector{Union{Nothing, String}}}
        end

        @testset "Feature, then EOF; OK" begin
            # Arrange
            input = ParserInput("""
                Feature: Some feature

                    Scenario: Some scenario

                    Scenario: Other scenario
            """)

            # Act
            parser = Sequence{Union{Nothing, Feature}}(FeatureParser(), EOFParser())
            result = parser(input)

            # Assert
            @test result isa OKParseResult{Vector{Union{Nothing, Feature}}}
            @test result.value[1] isa Feature
            @test result.value[2] === nothing
        end

        @testset "Feature, then unallowed new feature; Not OK" begin
            # Arrange
            input = ParserInput("""
                Feature: Some feature

                    Scenario: Some scenario

                    Scenario: Other scenario

                    Feature: Not allowed here
            """)

            # Act
            parser = Sequence{Union{Nothing, Feature}}(FeatureParser(), EOFParser())
            result = parser(input)

            # Assert
            @test result isa BadParseResult{Vector{Union{Nothing, Feature}}}
        end
    end

    @testset "EscapedChar" begin
        @testset "EscapedChar; String is A; OK" begin
            # Arrange
            input = ParserInput(
                """
                A
                """
            )

            # Act
            parser = EscapedChar()
            result = parser(input)

            # Assert
            @test result isa OKParseResult{Char}
            @test result.value == 'A'
        end

        @testset "EscapedChar; String is B; OK" begin
            # Arrange
            input = ParserInput(
                """
                B
                """
            )

            # Act
            parser = EscapedChar()
            result = parser(input)

            # Assert
            @test result isa OKParseResult{Char}
            @test result.value == 'B'
        end

        @testset "EscapedChar; String is AB; Read A then B" begin
            # Arrange
            input = ParserInput(
                """
                AB
                """
            )

            # Act
            parser = EscapedChar()
            result1 = parser(input)
            result2 = parser(result1.newinput)

            # Assert
            @test result1.value == 'A'
            @test result2.value == 'B'
        end

        @testset "EscapedChar; String is | escaped; Char is |" begin
            # Arrange
            input = ParserInput(
                """
                \\|
                """
            )

            # Act
            parser = EscapedChar()
            result = parser(input)

            # Assert
            @test result isa OKParseResult{Char}
            @test result.value == '|'
        end
    end
end