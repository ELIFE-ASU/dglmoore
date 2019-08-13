#pragma once

#include <algorithm>
#include <iostream>
#include <iterator>
#include <vector>

template <typename T>
auto operator<<(std::ostream &out, std::vector<T> const& v) -> std::ostream& {
    std::copy(std::begin(v), std::end(v), std::ostream_iterator<T>(out, " "));
    return out;
}
