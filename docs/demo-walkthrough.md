# Live demo walkthrough

1. Deploy with `-DeployPremiumNetworkFeatures` only for the live session.
2. Open the Log Analytics workspace and pin the queries in `../queries/network-evidence.kql`.
3. Access `demo-client-vm` through Bastion and run `/opt/demo/generate-traffic.sh`.
4. Show the allowed and rejected application paths, then correlate them with WAF, Firewall, and VNet flow logs.
5. Run `../scripts/teardown.ps1` immediately after the demo.

## Optional service catalogue

VPN Gateway, Local Network Gateway, ExpressRoute, Virtual WAN, Route Server, DDoS Protection, Virtual Network Manager, Private DNS Resolver, Front Door, Traffic Manager, and CDN should each be enabled in dedicated Bicep modules only when their required external dependency or paid SKU is available. ExpressRoute is represented by configuration only until a circuit is provisioned.
