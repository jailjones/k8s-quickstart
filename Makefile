#---------------------------------------------------
## Usage: make [command] [arg=value ...]
## |
## Available commands:
## |
#---------------------------------------------------

# Makefile Settings
.SHELL									= /bin/bash
.DEFAULT_GOAL 					:= install

# User-defined Variables
config 									?= $(abspath clusters/singlenode.yaml)
name 										?= $(basename $(notdir $(config)))

# Constants
override context 				:= kind-$(name)
override kubectl	 			:= kubectl --context $(context)
override linkerd				:= linkerd --context $(context)

# Private Targets
.PHONY: .print
.print:
	@$(foreach V,$(sort $(.VARIABLES)), \
		$(if $(filter-out environment% default automatic, \
		$(origin $V)),$(warning $V=$($V) ($(value $V)))))

.PHONY:
.brew-%:
	@type -P $* > /dev/null 2>&1 || brew install $*

# Public Targets

## help | prints this help message
.PHONY: help
help: Makefile
	@echo
	@sed -n "s/^##/ /p" $< | column -t -s "|"
	@echo

## install (default) | creates a new kubernetes cluster using kind
.PHONY: install
install: .brew-kind .brew-kubectl
	@kind get clusters | grep -q $(name) && \
		echo "Reusing existing cluster: $(name)" || \
		kind create cluster --config $(config) --name $(name) --wait 60s

## port-mappings | displays host-to-container port mappings to control plan and woker nodes
.PHONY:	port-mappings
port-mappings:
	@docker ps  -f NAME=$(name) --format "table {{.Names}}\t{{.Ports}}"

## clean | deletes the kind k8s cluster
.PHONY: clean
clean: .brew-kind
	@kind delete cluster --name $(name)

## clean-all | deletes all kind k8s clusters
.PHONY: clean-all
clean-all: .brew-kind
	@kind get clusters | xargs -L1 -I% kind delete cluster --name %

## export-logs | exports docker and kubernetes logs to the "logs" directory
.PHONY: export-logs
export-logs: .brew-kind
	@kind export logs --name $(name) logs/$(name)

## install-linkerd | installs linkerd service mesh
.PHONY: install-linkerd
install-linkerd: install .brew-linkerd
	@$(linkerd) check &> /dev/null || ( \
		$(linkerd) check --pre && \
		$(linkerd) install | $(kubectl) apply -f - && \
		$(linkerd) check)

## clean-linkerd | uninstalls linkerd
.PHONY: clean-linkerd
clean-linkerd: .brew-kubectl .brew-linkerd
	@$(linkerd) install --ignore-cluster | $(kubectl) delete --ignore-not-found=true -f -

## dashboard-linkerd | opens the linkderd dashboard
.PHONY: linkerd-dashboard
dashboard-linkderd: .brew-linkerd
	@$(linkerd) dashboard

## install-argocd | installs the ArgoCD continuous delivery tool
install-argocd: install .brew-kubectl
	@type -P argocd > /dev/null 2>&1 || (brew tap argoproj/tap && brew install argoproj/tap/argocd)
	@$(kubectl) get ns argocd > /dev/null || $(kubectl) create namespace argocd
	@$(kubectl) apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

## clean-argocd | uninstalls ArgoCD
clean-argocd: .brew-kubectl
	@$(kubectl) delete --ignore-not-found=true -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
	@$(kubectl) delete ns argocd

argocd-dashboard-port ?= 50850

## dashboard-argocd | Displays the ArgoCD dashboard
dashboard-argocd: .brew-kubectl
	@echo "ArgoCD dashboard available at:"
	@echo "  https://localhost:$(argocd-dashboard-port)"
	@echo "Username: admin"
	@echo "Password: $$($(kubectl) get pods -n argocd -l app.kubernetes.io/name=argocd-server -o name | cut -d'/' -f 2)"
	@echo "Opening ArgoCD dashboard in the default browser"
	@open https://localhost:$(argocd-dashboard-port)
	@$(kubectl) port-forward svc/argocd-server -n argocd $(argocd-dashboard-port):443 > /dev/null

## install-nginx-ingress | installs NGINX Ingress Controller
install-nginx-ingress: .brew-helm
	@helm install nginx-ingress stable/nginx-ingress \
		--set controller.service.type=NodePort \
		--set controller.service.nodePorts.http=30080 \
		--set controller.service.nodePorts.https=30443

## clean-nginx-ingress | uninstalls NGINX Ingress Controller
clean-nginx-ingress: .brew-helm
	@helm delete nginx-ingress
