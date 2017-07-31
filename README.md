# puppet-local_users
Puppet module to easily manage local users and their authorized keys.  It also manages local groups. It's an abstraction layer over the user and group resources to make it easier to add/remove users/groups across different systems using just hiera and calling this class.

Features:
  * maps keys into accounts according to the SSH key comment
  * sets the password aging for non expiring accounts

It makes some assumptions to simplify the creation of local users:
  * the GID is the same as the UID unless it is explicitly specified
  * if GID is not specified, the system will choose one
  * the home directory location is the convention for the OS - it will be created if it doesn't exist

It will fail, if:
  * there is no user comment (GECOS)


## Instructions
Include the class:
```
  class { 'local_users': }
```


Specify hiera details along the following lines:

```
local_users::add::keys:
  -
    comment: 'jblogs@imac.local'
    type: ssh-rsa 
    key: 'AAAAB3NzaC1yc2EAAAABIwAAAQEArqFOapIoElAmJBlKq74MdlXQjPZ2xqOZ7xo2UZ4sRD4fRh+kgkfOP0+wius71pIJ2N2n7cgP1QWMP1i7xsvFJBnb+up9P0y93WTnf+wjKMNx3b9Xt43AffXAADegkWnaImIY+nVrqC1fOiq8xyDjT+kq5ItdE+QHaBNlsuP/FCSGQB8hhxOQyqwKsALdhedhZZ9MsCuVqf62Zti+V3CujyKwRuyeZa3f8zMLjjRFXXldxMVFMJv3/PbJNvMSGe38ikI6Dz/1ESJbNHJFcN+3sM6yzHWS1MROfW6jdxDEtvNgccirDDKUzmeA6wzGnHiDAqf/iJn/x4DUBdijROxE1Q=='
  -
    comment: 'root@prd009'
    type: ssh-rsa
    key: 'AAAAB3NzaC1yc2EAAAAdaqabaaabaqcHyTOwUqmD5evjpDdqyOaR7DISjHa4hu5vwIjg1IecduOZ9Mx00St6emeGwIjMWIapLwaWmTds3DnrON+lFCmMXYPhgIZJpJ4JrxJevMNFXZObS+TdSRwsCo9nuehA9Y1+NPMEPFdtcwdBRSjxDwCbuHzgTYo+hS2Wzwz4B2KjGFvFKx6IlK9qKx7B31n5O4bJMSJLsw+BPe/4xqzDUHjBpcXPPOP+4TWZzhXqZCdXalQZkhxLEC4jHTVycPvpyd3fHr3LOGThpc2ldnh8JAJz71sA01AquErQXa1/pFRl6dGbCZLRuHU8flMj8dA4ZZWCU06cboAkCgxYifTwB8Dd'
  -
    comment: 'bsmith@linux-9g92.site'
    type: ssh-rsa
    key: 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDFcGZD9nyS34Q4olunx2UgN3XKmZqQT2CeKNiuA2/KJkscty9tWP4cG4syEGY21ws3YL11KLYlI1oH4r2qiBk/AdyKhqpo10sCdCuOVAA+kXK7UQGyAjjwlkCLMYkofjEc5iauz1E6d9UOyrtSMnWZ+B59tq5Kd5zPMXAG1MrzWRO4bB2LwT82HaxXKdoon3VCB7jnXKMYQkj1o890HFp/RA1r4B+EBMDf6Op6iSsQsZGG4607Qvhrf8mfeJbSJiK3FezbO7i2hbIyqfzTNaDgzAexJNpsO/67nlytLs9w2Sx7npdp8faMECPQU0DW31e2UckXgDN43edYpYlNNV/N'

local_users::add::users:
  jblogs:
    uid: 1000
    comment: Joe Blogs
    expiry: none
    auth_keys: 
      - 'jblogs@imac.local'
  bsmith:
    uid: 1051
    comment: Bill smitth
    expiry: none
    mode: '0700'
    auth_keys: 
      - 'bsmith@linux-9g92.site'
  root:
    expiry: none
    auth_keys: 
      - 'jblogs@imac.local'
      - 'root@prd009'

local_users::remove::users:
  - jsmith
  - bob

local_users::add::groups:
  admin: {}
  git:
    gid: 15002

local_users::remove::groupss:
  - thesmiths
  - builders

```

## Issues
Only tested on UNIX/Linux type systems.

Since version 1.0.1 of this module duplicate GIDs will not be forced through.  This will create an issue if you have previously relied on this behaviour.

This module does not check for the existance of the users groups first - which might mean a duplicate is created rather than failing.

This module is using hiera data that is embedded in the module rather than using a params class.  This may not play nicely with other modules using the same technique unless you are using hiera 3.0.6 and above (PE 2015.3.2+).
