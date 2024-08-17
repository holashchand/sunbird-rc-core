IMAGE_NAME=local/encryption-service

build:
	rm -rf ./target
	mvn clean install

docker: build
	docker buildx build --platform=$$PLATFORM --cache-from=$$CACHE_SRC --cache-to=$$CACHE_DST -t $(IMAGE_NAME) .

release: docker
    @docker push $(IMAGE_NAME):latest

