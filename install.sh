#!/bin/bash

dir="$(cd $(dirname $0) && pwd -P)"

# .claudeディレクトリが存在しない場合は作成する
[ ! -d $HOME/.claude ] && mkdir -p $HOME/.claude

# CLAUDE.mdのシンボリックリンクを作成する
ln -snf $dir/.claude/CLAUDE.md $HOME/.claude/CLAUDE.md

# settings.jsonのシンボリックリンクを作成する
ln -snf $dir/.claude/settings.json $HOME/.claude/settings.json

# hooksディレクトリのシンボリックリンクを作成する
ln -snf $dir/.claude/hooks $HOME/.claude/hooks

# skillsディレクトリのシンボリックリンクを作成する
ln -snf $dir/.claude/skills $HOME/.claude/skills

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
