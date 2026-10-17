-- End every blog post (body-classes: article, from posts/_metadata.yml)
-- with a quiet link back to the post index.
function Pandoc(doc)
  local classes = doc.meta["body-classes"]
  if classes and pandoc.utils.stringify(classes):match("%f[%w]article%f[%W]") then
    table.insert(doc.blocks, pandoc.RawBlock("html",
      '<nav class="post-end" aria-label="More writing"><a href="/blog.html">← All posts</a></nav>'))
  end
  return doc
end
