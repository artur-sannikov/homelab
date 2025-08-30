# Caddy reverse proxy setup with Crowdsec plugin

This role sets up a caddy reverse proxy for my homelab services. It integrates
with the Crowdsec plugin that runs on my OPNsense box.

# Hardware

1. OPNsense: Protectli FW4C, Intel Pentium J3710, 4GB RAM
2. VM on Proxmox host, 2GB RAM, 4 CPU of Intel Celeron N5105

## How?

Dustin Casto wrote an outstanding guide on this setup only [his
website](https://homenetworkguy.com/how-to/set-up-caddy-reverse-proxy-with-lets-encrypt-and-crowdsec-using-opnsense-lapi/).
I automated it with Ansible.

caddy runs on a VM in [Proxmox](https://www.proxmox.com/en/) on a DMZ network.
I access it via [Tailscale](https://tailscale.com/), and it redirects me to the
desired service.

Every service runs with a valid HTTPS certificate. I use a wildcard certificate
because it's easier to manage. I also found that retrieving certificates for
each subdomain is very unreliable on my network and might take hours.

I also do some SSH hardening and set up an ufw firewall.

## Prerequisites

1. Cloudflare account with an API key with permissions: `Zone.Zone Read` and
   `Zone.DNS Edit`. You need to set up this key
   `roles/reverse_proxy/files/caddy_override.conf` file.
2. I use OPNsense as my firewall. However, it should be possible to modify
   this playbook to just install and set up Caddy.
3. A domain name, since we want valid HTTPS certificates.
4. Ubuntu. This setup has been tested on Ubuntu 24.04, but should work on
   anyDebian-based Debian-based distro.
5. I use [Ubuntu cloud images](https://cloud-images.ubuntu.com/) to quickly
   bootstrap new virtual machiens on Proxmox.
6. An `inventory.yaml` file. For example,

```yaml
all:
  caddyDMZ-srv:
    hosts:
      caddyDMZ: {}
```

### Set up Crowdsec on OPNsense

This repo assumes that you have set up Crowdsec on OPNsense according to
[Dustin's
guide](https://homenetworkguy.com/how-to/set-up-caddy-reverse-proxy-with-lets-encrypt-and-crowdsec-using-opnsense-lapi/).
During the playbook's run, it will pause and ask you to validate the caddy
machine in OPNsense. Make sure you do it as described in the guide.

### Set up Cloudflare

This repo builds Caddy with the Cloudflare plugin to perform the DNS-01
challenge to validate that you own a domain. [This
guide](https://homenetworkguy.com/how-to/replace-opnsense-web-ui-self-signed-certificate-with-lets-encrypt/)
might be helpful.

## Variables and files

1. Create the
   [inventory](https://docs.ansible.com/ansible/latest/inventory_guide/intro_inventory.html).
   The repo assumes the file is called `inventory.yaml` with your machines.
2. Define host variables in `host_vars/caddyDMZ.yaml`. The comments in the
   example file should be helpful.
3. Set up your [Caddyfile](https://caddyserver.com/docs/caddyfile) in
   `roles/deploy_caddy/files`. See the provided example for ideas. I am using
   [Authentik](https://goauthentik.io/) for some of the apps that do not provide
   built-in authentication.
4. Set up `caddy_override.conf` in `roles/deploy_caddy/files`. It only
   contains the Cloudflare API token. Keep it **safe**!

Remove the `.example` extension from the provided files.

## How to run?

Provided you have Ansible installed and `inventory.yaml` and `ansible.cfg`, run
`ansible-playbook playbooks/deploy_caddy.yaml`.

## Things to keep in mind

1. I use `unattended-upgrades` to upgrade the system. It also _might_ reboot
   if it's necessary after the update. That's not ideal if you want 100%
   availability and stability because things can break after an update. Ubuntu
   is a rather stable system, and I only automatically install security
   updates; it _should_ not break after a reboot.
2. I took steps to harden SSH and set up a firewall, but it is not a
   super-protected system. I do not expose any ports on my home network and use
   public key authentication for SSH, so this security level works for me.
3. If you are inside your home network, you can set up OPNsense to override
   IP address that are returned by DNS. Now, if you
   request `service.example.com`, you will not query a remote DNS server, and
   the domain will resolve immediately to your local IP. See [Unbound DNS
   Override Aliases in
   OPNsense](https://homenetworkguy.com/how-to/create-unbound-dns-override-aliases-in-opnsense/)
   for more information.

## 🙌 Thanks

1. Dustin Casto for the amazing guide, [Set Up a Caddy Reverse Proxy with Let's
   Encrypt and CrowdSec Using OPNsense
   LAPI](https://homenetworkguy.com/how-to/set-up-caddy-reverse-proxy-with-lets-encrypt-and-crowdsec-using-opnsense-lapi/),
   this repo is based on.
2. Jay LaCroix's excellent [Ansible video series](https://www.youtube.com/playlist?list=PLqyUgadpThTL1guZCdGy7H8V4snPrpj8t).
3. Jim's Garage for [changing the way I create new VMs](https://youtu.be/Kv6-_--y5CM).
4. Software developers whose work made this repo possible.
