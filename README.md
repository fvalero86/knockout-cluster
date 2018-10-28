# knockout-infra

## Requeriments
* Centos 7
* Google Cloud account with billing enabled
* automatically installed by install.sh:
  * kubectl and gcloud commands to interact with the kubernetes cluster and GCloud account.
  * helm package manager.
  * tiller (helm server) installed on kubernetes.

## Explanation
The installation platform for the test is based on a Kubernetes Cluster from Google Cloud.

The script **install.sh** will set up the required services:
* Virtual Load Balancer (created by each service)
* Nginx
* Mysql
* Prometheus / Alertmanager and Graphana (monitoring system)

## Packages
The **install.sh** script uses the helm package manager to install all the infra packages easily.

### Infra base
The custom package created for the knockout test which installs nginx and mysql: https://github.com/fvalero86/knockout-cluster/tree/master/package

### Monitoring
The monitoring part is installed via a Custom Definition Resource (CDR) https://docs.okd.io/latest/admin_guide/custom_resource_definitions.html **ServiceMonitor** called Prometheus operator: https://github.com/coreos/prometheus-operator which hugely simplifies the configuration and the installation of the monitoring infra inside a Kubernetes cluster. 

## Installation
The script **install.sh** should run without arguments.

Only two variables are required before start:
* [`account_name`](install.sh#L5): The email account with RBAC permissions to manage the Kuberntes cluster into the GCloud account.
* [`billing_account`](install.sh#L6): The billing account id. The script will link the cluster to this account.


## Caveats
* **nginx** and **mysql** are installed inside `default` Kubernetes namespace.
* **tiller** (helm server) is installed inside `kube-system` workspace.
monitoring system (grafana, prometheus, alertmanager, etc) are installed inside `monitoring` workspace.