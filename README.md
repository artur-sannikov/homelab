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
  - RAM: `16GB`
  - SSD: `1TB`

- Dell OptiPlex 3000 Micro:
  - CPU: `Intel(R) Core(TM) i5-12500T @ 4.40GHz`
  - RAM: `64GB`
  - SSD: `2TB`

### Software

All the services are deployed via Podman Quadlets.

| Software          | Purpose                          |
|-------------------|----------------------------------|
| Actual Budget     | Budgeting                        |
| Authentik         | Single-Sign On                   |
| Changedetection   | Detect website changes           |
| FreshRSS          | Follow RSS feeds                 |
| Librechat         | API access to multiple LLMs      |
| Paperless-ngx     | Document management              |
| Readeck           | Read-it-later                    |
| Stirling-PDF      | PDF manipulation                 |
| Grafana           | Observe homelab with nice charts |
| Homepage          | ...Homepage                      |
| Prometheus        | Collect data for Grafana         |
| Speedtest-tracker | Measure Internet speed           |
| Uptime Kuma       | Monitor uptime                   |

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
