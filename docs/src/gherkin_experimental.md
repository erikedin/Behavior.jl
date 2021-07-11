# Gherkin Experimental Parser
There is a new Gherkin parser, which has support for Rules, and will
replace the current Gherkin parser. It is possible to use this new parser today,
with an experimental flag.

## Command line
If you are running Behavior from the command line,
add a flag like this, to try this new parser

```bash
$ julia cmd/runspec.jl --experimental
```

```bash
$ julia cmd/suggeststeps.jl features/Some.feature features/steps --experimental
```

```bash
$ julia cmd/parseonly.jl features/ --experimental
```

## Using ParseOptions
If you are running Behavior from the `runtests.jl` script, instead create
a `ParseOptions` struct, like

```julia
parseoptions = ParseOptions(use_experimental=true)
runspec("path/to/project", parseoptions=parseoptions)
```

## Progress
The new parser is on par with the current parser in `Behavior.Gherkin`, and
has additional support for `Rule`s. Aside from the flag describe above, the
changes are entirely transparent to the user of Behavior.

The general idea is that the experimental parser will undergo a period of
testing to ensure that no major problems are present, and then it will
replace the current parser in a new release.

While the parser is mostly on par with the current one, there are still some
missing parts, like support for steps `But` and `*`. With the new parser,
they are fortunately trivial to add.