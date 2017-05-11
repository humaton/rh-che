export OPENSHIFT_ENDPOINT="https://$(minishift ip):8443/"
export OPENSHIFT_USERNAME="developer"
export OPENSHIFT_PASSWORD="developer"
export CHE_OPENSHIFT_PROJECT="eclipse-che"
export OPENSHIFT_NAMESPACE_URL="${CHE_OPENSHIFT_PROJECT}.$(minishift ip).nip.io"
export CHE_LOG_LEVEL="DEBUG"
export CHE_DEBUGGING_ENABLED="true"
export FABRIC8_ONLINE_PATH=${FABRIC8_ONLINE_PATH:-"${HOME}/github/fabric8-online/"}
