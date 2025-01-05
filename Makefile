deploy.alpha.kafka-cluster:
	kubectl create namespace kafka
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
	kubectl apply -n monitoring -f ./helm/prometheus/pvc.yaml
	helm install prometheus -n monitoring prometheus-community/prometheus -f ./helm/prometheus/values.yaml
	helm install grafana -n monitoring grafana/grafana -f ./helm/grafana/values.yaml

deploy.argocd:
	kubectl create namespace argocd
	kubectl apply -n argocd -f ./manifests/argocd/argocd.yaml

deploy.kong.system:
	openssl req -new -x509 -nodes -newkey ec:<(openssl ecparam -name secp384r1) -keyout ./tls.key -out ./tls.crt -days 1095 -subj "/CN=kong_clustering"
	kubectl create secret tls kong-system-cluster-cert --cert=./tls.crt --key=./tls.key -n kong
	rm tls.key tls.crt
	helm install kong-cp-system kong/kong -n kong --values ./helm/kong/values-cp-system.yaml
	helm install kong-dp-system kong/kong -n kong --values ./helm/kong/values-dp-system.yaml

deploy.kong.partner:
	openssl req -new -x509 -nodes -newkey ec:<(openssl ecparam -name secp384r1) -keyout ./tls.key -out ./tls.crt -days 1095 -subj "/CN=kong_clustering"
	kubectl create secret tls kong-partner-cluster-cert --cert=./tls.crt --key=./tls.key -n kong
	rm tls.key tls.crt
	helm install kong-cp-partner kong/kong -n kong --values ./helm/kong/values-cp-partner.yaml
	helm install kong-dp-partner kong/kong -n kong --values ./helm/kong/values-dp-partner.yaml

deploy.elastic.stack:
	kubectl create namespace logging
	kubectl config set-context --current --namespace=logging
	helm install elasticsearch elastic/elasticsearch -n logging --values ./helm/elastic-stack/elasticsearch/values.yaml
	helm install filebeat elastic/filebeat -n logging --values ./helm/elastic-stack/filebeat/values.yaml
	helm install logstash elastic/logstash -n logging --values ./helm/elastic-stack/logstash/values.yaml
	helm install kibana elastic/kibana -n logging --values ./helm/elastic-stack/kibana/values.yaml

deploy.longhorn:
	helm install longhorn longhorn/longhorn -n longhorn-system --create-namespace --values ./helm/longhorn/values.yaml

deploy.loki:
	kubectl create namespace loki
	helm install loki grafana/loki -n loki -f ./helm/loki/values.yaml
	helm install promtail grafana/promtail -n loki -f ./helm/promtail/values.yaml
