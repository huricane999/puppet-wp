define wp::plugin (
  $slug = $title,
  $source = $title,
  $location,
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
    $held = " --version=$version"
  }

  case $ensure {
    enabled: {
      exec { "${title}: wp install plugin \"$source\" $activate$held":
        cwd     => $location,
        user    => $user,
        command => "/usr/bin/wp plugin install \"$source\" $activate$held",
        unless  => "/usr/bin/wp plugin is-installed $slug",
        require => Class["wp::cli"],
        onlyif  => "/usr/bin/wp core is-installed"
      }
    }
    disabled: {
      exec { "${title}: wp deactivate plugin $slug$network$held":
        cwd     => $location,
        user    => $user,
        command => "/usr/bin/wp plugin deactivate $slug",
        require => Class["wp::cli"],
        onlyif  => "/usr/bin/wp core is-installed"
      }
    }
    installed: {
      exec { "${title}: wp install plugin \"$source\"$network$held":
        cwd     => $location,
        user    => $user,
        command => "/usr/bin/wp plugin install \"$source\" $network$held",
        unless  => "/usr/bin/wp plugin is-installed $slug",
        require => Class["wp::cli"],
        onlyif  => "/usr/bin/wp core is-installed"
      }
    }
    deleted: {
      exec { "${title}: wp delete plugin $slug":
        cwd     => $location,
        user    => $user,
        command => "/usr/bin/wp plugin delete $slug",
        require => Class["wp::cli"],
        onlyif  => "/usr/bin/wp core is-installed"
      }
    }
    uninstalled: {
      exec { "${title}: wp uninstall plugin $slug":
        cwd     => $location,
        user    => $user,
        command => "/usr/bin/wp plugin uninstall $slug --deactivate",
        require => Class["wp::cli"],
        onlyif  => "/usr/bin/wp core is-installed"
      }
    }
    default: {
      fail( "Invalid ensure argument passed into wp::plugin" )
    }
  }
}
