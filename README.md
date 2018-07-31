This is an example how monit monitor and restart apache and mysql services

Requirements: AWS-cli with configured AWS Access Key ID and AWS Secret Access Key -- use https://docs.aws.amazon.com/cli/latest/userguide/awscli-install-linux.html https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html

How to :

Create aws key-pair

aws ec2 create-key-pair --key-name terraformwp --query 'KeyMaterial' --output text > ~/.ssh/terraformwp.pem

chmod 400 ~/.ssh/terraformwp.pem

mkdir somedir

cd somedir

git clone https://github.com/SergeyMuha/monit-terraform.git

cd monit-terraform

terraform init

Deploy infrastructure. This command will output dns name for monithost


terraform apply -input=false -auto-approve


ROUTE host = ec2-18-207-110-252.compute-1.amazonaws.com:8951


To destroy infrastructure use


terraform destroy -input=false -auto-approve
