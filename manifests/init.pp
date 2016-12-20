class local_users(
  # Class parameters are populated from module hiera data
) {

  class { 'local_users::remove': } ->
  class { 'local_users::add': }
  
}
