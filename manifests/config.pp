# Manage a WordPress Config
define wp::config (
  $location = $title,
  $dbname       = 'wordpress',
  $dbuser       = 'wordpress',
  $dbpass       = 'P@ssw0rd',
  $dbhost       = 'localhost',
  $dbprefix     = 'wp_',
  $dbcharset    = 'utf8',
  $multisite    = false,
  $ms_subdomain = false,
  $ms_domain    = '',
  $ms_path      = '/',
  $ms_site_id   = 1,
  $ms_blog_id   = 1,
  $extraphp     = '',
  $user         = $::wp::user
) {
  include wp::cli

  if $multisite {
    $multisitephp = template( 'wp/config_extraphp_multisite.erb' )
  } else {
    $multisitephp = ''
  }

  $extraphp_str = @("EOF"/L)
    ${multisitephp}\n\
    \n\
    if (file_exists('wp-config-puppet.php')) {\n\
        include 'wp-config-puppet.php';\n\
    }\n
    | -EOF

  if $extraphp_str != '' {
    # lint:ignore:140chars
    $config = "config --path='${location}' --dbname='${dbname}' --dbuser='${dbuser}' --dbpass='${dbpass}' --dbhost='${dbhost}' --dbprefix='${dbprefix}' --extra-php \"<<PHP\n${extraphp_str}\nPHP\""
    # lint:endignore
  } else {
    # lint:ignore:140chars
    $config = "config --path='${location}' --dbname='${dbname}' --dbuser='${dbuser}' --dbpass='${dbpass}' --dbhost='${dbhost}' --dbprefix='${dbprefix}'"
    # lint:endignore
  }

  if $extraphp != '' {
    file { "${location}/wp-config-puppet.php":
      ensure  => 'present',
      owner   => $user,
      group   => $user,
      mode    => '0644',
      content => $extraphp,
    }
  }

  exec {"wp config ${location}":
    command => "/usr/bin/wp core ${config}",
    user    => $user,
    require => [ Class['wp::cli'] ],
    path    => '/bin:/usr/bin:/usr/sbin',
    creates => "${location}/wp-config.php",
  }

  wp::command { "${location} wp config set dbname":
    location => $location,
    command  => "config set DB_NAME '${dbname}'",
    user     => $user,
    unless   => "/bin/test \"`/usr/bin/wp config get DB_NAME`\" == '${dbname}'",
  }

  wp::command { "${location} wp config set dbuser":
    location => $location,
    command  => "config set DB_USER '${dbuser}'",
    user     => $user,
    unless   => "/bin/test \"`/usr/bin/wp config get DB_USER`\" == '${dbuser}'",
  }

  wp::command { "${location} wp config set dbpass":
    location => $location,
    command  => "config set DB_PASSWORD '${dbpass}'",
    user     => $user,
    unless   => "/bin/test \"`/usr/bin/wp config get DB_PASSWORD`\" == '${dbpass}'",
  }

  wp::command { "${location} wp config set dbprefix":
    location => $location,
    command  => "config set table_prefix '${dbprefix}'",
    user     => $user,
    unless   => "/bin/test \"`/usr/bin/wp config get table_prefix`\" == '${dbprefix}'",
  }

  $multisite_str = bool2str($multisite)
  if $multisite {
    $multisite_int = '1'
  } else {
    $multisite_int = '0'
  }

  wp::command { "${location} wp config set WP_ALLOW_MULTISITE":
    location => $location,
    command  => "config set WP_ALLOW_MULTISITE --raw ${multisite_str} --type=constant",
    user     => $user,
    unless   => "/bin/test \"`/usr/bin/wp config get WP_ALLOW_MULTISITE`\" == '${multisite_int}'",
  }

  wp::command { "${location} wp config set MULTISITE":
    location => $location,
    command  => "config set MULTISITE --raw ${multisite_str} --type=constant",
    user     => $user,
    unless   => "/bin/test \"`/usr/bin/wp config get MULTISITE`\" == '${multisite_int}'",
  }

  $ms_subdomain_str = bool2str($ms_subdomain)
  if $ms_subdomain {
    $ms_subdomain_int = '1'
  } else {
    $ms_subdomain_int = '0'
  }
  wp::command { "${location} wp config set SUBDOMAIN_INSTALL":
    location => $location,
    command  => "config set SUBDOMAIN_INSTALL --raw ${ms_subdomain_str} --type=constant",
    user     => $user,
    unless   => "/bin/test \"`/usr/bin/wp config get SUBDOMAIN_INSTALL`\" == '${ms_subdomain_int}'",
  }

  wp::command { "${location} wp config set DOMAIN_CURRENT_SITE":
    location => $location,
    command  => "config set DOMAIN_CURRENT_SITE '${ms_domain}'",
    user     => $user,
    unless   => "/bin/test \"`/usr/bin/wp config get DOMAIN_CURRENT_SITE`\" == '${ms_domain}' --type=constant",
  }

  wp::command { "${location} wp config set PATH_CURRENT_SITE":
    location => $location,
    command  => "config set PATH_CURRENT_SITE '${ms_path}' --type=constant",
    user     => $user,
    unless   => "/bin/test \"`/usr/bin/wp config get PATH_CURRENT_SITE`\" == '${ms_path}'",
  }

  wp::command { "${location} wp config set SITE_ID_CURRENT_SITE":
    location => $location,
    command  => "config set SITE_ID_CURRENT_SITE '${ms_site_id}'",
    user     => $user,
    unless   => "/bin/test \"`/usr/bin/wp config get --path='${location}' SITE_ID_CURRENT_SITE`\" == '${ms_site_id}' --type=constant",
  }

  wp::command { "${location} wp config set BLOG_ID_CURRENT_SITE":
    location => $location,
    command  => "config set BLOG_ID_CURRENT_SITE '${ms_blog_id}'",
    user     => $user,
    unless   => "/bin/test \"`/usr/bin/wp config get --path='${location}' BLOG_ID_CURRENT_SITE`\" == '${ms_blog_id}' --type=constant",
  }
}
