# Node.js Sample Application for nconf-appconfig npm
> **DISCLAIMER**: This is a guideline sample application and is used for demonstrative and illustrative purposes only. This is not a production ready code.

## Contents
  - [Prerequisite](#prerequisite)
  - [Create an instance of App Configuration service](#create-an-instance-of-app-configuration-service)
  - [Setup the app](#setup-the-app)
    - [Prerequisites](#prerequisites)
    - [Next steps](#next-steps)
  - [Run the app locally](#run-the-app-locally)
  - [Test the app with feature toggle and segmentation](#test-the-app-with-feature-toggle-and-segmentation)
- [License](#license)

## Prerequisite

- You need an [IBM Cloud](http://cloud.ibm.com/) account. If you don't have an account, create one [here](https://cloud.ibm.com/registration/).

## Create an instance of App Configuration service
- Log in to your IBM Cloud account.
- In the [IBM Cloud catalog](https://cloud.ibm.com/catalog#services), search **App Configuration** and click [App Configuration](https://cloud.ibm.com/catalog/services/app-configuration). The service provisioning page opens.
- **Select a region** - Currently, Dallas (us-south), London (eu-gb) and Sydney (au-syd) regions are supported.
- Select a pricing plan, resource group and configure your resource with a service name, or use the preset name.
- Click **Create**. A new service instance is created and the App Configuration dashboard is displayed.

## Setup the app
## Prerequisites
- Node.js installed on your machine.
- jq - command-line JSON processor. Install it from [here](https://stedolan.github.io/jq/download/).

## Setup the App Configuration service instance
- Download the source code
    ```
    $ git clone https://github.com/saikumar1607/shopping-website.git
    $ cd shopping-website
    ```
- Install `jq` - command-line JSON processor.
    - You can install it from [here](https://stedolan.github.io/jq/download/)
- 
- Go to dashboard of your App Configuration instance in IBM Cloud UI.
- Navigate to Service Credentials section and generate a new set of credentials. Note down the `region`, `guid` and `apikey`. These credentials are required in the next steps.
- From your terminal, inside the source code execute the `demo.sh` script by running below command
    ```bash
    $ ./demo.sh
    ```
    > If you face any permission errors during the script execution, provide appropriate permission to the file by running - `sudo chmod +x ./demo.sh`. And then execute the script.  
- Provide all the inputs during script execution. 
- Script execution takes time. Script is executed successfully only when you see the log `---Demo script complete---` at the end in your terminal.
- This script will create the collections and properties using the default dev environment in the instance which are required for this sample app.

## Run the sample
- Prerequisites
    - Node.js installed on your machine.
- Edit the configuration values in file [`server.js`](server.js)
    - Provide all the configuration values in [.env](.env) file
- Installing Dependencies
    - Run `npm install` from the root folder to install the app’s dependencies.
- Run `npm start` to start the app
- Access the running app in a browser at http://localhost:3000

See [here](https://cloud.ibm.com/docs/app-configuration) for detailed docs on App Configuration service.
