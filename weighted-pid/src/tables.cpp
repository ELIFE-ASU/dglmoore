#include "tables.h"
#include "util.h"

#include <algorithm>
#include <stdexcept>

VectorsIterator::VectorsIterator(size_t n, bool done) : n{n}, element{0}, volume{size_t(1 << n)} {
    if (done) {
        this->element = this->volume;
    } else {
        this->store = std::vector<int>(n, 0);
    }
}

auto VectorsIterator::operator*() const -> std::vector<int> const& {
    return this->store;
}

auto VectorsIterator::operator->() const -> std::vector<int> const* {
	return &(this->store);
}

auto VectorsIterator::operator++() -> VectorsIterator& {
    if (this->element != this->volume) {
        for (auto it = this->store.begin(); it != this->store.end(); ++it) {
            if (*it == 0) {
                ++(*it);
                std::fill(this->store.begin(), it, 0);
                break;
            }
        }
        this->element++;
    }
    return *this;
}

auto VectorsIterator::operator++(int) -> VectorsIterator {
    auto temp = *this;
    this->operator++();
    return temp;
}

auto VectorsIterator::operator!=(VectorsIterator const &other) const -> bool {
    return this->element != other.element;
}

Vectors::Vectors(size_t n): n{n} {}

auto Vectors::begin() const -> VectorsIterator {
    return { this->n };
}

auto Vectors::end() const -> VectorsIterator {
    return { this->n, true };
}

auto Vectors::size() const -> size_t {
    return 1 << (1 << n);
}

LogicTable::LogicTable(size_t n, std::vector<int> const &response) {
	if (n == 0) {
		throw std::runtime_error("table size is zero");
	}

	auto const is_binary = std::all_of(std::begin(response), std::end(response), [](int x) {
		return x == 0 || x == 1;
	});

	if (response.size() != (1 << n)) {
		throw std::runtime_error("response vector is inconsistent with table size");
	} else if (!is_binary) {
		throw std::runtime_error("response vector has non-binary values");
	}
	
	this->n = n;
	this->response = response;
	this->signals = std::vector<int>(n * (1 << n));
	
	auto const vectors = Vectors{n};
	for (auto v = std::begin(vectors); v != std::end(vectors); ++v) {
		for (size_t i = 0; i < v->size(); ++i) {
			this->signals.at(i*(1 << n) + v.element) = v->operator[](i);
		}
	}
}

auto LogicTable::size() const -> size_t {
	return (1 << n);
}

auto operator<<(std::ostream &out, LogicTable const &table) -> std::ostream& {
	return out << table.response << '\n' << table.signals;
}

LogicTablesIterator::LogicTablesIterator(size_t n, bool done) {
    if (done) {
        this->response = std::end(Vectors{size_t(1) << n});
    } else {
        this->response = std::begin(Vectors{size_t(1) << n});
        this->table = LogicTable(n, *(this->response));
    }
}

auto LogicTablesIterator::operator*() const -> LogicTable const& {
    return this->table;
}

auto LogicTablesIterator::operator->() const -> LogicTable const* {
	return &(this->table);
}

auto LogicTablesIterator::operator++() -> LogicTablesIterator& {
	++this->response;
	this->table.response = *(this->response);
    return *this;
}

auto LogicTablesIterator::operator++(int) -> LogicTablesIterator {
    auto temp = *this;
    this->operator++();
    return temp;
}

auto LogicTablesIterator::operator!=(LogicTablesIterator const &other) const -> bool {
    return this->response != other.response;
}

LogicTables::LogicTables(size_t n): n{n} {}

auto LogicTables::begin() const -> LogicTablesIterator {
	return { n, false };
}

auto LogicTables::end() const -> LogicTablesIterator {
	return { n, true };
}