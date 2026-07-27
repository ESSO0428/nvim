return {
  root_dir = function(bufnr, on_dir)
    on_dir(vim.fs.root(bufnr, {
      "tailwind.config.js",
      "tailwind.config.ts",
      "tailwind.config.cjs",
      "tailwind.js",
      "tailwind.ts",
      "tailwind.cjs",
    }))
  end,
}
