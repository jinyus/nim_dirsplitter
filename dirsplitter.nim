import os
import tables
import strutils
import parseutils
import strformat
import confirm_op
import argparse

proc splitDir(dir: string, maxFilesize: BiggestInt, prefix: string, show: bool)
# proc reverseSplitDir(dir: string)

const GBMultiple = 1024 * 1024 * 1024

let p = argparse.newParser:
    help("Split directories into a specified maximum size")
    option("-d", "--dir", default = some("."), help = "Target directory")
    option("-m", "--max", default = some("5.0"), help = "Max part size in GB")
    option("-p", "--prefix", default = some(""),
            help = "Prefix for output files of the tar command. -show-cmd must be specified. eg: myprefix.part1.tar")
    flag("-s", "--show", help = "Show tar command to compress each directory")
    run:
        let dir = opts.dir.strip()
        var max: BiggestFloat = 5.0
        let result =  parseBiggestFloat(opts.max, max, 0)
        if result == 0:
            echo "Invalid number for max \"{opts.max}\"".fmt
            quit(1)

        let show = opts.show
        let outputPrefix = (if opts.prefix.isEmptyOrWhitespace:"" else:opts.prefix & ".")

        confirmOperation(fmt "Splitting \"{dir}\" into {max}GB parts.")

        if not os.dirExists(dir):
            echo "Directory {dir} doesn't exists."
            quit(1)

        splitDir(
            dir,
            maxFilesize = (max * GBMultiple).toBiggestInt,
            outputPrefix,
            show
        )

    command("reverse"):
        help("opposite of the main function, moves all files in part folders to the root")
        option("-d", "--dir", default = some("."), help = "Target directory")
        run:
            echo opts.dir

try:
  p.run(os.commandLineParams())
except ShortCircuit as e:
  if e.flag == "argparse_help":
    echo p.help
    quit(1)
except UsageError:
  stderr.writeLine getCurrentExceptionMsg()
  quit(1)

proc splitDir(dir: string, maxFilesize: BiggestInt, prefix: string, show: bool)=
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
            if tracker[currentPart] + size > maxFileSize and tracker[currentPart] > 0:
                inc currentPart
                decrementIfFailed = true
            discard tracker.hasKeyOrPut(currentPart, 0)
            tracker[currentPart] += size
        except OSError:
            echo "failed to get filesize : " & getCurrentExceptionMsg()
            continue

        var filename = os.extractFilename(path)
        var partDir = os.joinPath(dir, fmt"part{currentPart}")
        discard os.existsOrCreateDir(partDir)

        try:
            os.moveFile(path, joinPath(partDir, filename))
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

    if currentPart > 0 and show:
        if currentPart == 1:
            echo fmt"""Tar Command : tar -cf "{prefix}part1.tar" "part1"; done"""
        else:
            echo fmt"""Tar Command : for n in {{1..{currentPart}}}; do tar -cf "{prefix}part$n.tar" "part$n"; done"""
