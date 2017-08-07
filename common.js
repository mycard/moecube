'use strict';
Object.defineProperty(exports, '__esModule', {value: true});
const webpack = require('webpack');
const path = require('path');
const glob_copy_webpack_plugin_1 = require('../../plugins/glob-copy-webpack-plugin');
const named_lazy_chunks_webpack_plugin_1 = require('../../plugins/named-lazy-chunks-webpack-plugin');
const utils_1 = require('./utils');
const ProgressPlugin = require('webpack/lib/ProgressPlugin');
const CircularDependencyPlugin = require('circular-dependency-plugin');

/**
 * Enumerate loaders and their dependencies from this file to let the dependency validator
 * know they are used.
 *
 * require('source-map-loader')
 * require('raw-loader')
 * require('script-loader')
 * require('json-loader')
 * require('url-loader')
 * require('file-loader')
 * require('@angular-devkit/build-optimizer')
 */
function getCommonConfig(wco) {
  const {projectRoot, buildOptions, appConfig} = wco;
  const appRoot = path.resolve(projectRoot, appConfig.root);
  const nodeModules = path.resolve(projectRoot, 'node_modules');
  let extraPlugins = [];
  let extraRules = [];
  let entryPoints = {};
  if (appConfig.main) {
    entryPoints['main'] = [path.resolve(appRoot, appConfig.main)];
  }
  if (appConfig.polyfills) {
    entryPoints['polyfills'] = [path.resolve(appRoot, appConfig.polyfills)];
  }
  // determine hashing format
  const hashFormat = utils_1.getOutputHashFormat(buildOptions.outputHashing);
  // process global scripts
  if (appConfig.scripts.length > 0) {
    const globalScripts = utils_1.extraEntryParser(appConfig.scripts, appRoot, 'scripts');
    // add entry points and lazy chunks
    globalScripts.forEach(script => {
      let scriptPath = `script-loader!${script.path}`;
      entryPoints[script.entry] = (entryPoints[script.entry] || []).concat(scriptPath);
    });
  }
  // process asset entries
  if (appConfig.assets) {
    extraPlugins.push(new glob_copy_webpack_plugin_1.GlobCopyWebpackPlugin({
      patterns: appConfig.assets,
      globOptions: {cwd: appRoot, dot: true, ignore: '**/.gitkeep'}
    }));
  }
  if (buildOptions.progress) {
    extraPlugins.push(new ProgressPlugin({profile: buildOptions.verbose, colors: true}));
  }
  if (buildOptions.showCircularDependencies) {
    extraPlugins.push(new CircularDependencyPlugin({
      exclude: /(\\|\/)node_modules(\\|\/)/
    }));
  }
  if (buildOptions.buildOptimizer) {
    extraRules.push({
      test: /\.js$/,
      use: [{
        loader: '@angular-devkit/build-optimizer/webpack-loader',
        options: {sourceMap: buildOptions.sourcemaps}
      }]
    });
  }
  if (buildOptions.namedChunks) {
    extraPlugins.push(new named_lazy_chunks_webpack_plugin_1.NamedLazyChunksWebpackPlugin());
  }
  return {
    target: 'electron-renderer',
    resolve: {
      extensions: ['.ts', '.js'],
      modules: ['node_modules', nodeModules],
      symlinks: !buildOptions.preserveSymlinks
    },
    resolveLoader: {
      modules: [nodeModules, 'node_modules']
    },
    context: __dirname,
    entry: entryPoints,
    output: {
      path: path.resolve(projectRoot, buildOptions.outputPath),
      publicPath: buildOptions.deployUrl,
      filename: `[name]${hashFormat.chunk}.bundle.js`,
      chunkFilename: `[id]${hashFormat.chunk}.chunk.js`
    },
    module: {
      rules: [
        {enforce: 'pre', test: /\.js$/, loader: 'source-map-loader', exclude: [nodeModules]},
        {test: /\.json$/, loader: 'json-loader'},
        {test: /\.html$/, loader: 'raw-loader'},
        {test: /\.(eot|svg)$/, loader: `file-loader?name=[name]${hashFormat.file}.[ext]`},
        {
          test: /\.(jpg|png|webp|gif|otf|ttf|woff|woff2|cur|ani)$/,
          loader: `url-loader?name=[name]${hashFormat.file}.[ext]&limit=10000`
        },
        {test: require.resolve('bootstrap'), use: 'imports-loader?jQuery=jquery,Tether=tether'},
        {test: require.resolve('candy/libs.bundle.js'), use: 'imports-loader?jQuery=jquery'},
        {test: require.resolve('candy/libs.bundle.js'), use: 'exports-loader?Mustache,Strophe,Base64,MD5'},
        {
          test: require.resolve('candy'),
          use: 'imports-loader?jQuery=jquery,{Mustache%2CStrophe%2CBase64%2CMD5}=candy/libs.bundle.js'
        },
        {test: require.resolve('candy'), use: 'exports-loader?Candy'},
        {test: require.resolve('candy-shop/me-does/candy.js'), use: 'imports-loader?jQuery=jquery,Candy=candy'},
        {test: require.resolve('candy-shop/me-does/candy.js'), use: 'exports-loader?CandyShop.MeDoes'},
        {test: require.resolve('candy-shop/modify-role/candy.js'), use: 'imports-loader?jQuery=jquery,Candy=candy'},
        {test: require.resolve('candy-shop/modify-role/candy.js'), use: 'exports-loader?CandyShop.ModifyRole'},
        {test: require.resolve('candy-shop/namecomplete/candy.js'), use: 'imports-loader?jQuery=jquery,Candy=candy'},
        {test: require.resolve('candy-shop/namecomplete/candy.js'), use: 'exports-loader?CandyShop.NameComplete'},
        {test: require.resolve('candy-shop/notifications/candy.js'), use: 'imports-loader?jQuery=jquery,Candy=candy'},
        {test: require.resolve('candy-shop/notifications/candy.js'), use: 'exports-loader?CandyShop.Notifications'},
        {test: require.resolve('candy-shop/notifyme/candy.js'), use: 'imports-loader?jQuery=jquery,Candy=candy'},
        {test: require.resolve('candy-shop/notifyme/candy.js'), use: 'exports-loader?CandyShop.NotifyMe'},
        {test: require.resolve('candy-shop/refocus/candy.js'), use: 'imports-loader?jQuery=jquery,Candy=candy'},
        {test: require.resolve('candy-shop/refocus/candy.js'), use: 'exports-loader?CandyShop.Refocus'}
      ].concat(extraRules)
    },
    plugins: [
      new webpack.NoEmitOnErrorsPlugin()
    ].concat(extraPlugins),
    node: {
      fs: 'empty',
      // `global` should be kept true, removing it resulted in a
      // massive size increase with Build Optimizer on AIO.
      global: true,
      crypto: 'empty',
      tls: 'empty',
      net: 'empty',
      process: true,
      module: false,
      clearImmediate: false,
      setImmediate: false
    },
    externals: {
      bufferutil: "require('bufferutil')",
      'utf-8-validate': "require('utf-8-validate')",
      iconv: "require('iconv')",
      'iconv-loader': "require('iconv')",
    }
  };
}

exports.getCommonConfig = getCommonConfig;
//# sourceMappingURL=/users/hansl/sources/angular-cli/models/webpack-configs/common.js.map
