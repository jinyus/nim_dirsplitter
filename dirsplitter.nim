import os
import tables
import strutils
import parseopt
import parseutils
import strformat

proc confirmOperation(desc:string)= 
    echo desc
    write(stdout, "confirm? (y/n): ")
    var answer =  readLine(stdin)
    if answer != "y" and answer != "n":
        echo "invalid answer : expected (y or n) got (",answer,")"
        quit(1)
    elif answer != "y":
        echo "Goodbye!"
        quit(0)

var p = initOptParser(commandLineParams(),shortNoVal = {'s'},longNoVal = @["show-cmd"])

var dir : string = "."
var max : BiggestFloat = 5.0
var showCmd : bool = false
var outPrefix : string = ""

while true:
  p.next()
  case p.kind
  of cmdEnd: break
  of cmdShortOption, cmdLongOption:
    if p.key == "dir" or p.key == "d":
        if not p.val.isEmptyOrWhitespace():
            dir = p.val
    elif p.key == "max" or p.key == "m":
        if not p.val.isEmptyOrWhitespace():
            discard parseBiggestFloat(p.val,max,0)
    elif p.key == "show-cmd" or p.key == "s":
        showCmd = true
    elif p.key == "out-prefix" or p.key == "o":
        if not p.val.isEmptyOrWhitespace():
            outPrefix = p.val
  of cmdArgument:
      continue

confirmOperation("Splitting \"{dir}\" into {max:.3f}GB parts.".fmt)

echo "Splitting Directory\n\n"

const GBMultiple = 1024 * 1024 * 1024
var tracker : Table[int, BiggestFloat] = {1: 0.toBiggestFloat}.toTable  
var currentPart = 1
var filesMoved = 0
var failedOps = 0
var maxFileSize :BiggestFloat = max * GBMultiple

for kind, path in walkDir(dir):
    if  kind != pcFile:
        continue

    var size: BiggestFloat
    var decrementIfFailed = false
    try:
        size = getFileSize(path).toBiggestFloat
        if tracker[currentPart] + size > maxFileSize and tracker[currentPart] > 0.0:
            inc currentPart
            decrementIfFailed = true
        discard tracker.hasKeyOrPut(currentPart,0.toBiggestFloat)
        tracker[currentPart] += size
    except OSError:
        echo "failed to get filesize : " & getCurrentExceptionMsg()
        continue 

    var filename = extractFilename(path)
    var partDir = joinPath(dir,"part" & intToStr(currentPart))
    discard existsOrCreateDir(partDir)

    try:
        moveFile(path,joinPath(partDir,filename))
        inc filesMoved
    except OSError:
        echo "failed to move file : " & getCurrentExceptionMsg()
        inc failedOps
        tracker[currentPart] = tracker[currentPart] - size
        if decrementIfFailed:
            dec currentPart

if filesMoved == 0:
    currentPart = 0

echo "Done"
echo "Parts created: " & currentPart.intToStr
echo "Files moved: " & filesMoved.intToStr
echo "Failed Operations: " & failedOps.intToStr
# echo tracker

if currentPart > 0 and showCmd:
    if currentPart == 1:
        echo """Tar Command : tar -cf "{outPrefix}.part1.tar" "part1"; done""".fmt
    else:
        echo "Tar Command : for n in {1..", currentPart.intToStr,"}", fmt"""; do tar -cf "{outPrefix}.part$n.tar" "part$n"; done"""




    