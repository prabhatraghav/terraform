# Please read the COMMENTS provided within the "main.tf" file for the better understanding of the code.

Place both the files "main.tf" and "AWS_PRIVATE_KEY.pem" in the same folder/directory.

Necessary terraform commands:
1. terraform init                     -- initiate the terraform in the directory
2. terraform fmt                      -- checks for the syntactical errors in the *.tf file
3. terraform validate                 -- checks for the error in the code
4. terraform plan                     -- plan your infra resources
5. terraform apply --auto-approve     -- apply the code to create resources
6. terraform destroy --auto-approve   -- destroy the applied resourses

# 1. Creating Access-Key and Secret-Key Pair
![1](https://github.com/prabhatraghav/terraform/assets/156128444/8e6cd1b4-333e-4829-b924-4c15d3a46d0d)
![2](https://github.com/prabhatraghav/terraform/assets/156128444/bb03c010-2135-4b2a-9c29-e550a903eed4)
* Paste the Security Key pair in the "main.tf" file
# 
# 2. Security Group Creation in AWS a/c to exposes as many ports u want
![1](https://github.com/prabhatraghav/terraform/assets/156128444/c96b131c-5cec-4ae1-831c-9acc4a727b36)
![2](https://github.com/prabhatraghav/terraform/assets/156128444/5d0a9947-4550-4b7b-b53b-307aa67f8748)
* Paste the Security Group ID in the "main.tf" file
