# Azure networking stack observability demo

Disposable Azure lab that generates real network traffic and centralizes the resulting diagnostics in Log Analytics. All deployed resources belong to one dedicated resource group so the lab can be removed and recreated predictably.

## What it deploys

- Hub/spoke VNets, NSGs, user-defined routes, NAT Gateway, Azure Firewall, Azure Bastion, and VNet flow logs.
- Application Gateway WAF v2, an internal load balancer, two small Linux app VMs, Private Link, and Private DNS.
- A Log Analytics workspace and diagnostic settings for Application Gateway, Firewall, Storage, and network flow telemetry.

The premium network components are intentionally opt-in. Enable them only for a live demo, then run teardown.

## Prerequisites

- Azure CLI signed in to subscription `23d7b6f5-d09b-44e0-9b30-2c4de3ce5dab`
- Contributor permission on that subscription
- An SSH public key, supplied at deployment time

## Deploy

```powershell
./scripts/deploy.ps1 -SshPublicKey (Get-Content "$HOME/.ssh/id_ed25519.pub" -Raw) -DeployPremiumNetworkFeatures
```

The script displays the active subscription and requires a typed confirmation before creating the resource group.

## Generate evidence

After deployment, use Azure Bastion to access `demo-client-vm`, then run:

```bash
/opt/demo/generate-traffic.sh
```

This produces normal app requests, a WAF-triggering request, allowed and denied egress, app-tier flows, and private-endpoint storage access. Run the KQL files in `queries/` after logs arrive.

## Tear down

```powershell
./scripts/teardown.ps1
```

The teardown script verifies the expected subscription, tags, and resource group name before issuing deletion. It never deletes the Azure subscription, Entra ID tenant, or anything outside the demo resource group.
