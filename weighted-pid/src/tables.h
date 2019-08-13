#pragma once

#include <cstdlib>
#include <vector>
#include <iostream>

class VectorsIterator {
	public:
    	size_t n;
    	size_t element;
    	size_t volume;
    	std::vector<int> store;
    	
    	VectorsIterator() = default;
        VectorsIterator(size_t n, bool done = false);
    
        VectorsIterator(VectorsIterator const&) = default;
        VectorsIterator(VectorsIterator&&) = default;
    
        auto operator=(VectorsIterator const&) -> VectorsIterator& = default;
        auto operator=(VectorsIterator&&) -> VectorsIterator& = default;
    
        auto operator*() const -> std::vector<int> const&;
        
        auto operator->() const -> std::vector<int> const*;
    
        auto operator++() -> VectorsIterator&;
    
        auto operator++(int) -> VectorsIterator;
    
        auto operator!=(VectorsIterator const &other) const -> bool;
};

class Vectors {
    private:
        size_t n;

    public:
        Vectors(size_t n);
		
		Vectors(Vectors const&) = default;
		Vectors(Vectors&&) = default;
		
		auto operator=(Vectors const&) -> Vectors& = default;
		auto operator=(Vectors&&) -> Vectors& = default;

        auto begin() const -> VectorsIterator;

        auto end() const -> VectorsIterator;

        auto size() const -> size_t;
};

class LogicTable {
	public:
		size_t n;
		std::vector<int> signals;
		std::vector<int> response;
		
		LogicTable() = default;
		LogicTable(size_t n, std::vector<int> const &response);
		
		LogicTable(LogicTable const&) = default;
		LogicTable(LogicTable&&) = default;
		
		auto operator=(LogicTable const&) -> LogicTable& = default;
		auto operator=(LogicTable&&) -> LogicTable& = default;
		
		auto size() const -> size_t;
};
		
auto operator<<(std::ostream &out, LogicTable const &table) -> std::ostream&;

class LogicTablesIterator {
	private:
        LogicTable table;
        VectorsIterator response;

	public:
        LogicTablesIterator(size_t n, bool done = false);
    
        LogicTablesIterator(LogicTablesIterator const&) = default;
        LogicTablesIterator(LogicTablesIterator&&) = default;
    
        auto operator=(LogicTablesIterator const&) -> LogicTablesIterator& = default;
        auto operator=(LogicTablesIterator&&) -> LogicTablesIterator& = default;
    
        auto operator*() const -> LogicTable const&;
        
        auto operator->() const -> LogicTable const*;
    
        auto operator++() -> LogicTablesIterator&;
    
        auto operator++(int) -> LogicTablesIterator;
    
        auto operator!=(LogicTablesIterator const &other) const -> bool;
};

class LogicTables {
	private:
		size_t n;
		
	public:
		LogicTables(size_t n);
		
		LogicTables(LogicTables const&) = default;
		LogicTables(LogicTables&&) = default;
		
		auto operator=(LogicTables const&) -> LogicTables& = default;
		auto operator=(LogicTables&&) -> LogicTables& = default;
		
		auto begin() const -> LogicTablesIterator;
		auto end() const -> LogicTablesIterator;
};
