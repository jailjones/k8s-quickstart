.SHELL=/bin/bash
.DEFAULT_GOAL := help
CLUSTER_CONFIGS := $(basename $(notdir $(wildcard clusters/*.yaml)))
CLUSTERS := $(shell kind get clusters | tr '\n' ' ')

OS_NAME := $(shell uname | tr '[:upper:]' '[:lower:]')

help:
	@echo
	@echo Usage: make [command]
	@echo
	@echo Available Commands:
	@echo "  help                 Prints this usage message"
	@echo "  create-cluster       Creates a Kubernetes cluster using a config file specified in clusters folder"
	@echo "  delete-cluster       Deletes an existing cluster"
	@echo "  clusters             Lists the available clusters"
	@echo "  nodes                Lists the nodes in a cluster"
	@echo "  logs                 Exports the logs for a cluster to the logs folder"
	@echo "  clean                Deletes all clusters, logs,etc"
	@echo "  clean-logs           Deletes the logs folder"
	@echo

.install-%:
	@type -P $* > /dev/null 2>&1 || brew install $*

$(CLUSTER_CONFIGS:%=cluster-create-%): .install-kind
	$(eval name += $(@:cluster-create-%=%))
	$(eval config := $(@:cluster-create-%=clusters/%.yaml))
	@kind create cluster --config $(config) --name $(name) 

$(CLUSTERS:%=cluster-delete-%): .install-kind
	$(eval NAME=$(@:cluster-delete-%=%))
	@kind delete cluster --name $(name)

clean: .install-kind clean-logs
	@kind get clusters | xargs -L1 -I% kind delete cluster --name %

clusters: .install-kind
	@kind get clusters

$(CLUSTERS:%=nodes-%): .install-kind
	$(eval NAME=$(@:nodes-%=%))	
	@kind get nodes --name $(NAME)

$(CLUSTERS:%=logs-%): .install-kind
	$(eval NAME=$(@:logs-%=%))	
	@rm -rf logs/$(NAME)
	@kind export logs logs/$(NAME) --name $(NAME)

clean-logs:
	@rm -rf logs

install-linkerd: .install-kubectl .install-linkerd
	@linkerd check --pre
	@linkerd install | kubectl apply -f -
	@linkerd check	

linkerd-dashboard:
	@linkerd dashboard

install-ingress-nginx: .install-helm
	-@helm delete -n kube-system nginx-ingress
	@helm install -n kube-system nginx-ingress stable/nginx-ingress \
		--set controller.service.type=NodePort \
		--set controller.service.nodePorts.http=30080 \
		--set controller.service.nodePorts.https=30443

install-argocd: .install-kubectl
	-@kubectl create namespace argocd
	@kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
	@kubectl apply -n argocd -f argocd/nginx-ingress.yaml

install-argocd-cli:
	@brew tap argoproj/tap
	@brew install argoproj/tap/argocd