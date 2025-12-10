%skeleton "lalr1.cc"
%require "3.5"

%defines
%define api.token.constructor
%define api.value.type variant
%define parse.assert

%code requires {
    #include <functional>
    #include <list>
    #include <string>
    #include <variant>
  
    class Scanner;
    class Driver;

    using Command = std::function<void()>;
}


%define parse.trace
%define parse.error verbose

%code {
    #include "driver.hh"
    #include "location.hh"

    /* Redefine parser to use our function from scanner */
    static yy::parser::symbol_type yylex(Scanner &scanner) {
        return scanner.ScanToken();
    }
    
    inline Command generate_for_loop(Driver& driver,
                                     auto start_name,
                                     auto end_name,
                                     auto is_increment,
                                     auto iter_name,
                                     auto cond_mode,
                                     auto cond_lambda,
                                     auto body) {
        return 
             [&driver ,
              start_name      = std::move(start_name),
              end_name        = std::move(end_name),
              is_increment    = std::move(is_increment),
              iter_name       = std::move(iter_name),
              cond_mode       = std::move(cond_mode),
              cond_lambda     = std::move(cond_lambda),
              body            = std::move(body)]()
        {
            bool created = false;
            if (driver.variables.find(iter_name) == driver.variables.end()) {
                driver.variables.emplace(iter_name, 0);
                created = true;
            }

            auto& it = driver.variables[iter_name];
            if (!std::holds_alternative<int>(it)) {
                std::cerr << "Iterator must be integer" << std::endl;
                throw std::invalid_argument("Iterator must be integer");
            }
  
            it = 0;

            int step = is_increment ? 1 : -1;

            while (true) {
                auto cond_val = std::invoke(cond_lambda);
                
                if (!std::holds_alternative<bool>(cond_val)) {
                    std::cerr << "For condition must be bool" << std::endl;
                    throw std::invalid_argument("For condition must be bool");
                }
               
                bool cond = std::get<bool>(cond_val);
                if (cond != cond_mode) {
                    break;
                }

                for (auto& cmd : body) {
                    std::invoke(cmd);
                }

                std::get<int>(it) += step;
           }

            if (created) {
                driver.variables.erase(iter_name);
            }
        }; 
    }

    inline Command generate_while_loop(Driver& driver,
                                     auto start_name,
                                     auto end_name,
                                     auto cond_mode,
                                     auto cond_lambda,
                                     auto body) {
        return 
             [&driver ,
              start_name      = std::move(start_name),
              end_name        = std::move(end_name),
              cond_mode       = std::move(cond_mode),
              cond_lambda     = std::move(cond_lambda),
              body            = std::move(body)]()
        {
            while (true) {
                auto cond_val = std::invoke(cond_lambda);

                if (!std::holds_alternative<bool>(cond_val)) {
                    std::cerr << "While condition must be bool" << std::endl;
                    throw std::invalid_argument("While condition must be bool");
                }

                bool cond = std::get<bool>(cond_val);
                if (cond != cond_mode) {
                    break;
                }

                for (auto& cmd : body) {
                    std::invoke(cmd);
                }
            }
        }; 
    }

}

%lex-param { Scanner &scanner }

%parse-param { Scanner &scanner }
%parse-param { Driver &driver }

%locations

%define api.token.prefix {TOK_}
%token
    END 0 "end of file"
    START "HAI 1.3"
    STOP "KTHXBYE"
    LET "I HAS A"
    ASSIGN "R"
    PRINT "VISIBLE"
    DIFF "DIFF OF"
    SUM "SUM OF"
    MUL "PRODUKT OF"
    DIV "QUOSHUNT OF"
    MOD "MOD OF"
    MAX "BIGGR OF"
    MIN "SMALLR OF"
    EXP_SEP "AN"
    INIT_SEP "ITZ"
    FALSE "FAIL"
    TRUE "WIN"
    AND "BOTH OF"
    OR "EITHER OF"
    XOR "WON OF"
    NOT "NOT"
    IF_START ", O RLY?"
    IF "YA RLY"
    ELIF "MEBBE"
    ELSE "NO WAI"
    IF_END "OIC"
    EQ "BOTH SAEM"
    NOT_EQ "DIFFRINT"
    CONCAT_START "SMOOSH"
    CONCAT_END "MKAY"
    LOOP_START "IM IN YR"
    LOOP_END "IM OUTTA YR"
;

%token <bool> INCR
%token <bool> DECR
%token <bool> TIL
%token <bool> WILE

%token <std::string> IDENTIFIER
%token <int> INT_NUMBER
%token <std::string> STRING

%nterm <std::vector<Command>> commands
%nterm <Command> command
%nterm <Command> initialization
%nterm <Command> print
%nterm <Command> assignment
%nterm <Command> if_statement
%nterm <Command> for_cycle
%nterm <Command> while_cycle
%nterm <std::function<bool()>> elif_block
%nterm <std::list<std::function<std::variant<int, bool, std::string, std::nullptr_t>()>>> concat_chain
%nterm <std::function<std::variant<int, bool, std::string, std::nullptr_t>()>> exp

%%
%start unit;

unit:
    START commands STOP {
        for (auto& x : $2) {
            std::invoke(x);
        }
    };

commands:
    %empty { $$ = std::vector<Command>(); };
    | commands command { $$ = $1; $$.emplace_back($2); };

command:
    assignment { $$ = std::move($1); };
    | initialization { $$ = std::move($1); };
    | print { $$ = std::move($1); };
    | exp { $$ = [this, lambda = $1]() { std::invoke(lambda); }; };
    | if_statement { $$ = std::move($1); };
    | for_cycle { $$ = std::move($1); };
    | while_cycle { $$ = std::move($1); };

initialization:
    LET IDENTIFIER INIT_SEP exp {
        $$ = [this, name = std::move($2), lambda = std::move($4)]() {
            driver.variables[name] = std::invoke(lambda);
            if (driver.location_debug) {
                std::cerr << driver.location << std::endl;
            }
        };
    };

print:
    PRINT exp {
        $$ = [this, lambda = std::move($2)]() {
            auto val = std::invoke(lambda);
            if (std::holds_alternative<int>(val)) {
                std::cout << std::get<int>(val) << std::endl;
            } else if (std::holds_alternative<bool>(val)) {
                if (std::get<bool>(val)) {
                    std::cout << "WIN" << std::endl;
                } else {
                    std::cout << "FAIL" << std::endl;
                }
            } else if (std::holds_alternative<std::string>(val)) {
                std::cout << std::get<std::string>(val) << std::endl;
            } else {
                std::cerr << "Cannot implicitly cast nil" << std::endl;
                throw std::runtime_error("Cannot print NOOB type");
            }
        };
    };

assignment:
    IDENTIFIER ASSIGN exp {
        $$ = [this, name = std::move($1), lambda = std::move($3)]() {
            driver.variables[name] = std::invoke(lambda);
            if (driver.location_debug) {
                std::cerr << driver.location << std::endl;
            }
        };
    };

exp:
    IDENTIFIER {
        $$ = [this, name = $1]() -> std::variant<int, bool, std::string, std::nullptr_t> {
            if (driver.variables.find(name) == driver.variables.end()) {
                std::cerr << "Using undeclared variable: " << name << std::endl;
                throw std::runtime_error("Undeclared variable");
            }
            auto& val = driver.variables[name];
            if (std::holds_alternative<int>(val)) {
                return std::get<int>(val);
            } else if (std::holds_alternative<bool>(val)) {
                return std::get<bool>(val);
            } else if (std::holds_alternative<std::string>(val)) {
                return std::get<std::string>(val);
            } else {
                return nullptr;
            }
        };
    };

    | STRING { 
        $$ = [val = $1]() -> std::variant<int, bool, std::string, std::nullptr_t> {
            return val;
        };
    };

    | CONCAT_START concat_chain CONCAT_END {
        $$ = [this, list = std::move($2)]() -> std::variant<int, bool, std::string, std::nullptr_t> {
            std::string result;
            for (auto& lambda : list) {
                auto val = std::invoke(lambda);
                if (std::holds_alternative<std::nullptr_t>(val)) {
                    std::cerr << "Cannot concat NOOB type";
                    throw std::runtime_error("Cannot concat NOOB type");
                } else if (std::holds_alternative<int>(val)) {
                    result += std::to_string(std::get<int>(val));
                } else if (std::holds_alternative<bool>(val)) {
                    if (std::get<bool>(val)) {
                        result += "WIN";
                    } else {
                        result += "FAIL";
                    }
                } else {
                    result += std::get<std::string>(val);
                }
            }
            return result;
        };
    };

    | TRUE {
        $$ = []() -> std::variant<int, bool, std::string, std::nullptr_t> {
            return true;
        };
    };

    | FALSE {
        $$ = []() -> std::variant<int, bool, std::string, std::nullptr_t> {
            return false;
        };
    };

    | AND exp EXP_SEP exp {
        $$ = [this, lambda1 = $2, lambda2 = $4]() -> std::variant<int, bool, std::string, std::nullptr_t> {
            auto val1 = std::invoke(lambda1);
            auto val2 = std::invoke(lambda2);
            if (std::holds_alternative<bool>(val1) && std::holds_alternative<bool>(val2)) {
                return std::get<bool>(val1) && std::get<bool>(val2);
            }
            std::cerr << "Arguments of BOTH OF must be bool" << std::endl;
            throw std::invalid_argument("Arguments of BOTH OF must be bool");
        };
    };

    | OR  exp EXP_SEP exp {
        $$ = [this, lambda1 = $2, lambda2 = $4]() -> std::variant<int, bool, std::string, std::nullptr_t> {
            auto val1 = std::invoke(lambda1);
            auto val2 = std::invoke(lambda2);
            if (std::holds_alternative<bool>(val1) && std::holds_alternative<bool>(val2)) {
                return std::get<bool>(val1) || std::get<bool>(val2);
            }
            std::cerr << "Arguments of EITHER OF must be bool" << std::endl;
            throw std::invalid_argument("Arguments of EITHER OF must be bool");
        };
    };

    | XOR exp EXP_SEP exp {
        $$ = [this, lambda1 = $2, lambda2 = $4]() -> std::variant<int, bool, std::string, std::nullptr_t> {
            auto val1 = std::invoke(lambda1);
            auto val2 = std::invoke(lambda2);
            if (std::holds_alternative<bool>(val1) && std::holds_alternative<bool>(val2)) {
                return std::get<bool>(val1) != std::get<bool>(val2);
            }
            std::cerr << "Arguments of WON OF must be bool" << std::endl;
            throw std::invalid_argument("Arguments of WON OF must be bool");
        };
    };

    | NOT exp {
        $$ = [this, lambda = $2]() -> std::variant<int, bool, std::string, std::nullptr_t> {
            auto val = std::invoke(lambda);
            if (std::holds_alternative<bool>(val)) {
                return !std::get<bool>(val);
            }
            std::cerr << "Argument of NOT must be bool" << std::endl;
            throw std::invalid_argument("Argument of NOT must be bool");
        };
    };

    | INT_NUMBER {
        $$ = [val = $1]() -> std::variant<int, bool, std::string, std::nullptr_t> {
            return val;
        };
    };

    | SUM  exp EXP_SEP exp  {
        $$ = [this, lambda1 = $2, lambda2 = $4]() -> std::variant<int, bool, std::string, std::nullptr_t> {
            auto val1 = std::invoke(lambda1);
            auto val2 = std::invoke(lambda2);
            if (std::holds_alternative<int>(val1) && std::holds_alternative<int>(val2)) {
                return std::get<int>(val1) + std::get<int>(val2);
            }
            std::cerr << "Arguments of SUM OF must be integer" << std::endl;
            throw std::invalid_argument("Arguments of SUM OF must be integer");
        };
    };

    | DIFF exp EXP_SEP exp {
        $$ = [this, lambda1 = $2, lambda2 = $4]() -> std::variant<int, bool, std::string, std::nullptr_t> {
            auto val1 = std::invoke(lambda1);
            auto val2 = std::invoke(lambda2);
            if (std::holds_alternative<int>(val1) && std::holds_alternative<int>(val2)) {
                return std::get<int>(val1) - std::get<int>(val2);
            }
            std::cerr << "Arguments of DIFF OF must be integer" << std::endl;
            throw std::invalid_argument("Arguments of DIFF OF must be integer");
        };
    };

    | MUL  exp EXP_SEP exp  {
        $$ = [this, lambda1 = $2, lambda2 = $4]() -> std::variant<int, bool, std::string, std::nullptr_t> {
            auto val1 = std::invoke(lambda1);
            auto val2 = std::invoke(lambda2);
            if (std::holds_alternative<int>(val1) && std::holds_alternative<int>(val2)) {
                return std::get<int>(val1) * std::get<int>(val2);
            }
            std::cerr << "Arguments of PRODUKT OF must be integer" << std::endl;
            throw std::invalid_argument("Arguments of PRODUKT OF must be integer");
        };
    };

    | DIV  exp EXP_SEP exp  {
        $$ = [this, lambda1 = $2, lambda2 = $4]() -> std::variant<int, bool, std::string, std::nullptr_t> {
            auto val1 = std::invoke(lambda1);
            auto val2 = std::invoke(lambda2);
            if (std::holds_alternative<int>(val1) && std::holds_alternative<int>(val2)) {
                return std::get<int>(val1) / std::get<int>(val2);
            }
            std::cerr << "Arguments of QUOSHUNT OF must be integer" << std::endl;
            throw std::invalid_argument("Arguments of QUOSHUNT OF must be integer");
        };
    };

    | MOD  exp EXP_SEP exp  {
        $$ = [this, lambda1 = $2, lambda2 = $4]() -> std::variant<int, bool, std::string, std::nullptr_t> {
            auto val1 = std::invoke(lambda1);
            auto val2 = std::invoke(lambda2);
            if (std::holds_alternative<int>(val1) && std::holds_alternative<int>(val2)) {
                return std::get<int>(val1) % std::get<int>(val2);
            }
            std::cerr << "Arguments of MOD OF must be integer" << std::endl;
            throw std::invalid_argument("Arguments of MOD OF must be integer");
        };
    };

    | MAX  exp EXP_SEP exp  {
        $$ = [this, lambda1 = $2, lambda2 = $4]() -> std::variant<int, bool, std::string, std::nullptr_t> {
            auto val1 = std::invoke(lambda1);
            auto val2 = std::invoke(lambda2);
            if (std::holds_alternative<int>(val1) && std::holds_alternative<int>(val2)) {
                return std::max(std::get<int>(val1), std::get<int>(val2));
            }
            std::cerr << "Arguments of BIGGR OF must be integer" << std::endl;
            throw std::invalid_argument("Arguments of BIGGR OF must be integer");
        };
    };

    | MIN  exp EXP_SEP exp  {
        $$ = [this, lambda1 = $2, lambda2 = $4]() -> std::variant<int, bool, std::string, std::nullptr_t> {
            auto val1 = std::invoke(lambda1);
            auto val2 = std::invoke(lambda2);
            if (std::holds_alternative<int>(val1) && std::holds_alternative<int>(val2)) {
                return std::min(std::get<int>(val1), std::get<int>(val2));
            }
            std::cerr << "Arguments of SMALLR OF must be integer" << std::endl;
            throw std::invalid_argument("Arguments of SMALLR OF must be integer");
        };
    };

    | EQ exp EXP_SEP exp {
        $$ = [this, lambda1 = $2, lambda2 = $4]() -> std::variant<int, bool, std::string, std::nullptr_t> {
            auto val1 = std::invoke(lambda1);
            auto val2 = std::invoke(lambda2);
            if ((std::holds_alternative<int>(val1) && std::holds_alternative<int>(val2)) ||
                (std::holds_alternative<bool>(val1) && std::holds_alternative<bool>(val2)) ||
                (std::holds_alternative<std::string>(val1) && std::holds_alternative<std::string>(val2)) ||
                (std::holds_alternative<std::nullptr_t>(val1) && std::holds_alternative<std::nullptr_t>(val2))) {
                return val1 == val2;
            } else {
                std::cerr << "Arguments must have same type" << std::endl;
                throw std::invalid_argument("Arguments must have same type");
            } 
        };
    }
    | NOT_EQ exp EXP_SEP exp {
        $$ = [this, lambda1 = $2, lambda2 = $4]() -> std::variant<int, bool, std::string, std::nullptr_t> {
            auto val1 = std::invoke(lambda1);
            auto val2 = std::invoke(lambda2);
            if ((std::holds_alternative<int>(val1) && std::holds_alternative<int>(val2)) ||
                (std::holds_alternative<bool>(val1) && std::holds_alternative<bool>(val2)) ||
                (std::holds_alternative<std::string>(val1) && std::holds_alternative<std::string>(val2)) ||
                (std::holds_alternative<std::nullptr_t>(val1) && std::holds_alternative<std::nullptr_t>(val2))) {
                return val1 != val2;
            } else {
                std::cerr << "Arguments must have same type" << std::endl;
                throw std::invalid_argument("Arguments must have same type");
            } 
        };
    }

concat_chain:
    exp { $$ = std::list<std::function<std::variant<int, bool, std::string, std::nullptr_t>()>>(1, $1); };
    | concat_chain EXP_SEP exp { $$ = std::move($1); $$.push_back(std::move($3)); };

if_statement:
    exp IF_START IF commands elif_block ELSE commands IF_END {
        $$ = [this, cond_lambda = $1, if_commands = std::move($4), elif_command = $5, else_commands = std::move($7)]() {
            auto val = std::invoke(cond_lambda);
            if (!std::holds_alternative<bool>(val)) {
                std::cerr << "Expression in if statement must be bool type" << std::endl;
                throw std::invalid_argument("Expression in if statement must be bool type");
            }
            if (std::get<bool>(val)) {
                for (auto& command : if_commands) {
                    std::invoke(command);
                }
            } else {
                bool result = std::invoke(elif_command);
                if (!result) {
                    for (auto& command : else_commands) {
                        std::invoke(command);
                    }
                }
            }
        };

    }
    | exp IF_START IF commands elif_block IF_END {
        $$ = [this, cond_lambda = $1, commands = std::move($4), elif_command = $5]() {
            auto val = std::invoke(cond_lambda);
            if (!std::holds_alternative<bool>(val)) {
                std::cerr << "Expression in if statement must be bool type" << std::endl;
                throw std::invalid_argument("Expression in if statement must be bool type");
            }
            if (std::get<bool>(val)) {
                for (auto& command : commands) {
                    std::invoke(command);
                }
            } else {
                std::invoke(elif_command);
            }
        };
    }

elif_block:
    %empty { $$ = []() -> bool { return false; }; }
    | elif_block "MEBBE" exp commands {
        $$ = [this, prev_part = std::move($1), cond_lambda = $3, commands = std::move($4)]() -> bool {
            bool result = std::invoke(prev_part);
            if (result) {
                return true;
            }
            auto val = std::invoke(cond_lambda);
            if (!std::holds_alternative<bool>(val)) {
                std::cerr << "Expression in if statement must be bool type" << std::endl;
                throw std::invalid_argument("Expression in if statement must be bool type");
            }
            if (std::get<bool>(val)) {
                for (auto& command : commands) {
                    std::invoke(command);
                }
                return true;
            }
            return false;
        };
    }

for_cycle:
    LOOP_START IDENTIFIER INCR IDENTIFIER TIL exp commands LOOP_END IDENTIFIER {
        $$ = generate_for_loop(driver, $2, $9, $3, $4, $5, $6, $7);
    }
    | LOOP_START IDENTIFIER DECR IDENTIFIER TIL exp commands LOOP_END IDENTIFIER {
        $$ = generate_for_loop(driver, $2, $9, $3, $4, $5, $6, $7);
    }
    | LOOP_START IDENTIFIER INCR IDENTIFIER WILE exp commands LOOP_END IDENTIFIER {
        $$ = generate_for_loop(driver, $2, $9, $3, $4, $5, $6, $7);
    }
    | LOOP_START IDENTIFIER DECR IDENTIFIER WILE exp commands LOOP_END IDENTIFIER {
        $$ = generate_for_loop(driver, $2, $9, $3, $4, $5, $6, $7);
    }

while_cycle:
    LOOP_START IDENTIFIER TIL exp commands LOOP_END IDENTIFIER {
        $$ = generate_while_loop(driver, $2, $7, $3, $4, $5);
    }
    | LOOP_START IDENTIFIER WILE exp commands LOOP_END IDENTIFIER {
        $$ = generate_while_loop(driver, $2, $7, $3, $4, $5);
    }

%%

void
yy::parser::error(const location_type& l, const std::string& m)
{
  std::cerr << l << ": " << m << '\n';
}

