#!/bin/bash

echo 'installing paperbennis personal dotfiles'
cd dotfiles || exit 1
instantinstall rsync
command -v rsync &> /dev/null || exit 1
rsync -a -r ./ ~/
echo "finished installing paperbenni's dotfiles"

