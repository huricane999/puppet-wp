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

  $extraphp_str = "${multisitephp}${extraphp}"

  if $extraphp_str != '' {
    $config = "config --path='${location}' --dbname='${dbname}' --dbuser='${dbuser}' --dbpass='${dbpass}' --dbhost='${dbhost}' --dbprefix='${dbprefix}' --extra-php <<PHP\n${extraphp_str}\nPHP"
  } else {
    $config = "config --path='${location}' --dbname='${dbname}' --dbuser='${dbuser}' --dbpass='${dbpass}' --dbhost='${dbhost}' --dbprefix='${dbprefix}'"
  }
  
  exec {"wp config ${location}":
    command => "/usr/bin/wp core ${config}",
    user    => $user,
    require => [ Class['wp::cli'] ],
    path    => '/bin:/usr/bin:/usr/sbin',
    unless  => "ls ${location}/wp-config.php | grep wp-config.php > /dev/null 2>&1",
  }
}
