# Remove any specified users and groups
class local_users::remove (
  # Class parameters are populated from module hiera data
) {

  $users_to_add_list = keys( $local_users::users_to_add )
  $groups_to_add_list = keys( $local_users::groups_to_add )

  $users_to_remove = $local_users::users_to_remove - $local_users::users_to_ignore - $users_to_add_list
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

  # Remove users that ship with the system - these usually have a non personal home directory that should not be deleted
  $sysusers_to_remove = $local_users::sysusers_to_remove - $local_users::users_to_ignore - $users_to_add_list
  user { $sysusers_to_remove:
    ensure     => absent,
    forcelocal => true,
    managehome => false,
  }

  $groups_to_remove = $local_users::groups_to_remove - $local_users::groups_to_ignore - $groups_to_add_list
  group { $groups_to_remove:
    ensure     => absent,
    forcelocal => $local_users::forcelocal,
  }
}
