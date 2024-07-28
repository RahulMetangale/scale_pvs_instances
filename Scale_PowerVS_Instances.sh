#!/bin/bash
#####################################################################################################################
# During scale up and down operation we may not want to scale up by 8 times or reduce by 8 times. 
# Hence this function uses the instance state captured before scale down.
# Scale down values automatically captured are 1/8 of CPU and RAM but they can be changed in configmap
# This information is stored in code engine's configmap
#####################################################################################################################
#Set Default values for variables
# If TEST_MODE is set to true then scale up will not actually perform scale up operation.
# It will just log, to be CPU and RAM
#TEST_MODE=${TEST_MODE:=false}
CODE_ENGINE_REGION=${CODE_ENGINE_REGION:="us-south"}
CODE_ENGINE_RESOURCE_GROUP_NAME=${CODE_ENGINE_RESOURCE_GROUP_NAME:="Default"}

#Use the values passed to function
PVS_CONFIGMAP_NAME=$1
PVS_CONFIGMAP_KEY_NAME=$2
TEST_MODE=$3

# Log in to IBM Cloud
ibmcloud login --apikey $IBM_CLOUD_API_KEY -a "https://cloud.ibm.com" -r "us-south"

# Target the appropriate workspace
ibmcloud pi ws tg $CRN

# Target resource group and region where code engine instance is present
ibmcloud target -g $CODE_ENGINE_RESOURCE_GROUP_NAME -r $CODE_ENGINE_REGION

# Select the code engine instance
ibmcloud ce project select -n $CODE_ENGINE_PROJECT_NAME

# Read the scale up configmap. This configmap stores instance id, scale up CPU and scale up RAM
pvs_instances_config=$(ibmcloud ce configmap get -n $PVS_CONFIGMAP_NAME --output=json | jq '.data.'$PVS_CONFIGMAP_KEY_NAME' | fromjson')

# Update instance
update_instance() {
    INSTANCE_ID=$1
    INSTANCE_NAME=$2
    NEW_PROCESSORS=$3
    NEW_MEMORY=$4
    TEST_MODE=$5
    if ! $TEST_MODE; then
        echo "Instance update started."
        echo "Updating instance with Instance_ID $INSTANCE_ID, Instance Name $INSTANCE_NAME to $NEW_PROCESSORS cores and $NEW_MEMORY GB memory"
        ibmcloud pi instance update $INSTANCE_ID --processors $NEW_PROCESSORS --memory $NEW_MEMORY
    else
        echo "Test Mode is ON."
        echo "TEST MODE: Instance with Instance_ID $INSTANCE_ID, Instance Name $INSTANCE_NAME will be updated to $NEW_PROCESSORS cores and $NEW_MEMORY GB memory"
    fi  
}

# Loop thorugh instances and update them
for obj in $(echo "$pvs_instances_config" | jq -c '.[]'); do
    instance_id=$(echo "$obj" | jq -r '.instance_id')
    instance_name=$(echo "$obj" | jq -r '.instance_name')
    current_cpu=$(echo "$obj" | jq -r '.cpu')
    current_ram=$(echo "$obj" | jq -r '.ram')
    update_instance $instance_id $instance_name $current_cpu $current_ram $TEST_MODE
done