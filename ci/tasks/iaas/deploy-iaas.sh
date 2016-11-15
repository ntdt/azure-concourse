#!/bin/bash
set -e
exit 1
# Get Opsman VHD from previous task
pcf_opsman_image_uri=$(cat opsman-metadata/uri)

# Get Public IPs
function fn_get_ip {
     azure_cmd="azure network public-ip list -g c0-opsman-validation --json | jq '.[] | select( .name | contains(\"${1}\")) | .ipAddress' | tr -d '\"'"
     pub_ip=$(eval $azure_cmd)
     echo $pub_ip
}

pub_ip_pcf=$(fn_get_ip "web-lb")
pub_ip_tcp_lb=$(fn_get_ip "tcp-lb")
pub_ip_ssh_and_doppler=$(fn_get_ip "web-lb")
pub_ip_jumpbox=$(fn_get_ip "jumpbox")
pub_ip_opsman=$(fn_get_ip "opsman")

echo "=============================================================================================="
echo "Executing Terraform ...."
echo "=============================================================================================="

export PATH=/opt/terraform/terraform:$PATH

/opt/terraform/terraform plan \
  -var "subscription_id=${azure_subscription_id}" \
  -var "client_id=${azure_service_principal_id}" \
  -var "client_secret=${azure_service_principal_password}" \
  -var "tenant_id=${azure_tenant_id}" \
  -var "location=${azure_region}" \
  -var "env_name=${azure_terraform_prefix}" \
  -var "dns_suffix=${pcf_ert_domain}" \
  -var "pub_ip_opsman=${pub_ip_opsman}" \
  -var "pub_ip_pcf=${pub_ip_pcf}" \
  azure-concourse/terraform/$azure_pcf_terraform_template
