locals {
  production_backup_jobs = {
    daily_snapshot = {
      id       = "daily-snapshot"
      schedule = "*-*-* 00:30"
      mode     = "snapshot"
    }

    weekly_backup = {
      id       = "weekly-backup"
      schedule = "sat 05:40"
      mode     = "stop"
    }
  }
}

resource "proxmox_backup_job" "production" {
  for_each                  = local.production_backup_jobs
  id                        = each.value.id
  schedule                  = each.value.schedule
  mode                      = each.value.mode
  storage                   = proxmox_storage_pbs.pbs-limited.id
  pbs_change_detection_mode = "metadata"                                          # Faster in theory
  pool                      = proxmox_virtual_environment_pool.production.pool_id # Only backup VMs in this resource pool
  notes_template            = "{{guestname}}"
}
