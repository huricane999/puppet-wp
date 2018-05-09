# Execute a WordPress CLI Command
define wp::command (
  $location,
  $command,
  $user = $::wp::user,
  $onlyif = '/usr/bin/wp core is-installed',
  $unless = undef,
  $refreshonly = false,
) {
  include wp::cli

  exec {"${location} wp ${command}":
    command     => "/usr/bin/wp ${command}",
    cwd         => $location,
    user        => $user,
    require     => [ Class['wp::cli'] ],
    onlyif      => $onlyif,
    unless      => $unless,
    refreshonly => $refreshonly,
  }
}
