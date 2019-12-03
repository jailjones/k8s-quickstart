
# Makefile Settings
.SHELL									= /bin/bash
.DEFAULT_GOAL 					:= install

# User-defined Variables
config 									?= $(abspath clusters/singlenode.yaml)
name 										?= $(basename $(notdir $(config)))

# Constants
override install_dir		:= $(abspath ./.clusters)
override cluster_dir		:= $(install_dir)/$(name)
override kubeconfig			:= $(cluster_dir)/kubeconfig
override context 				:= kind-$(name)
override kubectl				:= kubectl --context $(context) --kubeconfig $(kubeconfig)
override linkerd				:= linkerd --context $(context) --kubeconfig $(kubeconfig)

# Helpers
.PHONY: .print
.print:
	@$(foreach V,$(sort $(.VARIABLES)), \
		$(if $(filter-out environment% default automatic, \
		$(origin $V)),$(warning $V=$($V) ($(value $V)))))

define install
	@type -P $@ > /dev/null 2>&1 || brew install $@
endef

$(install_dir) $(cluster_dir):
	@mkdir -p $@

.PHONY: install
install: $(kubeconfig)

$(kubeconfig): | $(cluster_dir)
	$(install kind)
	@kind create cluster --config $(config) --name $(name) --kubeconfig $@

.PHONY: clean
clean:
	$(install kind)
	@kind delete cluster --name $(name)
	@rm -rf $(cluster_dir)

export-kubeconfig: $(kubeconfig)
	@kind export kubeconfig --name $(name)

export-logs: $(kubeconfig)
	@kind export logs --name $(name) $(cluster_dir)/logs

install-linkerd: $(kubeconfig)
	$(install kubectl)
	$(install linkerd)
	@$(linkerd) check --pre
	@$(linkerd) install | $(kubectl) apply -f -
	@$(linkerd) check

clean-linkerd:
	$(install kubectl)
	$(install linkerd)
	@$(linkerd) install --ignore-cluster | $(kubectl) delete --ignore-not-found=true -f -

linkerd-dashboard:
	@linkerd dashboard

# install-ingress-nginx: .install-helm
# 	-@helm delete -n kube-system nginx-ingress
# 	@helm install -n kube-system nginx-ingress stable/nginx-ingress \
# 		--set controller.service.type=NodePort \
# 		--set controller.service.nodePorts.http=30080 \
# 		--set controller.service.nodePorts.https=30443

# install-argocd: .install-kubectl
# 	-@kubectl create namespace argocd
# 	@kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
# 	@kubectl apply -n argocd -f argocd/nginx-ingress.yaml

# install-argocd-cli:
# 	@brew tap argoproj/tap
# 	@brew install argoproj/tap/argocd
