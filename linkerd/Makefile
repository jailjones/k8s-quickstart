linkerd	:= linkerd --context $(KUBE_CTX) --kubeconfig $(KUBE_CONFIG)

install:
	@$(linkerd) check --pre
	@$(linkerd) install | $(kubectl) apply -f -
	@$(linkerd) check

open:
	@$(linkerd) dashboard

clean:
	@$(linkerd) install --ignore-cluster | $(kubectl) delete --ignore-not-found=true -f -
