#!/usr/bin/env bash

readonly DIR_MIRACUM="/opt/MIRACUM-Pipe"
readonly SCRIPTPATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

function join_by { local IFS="$1"; shift; echo "$*"; }

function usage() {
  singularity exec $1 "${DIR_MIRACUM}"/miracum_pipe.sh -h
  echo ""
  echo "additional optional flags:"
  echo "  -n                    singularity image file (default is miracum-pipe-sl.sif)"
  exit 1
}

IMAGE_FILE="${SCRIPTPATH}/miracum-pipe-sl.sif"
readonly VALID_PROTOCOLS=("wes panel tumorOnly")

while getopts t:p:d:n:fsh option; do
  case "${option}" in
  t) readonly PARAM_TASK=$OPTARG;;
  p) readonly PARAM_PROTOCOL=$OPTARG;;
  f) readonly PARAM_FORCED=true;;
  d) readonly PARAM_DIR_PATIENT=$OPTARG;;
  s) readonly PARAM_SEQ=true;;
  n) IMAGE_FILE=$OPTARG;;
  h) readonly SHOW_USAGE=true;;
   \?)
    echo "Unknown option: -$OPTARG" >&2
    exit 1
    ;;
  :)
    echo "Missing option argument for -$OPTARG" >&2
    exit 1
    ;;
  *)
    echo "Unimplemented option: -$OPTARG" >&2
    exit 1
    ;;
  esac
done

[[ "${SHOW_USAGE}" ]] && usage "${IMAGE_FILE}"

if [[ ! -z "${PARAM_PROTOCOL}" ]]; then
  if [[ ! " ${VALID_PROTOCOLS[@]} " =~ " ${PARAM_PROTOCOL} " ]]; then
    echo "unknown protocol: ${PARAM_PROTOCOL}"
    echo "use one of the following values: $(join_by ' ' ${VALID_PROTOCOLS})"
    exit 1
  fi
elif [[ -z "${PARAM_PROTOCOL}" ]]; then
  echo "no protocol specified!"
  exit 1
fi

# call script
if [[ "${PARAM_FORCED}" ]]; then
  opt_args='-f'
fi

if [[ "${PARAM_TASK}" ]]; then
  opt_args="${opt_args} -t ${PARAM_TASK}"
fi

if [[ "${PARAM_PROTOCOL}" ]]; then
  opt_args="${opt_args} -p ${PARAM_PROTOCOL}"
fi

if [[ "${PARAM_SEQ}" ]]; then
  opt_args="${opt_args} -s"
fi

if [[ "${PARAM_DIR_PATIENT}" ]]; then
  opt_args="${opt_args} -d ${PARAM_DIR_PATIENT}"
fi

export SINGULARITYENV_CUSTOMCONFIGFILE=${SCRIPTPATH}/conf/custom.yaml
export SINGULARITYENV_INPUTPATH=$(pwd)/assets/input
export SINGULARITYENV_OUTPUTPATH=$(pwd)/assets/output
export SINGULARITYENV_REFERENCESPATH=${SCRIPTPATH}/assets/references
export SINGULARITYENV_DATABASEPATH=${SCRIPTPATH}/databases
export SINGULARITYENV_ANNOVARPATH=${SCRIPTPATH}/tools/annovar
export SINGULARITYENV_GATKPATH=${SCRIPTPATH}/tools/gatk
export SINGULARITYENV_OPTARGS=${opt_args}

echo "running \"${DIR_MIRACUM}/miracum_pipe.sh ${opt_args}\" of image ${IMAGE_FILE}"
echo "---"
singularity run --writable-tmpfs ${IMAGE_FILE}
