#pragma once

#include <inform/pid.h>
#include <string>
#include "tables.h"

auto source_name(inform_pid_source const&) -> std::string;

auto source_label(inform_pid_source const*) -> std::string;

auto pid(LogicTable const &table) -> inform_pid_lattice*;
