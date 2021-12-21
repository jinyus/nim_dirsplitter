import os
import strutils
import strformat
import argparse
import std/re

proc reverseSplitDir*(dir: string) =
    var partDirsToDelete: seq[string]

    var shouldDelete = true

    for kind, path in os.walkDir(dir):
        let isPartDir = kind == pcDir and re.endsWith(path, re"part\d+")

        if not isPartDir:
            echo "skipping: " & path
            continue

        let partPath = os.absolutePath(path)
        partDirsToDelete.add(partPath)

        for pFile in os.walkDirRec(path, yieldFilter = {pcFile}):
            try:
                let filePath = os.absolutePath(pFile)
                let dest = filePath.replace(partPath, dir)
                os.createDir(dest.parentDir)
                os.moveFile(filePath, dest)
            except OSError:
                shouldDelete = false
                echo fmt"failed to {pFile} to {dir}: " & getCurrentExceptionMsg()

    if shouldDelete:
        for partDir in partDirsToDelete:
            try:
                os.removeDir(partDir)
            except OSError:
                echo "failed to delete " & partDir & " " &
                        getCurrentExceptionMsg()
