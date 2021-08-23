-- Config { font = "-misc-fixed-*-*-*-*-10-*-*-*-*-*-*-*"
 Config { font = "xft:Dejavu Sans Mono:pixelsize=18:antialias=true:"
 
        , bgColor = "#012312"
        , fgColor = "white"
        , position = Top
        , lowerOnStart = True
        --, commands = [ Run Weather "EGPF" ["-t","<station>: <tempC>C","-L","18","-H","25","--normal","green","--high","red","--low","lightblue"] 36000
        , commands = [ 
     		            Run Date "%a %b %_d %Y %H:%M:%S" "date" 10 
                      , Run Network "eth0" ["-L","0","-H","32","--normal","green","--high","red"] 10
                     --, Run Network "eth1" ["-L","0","-H","32","--normal","green","--high","red"] 10
                     , Run Cpu ["-L","3","-H","50","--normal","green","--high","red"] 10
                     , Run Memory ["-t","Mem: <usedratio>%"] 10
                     , Run Swap [] 10
                    -- , Run Com "uname" ["-s","-r"] "" 36000
                    
                     ]
        , sepChar = "%"
        , alignSep = "}{"
        , template = "%cpu% | %memory% * %swap% | %eth0% | <fc=#ee9a00>%date%</fc>"
        --, template = "%cpu% | %memory% * %swap% | %eth0% - %eth1% }{ <fc=#ee9a00>%date%</fc>| %EGPF% | %uname%"
        }


