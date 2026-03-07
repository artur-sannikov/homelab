# Set Up Proxmox Virtual Environment

## Setup Proxmox Community Repositories

Disable enterprise repo:

```shell
cat <<EOF > /etc/apt/sources.list.d/pve-enterprise.sources
Types: deb
URIs: https://enterprise.proxmox.com/debian/pve
Suites: trixie
Components: pve-enterprise
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
Enabled: false
EOF
```

Enable community repo:

```shell
cat <<EOF > /etc/apt/sources.list.d/proxmox.sources
Types: deb
URIs: http://download.proxmox.com/debian/pve
Suites: trixie
Components: pve-no-subscription
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
EOF
```

Reload and update:

```shell
apt update && apt upgrade -y
```

## Notifications

The sad part is that currently there is no dedicated CLI tool like
`proxmox-backup-manager` to set everything up.

You can follow the
[docs](https://pve.proxmox.com/pve-docs/chapter-notifications.html).

Perhaps, one option is to use a series of `cat` commands to write the options
directly into the files, or use dedicated `ansible` roles to do that.

## Sources

1. [Proxmox API Viewer](https://pve.proxmox.com/pve-docs/api-viewer/index.html)
   contains all the API endpoints for the interaction with the `pvesh` CLI
   tool.
