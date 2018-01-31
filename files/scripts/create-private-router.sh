#!/bin/bash

router_replica_count=${1}

# Limita namespaces de aplicacoes internas as maquinas infra
oc annotate namespace default openshift.io/node-selector='role=infra' --overwrite
oc annotate namespace openshift-infra default openshift.io/node-selector='role=infra' --overwrite

oc project default
oc env dc/router ROUTE_LABELS='router=public'

# Cria router privado
oc adm router private-router --replicas=0 --service-account=router --ports='81:81,444:444' --stats-port=1937
oc rollout pause dc/private-router
oc env dc/private-router ROUTE_LABELS='router=private' ROUTER_SERVICE_HTTP_PORT=81 ROUTER_SERVICE_HTTPS_PORT=444
oc rollout resume dc/private-router
oc scale dc/private-router --replicas=${router_replica_count}

# Define router dos servicos
oc label route --namespace=default registry-console router=public --overwrite
oc label route --namespace=default docker-registry router=public --overwrite
