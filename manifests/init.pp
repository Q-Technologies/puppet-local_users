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
  $users_to_add = lookup( 'local_users::add::users', Data, 'deep', {} )
  $groups_to_add = lookup( 'local_users::add::groups', Data, 'deep', {} )
  $users_keys = lookup( 'local_users::add::keys', Collection, 'unique', [] )

  class { 'local_users::remove': }
  -> class { 'local_users::add': }

}
