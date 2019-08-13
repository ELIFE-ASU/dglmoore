#include "pid.h"

#include <algorithm>
#include <iomanip>
#include <iterator>
#include <numeric>
#include <sstream>

auto source_name(inform_pid_source const *src) -> std::string {
    std::stringstream namestream;
    std::copy(src->name, src->name + src->size, std::ostream_iterator<int>(namestream, " "));
    auto const name = namestream.str();
    return name.substr(0, name.size()-1);
}

auto source_label(inform_pid_source const *src) -> std::string {
    std::stringstream labelstream;
    labelstream << std::setw(4) << std::right << source_name(src)
                << std::setw(10) << std::right << std::setprecision(6) << src->pi;
    return labelstream.str();
}

auto pid(LogicTable const &table) -> inform_pid_lattice* {
	auto const &signals = table.signals;
	auto const &response = table.response;

	auto const bs = std::accumulate(std::begin(response), std::end(response), 2,
		[](int max, int x) {
			return std::max(max, x + 1);
		});
	
	auto const b = std::accumulate(std::begin(signals), std::end(signals), 2,
		[](int max, int x) {
			return std::max(max, x + 1);
		});
	
	auto const br = std::vector<int>(table.n, b);

    inform_error err = INFORM_SUCCESS;
    auto pid = inform_pid(response.data(), signals.data(), br.size(), response.size(), bs, br.data(), &err);
    if (err) {
        throw std::runtime_error(inform_strerror(&err));
    }
    
    return pid;
}
