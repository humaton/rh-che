#!/bin/bash

currentDir=`pwd`

. config 

source target/upstreamCheRepository.env
RH_CHE_TAG=$(git rev-parse --short HEAD)

cd ${upstreamCheRepository}
upstreamCheRepoFullPath=`pwd`
UPSTREAM_TAG=$(git rev-parse --short HEAD)

# Now lets build the local docker images
mkdir ${currentDir}/target/docker
cp -R dockerfiles ${currentDir}/target/docker

cd ${currentDir}/target/docker/dockerfiles/che
cat Dockerfile.centos > Dockerfile

distPath='assembly/assembly-main/target/eclipse-che-*.tar.gz'
for distribution in `ls -1 ${upstreamCheRepoFullPath}/${distPath}; ls -1 ${currentDir}/target/builds/fabric8*/fabric8-che/${distPath};`
do
  case "$distribution" in
    ${currentDir}/target/builds/fabric8-${RH_NO_DASHBOARD_SUFFIX}/fabric8-che/assembly/assembly-main/target/eclipse-che-*-${RH_DIST_SUFFIX}-${RH_NO_DASHBOARD_SUFFIX}*)
      TAG=${UPSTREAM_TAG}-${RH_DIST_SUFFIX}-no-dashboard-${RH_CHE_TAG}
      NIGHTLY=nightly-${RH_DIST_SUFFIX}-no-dashboard
      ;;
    ${currentDir}/target/builds/fabric8/fabric8-che/assembly/assembly-main/target/eclipse-che-*-${RH_DIST_SUFFIX}*)
      TAG=${UPSTREAM_TAG}-${RH_DIST_SUFFIX}-${RH_CHE_TAG}
      NIGHTLY=nightly-${RH_DIST_SUFFIX}
      ;;
    ${upstreamCheRepoFullPath}/assembly/assembly-main/target/eclipse-che-*)
      TAG=${UPSTREAM_TAG}
      NIGHTLY=nightly
      ;;
  esac
      
  rm ../../assembly/assembly-main/target/eclipse-che-*.tar.gz
  mkdir -p ../../assembly/assembly-main/target
  cp ${distribution} ../../assembly/assembly-main/target

  bash ./build.sh
  if [ $? -ne 0 ]; then
    echo 'Docker Build Failed'
    exit 2
  fi
  
  # lets change the tag and push it to the registry
  
  docker tag eclipse/che-server:nightly ${DOCKER_HUB_NAMESPACE}/che-server:${NIGHTLY}
  
  if [ $DeveloperBuild != "true" ]
  then
    docker tag eclipse/che-server:nightly ${DOCKER_HUB_NAMESPACE}/che-server:${TAG}
    docker login -u ${DOCKER_HUB_USER} -p $DOCKER_HUB_PASSWORD -e noreply@redhat.com 
    
    # We are not pushing the nightly tag because we don't need it and CI has an issue
    # when publishing > 1 tag at a time 
    # docker push ${DOCKER_HUB_NAMESPACE}/che-server:${NIGHTLY}
    echo 'export CHE_SERVER_DOCKER_IMAGE_TAG='${TAG} >> ~/che_image_tag.env
    docker push ${DOCKER_HUB_NAMESPACE}/che-server:${TAG}
    
    if [ "${DOCKER_HUB_USER}" == "${RHCHEBOT_DOCKER_HUB_USER}" ]; then
    # lets also push it to registry.devshift.net
      docker tag ${DOCKER_HUB_NAMESPACE}/che-server:${NIGHTLY} registry.devshift.net/che/che:${NIGHTLY}
      docker tag ${DOCKER_HUB_NAMESPACE}/che-server:${NIGHTLY} registry.devshift.net/che/che:${TAG}
      # We are not pushing the nightly tag because we don't need it and CI has an issue
      # when publishing > 1 tag at a time 
      #docker push registry.devshift.net/che/che:${NIGHTLY}
      if [ ${TAG} == "*-no-dashboard*" ]
      then
        # We are not pushing the the no-dashboard tag because CI has an issue
        # when publishing > 1 tag at a time 
        continue
      fi

      if [ ${TAG} == "${UPSTREAM_TAG}" ]
      then
        # We are not pushing the the upstream tag because CI has an issue
        # when publishing > 1 tag at a time 
        continue
      fi
      
      docker push registry.devshift.net/che/che:${TAG}
      
    fi
  fi
done
