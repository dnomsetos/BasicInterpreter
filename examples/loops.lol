HAI 1.3

I HAS A counter ITZ 0
I HAS A sum ITZ 0

I HAS A LIMIT ITZ 5

IM IN YR LOOP UPPIN YR counter TIL BOTH SAEM counter AN LIMIT
    VISIBLE counter
    sum R SUM OF sum AN counter
IM OUTTA YR LOOP

VISIBLE SMOOSH "Sum from 0 to 4: " AN sum MKAY

IM IN YR LOOP WILE DIFFRINT counter AN -3
    VISIBLE counter
    counter R DIFF OF counter AN 1
IM OUTTA YR LOOP

I HAS A outer_limit ITZ 2
I HAS A inner_limit ITZ 3
I HAS A outer_counter ITZ 0
I HAS A inner_counter ITZ 0

IM IN YR LOOP UPPIN YR outer_counter TIL BOTH SAEM outer_counter AN outer_limit
    VISIBLE SMOOSH "Outer: " AN outer_counter MKAY
    IM IN YR LOOP UPPIN YR inner_counter TIL BOTH SAEM inner_counter AN inner_limit
        VISIBLE SMOOSH "Inner: " AN inner_counter MKAY
    IM OUTTA YR LOOP
IM OUTTA YR LOOP

KTHXBYE

