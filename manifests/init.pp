# Manage local users/groups just through hiera
class local_users(
  # Class parameters are populated from module hiera data
  Boolean $managehome,
  Boolean $forcelocal,
) {

  class { 'local_users::remove': }
  -> class { 'local_users::add': }

}
