[![GitHub License](https://img.shields.io/badge/license-MIT-green.svg)](https://opensource.org/licenses/MIT)

## Introduction
The clusters at the Yale Center for Research Computing (YCRC) are used 
for both research and academic courses with a computational compoment. Therefore, we support two types 
of accounts on out clusters: **research accounts** and **course accounts**. 
Althouth both are essentially cluster accounts, 
this distinction allows us to follow different procedures and provide seperate 
cluster resources for the two types of accounts.

The YCRC OOD servers are configured with CAS for authentication. Users
log in to a CAS-enabled OOD using their NetID, which is unique to each
user. When a user has multiple accounts on the cluster 
(ex: a research account + a course account), they 
would like to be able to log in to OOD and work under the different accounts. 
However, the default setting of OOD can only allow one such account. 
To resolve the issue, we dedicate the default virtual host deployed by OOD 
for research accounts only and create an individual virtual host for 
each course that is using OOD on the cluster. We also map the login NetID 
to the appropriate course account in each course-specific virtual host. 
The mapping operation is done using our customized user mapping scripts. 
Through multiple virtual hosts and
our customized user mapping scripts, a user with multiple accounts can easily 
log in with one NetID, but work under different accounts on OOD.

The YCRC user mapping script also supports **impersonation**, a handy feature to allow
a system admin to log in to OOD and become another user. Impersonation is useful when
helping users troubleshoot their issues on OOD. 

The YCRC customized OOD user mapping scripts are based on the OOD user mapping scripts 
from OOD version 1.8 and below. Since OOD 2.0, OOD has adopted `user_map_match` 
as the default user mapping command. However, we can still use the scripts described 
in this document by adding `user_map_cmd` in `ood_portal.yml`.

## What's Included
<pre>
.
├── macro.conf (<i>a sample configuration file for name-based virutal hosts</i>)
├── ood-portal.conf.erb.patch (<i>a patch to make OOD work properly with multiple virtual hosts </i>)
├── README.md (<i>this file</i>)
└── ycrc_auth_map (<i>source tree of the YCRC customized user mapping scripts</i>)
    ├── bin
    │   ├── ood_auth_map.automap
    │   ├── ood_auth_map.mapfile
    │   └── ood_auth_map.regex
    ├── CHANGELOG.md
    ├── Gemfile
    ├── lib
    │   ├── ood_auth_map
    │   │   ├── admin.rb (<i>define the mapfile used by admins to impersonate a user</i>)
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
2. copy `ycrc_auth_map` and rename it to something you like (we use `customized_auth_map` as an example)
```{bash}
cd ood-user-mapping
sudo cp -R ycrc_auth_map /opt/ood/customized_auth_map
```
3. edit `/etc/ood/config/ood-portal.yml` and add the following line. You could also choose `ood_auth_map.mapfile` or `ood_auth_map.automap` depending on what you need to do. 
```{bash
user_map_cmd: '/opt/ood/customized_auth_map/bin/ood_auth_map.regex'
```
4. apply the patch to the portal generator
```{bash}
patch -u /opt/ood/ood-portal-generator/templates/ood-portal.conf.erb -i ood-portal.conf.erb.patch
```
5. build and install the new Apache configuration file with: 
```{bash}
sudo /opt/ood/ood-portal-generator/sbin/update_ood_portal
```

## How to Use the User Mapping Scripts

You can test the user mapping scripts from the command line. To see how to use one of the scripts, launch the script with `--help`. For example: 
```{bash}
$ ./ycrc_auth_map/bin/ood_auth_map.automap --help
Usage: ood_auth_map.automap [options] <authenticated_user>

Used to parse for a mapped authenticated user from a template.

General options:
    -a, --automap=TEMPLATE           # Template used to generate the authenticated user
                                     # TEMPLATE must contains at least one '%' sign
                                     # The first '%' in TEMPLATE will be replaced by the authenticated username
                                     # Default: None

Common options:
    -h, --help                       # Show this help message
    -v, --version                    # Show version

Examples:
    Map the authenticated username to the system-level username 
    by replacing the first '%' in TEMPLATE. 

        ood_auth_map.automap --automap=foo_%_bar alice

    this will return `foo_alice_bar`. 
```
## Name-based Virtual Hosts 

We need some preparation before configuring a new name-based virtual host for OOD. First, we need to 
obtain a Canonical Name (CNAME) Record for the OOD server. Second, we need to update the 
site SSL certificate to accept the new CNAME.  

Once the above are done, we can start configuring a new OOD virtual host.
One way is to make a copy of `/opt/rh/httpd24/root/etc/httpd/conf.d/ood-portal.conf` and then replace in the copy 
any occurrence of the old FQDN with the new CNAME. Also point `OOD_USER_MAP_CMD` to the new user mapping script if needed. 

If more than one additional virtual host needs to be created and all of them follow a specific pattern, 
then using Apache `mod_macro` will simplify the configuration tremendously. 
A sample `mod_macro` configuration file `macro.conf` is provided, which is adapted from
the default OOD portal configuration file. It should be stored at `/opt/rh/httpd24/root/etc/httpd/conf.d/macro.conf`. 

Adding a new virtual host is simple using `mod_macro`. Only two lines need be added in `macro.conf` before `UndefMacro VHost80`:
<pre>
    Use VHost80 coursename.your_domain
    Use VHost coursename coursename.your_domain
</pre>

## Impersonation

Allowing a system admin to "run as" another user is useful when the system admin needs to help the user troubleshoot problems on OOD.
Our scripts allow impersonation through a mapping file. 
The mapping file is defined in `/opt/ood/customized_auth_map/lib/ood_auth_map/admin.rb`. 
The default mapping file is `/etc/ood/config/map_file`. 

To impersonate a local cluster user, add one entry to `/etc/ood/config/map_file` following the format as below:

    "amdin_login_account" cluster_user_account


## Security

File based mapping is very flexible. It could also be dangerous if the permissions of 
the related files are not set properly. As such, we must take necessary precaution to protect
the code base of `customized_auth_map`, the mapping file used for impersonation, and any other mapping files 
used by `ood_auth_map.mapfile` if it is used as the user mapping command.
All these files are world readable, however, they must be owned by a privileged user and are **ONLY** writable by that user. 
In our case, those files are owned by root and are only writable by root.

## Contact Us 

Please provide your feedback and report bugs to [research.computing@yale.edu](mailto:research.computing@yale.edu)

## References

[OOD: setup user mapping](https://osc.github.io/ood-documentation/latest/authentication/overview/map-user.html)

[PEARC'21 Paper: Using Single Sign-On Authentication with Multiple Open OnDemand Accounts](https://camps.aptaracorp.com/ACM_PMS/PMS/ACM/PEARC21/17/24105510-ba1d-11eb-8d84-166a08e17233/OUT/pearc21-17.html)
