#!/bin/bash

if command -v node &> /dev/null; then
    echo "Node.js is installed."
    node --version
else
    echo "Node.js is not installed. Installing now".
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    source ~/.bashrc
    nvm install 20.10.0
fi
