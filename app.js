const express = require('express');
const {exec} = require("child_process");


const app = express();

const PORT = process.env.PORT || 3000;

app.listen(PORT,function(err){
    if(err){
        console.log("Error while starting server.");
    }
    else{
        if(!process.env.IBM_CLOUD_API_KEY){
            console.log("Required environment variable IBM_CLOUD_API_KEY is not set.")
            process.exit(1);
        }
        else if(!process.env.CRN){
            console.log("Required environment variable PowerVS Workspace CRN is not set.")
            process.exit(1);
        }
        else if(!process.env.CODE_ENGINE_PROJECT_NAME){
            console.log("Required environment variable CODE_ENGINE_PROJECT_NAME is not set.")
            //process.exit(1);
        }
        else{
            console.log("Server started on port "+PORT);
        }
    }
})

app.get('/createConfigMaps', function (req, res) {
    res.send('Capturing Current PowerVS Instances State');
    console.log("Capturing the current PowerVS instance state")
    exec('./Create_Current_PVS_State_ConfigMap.sh', (error, stdout, stderr) => {
            if (error !== null) {
                console.log(`exec error: ${error}`);
            }
            console.log(`stdout: ${stdout}`);
            console.error(`stderr: ${stderr}`);
        });
    console.log("Creating scale down PowerVS instance configuration")
    exec('./Create_Scale_Down_PVS_State_ConfigMap.sh', (error, stdout, stderr) => {
            if (error !== null) {
                console.log(`exec error: ${error}`);
            }
            console.log(`stdout: ${stdout}`);
            console.error(`stderr: ${stderr}`);
        });
  })

app.get('/runScaleUPTest', function (req, res) {
    res.send('Running Scale up Test');
    exec('./Scale_PowerVS_Instances.sh "pvs-scale-up-config" "pvs_scale_up_config" true', (error, stdout, stderr) => {
        if (error) {
            console.error(`exec error: ${error}`);
            return;
        }
        console.log(`stdout: ${stdout}`);
        console.error(`stderr: ${stderr}`);
    });
})

app.get('/runScaleUP', function (req, res) {
    res.send('Scaling up');
    exec('./Scale_PowerVS_Instances.sh "pvs-scale-up-config" "pvs_scale_up_config" false', (error, stdout, stderr) => {
        if (error) {
            console.error(`exec error: ${error}`);
            return;
        }
        console.log(`stdout: ${stdout}`);
        console.error(`stderr: ${stderr}`);
    });
})

app.get('/runScaleDownTest', function (req, res) {
    res.send('Running Scale Down Test');
    exec('./Scale_PowerVS_Instances.sh "pvs-scale-down-config" "pvs_scale_down_config" true', (error, stdout, stderr) => {
        if (error) {
            console.error(`exec error: ${error}`);
            return;
        }
        console.log(`stdout: ${stdout}`);
        console.error(`stderr: ${stderr}`);
    });
})

app.get('/runScaleDown', function (req, res) {
    res.send('Scaling Down');
    exec('./Scale_PowerVS_Instances.sh "pvs-scale-down-config" "pvs_scale_down_config" false', (error, stdout, stderr) => {
        if (error) {
            console.error(`exec error: ${error}`);
            return;
        }
        console.log(`stdout: ${stdout}`);
        console.error(`stderr: ${stderr}`);
    });
})