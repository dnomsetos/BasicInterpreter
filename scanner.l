%{

    #include <cerrno>
    #include <climits>
    #include <cstdlib>
    #include <cstring> // strerror
    #include <string>
    #include <iostream>
    #include "driver.hh"
    #include "parser.hh"
%}

%option noyywrap nounput noinput batch debug

%option c++
%option yyclass="Scanner"

%{
  // Code definitions at the end of scanner.cpp

  // A number symbol corresponding to the value in S.
  yy::parser::symbol_type make_INT_NUMBER(
    const std::string &s,
    const yy::parser::location_type& loc
  );

  void Scanner::UpdateLocation() {
    if (driver.location_debug) {
        std::cerr << "Action called " << driver.location << std::endl;
    }
    driver.location.columns(yyleng);
  }
%}

id    [a-zA-Z][a-zA-Z_0-9]*
int   -?[0-9]+
blank [ \r\n]

%{
  // Code run each time a pattern is matched.
  #define YY_USER_ACTION UpdateLocation();
%}

%%


%{
  // A handy shortcut to the location held by the driver.
  yy::location& loc = driver.location;
  if (driver.location_debug) {
  // Code run each time yylex is called.
    std::cerr << "BEFORE " << loc << std::endl;
  }
  // loc.step();
  if (driver.location_debug) {
    std::cerr << "AFTER " <<  loc << std::endl;
  }
%}

{blank}+   {
    if (driver.location_debug) {
        std::cerr << "Blank matched" << std::endl;
    }
    // loc.step();
}
\n+ {
    if (driver.location_debug) {
        std::cerr << "EOL called" << std::endl;
    }
    loc.lines(yyleng);
    loc.step();
}

"I HAS A"     return yy::parser::make_LET         (loc);
"DIFF OF"     return yy::parser::make_DIFF        (loc);
"SUM OF"      return yy::parser::make_SUM         (loc);
"PRODUKT OF"  return yy::parser::make_MUL         (loc);
"QUOSHUNT OF" return yy::parser::make_DIV         (loc);
"MOD OF"      return yy::parser::make_MOD         (loc);
"BIGGR OF"    return yy::parser::make_MAX         (loc);
"SMALLR OF"   return yy::parser::make_MIN         (loc);
"R"           return yy::parser::make_ASSIGN      (loc);
"AN"          return yy::parser::make_EXP_SEP     (loc);
"ITZ"         return yy::parser::make_INIT_SEP    (loc);
"FAIL"        return yy::parser::make_FALSE       (loc);
"WIN"         return yy::parser::make_TRUE        (loc);
"BOTH OF"     return yy::parser::make_AND         (loc);
"EITHER OF"   return yy::parser::make_OR          (loc);
"WON OF"      return yy::parser::make_XOR         (loc);
"NOT"         return yy::parser::make_NOT         (loc);
", O RLY?"    return yy::parser::make_IF_START    (loc);
"YA RLY"      return yy::parser::make_IF          (loc);
"MEBBE"       return yy::parser::make_ELIF        (loc);
"NO WAI"      return yy::parser::make_ELSE        (loc);
"OIC"         return yy::parser::make_IF_END      (loc);
"BOTH SAEM"   return yy::parser::make_EQ          (loc);
"DIFFRINT"    return yy::parser::make_NOT_EQ      (loc);
"SMOOSH"      return yy::parser::make_CONCAT_START(loc);
"MKAY"        return yy::parser::make_CONCAT_END  (loc);
"IM IN YR"    return yy::parser::make_LOOP_START  (loc);
"UPPIN YR"    return yy::parser::make_INCR        (true, loc);
"NERFIN YR"   return yy::parser::make_DECR        (false, loc);
"TIL"         return yy::parser::make_TIL         (false, loc);
"WILE"        return yy::parser::make_WILE        (true, loc);
"IM OUTTA YR" return yy::parser::make_LOOP_END    (loc);
"VISIBLE"     return yy::parser::make_PRINT       (loc);
"HAI 1.3"     return yy::parser::make_START       (loc);
"KTHXBYE"     return yy::parser::make_STOP        (loc);

\"([^\"\\]|\\.)*\"  {
                        std::string raw = yytext;
                        std::string value = raw.substr(1, raw.size() - 2);
                        return yy::parser::make_STRING(value, loc);
                    }

{int}      return make_INT_NUMBER(yytext, loc);
{id}       {
                std::string name = yytext;
                if (driver.location_debug) {
                    std::cerr << "ID found " << yytext << std::endl;
                }
                return yy::parser::symbol_type(yy::parser::make_IDENTIFIER(name, loc));
           }
.          {
                throw yy::parser::syntax_error(loc, "invalid character: " + std::string(yytext));
           }
<<EOF>>    return yy::parser::make_END (loc);
%%

yy::parser::symbol_type make_INT_NUMBER(
  const std::string &s,
  const yy::parser::location_type& loc
) {
  errno = 0;
  long n = strtol(s.c_str(), NULL, 10);
  if (! (INT_MIN <= n && n <= INT_MAX && errno != ERANGE))
    throw yy::parser::syntax_error(loc, "integer is out of range: " + s);
  return yy::parser::make_INT_NUMBER((int) n, loc);
}

