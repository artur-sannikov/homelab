# Set Up Proxmox Backup Server

Currently, very limited Ansible set up is available for Proxmox Backup Server
(PBS). Collection
[maxhoesel.proxmox](https://galaxy.ansible.com/ui/repo/published/maxhoesel/proxmox/)
supports some features but I wanted to avoid using even more third-party
dependencies when setting up the server.

Below are my notes on things to set up after installing PBS.

# What to Set Up Manually

## Users

Create Admin user account:

```shell
proxmox-backup-manager user create artur@pbs
```

As a `root` user, in the GUI "Configuration - Access Control" select the user
and change the password.

Add Admin access to the user account:

```shell
proxmox-backup-manager acl update / Admin  --auth-id artur@pbs
```

Create backupUser account:

```shell
proxmox-backup-manager user create backupUser@pbs
```

As a `root` user, in the GUI "Configuration - Access Control" select the user
and change the password.

After creating datastores (see below), give access:

```shell
proxmox-backup-manager acl update /datastore/pve-datastore DatastoreAdmin \
  --auth-id backupUser@pbs

proxmox-backup-manager acl update /datastore/pve-etc DatastoreAdmin \
  --auth-id backupUser@pbs

# For S3
proxmox-backup-manager acl update /datastore/PBS-B2-EU-CENTRAL DatastoreAdmin \
  --auth-id backupUser@pbs
```

### API Keys

I am backing up the configuration of Proxmox hosts and I use API keys to do
this.

```shell
# For node 1
proxmox-backup-manager user generate-token backupUser@pbs pve1-etc
# For node 2
proxmox-backup-manager user generate-token backupUser@pbs pve2-etc
```

Copy both API keys!

On Proxmox Backup Server add permissions to access the datastore created below.

```shell
set +H
proxmox-backup-manager acl update /datastore/pve-etc DatastoreBackup \
  --auth-id "backupUser@pbs!pve1-etc"

proxmox-backup-manager acl update /datastore/pve-etc DatastoreBackup \
  --auth-id "backupUser@pbs!pve2-etc"
set -H
```

`set +H` is required to disable history expansion (causes issue with `!pve1`)

## Datastores

Ansible playbook creates several mount points:

- `/mnt/pve-datastore`: for Proxmox VMs and LXC containers.
- `/mnt/pve-etc`: for Proxmox `/etc/` directory (host settings).

Now create datastores:

```shell
proxmox-backup-manager datastore create pve-datastore /mnt/pve-datastore \
  --gc-schedule "*-*-* 13:00:00"

proxmox-backup-manager datastore create pve-etc /mnt/pve-etc \
  --gc-schedule "*-*-* 14:00:00"
```

Add prune jobs:

```shell
proxmox-backup-manager prune-job create pve-datastore-prune \
  --store pve-datastore --keep-daily 7 --keep-weekly 4 \
  --keep-monthly 12 --keep-last 5 --schedule "*-*-* 17:00:00"

proxmox-backup-manager prune-job create pve-etc-prune \
  --store pve-etc --keep-daily 7 --keep-weekly 4 \
  --keep-monthly 12 --keep-last 24 --schedule "*-*-* 17:30:00"
```

Add verify jobs

```
proxmox-backup-manager verify-job create pve-datastore-verify \
  --store pve-datastore --outdated-after 30 --schedule daily \
  --ignore-verified true

proxmox-backup-manager verify-job create pve-etc-verify \
  --store pve-etc --outdated-after 30 --schedule daily \
  --ignore-verified true
```

### S3 Storage

PBS 4 added support for S3-compatible storage. Before starting, add a disk
for S3 cache. My server is running on TrueNAS Scale, so it's a matter of
adding a new zvol to the virtual machine. Then create an ext4 file system
on the drive and mount it at `/mnt/s3-cache` (via `/etc/fstab`).

You will need
`keyID` and `applicationKey` from Backblaze. For more info, see [Creating and
Managing Application
Keys](https://help.backblaze.com/hc/en-us/articles/360052129034-Creating-and-Managing-Application-Keys).
You **have** to select "Allow listing all bucket names including bucket
creation dates".

Create a file `s3-cache` with content:

```
KEYID=<keyID>
APPKEY=<applicationKey>
```

To add a Backblaze S3 storage run

```shell
source ./s3-cache

proxmox-backup-manager s3 endpoint create pbs-backblaze \
  --access-key $KEYID --secret-key $APPKEY \
  --endpoint 's3.{{region}}.backblazeb2.com' \
  --region 'eu-central-003' \
  --path-style true \
  --provider-quirks skip-if-none-match-header

rm ./s3-cache
```

Now create a datastore

```shell
proxmox-backup-manager datastore create PBS-B2-EU-CENTRAL /mnt/s3-cache \
  --backend type=s3,client=pbs-backblaze,bucket=<your_bucket> \
  --gc-schedule "*-*-* 14:00:00"
```

Add prune job

```shell
proxmox-backup-manager prune-job create pbs-b2-eu-central-prune  \
  --store PBS-B2-EU-CENTRAL --keep-daily 7 --keep-weekly 4 \
  --keep-monthly 12 --keep-last 5 --schedule "*-*-* 17:00:00"
```

Add verify jobs:

```shell
proxmox-backup-manager verify-job create pve-b2-eu-central-verify \
  --store PBS-B2-EU-CENTRAL --outdated-after 30 --schedule 'Wed,Sat 18:00:00' \
  --ignore-verified true
```

For the S3-backed storage create a pull sync jobs for encrypted off-site
backups.

```shell
proxmox-backup-manager sync-job create backblaze  --store PBS-B2-EU-CENTRAL \
  --remote-store pve-datastore --verified-only true --encrypted-only true \
  --schedule 21:00 --remove-vanished --sync-direction pull \
  --owner backupUser@pbs
```

## Certificates

Add ACME account. Let's Encrypt does not use email anymore, so put any email
address:

```shell
proxmox-backup-manager acme account register letsencrypt enc@proton.me

# Select https://acme-v02.api.letsencrypt.org/directory
# Agree to ToS
```

On Cloudflare, create an API token with this permission:

- Zone - DNS - Edit

Create a file with this content to set up Cloudflare DNS:

```txt
#/root/token
CF_Account_ID=<your_account_id>
CF_Token=<token_from_above>
CF_Zone_ID=<domain_zone_id>
```

Run:

```shell
proxmox-backup-manager acme plugin add dns cloudflare --api cf --data ./token
rm ./token
```

I could not find any information about how to do it via CLI. In web-UI, go to
Configuration &#8594; Certificates. Add ACME, set Challenge type to DNS, select
the plugin created above, input your domain. Click OK and then Order
Certificates Now.

## Proxmox Backup Client to Backup Proxmox Host

It is possible to backup and Linux file/directory with `proxmox-backup-server`
client (installed by default on Proxmox VE).

I adapted a script from
[Proxmox forum](https://forum.proxmox.com/threads/is-there-a-way-to-backup-the-pve-host-to-the-proxmox-backup-server-pbs.157945/).

1. Place the content below to the file `/usr/local/sbin/pve-backup.sh`.
2. Set the environment variables in the `/root/pve-backup.env`.
3. Restrict `pve-backup.env` permissions `chmod 640 /root/pve-backup.env`.
4. Make the script executable: `chmod u+x /usr/local/sbin/pve-backup.sh`.
5. You can get the value for PBS_FINGERPRINT by running
   `proxmox-backup-manager cert info | grep Fingerprint`
6. To generate a backup encryption key run

```shell
proxmox-backup-client key create /root/pve-etc.key --kdf none
```

The encryption key is not password-protected to allow automation. Save it to a
password manager and keep it safe!

```
# /root/pve-backup.env
export PBS_REPOSITORY=backupUser@pbs!<API TOKEN NAME>@<PBS HOST>:<DATASTORE>
export PBS_PASSWORD=<API TOKEN>
export PBS_FINGERPRINT=<PBS HOST FINGERPRINT>
```

```bash
#!/bin/bash
if [ -f /root/pve-backup.env ] ; then
        source /root/pve-backup.env
else
        echo "File /root/pve-backup.env missing" > /dev/stderr
        exit 1
fi

/usr/bin/proxmox-backup-client backup etc.pxar:/etc \
        --crypt-mode encrypt \
        --keyfile /root/pve-etc.key \
        --backup-type host \
        --skip-lost-and-found \
        --include-dev /etc/pve
```

5. Run `crontab -e`. I suggest using healthchecks.io to monitor failed jobs.

```
8 20 * * * /usr/local/sbin/pve-backup.sh && curl -fsS -m 10 --retry 5 -o /dev/null <healthchecks.io link>
```

### Restore with Proxmox Backup Client

```shell
# Create directory for restore
mkdir restore

# Show snapshots
proxmox-backup-client snapshot list host/pve1 --repository backupUser@pbs@<PBS_IP>:pve-etc

# Restore
proxmox-backup-client restore --repository backupUser@pbs@<PBS_IP>:pve-etc \
  <snaphot_id from previous command> etc.pxar restore/
```
