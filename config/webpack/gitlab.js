const path = require('path');
const glob = require('glob');



const ROOT_PATH = path.resolve(__dirname, '..');
const IS_EE = require('./helpers/is_ee_env');
const VUE_VERSION = require('vue/package.json').version;
const VUE_LOADER_VERSION = require('vue-loader/package.json').version;

const alias = {
  '~': path.join(ROOT_PATH, 'app/assets/javascripts'),
  emojis: path.join(ROOT_PATH, 'fixtures/emojis'),
  empty_states: path.join(ROOT_PATH, 'app/views/shared/empty_states'),
  icons: path.join(ROOT_PATH, 'app/views/shared/icons'),
  images: path.join(ROOT_PATH, 'app/assets/images'),
  vendor: path.join(ROOT_PATH, 'vendor/assets/javascripts'),
  vue$: 'vue/dist/vue.esm.js',
  spec: path.join(ROOT_PATH, 'spec/javascripts'),

  // the following resolves files which are different between CE and EE
  ee_else_ce: path.join(ROOT_PATH, 'app/assets/javascripts'),
};

if (IS_EE) {
  Object.assign(alias, {
    ee: path.join(ROOT_PATH, 'ee/app/assets/javascripts'),
    ee_empty_states: path.join(ROOT_PATH, 'ee/app/views/shared/empty_states'),
    ee_icons: path.join(ROOT_PATH, 'ee/app/views/shared/icons'),
    ee_images: path.join(ROOT_PATH, 'ee/app/assets/images'),
    ee_spec: path.join(ROOT_PATH, 'ee/spec/javascripts'),
    ee_else_ce: path.join(ROOT_PATH, 'ee/app/assets/javascripts'),
  });
}

module.exports = {
  // resolve
  resolve: {
    alias,
  },

  // module
  module: {
    strictExportPresence: true,
    rules: [
      {
        type: 'javascript/auto',
        test: /\.mjs$/,
        use: [],
      },
      {
        test: /\.js$/,
        exclude: path => /node_modules|vendor[\\/]assets/.test(path) && !/\.vue\.js/.test(path),
        loader: 'babel-loader',
        options: {
          cacheDirectory: path.join(CACHE_PATH, 'babel-loader'),
        },
      },
      {
        test: /\.vue$/,
        loader: 'vue-loader',
        options: {
          cacheDirectory: path.join(CACHE_PATH, 'vue-loader'),
          cacheIdentifier: [
            process.env.NODE_ENV || 'development',
            webpack.version,
            VUE_VERSION,
            VUE_LOADER_VERSION,
          ].join('|'),
        },
      },
      {
        test: /\.(graphql|gql)$/,
        exclude: /node_modules/,
        loader: 'graphql-tag/loader',
      },
      {
        test: /\.svg$/,
        loader: 'raw-loader',
      },
      {
        test: /\.(gif|png)$/,
        loader: 'url-loader',
        options: { limit: 2048 },
      },
      {
        test: /\_worker\.js$/,
        use: [
          {
            loader: 'worker-loader',
            options: {
              name: '[name].[hash:8].worker.js',
              inline: IS_DEV_SERVER,
            },
          },
          'babel-loader',
        ],
      },
      {
        test: /\.(worker(\.min)?\.js|pdf|bmpr)$/,
        exclude: /node_modules/,
        loader: 'file-loader',
        options: {
          name: '[name].[hash:8].[ext]',
        },
      },
      {
        test: /.css$/,
        use: [
          'vue-style-loader',
          {
            loader: 'css-loader',
            options: {
              name: '[name].[hash:8].[ext]',
            },
          },
        ],
      },
      {
        test: /\.(eot|ttf|woff|woff2)$/,
        include: /node_modules\/katex\/dist\/fonts/,
        loader: 'file-loader',
        options: {
          name: '[name].[hash:8].[ext]',
        },
      },
    ],
  },

  // optimization
  optimization: {
    runtimeChunk: 'single',
    splitChunks: {
      maxInitialRequests: 4,
      cacheGroups: {
        default: false,
        common: () => ({
          priority: 20,
          name: 'main',
          chunks: 'initial',
          minChunks: autoEntriesCount * 0.9,
        }),
        vendors: {
          priority: 10,
          chunks: 'async',
          test: /[\\/](node_modules|vendor[\\/]assets[\\/]javascripts)[\\/]/,
        },
        commons: {
          chunks: 'all',
          minChunks: 2,
          reuseExistingChunk: true,
        },
      },
    },
  },
};
