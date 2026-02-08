# Ansible Role to Deploy Action Runners

This Ansible role deploys Action runners on Forgejo instances (ex. Codeberg).

## Acknowledgements

Much code here is based on [this
role](https://github.com/roles-ansible/ansible_role_forgeo_runner).

## Variables

Set up two environment variables with `read -s VAR_NAME`:

- `FORGEJO_INSTANCE`
- `FORGEJO_TOKEN` - registration token

## How to Deploy

To deploy with `Just` just run

```shell
just deploy-forgejo-runner
```
