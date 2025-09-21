import os, re, sys
from io import StringIO

codexName = "project45catalog"
defaultMarkdownPath = f"docs/devtools/python/md-to-codex/{codexName}.md"
defaultCodexPath = f"codex/project45/{codexName}.codex"

markdownPath = sys.argv[1] if len(sys.argv) >= 2 else input("Enter path of markdown file to convert: ")
codexPath = sys.argv[2] if len(sys.argv) >= 3 else input("Enter path of codex file to patch: ")

if markdownPath == "":
  markdownPath = defaultMarkdownPath
if not os.path.exists(markdownPath):
    print("ERROR: Markdown file not found.")
    sys.exit()


if codexPath == "":
  codexPath = defaultCodexPath
if not os.path.exists(codexPath):
    print("ERROR: Codex file not found.")
    sys.exit()


codexPages = []

tabSpaces = 2

# in characters
codexWidth = 37
codexHeight = 13
wordWrap = False

def trim_string_format(s: str) -> str:
  return re.sub(r"\^.*?;", "", s)

def effective_length(s: str) -> int:
    # Remove everything from ^ up to and including the next ;
    cleaned = trim_string_format(s)
    return len(cleaned)

def replace_spans(s: str) -> str:
    # Replace opening <span style="color: #XXXXXX"> with ^#XXXXXX;
    s = re.sub(
        r'<span\s+style="color:\s*(#[0-9A-Fa-f]{6})"\s*>',
        r'^\1;',
        s
    )
    # Replace closing </span> with ^reset;
    s = re.sub(r'</span>', r'^reset;', s, flags=re.IGNORECASE)
    return s

def open_without_comments(path: str, encoding="utf-8"):
    with open(path, "r", encoding=encoding) as f:
        text = f.read()
    # Remove comments (DOTALL = span multiple lines)
    cleaned = re.sub(r'<!--.*?-->', '', text, flags=re.DOTALL)
    # Wrap in StringIO so it behaves like a file
    return StringIO(cleaned)
    
with open_without_comments(markdownPath) as textFile:
  currentHeader = ""
  lineCount = 0
  currentPage = ""

  def addPage(s: str):
    global codexPages
    if s.strip() != "":
      codexPages += [s]
  
  for line in textFile:
    
    # get line, clean it up
    currentLine = replace_spans(line.replace("\t", " "*tabSpaces).rstrip())
    
    # skip blank lines
    if currentLine == "":
      if lineCount < codexHeight:
        currentPage += "\n"
        lineCount += 1
      continue

    # if the line is a header, update current header and make new page
    if trim_string_format(currentLine[0]) == "#":
      addPage(currentPage)
      if trim_string_format(currentLine).strip() != "#":
        currentHeader = currentLine
        currentPage = ""
        lineCount = 0
      else:
        currentPage = currentHeader + "\n"
        lineCount = 1
        continue
    
    # auto-pagebreaker doesnt work well
    # better to just do pagebreaks manually
    # also codexes have built-in wordwrap anyway
    """
    # split up the line/header so that it fits within the page;
    while wordWrap and effective_length(currentLine) >= codexWidth:

      # break the line/header by the last space,
      # or break the last word with a hyphen
      space = currentLine.rfind(" ", 0, codexWidth)
      space = -1
      if space > -1: 
        currentPage += currentLine[:space] + "\n"
        currentLine = currentLine[space:].strip()
      else:
        currentPage += currentLine[:codexWidth-1] + "-\n"
        currentLine = currentLine[codexWidth-1:].strip()
      lineCount += 1
      
      # if codex height exceeded,
      # make new page
      if lineCount >= codexHeight:
        addPage(currentPage)
        # init new page with header if it's short enough
        # to fit in a line
        if effective_length(currentHeader) < codexWidth:
          currentPage = currentHeader + "\n"
          lineCount = 1
        else:
          currentPage = ""
          lineCount = 0
    """
    # loop exited
    if lineCount >= codexHeight:
      addPage(currentPage)
      currentPage = ""
      lineCount = 0

    # append last bit of line
    currentPage += currentLine + "\n"
    lineCount += 1

addPage(currentPage)

with open(codexPath + ".patch", "w") as output:
  output.write(
"""
[
  {
    "op": "replace",
    "path": "/contentPages",
    "value": [\n"""
  )
  i = 1
  for page in codexPages:
    r = repr(page)
    # Remove outer quotes (either ' or ")
    r = r[1:-1]
    # Escape internal double quotes
    r = r.replace('\\\\"', '\\"')
    r = r.replace('\\\'', '\'')
    if i == len(codexPages):
      r = f"      \"{r}\"\n"
    else:
      r = f"      \"{r}\",\n"
    # print(f"{i}: ", r, "\n")
    output.write(r)
    i+=1
  output.write(
"""    ]
  }
]
""")
