.SHELL=/bin/bash
.DEFAULT_GOAL := help
CLUSTER_CONFIGS := $(basename $(notdir $(wildcard clusters/*.yaml)))
CLUSTERS := $(shell kind get clusters | tr '\n' ' ')

help:
	@echo
	@echo Usage: make [command]
	@echo
	@echo Available Commands:
	@echo "  help                 Prints this usage message"
	@echo "  install-kind         Installs kind via homebrew"
	@echo "  clusters             Lists the available clusters"
	@echo "  create-{cluster}     Creates a Kubernetes cluster using the config file specified in clusters folder"
	@echo "  delete-{cluster}     Deletes an existing cluster"
	@echo "  delete-all           Deletes all clusters"
	@echo "  nodes-{cluster}      Lists the nodes in a cluster"
	@echo "  logs-{cluster}       Exports the logs for a cluster to the logs folder"
	@echo "  clean-logs           Deletes the logs folder"
	@echo

install-kind:
	@test kind || brew install kind

$(CLUSTER_CONFIGS:%=create-%):
	$(eval NAME=$(@:create-%=%))
	$(eval CONFIG=$(NAME:%=clusters/%.yaml))
	@kind create cluster --name $(NAME) --config $(CONFIG)
	@kind export kubeconfig --name $(NAME)

$(CLUSTERS:%=delete-%):
	$(eval NAME=$(@:delete-%=%))
	@kind delete cluster --name $(NAME)

delete-all:
	@kind get clusters | xargs -L1 -I% kind delete cluster --name %

clusters:
	@kind get clusters

$(CLUSTERS:%=nodes-%):
	$(eval NAME=$(@:nodes-%=%))	
	@kind get nodes --name $(NAME)

$(CLUSTERS:%=logs-%):
	$(eval NAME=$(@:logs-%=%))	
	@rm -rf logs/$(NAME)
	@kind export logs logs/$(NAME) --name $(NAME)

clean-logs:
	@rm -rf logs

install-kubectl:
	@test kubectl || brew install kubectl

install-helm: install-kubectl
	@test helm || brew install helm
	@helm repo add stable https://kubernetes-charts.storage.googleapis.com/	

install-linkerd: install-kubectl
	@test linkerd || brew install linkerd
	@linkerd check --pre
	@linkerd install | kubectl apply -f -
	@linkerd check
	@kubectl -n linkerd get deploy

linkerd-dashboard:
	@linkerd dashboard &