/* eslint-disable import/no-commonjs, filenames/match-regex */
module.exports = function(api) {
  const validEnv = ['development', 'test', 'production'];
  const currentEnv = api.env();
  const isDevelopmentEnv = api.env('development');
  const isProductionEnv = api.env('production');
  const isTestEnv = api.env('test');

  if (!validEnv.includes(currentEnv)) {
    throw new Error(
      'Please specify a valid `NODE_ENV` or ' +
        '`BABEL_ENV` environment variables. Valid values are "development", ' +
        '"test", and "production". Instead, received: ' +
        JSON.stringify(currentEnv) +
        '.'
    )
  }

  let presets = [];

  if (isTestEnv) {
    presets = [
      [
        '@babel/preset-env',
        {
          targets: {
            node: 'current',
          },
        },
      ],
    ];
  } else if (isProductionEnv || isDevelopmentEnv) {
    presets = [
      [
        '@babel/preset-env',
        {
          modules: false,
          targets: {
            ie: '11',
          },
        },
      ],
    ];
  }

  // let plugins = [
  //     'babel-plugin-macros',
  //     '@babel/plugin-syntax-dynamic-import',
  //     '@babel/plugin-transform-destructuring',
  //     [
  //       '@babel/plugin-proposal-class-properties',
  //       {
  //         loose: true
  //       },
  //     ],
  //     [
  //       '@babel/plugin-proposal-object-rest-spread',
  //       {
  //         useBuiltIns: true
  //       },
  //     ],
  //   [
  //     '@babel/plugin-transform-runtime',
  //     {
  //       helpers: false,
  //       regenerator: true,
  //       corejs: 3
  //     }
  //   ],
  //   [
  //     '@babel/plugin-transform-regenerator',
  //     {
  //       async: false
  //     }
  //   ],
  // ];
  //
  // if (isTestEnv) {
  //   plugins.push('babel-plugin-dynamic-import-node')
  // }

  // include stage 3 proposals
  const plugins = [
    '@babel/plugin-syntax-dynamic-import', // same
    '@babel/plugin-syntax-import-meta',
    '@babel/plugin-proposal-class-properties',
    '@babel/plugin-proposal-json-strings',
    '@babel/plugin-proposal-private-methods',
  ];

  return { presets: presets, plugins: plugins};
};
