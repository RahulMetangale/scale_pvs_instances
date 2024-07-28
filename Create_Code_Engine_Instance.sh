#!/bin/bash
ibmcloud target -g $CODE_ENGINE_RESOURCE_GROUP_NAME -r $CODE_ENGINE_REGION
ibmcloud ce project create --name $CODE_ENGINE_PROJECT_NAME