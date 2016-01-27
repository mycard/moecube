## Build
### Windows
```bash
npm install --prefix build1 --production glob ini mkdirp ws winreg windows-shortcuts
robocopy resources\win32 build1\bin\ *.exe *.dll
grunt
```

### OSX
```bash
npm install --prefix build1 --production glob ini mkdirp ws
grunt
```