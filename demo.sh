#!/bin/bash
set -e


#---------------------------------Setup base url values-------------------------
region[1]="https://us-south.apprapp.cloud.ibm.com/apprapp/feature/v1/instances"
region[2]="https://eu-gb.apprapp.cloud.ibm.com/apprapp/feature/v1/instances"
region[3]="https://au-syd.apprapp.cloud.ibm.com/apprapp/feature/v1/instances"
region[4]="https://us-east.apprapp.cloud.ibm.com/apprapp/feature/v1/instances"
tokenURL="https://iam.cloud.ibm.com/identity/token"
urlSeparator="/"
environmentName=""
environmentId=""
environments="environments"
collections="collections"
properties="properties"
segments="segments"

generateEnvId(){
	environmentId="$(tr [A-Z] [a-z] <<< "$1")"
}
#---------------------------------Get inputs for the script to run------------------------
printf "\nEnter the region where your App configuration service is created\n1. us-south (Dallas)\n2. eu-gb (London)\n3. au-syd (Sydney)\n4. us-east (Washington DC)\n\n"

read -p "Enter region number> "  regionIn
printf "\nChoose action\n"
printf "1. Setup - Create pre-defined properties flags, which are organized into collections and targeted to segments in your instance\n"
printf "2. Cleanup - Delete all the existing entires of collection, properties from your instance\n\n"
read -p "Enter action number> "  actionIn
if [[ $actionIn == 1 ]]
then
	printf "\nPerform setup using default environment?\n1. Yes\n2. No. Create a new environment\n\n"
	read -p "Enter action number(1 or 2)> " envActionIn
	if [[ $envActionIn == 1 ]]
	then
		environmentName="Dev"
		environmentId="dev"
	elif [[ $envActionIn == 2 ]]
	then
		printf "\n"
		read -r -p "Enter an environment name> " environmentName
		generateEnvId $environmentName
	else
		printf "\nProvide a valid input number"
		exit 1
	fi
fi
printf "\n"
read -p "Enter apikey: (Obtained from Service credentials tab of your instance): "  apikey
printf "\n"
read -p "Enter guid: (Obtained from Service credentials tab of your instance): "  guid

#---------------------------------Setup input params-------------------------
baseURL=${region[${regionIn}]}
baseURL="$baseURL$urlSeparator$guid"

#---------------------------------Setup input params-------------------------
environmentURL="$baseURL$urlSeparator$environments"
collectionURL="$baseURL$urlSeparator$collections"
propertyURL="$baseURL$urlSeparator$environments$urlSeparator$environmentId$urlSeparator$properties"
tokenResponse=$(curl -s -X POST $tokenURL -H "Content-Type: application/x-www-form-urlencoded" -d 'grant_type=urn:ibm:params:oauth:grant-type:apikey&apikey='"$apikey"'')
access_token=($((echo $tokenResponse | jq -r '.access_token') | tr -d \'\"))

cleanup()
{
	#---------------------------------collections Cleanup-------------------------
	cleanupCollectionURL="$collectionURL"
	curl -sb -H "Accept: application/json" -H "Authorization: Bearer $access_token" $cleanupCollectionURL > auto.json
	if [ -s auto.json ] && grep -q "collection" auto.json
	then
		collectionIds=($((<auto.json jq -r '.collections' | jq . | jq -r '.[].collection_id | @sh') | tr -d \'\"))

		for i in "${collectionIds[@]}"
		do
			printf "%b\n deleting collection with id $i\n"
			collectionDelURL=$collectionURL$urlSeparator$i
			collectionDelResponse=$(curl -s --write-out 'HTTPSTATUS:%{http_code}' -H "Accept: application/json" -H "Authorization: Bearer $access_token" -X DELETE  $collectionDelURL)
			HTTP_STATUS=$(echo $collectionDelResponse | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
			if [ $HTTP_STATUS != 204 ]
			then
				printf "%b\n \e[31m Failure : Collection delete failed with error code $HTTP_STATUS and body $HTTP_BODY \e[39m"
			fi
		done
	else 
		exit 1
	fi

	#---------------------------------environments Cleanup-------------------------
	cleanupEnvironmentURL="$environmentURL"
	curl -sb -H "Accept: application/json" -H "Authorization: Bearer $access_token" $cleanupEnvironmentURL > auto.json
	if [ -s auto.json ] && grep -q "environment" auto.json
	then
		environmentIds=($((<auto.json jq -r '.environments' | jq . | jq -r '.[].environment_id | @sh') | tr -d \'\"))

		for ((i=0; i<${#environmentIds[@]}-1; i++))
		do
			printf "%b\n deleting environment with id ${environmentIds[i]}\n"
			environmentDelURL=$environmentURL$urlSeparator${environmentIds[i]}
			environmentDelResponse=$(curl -s --write-out 'HTTPSTATUS:%{http_code}' -H "Accept: application/json" -H "Authorization: Bearer $access_token" -X DELETE  $environmentDelURL)
			HTTP_STATUS=$(echo $environmentDelResponse | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
			if [ $HTTP_STATUS != 204 ]
			then
				printf "%b\n \e[31m Failure : Environment delete failed with error code $HTTP_STATUS and body $HTTP_BODY \e[39m"
			fi
		done
		environmentId=${environmentIds[i]}
	else
		exit 1
	fi

	#---------------------------------Property Cleanup-------------------------
	cleanupPropertyURL="$baseURL$urlSeparator$environments$urlSeparator$environmentId$urlSeparator$properties"
	curl -sb -H "Accept: application/json" -H "Authorization: Bearer $access_token" $cleanupPropertyURL > auto.json
	if [ -s auto.json ] && grep -q "properties" auto.json
	then
		propertyIds=($((<auto.json jq -r '.properties' | jq . | jq -r '.[].property_id | @sh') | tr -d \'\"))

		for i in "${propertyIds[@]}"
		do
			printf "%b\n deleting property with id $i\n"
			propertyDelURL=$cleanupPropertyURL$urlSeparator$i
			propertyDelResponse=$(curl -s --write-out 'HTTPSTATUS:%{http_code}' -H "Accept: application/json" -H "Authorization: Bearer $access_token" -X DELETE  $propertyDelURL)
			HTTP_STATUS=$(echo $propertyDelResponse | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
			if [ $HTTP_STATUS != 204 ]
			then
				printf "%b\n \e[31m Failure : Property delete failed with error code $HTTP_STATUS and body $HTTP_BODY \e[39m"
			fi
		done
	else 
		exit 1
	fi

	printf "%b\n\n \e[32mSuccess : Cleanup completed successfully. Re-run the setup. \e[39m \n"
}

set -e

addCollection() 
{
	collectionStatus=$(curl -s --write-out 'HTTPSTATUS:%{http_code}'  -X POST $collectionURL -H "Authorization: Bearer $access_token" -H "Content-Type: application/json" --data '{"name" : "nconf appconfig sample","collection_id": "nconf-appconfig-sample","description": "Sample for nconf-appconfig","tags": "sample, configload"}' )
	HTTP_BODY=$(echo $collectionStatus | sed -e 's/HTTPSTATUS\:.*//g' | jq .)
	HTTP_STATUS=$(echo $collectionStatus | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
	printf "%b\nHTTP_STATUS is $HTTP_STATUS"
	if [ $HTTP_STATUS != 201 ]
	then
		printf "%b\n \e[31m Failure : Collection creation failed with error code $HTTP_STATUS and body $HTTP_BODY \e[39m"
		cleanup
	else 
		collectionId=$(echo $HTTP_BODY | jq -rc '.collection_id')
		printf "%b\nSuccess:  Collection created with id $collectionId\n"
	fi
}

addProperty()
{
	propertyUpdateURL=$propertyURL
	propertyStatus=$(curl -s --write-out 'HTTPSTATUS:%{http_code}'  -X POST $propertyUpdateURL -H "Authorization: Bearer $access_token" -H "Content-Type: application/json" --data '{"name": "Predict Age Host","property_id": "predict-age-host","description": "Server hostname to predict age","type": "STRING", "format": "TEXT", "value": "api.agify.io","collections": [{"collection_id": "nconf-appconfig-sample"}]}' )
	HTTP_BODY=$(echo $propertyStatus | sed -e 's/HTTPSTATUS\:.*//g' | jq .)
	HTTP_STATUS=$(echo $propertyStatus | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
	if [ $HTTP_STATUS != 201 ]
	then
		printf "%b\n \e[31m Failure : Property update failed with error code $HTTP_STATUS and body $HTTP_BODY \e[39m"
		cleanup
	else 
		propertyId=$(echo $HTTP_BODY | jq -rc '.property_id')
		printf "%bSuccess:  Property updated with id $propertyId\n"
	fi

	propertyUpdateURL=$propertyURL
	propertyStatus=$(curl -s --write-out 'HTTPSTATUS:%{http_code}'  -X POST $propertyUpdateURL -H "Authorization: Bearer $access_token" -H "Content-Type: application/json" --data '{"name": "Predict Age Protocol","property_id": "predict-age-protocol","description": "Server protocol to predict age","type": "STRING", "format": "TEXT", "value": "https","collections": [{"collection_id": "nconf-appconfig-sample"}]}' )
	HTTP_BODY=$(echo $propertyStatus | sed -e 's/HTTPSTATUS\:.*//g' | jq .)
	HTTP_STATUS=$(echo $propertyStatus | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
	if [ $HTTP_STATUS != 201 ]
	then
		printf "%b\n \e[31m Failure : Property update failed with error code $HTTP_STATUS and body $HTTP_BODY \e[39m"
		cleanup
	else 
		propertyId=$(echo $HTTP_BODY | jq -rc '.property_id')
		printf "%bSuccess:  Property updated with id $propertyId\n"
	fi

	propertyUpdateURL=$propertyURL
	propertyStatus=$(curl -s --write-out 'HTTPSTATUS:%{http_code}'  -X POST $propertyUpdateURL -H "Authorization: Bearer $access_token" -H "Content-Type: application/json" --data '{"name": "Predict Age Query","property_id": "predict-age-query","description": "Server Query string to predict age","type": "STRING","format": "TEXT", "value": "name","collections": [{"collection_id": "nconf-appconfig-sample"}]}' )
	HTTP_BODY=$(echo $propertyStatus | sed -e 's/HTTPSTATUS\:.*//g' | jq .)
	HTTP_STATUS=$(echo $propertyStatus | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
	if [ $HTTP_STATUS != 201 ]
	then
		printf "%b\n \e[31m Failure : Property update failed with error code $HTTP_STATUS and body $HTTP_BODY \e[39m"
		cleanup
	else 
		propertyId=$(echo $HTTP_BODY | jq -rc '.property_id')
		printf "%bSuccess:  Property updated with id $propertyId\n"
	fi
}


if [[ $actionIn == 2 ]]
then
	cleanup
	exit 1
fi


#------------------------------------Environment tests---------------------------
if [[ $envActionIn == 2 ]]
then
	printf "%b\n************************** Creating environment for demo **************************\n"
	addEnvironment
fi

#------------------------------------Collections tests---------------------------
printf "%b\n************************** Creating collections for demo **************************\n"
addCollection

#------------------------------------Property tests---------------------------
printf "%b\n************************** Creating properties for demo **************************\n"
addProperty

printf "%b\n \e[32m--------------------------Demo script complete %b--------------------------\n"
