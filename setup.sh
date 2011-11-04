#/bin/bash

DEPS='dlib|git@github.com:trifork/dlib.git'

if [ ! -d deps ]; then
    mkdir deps
fi

cd deps

for DEPANDURL in $DEPS; do

  DEP=`echo $DEPANDURL | awk '-F|' '{print $1}'`
  URL=`echo $DEPANDURL | awk '-F|' '{print $2}'`

  if [ ! -d $DEP ]; then
      git clone $URL $DEP
  else
      (cd $DEP; git pull)
  fi

  rm -Rf ../$DEP
  cp -R $DEP/src ../$DEP
  chmod -R a-w  ../$DEP

done

