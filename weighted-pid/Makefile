TARGETS=everytable
all: $(TARGETS)

%: src/%.cpp src/pid.cpp src/tables.cpp
	g++ -std=c++17 -g -o $@ $^ -linform

clean:
	rm $(TARGETS)

.PHONY: clean
