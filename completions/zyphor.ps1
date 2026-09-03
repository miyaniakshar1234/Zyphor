Register-ArgumentCompleter -Native -CommandName zyphor -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)
    $subcommands = @('doctor', 'cpu', 'memory', 'disk', '--json', '--plain', '--help', '--version')
    $subcommands | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}
