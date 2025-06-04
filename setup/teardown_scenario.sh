#! /usr/bin/env bash -ex

read -p "Enter Your Resource Group Name: " ResourceGroupName
read -p "Enter a short prefix for your Azure Resources (lowercase with no spaces): " ResourcePrefix

export TF_VAR_resource_group_name=$ResourceGroupName
export TF_VAR_prefix=$ResourcePrefix
export ARM_SUBSCRIPTION_ID=$(az account show --query id --output tsv)

terraform destroy
