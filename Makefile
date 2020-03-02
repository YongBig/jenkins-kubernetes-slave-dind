
# Image URL to use all building/pushing image targets
IMG ?= harbor.oneitfarm.com/jenkins

ci: docker-build-master docker-push-master docker-build-slave-dind docker-push-slave docker-push-docker-dind

# Build the docker image
docker-build-master:
	docker build -f Dockerfile  -t ${IMG}/master:lts .

# Push the docker image
docker-push-master:
	docker push ${IMG}/master:lts

docker-build-slave-dind:
	docker build -f ./slave-dind.Dockerfile -t ${IMG}/slave-dind .

docker-push-slave:
	docker push ${IMG}/slave-dind

docker-push-docker-dind:
	docker pull docker:18.03-dind
	docker tag docker:18.03-dind ${IMG}/docker:18.03-dind
	docker push ${IMG}/docker:18.03-dind