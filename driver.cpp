#include "driver.hh"
#include "parser.hh"



Driver::Driver() :
    trace_parsing(false),
    trace_scanning(false),
    location_debug(false),
    scanner(*this), parser(scanner, *this) {
    // variables["one"] = 1;
    // variables["two"] = 2;
}


int Driver::parse(const std::string& f) {
    file = f;
    // initialize location positions
    location.initialize(&file);
    scan_begin();
    parser.set_debug_level(trace_parsing);
    parser();
    scan_end();
    result = 0;
    return result;
}

void Driver::scan_begin() {
    scanner.set_debug(trace_scanning);
  if (file.empty () || file == "-") {
  } else {
    stream.open(file);

    // Restart scanner resetting buffer!
    scanner.yyrestart(&stream);
  }
}

void Driver::scan_end()
{
    stream.close();
}

