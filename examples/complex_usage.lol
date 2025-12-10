HAI 1.3

I HAS A x ITZ 0
I HAS A result ITZ 0
I HAS A name ITZ "Alexey"
I HAS A loop_limit ITZ 5

IM IN YR loop UPPIN YR x TIL BOTH SAEM x AN loop_limit
    result R SUM OF result AN x
    BOTH SAEM x AN 3, O RLY?
        YA RLY
            VISIBLE SMOOSH name AN " reached 3 at iteration " AN x MKAY
        NO WAI
            VISIBLE SMOOSH "Iteration " AN x AN " continues" MKAY
    OIC
IM OUTTA YR loop

BOTH SAEM result AN BIGGR OF result AN 10, O RLY?
    YA RLY
        VISIBLE SMOOSH "Result is big: " AN result MKAY
    NO WAI
        VISIBLE SMOOSH "Result is small: " AN result MKAY
OIC

I HAS A outer_limit ITZ 2
I HAS A inner_limit ITZ 2
I HAS A outer_counter ITZ 0
I HAS A inner_counter ITZ 0

IM IN YR outer_loop UPPIN YR outer_counter TIL BOTH SAEM outer_counter AN outer_limit
    IM IN YR inner_loop UPPIN YR inner_counter TIL BOTH SAEM inner_counter AN inner_limit
        BOTH SAEM outer_counter AN 1, O RLY?
            YA RLY
                VISIBLE SMOOSH "Inner " AN inner_counter AN " in outer 1" MKAY
            NO WAI
                VISIBLE SMOOSH "Inner " AN inner_counter AN " in outer " AN outer_counter MKAY
        OIC
    IM OUTTA YR inner_loop
IM OUTTA YR outer_loop

KTHXBYE

