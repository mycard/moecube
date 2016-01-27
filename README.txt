# build
npm install --prefix build1 --production glob ini mkdirp ws winreg windows-shortcuts
robocopy resources\win build1\bin\ *.exe *.dll
