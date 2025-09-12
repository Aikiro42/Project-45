import os, pyjson5

def list_files(startpath):
    for root, dirs, files in os.walk(startpath):
        level = root.replace(startpath, '').count(os.sep)
        indent = ' ' * 4 * (level)
        print('{}{}/'.format(indent, os.path.basename(root)))
        subindent = ' ' * 4 * (level + 1)
        for f in files:
            print('{}{}'.format(subindent, f))

def listItemIds(itemSet=("activeitem", "augment", "object", "thrownitem", "consumable"), commandPrefix=False, verbose=False):
    startpath = os.getcwd()
    listed = {}
    for root, dirs, files in os.walk(startpath):
        for f in files:
            if f[f.rfind(".")+1:] in itemSet and f != "default":
                with open(f"{root}\\{f}") as itemFile:
                    d = pyjson5.decode_io(itemFile)
                    
                    cat = "no_category"

                    if d.get('isUnique'): cat = "unique"
                    else:
                        cat = d.get('project45GunModInfo',{}).get('category', 'no_category')
                        if cat == "no_category":
                            cat = d.get('modCategory', 'no_category')
                    
                    if verbose: print(f"{cat}- ", end="")


                    itemId = d.get('itemName', d.get('objectName', '???'))
                    description = d.get('shortdescription', '???')
                    out = f"{'/spawnitem ' if commandPrefix else '- ' }<span style=\"color: #00FF00\">{itemId}</span>: {description}^reset;"
                    if verbose: print(out)
                    listed[cat] = listed.get(cat, []) + [out]
    return listed



stuffs = {
    "out-activeitems.md": ("activeitem"),
    "out-mods.md": ("augment"),
    "out-items.md": ("thrownitem", "consumable"),
    "out-objects.md": ("object")
}

for outfile, ext in stuffs.items():
    stuff = listItemIds(ext)
    with open(outfile, "w") as out:
        for category, outstrings in stuff.items():
            out.write(f"# {category}\n")
            for item in outstrings:
                out.write(item + "\n")


print()
print("Mods")
listItemIds(("augment"))

print()
print("Items")
listItemIds(("thrownitem", "consumable"))

print()
print("Objects")
listItemIds(("object"))
