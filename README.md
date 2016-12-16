# MyCard [![Build Status](https://travis-ci.org/mycard/mycard.svg?branch=v3)](https://travis-ci.org/mycard/mycard) [![Build status](https://ci.appveyor.com/api/projects/status/t4jyh0rkwh0nep7w?svg=true)](https://ci.appveyor.com/project/zh99998/mycard) [![NSP Status](https://nodesecurity.io/orgs/mycard/projects/62dd15a6-3927-49c2-8c30-1bc19d4a6e92/badge)](https://nodesecurity.io/orgs/mycard/projects/62dd15a6-3927-49c2-8c30-1bc19d4a6e92)

## Install Dependencies
```bash
npm install
```

## Build
```bash
npm run tsc
npm run dist
```

## Debug
```bash
./node_modules/.bin/electron .
```


## Install Dependencies (macOS)
```bash
mkdir -p bin
curl --location --retry 5 https://github.com/aria2/aria2/releases/download/release-1.29.0/aria2-1.29.0-osx-darwin.tar.bz2 | tar --strip-components=2 -C bin -jxf - aria2-1.29.0/bin/aria2c
```

## Install Dependencies (Windows)
```bash
mkdir -p bin
curl --location --retry 5 --output aria2-1.29.0-win-32bit-build1.zip https://github.com/aria2/aria2/releases/download/release-1.29.0/aria2-1.29.0-win-32bit-build1.zip
unzip -o aria2-1.29.0-win-32bit-build1.zip aria2-1.29.0-win-32bit-build1/aria2c.exe
mv aria2-1.29.0-win-32bit-build1/aria2c.exe bin
rm -rf aria2-1.29.0-win-32bit-build1 aria2-1.29.0-win-32bit-build1.zip
curl -L 'http://downloads.sourceforge.net/project/msys2/REPOS/MSYS2/i686/bsdtar-3.2.1-1-i686.pkg.tar.xz' | tar --strip-components=2 -C bin -Jxf - usr/bin/bsdtar.exe
curl -L 'http://downloads.sourceforge.net/project/msys2/Base/i686/msys2-base-i686-20161025.tar.xz' | tar --strip-components=3 -C bin -Jxf - msys32/usr/bin/msys-2.0.dll msys32/usr/bin/msys-bz2-1.dll msys32/usr/bin/msys-gcc_s-1.dll msys32/usr/bin/msys-iconv-2.dll msys32/usr/bin/msys-lzma-5.dll msys32/usr/bin/msys-lzo2-2.dll msys32/usr/bin/msys-nettle-6.dll msys32/usr/bin/msys-xml2-2.dll msys32/usr/bin/msys-z.dll msys32/usr/bin/sha256sum.exe msys32/usr/bin/msys-intl-8.dll
```