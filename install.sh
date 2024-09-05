#!/bin/bash

dir="$(cd $(dirname $0) && pwd -P)"

for f in $dir/.??*; do
  filename=`basename $f`
  [[ `basename $f` = ".git" ]] && continue

  ln -snf $dir/$filename $HOME
done
