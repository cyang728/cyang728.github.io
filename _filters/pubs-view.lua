-- Publications pages: build the All, Methods and Applications views from the
-- one list in _publications.qmd. Each page sets `pubs-view` (all, methods or
-- applications) in its front matter and includes the list; other pages are
-- left alone.
--
-- The filter keeps the entries of the page's kind (all of them on All),
-- removes the sections that are then empty, numbers the entries, and adds the
-- links to the three views and the "On this page" list of sections.

local VIEWS = {
  { key = "all",          label = "All",          href = "publications.html" },
  { key = "methods",      label = "Methods",      href = "publications-methods.html" },
  { key = "applications", label = "Applications", href = "publications-applications.html" },
}

local function esc(s)
  return (s:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub('"', "&quot;"))
end

local function raw(html) return pandoc.RawBlock("html", html) end

-- Split raw HTML into its top-level <div> elements and the text between them
-- (HTML comments are skipped).
local function top_divs(html)
  local parts, depth, from, pos, last = {}, 0, nil, 1, 1
  while true do
    local c = html:find("<!--", pos, true)
    local s, e, slash = html:find("<(/?)div[%s>]", pos)
    if c and (not s or c < s) then
      local ce = html:find("-->", c + 4, true)
      pos = ce and ce + 3 or #html + 1
    elseif not s then
      break
    elseif slash == "" then
      if depth == 0 then
        if s > last then table.insert(parts, { text = html:sub(last, s - 1) }) end
        from = s
      end
      depth = depth + 1
      pos = e
    else
      depth = depth - 1
      if depth < 0 then error("pubs-view: a </div> in _publications.qmd has no opening <div>") end
      local close = html:find(">", s, true)
      pos = close + 1
      if depth == 0 then
        table.insert(parts, { div = html:sub(from, close) })
        last = close + 1
      end
    end
  end
  if depth ~= 0 then error("pubs-view: a <div> in _publications.qmd is not closed") end
  if last <= #html then table.insert(parts, { text = html:sub(last) }) end
  return parts
end

local function attr(div, name)
  local open = div:match("^<div([^>]*)>")
  return open and open:match("%s" .. (name:gsub("%-", "%%-")) .. '="([^"]*)"')
end

local function has_class(div, class)
  local classes = attr(div, "class") or ""
  for c in classes:gmatch("%S+") do if c == class then return true end end
  return false
end

-- An element is shown on the All view, and on a view named in its data-kind.
-- Elements without data-kind are shown on every view.
local function shown(div, view)
  local kinds = attr(div, "data-kind")
  if view == "all" or not kinds then return true end
  for k in kinds:gmatch("%S+") do if k == view then return true end end
  return false
end

-- Put the entry's number in a first column and its text in a second one
-- (an entry that already has a number column only gets its number updated).
local function numbered(div, label)
  local n = '<div class="n">' .. esc(label) .. "</div>"
  if div:find('<div class="n">', 1, true) then
    return (div:gsub('<div class="n">.-</div>', function() return n end, 1))
  end
  local open = div:find(">", 1, true)
  local inner = div:sub(open + 1):match("^(.*)</div%s*>%s*$")
  return div:sub(1, open) .. n .. '<div class="body">' .. inner .. "</div></div>"
end

-- Years continue one numbering; any other section starts again at 1.
local function is_year(title) return title:match("^%d%d%d%d") ~= nil end

-- Filter (and number) the raw HTML blocks of one section; other blocks pass.
local function render(blocks, view, count)
  local out, items = {}, 0
  for _, b in ipairs(blocks) do
    if b.t == "RawBlock" and b.format == "html" and b.text:match("^%s*<!%-%-.-%-%->%s*$") then
      -- an editing note in the list: not published
    elseif b.t == "RawBlock" and b.format == "html" then
      local html = {}
      for _, p in ipairs(top_divs(b.text)) do
        if p.text then
          table.insert(html, p.text)
        elseif shown(p.div, view) then
          if has_class(p.div, "pub-item") then
            items = items + 1
            local n = attr(p.div, "data-n")
            if not n then count.n = count.n + 1; n = tostring(count.n) end
            table.insert(html, numbered(p.div, n))
          else
            table.insert(html, p.div)
          end
        end
      end
      table.insert(out, raw(table.concat(html)))
    else
      table.insert(out, b)
    end
  end
  return out, items
end

function Pandoc(doc)
  local meta = doc.meta["pubs-view"]
  if not meta then return nil end
  local view = pandoc.utils.stringify(meta)

  -- the blocks before the first level-2 heading, then one group per heading
  local head, sections, cur = {}, {}, nil
  for _, b in ipairs(doc.blocks) do
    if b.t == "Header" and b.level == 2 then
      cur = { id = b.identifier, title = pandoc.utils.stringify(b.content),
              kicker = b.attributes.kicker, blocks = {} }
      table.insert(sections, cur)
    elseif cur then
      table.insert(cur.blocks, b)
    else
      table.insert(head, b)
    end
  end

  local tabs = { '<nav class="pub-tabs" aria-label="Publication views">' }
  for _, v in ipairs(VIEWS) do
    local current = v.key == view and ' aria-current="page"' or ""
    table.insert(tabs, '<a href="' .. v.href .. '"' .. current .. ">" .. v.label .. "</a>")
  end
  table.insert(tabs, "</nav>")

  local out = { raw('<div class="pubs-page pub-layout">\n<div class="pub-head">\n' .. table.concat(tabs, "\n")) }
  local head_blocks = render(head, view, { n = 0 })
  for _, b in ipairs(head_blocks) do table.insert(out, b) end
  table.insert(out, raw("</div>"))

  local list, rail, count = {}, {}, { n = 0 }
  for _, s in ipairs(sections) do
    if not is_year(s.title) then count.n = 0 end
    local blocks, items = render(s.blocks, view, count)
    if view == "all" or items > 0 then
      local id = esc(s.id)
      local kicker = s.kicker and ('<div class="pub-group-kicker">' .. esc(s.kicker) .. "</div>\n") or ""
      table.insert(list, raw('<section id="' .. id .. '" class="pub-group">\n' .. kicker ..
        '<h2 class="anchored" data-anchor-id="' .. id .. '">' .. esc(s.title) .. "</h2>\n" ..
        '<div class="publist2">'))
      for _, b in ipairs(blocks) do table.insert(list, b) end
      table.insert(list, raw("</div>\n</section>"))
      table.insert(rail, '<li><a href="#' .. id .. '">' .. esc(s.title) .. "</a></li>")
    end
  end

  table.insert(out, raw('<nav class="pub-rail" aria-labelledby="pub-rail-h">\n' ..
    '<p class="pub-rail-h" id="pub-rail-h">On this page</p>\n<ul>\n' .. table.concat(rail, "\n") .. "\n</ul>\n</nav>"))
  table.insert(out, raw('<div class="pub-list">'))
  for _, b in ipairs(list) do table.insert(out, b) end
  table.insert(out, raw("</div>\n</div>"))

  doc.blocks = out
  return doc
end
