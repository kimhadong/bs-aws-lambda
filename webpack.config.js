const path = require('path');
const slsw = require('serverless-webpack');
const CopyPlugin = require('copy-webpack-plugin');
const nodeExternals = require('webpack-node-externals')

module.exports = {
  mode:'development',
  entry: slsw.lib.entries,
  resolve: {
    extensions: [
      '.js',
    ]
  },
  externals: [nodeExternals()],
  plugins: [
    new CopyPlugin({
      patterns: [
        { from: 'schema.prisma', to: 'schema.prisma' },
        { from: 'node_modules/.prisma/client/query-engine-rhel-openssl-1.0.x', to: 'query-engine-rhel-openssl-1.0.x' },
      ]
    })
  ],

  output: {
    libraryTarget: 'commonjs',
    path: path.join(__dirname, '.webpack'),
    filename: '[name].js',
  },
  target: 'node',
};
