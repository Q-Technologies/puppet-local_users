# Remove any specified users and groups
class local_users::remove (
  # Class parameters are populated from module hiera data
) {

  if empty( $local_users::users_to_add ) {
    $users_to_add_list = []
  }
  else {
    $users_to_add_list = keys( $local_users::users_to_add )
  }
  if empty( $local_users::groups_to_add ) {
    $groups_to_add_list = []
  }
  else {
    $groups_to_add_list = keys( $local_users::groups_to_add )
  }

  $users_to_remove = $local_users::users_to_remove - $users_to_add_list
  $groups_to_remove = $local_users::groups_to_remove - $groups_to_add_list

  $users_to_remove.each | $user | {
    exec { "killing ${user}":
      command => "pkill -9 -u ${user}",
      onlyif  => "grep '^${user}' /etc/passwd && ps -u ${user}",
      path    => [ '/bin', '/sbin', '/usr/bin', '/usr/sbin' ],
    }
    -> user { $user:
      ensure     => absent,
      forcelocal => $local_users::forcelocal,
      managehome => $local_users::managehome,
    }
  }

  $groups_to_remove.each | $group | {
    group { $group:
      ensure     => absent,
      forcelocal => $local_users::forcelocal,
    }
  }
}
