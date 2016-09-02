## install dependencies
npm install

## build
codesign -f -s 'Developer ID Application: XIAOCHI CHEN (ZNVDEVDRX3)' --deep /Users/zh99998/Perforce/TH-TDOG/TH-TDOG-Game/TH-TDOG.app
mv /Users/zh99998/Perforce/TH-TDOG/TH-TDOG-Game/TH-TDOG.app ./
npm run tsc
npm run dist

## debug
electron .

