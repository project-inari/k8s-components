deploy.alpha.kafka-cluster:
	kubectl create namespace kafka
	kubectl config set-context --current --namespace=kafka
	helm install confluent-operator confluentinc/confluent-for-kubernetes -n kafka
	make create.kafka-tls-secret
	kubectl apply -n kafka -k ./kustomize/kafka-cluster/overlays/alpha

deploy.prod.kafka-cluster:
	kubectl create namespace kafka
	kubectl config set-context --current --namespace=kafka
	helm install confluent-operator confluentinc/confluent-for-kubernetes -n kafka
	make create.kafka-tls-secret
	kubectl apply -n kafka -k ./kustomize/kafka-cluster/overlays/prod

create.kafka-tls-secret:
	openssl genrsa -out ca-key.pem 2048
	openssl req -new -key ca-key.pem -x509 \
		-days 1000 \
		-out ca.pem \
		-subj "/C=US/ST=CA/L=Confluent/O=Confluent/OU=Operator/CN=MyCA"
	kubectl create secret tls ca-pair-sslcerts --cert=ca.pem --key=ca-key.pem -n kafka
	rm ca-key.pem ca.pem

deploy.argocd:
	kubectl create namespace argocd
	kubectl config set-context --current --namespace=argocd
	kubectl apply -n argocd -f ./manifests/argocd/argocd.yaml

deploy.kong:
	kubectl create namespace kong
	kubectl config set-context --current --namespace=kong
	helm install kong -n kong kong/kong -f ./helm/kong/values.yaml

upgrade.kong:
	kubectl config set-context --current --namespace=kong
	helm upgrade kong -n kong kong/kong -f ./helm/kong/values.yaml

.PHONY: deploy.argocd deploy.kong upgrade.kong
