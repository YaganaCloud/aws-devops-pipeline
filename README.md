
# Automated CI/CD on AWS with Jenkins, Docker, and EKS (Kubernetes)

A production-style DevOps portfolio project that demonstrates CI/CD on AWS:
- Jenkins runs a declarative pipeline on each Git push
- Pipeline builds and tests a Python Flask app, builds a Docker image, and pushes to Amazon ECR
- Pipeline deploys to Amazon EKS with kubectl (LoadBalancer Service exposed to the internet)
- Horizontal Pod Autoscaler (HPA) is included for basic scaling

ARCHITECTURE
GitHub -> Webhook -> Jenkins (EC2)
Jenkins stages: Checkout -> Unit Tests -> Docker Build -> Push to ECR -> Deploy to EKS
EKS runs the container, fronted by a LoadBalancer Service -> Public URL

PREREQUISITES
- AWS Account with permissions to create: ECR repo, EKS cluster, IAM roles, CloudWatch logs
- Local machine or EC2 with: AWS CLI v2, kubectl, eksctl, Docker, Git
- Jenkins on EC2 (Amazon Linux 2) with Java 11+ and Docker installed
- An ECR repository named "myapp" (or change env vars below)

Create ECR repo (once):
    aws ecr create-repository --repository-name myapp --image-scanning-configuration scanOnPush=true --region us-east-1

QUICK START
1) Clone and configure
    git clone https://github.com/your-username/aws-devops-pipeline.git
    cd aws-devops-pipeline

Set environment variables for your AWS account and region (replace values):
    export AWS_REGION=us-east-1
    export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    export ECR_REPO=myapp

2) Option A: Create EKS cluster with eksctl
    eksctl create cluster -f infra/eksctl-cluster.yaml
    aws eks update-kubeconfig --name devops-cluster --region $AWS_REGION

3) Test local build
    docker build -t myapp:dev ./app
    docker run -p 8080:8080 myapp:dev
    # Open http://localhost:8080

JENKINS SETUP (EC2)
Install Jenkins + Docker (Amazon Linux 2):
    sudo yum update -y
    sudo amazon-linux-extras install java-openjdk11 -y
    sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
    sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key
    sudo yum install jenkins git docker -y
    sudo systemctl enable jenkins docker
    sudo usermod -aG docker jenkins
    sudo usermod -aG docker ec2-user
    sudo systemctl start docker jenkins

Plugins to install in Jenkins:
- Pipeline (Declarative), Git, GitHub, Credentials Binding
- Optional: Slack or Email extensions

Jenkins credentials to add:
- aws-access-key-id (Secret text)
- aws-secret-access-key (Secret text)
- aws-region (Secret text or use a default in the Jenkinsfile)

Create a Multibranch Pipeline or Pipeline job pointing to your GitHub repo. Add a GitHub webhook to trigger on push.

EKS MANIFESTS
- k8s/deployment.yaml – Deployment for the app
- k8s/service.yaml – LoadBalancer Service (public)
- k8s/hpa.yaml – Basic autoscaling from 2–5 pods

After Jenkins deploys, get the URL:
    kubectl get svc myapp-service -n default
Copy EXTERNAL-IP and open in browser.

PIPELINE STAGES (jenkins/Jenkinsfile)
1. Checkout – Pulls code from GitHub
2. Unit Tests – Runs pytest against the Flask app
3. Docker Build – Builds image with git short SHA tag
4. Push to ECR – Logs in and pushes image
5. Deploy to EKS – Applies manifests with the new image
6. Post – Archive logs and optional notifications

CLOUDWATCH (optional)
Enable Kubernetes control plane logs:
    eksctl utils update-cluster-logging --cluster=devops-cluster --region=$AWS_REGION --enable-types=api,audit,authenticator,controllerManager,scheduler --approve

HANDY MAKE TARGETS
    make docker-build
    make ecr-login
    make docker-push
    make deploy

LINKEDIN POST TEMPLATE
Title: I built a complete AWS DevOps CI/CD pipeline

I just completed a production-style CI/CD pipeline on AWS using Jenkins, Docker, ECR, and EKS. Each push triggers automated tests, image builds, ECR push, and Kubernetes deployment (LoadBalancer + HPA).

Stack: Jenkins · Docker · Kubernetes (EKS) · Amazon ECR · eksctl · CloudWatch · Python/Flask · Pytest
Repo: https://github.com/your-username/aws-devops-pipeline
Live URL: (EKS LoadBalancer link)

#DevOps #AWS #Jenkins #Docker #Kubernetes #EKS #ECR #Cloud #CI #CD #SRE #Flask
