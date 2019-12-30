install:
	@$(kubectl) get ns ambassador > /dev/null || $(kubectl) create namespace ambassador
	@$(kubectl) get clusterrolebinding > /dev/null || create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --user=`$(kubectl) config view -o jsonpath='{.users[].name}'`
	@$(kubectl) apply -f https://getambassador.io/yaml/ambassador/ambassador-rbac.yaml
	@$(kubectl) patch deployments ambassador -p "$$(cat patch.yaml)"

clean:
	@$(kubectl) delete --ignore-not-found=true -f https://getambassador.io/yaml/ambassador/ambassador-rbac.yaml
	@$(kubectl) delete --ignore-not-found=true clusterrolebinding cluster-admin-binding
	@$(kubectl) delete --ignore-not-found=true ns ambassador

open:
	@open http://localhost/ambassador/v0/diag/
