from itertools import islice
from neet.boolean.examples import myeloid
from randnet import FixedMeanDegree, NetworkRandomizer
import networkx as nx
import numpy as np

N, m, p = 100, 10, 0.15

def show_table(net):
    for row in net.table:
        print(row)
    print()

def show_graph(g):
    for i in g.nodes:
        print(i, list(g.predecessors(i)))
    print()

def fixed_structure_example():
    np.random.seed(2020)
    print('Fixed Structure Example')
    print('  Before:')
    show_table(myeloid)
    print('  After:')
    show_table(NetworkRandomizer(myeloid).random())

def fixed_mean_degree_example():
    np.random.seed(2020)
    print('Fixed Mean-Degree Example')
    print('  Before:')
    show_table(myeloid)
    print('  After:')
    show_table(NetworkRandomizer(myeloid, FixedMeanDegree(myeloid)).random())

def first_constrained_example():
    print('First Constrained Example')
    np.random.seed(2020)
    g = nx.erdos_renyi_graph(m, p, directed=True, seed=np.random)
    gen = FixedMeanDegree(g)

    n = sum(map(nx.is_weakly_connected, islice(gen, N)))
    print('  {}% connected networks without constraint'.format(100*n/N))

    gen.add_constraint(nx.is_weakly_connected)
    n = sum(map(nx.is_weakly_connected, islice(gen, N)))
    print('  {}% connected networks with constraint'.format(100*n/N))

def second_constrained_example():
    print('Second Constrained Example')

    def is_connected(net):
        return nx.is_weakly_connected(net.network_graph())

    np.random.seed(2020)
    g = nx.erdos_renyi_graph(m, p, directed=True, seed=np.random)
    gen = NetworkRandomizer(g, FixedMeanDegree(g))

    n = sum(map(is_connected, islice(gen, N)))
    print('  {}% connected networks without constraint'.format(100*n/N))

    gen.add_constraint(is_connected)
    n = sum(map(is_connected, islice(gen, N)))
    print('  {}% connected networks with constraint'.format(100*n/N))

def main():
    fixed_structure_example()
    fixed_mean_degree_example()

    # There seems to be some leaky random state. If I chance the order of
    # these, despite the fact that we are seeding the RNG inside the functions,
    # the results change.
    second_constrained_example()
    first_constrained_example()

if __name__ == '__main__':
    main()
