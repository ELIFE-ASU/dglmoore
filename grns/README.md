# Functional Ensembles

The GRN survey has focused on random ensembles which conserve structural
information of an experimentally-derived Boolean network. An alternative
approach is to randomize to ensure that the resulting state-transition graph is
isomorphic to that of the original network. The idea is to construct the
state-transition graph of the original network, and permute the labels on the
vertices of the graph. From the transition graph, we can then construct a
`LogicNetwork` which implements it.

## How many functional identical networks are there?

This is actually a little tricky to answer, but we can bound it above. A
Boolean GRN with $n$ nodes has $2^n$ states. Then there are $2^n!$ permutations
on the nodes of the transition graph. Of course, some of these lead to
essentially identical GRNs by simply permuting the names of the $n$ nodes of
the GRN. That accounts for at most $n!$ of the resulting networks. Ultimately,
there are **a lot** of networks in this class.

## Results

To get a rough idea of what this would look like, we decided to carry out this
program on the 4 networks in `neet.boolean.examples` which have 10 or fewer
nodes. The
[`ensemble.py`](https://github.com/elife-asu/dglmoore/blob/master/grns/ensemble/ensemble.py`)
script constructs an ensemble of 10,000 random networks, computes the
sensitivity of each, and plots the distribution in the [`plots`](plots)
directory. After installing [Neet](https://github.com/elife-asu/neet), it can be executed
```shell
$ python ensemble.py
```

It takes around 6 hours to run at the moment, but I'm confident a more
efficient randomization algorithm will improve this performance.

### C. elegans
![C. elegans](https://github.com/elife-asu/dglmoore/raw/master/grns/plots/c_elegans.png "C. elegans Sensitivity")

### Mouse Cortical Network, Fig. 7B

![Mouse Cortical Network, Fig. 7B](https://github.com/elife-asu/dglmoore/raw/master/grns/plots/mouse_cortical_fig_7B.png "Mouse Cortical, Fig. 7B Sensitivity")

### Mouse Cortical Network, Fig. 7C
![Mouse Cortical Network, Fig. 7C](https://github.com/elife-asu/dglmoore/raw/master/grns/plots/mouse_cortical_fig_7C.png "Mouse Cortical, Fig. 7C Sensitivity")

### S. pombe
![S. pombe](https://github.com/elife-asu/dglmoore/raw/master/grns/plots/s_pombe.png "S. pombe Sensitivity")

## Conclusions

It is striking how different the sensitivity of the experimentally-derived
network is from the random ensemble. It is also worth pointing out that the
distribution peaks right around $n/2$, where $n$ is the number of nodes in the
network.
