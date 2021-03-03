## Impersonation
This script allows a system admin to log in to the OOD portal with their own account, but becomes another user on the cluster. This comes handy when the system admin needs to "run as" the other user to help troubleshooting user issues. To impersonate a local cluster user, add one entry to /etc/ood/config/map-file with the following format:

    "amdin_account" cluster_user_account


## References
[OOD: setup user mapping](https://osc.github.io/ood-documentation/latest/authentication/overview/map-user.html)
