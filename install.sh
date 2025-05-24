#!/bin/bash

dir="$(cd $(dirname $0) && pwd -P)"

# .claudeディレクトリが存在しない場合は作成する
[ ! -d $HOME/.claude ] && mkdir -p $HOME/.claude

# CLAUDE.mdのシンボリックリンクを作成する
ln -snf $dir/.claude/CLAUDE.md $HOME/.claude/CLAUDE.md

for f in $dir/.??*; do
  filename=`basename $f`
  [[ `basename $f` = ".git" ]] && continue
  [[ `basename $f` = ".claude" ]] && continue

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
