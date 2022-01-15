locals {
  account_tier             = (var.account_kind == "FileStorage" ? "Premium" : split("_", var.skuname)[0])
  account_replication_type = (local.account_tier == "Premium" ? "LRS" : split("_", var.skuname)[1])
}

data "azurerm_resource_group" "rgrp" {
  name = var.resource_group_name
}

resource "azurerm_storage_account" "storeacc" {
  name                      = var.storage_account_name
  resource_group_name       = data.azurerm_resource_group.rgrp.name
  location                  = coalesce(var.location, data.azurerm_resource_group.rgrp.location)
  account_kind              = var.account_kind
  account_tier              = local.account_tier
  account_replication_type  = local.account_replication_type
  enable_https_traffic_only = true
  min_tls_version           = var.min_tls_version
  allow_blob_public_access  = var.allow_blob_public_access
  tags                      = var.tags

  identity {
    type = var.assign_identity ? "SystemAssigned" : null
  }

  dynamic "blob_properties" {
    for_each = var.soft_delete_retention > 0 ? ["true"] : []

    content {
      delete_retention_policy {
        days = var.soft_delete_retention
      }
    }
  }
}

resource "azurerm_advanced_threat_protection" "atp" {
  target_resource_id = azurerm_storage_account.storeacc.id
  enabled            = var.enable_advanced_threat_protection
}

resource "azurerm_storage_container" "container" {
  count                 = length(var.containers_list)
  name                  = var.containers_list[count.index].name
  storage_account_name  = azurerm_storage_account.storeacc.name
  container_access_type = lookup(var.containers_list[count.index], "access_type", "private")
}

resource "azurerm_storage_share" "fileshare" {
  count                = length(var.file_shares)
  name                 = var.file_shares[count.index].name
  storage_account_name = azurerm_storage_account.storeacc.name
  quota                = lookup(var.file_shares[count.index], "quota", null)
}

resource "azurerm_storage_table" "tables" {
  count                = length(var.tables)
  name                 = var.tables[count.index].name
  storage_account_name = azurerm_storage_account.storeacc.name
}

resource "azurerm_storage_queue" "queues" {
  count                = length(var.queues)
  name                 = var.queues[count.index].name
  storage_account_name = azurerm_storage_account.storeacc.name
}

resource "azurerm_storage_management_policy" "lcpolicy" {
  count              = length(var.lifecycles) == 0 ? 0 : 1
  storage_account_id = azurerm_storage_account.storeacc.id

  dynamic "rule" {
    for_each = var.lifecycles
    iterator = rule
    content {
      name    = "rule${rule.key}"
      enabled = true
      filters {
        prefix_match = rule.value.prefix_match
        blob_types   = ["blockBlob"]
      }
      actions {
        base_blob {
          tier_to_cool_after_days_since_modification_greater_than    = rule.value.tier_to_cool_after_days
          tier_to_archive_after_days_since_modification_greater_than = rule.value.tier_to_archive_after_days
          delete_after_days_since_modification_greater_than          = rule.value.delete_after_days
        }
        snapshot {
          delete_after_days_since_creation_greater_than = rule.value.snapshot_delete_after_days
        }
      }
    }
  }
}

resource "azurerm_private_endpoint" "storeacc" {
  count = var.create_private_endpoint ? 1 : 0

  name                = "${var.storage_account_name}-ep"
  location            = data.azurerm_resource_group.rgrp.location
  resource_group_name = data.azurerm_resource_group.rgrp.name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = var.storage_account_name
    is_manual_connection           = false
    private_connection_resource_id = azurerm_storage_account.storeacc.id
    subresource_names = distinct(
      compact(
        [
          length(var.containers_list) > 0 ? "blob" : "",
          length(var.file_shares) > 0 ? "file" : "",
          length(var.queues) > 0 ? "queue" : "",
          length(var.tables) > 0 ? "table" : "",
          var.is_log_storage ? "blob" : "",
          var.is_dr_storage ? "blob" : "",
        ]
      )
    )
  }

  dynamic private_dns_zone_group {
    for_each = length(var.private_endpoint_dns_zone_ids) > 0 ? [1] : []

    content {
      name                 = "${var.storage_account_name}-ep"
      private_dns_zone_ids = var.private_endpoint_dns_zone_ids
    }
  }

  tags = var.tags
}

resource "azurerm_storage_account_network_rules" "netrules" {
  count = var.network_rules != {} ? 1 : 0

  resource_group_name  = data.azurerm_resource_group.rgrp.name
  storage_account_name = azurerm_storage_account.storeacc.name

  default_action             = lookup(var.network_rules, "default_action", "Deny")
  ip_rules                   = lookup(var.network_rules, "ip_rules", null)
  virtual_network_subnet_ids = lookup(var.network_rules, "subnet_ids", null)
  bypass                     = lookup(var.network_rules, "bypass", ["Logging", "Metrics", "AzureServices"])

  depends_on = [
    azurerm_advanced_threat_protection.atp,
    azurerm_storage_container.container,
    azurerm_storage_share.fileshare,
    azurerm_storage_table.tables,
    azurerm_storage_queue.queues,
    azurerm_storage_management_policy.lcpolicy
  ]
}
