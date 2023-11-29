#!/bin/bash
set -o nounset
set -o pipefail

#================================================
# VARIABLES
#================================================
kube_bin=kubectl
helm_bin=helm
helm_opts=""
kubectl_opts=""
MONGODB_PASSWORD=""
MONGODB_CLIENT_IMAGE=""
MARIADB_PASSWORD=""
MARIADB_CLIENT_IMAGE=""
api_resources=( configmap
                statefulset
                certificates.cert-manager.io
                certificaterequests.cert-manager.io
                ingress 
                persistentvolumeclaim 
              )
api_sensitive_resources=( secret 
              )

tmp_dir=$(mktemp -d -t thingpark-audit-XXXX)
tarball_name=thingpark-kubernetes-audit-$(date +%Y-%m-%d-%H-%M-%S).tgz
output_dir="."
error_counter=0

# Kubernetes context
namespace="thingpark-enterprise"
context=""
get_secrets=0
use_metrics_api=yes
thingpark_flavor=${thingpark_flavor:-"thingpark-enterprise"}
node_selector=${node_selector:-"thingpark.enterprise.actility.com/nodegroup-name=tpe"}

red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
reset=$(tput sgr0)

#================================================
# FUNCTIONS
#================================================

main() {

  process_options "${@}"
  info "PREPARE AUDIT. "
  check_prerequisites
  prepare

  info "START THINGPARK DEPLOYMENT AUDIT. "
  info "[1/6]: AUDIT VERSIONS. "
  audit_versions
  info "[2/6]: AUDIT THINGPARK DEPLOYMENT. "
  audit_thingpark_deployment
  info "[3/6]: AUDIT COMPUTE AND STORAGE. "
  audit_compute_storage_resources
  info "[4/6]: AUDIT DATABASES. "
  audit_databases
  info "[5/6]: AUDIT THINGPARK COMPONENTS. "
  audit_thingpark
  info "[6/6]: BUILD TARBALL. "
  build_tarball
  
  if [ ${error_counter} -gt 0 ]; then
    warn "The report is incomplete due to deployment state. \
    Please retry once before consider to provide it to support" 
  fi
}

usage(){
    echo "ThingPark Kubernetes deployment audit script"
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
}

error() {
  (( error_counter++ ))
  printf "${red}$(date): [error]: %s${reset}\\n" "${*}" 1>&2 | tee -a ${output_dir}/tp-audit.log
}

panic() {
  error
  exit 1
}

warn() {
  printf "${yellow}$(date): [warning]: %s${reset}\\n" "${*}" 1>&2 | tee -a ${output_dir}/tp-audit.log
}

info() {
  printf "$(date): [info]: %s\\n" "${*}" 1>&2 | tee -a ${output_dir}/tp-audit.log
}

success() {
  printf "${green}$(date): [success]: %s${reset}\\n" "${*}" 1>&2 | tee -a ${output_dir}/tp-audit.log
}

process_options(){

  while (( "$#" )); do
    case "$1" in
      -h | --help)
        usage
        exit 0
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
        usage
        panic "Unknown parameter \"${1}\""
        ;;
    esac
  done
}

check_prerequisites(){
  info "Check Work Station prerequisites"

  for cmd in "${kube_bin}" "${helm_bin}" "jq"
  do
    if ! command -v ${cmd} &> /dev/null; then
        panic "${cmd} binary is required"
    fi
  done

  info "Check Kubernetes api access prerequisites"

  if [ ! -z  ${context} ]; then
    ${kube_bin} config get-contexts ${context} > /dev/null 2>&1
    if [ $? -ne 0 ]; then
      panic "Unable to use ${context} context"
    fi
  else
    context=$(kubectl config current-context)
  fi
  helm_opts+=" --kube-context ${context}"
  kubectl_opts+=" --context ${context}"
  info "Use ${context} kubernetes context"

  ${kube_bin} ${kubectl_opts} get ns ${namespace} > /dev/null 2>&1 
  if [ $? -ne 0 ]; then
    usage
    panic "Namespace ${namespace} not found in ${context} context"
  fi
  helm_opts+=" --namespace ${namespace}"
  kubectl_opts+=" --namespace ${namespace}"
  info "Use ${namespace} as ThingPark Enterprise deployment namespace"

  ${kube_bin} ${kubectl_opts} get --raw "/apis/metrics.k8s.io" > /dev/null 2>&1
  if [ $? -ne 0 ]; then
    warn "Metric API not available"
    use_metrics_api=no
  fi

  ${kube_bin} ${kubectl_opts} get nodes > /dev/null 2>&1
  if [ $? -ne 0 ]; then
    panic "Unable to list nodes. Audit script require get and list verbs on nodes resources"
  fi

  res=$(${helm_bin} ${helm_opts} list -o yaml | grep -c "chart: ${thingpark_flavor}")
  if [ $res -eq 0 ]; then
     panic "No ${thingpark_flavor} Helm Chart Release found. Namespace: ${namespace}, Context: ${context}"
  fi
  info "${thingpark_flavor} Helm Chart Release found in ${namespace} namespace"
}

prepare(){
  info "Prepare ${tmp_dir} workdir"
  mkdir -p ${tmp_dir}/thingpark \
        ${tmp_dir}/thingpark-instance/manifests \
        ${tmp_dir}/kubernetes \
        ${tmp_dir}/data-stack \
        ${tmp_dir}/compute-storage
  if [ $? -ne 0 ]; then
    panic "Fail to prepare  ${tmp_dir} workdir"
  fi

  MARIADB_PASSWORD=$(${kube_bin} ${kubectl_opts} get secrets mariadb-galera -o jsonpath='{.data.mariadb-root-password}' | base64 -d)
  if [ $? -ne 0 ]; then
    panic "Fail to get MariaDB connection credentials"
  fi
  MARIADB_IMAGE=$(${kube_bin} ${kubectl_opts} get sts mariadb-galera -o jsonpath='{.spec.template.spec.containers[0].image}')
  if [ $? -ne 0 ]; then
    panic "Fail to get MariaDB client Image"
  fi
  MONGODB_PASSWORD=$(${kube_bin} ${kubectl_opts} get secrets maintenance-mongo-account -o jsonpath='{.data.userPassword}' | base64 -d)
  if [ $? -ne 0 ]; then
    panic "Fail to get MongoDB connection credentials"
  fi
  MONGODB_CLIENT_IMAGE=$(${kube_bin} ${kubectl_opts} get sts mongo-replicaset-rs0 -o jsonpath='{.spec.template.spec.containers[0].image}')
  if [ $? -ne 0 ]; then
    panic "Fail to get MongoDB client Image"
  fi
}

audit_versions(){
  ${kube_bin} ${kubectl_opts} \
              version \
              > ${tmp_dir}/kubernetes/k8s-versions.txt  2>&1
  if [ $? -ne 0 ]; then
    error "Fail to get kubernetes versions"
  fi

  ${helm_bin} version \
              > ${tmp_dir}/kubernetes/helm-versions.txt 2>&1 
  if [ $? -ne 0 ]; then
    error "Fail to get helm versions"
  else
    success "Get versions"
  fi
}

audit_thingpark_deployment(){
  ${helm_bin} ${helm_opts} \
              list \
              --output yaml \
              > ${tmp_dir}/thingpark-instance/thingpark-helm-releases.yaml
  if [ $? -ne 0 ]; then
    error "Fail to get Helm ThingPark releases info"
  else
    success "Get Helm ThingPark releases info"
  fi

  ${kube_bin} ${kubectl_opts} \
              cluster-info  dump \
              --namespaces ${namespace} \
              --output-directory ${tmp_dir}/thingpark-instance/info/ \
              -o yaml > /dev/null 2>&1
  if [ $? -ne 0 ]; then
    error "Dump cluster info for ${namespace} failed"
  else
    success "Dump cluster info for ${namespace}"
  fi

  for r in "${api_resources[@]}"
  do
    ${kube_bin} ${kubectl_opts} \
      get ${r} -o yaml > ${tmp_dir}/thingpark-instance/manifests/${r}.yaml
    if [ $? -ne 0 ]; then
      error "Fail to get ThingPark ${r} manifests"
    else
      success "Get ThingPark  ${r} manifests"
    fi
  done

  if [ ${get_secrets} -gt 0 ]; then
    warn "Get ThingPark sensitives resources"
    for r in "${api_sensitive_resources[@]}"
    do
      ${kube_bin} ${kubectl_opts} \
                  get ${r} -o yaml > ${tmp_dir}/manifests/${r}.yaml
      if [ $? -ne 0 ]; then
        error "Fail to get ThingPark ${r} manifests"
      else
        success "Get ThingPark ${r} manifests"
      fi
    done
  fi

  success "Get ThingPark deployment resources in ${namespace} namespace"

}

audit_compute_storage_resources(){
  if [ "$use_metrics_api" == "yes" ]; then
    ${kube_bin} ${kubectl_opts} \
      top pod --containers > ${tmp_dir}/compute-storage/pods-metrics.txt 2>&1
    if [ $? -ne 0 ]; then
      error "Fail to get pods metrics"
    fi
            
    ${kube_bin} ${kubectl_opts} \
      top nodes --selector ${node_selector} > ${tmp_dir}/compute-storage/nodes-metrics.txt 2>&1
    if [ $? -ne 0 ]; then
      error "Fail to get nodes metrics"
    fi
    success "Get Metrics"
  fi

  ${kube_bin} ${kubectl_opts} \
              describe nodes > ${tmp_dir}/compute-storage/nodes.txt 2>&1
  if [ $? -ne 0 ]; then
    error "Fail to get nodes describe"
  else
    success "Get nodes describe"
  fi

  for node in $(${kube_bin} ${kubectl_opts} get nodes -o json | jq -r '.items[].metadata.name'); do
    ${kube_bin} ${kubectl_opts} \
      get --raw /api/v1/nodes/${node}/proxy/stats/summary | jq ".pods[].volume[]?|select(has(\"pvcRef\"))|select(.pvcRef.namespace == \"${namespace}\")|{name: .pvcRef.name,  capacityBytes, usedBytes, availableBytes, inodes, inodesUsed, inodesFree,  percentageUsed: (.usedBytes / .capacityBytes * 100), percentageInodesUsed: (.inodesUsed / .inodes * 100)}" \
      >> ${tmp_dir}/compute-storage/storage.txt 2>&1
    if [ $? -ne 0 ]; then
      error "Fail to get volumes stats for node ${node}"
    else
      success "Get volumes stats for node ${node}"
    fi
  done
}


audit_databases(){

  ${kube_bin} ${kubectl_opts} \
    run mariadb-client -it --rm --restart='Never' \
    --env="MARIADB_PASSWORD=$MARIADB_PASSWORD" --image $MARIADB_IMAGE \
    -- bash -c "mysql -N -B -h mariadb-galera -u root --password=$MARIADB_PASSWORD \
    -e \"SELECT table_schema AS DB_NAME, TABLE_NAME, SUM(TABLE_ROWS) AS ROWS_COUNT, \
    round(((data_length + index_length) / 1024 / 1024), 2) 'Size (MB)' \
    FROM INFORMATION_SCHEMA.TABLES GROUP BY TABLE_NAME ORDER BY DB_NAME;\"" \
    > ${tmp_dir}/data-stack/mariadb-tables-stats.txt 2>&1
  if [ $? -ne 0 ]; then
    error "Fail to get MariaDB tables stats"
  else
    success "Get MariaDB tables stats"
  fi

  ${kube_bin} ${kubectl_opts} \
    run mariadb-client -it --rm --restart='Never' \
    --env="MARIADB_PASSWORD=$MARIADB_PASSWORD" --image $MARIADB_IMAGE \
    -- bash -c "mysql -N -B -h mariadb-galera -u root --password=$MARIADB_PASSWORD \
    -e \"SELECT table_schema AS DB_NAME, TABLE_NAME, \
    round(((data_length + index_length) / 1024 / 1024), 2) 'Size (MB)' \
    FROM INFORMATION_SCHEMA.TABLES GROUP BY DB_NAME ORDER BY DB_NAME;\"" \
    > ${tmp_dir}/data-stack/mariadb-databases-stats.txt 2>&1
  if [ $? -ne 0 ]; then
    error "Fail to get MariaDB databases stats"
  else
    success "Get MariaDB databases stats"
  fi

  ${kube_bin} ${kubectl_opts} \
    run mongo-client -it --rm --restart='Never' \
    --env="MONGODB_PASSWORD=$MONGODB_PASSWORD" --image $MONGODB_CLIENT_IMAGE \
    -- bash -c "mongo -u maintenance -p $MONGODB_PASSWORD \
    --authenticationDatabase admin mongodb://mongo-replicaset-rs0/?replicaSet=rs0 \
    --eval 'db.adminCommand( { listDatabases: 1 } )'" > ${tmp_dir}/data-stack/mongo-databases-metrics.txt 2>&1
  if [ $? -ne 0 ]; then
    error "Fail to get mongoDB databases stats"
  else
    success "Get MongoDB databases stats"
  fi

  ${kube_bin} ${kubectl_opts} \
    run mongo-client -it --rm --restart='Never' \
    --env="MONGODB_PASSWORD=$MONGODB_PASSWORD" --image $MONGODB_CLIENT_IMAGE \
    -- bash -c "mongo -u maintenance -p $MONGODB_PASSWORD \
    --authenticationDatabase admin mongodb://mongo-replicaset-rs0/?replicaSet=rs0 \
    --eval 'var alldbs = db.getMongo().getDBNames(); \
    for(var j = 0; j < alldbs.length; j++){ \
    if(alldbs[j] != \"admin\"){ \
    var db = db.getSiblingDB(alldbs[j]); \
    var collections = db.getCollectionNames(); \
    for(var i = 0; i < collections.length; i++){ \
    var name = collections[i]; \
    var c = db.getCollection(name).count(); \
    print(db + \"  \" + name + \"    \" + c ); \
    }}}'" > ${tmp_dir}/data-stack/mongo-databases-documents.txt 2>&1
  if [ $? -ne 0 ]; then
    error "Fail to get MongoDB documents stats"
  else
    success "Get MongoDB documents stats"
  fi

  ${kube_bin} ${kubectl_opts} \
    get -o yaml kafkatopics.kafka.strimzi.io > ${tmp_dir}/data-stack/kafka-topics.yaml 2>&1
  if [ $? -ne 0 ]; then
    error "Fail to get kafka topic configuration"
  else
    success "Get kafka topic configuration"
  fi

  ${kube_bin} ${kubectl_opts} \
    run kafka-client -it --rm --restart='Never' \
    --image=quay.io/strimzi/kafka:0.32.0-kafka-3.3.1 \
    -- bin/kafka-consumer-groups.sh \
    --bootstrap-server kafka-cluster-kafka-bootstrap:9092 \
    --describe --all-groups > ${tmp_dir}/data-stack/kafka-consumer-groups.txt 2>&1
  if [ $? -ne 0 ]; then
    error "Fail to get kafka consumer groups stats"
  else
    success "Get Kafka Cluster stats"
  fi
}

audit_thingpark(){
  ${kube_bin} ${kubectl_opts} \
    run mariadb-client -it --rm --restart='Never' \
    --env="MARIADB_PASSWORD=$MARIADB_PASSWORD" --image $MARIADB_IMAGE \
    -- bash -c "mysqldump -h mariadb-galera -u root --password=$MARIADB_PASSWORD \
    --extended-insert --hex-blob \
    twa ProvisioningQueue CommandQueue FullProvisioningRequest" \
    > ${tmp_dir}/thingpark/twa-proc-cmd.sql
  if [ $? -ne 0 ]; then
    error "Fail to get Twa provisioning state"
  else
    success "Get Twa provisioning state"
  fi

  ${kube_bin} ${kubectl_opts} \
    exec -it deploy/pum -- \
    status > ${tmp_dir}/thingpark/pum-status.txt
  if [ $? -ne 0 ]; then
    error "Fail to get Post Upgrade Manager status"
  else
    success "Get Post Upgrade Manager status"
  fi

  ${kube_bin} ${kubectl_opts} \
    run mariadb-client -it --rm --restart='Never' \
    --env="MARIADB_PASSWORD=$MARIADB_PASSWORD" --image $MARIADB_IMAGE \
    -- bash -c "mysql -h mariadb-galera -u root --password=$MARIADB_PASSWORD \
    -e \"SELECT nextUpdate, issuerDN, ThisUpdate FROM ejbca.CRLData order by cRLNumber desc limit 10; \
    SELECT count(*) FROM ejbca.CRLData;\"" \
    > ${tmp_dir}/thingpark/pki-crl.sql
  if [ $? -ne 0 ]; then
    error "Fail to get Pki Crl state"
  else
    success "Get Pki Crl state"
  fi

  counter=1
  while [ $counter -ge 0 ]
  do
    ${kube_bin} ${kubectl_opts} \
      exec -it "lrc-${counter}" -c lrc -- curl http://127.0.0.1:8807/CLI/?cmd=info \
      > ${tmp_dir}/thingpark/lrc-${counter}-info.txt
    if [ $? -ne 0 ]; then
      error "Fail to get Lrc lrc-${counter} info"
    else 
      success "Get Lrc lrc-${counter} info"
    fi
    ${kube_bin} ${kubectl_opts} \
      exec -it "lrc-${counter}" -c lrc -- top -n1 -b \
      > ${tmp_dir}/thingpark/lrc-${counter}-top.txt
    if [ $? -ne 0 ]; then
      error "Fail to get Lrc lrc-${counter} top"
    else 
      success "Get Lrc lrc-${counter} top"
    fi

    ${kube_bin} ${kubectl_opts} \
      exec -it "lrc-${counter}" -c lrc  \
      -- bash -c 'cd /home/actility/FDB_lora/aEUI; \
      for i in $(grep xmlns ./ -ri | awk -F  ":" "{print \$1}" | awk -F "/"  "{print \$3}"); do \
      ret=$(ls -lh "/home/actility/FDB_lora/b/"$(echo $i | cut -c 14- |  sed -e "s/\(.*\)/\L\1/")"/"$(echo $i | sed -e "s/\(.*\)/\L\1/")); \
      if [ "$?" != 0 ]; then \
      echo "FAIL - $i  doesn t exist"; \
      elif [ $(echo $ret  |  awk "{print \$5}") = 0 ]; then \
      echo "EMPTY -  $i"; \
      fi; \
      done' > ${tmp_dir}/thingpark/lrc-${counter}-empty-tableB.txt;
      if [ $? -ne 0 ]; then
        error "Fail to check Lrc lrc-${counter} FDB Lora"
      else 
        success "Check Lrc lrc-${counter} FDB Lora"
      fi
    counter=$(( $counter - 1 ))
  done
  success "Get get Lrc info"


}

build_tarball(){
  mv ${output_dir}/tp-audit.log ${tmp_dir}/
  tar -C ${tmp_dir} -czf  ${output_dir}/${tarball_name} . 
  if [ $? -ne 0 ]; then
    panic "Fail to build tarball"
  else
    success "Build tarball"
  fi

  rm -r ${tmp_dir}

  info "Tarball to communicate to support: ${output_dir}/${tarball_name}"
}

#================================================
# MAIN
#================================================
main "${@}"
