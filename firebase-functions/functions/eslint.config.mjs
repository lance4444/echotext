import globals from "globals";
import path from "node:path";
import { fileURLToPath } from "node:url";
import js from "@eslint/js";
import { FlatCompat } from "@eslint/eslintrc";


const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const compat = new FlatCompat({
    baseDirectory: __dirname,
    recommendedConfig: js.configs.recommended,
    allConfig: js.configs.all
});

export default [...compat.extends("eslint:recommended", "google"), {
    languageOptions: {
        globals: {
            ...globals.node,
        },

        ecmaVersion: 2021,
        sourceType: "module",
    },

    rules: {
        "no-restricted-globals": "off",
        "prefer-arrow-callback": "off",
        "quotes": "off",
        "max-len": "off",
        "comma-dangle": "off",
        "indent": "off",
        "object-curly-spacing": "off",
        "require-jsdoc": "off",
    },
}, {
    files: ["**/*.spec.*"],

    languageOptions: {
        globals: {
            ...globals.mocha,
        },
    },

    rules: {},
}];
