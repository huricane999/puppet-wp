# Download WordPress Core 
define wp::download (
  $ensure               = 'installed',
  $location             = $title,
  $locale               = 'en_US',
  $version              = 'latest',
  $force                = false,
  $user                 = $::wp::user,
  $purge_default_themes = false,
) {
  include wp::cli

  if ('installed' == $ensure or 'present' == $ensure) {
    if ($force) {
      $download = "download --path='${location}' --locale='${locale}' --version='${version}' --force'"
    } else {
      $download = "download --path='${location}' --locale='${locale}' --version='${version}'"
    }

    exec {"wp download ${location}":
      command => "/usr/bin/wp core ${download}",
      user    => $user,
      require => [ Class['wp::cli'] ],
      path    => '/bin:/usr/bin:/usr/sbin',
      unless  => "ls ${location} | grep index.php > /dev/null 2>&1",
    }

    if $purge_default_themes {
      exec { "${location} purge default themes":
        command     => "/bin/rm -rf ${location}/wp-content/themes/twenty*",
        user        => $user,
        path        => '/bin:/usr/bin:/usr/sbin',
        refreshonly => true,
        subscribe   => Exec["wp download ${location}"],
      }
    }
  }
  elsif 'absent' == $ensure {
    file { $location:
      ensure => absent,
    }
  }
}
