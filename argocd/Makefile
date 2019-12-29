argocd-dashboard-port ?= 50850

install:
	@$(kubectl) get ns argocd > /dev/null || $(kubectl) create namespace argocd
	@$(kubectl) apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

clean:
	@$(kubectl) delete --ignore-not-found=true -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
	@$(kubectl) delete ns argocd

open:
	@echo "ArgoCD dashboard available at:"
	@echo "  https://localhost:$(argocd-dashboard-port)"
	@echo "Username: admin"
	@echo "Password: $$($(kubectl) get pods -n argocd -l app.kubernetes.io/name=argocd-server -o name | cut -d'/' -f 2)"
	@echo "Opening ArgoCD dashboard in the default browser"
	@open https://localhost:$(argocd-dashboard-port)
	@$(kubectl) port-forward svc/argocd-server -n argocd $(argocd-dashboard-port):443 > /dev/null
