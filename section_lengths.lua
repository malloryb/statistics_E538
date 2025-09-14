-- section_lengths.lua
-- Produces a CSV of "heading path" + word counts (ignores code/math)
-- Output path is taken from metadata "wordcount_out" or defaults to "section_lengths.csv"

local path_stack = {}
local counts = {}         -- map: path -> word count
local current_path = "(preamble)"

local function join_path()
  if #path_stack == 0 then return "(preamble)" end
  return table.concat(path_stack, " > ")
end

local function words_in_inlines(inlines)
  local n = 0
  for _, el in ipairs(inlines) do
    local t = el.t
    if t == "Str" then
      -- count tokens in the string
      for _ in string.gmatch(el.text, "%S+") do n = n + 1 end
    elseif t == "Code" or t == "Math" then
      -- ignore code/math
    elseif t == "Space" or t == "SoftBreak" or t == "LineBreak" then
      -- no-op
    elseif t == "Emph" or t == "Strong" or t == "Underline" or
           t == "Superscript" or t == "Subscript" or t == "SmallCaps" or
           t == "Strikeout" or t == "Quoted" or t == "Span" or
           t == "Link" or t == "Note" then
      -- recurse into containers with .content
      if el.content then n = n + words_in_inlines(el.content) end
    end
  end
  return n
end

local function add_words(n)
  if n <= 0 then return end
  counts[current_path] = (counts[current_path] or 0) + n
end

-- Handlers that contribute words
function Para(el)         add_words(words_in_inlines(el.content)) end
function Plain(el)        add_words(words_in_inlines(el.content)) end

function BulletList(items)
  for _, item in ipairs(items) do
    for _, blk in ipairs(item) do
      Pandoc({blk}) -- let the other handlers process
    end
  end
  return nil
end

function OrderedList(items)
  for _, item in ipairs(items) do
    for _, blk in ipairs(item) do
      Pandoc({blk})
    end
  end
  return nil
end

function DefinitionList(items)
  for _, def in ipairs(items) do
    local terms, defs = def[1], def[2]
    -- terms are inlines
    add_words(words_in_inlines(terms))
    -- defs are lists of blocks
    for _, blocks in ipairs(defs) do
      for _, blk in ipairs(blocks) do
        Pandoc({blk})
      end
    end
  end
  return nil
end

-- Ignore: CodeBlock, RawBlock, Tables (optional: uncomment to count table text)
function CodeBlock(el) return nil end
function RawBlock(el)  return nil end
-- If you want to count words inside tables, add a Table handler.

-- Update the current heading path
function Header(el)
  -- truncate/extend stack to header level
  while #path_stack >= el.level do table.remove(path_stack) end
  table.insert(path_stack, pandoc.utils.stringify(el.content))
  current_path = join_path()
  -- ensure the section key exists
  counts[current_path] = counts[current_path] or 0
end

-- On document end: write CSV
function Pandoc(doc)
  -- ensure preamble bucket exists if any text preceded first header
  counts[current_path] = counts[current_path] or 0

  local outname = "section_lengths.csv"
  if doc.meta and doc.meta.wordcount_out then
    outname = pandoc.utils.stringify(doc.meta.wordcount_out)
    if outname == "" then outname = "section_lengths.csv" end
  end

  local f = io.open(outname, "w")
  f:write("path,words,approx_pages(@400wpp)\n")

  -- stable order: by appearance-ish (preamble first), then alpha
  -- build a list
  local keys = {}
  for k, _ in pairs(counts) do table.insert(keys, k) end
  table.sort(keys, function(a,b)
    if a == "(preamble)" then return true end
    if b == "(preamble)" then return false end
    return a:lower() < b:lower()
  end)

  for _, k in ipairs(keys) do
    local w = counts[k] or 0
    local pages = string.format("%.2f", w / 400.0)
    -- escape quotes if any
    local safe = '"' .. k:gsub('"', '""') .. '"'
    f:write(string.format("%s,%d,%s\n", safe, w, pages))
  end
  f:close()

  -- return doc unchanged
  return doc
end
