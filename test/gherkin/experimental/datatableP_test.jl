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

using Behavior.Gherkin.Experimental: ParserInput, tablecellP, escapeP, charP, manyC, satisfyC, datatableP, commentP, tablerowP
using Behavior.Gherkin.Experimental: BadTableRowsParseResult
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

@testset "tablecellP; Input has a newline in the cell; BadParseResult" begin
    # Arrange
    input = ParserInput("abc\ndef|")

    # Act
    result = tablecellP(input)

    # Assert
    @test result isa BadParseResult{String}
end

@testset "tablecellP; Input has a single leading space; Space is stripped" begin
    # Arrange
    # The leading x is required because ParserInput automatically strips leading and trailing
    # spaces from the input. Here we need to keep that space, so we prefix it by a character.
    # The x is parsed, so it's not part of the input to tablecellP.
    prefixedinput = ParserInput("x abc|")
    prefixresult = charP(prefixedinput)
    input = prefixresult.newinput

    # Act
    result = tablecellP(input)

    # Assert
    @test result isa OKParseResult{String}
    @test result.value == "abc"
end

@testset "tablecellP; Input has leading spaces; Spaces are stripped" begin
    # Arrange
    # The leading x is required because ParserInput automatically strips leading and trailing
    # spaces from the input. Here we need to keep that space, so we prefix it by a character.
    # The x is parsed, so it's not part of the input to tablecellP.
    prefixedinput = ParserInput("x  abc|")
    prefixresult = charP(prefixedinput)
    input = prefixresult.newinput

    # Act
    result = tablecellP(input)

    # Assert
    @test result isa OKParseResult{String}
    @test result.value == "abc"
end

@testset "tablecellP; Input has a single trailing space; Space is stripped" begin
    # Arrange
    input = ParserInput("abc |")

    # Act
    result = tablecellP(input)

    # Assert
    @test result isa OKParseResult{String}
    @test result.value == "abc"
end

@testset "tablecellP; Input has trailing spaces; Spaces are stripped" begin
    # Arrange
    input = ParserInput("abc  |")

    # Act
    result = tablecellP(input)

    # Assert
    @test result isa OKParseResult{String}
    @test result.value == "abc"
end

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

@testset "datatableP; Input is |abc| then |def|; Table is [[abc], [def]]" begin
    # Arrange
    input = ParserInput("|abc|\n|def|")

    # Act
    result = datatableP(input)

    # Assert
    @test result isa OKParseResult{DataTable}
    @test result.value == DataTable([["abc"], ["def"]])
end

@testset "datatableP; Input is |abc| then |def| then ghi; Table is [[abc], [def]]" begin
    # Arrange
    input = ParserInput("|abc|\n|def|\nghi")

    # Act
    result = datatableP(input)

    # Assert
    @test result isa OKParseResult{DataTable}
    @test result.value == DataTable([["abc"], ["def"]])
end

@testset "datatableP; Input is |abc| then |def| then ghi; Table is [[abc], [def]]" begin
    # Arrange
    table = """
    |abc|def|ghi|
    |jkl|mno|pqr|
    """
    input = ParserInput(table)

    # Act
    result = datatableP(input)

    # Assert
    @test result isa OKParseResult{DataTable}
    @test result.value == DataTable([["abc", "def", "ghi"], ["jkl", "mno", "pqr"]])
end

@testset "datatableP; The row has an empty cell |abc||def|; Table is [[abc, , def]]" begin
    # Arrange
    table = """
    |abc||def|
    """
    input = ParserInput(table)

    # Act
    result = datatableP(input)

    # Assert
    @test result isa OKParseResult{DataTable}
    @test result.value == DataTable([["abc", "", "def"]])
end

@testset "datatableP; Table cells have leading and trailing spaces; Spaces in table cells are stripped" begin
    # Arrange
    table = """
    | abc | def | ghi |
    | jkl | mno | pqr |
    """
    input = ParserInput(table)

    # Act
    result = datatableP(input)

    # Assert
    @test result isa OKParseResult{DataTable}
    @test result.value == DataTable([["abc", "def", "ghi"], ["jkl", "mno", "pqr"]])
end

@testset "datatableP; Table rows have leading spaces; Leading spaces are ignored" begin
    # Arrange
    table = """
    | abc | def | ghi |
       | jkl | mno | pqr |
    """
    input = ParserInput(table)

    # Act
    result = datatableP(input)

    # Assert
    @test result isa OKParseResult{DataTable}
    @test result.value == DataTable([["abc", "def", "ghi"], ["jkl", "mno", "pqr"]])
end

@testset "datatableP; Table rows have trailing spaces; Trailing spaces are ignored" begin
    # Arrange
    # Editors often automatically remove trailing spaces on lines, so this table is
    # on a single line to prevent the spaces from being removed.
    table = "| abc | def | ghi |   \n| jkl | mno | pqr |"
    input = ParserInput(table)

    # Act
    result = datatableP(input)

    # Assert
    @test result isa OKParseResult{DataTable}
    @test result.value == DataTable([["abc", "def", "ghi"], ["jkl", "mno", "pqr"]])
end

@testset "commentP; Character a followed by comment; Only character a returned" begin
    # Arrange
    table = """
    a# This is a comment
    """
    input = ParserInput(table)
    parser = isC('a', charP) >> -commentP

    # Act
    result = parser(input)

    # Assert
    @test result isa OKParseResult{Char}
    @test result.value == 'a'
end

@testset "commentP; The comment consumes leading spaces; All input consumed" begin
    # Arrange
    table = """
    a   # This is a comment
    """
    input = ParserInput(table)
    parser = isC('a', charP) >> -optionalC(commentP)

    # Act
    result = parser(input)
    nextresult = eofP(result.newinput)

    # Assert
    @test result isa OKParseResult{Char}
    @test nextresult isa OKParseResult{Nothing}
end

@testset "commentP; The row has no comment; All input consumed" begin
    # Arrange
    table = "a"
    input = ParserInput(table)
    parser = isC('a', charP) >> -optionalC(commentP)

    # Act
    result = parser(input)
    nextresult = eofP(result.newinput)

    # Assert
    @test result isa OKParseResult{Char}
    @test result.value == 'a'
    @test nextresult isa OKParseResult{Nothing}
end

@testset "tablerowP; The table row has a comment; All input consumed" begin
    # Arrange
    table = """
    |a|b| # This is a comment
    """
    input = ParserInput(table)

    # Act
    result = tablerowP(input)
    nextresult = eofP(result.newinput)

    # Assert
    @test result isa OKParseResult{Vector{String}}
    @test result.value == ["a", "b"]
    @test nextresult isa OKParseResult{Nothing}
end

@testset "datatableP; Table rows have trailing comments; Trailing comments are ignored" begin
    # Arrange
    table = """
    | abc | def | ghi | # This is a comment
    | jkl | mno | pqr |
    """
    input = ParserInput(table)

    # Act
    result = datatableP(input)

    # Assert
    @test result isa OKParseResult{DataTable}
    @test result.value == DataTable([["abc", "def", "ghi"], ["jkl", "mno", "pqr"]])
end

@testset "datatableP; A row has an escaped pipe; The escaped pipe is part of the cell" begin
    # Arrange
    table = """
    | abc | \\| | ghi |
    """
    input = ParserInput(table)

    # Act
    result = datatableP(input)

    # Assert
    @test result isa OKParseResult{DataTable}
    @test result.value == DataTable([["abc", "|", "ghi"]])
end

@testset "datatableP; The rows have different number of cells; BadParseResult" begin
    # Arrange
    table = """
    | abc | def | ghi |
    | jkl | mno | pqr | stu |
    """
    input = ParserInput(table)

    # Act
    result = datatableP(input)

    # Assert
    @test result isa BadTableRowsParseResult{DataTable}
    @test result.table == [["abc", "def", "ghi"], ["jkl", "mno", "pqr", "stu"]]
end

end # datatableP