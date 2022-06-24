#!/bin/bash

#================================================
# CONFIGURATION
#================================================
kube_bin=kubectl
helm_bin=helm
helm_opts=""
kubectl_opts=""

api_resources=( configmap
                statefulset
                certificates.cert-manager.io
                certificaterequests.cert-manager.io
                ingress 
                persistentvolume 
                persistentvolumeclaim 
                mutatingwebhookconfigurations.admissionregistration.k8s.io 
                validatingwebhookconfigurations.admissionregistration.k8s.io 
              )
api_sensitive_resources=( secret 
                        )

tmp_dir=$(mktemp -d -t tpe-XXXX)
tarball_name=thingpark-enterprise-kubernetes-audit-$(date +%Y-%m-%d-%H-%M-%S).tgz
output_dir="."

# Kubernetes context
namespace="thingpark-enterprise"
context=""
get_secrets=0
node_selector="thingpark.enterprise.actility.com/nodegroup-name=tpe"

#================================================
# FUNCTIONS
#================================================

usage(){
    echo "ThingPark Enterprise Kubernetes deployment audit script"
    echo ""
cat << EOF
Usage: ${0##*/} [-d tarball_path] [-c context] [-n namespace] [-s secrets]
Options:
       -h: show this help
       -n | --namespace: The Namespace of ThingPark Enterprise deployment
       -c | --context: Use specific Kubernetes context to reach ThingPark Enterprise deployment
       -d | --directory: Path where put audit result. Default current dir
       -s | --secrets: Export Secret content
EOF
    exit $1
}

process_options(){
  if [ ! -z  ${context} ];then
    ${kube_bin} config get-contexts ${context} 2>&1 > /dev/null
    if [ $? -ne 0 ];then
      echo "$(date): [error]: Unable to use ${context} context"
      exit 1
    fi
    helm_opts+=" --kube-context ${context}"
    kubectl_opts+=" --context ${context}"
    echo "$(date): [info]: Use ${context} kubernetes context."
  fi

  ${kube_bin} ${kubectl_opts} get ns ${namespace} 2>&1 > /dev/null
  if [ $? -ne 0 ];then
    echo "$(date): [error]: ${namespace} not found in ${context} context"
    exit 1
  fi
  helm_opts+=" --namespace ${namespace}"
  kubectl_opts+=" --namespace ${namespace}"
  echo "$(date): [info]: Use ${namespace} as ThingPark Enterprise deployment namespace."

  res=$(${helm_bin} ${helm_opts} list -o yaml | grep -c 'chart: thingpark-enterprise')
  if [ $res -eq 0 ];then
    echo "$(date): [error]: No ThinPark Enterprise chart deployment found. Namespace: ${namespace}, Context: ${context}"
    exit 1
  fi
  echo "$(date): [info]: ThingPark Enterprise deployment found in ${namespace} namespace."
}

#================================================
# PARSE OPTIONS
#================================================
while (( "$#" )); do
  case "$1" in
    -h | --help)
      usage
      ;;
    -s | --secrets)
      get_secrets=1
      shift
      ;;
    -d | --directory)
      output_dir="${2}"
      shift
      shift
      ;;
    -n | --namespace)
      namespace="${2}"
      shift
      shift
      ;;
    -c | --context)
      context="${2}"
      shift
      shift
      ;;
    *)
      echo "$(date): [error]: unknown parameter \"${1}\""
      usage 1
      ;;
  esac
done

#================================================
# MAIN
#================================================
for cmd in "${kube_bin}" "${helm_bin}"
do
  if ! command -v ${cmd} &> /dev/null; then
      echo "$(date): [error]: ${cmd} is required"
      exit 1
  fi
done

echo "$(date): [info]: Start ThingPark Enterprise deployment audit. "

process_options

## Cluster info
echo "$(date): [info]: Prepare ${tmp_dir} tmpdir."
mkdir ${tmp_dir}/cluster-info \
      ${tmp_dir}/manifests \
      ${tmp_dir}/top \
      ${tmp_dir}/describe \
      ${tmp_dir}/versions

echo "$(date): [info]: Get versions. "
${kube_bin} ${kubectl_opts} \
            version \
            > ${tmp_dir}/versions/kubernetes.txt

${helm_bin} version \
            > ${tmp_dir}/versions/helm.txt

echo "$(date): [info]: Get Helm ThingPark Enterprise releases info. "
${helm_bin} ${helm_opts} \
            list \
            --output yaml \
            > ${tmp_dir}/versions/thingpark-helm-releases.yaml

echo "$(date): [info]: Dump cluster info for ${namespace} namespace. "
${kube_bin} ${kubectl_opts} \
            cluster-info  dump \
            --namespaces kube-system,${namespace} \
            --output-directory ${tmp_dir}/cluster-info/ \
            -o yaml > /dev/null 2>&1
if [ $? -ne 0 ];then
  echo "$(date): [error]: Dump cluster info failed"
  exit 1
fi

for r in "${api_resources[@]}"
do
  echo "$(date): [info]: Get ThingPark Enterprise ${r} manifests."
  ${kube_bin} ${kubectl_opts} \
              get ${r} -o yaml > ${tmp_dir}/manifests/${r}.yaml
done

if [ ${get_secrets} -gt 0 ]; then
  echo "$(date): [warning]: Get ThingPark Enterprise sensitives resources."
  for r in "${api_sensitive_resources[@]}"
  do
    echo "$(date): [info]: Get ThingPark Enterprise ${r} manifests."
    ${kube_bin} ${kubectl_opts} \
                get ${r} -o yaml > ${tmp_dir}/manifests/${r}.yaml
  done
fi

echo "$(date): [info]: Describe nodes."
${kube_bin} ${kubectl_opts} \
            describe nodes > ${tmp_dir}/describe/nodes.txt 2>&1

echo "$(date): [info]: Get Metrics."
${kube_bin} ${kubectl_opts} \
            top pod --containers > ${tmp_dir}/top/pods.txt 2>&1
        
${kube_bin} ${kubectl_opts} \
            top nodes --selector ${node_selector} > ${tmp_dir}/top/nodes.txt 2>&1

echo "$(date): [info]: Build tarball and clean."
tar -C ${tmp_dir} -czf  ${output_dir}/${tarball_name} . 
rm -r ${tmp_dir}

echo "$(date): [info]: Tarball to communicate to support: ${output_dir}/${tarball_name}."