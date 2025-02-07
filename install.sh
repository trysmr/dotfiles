#!/bin/bash

dir="$(cd $(dirname $0) && pwd -P)"

for f in $dir/.??*; do
  filename=`basename $f`
  [[ `basename $f` = ".git" ]] && continue

  # .configの場合はディレクトリを対象にする
  if [ $filename = ".config" ]; then
    # .configディレクトリが存在しない場合は作成する
    [ ! -d $HOME/.config ] && mkdir -p $HOME/.config

    for config in $dir/$filename/*; do
      configname=`basename $config`
      ln -snf $config $HOME/.config
    done
    continue
  fi

  ln -snf $dir/$filename $HOME
done
