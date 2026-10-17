-- Wrap every table in a focusable, labelled horizontal-scroll region so wide
-- tables scroll inside the text column instead of widening the page on phones.
-- Each region gets a unique accessible name: its caption, else "Table N".
local count = 0

function Table(tbl)
  count = count + 1
  local caption = pandoc.utils.stringify(tbl.caption.long or {})
  local label = caption ~= "" and caption or ("Table " .. count)
  return pandoc.Div({ tbl }, pandoc.Attr("", { "table-scroll" }, {
    role = "region", tabindex = "0", ["aria-label"] = label,
  }))
end
