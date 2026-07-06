deploy-services:
    cd ansible && ansible-playbook playbooks/services.yaml
deploy-monitoring:
    cd ansible && ansible-playbook playbooks/monitoring.yaml
deploy-caddy:
    cd ansible && ansible-playbook playbooks/deploy_caddy.yaml
deploy-infisical:
    cd ansible && ansible-playbook playbooks/deploy_infisical.yaml
deploy-pulse:
    cd ansible && ansible-playbook playbooks/deploy_pulse.yaml
deploy-forgejo-runner:
    cd ansible && ansible-playbook playbooks/deploy_forgejo_runner.yaml

maintain:
    cd ansible && ansible-playbook -i inventory.yaml playbooks/maintenence.yaml
