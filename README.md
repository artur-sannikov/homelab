# Artur's Homelab

This the repo, which deployes my homelab with Ansible.

## Overview

I like the idea of Infrastructure of Code, Automations, and reproducible builds.
This is my attempt to achieve this for my homelab.

> **What's a homelab?**
>
> It's a hardware and software experimental laboratory for you to test and break
> bleeding-edge technologies. And learn, learn so much about how the internet works,
> what's behind the scenes of common cloud services and large websites, and much more.
>
> At the same time, a homelab can be your production environment to run self-hosted
> services to enhance your quality of life, while achieving maximum privacy, because
> all of you data is at your home.
>
> To learn more, consult [/c/selfhosted](https://lemmy.world/c/selfhosted),
> [/r/homelab](https://www.reddit.com/r/homelab/), and
> [/r/selfhosted](https://reddit.com/r/selfhosted).

### Hardware

- Intel NUC11ATKC4:
  - CPU: `Intel Celeron N5105 @ 2.00GHz`
  - RAM: `32GB`
  - SSD: `1TB`

- Dell OptiPlex 3000 Micro:
  - CPU: `Intel(R) Core(TM) i5-12500T @ 4.40GHz`
  - RAM: `64GB`
  - SSD: `2TB`

### Software

All the services are deployed via Podman Quadlets.

| Software                                                               | Purpose                          |
|------------------------------------------------------------------------|----------------------------------|
| [Actual Budget](https://github.com/actualbudget/actual)                | Budgeting                        |
| [Authentik](https://github.com/goauthentik/authentik)                  | Single-Sign On                   |
| [Changedetection](https://github.com/dgtlmoon/changedetection.io)      | Detect website changes           |
| [FreshRSS](https://github.com/FreshRSS/FreshRSS)                       | Follow RSS feeds                 |
| [Librechat](https://github.com/danny-avila/LibreChat)                  | API access to multiple LLMs      |
| [Paperless-ngx](https://github.com/paperless-ngx/paperless-ngx)        | Document management              |
| [Readeck](https://codeberg.org/readeck/readeck)                        | Read-it-later                    |
| [Stirling-PDF](https://github.com/Frooodle/Stirling-PDF)               | PDF manipulation                 |
| [Grafana](https://github.com/grafana/grafana)                          | Observe homelab with nice charts |
| [Homepage](https://github.com/gethomepage/homepage)                    | ...Homepage                      |
| [Prometheus](https://github.com/prometheus/prometheus)                 | Collect data for Grafana         |
| [Speedtest-tracker](https://github.com/alexjustesen/speedtest-tracker) | Measure Internet speed           |
| [Uptime Kuma](https://github.com/louislam/uptime-kuma)                 | Monitor uptime                   |

I also deploy Forgejo for version control and Immich for photos with Nix.
See my NixOS repo [here](https://github.com/artur-sannikov/nixos/tree/main/hosts/homelab-services).

## Roadmap

- [ ] Implement Hashicorp Vault/Infiscal or other external secret management to remove my reliance on
Ansible Vault
- [ ] Tailscale deployment
- [ ] Merge this repo with [my Caddy deployment](https://github.com/artur-sannikov/caddy-ansible)

## Availability

The repo is available on [Codeberg](https://codeberg.org/arsann/homelab) and is mirrored
on [GitHub](https://github.com/artur-sannikov/homelab).

## Thanks

1. [Ansible Collection - devsec.hardening](https://github.com/dev-sec/ansible-collection-hardening/tree/master).
I used their code to dynamically generate my sshd configuration.
