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
      exec { "wp install plugin \"${source}\" ${activate_arg} ${held_arg}":
        cwd     => $location,
        user    => $user,
        command => "/usr/bin/wp plugin install \"${source}\" ${activate_arg} ${held_arg}",
        unless  => "/usr/bin/wp plugin is-installed ${slug}",
        require => Class['wp::cli'],
        onlyif  => '/usr/bin/wp core is-installed'
      }
    }
    disabled: {
      exec { "wp deactivate plugin ${slug} ${network_arg} ${held_arg}":
        cwd     => $location,
        user    => $user,
        command => "/usr/bin/wp plugin deactivate ${network_arg} ${slug}",
        require => Class['wp::cli'],
        onlyif  => '/usr/bin/wp core is-installed'
      }
    }
    installed: {
      exec { "wp install plugin \"${source}\" ${held_arg}":
        cwd     => $location,
        user    => $user,
        command => "/usr/bin/wp plugin install \"${source}\" ${held_arg}",
        unless  => "/usr/bin/wp plugin is-installed ${slug}",
        require => Class['wp::cli'],
        onlyif  => '/usr/bin/wp core is-installed'
      }
    }
    deleted: {
      exec { "wp delete plugin ${slug}":
        cwd     => $location,
        user    => $user,
        command => "/usr/bin/wp plugin delete ${slug}",
        require => Class['wp::cli'],
        onlyif  => '/usr/bin/wp core is-installed'
      }
    }
    uninstalled: {
      exec { "wp uninstall plugin ${slug}":
        cwd     => $location,
        user    => $user,
        command => "/usr/bin/wp plugin uninstall ${slug} --deactivate",
        require => Class['wp::cli'],
        onlyif  => '/usr/bin/wp core is-installed'
      }
    }
    default: {
      fail( 'Invalid ensure argument passed into wp::plugin' )
    }
  }
}
