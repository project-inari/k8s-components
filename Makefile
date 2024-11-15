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

deploy.alpha.mysql:
	kubectl create namespace alpha
	kubectl config set-context --current --namespace=alpha
	helm install mysql -n alpha bitnami/mysql -f ./helm/mysql/values.yaml

deploy.monitoring:
	kubectl create namespace monitoring
	kubectl config set-context --current --namespace=monitoring
	helm install prometheus -n monitoring prometheus-community/prometheus -f ./helm/prometheus/values.yaml
	helm install grafana -n monitoring grafana/grafana -f ./helm/grafana/values.yaml

deploy.argocd:
	kubectl create namespace argocd
	kubectl config set-context --current --namespace=argocd
	kubectl apply -n argocd -f ./manifests/argocd/argocd.yaml

deploy.kong:
	kubectl create namespace kong
	kubectl config set-context --current --namespace=kong
	openssl req -new -x509 -nodes -newkey ec:<(openssl ecparam -name secp384r1) -keyout ./tls.key -out ./tls.crt -days 1095 -subj "/CN=kong_clustering"
	kubectl create secret tls kong-cluster-cert --cert=./tls.crt --key=./tls.key -n kong
	rm tls.key tls.crt
	helm install kong-cp kong/kong -n kong --values ./helm/kong/values-cp.yaml
	helm install kong-dp kong/kong -n kong --values ./helm/kong/values-dp.yaml

.PHONY: deploy.alpha.kafka-cluster deploy.prod.kafka-cluster create.kafka-tls-secret deploy.alpha.mysql deploy.monitoring deploy.argocd deploy.kong
