#!/bin/bash -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source ${DIR}/default-env.sh
source ${DIR}/util.sh

: "${CREATE_NAMESPACE:=false}"

: "${CHARGEBACK_CR_FILE:=manifests/installer/chargeback-crd.yaml}"

if [ "$CREATE_NAMESPACE" == "true" ]; then
    echo "Creating namespace ${CHARGEBACK_NAMESPACE}"
    kubectl create namespace "${CHARGEBACK_NAMESPACE}" || true
elif ! kubectl get namespace ${CHARGEBACK_NAMESPACE} 2> /dev/null; then
    echo "Namespace '${CHARGEBACK_NAMESPACE}' does not exist, please create it before starting"
    exit 1
fi

if [ "$CHARGEBACK_NAMESPACE" != "tectonic-system" ]; then
    msg "Configuring pull secrets"
    copy-tectonic-pull
fi

msg "Installing Custom Resource Definitions"
kube-install \
    manifests/custom-resource-definitions

msg "Installing Chargeback CRD"
kube-install \
    manifests/installer/chargeback-crd.yaml

msg "Installing chargeback-helm-operator service account and RBAC resources"
kube-install \
    manifests/installer/chargeback-helm-operator-service-account.yaml \
    manifests/installer/chargeback-helm-operator-rbac.yaml

msg "Installing chargeback-helm-operator"
kube-install \
    manifests/installer/chargeback-helm-operator-deployment.yaml

msg "Installing Chargeback"
kube-install \
    "$CHARGEBACK_CR_FILE"
