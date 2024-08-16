#SOURCES = $(wildcard java/**/*.java)
rwildcard=$(wildcard $1$2) $(foreach d,$(wildcard $1*),$(call rwildcard,$d/,$2))
SOURCES := $(call rwildcard,java/,*.java)
BUILD_VERSION := $$(git rev-parse --short HEAD)
RELEASE_VERSION = v2.0.1
#PACKAGE_REPO = ghcr.io/sunbird-rc/
PACKAGE_REPO = locanbabu/
IMAGES := sunbird-rc-core sunbird-rc-claim-ms \
			sunbird-rc-notification-service sunbird-rc-metrics \
			id-gen-service encryption-service \
			sunbird-rc-identity-service sunbird-rc-credential-schema \
			sunbird-rc-credentials-service
build-java: java/registry/target/registry.jar
	echo ${SOURCES}
	rm -rf java/claim/target/*.jar
	cd target && rm -rf * && jar xvf ../java/registry/target/registry.jar && cp ../java/Dockerfile ./ && docker build -t local/sunbird-rc-core .
	make -C java/claim
	make -C services/id-gen-service docker
	make -C services/encryption-service docker
build-go:
	make -C services/notification-service docker
	make -C services/metrics docker
build-node:
	make -C services/identity-service/ docker
	make -C services/credential-schema docker
	make -C services/credentials-service/ docker


java/registry/target/registry.jar: $(SOURCES)
	echo $(SOURCES)
	sh configure-dependencies.sh
	cd java && ./mvnw clean install


publish-builds:
	@for image in $(IMAGES); \
    	do \
    	  if [ -n "$$(docker images -q local/$$image:latest)" ]; then \
          	  docker tag local/$$image:latest $(PACKAGE_REPO)$$image:$(BUILD_VERSION); \
          	  echo publish: $(PACKAGE_REPO)$$image:$(BUILD_VERSION); \
          	  docker push $(PACKAGE_REPO)$$image:$(BUILD_VERSION); \
          else \
          	  echo "Skipping image local/$$image:latest -> does not exist locally"; \
          fi \
      	done

pull-builds:
	@for image in $(IMAGES); \
    	do \
    	  echo pull: $(PACKAGE_REPO)$$image:$(BUILD_VERSION); \
    	  docker pull $(PACKAGE_REPO)$$image:$(BUILD_VERSION); \
    	  docker tag $(PACKAGE_REPO)$$image:$(BUILD_VERSION) $(PACKAGE_REPO)$$image:latest; \
      	done

test-node-1:
	@docker-compose -f docker-compose-v1.yml down
	@sudo rm -rf db-data* es-data* || echo "no permission to delete"
	# test with distributed definition manager and native search
	@docker-compose -f docker-compose-v1.yml --env-file test_environments/test_with_distributedDefManager_nativeSearch.env up -d db keycloak registry certificate-signer certificate-api redis
	@echo "Starting the test" && sh build/wait_for_port.sh 8080
	@echo "Starting the test" && sh build/wait_for_port.sh 8081
	@docker-compose -f docker-compose-v1.yml ps
	@curl -v http://localhost:8081/health
	@cd java/apitest && ../mvnw -Pe2e test
	@docker-compose -f docker-compose-v1.yml down
	@sudo rm -rf db-data-1 || echo "no permission to delete"

test-node-2:
	# test with kafka(async), events, notifications,
	@docker-compose -f docker-compose-v1.yml --env-file test_environments/test_with_asyncCreate_events_notifications.env up -d db es clickhouse redis keycloak registry certificate-signer certificate-api kafka zookeeper notification-ms metrics
	@echo "Starting the test" && sh build/wait_for_port.sh 8080
	@echo "Starting the test" && sh build/wait_for_port.sh 8081
	@docker-compose -f docker-compose-v1.yml ps
	@curl -v http://localhost:8081/health
	@cd java/apitest && MODE=async ../mvnw -Pe2e test
	@docker-compose -f docker-compose-v1.yml down
	@sudo rm -rf db-data-2 es-data-2 || echo "no permission to delete"
#	make -C services/identity-service test
#	make -C services/credential-schema test
#	make -C services/credentials-service test

clean:
	@rm -rf target || true
	@rm java/registry/target/registry.jar || true

release: test
	for image in $(IMAGES); \
    	do \
    	  echo $$image; \
    	  docker tag $(PACKAGE_REPO)$$image:latest $$image:$(RELEASE_VERSION);\
    	  docker push $(PACKAGE_REPO)$$image:latest;\
    	  docker push $(PACKAGE_REPO)$$image:$(RELEASE_VERSION);\
      	done
	@cd tools/cli/ && npm publish

compose-init:
	bash setup_vault.sh docker-compose.yml vault

check-build-version:
	@echo $(BUILD_VERSION)
