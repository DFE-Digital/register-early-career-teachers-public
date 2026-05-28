#!/bin/bash

echo "Setting SSH password for vscode user..."
sudo usermod --password $(echo vscode | openssl passwd -1 -stdin) vscode

echo "Updating RubyGems..."
sudo gem update --system

echo "Installing foreman and bundler"
sudo gem install foreman bundler solargraph

echo "Setting up app..."
bin/setup

echo "Done!"
