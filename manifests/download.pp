define wp::download (
  $ensure = 'installed',
  $location = $title,
  $locale   = 'en_US',
  $version  = '4.6.1',
  $force    = false,
  $user     = $::wp::user
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
  }
  elsif 'absent' == $ensure {
    file { $location:
      ensure => absent,
    }
  }
}
