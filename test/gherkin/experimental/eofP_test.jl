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

using Behavior.Gherkin.Experimental: ParserInput, eofP

@testset "eofP                          " begin

@testset "eofP; Input is a; BadParseResult" begin
    # Arrange
    input = ParserInput("a")

    # Act
    result = eofP(input)

    # Assert
    @test result isa BadParseResult{Nothing}
end

@testset "eofP; Input is empty; OK" begin
    # Arrange
    input = ParserInput("")

    # Act
    result = eofP(input)

    # Assert
    @test result isa OKParseResult{Nothing}
    @test result.value === nothing
end

end # eofP
