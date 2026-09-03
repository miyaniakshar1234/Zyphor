_zyphor_completions() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local commands="doctor cpu memory disk --json --plain --help --version"
    COMPREPLY=( $(compgen -W "${commands}" -- "${cur}") )
}
complete -F _zyphor_completions zyphor
