#!/bin/bash

# ---------- startup ----------

sudo apt update && sudo apt upgrade && sudo apt autoremove && clear

echo "
▄▄▄█████▓ ██▓ ██ ▄█▀ ██▀███   ██▓▄▄▄█████▓
▓  ██▒ ▓▒▓██▒ ██▄█▒ ▓██ ▒ ██▒▓██▒▓  ██▒ ▓▒
▒ ▓██░ ▒░▒██▒▓███▄░ ▓██ ░▄█ ▒▒██▒▒ ▓██░ ▒░
░ ▓██▓ ░ ░██░▓██ █▄ ▒██▀▀█▄  ░██░░ ▓██▓ ░ 
  ▒██▒ ░ ░██░▒██▒ █▄░██▓ ▒██▒░██░  ▒██▒ ░ 
  ▒ ░░   ░▓  ▒ ▒▒ ▓▒░ ▒▓ ░▒▓░░▓    ▒ ░░   
    ░     ▒ ░░ ░▒ ▒░  ░▒ ░ ▒░ ▒ ░    ░    
  ░       ▒ ░░ ░░ ░   ░░   ░  ▒ ░  ░      
          ░  ░  ░      ░      ░           
"

# ---------- defaults ----------

if command -v lua &> /dev/null; then
    echo "lua already installed"
else
    echo "installing lua..."
    sudo apt install lua5.4
fi

if command -v make &> /dev/null; then
    echo "make already installed"
else
    echo "installing make..."
    sudo apt install make  
fi

if command -v love &> /dev/null; then
    echo "love2d already installed"
else
    echo "installing love2d..."
    sudo add-apt-repository ppa:bartbes/love-stable
    sudo apt update
    sudo apt install love
fi

echo "testing love2d installation"
echo -e 'function love.draw()\n\tlove.graphics.print("Your installation is functioning if you can see this!", 200, 200)\nend' >> test/main.lua
love test
echo "love2d installation validated"
rm test/main.lua

# ----------- end ----------

echo "tikrit setup finished"
