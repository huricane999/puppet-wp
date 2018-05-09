# Define a htaccess Rewrite Rule
define wp::rewrite (
  $location,
  $structure = $title,
  $user = $::wp::user
) {
  include wp::cli

  wp::command { "${location} rewrite structure '${structure}'":
    location => $location,
    command  => "rewrite structure '${structure}'",
    user     => $user
  }
}
