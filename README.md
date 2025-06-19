# sample_flask_app
for devops 3 tier application

## application (sample app)
app/
├── Dockerfile
├── requirements.txt
├── app.py
├── prometheus_monitoring.py
└── wsgi.py

build the app and register to docker hub or amazon ecr

aws 
`aws ecr get-login-password | docker login --username AWS --password-stdin 148761635167.dkr.ecr.us-east-1.amazonaws.com
docker tag flask-test-app:latest 148761635167.dkr.ecr.us-east-1.amazonaws.com/flask-test-app:latest

docker push 148761635167.dkr.ecr.us-east-1.amazonaws.com/flask-test-app # create the repo manually with this name before you push`

## Doing a minimal deployment with terraform locally to get jenkins setup.
i created a jenkins file to deploy just jenkins server "jenkins-only.tf"
then i will use this server to deploy the whole architecture

cd infra/
terraform init
terraform plan -target=module.network -target=module.jenkins -auto-approve
terraform apply -target=module.network -target=module.jenkins -auto-approve

** after doing this user_data.sh did not install (well this is called from the pipeline.) so i manualy had to create the script in ec2 and run it. 

## created a bootstrap deployment first
this will trigger another diployment.