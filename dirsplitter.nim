import os
import strutils
import parseutils
import strformat
import argparse
import confirm_op
import split_dir
import reverse_split


const versionProd = "1.0.1"
const GBMultiple = 1000 * 1000 * 1000

let p = argparse.newParser:
    command("version"):
        help("Prints the version of the program")
        run:
            echo "Dirsplitter version : {versionProd}".fmt
            quit(0)
    command("split"):
        help("Split directories into a specified maximum size")
        option("-d", "--dir", default = some("."), help = "Target directory")
        option("-m", "--max", default = some("5.0"),
                help = "Max part size in GB")
        option(
            "-p", "--prefix",
            default = some(""),
            help = "Prefix for output files of the tar command. eg: myprefix.part1.tar"
            )
        run:
            let dir = os.absolutePath(opts.dir.strip())

            if not os.dirExists(dir):
                echo "Directory {dir} doesn't exists."
                quit(1)

            var max: BiggestFloat = 5.0
            let result = parseBiggestFloat(opts.max, max, 0)
            if result == 0:
                echo "Invalid number for max \"{opts.max}\"".fmt
                quit(1)

            let outputPrefix = (if opts.prefix.isEmptyOrWhitespace(): "" else: opts.prefix & ".")

            confirmOperation(fmt "Splitting \"{dir}\" into {max}GB parts.")

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

            if not os.dirExists(dir):
                echo fmt "Directory \"{dir}\" doesn't exists."
                quit(1)

            confirmOperation(fmt "ReverseSplit \"{dir}\" ")

            reverseSplitDir(dir)

if os.commandLineParams().len == 0:
    echo p.help
    quit(0)

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
