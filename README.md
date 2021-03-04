## Impersonation
This script allows a system admin to log in to the OOD portal with their own account, but becomes another user on the cluster. This comes handy when the system admin needs to "run as" the other user to help troubleshooting user issues. To impersonate a local cluster user, add one entry to /etc/ood/config/map-file with the following format:

    "amdin_account" cluster_user_account

If your site are using the default regex user mapping script from OOD, you can simply modify `mod_auth_user.regex` with the following changes. Then `mod_auth_user.regex` will try to map a user using `/etc/ood/config/map_file` first.

    diff /opt/ood/ood_auth_map/bin/ood_auth_map.regex.orig
    54,56c54
    <     if sys_user =  Helpers.parse_mapfile('/etc/ood/config/map_file', auth_user)
    <       puts sys_user
    <     elsif sys_user = Helpers.parse_string(auth_user, /#{options[:regex]}/)
    ---
    >     if sys_user = Helpers.parse_string(auth_user, /#{options[:regex]}/)


## References
[OOD: setup user mapping](https://osc.github.io/ood-documentation/latest/authentication/overview/map-user.html)
