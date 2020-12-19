# dirsplitter
Split large directories into parts of a specified maximum size

How to build:  
-Clone this git repo  
-cd into directory and run "nim c dirsplitter.nim" to compile

Or download the prebuild binary(windows and linux 64bit only) from: https://github.com/jinyus/nim_dirsplitter/releases



Usage of dirsplitter:  
  -dir , d string  
        &nbsp;&nbsp;&nbsp;&nbsp;Target Directory (default ".")  
  -max , m float  
        &nbsp;&nbsp;&nbsp;&nbsp;Max part size in GB (default 5)  
        
```
example:

dirsplitter --dir ./mylarge2GBdirectory --max "0.5"
NB: decimals has to be wrapped in quotes("")

This will yield the following directory structure:

📂mylarge2GBdirectory
 |- 📂part1
 |- 📂part2
 |- 📂part3
 |- 📂part4

with each part being a maximum of 500MB in size.
```
