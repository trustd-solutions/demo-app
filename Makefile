REGION="us-east-1"
NAMESPACE="default"
ENVIRONMENT="demo"
REGISTRY_URL=${AWS_ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com
REPOSITORY_URI=${REGISTRY_URL}/${APP_NAME}

include Makefile.helper

version:
	@echo "Version: ${APP_NAME}:${APP_VERSION}"
docker-login:
	@echo ""
	@aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${REGISTRY_URL}

docker-build:
	@echo "Building Docker image ${APP_NAME}:${IMAGE_TAG} ECR: ${REPOSITORY_URI}..."
	@./mvnw -DskipTests spring-boot:build-image -Dspring.profiles.active=mysql -Dspring-boot.build-image.imageName=${APP_NAME}:${IMAGE_TAG}
docker-push: docker-login
	@echo "Pushing Docker Image ${APP_NAME}:${IMAGE_TAG} to ${REPOSITORY_URI}..."
	@docker tag ${APP_NAME}:${IMAGE_TAG} ${APP_NAME}:latest
	@docker tag ${APP_NAME}:${IMAGE_TAG} ${REPOSITORY_URI}:${IMAGE_TAG}
	@docker tag ${APP_NAME}:${IMAGE_TAG} ${REPOSITORY_URI}:latest
	@docker push ${REPOSITORY_URI}:${IMAGE_TAG}
	@docker push ${REPOSITORY_URI}:latest
docker: docker-login docker-build docker-push
docker-run:
	@echo "Running Docker container ${APP_NAME}:${IMAGE_TAG}"
	@docker run -it --rm ${APP_NAME}:${IMAGE_TAG}
helm-dryrun:
	@echo "Deploying Helm Chart version in Kubernetes..."
	@helm upgrade ${APP_NAME} helm-chart/ --version ${APP_VERSION} -n ${NAMESPACE} --cleanup-on-fail --debug --dry-run --install --atomic --wait --set image.tag=${IMAGE_TAG} --values=${HELM_DIR}/values/${ENVIRONMENT}.yaml
helm-upgrade:
	@echo "Deploying Helm Chart version in Kubernetes..."
	@helm upgrade ${APP_NAME} helm-chart/ --version ${APP_VERSION} -n ${NAMESPACE} --cleanup-on-fail --install --atomic --wait --set image.tag=${IMAGE_TAG} --values=${HELM_DIR}/values/${ENVIRONMENT}.yaml
helm-template:
	@echo "Template Helm Chart version in Kubernetes ${HELM_DIR}/values/${ENVIRONMENT}.yaml..."
	@helm template ${APP_NAME} helm-chart/ --debug --version ${APP_VERSION} -n ${NAMESPACE} --values=${HELM_DIR}/values/${ENVIRONMENT}.yaml --set image.tag=${IMAGE_TAG}
helm-rollback:
	@echo "Rollback Helm Chart version in Kubernetes..."
	@helm rollback ${APP_NAME} ${APP_VERSION} -n ${NAMESPACE}
helm-uninstall:
	@echo "Rollback Helm Chart version in Kubernetes..."
	@helm uninstall ${APP_NAME} -n ${NAMESPACE}
