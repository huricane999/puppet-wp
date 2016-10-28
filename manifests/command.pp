define wp::command (
	$location,
	$command,
  $user = $::wp::user
) {
	include wp::cli

	exec {"$location wp $command":
		command => "/usr/bin/wp $command",
		cwd => $location,
		user => $user,
		require => [ Class['wp::cli'] ],
		onlyif => '/usr/bin/wp core is-installed'
	}
}
