from neet.network import Network
from neet.boolean import LogicNetwork
from time import time
import matplotlib.pyplot as plt
import neet.boolean.examples as ex
import numpy as np
import os


def make_network(net, trans):
    """
    Given a network and desired state transitions, construct a `LogicNetwork`
    which implements those transitions.
    """
    table = [(list(range(net.size)), set()) for _ in range(net.size)]
    for a, b in zip(net, map(net.decode, trans)):
        state = ''.join(map(str, a))
        for u, row in zip(b, table):
            if u == 1:
                row[1].add(state)
    return LogicNetwork(table, reduced=True)


def random(net):
    """
    Given a network, construct a `LogicNetwork` whose state-transition graph is
    isomorphic to the original, but with random state transitions.
    """
    trans = net.transitions
    mapping = np.random.permutation(net.volume)
    mapped_trans = np.empty(net.volume, dtype=int)
    for i in range(net.volume):
        x, y = mapping[i], mapping[trans[i]]
        mapped_trans[x] = y
    return make_network(net, mapped_trans)


def main(net, ensemble_size, out_dir):
    """
    Given a network, construct an ensemble of random networks with isomorphic
    state transition graphs, compute the average sensitivity of each, and plot
    the result as a histogram in a specific output directory.
    """
    ss = [random(net).average_sensitivity() for _ in range(ensemble_size)]

    plt.hist(ss)
    plt.axvline(net.average_sensitivity(), color='r')
    plt.savefig(os.path.join(out_dir, net.metadata['name'] + '.png'))
    plt.clf()


if __name__ == '__main__':
    # Number of random networks in the ensemble
    ensemble_size = 10000
    # The directory in which to place the plots
    plots_dir = 'plots'

    # Create the output directory if it doesn't exist
    if not os.path.exists(plots_dir):
        os.mkdir(plots_dir)

    # Get all of the named networks in the `neet.boolean.examples` module with
    # size less than 11.
    networks = map(lambda entry: getattr(ex, entry), dir(ex))
    networks = filter(lambda entry: isinstance(entry, Network), networks)
    networks = filter(lambda net: net.size < 11, networks)
    networks = filter(lambda net: 'name' in net.metadata, networks)

    # For each network, construct an ensemble and plot the distribution of
    # sensitivity.
    for net in networks:
        print(net.metadata['name'], net.size)
        start = time()
        main(net, ensemble_size, plots_dir)
        stop = time()
        print('\t{}s'.format(stop - start))
