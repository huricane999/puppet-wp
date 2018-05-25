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

  if $manage_install and $ensure != 'uninstalled' {
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
        $command = "enable ${theme_name} --network"
        $check = "/bin/bash -c \"[[ `/usr/bin/wp theme list | /bin/grep ${theme_name} | /bin/awk '{print \$5}'` =~ 'network' ]]\""
      } else {
        $command = "enable ${theme_name}"
        $check = "/usr/bin/wp theme status ${theme_name} --skip-plugins --skip-themes --skip-packages | /bin/grep -q Status:\\ Active"
      }
    }
    disabled: {
      if $networkwide {
        $command = "disable ${theme_name} --network"
        $check = "/bin/bash -c \"[[ `/usr/bin/wp theme list | /bin/grep ${theme_name} | /bin/awk '{print \$5}'` =~ 'no' ]]\""
      } else {
        $command = "disable ${theme_name}"
        $check = "/usr/bin/wp theme status ${theme_name} --skip-plugins --skip-themes --skip-packages | /bin/grep -q Status:\\ Inactive"
      }
    }
    /^(absent|uninstalled)$/: {
      # lint:ignore:140chars
      $command = "delete ${theme_name}"
      $only_if = "/bin/bash -c \"[[ `/usr/bin/wp theme list --skip-plugins --skip-themes --skip-packages | /bin/grep ${theme_name} | /bin/awk '{print \\\$5}'` == 'no' ]]\""

      wp::command { "${location} disable theme ${theme_name}":
        location => $location,
        command  => "theme disable ${theme_name} --skip-plugins --skip-themes --skip-packages",
        user     => $user,
        onlyif   => [
          "/bin/bash -c \"/usr/bin/wp theme list --skip-plugins --skip-themes --skip-packages | /bin/grep -q ${theme_name}",
          "/bin/bash -c \"/usr/bin/wp theme list --skip-plugins --skip-themes --skip-packages | /bin/grep ${theme_name} | /bin/awk '{print \\\$5}' | /bin/grep -q site\"",
        ],
        tag      => 'theme-uninstalled',
      }
      ->exec { "${location} deactivate theme ${theme_name}":
        command => "/bin/bash -c \"/usr/bin/wp theme activate `/usr/bin/wp theme list --skip-plugins --skip-themes --skip-packages | /bin/grep -v ${theme_name} | /bin/grep -m1 -e \"network\\|site\" | /bin/awk '{print \$1}'` --skip-plugins --skip-themes --skip-packages\"",
        cwd     => $location,
        user    => $user,
        onlyif  => [
          "/bin/bash -c \"/usr/bin/wp theme list --skip-plugins --skip-themes --skip-packages | /bin/grep -q ${theme_name}",
          "/bin/bash -c \"[[ `/usr/bin/wp theme list --skip-plugins --skip-themes --skip-packages | /bin/grep ${theme_name} | /bin/awk '{print \\\$2}'` == 'active' ]]\"",
        ],
        tag     => 'theme-uninstalled',
      }
      if $networkwide {
        wp::command { "${location} network disable theme ${theme_name}":
          location => $location,
          command  => "theme disable ${theme_name} --network --skip-plugins --skip-themes --skip-packages",
          user     => $user,
          onlyif   => [
            "/bin/bash -c \"/usr/bin/wp theme list --skip-plugins --skip-themes --skip-packages | /bin/grep -q ${theme_name}",
            "/bin/bash -c \"/usr/bin/wp theme list --skip-plugins --skip-themes --skip-packages | /bin/grep ${theme_name} | /bin/awk '{print \\\$5}' | /bin/grep -q network\"",
          ],
          tag      => 'theme-uninstalled',
        }
        ->exec { "${location} sites disable theme ${theme_name}":
          command => "/bin/bash -c 'while read line; do /usr/bin/wp theme disable ${theme_name} --url=\$line --skip-plugins --skip-themes --skip-packages; done <<< \"$(/usr/bin/wp site list --field=url --skip-plugins --skip-themes --skip-packages)\"'",
          cwd     => $location,
          user    => $user,
          onlyif  => [
            "/bin/bash -c \"/usr/bin/wp theme list --skip-plugins --skip-themes --skip-packages | /bin/grep -q ${theme_name}",
            "/bin/bash -c 'ret=0; while read line; do /usr/bin/wp theme list --url=\$line --skip-plugins --skip-themes --skip-packages | /bin/grep ${theme_name} | /bin/awk \'{print \$5}\' | /bin/grep -q site; if [ $? -eq 0 ]; then let \"ret++\"; fi; done <<< \"$(/usr/bin/wp site list --field=url --skip-plugins --skip-themes --skip-packages)\"; echo \$ret; /bin/test \$ret -gt 0'",
          ],
          require => Exec["${location} deactivate theme ${theme_name}"],
          before  => Wp::Command["${location} theme ${command}"],
          tag     => 'theme-uninstalled',
        }
        ->exec { "${location} network deactivate theme ${theme_name}":
          command => "/bin/bash -c \"while read line; do /usr/bin/wp theme activate `/usr/bin/wp theme list --url=\$line --skip-plugins --skip-themes --skip-packages | /bin/grep -v ${theme_name} | /bin/grep -e \"network\\|site\" | head -n 1 | /bin/awk '{print \$1}'` --url=\$line --skip-plugins --skip-themes --skip-packages; done <<< \"$( /usr/bin/wp site list --field=url --skip-plugins --skip-themes --skip-packages )\"\"",
          cwd     => $location,
          user    => $user,
          onlyif  => [
            "/bin/bash -c \"/usr/bin/wp theme list --skip-plugins --skip-themes --skip-packages | /bin/grep -q ${theme_name}",
            "/bin/bash -c 'ret=0; while read line; do if [ `/usr/bin/wp theme list --skip-plugins --skip-themes --skip-packages | /bin/grep ${theme_name} | /bin/awk '{print \$2}'` == 'active' ]; then let \"ret++\"; fi; done <<< \"$(/usr/bin/wp site list --field=url --skip-plugins --skip-themes --skip-packages)\"; /bin/test \$ret -gt 0'",
          ],
          before  => Wp::Command["${location} theme ${command}"],
          tag     => 'theme-uninstalled',
        }
      }
      # lint:endignore
    }
    /^(present|installed)$/: {
      $command = false
    }
    default: {
      fail('Invalid ensure for wp::theme')
    }
  }

  if $command {
    if !$only_if {
      $only_if = undef
    }

    wp::command { "${location} theme ${command}":
      location => $location,
      command  => "theme ${command} --skip-plugins --skip-themes --skip-packages",
      user     => $user,
      unless   => $check,
      onlyif   => $only_if,
      tag      => "theme-${ensure}",
    }

    if $manage_install and $ensure != 'uninstalled' {
      Wp::Command["${location} wp theme install ${theme_name}"] -> Wp::Command["${location} theme ${command}"]
    }

    # lint:ignore:140chars
    Wp::Command<| tag == 'theme-installed' or tag == 'theme-present' |> -> Wp::Command<| tag == 'theme-enabled' |> -> Wp::Command<| tag == 'theme-uninstalled' or tag == 'theme-absent' |>
    # lint:endignore
  }
}
