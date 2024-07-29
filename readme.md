# Scaling Power Virtual Server Instances

## Introduction
This project contains scripts to scale up and down Power Virtual server instances. Project is capable of deploying IBM Cloud Code Engine instance which can help scheduling scaling tasks. 

Project is written using following programming languages:
1. Bash Scripts: Reason for using bash scripting for main logic is, scaling tasks are done by system admins. And system admins would know bash scripting than any other languages like Nodejs etc. I know i am generalizing but this was my thought process. 
2. NodeJS: Used mainly for creating API endpoint. These endpoint are triggered on schedule and they call Bash Script internally.
3. Docker: Used to package required dependencies along with code. This allows easier deployment. And this deployment is supported by IBM Cloud Code engine as well. 
4. IBM Cloud CLI: For interacting with IBM Cloud resources. Bash script in this project uses IBM cloud cli heavily. 

Why IBM Cloud Code Engine:  
While its possible to schedule the bash script using any scheduler, i have use Code engine for following reasons:
1. Available on IBM Cloud.
2. Supports ConfigMap. I have used ConfigMap to store scale up and down configuration. Since this configuration can be edited from IBM cloud portal its easier to control scaling values. 

# Steps to Deploy
## Create Service ID
A service ID identifies a service or application similar to how a user ID identifies a user. You can assign specific access policies to the service ID that restrict permissions for using specific services, or even combine permissions for accessing different services. Since service IDs are not tied to a specific user, if a user leaves an organization and is deleted from the account, the service ID remains. This way, your application or service stays up and running.

Please follow steps given [here](https://cloud.ibm.com/docs/account?topic=account-serviceids&interface=ui#create_serviceid) to create service ID.

You should give minimum access to service IDs as possible. I have given following access:
1. Power Virtual Server: Service Access - Manager
2. Resource Group: Viewer access
3. Code Engine: Service Access - Reader, Writer, Compute Environment Administrator. Platform Access - Administrator and Service Configuration Reader

Create API Key for this service ID. This API key will be used as IBM_CLOUD_API_KEY.

## Create Code Engine Instance
From IBM Cloud Portal Create a 

To create code engine instance run following commands:
`export IBM_CLOUD_API_KEY="API key generated in above step"`

`export CODE_ENGINE_RESOURCE_GROUP_NAME="Default"`

`export CODE_ENGINE_REGION="us-south"`
`ibmcloud target -g $CODE_ENGINE_RESOURCE_GROUP_NAME -r $CODE_ENGINE_REGION`

`ibmcloud ce project create --name $CODE_ENGINE_PROJECT_NAME`