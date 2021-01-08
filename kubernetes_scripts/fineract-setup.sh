#!/bin/bash -ex

AWS_REGION="us-east-2"
EKS_CLUSTER="eks-fineract-cluster02"

# NOTE!!!! The IAM user used to create the EKS cluster will be the only one able
# to initially connect to it. This user will need aws cli console access and
# ultimately a working kubectl setup to setup Fineract.

# install aws cli and configure with user you used to create EKS cluster
brew install awscli

if [[ ! -f ~/.aws/credentials && ! -f ~/.aws/config ]]; then
    aws configure
fi

# install eksctl
brew tap weaveworks/tap
brew install weaveworks/tap/eksctl
brew upgrade eksctl && brew link --overwrite eksctl

# Must be 0.35.0+ ?
eksctl version

# EKS Setup
# https://docs.aws.amazon.com/eks/latest/userguide/create-cluster.html
eksctl create cluster \
 --name "${EKS_CLUSTER}" \
 --version 1.18 \
 --with-oidc \
 --without-nodegroup

# Will take 10-15 minutes to create the EKS cluster

# add node group to cluster
eksctl create nodegroup \
  --cluster "${EKS_CLUSTER}" \
  --region "${AWS_REGION}" \
  --name eks-fineract-cluseter01-nodes \
  --node-type t3.large \
  --nodes-min 3 \
  --nodes-max 6 \
  --node-ami-family AmazonLinux2 \
  --managed

# Setup kubectl to connect to our AWS EKS cluster
# https://docs.aws.amazon.com/eks/latest/userguide/create-kubeconfig.html

# Had to turn of zscalar to fix this SSL error:
# SSL validation failed for https://eks.us-east-2.amazonaws.com/clusters/eks-fineract-cluster [SSL: CERTIFICATE_VERIFY_FAILED] certificate verify failed: unable to get local issuer certificate (_ssl.c:1123)

# Had to delete ~/.kube/config to fix this error:
# Tried to insert into users,which is a <class 'NoneType'> not a <class 'list'>
rm ~/.kube/config

# generate ~/.kube/config
aws eks --region "${AWS_REGION}" update-kubeconfig --name "${EKS_CLUSTER}"

# This should work without error is kubectl is setup
kubectl get svc

# Output:
#> NAME         TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
#> kubernetes   ClusterIP   10.1.0.1     <none>        443/TCP   8m6s

# Deploy Fineract-CN
./fineract-start.sh
