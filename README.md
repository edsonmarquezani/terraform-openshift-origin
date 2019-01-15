# Overview
This is an automation to deploy [*Openshift Origin*](https://www.openshift.org/) on *Microsoft Azure*, with help of [*Terraform*](https://www.terraform.io/) and [Openshift Ansible official playbooks](https://github.com/openshift/openshift-ansible). It acomplishes pretty much the same as [Microsoft's official scripts](https://github.com/Microsoft/openshift-container-platform) does, but instead of using [*Azure CLI*](https://docs.microsoft.com/en-us/cli/azure/overview?view=azure-cli-latest), leverages Terraform for cloud automation.

It was developed at work, so the setup follows an architecture defined within that context. (You'll likely need to modify it to suit your needs.)

Mainly, it deploys the following components:

- Nodes
  - **1 bastion host** for Ansible (won't be a member of the cluster)
  - **a master node pool** (include all master and node components + ETCd)
  - **a infra node pool** dedicated to cluster components (registers, routers, metric and logging subsystems)
  - **a generic node pool**, for application general usage
- Load Balancers
  - 1 private load balancer for Master API/Console traffic
  - 1 private balancer for private router
  - 1 public balancer for public router
- DNS records (*AWS Route53*)
  - `A` records for every VM
  - `A` record for Master API/Console
  - Subdomains with wildcard records for public and private routes
- Openshift-related resources
  - Routers
    - 1 public (Openshift's default)
    - 1 private (additional)
  - Storage Classes
    - Azure Managed Disk Standard LRS
    - Azure Managed Disk Premium LRS
  - Logging and metrics subsystems (if enabled)


# Requirements
- Terraform >= 0.11.1
- Azure credentials on environment (see `az login` command or alternatives)
- AWS credentials on environment (see `aws configure` command or alternatives)
- A DNS zone/domain delegated to *AWS Route53* (**unfornately, this part is not easily decoupable from the solution, as all FQDNs used in configuration come from this zone, and without it, it won't work** - contributions are welcome)

After all infra-structure is created, all necessary pre-setup steps will be done on VMs (Docker installation, Docker storage setup, etc). Then, the main automation will be run from the bastion host.

**In order to do so, Terraform needs to be able to connect via SSH on VMs. So make sure you have a private key loaded (`~/.ssh/id_rsa` or via `ssh-agent`) and that it matches the public key set on `ssh_public_key` module variable.**

Regarding providers credentials, you can, alternatively, define them directly on Terraform. See [***Azure***](https://www.terraform.io/docs/providers/azurerm/index.html) and [***AWS***](https://www.terraform.io/docs/providers/aws/index.html) providers documentation.

# How to use
It's strongly recommended that you fork it, and modify it according to your needs. But, if for any reason you don't want to, the easiest way to use it is setting this repository as a module source, and parameterize it according to your needs, like below.

```hcl
module "openshift-cluster" {

  # Change the repo branch if needed and NEVER USE MASTER
  # (as it may change and break you setup)
  source = "github.com/edsonmarquezani/terraform-openshift-origin?ref=0.1.0"

  environment         = "production"
  resource_group_name = "openshift-production"
  location            = "East US"
  location_compact    = "eastus"

  master_nodes_initial_vm_count = 3
  infra_nodes_initial_vm_count  = 2
  app_nodes_initial_vm_count    = 2

  deploy_metrics = true
  deploy_logging = true

  # All following variables don't have defaults, thus, are mandatory.
  private_subnet = "/subscriptions/<tenant_id>/resourceGroups/my-resource-group/providers/Microsoft.Network/virtualNetworks/my-network/subnets/my-private-subnet"
  public_subnet = "/subscriptions/<tenant_id>/resourceGroups/my-resource-group/providers/Microsoft.Network/virtualNetworks/my-network/subnets/my-public-subnet"

  # Make sure the matching private key is loaded on you environment, so Terraform
  # will able to connect via SSH
  ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC2Vq54X3Z/iUKOAXW9YhNdPc3mt58tzECucaglIqsKHoWk2/yLfVlJSAQcWRHYU33r2lYKyeYK67mnY7qNa2u2snxaUylIptWmZ/E4BuoeLrJG6LY4q5cvlPkPIUJKQ2X2ZSjoOv3zba1QgpbupA0H/+IFO34/+JsAZxuwF8w67TvqnBaqdA7tJUxoGhJB1vzncnPJWVlqkx9xRQJeBsSIv86UNLsKoqX+DiYKuIgFnyt3xojrFUGWq1/2tbkxNfkrxkUgXuQTZ9pqStVHSmQxzK3HMuIKrxKnvkHN6ubfDEalJBhUCx/86P4RuX5ZxYNhWrtvfoRXV2J2xhlsjhLB"

  # These are not the credentials used by Terraform, but the ones used by
  # Kubernetes (cloud-provider configuration)
  azure_tenant_id         = "<tenant_id>"
  azure_subscription_id   = ""
  azure_aad_client_id     = ""
  azure_aad_client_secret = ""
  azure_aad_tenant_id     = ""

  # MUST BE managed by AWS Route53
  root_domain             = "domain.com"
  # MUST BE a subdomain of 'root_domain'
  cluster_domain          = "openshift.domain.com"
  # MUST BE a subdomain of 'cluster_domain'
  cluster_private_domain  = "internal.openshift.domain.com"
}


output "fqdns" {
  value = [ "${concat( module.openshift-cluster.master-nodes-fqdns,
                       module.openshift-cluster.app-nodes-fqdns,
                       module.openshift-cluster.infra-nodes-fqdns)}",
            "${module.openshift-cluster.bastion-fqdn}"
          ]
}

output "openshift-url" {
  value = "${module.openshift-cluster.openshift-url}"
}

```

```shell
$ terraform init
$ terraform apply
```

If successfull, Terraform will show information like bellow.
```
Apply complete! Resources: 87 added, 0 changed, 0 destroyed.

Outputs:

fqdns = [
    openshift-production-master-1.openshift.domain.com,
    openshift-production-master-2.openshift.domain.com,
    openshift-production-master-3.openshift.domain.com,
    openshift-production-node-1.openshift.domain.com,
    openshift-production-infra-1.openshift.domain.com,
    openshift-production-bastion.openshift.domain.com
]
openshift-url = https://console.openshift.domain.com:8443

```

The entire proccess takes about 1 hour to complete.

### Caveats/Hints
- It's a good idea to change the automation user private/public key-pair on `files/keys` prior to run it, for obvious security reasons.
- `files/configs/inventory.yaml.tpl` is the main Ansible playbook configuration file, and you may want/need to modify options that are not parametrized as Terraform variables.
- You'll probably want to add other authentication backends and/or users (option `openshift_master_identity_providers`). A **dangerous** `admin:admin` is created by default.
- It's recommended to pass some variable values on command-line (with `-var name=value` Terraform option), instead of commiting it on repository, like credentials, ssh-keys, etc - any sensitive information.
- I find it important to pin playbooks' version to guarantee consistent deploys across cluster's lifespan (`openshift_playbook_version`); it doesn't mean it should never be updated - in fact, when setting a cluster from scratch, it sounds a good idea to use the latest one; **only be warned that it hasn't been tested with any version different from the default**.

For Ansible deployment options, see the [official documentation](https://docs.openshift.org/latest/install_config/install/advanced_install.html).

# Scaling the cluster

To scale the cluster, just add/change one of the following module variables with the wanted value:
```
master_nodes_extra_vm_count
infra_nodes_extra_vm_count
app_nodes_extra_vm_count
```

Then apply it as usual.

**Important:** After the cluster initial setup, the only way to scale it is modifying the variables above. **Don't change `*_initial_vm_count` variables after it.** (The reason for that is the way Ansible playbooks work, having different ones for each purpose. Indeed, the task of adding a new node to the cluster is far more simple than setting one from scratch.)

# Know issues

- I've experienced problems with DNS resolution when destroying and recreating the cluster in a short interval - it seems to be related to NS records' TTL, that are not being respected, although set to a low value.
- Master scale-out will fail in the middle of the playbook run (in the current version), but running it again finishes the task successfully - just run it twice and you'll be fine.
- Metrics and logging subsystem will very oftenly fail, because of persistent storage bootstrap - it can be solved scaling out all components to zero, then scaling them in at the right order (always the database first - Cassandra, Elasticsearch - then the others).
- I would recommended to reboot all VMs after the initial setup - I've run into some comunication issues inside PODs' network right after nodes creation, and a restart fixed it.

**If the automation fails at any step, it will abort completely**. Usually and theoretically, once the cause has been fixed, Terraform can be run again, and will finish it. (Note that it will run everything over again.)

Yet, if you change something on scripts/confs in the meantime, it's necessary to do a few manual steps to get it applied next time Terraform is run:
  - connect to Bastion and delete all setup files
```shell
$ sudo rm -rf /tmp/setup-files*
```
  - run Terraform, ensuring it will copy files again
```shell
$ terraform taint --module=<name_of_module> null_resource.setup-openshift-files
$ terraform apply
  ```

# Contributing
I may accept PRs, as long as they're minimally relevant. But I can't guarantee I will be able to test it every time, once it cost (not so little) time and money. So, you would probably be better off forking it. Really.

My main intention was to share it, but I really can't commit myself to evolve it.

# Final considerations

Running Openshift on Azure is quite tricky. If you go through the setup scripts, you'll see that there's a lot of workarounds related to corner cases on Ansible's playbooks, and things like that. This setup (since Openshift 3.6) has cost me unaccountable hours of work and I'm pretty sure it is still incomplete. I wouldn't be surprised if you find other issues as well. Yet, I hope it can be helpfull, as it seems *Red Hat* itself is not very experienced with setups on *Azure*.
