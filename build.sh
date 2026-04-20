if [ ! -d "./jaylib/src" ]; then
    echo Please clone jaylib git submodule
    echo git submodule update --init --recursive or git clone --recurse-submodules
    exit 1
fi

(cd jaylib/raylib/src && make)

set -xe
cflags="-fPIC -shared"
cc -o jaylib.so $cflags ./jaylib/src/main.c ./jaylib/raylib/src/libraylib.a -I./jaylib/raylib/src
