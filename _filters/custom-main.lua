-- page-layout: custom emits page content without a <main> element.
-- Wrap it in one so custom pages keep the main landmark (accessibility)
-- and the same #quarto-document-content hook as article pages.
function Pandoc(doc)
  local layout = doc.meta["page-layout"]
  if layout and pandoc.utils.stringify(layout) == "custom" then
    table.insert(doc.blocks, 1, pandoc.RawBlock("html", '<main id="quarto-document-content" class="content">'))
    table.insert(doc.blocks, pandoc.RawBlock("html", "</main>"))
  end
  return doc
end
