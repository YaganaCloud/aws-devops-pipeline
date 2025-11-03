
AWS_REGION ?= us-east-1
AWS_ACCOUNT_ID := $(shell aws sts get-caller-identity --query Account --output text)
ECR_REPO ?= myapp
IMAGE_URI := $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com/$(ECR_REPO)

docker-build:
	docker build -t $(IMAGE_URI):dev ./app

ecr-login:
	aws ecr get-login-password --region $(AWS_REGION) | docker login --username AWS --password-stdin $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com

docker-push: ecr-login
	docker push $(IMAGE_URI):dev

deploy:
	aws eks update-kubeconfig --name devops-cluster --region $(AWS_REGION)
	sed "s#REPLACE_WITH_ECR_URI#$(IMAGE_URI)#g" k8s/deployment.yaml | kubectl apply -f -
	kubectl apply -f k8s/service.yaml
	kubectl apply -f k8s/hpa.yaml
	kubectl rollout status deployment/myapp-deployment
