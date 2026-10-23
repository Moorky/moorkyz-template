export default [
  {
    ignores: [
      ".template/**",
      ".moorkyz/**",
      ".logs/**",
      ".archive/**",
      "coverage/**",
      "dist/**",
      "build/**",
    ],
  },
  {
    files: ["**/*.{js,cjs,mjs}"],
    languageOptions: { ecmaVersion: "latest" },
    rules: {
      "constructor-super": "error",
      "no-debugger": "error",
      "no-duplicate-imports": "error",
      "no-unused-vars": ["error", { argsIgnorePattern: "^_", varsIgnorePattern: "^_" }],
      "valid-typeof": "error",
    },
  },
];
