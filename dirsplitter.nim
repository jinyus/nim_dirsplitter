import os
import tables
import strutils
import parseutils
import strformat
import confirm_op
import argparse
import std/re
import sequtils

proc splitDir(dir: string, maxFilesize: BiggestInt, prefix: string)
proc reverseSplitDir(dir: string)

const GBMultiple = 1024 * 1024 * 1024

let p = argparse.newParser:
    command("split"):
        help("Split directories into a specified maximum size")
        option("-d", "--dir", default = some("."), help = "Target directory")
        option("-m", "--max", default = some("5.0"), help = "Max part size in GB")
        option(
            "-p", "--prefix",
            default = some(""),
            help = "Prefix for output files of the tar command. eg: myprefix.part1.tar"
            )
        run:
            let dir = os.absolutePath(opts.dir.strip())
            var max: BiggestFloat = 5.0
            let result = parseBiggestFloat(opts.max, max, 0)
            if result == 0:
                echo "Invalid number for max \"{opts.max}\"".fmt
                quit(1)

            let outputPrefix = (if opts.prefix.isEmptyOrWhitespace(): "" else: opts.prefix & ".")

            confirmOperation(fmt "Splitting \"{dir}\" into {max}GB parts.")

            if not os.dirExists(dir):
                echo "Directory {dir} doesn't exists."
                quit(1)

            splitDir(
                dir,
                maxFilesize = (max * GBMultiple).toBiggestInt,
                outputPrefix
            )

    command("reverse"):
        help("Opposite of the main function, moves all files in part folders to the root")
        option("-d", "--dir", default = some("."), help = "Target directory")
        run:
            let dir = os.absolutePath(opts.dir.strip())

            confirmOperation(fmt "ReverseSplit \"{dir}\" ")

            if not os.dirExists(dir):
                echo fmt "Directory \"{dir}\" doesn't exists."
                quit(1)

            reverseSplitDir(dir)

try:
    p.run(os.commandLineParams())
except ShortCircuit as e:
    if e.flag == "argparse_help":
        echo p.help
        quit(1)
except UsageError:
    stderr.writeLine getCurrentExceptionMsg()
    echo p.help
    quit(1)

proc splitDir(dir: string, maxFilesize: BiggestInt, prefix: string) =
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

proc reverseSplitDir(dir: string) =
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
