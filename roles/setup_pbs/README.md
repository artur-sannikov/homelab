# Set up Proxmox Backup Server

Currently, very limited Ansible set up is available for Proxmox Backup Server
(PBS). Collection
[maxhoesel.proxmox](https://galaxy.ansible.com/ui/repo/published/maxhoesel/proxmox/)
supports some features but I wanted to avoid using even more third-party
dependencies when setting up the server.

Below are my notes on things to set up after installing PBS.

# What to set up manually

Create Admin user account:

```shell
proxmox-backup-manager user create artur@pbs
```

In the GUI "Configuration - Access Control" select the user and change the
password.

Add Admin access to the user account:

```shell
proxmox-backup-manager acl update / Admin  --auth-id artur@pbs
```
