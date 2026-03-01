# Set Up Proxmox Virtual Environment

## Notifications

The sad part is that currently there is no dedicated CLI tool like
`proxmox-backup-manager` to set everything up.

You can follow the
[docs](https://pve.proxmox.com/pve-docs/chapter-notifications.html).

Perhaps, one option is to use a series of `cat` commands to write the options
directly into the files, or use dedicated `ansible` roles to do that.
