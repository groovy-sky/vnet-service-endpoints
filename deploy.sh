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
python3 -m venv $web_folder/code/.venv
source $web_folder/code/.venv/bin/activate
pip install -r $web_folder/code/requirements.txt

echo "Web App deploy"

web_arm_out=$(az deployment group create --resource-group $web_group --template-file $web_folder/template/azuredeploy.json | jq -r '. | .properties | .outputs')

subnet_id=$(echo $web_arm_out | jq -r '.subnetId.value')
web_url=$(echo $web_arm_out | jq -r '.webAppUrl.value')
web_name=$(echo $web_arm_out | jq -r '.webAppName.value')


echo "Publish to Web App"

cd $web_folder/code && az webapp up --sku S1 --name $web_name && cd ../..

func_arm_out=$(az deployment group create --resource-group $func_group --template-file $func_folder/template/azuredeploy.json --parameters subnetResourceId=$subnet_id | jq -r '. | .properties | .outputs')
#go build *.go && func azure functionapp publish $func_name --no-build --force