# dirsplitter
Split large directories into parts of a specified maximum size

How to build:  
-Clone this git repo  
-cd into directory and run "nim c dirsplitter.nim" to compile

Or download the prebuild binary(windows and linux 64bit only) from: https://github.com/jinyus/nim_dirsplitter/releases


```text
Usage:
   dirsplitter COMMAND

Commands:

  split            Split directories into a specified maximum size
  reverse          Opposite of the main function, moves all files in part folders to the root

Options:
  -h, --help
  ```
  ## SPLIT USAGE:
  
  ```text
  Splits directory into a specified maximum size

Usage:
  dirsplitter split [options] 

Options:
  -h, --help
  -d, --dir=DIR              Target directory (default: .)
  -m, --max=MAX              Max part size in GB (default: 5.0)
  -p, --prefix=PREFIX        Prefix for output files of the tar command. -show-cmd must be specified. eg: myprefix.part1.tar (default: )
  -s, --show                 Show tar command to compress each directory
 ```
  
### example: 
```text
dirsplitter split --dir ./mylarge2GBdirectory --max 0.5

This will yield the following directory structure:

📂mylarge2GBdirectory
 |- 📂part1
 |- 📂part2
 |- 📂part3
 |- 📂part4

with each part being a maximum of 500MB in size.
```
