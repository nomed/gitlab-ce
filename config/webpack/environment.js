const { environment } = require('@rails/webpacker');

// custom GitLab config
const gitlabConfig = require('./gitlab');
environment.config.merge(gitlabConfig);

// custom webpack Plugins
const { VueLoaderPlugin } = require('vue-loader');
const { StatsWriterPlugin } = require('webpack-stats-plugin');
const CompressionPlugin = require('compression-webpack-plugin');
const MonacoWebpackPlugin = require('monaco-editor-webpack-plugin');
const { BundleAnalyzerPlugin } = require('webpack-bundle-analyzer');

custom_plugins = [
  // manifest filename must match config.webpack.manifest_filename
  // webpack-rails only needs assetsByChunkName to function properly
  new StatsWriterPlugin({
    filename: 'manifest.json',
    transform: function(data, opts) {
      const stats = opts.compiler.getStats().toJson({
        chunkModules: false,
        source: false,
        chunks: false,
        modules: false,
        assets: true,
      });
      return JSON.stringify(stats, null, 2);
    },
  }),
];

module.exports = environment;
