SHELL						= /bin/bash
.DEFAULT_GOAL		:= help

name ?= kind
wait ?= 60s

CLUSTER_CONFIGS := $(wildcard *cluster.yaml *cluster)
CLUSTER_CONFIGS := $(CLUSTER_CONFIGS:%.yaml=%)

export KUBE_HOME 			:= $(abspath .kube)
export KUBE_CONFIG 		:= $(KUBE_HOME)/config
export KUBE_CTX 			:= kind-$(name)

export kubectl					:= kubectl --context $(KUBE_CTX) --kubeconfig $(KUBE_CONFIG)
export helm							:= helm --kube-context $(KUBE_CTX) --kubeconfig $(KUBE_CONFIG)

tools: Brewfile
	@brew bundle check || brew bundle install

$(KUBE_HOME):
	@mkdir -p $@

.PHONY: $(CLUSTER_CONFIGS)
$(CLUSTER_CONFIGS): $(KUBE_HOME)
	@kind create cluster --name $(name) --kubeconfig $(KUBE_CONFIG) --config $(@:%=%.yaml) --wait $(wait)

clean:
	@kind delete cluster --name $(name) --kubeconfig $(KUBE_CONFIG)
	@rm -rf logs/$(name)

clean-all-clusters:
	@kind get clusters | xargs -L1 -I% kind delete cluster --name %
	@rm -rf $(KUBE_HOME)

.PHONY: logs
logs:
	@kind export logs logs/$(name) --name $(name)

kubeconfig:
	@kind export kubeconfig --name $(name)

## Common commands for installing, uninstalling subsystems
DIRS 				:= $(dir $(wildcard */Makefile))
INSTALLDIRS := $(DIRS:%/=install-%)
CLEANDIRS 	:= $(DIRS:%/=clean-%)
OPENDIRS 		:= $(DIRS:%/=open-%)

install-all: $(INSTALLDIRS)
clean-all: $(CLEANDIRS)

$(INSTALLDIRS):
	@$(MAKE) -C $(@:install-%=%) install

$(CLEANDIRS):
	@$(MAKE) -C $(@:clean-%=%) clean

$(OPENDIRS):
	@$(MAKE) -C $(@:open-%=%) open
