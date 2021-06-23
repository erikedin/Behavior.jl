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

@testset "Gherkin combinators  " begin
    @testset "Block text" begin
        @testset "Empty; OK" begin
            # Arrange
            input = ParserInput("""
                \"\"\"
                \"\"\"
            """)
            # Act
            p = BlockText()
            result = p(input)

            # Assert
            @test result isa OKParseResult{String}
            @test result.value == ""
        end

        @testset "Empty, then Quux; OK" begin
            # Arrange
            input = ParserInput("""
                \"\"\"
                \"\"\"
                Quux
            """)
            # Act
            p = Sequence{String}(BlockText(), Line("Quux"))
            result = p(input)

            # Assert
            @test result isa OKParseResult{Vector{String}}
            @test result.value == ["", "Quux"]
        end

        @testset "Foo; OK" begin
            # Arrange
            input = ParserInput("""
                \"\"\"
                Foo
                \"\"\"
            """)
            # Act
            p = BlockText()
            result = p(input)

            # Assert
            @test result isa OKParseResult{String}
            @test result.value == "Foo"
        end

        @testset "Foo Bar Baz; OK" begin
            # Arrange
            input = ParserInput("""
                \"\"\"
                Foo
                Bar
                Baz
                \"\"\"
            """)
            # Act
            p = BlockText()
            result = p(input)

            # Assert
            @test result isa OKParseResult{String}
            @test result.value == "Foo\nBar\nBaz"
        end

        @testset "Foo Bar Baz, then Quux; OK" begin
            # Arrange
            input = ParserInput("""
                \"\"\"
                Foo
                Bar
                Baz
                \"\"\"
                Quux
            """)
            # Act
            p = Sequence{String}(BlockText(), Line("Quux"))
            result = p(input)

            # Assert
            @test result isa OKParseResult{Vector{String}}
            @test result.value == ["Foo\nBar\nBaz", "Quux"]
        end
    end
end