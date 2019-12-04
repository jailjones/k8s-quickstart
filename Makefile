
# Makefile Settings
.SHELL									= /bin/bash
.DEFAULT_GOAL 					:= all

# User-defined Variables
config 									?= $(abspath clusters/singlenode.yaml)
name 										?= $(basename $(notdir $(config)))

# Constants
override context 				:= kind-$(name)
override kubectl				:= kubectl --context $(context)
override linkerd				:= linkerd --context $(context)

# Helpers
.PHONY: .print
.print:
	@$(foreach V,$(sort $(.VARIABLES)), \
		$(if $(filter-out environment% default automatic, \
		$(origin $V)),$(warning $V=$($V) ($(value $V)))))

define install
	@type -P $@ > /dev/null 2>&1 || brew install $@
endef

.PHONY: all
all: install

.PHONY: install
install:
	$(install kind)
	$(install kubectl)
	@kind get clusters | grep -q $(name) && \
		echo "Reusing existing cluster: $(name)" || \
		kind create cluster --config $(config) --name $(name) --wait 60s

.PHONY: clean
clean:
	$(install kind)
	@kind delete cluster --name $(name)

.PHONY: export-logs
export-logs:
	@kind export logs --name $(name) logs/$(name)

.PHONY: install-linkerd
install-linkerd: install
	$(install linkerd)
	@$(linkerd) check &> /dev/null || ( \
		$(linkerd) check --pre && \
		$(linkerd) install | $(kubectl) apply -f - && \
		$(linkerd) check)

.PHONY: clean-linkerd
clean-linkerd:
	$(install kubectl)
	$(install linkerd)
	@$(linkerd) install --ignore-cluster | $(kubectl) delete --ignore-not-found=true -f -

.PHONY: linkerd-dashboard
linkerd-dashboard:
	@$(linkerd) dashboard

# install-ingress-nginx: .install-helm
# 	-@helm delete -n kube-system nginx-ingress
# 	@helm install -n kube-system nginx-ingress stable/nginx-ingress \
# 		--set controller.service.type=NodePort \
# 		--set controller.service.nodePorts.http=30080 \
# 		--set controller.service.nodePorts.https=30443

install-argocd: install
	@type -P argocd > /dev/null 2>&1 || (brew tap argoproj/tap && brew install argoproj/tap/argocd)
	@$(kubectl) get ns argocd > /dev/null || $(kubectl) create namespace argocd
	@$(kubectl) apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

argocd-dashboard-port ?= 50850

argocd-dashboard:
	@echo "ArgoCD dashboard available at:"
	@echo "  https://localhost:$(argocd-dashboard-port)"
	@echo "Username: admin"
	@echo "Password: $$($(kubectl) get pods -n argocd -l app.kubernetes.io/name=argocd-server -o name | cut -d'/' -f 2)"
	@echo "Opening ArgoCD dashboard in the default browser"
	@open https://localhost:$(argocd-dashboard-port)
	@$(kubectl) port-forward svc/argocd-server -n argocd $(argocd-dashboard-port):443 > /dev/null
