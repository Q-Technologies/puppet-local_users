class local_users(
  # Class parameters are populated from module hiera data
  String $root_home_dir,
  String $user_home_location,
) {

  include stdlib

  $users = hiera_hash( "local_users::users" )
  $users_keys = hiera( "local_users::keys" )

  $users.each | $user, $props | {
    #notify { "Checking user: $user ($props)": }

    if $props[uid] {
      $uid = $props[uid]
    }
    else {
      if $user == "root" {
        $uid = 0
      }
      else {
        fail( "The UID of user $user must be specified" )
      }
    }

    if $props[gid] {
      $gid = $props[gid]
    }
    else {
      if $user == "root" {
        $gid = 0
      }
      else {
        fail( "The GID of user $user must be specified" )
      }
    }

    unless $props[home] {
      if $user == "root" {
          $home = $root_home_dir
      }
      else {
          $home = "$user_home_location/$user"
      }
    }

    $merged_props = merge( $props, { uid => $uid, gid => $gid, home => $home } )
 
    $defaults = {
      ensure   => present,
      purge_ssh_keys => true,
    } 

    $clean_props = delete( $merged_props, ['auth_keys'] )
    create_resources( user, { $user => $clean_props }, $defaults )

    $keys = $props[auth_keys]
    $keys.each | $key | {
        #notify { "Checking authorized keys for $user: $key": }
        $users_keys.each | $user_key | {
            $comment = $user_key[comment]
            #notify { "Checking authorized keys for $user: $key ($comment)": }
            if $comment == $key {
                #notify { "Found authorized keys for $user: $key": }
                ssh_authorized_key { "$comment for $user":
                    user => $user,
                    type => $user_key['type'],
                    key  => $user_key['key'],
                }
            }
        }
    }
  }
  
}
