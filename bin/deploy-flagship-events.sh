#!/usr/bin/env bash
#
# deploy-flagship-events.sh is used to deploy the flagship-events pipeline to a given environment

SCRIPT_ROOT=$(dirname "${BASH_SOURCE[0]}")/..

usage() {
  echo 1>&2 "usage: $(basename $0) [options]"
  echo 1>&2 ""
  echo 1>&2 "    --help    display usage"
  echo 1>&2 "    --env     environment to work with, default is intg"
  echo 1>&2 "    --verify  verify local config matches cluster, do not apply any changes"
  exit 1
}

main() {
  if [[ "${DEBUG}" == "1" ]]; then
    echo "debuging enabled"
    set -x
  fi

  set -o errexit
  set -o pipefail
  trap 'echo "error on line ${LINENO}"' ERR

  ENVIRONMENT=intg
  DATAFLOW_RELEASE_TAG=$(<DATAFLOW_RELEASE_TAG)

  ARGUMENTS=()
  while (( $# > 0 )); do
    key=$1
    case $key in
      --help| -h )
        usage
        ;;
      --env )
        ENVIRONMENT=$2
        shift
        shift
        ;;
      --verify )
        VERIFY=true
        shift
        ;;
      --clean )
        CLEAN=true
        shift
        ;;
      * )
        ARGUMENTS+=("$1")
        shift
        ;;
    esac
  done
  set -- "${ARGUMENTS[@]}"

  if ! [[ "${ENVIRONMENT}" =~ ^(intg|stge|prod)$ ]]; then
    echo "error: unknown environment '${ENVIRONMENT}'"
    exit 1
  fi

  gcloud config set project "is-events-dataflow-${ENVIRONMENT}"

  if ! test -f ~/.config/gcloud/application_default_credentials.json; then
    gcloud auth application-default login
  fi

  if [[ ${CLEAN} ]] || [ ! -d "upstream" ]; then
    echo "Cloning"
    rm -rf upstream
    git clone --depth 1 --branch "${DATAFLOW_RELEASE_TAG}" --single-branch https://github.com/GoogleCloudPlatform/DataflowTemplates.git upstream
    CLEAN=true
  else
    echo "Cloned repo exists"
    cd upstream
    # Reset the pom so we can add the modules again in case any new ones were added
    git restore v2/pom.xml
    cd ..
  fi

  # Add our modules to the cloned repo
  cp -rf v2/* upstream/v2

  find ./v2 -mindepth 1 -maxdepth 1 \( ! -name '.*' \) -type d -printf '<module>%P</module>\n' > MODULES
  MODULE_ARRAY=$(find ./v2 -mindepth 1 -maxdepth 1 \( ! -name '.*' \) -type d)

  awk 'NR==FNR {replace = replace $0 RS; next}
      {text = text $0 RS}
      END {
          print gensub(/<\/modules>/, replace "&", "g", text)
      }' MODULES upstream/v2/pom.xml > UPDATED_V2_POM

  mv UPDATED_V2_POM upstream/v2/pom.xml

  rm MODULES

  cd upstream

  # Just to alleviate pain from having mis-formatted files fail to build, spotless the modules
  for dir in $MODULE_ARRAY; do (mvn spotless:apply -pl "$dir"); done

  # Build the uber jar if necessary or not built before
  if [[ ${CLEAN} ]]; then
    echo "Uber Jar build started"
    mvn clean package -Dmaven.test.skip=true
  fi

  ###------------flagship-events--------------------

  # Build flagship-events
  mvn clean package -pl v2/flagship-events -am

  gcloud dataflow flex-template build "gs://is-events-dataflow-${ENVIRONMENT}/templates/flagship-events.json" \
    --image-gcr-path "us-west1-docker.pkg.dev/is-events-dataflow-${ENVIRONMENT}/dataflow/flagship-events:latest" \
    --sdk-language "JAVA" \
    --flex-template-base-image JAVA11 \
    --metadata-file "v2/flagship-events/metadata.json" \
    --jar "v2/flagship-events/target/flagship-events-1.0-SNAPSHOT.jar" \
    --jar "v2/flagship-events/target/extra_libs/conscrypt-openjdk-uber.jar" \
    --env FLEX_TEMPLATE_JAVA_MAIN_CLASS="com.keap.dataflow.flagshipevents.FlagshipEventsPubsubToBigQuery"

  gcloud dataflow flex-template run "flagshipevents-`date +%Y%m%d-%H%M%S`" \
    --template-file-gcs-location "gs://is-events-dataflow-${ENVIRONMENT}/templates/flagship-events.json" \
    --parameters env="${ENVIRONMENT}" \
    --parameters maxNumWorkers="9" \
    --parameters numWorkers="1" \
    --parameters workerMachineType="n1-standard-1" \
    --region "us-east1" \
    --service-account-email "is-events-dataflow-${ENVIRONMENT}@is-events-dataflow-${ENVIRONMENT}.iam.gserviceaccount.com"

  ###------------flagship-events--------------------

  cd ..
}

main "$@"
