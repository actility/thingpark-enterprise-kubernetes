#!/bin/bash
set -o nounset
set -o pipefail

#================================================
# VARIABLES
#================================================
helm_bin=helm
helm_opts=""
yq_bin=yq

# git_repository=https://raw.githubusercontent.com/actility/thingpark-enterprise-kubernetes
# git_ref=main

helm_repository_ref=actility

output_dir="."

SCRIPT=$(readlink -f $0)
SCRIPT_PATH=`dirname $SCRIPT`

manifest_path=$SCRIPT_PATH/../VERSIONS

red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
reset=$(tput sgr0)

#================================================
# FUNCTIONS
#================================================

main() {

  process_options "${@}"
  check_prerequisites
  get_release_container_images
  
}

usage(){
    echo "ThingPark Kubernetes container manifest builder"
    echo ""
cat << EOF
Usage: ${0##*/} [-r helm_repository_id]
Options:
       -h: show this help
       -r | --repository: The Helm repository id to use
EOF
}

error() {
  (( error_counter++ ))
  printf "${red}$(date): [error]: %s${reset}\\n" "${*}" 1>&2
}

panic() {
  error "${*}"
  exit 1
}

warn() {
  printf "${yellow}$(date): [warning]: %s${reset}\\n" "${*}" 1>&2
}

info() {
  printf "$(date): [info]: %s\\n" "${*}" 1>&2
}

success() {
  printf "${green}$(date): [success]: %s${reset}\\n" "${*}" 1>&2
}

process_options(){

  while (( "$#" )); do
    case "$1" in
      -h | --help)
        usage
        exit 0
        ;;
      -r | --helm-repo)
        helm_repository_ref="${2}"
        shift
        shift
        ;;
      *)
        usage
        error "Unknown parameter \"${1}\""
        ;;
    esac
  done
}

get_release_container_images(){

  source $manifest_path

  #eval $(curl ${git_repository}/${git_ref}/VERSIONS 2>/dev/null)
  declare -A helm_chart_list=( ["thingpark-data-controllers"]="$THINGPARK_DATA_CONTROLLERS_VERSION"
                               ["thingpark-data"]="$THINGPARK_DATA_VERSION"
                               ["thingpark-application-controllers"]="$THINGPARK_APPLICATION_CONTROLLERS_VERSION"
                               ["thingpark-enterprise"]="$THINGPARK_ENTERPRISE_VERSION"
                              )

  image_list=""
  for chart in "${!helm_chart_list[@]}"
  do
    echo "Get $chart-${helm_chart_list[$chart]} container images"
    image_list+=$(helm template release ${helm_repository_ref}/$chart \
         --version ${helm_chart_list[$chart]} \
         --set global.installationId=000000000000000000000000000 \
        | yq '..|.image? | select(.)'| sort -u | tail -n +2 )
    image_list+=" "    
  done
  echo "Images:"
  echo $image_list | sed 's/ /\n/g' | tee  ${output_dir}/container-manifest.txt

  info "Image list put in ${output_dir}/container-manifest.txt"

}

check_prerequisites(){
  info "Check Work Station prerequisites"

  for cmd in "${helm_bin}" "jq" "yq"
  do
    if ! command -v ${cmd} &> /dev/null; then
        panic "${cmd} binary is required"
    fi
  done


  info "Check Helm Configuration"

  repo_exists=$(${helm_bin} repo list -o json| jq -r --arg helm_repository_ref "$helm_repository_ref" '.[]|select(.name == $helm_repository_ref)|.name')
  if [ "${repo_exists}" == "" ]; then
    panic "No ${helm_repository_ref} Helm Repository Found. Please configure repository using helm repo add actility https://repository.thingpark.com/charts."
  fi

}

#================================================
# MAIN
#================================================
main "${@}"
