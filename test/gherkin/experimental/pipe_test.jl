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

using Behavior.Gherkin.Experimental: ParserInput, charP, satisfyC, to, EscapeChar

@testset "chainC |>            " begin

@testset "charP |> charP; Input is ab; Result is b" begin
    # Arrange
    input = ParserInput("ab")

    # Act
    parser = charP |> charP
    result = parser(input)

    # Assert
    @test result isa OKParseResult{Char}
    @test result.value == 'b'
end

@testset "charP |> charP; Input is empty; BadParseResult" begin
    # Arrange
    input = ParserInput("")

    # Act
    parser = charP |> charP
    result = parser(input)

    # Assert
    @test result isa BadParseResult{Char}
end

@testset "satisfy(\\) |> charP; Input is \\a; Result is a" begin
    # Arrange
    input = ParserInput(raw"\a")

    # Act
    parser = satisfyC(c -> c == '\\', charP) |> charP
    result = parser(input)

    # Assert
    @test result isa OKParseResult{Char}
    @test result.value == 'a'
end

@testset "satisfy(\\) |> charP |> to{EscapeChar}; Input is \\a; Result is EscapeChar(a)" begin
    # Arrange
    input = ParserInput(raw"\a")

    # Act
    parser = satisfyC(c -> c == '\\', charP) |> charP |> to{EscapeChar}()
    result = parser(input)

    # Assert
    @test result isa OKParseResult{EscapeChar}
    @test result.value == EscapeChar('a')
end

end # chainC |>