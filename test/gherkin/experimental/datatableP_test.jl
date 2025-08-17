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

using Behavior.Gherkin.Experimental: ParserInput, tablecellP, escapeP, charP, manyC, satisfyC, datatableP
using Behavior.Gherkin: DataTable

@testset "datatableP           " begin

@testset "tablecellP; Input is abc|; Element is abc " begin
    # Arrange
    input = ParserInput("abc|")

    # Act
    result = tablecellP(input)

    # Assert
    @test result isa OKParseResult{String}
    @test result.value == "abc"
end

@testset "tablecellP; Input is empty; BadParseResult" begin
    # Arrange
    input = ParserInput("")

    # Act
    result = tablecellP(input)

    # Assert
    @test result isa BadParseResult{String}
end

@testset "tablecellP; Input is abc; BadParseResult" begin
    # Arrange
    input = ParserInput("abc")

    # Act
    result = tablecellP(input)

    # Assert
    @test result isa BadParseResult{String}
end

# This test implements tablecellP, which ensures that we have all the necessary
# parts to finish the implementation in the Gherkin module.
@testset "tablecellP implementation check; Input is def|; Element is def" begin
     # Arrange
     input = ParserInput("def|")

     # Act
     notpipeP = satisfyC(c -> c != '|', escapeP)
     untilpipeP = manyC(notpipeP) |> to{String}(join)
     result = untilpipeP(input)

     # Assert
     @test result isa OKParseResult{String}
     @test result.value == "def"
end

@testset "tablecellP; Input is def|; Element is def " begin
    # Arrange
    input = ParserInput("def|")

    # Act
    result = tablecellP(input)

    # Assert
    @test result isa OKParseResult{String}
    @test result.value == "def"
end

# @testset "tablecellP; Input has a newline in the cell; BadParseResult" begin
#     # Arrange
#     input = ParserInput("abc\ndef|")
#
#     # Act
#     result = tablecellP(input)
#
#     # Assert
#     @test result isa BadParseResult{String}
# end

@testset "datatableP; Input is |def|; Table is [[def]]" begin
    # Arrange
    input = ParserInput("|def|")

    # Act
    result = datatableP(input)

    # Assert
    @test result isa OKParseResult{DataTable}
    @test result.value == DataTable([["def"]])
end

@testset "datatableP; Input is empty; BadParseResult" begin
    # Arrange
    input = ParserInput("")

    # Act
    result = datatableP(input)

    # Assert
    @test result isa BadParseResult{DataTable}
end

@testset "datatableP; Input is |abc|def|; Table is [[abc, def]]" begin
    # Arrange
    input = ParserInput("|abc|def|")

    # Act
    result = datatableP(input)

    # Assert
    @test result isa OKParseResult{DataTable}
    @test result.value == DataTable([["abc", "def"]])
end

@testset "datatableP; Input is |abc|def|ghi|; Table is [[abc, def, ghi]]" begin
    # Arrange
    input = ParserInput("|abc|def|ghi|")

    # Act
    result = datatableP(input)

    # Assert
    @test result isa OKParseResult{DataTable}
    @test result.value == DataTable([["abc", "def", "ghi"]])
end

@testset "datatableP; Input is |abc; BadParseResult" begin
    # Arrange
    input = ParserInput("|abc")

    # Act
    result = datatableP(input)

    # Assert
    @test result isa BadParseResult{DataTable}
end

# @testset "datatableP; Input is |abc| then |def|; Table is [[abc], [def]]" begin
#     # Arrange
#     input = ParserInput("|abc|\n|def|")
#
#     # Act
#     result = datatableP(input)
#
#     # Assert
#     @test result isa OKParseResult{DataTable}
#     @test result.value == DataTable([["abc"], ["def"]])
# end

end # datatableP