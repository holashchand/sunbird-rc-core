IMAGE:=local/sunbird-rc-credential-schema

.PHONY: docker publish test

docker:
	@docker buildx build --platform=$$PLATFORM --cache-from=$$CACHE_SRC --cache-to=$$CACHE_DST -t $(IMAGE) .

publish:
	@docker push $(IMAGE)

test:
#	Resetting vault of identity-service before running the tests
	make -C ../identity-service stop
	make -C ../identity-service vault-reset
# 	Creating an external docker network to connnect services in different compose
	@docker network create rcw-test || echo ""
#	Starting dependent services 
	make -C ../identity-service compose-init
	@docker-compose -f docker-compose-test.yml down
	@docker-compose -f docker-compose-test.yml up --build --abort-on-container-exit
	make -C ../identity-service stop
	make -C ../identity-service vault-reset

compose-init:
	@docker-compose up -d --build
stop:
	@docker-compose stop