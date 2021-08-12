# Notejam on AWS (EKS + RDS MySQL) with Terraform

Assuming you already have Amazon AWS account we will need additional binaries for AWS CLI, terraform, kubectl. 

**Article is structured in 5 parts**

* Initial tooling setup aws cli , kubectl and terraform
* Creating terraform IAM account with access keys and access policy
* Creating back-end storage for tfstate file in AWS S3 
* Creating Kubernetes cluster on AWS EKS and RDS on Mysql
* Working with kubernetes "kubectl" in EKS

## Initial tooling setup aws-cli, kubectl, terraform and aws-iam-authenticator

Assuming you already have AWS account and [AWS CLI installed](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) and [AWS CLI configured](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html) for your user account we will need additional binaries for, terraform and kubectl.

To do so, please follow the official instructions:
* [Install Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)
* [Install Kubectl](https://kubernetes.io/docs/tasks/tools/)

### Authenticate to AWS

In below example we will be using EU West (Ireland) "eu-east-1"

```sh
aws configure
```

## Creating terraform IAM account with access keys and access policy

1st step is to setup terraform admin account in AWS IAM

### Create IAM terraform User

```sh
aws iam create-user --user-name terraform
```

### Add to newly created terraform user IAM admin policy

> NOTE: For production or event proper testing account you may need tighten up and restrict access for terraform IAM user


```sh
aws iam attach-user-policy --user-name terraform --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
```

### Create access keys for the user

> NOTE: This Access Key and Secret Access Key will be used by terraform to manage infrastructure deployment

```sh
aws iam create-access-key --user-name terraform
```

### update terraform.tfvars file with access and security keys for newly created terraform IAM account

## Creating back-end storage for tfstate file in AWS S3

Once we have terraform IAM account created we can proceed to next step creating dedicated bucket to keep terraform state files

### Create terraform state bucket

> NOTE: Change name of the bucker, name should be unique across all AWS S3 buckets

```sh
aws s3 mb s3://nc-demo-terraform-state-bucket --region eu-east-1
```

### Enable versioning on the newly created bucket

```sh
aws s3api put-bucket-versioning --bucket nc-demo-terraform-state-bucket --versioning-configuration Status=Enabled
```
## Creating Kubernetes cluster on AWS EKS and RDS on MySQL

Now we can move into creating new infrastructure, eks and rds with terraform

Terraform modules will create

* VPC
* Subnets
* Routes
* IAM Roles for master and nodes
* Security Groups "Firewall" to allow master and nodes to communicate
* EKS cluster
* Autoscaling Group will create nodes to be added to the cluster
* Security group for RDS
* RDS with MySQL

1. Initialize and pull terraform cloud specific dependencies

    ```sh
    terraform init
    ```

1. View terraform plan

    ```sh
    terraform plan
    ```

1. Apply terraform plan

    > NOTE: building complete infrastructure may take more than 10 minutes.

    ```sh
    terraform apply
    ```

1. Verify instance creation

    ```sh
    aws ec2 describe-instances --output table
    ```

1. Export kubectl config file

    ```sh
    aws eks --region $(terraform output -raw region) update-kubeconfig --name $(terraform output -raw cluster_name)
    ```

1. Verify kubectl connectivity and nodes creation

    ```sh
    kubectl get nodes
    
    kubectl get pod
    ```

### Connect to the Argo CD UI
To print argocd admin account password:
```sh
kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep eks-admin | awk '{print $1}')
```
Proxy ArgoCD Service to local port 8080:
```sh
kubectl port-forward svc/argo-cd-argocd-server -n argocd 8080:443
```
Open the link with a web browser to access the ArgoCD UI: http://localhost:8080 and review the application deployment.

Please note, at this point, there is no docker image present in the ECR registry => application can't be started.

1. Image has to be republished to ECR using Github Actions pipeline: https://github.com/nc-demo/notejam
1. ArgoCD should sync cluster state (automatically, or via ArgoCD UI manual action).

Afterwards the notejam application should be accesible on the hostname discoverable via:

```shell
kubecl get svc/notejam
```
where the `EXTERNAL-IP` column contains the hostname to be opened in the web browser (port is 80).

## Rolling back all changes

### Destroy all terraform created infrastructure

```sh
terraform destroy -auto-approve
```

Please note, sometimes destruction gets stuck on destroying VPC and can't be performed by Terraform (despite retries). In such a case:

* Login to [AWS Console](https://console.aws.amazon.com/) and
* manually remove nc-demo-created resources: ELB and VPC.


### Removing S3 bucket, IAM roles and terraform account

```sh
aws s3 rm s3://nc-demo-terraform-state-bucket --recursive

aws s3api put-bucket-versioning --bucket nc-demo-terraform-state-bucket --versioning-configuration Status=Suspended

aws s3api delete-objects --bucket nc-demo-terraform-state-bucket --delete \
"$(aws s3api list-object-versions --bucket nc-demo-terraform-state-bucket | \
jq '{Objects: [.Versions[] | {Key:.Key, VersionId : .VersionId}], Quiet: false}')"

aws s3 rb s3://nc-demo-terraform-state-bucket --force

aws iam detach-user-policy --user-name terraform --policy-arn arn:aws:iam::aws:policy/AdministratorAccess

aws iam list-access-keys --user-name terraform  --query 'AccessKeyMetadata[*].{ID:AccessKeyId}' --output text

aws iam delete-access-key --user-name terraform --access-key-id OUT_KEY

aws iam delete-user --user-name terraform
```