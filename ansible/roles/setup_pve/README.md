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

Read in the server's address and `backupUser`'s API token. See
`setup_pbs/README.md` on how to create it and what permissions to give it.

Each token is per node.

```shell
read -s SERVER
read -s PASSWORD
read -s ENC_KEY
export TOKEN_ID=<backupUser@pbs!pve1>
export NODE=$(hostname)
```

```shell
pvesh create /storage --storage pbs-limited-$NODE --type pbs \
  --datastore pve-datastore --server $SERVER --username $TOKEN_ID \
  --password $PASSWORD --nodes $NODE --encryption-key $ENC_KEY
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

You can add notifications targets. I'm using [Migadu](https://www.migadu.com/)
for SMTP and [ntfy.sh](https://ntfy.sh).

### SMTP

First, read in your password into an environment variable `PASSWORD`.

```shell
read -s PASSWORD
```

Also the domain:

```shell
read -s DOMAIN
```

Next, run the command to add the notification target:

```shell
pvesh create /cluster/notifications/endpoints/smtp --name migadu \
  --from-address proxmox@$DOMAIN --server smtp.migadu.com --mode tls \
  --username admin@$DOMAIN --password $PASSWORD --mailto-user root@pam
```

> [!note]
> `--mailto-user` is root@pam which has an associated email address, to which
> the emails arrive.

Test that the email can be received successfully:

```shell
pvesh create /cluster/notifications/targets/migadu/test
```

### ntfy.sh

For more info see `roles/setup_pbs/README.md`.

```shell
read -s TOPIC
```

We will need a base64 version of `TOPIC` for the setup.

```shell
TOPIC_BASE64=$(echo -n $TOPIC | base64)
```

All headers and the body of the POST request should also be in base64:

```shell
echo -n "yes" | base64
# eWVz

echo -n "{{ title }}" | base64
# e3sgdGl0bGUgfX0=

echo -n "{{ message }}" | base64
# e3sgbWVzc2FnZSB9fQ==

echo -n "{{ secrets.token }}" | base64
# e3sgc2VjcmV0cy50b2tlbiB9fQ==
```

I use API keys to access my ntfy instance.

On your instances create an API key for Proxmox notification.

Create a base64 version of the authorization token secret.

```shell
read -s AUTHORIZATION_TOKEN # should be '<Bearer <token>'
AUTHORIZATION_TOKEN_BASE64=$(echo -n $AUTHORIZATION_TOKEN | base64)
```

Next, run the command to add the notification target:

```shell
pvesh create /cluster/notifications/endpoints/webhook --name ntfy --method post \
  --url "https://ntfy.asannikov.com/{{ secrets.topic }}" \
  --header name=Markdown,value=eWVz \
  --header name=X-Title,value=e3sgdGl0bGUgfX0= --body e3sgbWVzc2FnZSB9fQ== \
  --header name=Authorization,value=e3sgc2VjcmV0cy50b2tlbiB9fQ== \
  --secret name=topic,value=$TOPIC_BASE64 \
  --secret name=token,value=$AUTHORIZATION_TOKEN_BASE64
```

Test that the notification can be received successfully:

```shell
pvesh create /cluster/notifications/targets/ntfy/test
```

Unset the environment variables:

```shell
unset TOPIC
unset TOPIC_BASE64
unset AUTHORIZATION_TOKEN
unset AUTHORIZATION_TOKEN_BASE64
```

### Notification Matchers

Create notification matchers. Here I set the target to both `migadu` and `ntfy`
because I want to receive notifications on both, but you can adjust as per your
needs.

```shell
pvesh set /cluster/notifications/matchers/default-matcher --disable true

pvesh create /cluster/notifications/matchers --name errors \
  --match-severity unknown,warning,error --target migadu --target ntfy \
  --comment "Notify about unknown, warnings or errors"
```

## Sources

1. [Proxmox API Viewer](https://pve.proxmox.com/pve-docs/api-viewer/index.html)
   contains all the API endpoints for the interaction with the `pvesh` CLI
   tool.
2. [Proxmox
   Notifications](https://pve.proxmox.com/pve-docs/chapter-notifications.html).
