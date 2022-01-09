deploy_region="westeurope"
web_folder="webapp"
func_folder="func"
web_group=$web_folder"-res-grp"
func_group=$func_folder"-res-grp"

echo "Resource groups creation"

az group create -l $deploy_region -n $web_group
az group create -l $deploy_region -n $func_group

echo "Repository clone"

[ ! -d "azure-func-go-handler/.git" ] && git clone https://github.com/groovy-sky/vnet-service-endpoints
cd vnet-service-endpoints && git pull

echo "Compile/build code"

go build -o $func_folder/code/GoCustomHandler $func_folder/code/GoCustomHandler.go 

cd $web_folder/code 

echo "Web App deploy"

web_arm_out=$(az deployment group create --resource-group $web_group --template-file ../template/azuredeploy.json | jq -r '. | .properties | .outputs')

subnet_id=$(echo $web_arm_out | jq -r '.subnetId.value')
web_url=$(echo $web_arm_out | jq -r '.webAppUrl.value')
web_name=$(echo $web_arm_out | jq -r '.webAppName.value')

echo "Publish to Web App"

python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

az webapp config appsettings set --name $web_name  --resource-group $web_group --settings SCM_DO_BUILD_DURING_DEPLOYMENT=true ENABLE_ORYX_BUILD=true

az webapp restart --name $web_name --resource-group $web_group

az webapp up --sku S1 --resource-group $web_group --name $web_name && cd ../..

cd $func_folder/code

func_arm_out=$(az deployment group create --resource-group $func_group --template-file ../template/azuredeploy.json --parameters subnetResourceId=$subnet_id | jq -r '. | .properties | .outputs')

func_url=$(echo $func_arm_out | jq -r '.funcUrl.value')
func_name=$(echo $func_arm_out | jq -r '.funcName.value')

func azure functionapp publish $func_name --custom
curl https://$web_url?url=https://$func_url/api/httptrigger
