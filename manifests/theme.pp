# Manage a WordPress Theme
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

  if $manage_install {
    wp::command{ "${location} wp theme install ${theme_name}":
      location => $location,
      command  => "theme install \"${install_name}\" --skip-plugins --skip-themes --skip-packages",
      user     => $user,
      unless   => "/usr/bin/wp theme is-installed ${theme_name} --skip-plugins --skip-themes --skip-packages",
      tag      => 'theme-installed',
    }
  }

  case $ensure {
    enabled: {
      if $networkwide {
        $command = "enable ${theme_name} --network --skip-plugins --skip-themes --skip-packages"
        $check = "/bin/bash -c \"[[ `/usr/bin/wp theme list | grep ${theme_name} | awk '{print \$5}'` =~ 'site' ]]\""
      } else {
        $command = "enable ${theme_name}"
        $check = "/usr/bin/wp theme status ${theme_name} --skip-plugins --skip-themes --skip-packages | grep -q Status:\\ Active"
      }
    }
    disabled: {
      if $networkwide {
        $command = "disable ${theme_name} --network --skip-plugins --skip-themes --skip-packages"
        $check = "/bin/bash -c \"[[ `/usr/bin/wp theme list | grep ${theme_name} | awk '{print \$5}'` =~ 'no' ]]\""
      } else {
        $command = "disable ${theme_name}"
        $check = "/usr/bin/wp theme status ${theme_name} --skip-plugins --skip-themes --skip-packages | grep -q Status:\\ Inactive"
      }
    }
    uninstalled: {
      $command = "delete ${theme_name} --skip-plugins --skip-themes --skip-packages"
      $check = "/bin/bash -c \"[[ `/usr/bin/wp theme list | grep ${theme_name} | awk '{print \$5}'` =~ 'no' ]]\""

      wp::command { "${location} disable theme ${theme_name}":
        location => $location,
        command  => "theme disable ${theme_name} --skip-plugins --skip-themes --skip-packages",
        user     => $user,
        onlyif   => "/usr/bin/wp theme status ${theme_name} --skip-plugins --skip-themes --skip-packages | grep -q Status:\\ Inactive",
        tag      => 'theme-uninstalled',
      }
      ->exec { "${location} deactivate theme ${theme_name}":
        command => "/bin/bash -c '/usr/bin/wp theme activate \"$(/usr/bin/wp theme list --skip-plugins --skip-themes --skip-packages | grep -e \"network\|site\" | awk \"{print \$1}\")\" --skip-plugins --skip-themes --skip-packages'",
        cwd     => $location,
        user    => $user,
        onlyif  => "/usr/bin/wp theme list --skip-plugins --skip-themes --skip-packages | grep -e ${theme_name} | grep -q active",
        tag     => 'theme-uninstalled',
      }
      if $networkwide {
        # lint:ignore:140chars
        exec { "${location} network disable theme ${theme_name}":
          command => "/bin/bash -c 'while read line; do /usr/bin/wp theme disable ${theme_name} --url=\$line --skip-plugins --skip-themes --skip-packages; done <<< \"$(/usr/bin/wp site list --field=url --skip-plugins --skip-themes --skip-packages)\"'",
          cwd     => $location,
          user    => $user,
          unless  => "/bin/bash -c 'ret=0; while read line; do /usr/bin/wp --allow-root theme list --url=\$line --skip-plugins --skip-themes --skip-packages | grep -e ${theme_name} | grep -q \"network\|site\"; if [ $? -eq 0 ]; then let \"ret++\"; fi; done <<< \"$(/usr/bin/wp --allow-root site list --field=url --skip-plugins --skip-themes --skip-packages)\"; echo \$ret; /bin/test \$ret == 0'",
          require => Exec["${location} deactivate theme ${theme_name}"],
          before  => Wp::Command["${location} theme ${command}"],
          tag     => 'theme-uninstalled',
        }
        ->exec { "${location} network deactivate theme ${theme_name}":
          command => "/bin/bash -c 'while read line; do /usr/bin/wp theme activate \"$(/usr/bin/wp theme list --url=\$line --skip-plugins --skip-themes --skip-packages | grep -e \\\"network\|site\\\" | awk \\\"{print \\\$1}\\\")\" --url=\$line --skip-plugins --skip-themes --skip-packages; done <<< \"$( /usr/bin/wp site list --field=url --skip-plugins --skip-themes --skip-packages )\"'",
          cwd     => $location,
          user    => $user,
          unless  => "/bin/bash -c 'ret=0; while read line; do /usr/bin/wp theme status ${theme_name} --url=\$line --skip-plugins --skip-themes --skip-packages | grep Status | grep -q Active; if [ $? -eq 0 ]; then let \"ret++\"; fi; done <<< \"$(/usr/bin/wp site list --field=url --skip-plugins --skip-themes --skip-packages)\"; /bin/test \$ret == 0'",
          before  => Wp::Command["${location} theme ${command}"],
          tag     => 'theme-uninstalled',
        }
        # lint:endignore
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
      command  => "theme ${command} --skip-plugins --skip-themes --skip-packages",
      user     => $user,
      unless   => $check,
      tag      => "theme-${ensure}",
    }

    if $manage_install {
      Wp::Command["${location} wp theme install ${theme_name}"] -> Wp::Command["${location} theme ${command}"]
    }

    Wp::Command<| tag == 'theme-installed' |> -> Wp::Command<| tag == 'theme-enabled' |> -> Wp::Command<| tag == 'theme-uninstalled' |>
  }
}
