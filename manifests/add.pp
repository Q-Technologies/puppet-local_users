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

  # Then perform actions on users
  $users = lookup( 'local_users::add::users', Data, 'deep', {} )
  $users_keys = lookup( 'local_users::add::keys', Collection, 'unique', [] )

  $users.each | $user, $props | {
    #notify { "Checking user: $user ($props)": }

    $name = $user
    $generate = $props[generate]

    # Make sure we have the UID - root's can be guessed
    if $props[uid] {
      $uid = $props[uid]
    }
    else {
      if $user == 'root' {
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
    if $props[home] {
      $home = $props[home]
    }
    else {
      if $user == 'root' {
          $home = $root_home_dir
      }
      else {
          $home = "${user_home_location}/${user}"
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
      if $user == 'root' {
        $comment = $user
      }
      else {
        fail( "The GECOS of user ${user} must be specified" )
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
            $groups_param = $groups << $name # Add the primary group as well - required for AIX
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
    $clean_props = delete( $merged_props3, ['auth_keys','mode','generate'] )

    # If a UID is specified, supply GID also
    if $uid {
      # Merge our optimisations with the raw hiera data
      $user_props = merge( $clean_props,  { uid => $uid,
                                            gid => $gid,
                                          } )
      # Make sure the specified gid exists - must use exec as group resource only manages by name
      #create_resources( group, { $name => { gid => $gid} }, $grp_defaults )
      exec { "group $name": 
        unless  => "/bin/grep -c :${gid}: /etc/group",
        command => "/sbin/groupadd --gid ${gid} ${name}",
      }
      create_resources( user, { $user => $user_props }, $usr_defaults )
      $owner_perm = $uid
      $group_perm = $gid
    }
    # If the UID is not specified, let the system decide
    else {
      $user_props = $clean_props
      create_resources( user, { $user => $user_props }, $usr_defaults )
      $owner_perm = $user
      $group_perm = $user
    }

    # Make sure each user has a home directory
    file { "${user}home":
      ensure  => directory,
      path    => $home,
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
