using ExecutableSpecifications
using ExecutableSpecifications.Gherkin

# In case you want a more lenient parser, you can do something like this.
# For instance, the below options allows the Given/When/Then steps to be in any order
# exitcode = runspec(; parseoptions=ParseOptions(allow_any_step_order=true)) ? 0 : - 1

exitcode = runspec() ? 0 : - 1
exit(exitcode)