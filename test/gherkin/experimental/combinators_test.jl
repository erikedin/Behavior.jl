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
end