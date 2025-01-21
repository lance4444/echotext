module.exports = {
  env: {
    es6: true,
    node: true,
  },
  parserOptions: {
    "ecmaVersion": 2018,
  },
  extends: [
    "eslint:recommended",
    "google",
  ],
  rules: {
    // Disable all syntax-related checks
    "no-restricted-globals": "off",
    "prefer-arrow-callback": "off",
    "quotes": "off",
    "max-len": "off",
    "comma-dangle": "off",
    "indent": "off",
    "object-curly-spacing": "off",
    "require-jsdoc": "off",
    // Add more rules to turn off as needed
  },
  overrides: [
    {
      files: ["**/*.spec.*"],
      env: {
        mocha: true,
      },
      rules: {},
    },
  ],
  globals: {},
};
