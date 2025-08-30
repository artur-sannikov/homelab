# Deployment

## host_vars

Create `host_vars/caddyDMZ.yaml` file for variables specific for
caddy machine.

```yaml
lapi_endpoint: http://192.168.1.1:8080
```

## Required files

Two files are required for this deployment (see the respective examples
files in `roles/reverse_proxy/files/*.example`):

- `caddy_override.conf`: holds Cloudflare (DNS) token
- `Caddyfile`: main [configuration
  file](https://caddyserver.com/docs/caddyfile) for caddy.
