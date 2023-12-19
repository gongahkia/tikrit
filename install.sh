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

if command -v gcc &> /dev/null; then
    echo "gcc already installed"
else
    echo "installing gcc..."
    sudo apt install gcc
fi

if command -v make &> /dev/null; then
    echo "make already installed"
else
    echo "installing make..."
    sudo apt install make  
fi

# ---------- install raylib ----------

echo "checking raylib installation"
echo "creating test program for compilation..."
echo -e '#include <raylib.h>\nint main() { InitWindow(800, 600, "Raylib Test"); while (!WindowShouldClose()) {} CloseWindow(); return 0; }' > test/test.c
gcc -o test/test test/test.c -lraylib -ldl -lpthread -lm -lX11 || {
    echo "installing raylib..."
    sudo apt install libasound2-dev libx11-dev libxrandr-dev libxi-dev libgl1-mesa-dev libglu1-mesa-dev libxcursor-dev libxinerama-dev    
    cd ~
    git clone https://github.com/raysan5/raylib.git raylib
    cd raylib/src/
    make PLATFORM=PLATFORM_DESKTOP
    make clean
    sudo make install
    echo "raylib installed"
    gcc -o test/test test/test.c -lraylib -ldl -lpthread -lm -lX11
}
if [ $? -eq 0 ]; then
    echo "raylib compilation succesful"
    rm test/test.c test/test
else
    echo "raylib compilation failed"
    echo "please check your raylib installation"
    rm test/test.c test/test
fi

# ----------- end ----------

echo "setup finished"
