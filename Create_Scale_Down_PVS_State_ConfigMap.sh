#!/bin/bash
##########################################################################################################################
# This script calculates the scale down state (InstanceID, Current CPU and Current RAM) of all instances within workspace.
# Scale down CPU and RAM values are calculated
# Scale down CPU will be rounded up to nearest quarter that is multiple of 0.25
# This information is stored in code engine's configmap
# This configmap is read during scale up operation and instance will be scaled according to values stored in configmap.
##########################################################################################################################

PVS_SCALE_DONW_CONFIGMAP_NAME="pvs-scale-down-config"

# Log in to IBM Cloud
ibmcloud login --apikey $IBM_CLOUD_API_KEY -a "https://cloud.ibm.com" -r "us-south"

# Target the appropriate workspace
ibmcloud pi ws tg $CRN

# List all PowerVS instances and capture their IDs
pvs_instances=$(ibmcloud pi instance ls --json)

# Find the number of LPARs in workspace
number_of_pvs_instances=$(echo "$pvs_instances" | jq '.pvmInstances | length')

instances_details_json=$(echo "$pvs_instances" | jq '[range('$number_of_pvs_instances') as $i | { instance_id: .pvmInstances[$i].id, instance_name: .pvmInstances[$i].name, cpu: .pvmInstances[$i].cores.assigned, ram: .pvmInstances[$i].memory.assigned}]')

roundup_to_nearest_quarter() {
    value=$1
    scaled_down_value=$(echo "scale=10; $value / 8" | bc)
    divided=$(echo "scale=10; $scaled_down_value / 0.25" | bc)
    rounded_up=$(echo "scale=10; $divided + 0.9999999999" | bc)
    integer_part=$(echo "$rounded_up / 1" | bc)
    result=$(echo "scale=2; $integer_part * 0.25" | bc)
    echo $result
}

get_updated_cpu() {
    value=$1
    scaled_down_cpu=$(echo "scale=10; $value / 8" | bc)
    # We want to round up instead of down. 
    # This is beacuse if we round down then during scale up operation scale up CPU value may become higher than 8 times
    UPDATED_CPU=$(roundup_to_nearest_quarter $scaled_down_cpu)
    echo $UPDATED_CPU
}

get_updated_ram() {
    value=$1
    UPDATED_RAM=$(echo "scale=0; $value / 8" | bc)
    if [ $UPDATED_RAM -lt 2 ]; then
        UPDATED_RAM=2
    fi
    echo $UPDATED_RAM
}

scale_down_json='[]'

for obj in $(echo "$instances_details_json" | jq -c '.[]'); do
    id=$(echo "$obj" | jq -r '.instance_id')
    instance_name=$(echo "$obj" | jq -r '.instance_name')
    current_cpu=$(echo "$obj" | jq -r '.cpu')
    current_ram=$(echo "$obj" | jq -r '.ram')
    UPDATED_CPU=$(roundup_to_nearest_quarter $current_cpu)
    UPDATED_RAM=$(get_updated_ram $current_ram)
    nested_json=$(jq -n --arg instance_id "$id" --arg instance_name "$instance_name" --arg cpu $UPDATED_CPU --arg ram $UPDATED_RAM '{instance_id: $instance_id, instance_name: $instance_name, cpu: $cpu, ram: $ram}')
    scale_down_json=$(jq --argjson nested "$nested_json" '. += [$nested]' <<< "$scale_down_json")
done

echo $scale_down_json | jq .

ibmcloud target -g $CODE_ENGINE_RESOURCE_GROUP_NAME -r $CODE_ENGINE_REGION

ibmcloud ce project select -n $CODE_ENGINE_PROJECT_NAME

configmap=$(ibmcloud ce configmap get  --name $PVS_SCALE_DONW_CONFIGMAP_NAME --output=json)

# Create configmap if it does not exists and update if present.
if [ -z "$configmap" ]; then
    echo "Creating configmap $PVS_SCALE_DONW_CONFIGMAP_NAME"
    ibmcloud ce configmap create --name $PVS_SCALE_DONW_CONFIGMAP_NAME --from-literal "pvs_scale_down_config=$scale_down_json"
else
    echo "Updating existing configmap $PVS_SCALE_DONW_CONFIGMAP_NAME" 
    ibmcloud ce configmap update --name $PVS_SCALE_DONW_CONFIGMAP_NAME --from-literal "pvs_scale_down_config=$scale_down_json" 
fi

