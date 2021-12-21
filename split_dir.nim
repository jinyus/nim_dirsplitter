import os
import tables
import strutils
import strformat

proc splitDir*(dir: string, maxFilesize: BiggestInt, prefix: string) =
    echo "\nSplitting Directory...\n\n"

    var tracker: Table[int, BiggestInt] = {1: 0.toBiggestInt}.toTable
    var currentPart = 1
    var filesMoved = 0
    var failedOps = 0

    for path in os.walkDirRec(dir):
        let size = os.getFileSize(path)


        #the filesize is added to the table so decrement is the move op fails
        var decrementIfFailed = false

        try:
            if tracker[currentPart] + size > maxFileSize and tracker[
                    currentPart] > 0:
                inc currentPart
                decrementIfFailed = true
            discard tracker.hasKeyOrPut(currentPart, 0)
            tracker[currentPart] += size
        except OSError:
            echo "failed to get filesize : " & getCurrentExceptionMsg()
            continue

        var filePath = os.absolutePath(path)
        var partDir = os.joinPath(dir, fmt"part{currentPart}")
        let dest = filePath.replace(dir, partDir)

        try:
            os.createDir(dest.parentDir)
            os.moveFile(path, dest)
            inc filesMoved
        except OSError:
            echo "failed to move file : \n" & getCurrentExceptionMsg()
            inc failedOps
            tracker[currentPart] -= size
            if decrementIfFailed:
                dec currentPart

    if filesMoved == 0:
        currentPart = 0

    echo fmt"Parts created: {currentPart}"
    echo fmt"Files moved: {filesMoved}"
    echo fmt"Failed Operations: {failedOps}"

    if currentPart > 0 and not prefix.isEmptyOrWhitespace():
        if currentPart == 1:
            echo fmt"""Tar Command : tar -cf "{prefix}part1.tar" "part1"; done"""
        else:
            echo fmt"""Tar Command : for n in {{1..{currentPart}}}; do tar -cf "{prefix}part$n.tar" "part$n"; done"""
