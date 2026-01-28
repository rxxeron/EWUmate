import js from "@eslint/js";
import tseslint from "typescript-eslint";

export default [
    js.configs.recommended,
    ...tseslint.configs.recommended,
    {
        languageOptions: {
            parserOptions: {
            },
        },
        rules: {
            // Relaxed rules for faster deployment
            "@typescript-eslint/no-explicit-any": "off",
            "@typescript-eslint/no-unused-vars": "warn",
            "no-console": "off",
        },
    },
    {
        ignores: ["lib/**", "node_modules/**", "venv/**", "*.py", "**/*.py"],
    },
];
