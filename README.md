## Introduction
At the Yale Center for Research Computing, we separate **course 
accounts** from regular **research accounts**. 
This allows us to separate quotas for the two types of accounts and 
makes it easy to creat and delete course accounts each semester. Users 
with multiple accounts (ex: a research account plus a course account) 
also find it is extremely useful to have the working spaces of their 
research separated from those of their coursework on the cluster.

The YCRC OOD servers are configured with CAS for authentication. Users
log in to our CAS-enabled OODs using their NetID, which is unique to each
user. However, when a user has multiple accounts on the cluster, they 
would like to be able to log in and work under different accounts. So 
in addition to the default virtual host deployed by OOD, which will
be used by the regular research accounts, for each course
using the cluster, we also create a course-specific virtual host
and map the login NetID to the appropriate user account. The mapping operation
is done using our customized user mapping scripts. 
The different virtual hosts are essentially different frontends of the OOD server.
However, they all share the same OOD backend. Through multiple virtual hosts and
our customized user mapping scripts, 
a user with multiple accounts can easily log in with one NetID, but work under different accounts on OOD.

Our user mapping script also supports **impersonation**, a handy feature for
system admins to log into OOD as any users. We have used impersonation frequently
to help our user debugging their OOD issues. 

Our customized OOD user mapping scripts are based on the OOD user mapping scripts from OOD version 1.8 and below. Since OOD 2.0, OOD has adopted `user_map_match` as the default user mapping command. However, we can still use the scripts described in this document by assigning `user_map_cmd` to one of the scripts in `ood_portal.yml`.

## What's Included
<pre>
.
├── macro.conf (<i>a sample configuration file for name-based virutal hosts</i>)
├── ood-portal.conf.erb.patch (<i>a patch to make OOD work properly with multiple virtual hosts </i>)
├── README.md (<i>this file</i>)
└── ycrc_auth_map (<i>source tree of our customized user mapping scripts</i>)
    ├── bin
    │   ├── ood_auth_map.automap
    │   ├── ood_auth_map.mapfile
    │   └── ood_auth_map.regex
    ├── CHANGELOG.md
    ├── Gemfile
    ├── lib
    │   ├── ood_auth_map
    │   │   ├── admin.rb (<i>the mapfile used by admins to impersonate a user</i>)
    │   │   ├── helpers.rb
    │   │   └── version.rb
    │   └── ood_auth_map.rb
    ├── LICENSE.txt
    ├── ood_auth_map.gemspec
    ├── Rakefile
    └── README.md
</pre>

## Deploy the Customized User Mapping Scripts
1. clone this repository
```{bash}
git clone https://github.com/ycrc/ood-user-mapping 
``` 
1. copy `ycrc_auth_map` and rename it to something you like (we use `customized_auth_map` as an example)
```{bash}
cd ood-user-mapping
sudo cp -R ycrc_auth_map /opt/ood/customized_auth_map
```
1. edit `/etc/ood/config/ood-portal.yml` and add the following line. You could also choose `ood_auth_map.mapfile` or `ood_auth_map.automap` depending on what you need to do. 
```{bash
user_map_cmd: '/opt/ood/customized_auth_map/bin/ood_auth_map.regex'
```
1. apply the patch to the portal generator
```{bash}
patch -u /opt/ood/ood-portal-generator/templates/ood-portal.conf.erb -i ood-portal.conf.erb.patch
```
1. build and install the new Apache configuration file with: 
```{bash}
sudo /opt/ood/ood-portal-generator/sbin/update_ood_portal
```

## Name-based Virtual Hosts 

We need some preparational work before configuring a new name-based virtual host for OOD. First, we need to 
obtain a Canonical Name (CNAME) Record for the OOD server. Second, we need update the 
site SSL certificate to accept the new CNAME.  

To configure a new OOD virtual host, one way is to copy `/opt/rh/httpd24/root/etc/httpd/conf.d/ood-portal.conf` and then replace 
any occurrence of the old FQDN with the new CNAME. Also point `OOD_USER_MAP_CMD` to the new user mapping script if needed. 

If more than one additional virtual host needs to be created and all of them follow a specific pattern, 
then use Apache `mod_macro` will simplify the configuration tremendously. 
We have provided a sample `mod_macro` configuration file `macro.conf`, which is adapted from
the default OOD portal configuration file. Its full location is `/opt/rh/httpd24/root/etc/httpd/conf.d/macro.conf`. 

Adding a new virtual host is simple using `mod_macro`. Only two lines need be added in `macro.conf` before `UndefMacro VHost80`:
<pre>
    Use VHost80 coursename.your_domain
    Use VHost coursename coursename.your_domain
</pre>
## Impersonation
The mapping file used by system admins to impersonate a user is defined in `/opt/ood/customized_auth_map/lib/ood_auth_map/admin.rb`. The default mapping file is `/etc/ood/config/map_file`. 

To impersonate a local cluster user, add one entry to `/etc/ood/config/map_file` following format as below:

    "amdin_login_account" cluster_user_account


<b>WARNING</b>

Allowing a system admin to "run as" another user is useful when the system admin needs to help the user troubleshoot problems on OOD.
However, it is also very dangerous if the permissions of related files are not set properly, 
including `admin.rb`, `map_file`, and any other mapping files if exist (for example, mapping files used by `ood_auth_map.mapfile`). 
All these files are world readable, however, they must be owned by a privileged user and are **ONLY** writable by that user. 
In our case, those files are owned by root and is only writable by root.

## References
[OOD: setup user mapping](https://osc.github.io/ood-documentation/latest/authentication/overview/map-user.html)
