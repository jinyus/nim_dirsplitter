import os
import tables
import strutils
import parseopt
import parseutils
import strformat

proc confirmOperation(desc:string)

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
    case p.key:
    of "dir","d":
        dir = p.val
    of "max","m":
        discard parseBiggestFloat(p.val,max,0)
    of "show-cmd","s":
        showCmd = true
    of "out-prefix","o":
        outPrefix = p.val
    else: discard
  of cmdArgument:
      continue

if not outPrefix.isEmptyOrWhitespace:
    outPrefix.add('.')

confirmOperation("Splitting \"{dir}\" into {max}GB parts.".fmt)

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

if currentPart > 0 and showCmd:
    if currentPart == 1:
        echo fmt"""Tar Command : tar -cf "{outPrefix}part1.tar" "part1"; done"""
    else:
        echo fmt"""Tar Command : for n in {{1..{currentPart}}}; do tar -cf "{outPrefix}part$n.tar" "part$n"; done"""


proc confirmOperation(desc:string)= 
    echo desc
    write(stdout, "confirm? (y/n): ")
    var answer =  readLine(stdin).strip.toLower
    case answer:
    of "y","yes":
        return
    of "n","no":
        echo "Goodbye!"
        quit(0)
    else:
        echo fmt"invalid answer : expected (y or n) got ({answer})" 
        quit(1)