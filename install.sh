# ############ INFRA CONFIGURATION ############
project_id="knockout-${RANDOM}-${RANDOM}"
project_name="knockout-test"
cluster_name="test"
account_name=""
billing_account=""
# #############################################

if [ ! -f /etc/centos-release ]; then
    echo "not a centos"
    exit 1
fi

if [ ! -f /etc/yum.repos.d/google-cloud-sdk.repo ]; then

    sudo tee -a /etc/yum.repos.d/google-cloud-sdk.repo << EOM
[google-cloud-sdk]
name=Google Cloud SDK
baseurl=https://packages.cloud.google.com/yum/repos/cloud-sdk-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
       https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOM

    yum -y install google-cloud-sdk kubectl
fi

echo -e "\n\n----------------------- login into ACCOUNT with: $account_name"
gcloud auth login
gcloud config set account $account_name

echo -e "\n\n----------------------- creating project: $project_id"
gcloud projects create $project_id --name="$project_name"
gcloud config set project $project_id

echo -e "\n\n----------------------- Linking account to $project_name"
gcloud beta billing projects link $project_id --billing-account=$billing_account

echo -e "\n\n----------------------- enabling Kubernetes API (may take a while)\n\n"
gcloud services enable container.googleapis.com

echo -e "\n\n----------------------- creating cluster: $cluster_name \n\n"
gcloud container clusters create $cluster_name --zone us-central1-a --project "$project_name"
gcloud container clusters get-credentials $cluster_name --zone us-central1-a --project "$project_name"

echo -e "\n\n----------------------- Installing package manager\n\n"

echo -e "\n\n>>>>>> Installing Helm"
# installs helm with bash commands for easier command line integration
curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get | bash
# add a service account within a namespace to segregate tiller
kubectl --namespace kube-system create sa tiller
# create a cluster role binding for tiller
kubectl create clusterrolebinding tiller \
    --clusterrole cluster-admin \
    --serviceaccount=kube-system:tiller

echo -e "\n\n>>>>>> Initialize Helm in $cluster_name"
# initialized helm within the tiller service account
helm init --service-account tiller
# updates the repos for Helm repo integration
helm repo update

echo -e "\n\n>>>>>> Veryfing Helm in $cluster_name"
# verify that helm is installed in the cluster
kubectl get deploy,svc tiller-deploy -n kube-system

echo -e "\n\n----------------------- Installing infra in $cluster_name"

echo -e "\n\n>>>>>> Installing knockout base"
helm repo add knockout-infra https://raw.githubusercontent.com/fvalero86/knockout-cluster/master/package/
helm install --name knockout-cluster knockout-cluster

echo -e "\n\n>>>>>> Installing monitoring"
helm repo add coreos https://s3-eu-west-1.amazonaws.com/coreos-charts/stable/
helm install coreos/prometheus-operator --name prometheus-operator --namespace monitoring
helm install coreos/kube-prometheus --name kube-prometheus --set global.rbacEnable=true --namespace monitoring