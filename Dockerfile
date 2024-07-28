# Use an official Node.js runtime as the base image
FROM node:latest

# Install IBM Cloud CLI prerequisites
RUN apt-get update && \
    apt-get install -y curl && \
    apt-get install -y apt-transport-https && \
    apt-get install -y lsb-release && \
    apt-get install -y gnupg && \
    apt-get install -y wget && \
    apt-get install -y jq && \
    apt-get install -y bc && \
    apt-get clean

# Install IBM Cloud CLI
RUN curl -fsSL https://clis.cloud.ibm.com/install/linux | sh
RUN ibmcloud plugin install -a
# Install any additional dependencies for your Node.js application
# For example:
# RUN apt-get install -y <package-name>

# Set the working directory in the container
WORKDIR /app

# Copy the Node.js application files into the container
COPY app.js package.json package-lock.json Scale_PowerVS_Instances.sh Create_Current_PVS_State_ConfigMap.sh Create_Scale_Down_PVS_State_ConfigMap.sh /app/

# Install Node.js dependencies if package.json is present
RUN chmod +x Scale_PowerVS_Instances.sh Create_Current_PVS_State_ConfigMap.sh Create_Scale_Down_PVS_State_ConfigMap.sh
RUN npm ci

# Expose the port your app runs on (if applicable)
EXPOSE 3000

# Define the command to run your Node.js application
CMD ["node", "app.js"]
