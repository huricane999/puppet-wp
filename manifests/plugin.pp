# Manage a WordPress Plugin
define wp::plugin (
  $location,
  $slug = $title,
  $source = $title,
  $ensure = enabled,
  $networkwide = false,
  $networkuser = undef,
  $version = 'latest',
  $min_version_update = false,
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

  # lint:ignore:140chars
  if $ensure == 'installed' or $ensure == 'enabled' or $ensure == 'disabled' {
    wp::command { "${location} install plugin \"${source}\" ${held_arg}":
      command  => "plugin install \"${source}\" ${held_arg}",
      location => $location,
      user     => $user,
      onlyif   => '/usr/bin/wp core is-installed',
      unless   => "/usr/bin/wp plugin is-installed ${slug}",
      tag      => 'plugin-installed'
    }

    if $version != 'latest' {
      if $min_version_update {
        wp::command { "${location} enforce plugin version upgrade \"${source}\" (Min Version: ${version})":
          command  => "plugin update \"${slug}\"",
          location => $location,
          user     => $user,
          onlyif   => [
            '/usr/bin/wp core is-installed',
            "/bin/php -r '\$version = \"`/usr/bin/wp plugin status ${slug} | /bin/grep Version | /bin/awk '{print \$2}'`\"; if (version_compare(\$version, \"${version}\") < 0) { exit(0); } else { exit(1); }'",
          ],
          tag      => 'plugin-installed',
          require  => Wp::Command["${location} install plugin \"${source}\" ${held_arg}"],
        }
      } else {
        wp::command { "${location} enforce plugin version upgrade \"${source}\" ${held_arg}":
          command  => "plugin update \"${slug}\" ${held_arg}",
          location => $location,
          user     => $user,
          onlyif   => [
            '/usr/bin/wp core is-installed',
            "/bin/php -r '\$version = \"`/usr/bin/wp plugin status ${slug} | /bin/grep Version | /bin/awk '{print \$2}'`\"; if (version_compare(\$version, \"${version}\") < 0) { exit(0); } else { exit(1); }'",
          ],
          tag      => 'plugin-installed',
          require  => Wp::Command["${location} install plugin \"${source}\" ${held_arg}"],
        }

        wp::command { "${location} enforce plugin version downgrade \"${source}\" ${held_arg}":
          command  => "plugin install \"${source}\" ${held_arg} --force",
          location => $location,
          user     => $user,
          onlyif   => [
            '/usr/bin/wp core is-installed',
            "/bin/php -r '\$version = \"`/usr/bin/wp plugin status ${slug} | /bin/grep Version | /bin/awk '{print \$2}'`\"; if (version_compare(\$version, \"${version}\") != 0) { exit(0); } else { exit(1); }'",
          ],
          tag      => 'plugin-installed',
          require  => Wp::Command["${location} enforce plugin version upgrade \"${source}\" ${held_arg}"],
        }
      }
    }
  }

  case $ensure {
    enabled: {
      wp::command { "${location} enable plugin \"${source}\" ${network_arg} ${held_arg}":
        command  => "plugin activate ${slug} ${network_arg}",
        location => $location,
        user     => $user,
        onlyif   => [
          '/usr/bin/wp core is-installed',
          "/bin/bash -c '/usr/bin/wp plugin status ${slug} | grep -q \"Status: ${status_str}\" >& /dev/null; /bin/test 1 == $?'",
        ],
        tag      => 'plugin-enabled',
      }
    }
    disabled: {
      wp::command { "${location} deactivate plugin ${slug} ${network_arg} ${held_arg}":
        command  => "plugin deactivate ${network_arg} ${slug}",
        location => $location,
        user     => $user,
        onlyif   => [
          '/usr/bin/wp core is-installed',
          "/bin/bash -c '/usr/bin/wp plugin status ${slug} | grep -q \"Status: Inactive\" >& /dev/null; /bin/test 1 == $?'",
        ],
        tag      => 'plugin-disabled',
      }
    }
    installed: {}
    deleted: {
      wp::command { "${location} delete plugin ${slug}":
        command  => "plugin delete ${slug}",
        location => $location,
        user     => $user,
        onlyif   => [
          '/usr/bin/wp core is-installed',
          "/bin/bash -c 'if [[ -d \"$(/usr/bin/wp plugin path)/${slug}\" ]]; then true; else false; fi'",
        ],
        tag      => 'plugin-deleted',
      }
    }
    uninstalled: {
      wp::command { "${location} uninstall plugin ${slug}":
        command  => "plugin uninstall ${slug} --deactivate",
        location => $location,
        user     => $user,
        onlyif   => [
          '/usr/bin/wp core is-installed',
          "/usr/bin/wp plugin is-installed ${slug}",
        ],
        tag      => 'plugin-uninstalled',
      }
    }
    default: {
      fail( 'Invalid ensure argument passed into wp::plugin' )
    }
  }

  Wp::Command<| tag == 'plugin-uninstalled' |>
  -> Wp::Command<| tag == 'plugin-installed' |>
  -> Wp::Command<| tag == 'plugin-disabled' |>
  -> Wp::Command<| tag == 'plugin-enabled' |>
  # lint:endignore
}
