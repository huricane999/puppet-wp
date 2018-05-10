# Manage a WordPress Plugin
define wp::plugin (
  $location,
  $slug = $title,
  $source = $title,
  $ensure = enabled,
  $networkwide = false,
  $networkuser = undef,
  $version = 'latest',
  $user = $::wp::user,
) {
  include wp::cli

  if $networkwide {
    if $networkuser {
      $network_arg = "--user=${networkuser} --network"
      $activate_arg = "--user=${networkuser} --activate-network"
    } else {
      $network_arg = ' --network'
      $activate_arg = '--activate-network'
    }
    $status_str = 'Network Active'
  } else {
    $network_arg = ''
    $activate_arg = '--activate'
    $status_str = 'Active'
  }

  if ( $version != 'latest' ) {
    $held_arg = " --version=${version}"
  } else {
    $held_arg = ''
  }

  if $ensure == 'installed' or $ensure == 'enabled' or $ensure == 'disabled' {
    exec { "${location} install plugin \"${source}\" ${held_arg}":
      cwd     => $location,
      user    => $user,
      command => "/usr/bin/wp plugin install \"${source}\" ${held_arg} --skip-plugins --skip-themes --skip-packages",
      require => Class['wp::cli'],
      onlyif  => [
        '/usr/bin/wp core is-installed --skip-plugins --skip-themes --skip-packages',
        "/bin/bash -c '/usr/bin/wp plugin is-installed ${slug} --skip-plugins --skip-themes --skip-packages >& /dev/null; /bin/test 1 == $?'",
      ],
    }
  }

  case $ensure {
    enabled: {
      exec { "${location} enable plugin \"${source}\" ${network_arg} ${held_arg}":
        cwd     => $location,
        user    => $user,
        command => "/usr/bin/wp plugin activate ${slug} ${network_arg} --skip-plugins --skip-themes --skip-packages",
        require => Class['wp::cli'],
        onlyif  => [
          '/usr/bin/wp core is-installed --skip-plugins --skip-themes --skip-packages',
          "/bin/bash -c '/usr/bin/wp plugin status ${slug} --skip-plugins --skip-themes --skip-packages | grep -q \"Status: ${status_str}\" >& /dev/null; /bin/test 1 == $?'",
        ],
      }
    }
    disabled: {
      exec { "${location} deactivate plugin ${slug} ${network_arg} ${held_arg}":
        cwd     => $location,
        user    => $user,
        command => "/usr/bin/wp plugin deactivate ${network_arg} ${slug} --skip-plugins --skip-themes --skip-packages",
        require => Class['wp::cli'],
        onlyif  => [
          '/usr/bin/wp core is-installed --skip-plugins --skip-themes --skip-packages',
          "/bin/bash -c '/usr/bin/wp plugin status ${slug} --skip-plugins --skip-themes --skip-packages | grep -q \"Status: Inactive\" >& /dev/null; /bin/test 1 == $?'",
        ],
      }
    }
    installed: {}
    deleted: {
      exec { "${location} delete plugin ${slug}":
        cwd     => $location,
        user    => $user,
        command => "/usr/bin/wp plugin delete ${slug} --skip-plugins --skip-themes --skip-packages",
        require => Class['wp::cli'],
        onlyif  => [
          '/usr/bin/wp core is-installed --skip-plugins --skip-themes --skip-packages',
          "/bin/bash -c 'if [[ -d \"$(/usr/bin/wp plugin path --skip-plugins --skip-themes --skip-packages)/${slug}\" ]]; then true; else false; fi'",
        ]
      }
    }
    uninstalled: {
      exec { "${location} uninstall plugin ${slug}":
        cwd     => $location,
        user    => $user,
        command => "/usr/bin/wp plugin uninstall ${slug} --deactivate --skip-plugins --skip-themes --skip-packages",
        require => Class['wp::cli'],
        onlyif  => [
          '/usr/bin/wp core is-installed --skip-plugins --skip-themes --skip-packages',
          "/usr/bin/wp plugin is-installed ${slug} --skip-plugins --skip-themes --skip-packages",
        ],
      }
    }
    default: {
      fail( 'Invalid ensure argument passed into wp::plugin' )
    }
  }
}
