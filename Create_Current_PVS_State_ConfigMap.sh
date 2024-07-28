#!/bin/bash
##########################################################################################################################
# This script captures the current state (InstanceID, Current CPU and Current RAM) of all instances within workspace.
# This information is stored in code engine's configmap
# This configmap is read during scale up operation and instance will be scaled according to values stored in configmap.
##########################################################################################################################
PVS_SCALE_UP_CONFIGMAP_NAME="pvs-scale-up-config"

# Log in to IBM Cloud
ibmcloud login --apikey $IBM_CLOUD_API_KEY -a "https://cloud.ibm.com" -r "us-south"

# Target the appropriate workspace
ibmcloud pi ws tg $CRN

# List all PowerVS instances and capture their IDs
pvs_instances=$(ibmcloud pi instance ls --json)

# Find the number of LPARs in workspace
number_of_pvs_instances=$(echo "$pvs_instances" | jq '.pvmInstances | length')

instances_details_json=$(echo "$pvs_instances" | jq '[range('$number_of_pvs_instances') as $i | { instance_id: .pvmInstances[$i].id, instance_name: .pvmInstances[$i].name, cpu: .pvmInstances[$i].cores.assigned, ram: .pvmInstances[$i].memory.assigned}]')

ibmcloud target -g $CODE_ENGINE_RESOURCE_GROUP_NAME -r $CODE_ENGINE_REGION

ibmcloud ce project select -n $CODE_ENGINE_PROJECT_NAME

configmap=$(ibmcloud ce configmap get  --name $PVS_SCALE_UP_CONFIGMAP_NAME --output=json)

# Create configmap if it does not exists and update if present.
if [ -z "$configmap" ]; then
    echo "Creating configmap $PVS_SCALE_UP_CONFIGMAP_NAME"
    ibmcloud ce configmap create --name $PVS_SCALE_UP_CONFIGMAP_NAME --from-literal "pvs_scale_up_config=$instances_details_json"
else
    echo "Updating existing configmap $PVS_SCALE_UP_CONFIGMAP_NAME" 
    ibmcloud ce configmap update --name $PVS_SCALE_UP_CONFIGMAP_NAME --from-literal "pvs_scale_up_config=$instances_details_json" 
fi

