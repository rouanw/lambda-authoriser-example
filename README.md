```sh
terraform apply # will output the invoke URL for the API Gateway
curl -H "Content-Type: application/json" --header "Authorization: Example" -X GET <invoke-url-from-above>
```
