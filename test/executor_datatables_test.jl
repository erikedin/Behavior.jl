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

using .Gherkin: DataTable, DataTableRow

@testset "Executor Datatables  " begin
    @testset "Scenario step has a data table; Context contains the data tables" begin
        table = DataTable(
            DataTableRow[
                ["header1", "header2"],
                ["value 11", "value 12"],
                ["value 21", "value 22"],
            ]
        )
        given = Given("Some precondition", datatable=table)
        function check_datatable_step_definition(context::StepDefinitionContext, _args)
            expectedtable = DataTable(
                DataTableRow[
                    ["header1", "header2"],
                    ["value 11", "value 12"],
                    ["value 21", "value 22"],
                ]
            )

            if context.datatable == expectedtable
                Behavior.SuccessfulStepExecution()
            else
                Behavior.StepFailed("")
            end
        end
        stepdefmatcher = FakeStepDefinitionMatcher(Dict(given => check_datatable_step_definition))
        executor = Behavior.Executor(stepdefmatcher)
        scenario = Scenario("Description", String[], ScenarioStep[given])

        scenarioresult = Behavior.executescenario(executor, [Background()], scenario)

        @test isa(scenarioresult.steps[1], Behavior.SuccessfulStepExecution)
    end

    @testset "Scenario step has no data table; Context table is empty" begin
        given = Given("Some precondition")
        function check_datatable_step_definition(context::StepDefinitionContext, _args)
            if context.datatable == []
                Behavior.SuccessfulStepExecution()
            else
                Behavior.StepFailed("")
            end
        end
        stepdefmatcher = FakeStepDefinitionMatcher(Dict(given => check_datatable_step_definition))
        executor = Behavior.Executor(stepdefmatcher)
        scenario = Scenario("Description", String[], ScenarioStep[given])

        scenarioresult = Behavior.executescenario(executor, [Background()], scenario)

        @test isa(scenarioresult.steps[1], Behavior.SuccessfulStepExecution)
    end

    @testset "First step has table but not second; Second context table is empty" begin
        given1 = Given("Some precondition")
        given2 = Given("Some other precondition")
        function check_datatable_step_definition(context::StepDefinitionContext, _args)
            if context.datatable == []
                Behavior.SuccessfulStepExecution()
            else
                Behavior.StepFailed("")
            end
        end
        stepdefmatcher = FakeStepDefinitionMatcher(Dict(
            given1 => successful_step_definition,
            given2 => check_datatable_step_definition
        ))
        executor = Behavior.Executor(stepdefmatcher)
        scenario = Scenario("Description", String[], ScenarioStep[given1, given2])

        scenarioresult = Behavior.executescenario(executor, [Background()], scenario)

        @test isa(scenarioresult.steps[2], Behavior.SuccessfulStepExecution)
    end

    @testset "Scenario Outline step has a data table; Context contains the data tables" begin
        table = DataTable(
            DataTableRow[
                ["header1", "header2"],
            ]
        )
        given = Given("Some precondition <foo>", datatable=table)
        when = When("Some precondition", datatable=table)
        then = Then("Some precondition", datatable=table)
        function check_datatable_step_definition(context::StepDefinitionContext, _args)
            expectedtable = DataTable(
                DataTableRow[
                    ["header1", "header2"],
                ]
            )

            if context.datatable == expectedtable
                Behavior.SuccessfulStepExecution()
            else
                Behavior.StepFailed("")
            end
        end
        stepdefmatcher = FakeStepDefinitionMatcher(Dict(
            Given("Some precondition 1") => check_datatable_step_definition,
            Given("Some precondition 2") => check_datatable_step_definition,
            Given("Some precondition 3") => check_datatable_step_definition,
            when => check_datatable_step_definition,
            then => check_datatable_step_definition,
        ))
        executor = Behavior.Executor(stepdefmatcher)
        scenario = ScenarioOutline(
            "Description",
            String[],                        # Tags
            ScenarioStep[given, when, then], # Steps
            ["foo"],                         # Placeholders
            [["1"], ["2"]]                       # Examples
        )

        scenarioresult = Behavior.executescenario(executor, [Background()], scenario)

        @test isa(scenarioresult[1].steps[1], Behavior.SuccessfulStepExecution)
        @test isa(scenarioresult[1].steps[2], Behavior.SuccessfulStepExecution)
        @test isa(scenarioresult[1].steps[3], Behavior.SuccessfulStepExecution)
        @test isa(scenarioresult[2].steps[1], Behavior.SuccessfulStepExecution)
        @test isa(scenarioresult[2].steps[2], Behavior.SuccessfulStepExecution)
        @test isa(scenarioresult[2].steps[3], Behavior.SuccessfulStepExecution)
    end


end