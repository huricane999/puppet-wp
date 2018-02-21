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
    $network = ' --network'
    $activate = '--activate-network'
  } else {
    $activate = '--activate'
  }

  if ( $version != 'latest' ) {
    $held = " --version=${version}"
  }

  case $ensure {
    enabled: {
      exec { "wp install plugin \"${source}\" ${activate} ${held}":
        cwd     => $location,
        user    => $user,
        command => "/usr/bin/wp plugin install \"${source}\" ${activate} ${held}",
        unless  => "/usr/bin/wp plugin is-installed ${slug}",
        require => Class['wp::cli'],
        onlyif  => '/usr/bin/wp core is-installed'
      }
    }
    disabled: {
      exec { "wp deactivate plugin ${slug} ${network} ${held}":
        cwd     => $location,
        user    => $user,
        command => "/usr/bin/wp plugin deactivate ${slug}",
        require => Class['wp::cli'],
        onlyif  => '/usr/bin/wp core is-installed'
      }
    }
    installed: {
      exec { "wp install plugin \"${source}\" ${network} ${held}":
        cwd     => $location,
        user    => $user,
        command => "/usr/bin/wp plugin install \"${source}\" ${network} ${held}",
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
