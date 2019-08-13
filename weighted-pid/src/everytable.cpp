#include "tables.h"
#include "pid.h"
#include "util.h"

auto main() -> int {
	auto const N = 2;

    for (auto const &table: LogicTables{N}) {
        auto lattice = pid(table);

        std::cout << table.response << ":\n";
        std::for_each(lattice->sources, lattice->sources + lattice->size, [](inform_pid_source const *src) {
            if (src->pi >= 1e-6) {
                std::cout << source_label(src) << '\n';
            }
        });
        std::cout << std::flush;

        inform_pid_lattice_free(lattice);
    }
}
