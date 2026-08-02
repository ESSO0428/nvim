; extends
([
  (fenced_code_block)
  (indented_code_block)
  (section)
  (list_item
    (list))
  (list_item
    (fenced_code_block))
  (list_item
    (pipe_table))
  (html_block)
  (pipe_table)
  (block_quote)
] @fold
  (#trim! @fold))

(section
  (setext_heading
    (setext_h2_underline)) @fold
  .
  (list) @fold)

(section
  (setext_heading
    (setext_h2_underline)) @fold
  .
  (paragraph) @fold)

(section
  (setext_heading
    (setext_h2_underline)) @fold
  .
  (pipe_table) @fold)
