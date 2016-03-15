## Build
### Windows

```bash
del /s /q build1
npm install --prefix build1\win32-ia32 --production glob ini mkdirp ws aria2 winreg windows-shortcuts
xcopy /S /Y /I build1\win32-ia32 build1\win32-x64
robocopy resources\win build1\win32-ia32\bin\ *.exe *.dll
robocopy resources\win build1\win32-x64\bin\ *.exe *.dll
robocopy resources\win32 build1\win32-ia32\bin\ *.exe *.dll
robocopy resources\win64 build1\win32-x64\bin\ *.exe *.dll
grunt
```

### OSX

```bash
npm install --prefix build1 --production glob ini mkdirp ws aria2
grunt
```

### LINUX (DEBIAN&UBUNTU)

```bash
npm install grunt-cli -g
npm install --prefix build1 --production glob ini mkdirp ws aria2
npm install

grunt
```
