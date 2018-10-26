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

echo -e "----------------------- login into ACCOUNT with: $account_name \n\n"
gcloud auth login
gcloud config set account $account_name

echo -e "----------------------- creating project: $project_id \n\n"
gcloud projects create $project_id --name="$project_name"
gcloud config set project $project_id

echo -e "----------------------- Linking account to $project_name"
gcloud alpha billing accounts projects link $project_name--billing-account

echo -e "----------------------- enabling Kubernetes API (may take a while)\n\n"
gcloud services enable container.googleapis.com

echo -e "----------------------- creating cluster: $cluster_name \n\n"
gcloud container clusters create $cluster_name --zone us-central1-a --project "$project_name"
gcloud container clusters get-credentials $cluster_name --zone us-central1-a --project "$project_name"

echo -e "----------------------- Installing package manager\n\n"
echo ">>>>>> Installing Helm"
# installs helm with bash commands for easier command line integration
curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get | bash
# add a service account within a namespace to segregate tiller
kubectl --namespace kube-system create sa tiller
# create a cluster role binding for tiller
kubectl create clusterrolebinding tiller \
    --clusterrole cluster-admin \
    --serviceaccount=kube-system:tiller

echo ">>>>>> Initialize Helm in $cluster_name"
# initialized helm within the tiller service account
helm init --service-account tiller
# updates the repos for Helm repo integration
helm repo update

echo ">>>>>> Veryfing Helm in $cluster_name"
# verify that helm is installed in the cluster
kubectl get deploy,svc tiller-deploy -n kube-system

echo -e "----------------------- Installing infra in $cluster_name\n\n"

echo ">>>>>> Installing knockout base"
helm repo add knockout-infra https://github.com/fvalero86/knockout-cluster/knockout-infra/
helm install --name knockout-cluster knockout-cluster

echo ">>>>>> Installing monitoring"
helm repo add coreos https://s3-eu-west-1.amazonaws.com/coreos-charts/stable/
helm install coreos/prometheus-operator --name prometheus-operator --namespace monitoring
helm install coreos/kube-prometheus --name kube-prometheus --set global.rbacEnable=true --namespace monitoring