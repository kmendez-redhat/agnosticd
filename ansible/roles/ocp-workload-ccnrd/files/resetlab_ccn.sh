#!/bin/bash
#
# Prereqs: a running ocp 4 cluster, logged in as kubeadmin
#
MYDIR="$( cd "$(dirname "$0")" ; pwd -P )"
function usage() {
    echo "usage: $(basename $0)"
}
# Defaults
USERCOUNT=3

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -c|--count)
    USERCOUNT="$2"
    shift # past argument
    shift # past value
    ;;
    *)    # unknown option
    echo "Unknown option: $key"
    usage
    exit 1
    ;;
esac
done

if [ ! "$(oc get clusterrolebindings)" ] ; then
  echo "not cluster-admin"
  exit 1
fi

# Remove view role of default namespace to all userXX
for i in $(eval echo "{0..$USERCOUNT}") ; do
  oc adm policy remove-role-from-user view user$i -n default
  echo -n .
  sleep 2
done

oc delete project labs-infra
oc delete template coolstore-monolith-binary-build coolstore-monolith-pipeline-build ccn-sso72 -n openshift
oc delete CatalogSourceConfig/installed-redhat-che -n openshift-marketplace

# delete user projects
for proj in $(oc get projects -o name | grep 'user*' | cut -d/ -f2) ; do
  oc delete project $proj
done

# delete dummy projects
for proj in $(oc get projects -o name | grep 'dummy*' | cut -d/ -f2) ; do
  oc delete project $proj
done

# delete json files
rm -rf *.json
