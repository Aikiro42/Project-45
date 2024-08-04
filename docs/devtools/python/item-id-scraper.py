import os, pyjson5

def list_files(startpath):
    for root, dirs, files in os.walk(startpath):
        level = root.replace(startpath, '').count(os.sep)
        indent = ' ' * 4 * (level)
        print('{}{}/'.format(indent, os.path.basename(root)))
        subindent = ' ' * 4 * (level + 1)
        for f in files:
            print('{}{}'.format(subindent, f))

def listItemIds(itemSet=("activeitem", "augment", "object", "thrownitem", "consumable"), commandPrefix=True):
    startpath = os.getcwd()
    for root, dirs, files in os.walk(startpath):
        for f in files:
            if f[f.rfind(".")+1:] in itemSet and f != "default":
                with open(f"{root}\\{f}") as itemFile:
                    d = pyjson5.decode_io(itemFile)
                    try:
                      print(f"{'/spawnitem ' if commandPrefix else '' }{d['itemName']}")
                    except:
                      print(f"{'/spawnitem ' if commandPrefix else '' }{d['objectName']}")


print("[h2]Active Items[/h2]")
print("[code]")
listItemIds(("activeitem"))
print("[/code]")

print()
print("[h2]Mods[/h2]")
print("[code]")
listItemIds(("augment"))
print("[/code]")

print()
print("[h2]Items[/h2]")
print("[code]")
listItemIds(("thrownitem", "consumable"))
print("[/code]")

print()
print("[h2]Objects[/h2]")
print("[code]")
listItemIds(("object"))
print("[/code]")
