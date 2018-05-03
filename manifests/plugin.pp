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

  if $ensure == 'installed' or $ensure == 'enabled' or $ensure == 'disabled' {
    exec { "wp install plugin \"${source}\" ${held_arg}":
      cwd     => $location,
      user    => $user,
      command => "/usr/bin/wp plugin install \"${source}\" ${held_arg}",
      require => Class['wp::cli'],
      onlyif  => [
        '/usr/bin/wp core is-installed',
        "/bin/bash -c \"/usr/bin/wp plugin is-installed ${slug} >& /dev/null; /bin/test ! $?\"",
      ],
    }
  }

  case $ensure {
    enabled: {
      exec { "wp install plugin \"${source}\" ${network_arg} ${held_arg}":
        cwd     => $location,
        user    => $user,
        command => "/usr/bin/wp plugin activate ${slug} ${network_arg}",
        require => Class['wp::cli'],
        onlyif  => [
          '/usr/bin/wp core is-installed',
          "/usr/bin/wp plugin status ${slug} | grep -q Status:\\ Inactive",
        ],
      }
    }
    disabled: {
      exec { "wp deactivate plugin ${slug} ${network_arg} ${held_arg}":
        cwd     => $location,
        user    => $user,
        command => "/usr/bin/wp plugin deactivate ${network_arg} ${slug}",
        require => Class['wp::cli'],
        onlyif  => [
          '/usr/bin/wp core is-installed',
          "/usr/bin/wp plugin status ${slug} | grep -q Status:\\ Active",
        ],
      }
    }
    installed: {}
    deleted: {
      exec { "wp delete plugin ${slug}":
        cwd     => $location,
        user    => $user,
        command => "/usr/bin/wp plugin delete ${slug}",
        require => Class['wp::cli'],
        onlyif  => [
          '/usr/bin/wp core is-installed',
          "/bin/bash -c 'if [[ -d \"$(wp --allow-root plugin path)/acf-flexible-content\" ]]; then true; else false; fi'",
        ]
      }
    }
    uninstalled: {
      exec { "wp uninstall plugin ${slug}":
        cwd     => $location,
        user    => $user,
        command => "/usr/bin/wp plugin uninstall ${slug} --deactivate",
        require => Class['wp::cli'],
        onlyif  => [
          '/usr/bin/wp core is-installed',
          "/usr/bin/wp plugin is-installed ${slug}",
        ],
      }
    }
    default: {
      fail( 'Invalid ensure argument passed into wp::plugin' )
    }
  }
}
