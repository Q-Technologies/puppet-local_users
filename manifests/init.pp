# Manage local users/groups just through hiera
class local_users(
  # Class parameters are populated from module hiera data
  Boolean $managehome,
  Boolean $forcelocal,
) {
  $users_to_remove = lookup('local_users::remove::users', Collection, 'unique', [])
  $sysusers_to_remove = lookup('local_users::remove::sysusers', Collection, 'unique', [])
  $groups_to_remove = lookup('local_users::remove::groups', Collection, 'unique', [])

  $users_to_ignore = lookup('local_users::ignore::users', Collection, 'unique', [])
  $groups_to_ignore = lookup('local_users::ignore::groups', Collection, 'unique', [])

  $users_lookup = lookup( 'local_users::add::users', Data, 'deep', {} )
  $users_to_add = $users_lookup ? {
    Array   => merge({}, {}, *flatten($users_lookup)),
    default => $users_lookup
  }

  $groups_lookup = lookup( 'local_users::add::groups', Data, 'deep', {} )
  $groups_to_add = $groups_lookup ? {
    Array   => merge({}, {}, *flatten($groups_lookup)),
    default => $groups_lookup
  }

  $users_keys = lookup( 'local_users::add::keys', Collection, 'unique', [] )

  class { 'local_users::remove': }
  -> class { 'local_users::add': }

}
