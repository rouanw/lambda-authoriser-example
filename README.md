```sh
cd src/authorizer_lambda && npm install
cd ../infra
terraform apply -var-file=secrets.tfvars # will output the invoke URL for the API Gateway
curl -H "Content-Type: application/json" --header "Authorization: Example" -X GET <invoke-url-from-above>
```
