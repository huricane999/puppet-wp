define wp::plugin (
  $location,
  $slug = $title,
  $source = $title,
  $ensure = enabled,
  $networkwide = false,
  $version = 'latest',
  $user = $::wp::user,
) {
  include wp::cli

  if ( $networkwide ) {
    $network_arg = ' --network'
    $activate_arg = '--activate-network'
  } else {
    $network_arg = ''
    $activate_arg = '--activate'
  }

  if ( $version != 'latest' ) {
    $held_arg = " --version=${version}"
  } else {
    $held_arg = ''
  }

  case $ensure {
    enabled: {
      exec { "wp install plugin \"${source}\" ${network_arg} ${held_arg}":
        cwd     => $location,
        user    => $user,
        command => "/usr/bin/wp plugin activate ${slug} ${network_arg}",
        unless  => "/usr/bin/wp plugin status ${slug} | grep -q Status:\\ Active",
        require => [
          Class['wp::cli'],
          Exec["wp install plugin \"${source}\" ${held_arg}"],
        ],
        onlyif  => '/usr/bin/wp core is-installed',
      }
    }
    disabled: {
      exec { "wp deactivate plugin ${slug} ${network_arg} ${held_arg}":
        cwd     => $location,
        user    => $user,
        command => "/usr/bin/wp plugin deactivate ${network_arg} ${slug}",
        unless  => "/usr/bin/wp plugin status ${slug} | grep -q Status:\\ Inactive",
        require => [
          Class['wp::cli'],
          Exec["wp install plugin \"${source}\" ${held_arg}"],
        ],
        onlyif  => '/usr/bin/wp core is-installed'
      }
    }
    installed: {}
    deleted: {
      exec { "wp delete plugin ${slug}":
        cwd     => $location,
        user    => $user,
        command => "/usr/bin/wp plugin delete ${slug}",
        unless  => '/bin/bash -c "[ ! -d \"$(wp plugin path)\"]"',
        require => Class['wp::cli'],
        onlyif  => '/usr/bin/wp core is-installed'
      }
    }
    uninstalled: {
      exec { "wp uninstall plugin ${slug}":
        cwd     => $location,
        user    => $user,
        command => "/usr/bin/wp plugin uninstall ${slug} --deactivate",
        unless  => "/bin/bash -c \"[ ! $(wp plugin is-installed ${slug}) ]\"",
        require => Class['wp::cli'],
        onlyif  => '/usr/bin/wp core is-installed'
      }
    }
    default: {
      fail( 'Invalid ensure argument passed into wp::plugin' )
    }
  }

  if $ensure == 'installed' or $ensure == 'enabled' or $ensure == 'disabled' {
    exec { "wp install plugin \"${source}\" ${held_arg}":
      cwd     => $location,
      user    => $user,
      command => "/usr/bin/wp plugin install \"${source}\" ${held_arg}",
      unless  => "/usr/bin/wp plugin is-installed ${slug}",
      require => Class['wp::cli'],
      onlyif  => '/usr/bin/wp core is-installed'
    }
  }
}
