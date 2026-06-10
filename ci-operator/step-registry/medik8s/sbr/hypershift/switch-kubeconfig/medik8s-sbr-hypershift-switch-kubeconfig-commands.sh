#!/bin/bash
set -eu -o pipefail

# hypershift-aws-create writes the hosted cluster kubeconfig to nested_kubeconfig.
# ci-operator points KUBECONFIG at ${SHARED_DIR}/kubeconfig for every step.
# Overwriting the file makes all subsequent test steps target the hosted cluster.
cp "${SHARED_DIR}/nested_kubeconfig" "${SHARED_DIR}/kubeconfig"
