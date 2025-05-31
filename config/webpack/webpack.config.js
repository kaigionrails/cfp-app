const { generateWebpackConfig, merge } = require('shakapacker')

const customConfig = {
  resolve: {
    extensions: [
      '.mjs',
      '.js',
      '.sass',
      '.scss',
      '.css',
      '.module.sass',
      '.module.scss',
      '.module.css',
      '.png',
      '.svg',
      '.gif',
      '.jpeg',
      '.jpg'
    ]
  },
  ignoreWarnings: [
    {
      module: /tailwind/,
      message: /Critical dependency: the request of a dependency is an expression/
    }
  ]
}

module.exports = merge(generateWebpackConfig(), customConfig)
