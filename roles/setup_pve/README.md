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

## Add Storage

### Proxmox Backup Server

Read in the server's address and `backupUser`'s password:

```shell
read -s SERVER
read -s PASSWORD
```

```shell
pvesh create /storage --storage pbs-limited --type pbs \
  --datastore pve-datastore --server $SERVER --username backupUser@pbs
  --password $PASSWORD
```

> [!note]
> The `--fingerprint` parameter might is required if you are not using FQDN,
> but an IP-address. Get it from the PBS dashboard's "Show Fingerprint".

## Add Backup to PBS

```
export SCHEDULE=22:30
pvesh create /cluster/backup --schedule $SCHEDULE --vmid 8001 --vmid 100 \
  --storage pbs-limited --mode snapshot
```

> [!warning]
> Running `pvesh create /cluster/backup` several times creates an identical
> backup job with a different id. It's a better idea to just use the Web-UI to
> set everything up.

> [!tip]
> To delete the backup job get a list of jobs `pvesh get /cluster/backup` and
> then delete one or more of them `pvesh delete /cluster/backup/<id>`. There is
> no way to distinguish between them other than id.

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
