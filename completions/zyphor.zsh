#compdef zyphor

_zyphor() {
    local -a commands
    commands=(
        'doctor:Run system diagnostics audit'
        'cpu:Show live CPU telemetry'
        'memory:Show RAM and pagefile metrics'
        'disk:Show disk partition table'
        '--json:Emit raw JSON snapshot'
        '--plain:Run in plain ASCII mode'
        '--help:Display help information'
        '--version:Display version string'
    )
    _describe 'command' commands
}
_zyphor "$@"
