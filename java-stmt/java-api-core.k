require "java-core.k"
require "java-classes.k"

module JAVA-API-CORE
    imports JAVA-CORE
    imports JAVA-CLASSES

// This module contains the minimal part of java API required to perform
// console read/write operations.

syntax KResult ::=  "rtSystem"
                  | "rtSystemOut"
                  | "rtSystemOutPrint"
               // | "rtSystemOutPrintln"  was moved to JAVA-CORE
                  | "rtSystemConsole"
                  | "rtSystemConsoleReadLine"
                  | "rtInteger"
                  | "rtIntegerParseInt"
                  | "rtSystemIn"
                  | "rtScannerNextInt"
                  | "methodGetClass" "(" K ")"
                  | "classObject" "(" Id ")"
                  | "methodClassGetName" "(" K ")"

syntax RawVal ::= "rtSymbolicConsoleLine"
                | "rtScanner"

rule [NameSystem]:
    'ExprName(X:Id) => rtSystem
when
    Id2String(X) ==String "System"

rule [NameSystemConsole]:
    'MethodName(rtSystem,, X:Id) => rtSystemConsole
when
    Id2String(X) ==String "console"

rule [InvokeSystemConsole]:
    'Invoke(rtSystemConsole,, 'ListWrap(.List{K})) => rtSystemConsole

rule [NameSystemConsoleReadLine]:
    'MethodName(rtSystemConsole,, X:Id) => rtSystemConsoleReadLine
when
    Id2String(X) ==String "readLine"

rule [InvokeSystemConsoleReadLine]:
    'Invoke(rtSystemConsoleReadLine,, 'ListWrap(.List{K}))
    => rtSymbolicConsoleLine :: rtString

rule [NameInteger]:
    'ExprName(X:Id) => rtInteger
when
    Id2String(X) ==String "Integer"

rule [NameIntegerParseInt]:
    'MethodName(rtInteger,, X:Id) => rtIntegerParseInt
when
    Id2String(X) ==String "parseInt"

rule [consoleReadInt]:
    <k>
      'Invoke(rtIntegerParseInt,, 'ListWrap(rtSymbolicConsoleLine :: rtString))
      => I:Int :: int
      ...
    </k>
    <in> ListItem(I) => . ...</in>
        [transition]

//@ For integers and strings, print their value. For classes, print class type.

rule [NameSystemOut]:
    'ExprName(rtSystem,, X:Id) => rtSystemOut
when
    Id2String(X) ==String "out"

rule [NameSystemOutPrint]:
    'MethodName(rtSystemOut,, X:Id) => rtSystemOutPrint
when
    Id2String(X) ==String "print"

rule [NameSystemOutPrintln]:
    'MethodName(rtSystemOut,, X:Id) => rtSystemOutPrintln
when
    Id2String(X) ==String "println"

rule [printlnDesugar]:
    'Invoke(rtSystemOutPrintln,, 'ListWrap(KR:KResult))
    => 'Invoke(rtSystemOutPrint,, 'ListWrap('Plus(KR:KResult,,"\n"::rtString)))

rule [printlnEmptyDesugar]:
    'Invoke(rtSystemOutPrintln,, 'ListWrap(.List{K}))
    => 'Invoke(rtSystemOutPrint,, 'ListWrap("\n"::rtString))

rule [consolePrintArgConvert]:
    'Invoke(rtSystemOutPrint,, 'ListWrap(KR:KResult => toString(KR)))
when
    typeOf(KR) =/=K rtString

rule [consolePrint]:
    <k>
      'Invoke(rtSystemOutPrint,, 'ListWrap(Str:String :: rtString))
      => nothing::void
      ...
    </k>
    <out>... .=> ListItem(Str) </out>
        [transition]

rule [NameSystemIn]:
    'ExprName(rtSystem,, X:Id) => rtSystemIn
when
    Id2String(X) ==String "in"

rule [NewInstanceScanner]:
    'NewInstance('None(.List{K}),,
      'ClassOrInterfaceType(
        'TypeName(X:Id),,
        'None(.List{K})
      ),,
      'ListWrap(rtSystemIn),,
      'None(.List{K})
    )
    => rtScanner :: class X
when
    Id2String(X) ==String "Scanner"

rule [ScannerNextInt]:
    'MethodName(rtScanner::_,, X:Id) => rtScannerNextInt
when
    Id2String(X) ==String "nextInt"

rule [InvokeScannerNextInt]:
    <k>
      'Invoke(rtScannerNextInt,, 'ListWrap(.List{K}))
      => I:Int :: int
      ...
    </k>
    <in> ListItem(I) => . ...</in>
        [transition]

rule [NameGetClass]:
    'MethodName(KR:KResult,, X:Id) => methodGetClass(KR)
when
    Id2String(X) ==String "getClass"

rule [InvokeGetClass]:
    'Invoke(
      methodGetClass(
        objectClosure((_ <envStack>ListItem((Class:Id, _))...</envStack>))::_
      ),,
      'ListWrap(.List{K})
    ) => classObject(Class)

rule [NameClassGetName]:
    'MethodName(classObject(Class:Id),, X:Id)
    => methodClassGetName(classObject(Class))
when
    Id2String(X) ==String "getName"

rule [InvokeClassGetName]:
    'Invoke(
      methodClassGetName(classObject(Class:Id)),,
      'ListWrap(.List{K})
    ) => toString(class Class)

endmodule
