ingress.yaml:
	@curl -L -o $@  https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/mandatory.yaml

install: patch.yaml ingress.yaml kustomization.yaml
	@$(kubectl) apply -k .

clean:
	@$(kubectl) delete --ignore-not-found=true -k .

open:
	@open http://localhost
