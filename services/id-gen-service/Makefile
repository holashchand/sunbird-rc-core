IMAGE_NAME=local/id-gen-service

build:
	rm -rf ./target
	mvn clean install

docker: build
	docker build -t $(IMAGE_NAME) .

release: docker
    @docker push $(IMAGE_NAME):latest