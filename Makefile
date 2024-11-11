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
