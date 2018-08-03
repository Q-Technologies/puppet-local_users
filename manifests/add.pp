# Add any specified users and groups
class local_users::add (
  # Class parameters are populated from module hiera data
  String $root_home_dir,
  String $user_home_location,
) {

  include stdlib

  # Set up the defaults for the group resource creation
  $grp_defaults = {
    ensure               => present,
    #allowdupe            => true,
    system               => true,
    auth_membership      => true,
    forcelocal           => true,
  }

  # Set up the defaults for the user resource creation
  $usr_defaults = {
    ensure               => present,
    purge_ssh_keys       => true,
    managehome           => false,
    forcelocal           => true,
    membership           => inclusive,
  }

  # Do group actions first
  $groups = lookup( 'local_users::add::groups', Data, 'deep', {} )

  $groups.each | $group, $props | {
    create_resources( group, { $group => $props }, $grp_defaults )
  }

  # For AIX, get prgp  for all local users
  if $osfamily == "AIX" {
        $users_pgrp = $facts['user_group']
  }
  # Then perform actions on users
  $users = lookup( 'local_users::add::users', Data, 'deep', {} )
  $users_keys = lookup( 'local_users::add::keys', Collection, 'unique', [] )

  $users.each | $name, $props | {
    #notify { "Checking user: $user ($props)": }

    if $props[generate] {
      $generate = $props[generate]
    } else {
      $generate = 1
    }

    # Make sure we have the UID - root's can be guessed
    if $props[uid] {
      $uid = $props[uid]
    }
    else {
      if $name == 'root' {
        $uid = 0
      }
      else {
        #let system decide
      }
    }

    # Make sure we have the GID - use the UID if not specified
    if $props[gid] {
      $gid = $props[gid]
    }
    else {
      $gid = $uid
    }

    # Make sure we have the home directory - root's can be guessed
    if $props[base_dir] {
      $base_dir = $props[base_dir]
      $home = "${$base_dir}/${name}"
    }
    elsif $props[home] {
      $home = $props[home]
    }
    else {
      if $name == 'root' {
          $home = $root_home_dir
      }
      else {
          $home = "${user_home_location}/${name}"
      }
    }
    # Find the mode of the home directory
    if $props[mode] {
      $mode = $props[mode]
    }
    else {
      $mode = '0750'
    }

    # Make sure we have a decent GECOS - root's can be guessed
    if $props[comment] {
      $comment = $props[comment]
    }
    else {
      if $name == 'root' {
        $comment = $name
      }
      else {
        fail( "The GECOS of user ${name} must be specified" )
      }
    }

    $groups = $props[groups]

    # Work around some platform idiosychronies
    case $facts['os']['family'] {
      'Suse': {
            if $facts[operatingsystem] == 'SLES' and ($facts[operatingsystemmajrelease]+0) < 12 {
              $expiry_param = '9999-12-31'
            }
            $groups_param = $groups
            $password_max_age = '99999'
      }
      'AIX':  {
            $expiry_param = 'absent'
#           $groups_param = $groups << $name # Add the primary group as well - required for AIX
            # Need to obtain the primary group of the user
            $pgrp = $users_pgrp[$name]
            $groups_param = $groups << $pgrp # Add the primary group as well - required for AIX
            $password_max_age = '0'
      }
      default:{
            $expiry_param = 'absent'
            $groups_param = $groups
            $password_max_age = '99999'
      }
    }


    # Merge our optimisations with the raw hiera data
    $merged_props = merge( $props,  { home    => $home,
                                      comment => $comment,
                                    } )

    # Add exprity parameters - if required
    if $props[expiry] == 'none' {
      $merged_props2 = merge( $merged_props,  { expiry           => $expiry_param,
                                                password_max_age => $password_max_age,
                                              } )
    }
    else {
      $merged_props2 = $merged_props
    }

    # Add in additional groups - if required
    if $props[groups] {
      $merged_props3 = merge( $merged_props2, { groups => $groups_param } )
    }
    else {
      $merged_props3 = $merged_props2
    }

    # Delete keys not understood by the user resource
    $clean_props = delete( $merged_props3, ['auth_keys','mode','generate','base_dir'] )

    if $generate > 0 {

      if $generate > 1 {
        # Look for the last digits of the username - assumes there is a non digit in the username somewhere
        # the range function from stdlib will generate the list of usernames - this will use
        # a leading zero as a number placeholder - e.g. user09, user10
        # We will zero pad according to the number of digits specified in the username
        $base_user = $name ? {
          /^([^0-9]+)(\d+)$/ => $1,
          /^([^0-9]+)$/      => $1,
          default            => '',
        }
        $base_num = $name ? {
          /^([^0-9]+)(\d+)$/ => $2,
          /^(\d+)$/          => $1,
          default            => '0',
        }
        # Need to resort to ERB as stdlib size function complains about the data type and the length function
        # says it's not found even though it was added in a much earlier version of stdlib
        #$num_length = size( "${base_num}" )
        $num_length = inline_template('<%= @base_num.length %>')
        $last_num = sprintf( "%0${num_length}d", $base_num + $generate - 1 )
        $last_user = "${base_user}${last_num}"
        $range_of_users = range( $base_num, $last_num )
        $array_of_users = $range_of_users.map | $number | {
          { base_user => $base_user, old_num => $base_num, new_num => sprintf( "%0${num_length}d", $number ) }
        }

      } else {
        $array_of_users = [ { user => $name } ]
      }

      if $array_of_users =~ Array {
        $array_of_users.each | $index, $hash | {
          # Find the correct home directory location
          if $generate > 1 {
            $base_user = $hash[base_user]
            $old_num = $hash[old_num]
            $new_num = $hash[new_num]
            $user = "${base_user}${new_num}"
            if $base_dir {
              $user_home = "${$base_dir}/${user}"
            } else {
              $home_arr = split( $home, /\// )
              $home_arr2 = $home_arr - $name + $user
              $user_home = join( $home_arr2, '/' )
            }
            $gecos_arr = split( $props[comment], /\s+/ )
            $gecos_arr2 = $gecos_arr - $old_num + $new_num
            $gecos = join( $gecos_arr2, ' ' )
          } else {
            $user = $hash[user]
            $user_home = $home
            $gecos = $props[comment]
          }

          # If a UID is specified, supply GID also
          if $uid {
            # Merge our optimisations with the raw hiera data
            $user_props = merge( $clean_props,  { uid => ($uid + $index),
                                                  gid => $gid,
                                                  home => $user_home,
                                                  comment => $gecos,
                                                } )
            # Make sure the specified gid exists - must use exec as group resource only manages by name
            #create_resources( group, { $name => { gid => $gid} }, $grp_defaults )
            exec { "group ${user}":
              unless  => "/bin/grep -c :${gid}: /etc/group",
              command => "/sbin/groupadd --gid ${gid} ${user}",
            }
            create_resources( user, { $user => $user_props }, $usr_defaults )
            $owner_perm = ($uid + $index)
            $group_perm = $gid
          }
          # If the UID is not specified, let the system decide
          else {
            $user_props = merge( $clean_props,  { home => $user_home,
                                                  comment => $gecos,
                                                } )
            create_resources( user, { $user => $user_props }, $usr_defaults )
            $owner_perm = $user
            $group_perm = $user
          }

          # Make sure each user has a home directory
          file { "${user}home":
            ensure  => directory,
            path    => $user_home,
            owner   => $owner_perm,
            group   => $group_perm,
            seluser => 'system_u',
            mode    => $mode,
            require => User[$user],
          }

          # Add the specified SSH keys to the account
          $keys = $props[auth_keys]
          if $keys =~ Array {
            $keys.each | $key | {
              #notify { "Checking authorized keys for $user: $key": }
              $users_keys.each | $user_key | {
                $comment = $user_key[comment]
                #notify { "Checking authorized keys for $user: $key ($comment)": }
                if $comment == $key {
                  #notify { "Found authorized keys for $user: $key": }
                  ssh_authorized_key { "${comment} for ${user}":
                    user    => $user,
                    type    => $user_key['type'],
                    key     => $user_key['key'],
                    require => File["${user}home"],
                  }
                }
              }
            }
          }
        }
      }
    }
  }

}
