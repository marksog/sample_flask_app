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
terraform plan -target=module.network -target=module.jenkins
terraform apply -target=module.network -target=module.jenkins -auto-approve

#### Things to do 
---On Jenkins server---
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
--- also install terraform ---
https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli


Install plugins:
Docker, AWS, Git, SSH Agent, Pipeline, AWS step, Terraform
You will eqully have to install terraform on jenkins server manually

update jenkins file to updated segurity group for jenkins. (to avoid duplication)

** after doing this user_data.sh did not install (well this is called from the pipeline.) so i manualy had to create the script in ec2 and run it. 

## created a bootstrap deployment first
this will trigger another diployment.

deployment is like this 
graph TD
    A[Manual: Deploy Jenkins] --> B[Jenkins Runs Main Pipeline]
    B --> C{Does EKS Exist?}
    C -->|No| D[Create Full Infrastructure]
    C -->|Yes| E[Skip Infrastructure]
    D --> F[Deploy App]
    E --> F
    F --> G[Run Tests]
    H[Manual Trigger] --> I[Destroy Pipeline]