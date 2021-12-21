import strutils
import strformat

proc confirmOperation*(desc:string)=
    echo desc
    var invalidAttemptCount = 0
    while true:    
        write(stdout, "continue? [y/n]: ")
        var answer =  readLine(stdin).strip().toLower()
        case answer:
        of "y","yes":
            return
        of "n","no":
            echo "Goodbye!"
            quit(0)
        else:
            inc invalidAttemptCount
            echo fmt"invalid answer : expected (y or n) got ({answer})"
            if invalidAttemptCount > 1:
                quit(1)
