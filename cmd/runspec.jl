using ExecutableSpecifications

exitcode = runspec() ? 0 : - 1
exit(exitcode)