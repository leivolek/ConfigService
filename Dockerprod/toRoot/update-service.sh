#!/bin/bash
# Script to download deployment unit from a Maven artifact repository.

version=0.4-alpha2
source config_override/service_override.properties # this might override version to download

releaseRepo=http://mvnrepo.cantara.no/content/repositories/releases
snapshotRepo=http://mvnrepo.cantara.no/content/repositories/snapshots
groupId=no/cantara/jau
artifactId=configservice

if [[ $version == *SNAPSHOT* ]]; then
   echo Note: If the artifact version contains "SNAPSHOT", the latest snapshot version is downloaded, ignoring the version before SNAPSHOT.
   path="$snapshotRepo/$groupId/$artifactId"
   version=`curl $curlAuth -s "$path/maven-metadata.xml" | grep "<version>" | sed "s/.*<version>\([^<]*\)<\/version>.*/\1/" | tail -n 1`
   echo "Found version=$version from metadata $path/maven-metadata.xml"
   build=`curl $curlAuth -s "$path/$version/maven-metadata.xml" | grep '<value>' | head -1 | sed "s/.*<value>\([^<]*\)<\/value>.*/\1/"`
   jarfile="$artifactId-$build.jar"
   url="$path/$version/$jarfile"
else #A specific Release version
   path="$releaseRepo/$groupId/$artifactId"
   url=$path/$version/$artifactId-$version.jar
   jarfile=$artifactId-$version.jar
fi

shaUrl=$url.sha1
shaFromWeb=$(wget $shaUrl -q -O -)
if [ -f $APP ]; then
  localSha=$(sha1sum $jarfile | awk '{print $1}')
else
  echo "No local app file found"
  localSha=-1
fi

if [ "$shaFromWeb" == "$localSha" ]; then
  echo "Already got newest version. Not doing anything."
else
  echo Downloading $url
  wget -O $jarfile -q -N $url

  # Create symlink or replace existing sym link
  if [ -h $artifactId.jar ]; then
     unlink $artifactId.jar
  fi
  ln -s $jarfile $artifactId.jar

  # Delete old jar files
  jar=$artifactId*.jar
  nrOfJarFilesToDelete=`ls $jar -A1t | tail -n +6 | wc -l`
  if [[ $nrOfJarFilesToDelete > 0 ]]; then
      echo Deleting $nrOfJarFilesToDelete old jar files. Keep the 4 newest + the symlink.
      ls $jar -A1t | tail -n +6 | xargs rm
  fi

fi