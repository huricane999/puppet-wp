define wp::theme (
  $location,
  $ensure = enabled,
  $manage_install = false,
  $install_name = '/tmp/theme.zip', # theme|zip|url 
  $theme_name = 'theme',
  $user = $::wp::user,
  $networkwide = false,
) {
  #$name = $title,
  include wp::cli

  if ($manage_install) {
    exec {"${location} wp theme install ${theme_name}":
      command => "/usr/bin/wp theme install \"${install_name}\"",
      cwd     => $location,
      user    => $user,
      require => [ Class['wp::cli'] ],
      unless  => "/usr/bin/wp theme is-installed ${theme_name}"
    }
  }

  case $ensure {
    enabled: {
      if $networkwide {
        $command = "enable ${theme_name} --network"
        $check = "/bin/bash -c \"[[ `/usr/bin/wp theme list | grep ${theme_name} | awk '{print \$5}'` =~ 'site' ]]\""
      } else {
        $command = "enable ${theme_name}"
        $check = "/usr/bin/wp theme status ${theme_name} | grep -q Status:\\ Active"
      }
    }
    installed: {
      $command = false
    }
    default: {
      fail('Invalid ensure for wp::theme')
    }
  }

  if $command {
    wp::command { "${location} theme ${command}":
      location => $location,
      command  => "theme ${command}",
      user     => $user,
      unless   => $check,
    }
  }
}
