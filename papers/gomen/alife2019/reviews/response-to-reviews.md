---
title: "Inferring a Graph's Topology from Games Played on It" Response to Reviewers
date: 21 May 2019
---

# Reviewer 1 (Ay or Polani?)

The paper describes the use of mutual information between agents paying games in different network topologies to infer the structure of the network. The authors show how the degree of effectiveness of the method varies strongly with the game being played and to some degree with the graph density.

The objective to connect topology and functional connectivity is of great interest in complex systems study, and the authors are able two show a number of cases in which the task can be solved. Still, for each game and network there is always some regions in which the connection between mutual information and connectivity cannot allow to reconstruct the network. **Maybe one of the more important limitations of the paper is that the authors offer little insight about what is happening in those cases.**

## Major Suggestions

As the authors describe its system as a sort of parallel Glauber Dynamics in a maximum entropy distribution (equation 4), maybe the authors could complement their analysis by comparing what happens in games with better known models as the Ising model (which could be simulated using an appropriate matrix G in equation 1), and maybe compare the AUC values for different values of beta in comparison with the behavior of well known information theoretic parameters of the model (entropy, heat capacity, mutual information, or even transfer entropy as in https://doi.org/10.1103/PhysRevLett.111.177203 ). Also, the use of better known topologies (like a lattice topology) could be helpful in connecting the results with other well known phenomena, like critical phase transitions

>   I think all of this is reasonable, but the Ising model is maybe a bit outside the scope of this. I'm sure we could concoct a payoff matrix that reproduces the Ising model, but I doubt it would live inside the T-S parameterization. I think most of these ideas would be great for the full journal article we are preparing. I've added the following:
>
>   >   **Page 5-6 (Conclusion)**:
>   >
>   >   The dynamics of the models we considered here are similar in many respects to the classic Ising model, with $\beta$ acting much like temperature and the payoff matrix \cref{eq:game} behaving similarly to interaction strengths. It's reasonable to expect that analogues of heat capacity, entropy, etc$\ldots$ could be related in some way to the effectiveness of the network inference. Comparing the AUC with some of these thermodynamic analogues is a tantalizing possibility for a future work.
>
>   As for lattice topologies, $50$ nodes doesn't factor well — either $5 \times 10$ or $2 \times 25$. I went ahead and simulated the dynamics on a $5 \times 10$ lattice and included it in the paper.

In the discussion, the authors claim that there is few reason to expect the TE to behave differently than mutual information because the current strategy is not used for updating to the new strategy. I do not think that this must be the case (since the current strategy could affect future strategies indirectly from correlations in the network), and maybe the authors should test transfer entropy in some cases to test this (or be more careful about the claim)

>   I'm going to ease up the **one** sentence in which I mention transfer entropy. I knew when I wrote it people would complain, but I'm almost certain it won't do much for us.
>
>   
>
>   >   **Page 5 (Conclusion):**
>   >
>   >   Transfer entropy is really a special case of CMI; it would condition on the target agent's previous strategies. Both approaches are worth exploring more rigorously.

Finally, the authors may be interested in testing or citing other information theoretic approaches that are more focused to capture causal interactions in the network, like causal information flows https://doi.org/10.1142/S0219525908001465 or interventional versions of information theory in general (ISBN: 9780521895606)

>   I'll add a few sentences about interventional methods to the discussion section as possible future directions.
>
>   >   **Page 5 (Conclusion):**
>   >
>   >   In this work, we were interested in methods that required only observation of the system. However, it is well understood that observation alone, particularly in the case of large systems wherein only a small portion of the state space can be explored, are inadequate for extracting causal relationships between components of a system. Interventional methods, such as \citep{Ay2008-jc}, are much more effective in such cases, provided you have the ability to control aspects of the system. Subsequent work may explore such an approach.

## Minor Suggestions

Other small corrections needed:
- The labels of the axes of the figures (specially Figure 1) are hard to read and should use a larger font.

    >   Bumped up the font sizes and emboldened in Fig. 1.

- Figures 2-4 are hard to read in black and white, the authors should choose a colormap that can be read also when printed in black and white.

    >   Pick a better color scheme. It now prints well and is color-blind friendly.

- Variable T is used twice for different purposes (eq 1 and eq 7), one should be changed to avoid confusion.

  >   How can this possibly confuse people? I hate everyone. I changed the $T$ in eq. 7 to $R$ (for real) and then $N$ in eq. 7 to $F$ (fake). I also explain the notation in the subsequent paragraph.

- When introducing the S-T plot, maybe for clarity the authors could refer to eq 1.

  >   We now refer to eq. 1.

# Reviewer 2 (Lizier)

The authors provide an interesting investigation of "effective network" inference of graph structure from time series of strategies of agents playing games on this structure. They use pairwise lagged mutual information for the inference, and experiment with game parameters across the space of prisoner's dilemma, hawk-dove, stag-hunt and harmony games. They seek to reveal where in the parameter space the inference is successful or otherwise in revealing the structure, showing interesting differences across this space, and large influence of average degree regardless of structure class.

Network inference is certainly a topical issue across many areas, particularly neuroscience as highlighted by the authors, and the paper is made well in scope for ALife by combining this with dynamics of networked game theory. The paper is on the short side, yet it is quite a solid piece with good experimental work presented, and is well written, so should clearly be accepted.

## Minor Suggestions

I have a number of suggestions that could be incorporated in a camera-ready version. I'll list the more interesting / longer points first, but all are fairly straightforward. (I'm also going to apologize that it's me reviewing your papers, *again*, and that I'm referring to some of my own papers below - that's mainly to provide further info, not to insist on additional citations!)

Most importantly, I'd suggest changing the nomenclature of the network inference here from "effective" to "functional", as neuroscientists get very picky about having these terms used correctly. The distinction is subtle: functional networks capture statistical relationships between the source and target, whereas effective networks additionally provide a more holistic model which explains and in some sense could reproduce the dynamics. Functional relationships are often undirected (e.g. correlation or MI) but not always. Earlier pieces I wrote, e.g. the review in sec 7.2 of our "Information flow in complex systems" book, equated functional with undirected, but that's not an accurate reflection of community consensus. Effective network inference is not only about having directionality, but importantly about making a minimal model that can explain and replicate the dynamics. Pairwise measures don't do that. This is why the consensus now is that pairwise transfer entropy should be seen as functional, not effective (despite some earlier work labeling it as such, e.g. our book, and the Vicente and Ito references you have). More holistic effective approaches (holistic as in taking into account the parent nodes as a whole set, like a multivariate transfer entropy as per the Rubinov 2011 or Sun 2015 articles, or a model based approach like DCM) provide a unified model of how the target updates its dynamics based on the set of parent sources. So lagged MI here is functional (even though the lag gives it some direction), not effective because it's looking at the sources individually (like TE) rather than as a set. With pairwise TE you might still be able to slip through calling it effective because that distinction is still argued from some quarters, but that definitely won't fly for MI, even lagged. I hope that makes sense.

>   Changed "effective" to "functional".

Bottom of p. 2 defining graph types -- the parameters for each graph type aren't defined here (e.g. m and p); those definitions should be added for completeness. Also, while I can guess at the cycle and wheel structures, the names alone leave some ambiguity, e.g.: I assume the nodes in the cycle are connected to the two nearest neighbors only? The wheel is a hub and spoke model, plus nearest neighbors? That should all be much more clear than it is.

>   Describe the topologies in more detail.
>
>   >   **Page 2-3 (Results):**
>   >
>   >   We were interested in the relationship between the form of the game $\mathcal{G}$, the topology of the graph $G$, and the rule parameter $\beta$. To explore this, we considered $50$ agents playing on graphs with one of 5 types of topology: a.) Barabási-Albert graphs, b.) Erdős-Rényi graphs, and the c.) cycle, d.) wheel and e.) lattice topologies. The Barabási-Albert model (Barabási and Albert, 1999)  generates random graphs using preferential attachment; as new nodes are iteratively added to the graph they are randomly connected to $m$ existent nodes with a bias toward those with higher degree; we considered only $m\in\{1,5\}$ in this work. The Erdős-Rényi model (Erdős and Rényi, 1959) starts with the full set of nodes and adds an edge between each pair of distinct nodes with probability $p$. We chose $p\in\{0.04,0.18\}$ to ensure that the edge density of the Barabási-Albert and Erdős-Rényi graphs are comparable. The cycle, wheel and $5 \times 10$ non-periodic lattice topologies, on the other hand, are non-random topologies, and are depicted in \ref{fig:topologies}.
>
>   And I added a figure depicting the topologies. (**Page 3**).

p. 4 "This suggests that the differences in the Barabási-Albert and Erdős-Rényi graphs may only be an edge density effect" - this looks to be a good observation. Perhaps that we only have 50 nodes means the degree distribution of BA can't look dissimilar enough to ER to make a difference to the dynamics here? It may even be worth plotting the degree distributions to check; in any case, it may be useful to speculate on whether they could be more different in larger networks.

>   The graphs are pretty topologically distinct. Still I modified that paragraph to reflect the new ER simulations and commented on this.
>
>   >   **Page 4-5 (Discussion):**
>   >
>   >   This brings us to the final factor involved in determining the efficacy of the classification: the edge density of the graph. When we compare, for example, the Barabási-Albert graphs with $m=1$ (fig. 3(a-b)) to the Erdős-Rényi graphs with $p=0.04$ (fig. 4(a-b)), we see almost identical structure in the $\overline{AUC}$ heatmaps. On average the Erdős-Rényi graphs have the same edge density to their Barabási-Albert counterparts, i.e. they have about the same number of edges. The cycle graph (fig. 5(a-b)) has the same edge density to the Barabási-Albert graph (\mbox{$m=1$}), and again we see almost identical heatmaps. By increasing the edge parameters for the Barabási-Albert and Erdős-Rényi graphs, $m$ and $p$ respectively, we can see a similar comparison for yet denser graphs (fig. 3(c-d) and  fig. 4(c-d)). Again, the Barabási-Albert ($m=5$) and Erdős-Rényi ($p=0.18$) graphs have similar edge density. What's more, the same qualitative change is seen for a single type of topology when the edge density changes. For example, comparing fig. 3(a) to 3(c) or fig. 4(a) to 4(c), we see fewer harmony and prisoner's dilemma games admit a faithful inference. The same phenomenon is observed in comparing cycles, lattices and wheels, (fig. 5), which further supports the claim. The graphs have remarkably distinct topologies even with only $50$-nodes. For example, it is difficult to find any similarity between the Barabási-Albert and cycle graphs other than edge density. However, it is entirely plausible that some other topological similarity between the graphs is causing these effects. Increasing the size of the graph should lead to increasingly divergent topological features. That would allow us to test this claim more fully.

p. 5 "Since our agents don’t use their current strategy to determine their next, there are few reasons to expect TE to be more effective." I don't think that's true here. The next strategy of each agent is computed as a stochastic update/change (or lack thereof) to their current strategy, so the current strategy seems to be a large, if not the largest, factor in computing their next strategy. It also influences their neighbor's strategies, which in turn influence it, so has an indirect effect there also. As such, TE may better elucidate the effect of source agents on those dynamic updates, given that it looks at those effects in the context of the past strategy and allows you to directly see how the source influenced that state update (rather than only looking to the relationship of what comes next). I'm not suggesting that you add TE for this paper, the MI investigation here is enough and is giving interesting insights; just that the assessment/conclusion of TE not helping I think is off-target.

>   >   **Page 5 (Conclusion):**
>   >
>   >   Transfer entropy is really a special case of CMI; it would condition on the target agent's previous strategies. Both approaches are worth exploring more rigorously.

p. 5 "Since our graphs have 50 nodes, that computation was infeasible. Alternative methods of computing CMI may make it viable for future work" This feasibility issue with large multivariate calculations is really important, and was one of the drivers for the iterative CMI/TE approaches (greedily building up a parent set) proposed in Rubinov 2011 and Sun 2015, which you already reference, plus others referred to in sec 7.2 of our book above. As such, it would be useful to specifically refer to those approaches as having been proposed to handle that problem.

>   Mention the iterative CMI methods from Rubinov and Sun.
>
>   >   **Page 5 (Conclusion)**:
>   >
>   >   Alternative methods of computing CMI, such as the iterative approaches of (Lizier and Rubinov, 2012; Sun et al., 2015), may make it viable for future work. 

## Minor Suggestions

I presume (2), (3) are only meant to sum over edges this node i is a part of? The maths makes it look like all edges; it would be better if the sum was over nodes j, such that (i,j) \in E.

>   Clarify this notation, apparently it's not as clear as I thought.
>
>   >   **Page 2 (Methods):** 
>   >
>   >   The game is played in rounds starting with each agent's strategy selected uniformly at random. In each round, the agents play with their neighbors $N_i = \{j~|~(i,j) \in E\}$ and accumulate payoff
>   >   $$
>   >       P_i(s_1, \ldots, s_n) = \sum_{j \in N_i} \mathcal{G}_{{s_i}{s_j}}
>   >   $$

p.1 "when agents’ perception of the which game their playing is allowed to change" -> "when agents’ perception of which game they're playing is allowed to change" (note: 2 word changes there)

>   Typo...

p.2 - "We consider predictors with AUC < 0.5 as high-quality, although the classification criterion must be switched to φ_ij ≤ θ " - this is unclear. From later text I gather you mean they could be considered high quality if you invert the decision they provide, but that should be made more clear here.

>   I knew this was a bit unclear. Clarified?
>
>   >   **Page 2 (Methods):**
>   >
>   >   A predictor which is no better than uniformly random will yield a perfect diagonal with $AUC=0.5$. Better predictors will yield curves which deviate from the diagonal with $|AUC - 0.5| \gg 0$. We consider predictors with $AUC \ll 0.5$ to be of high-quality because the ROC curve reflects over the diagonal if we change the classification criterion from $\phi_{i,j} \geq \theta$ to $\phi_{ij} \leq \theta$. In other words, the predictor was good, but we were using the wrong criterion. It is important to note that this analysis does not tell us what the threshold $\theta$ should be, though in principle it can be determined. For now, it is sufficient to know only that such a threshold exists.

References:
- Capitalization is strange on many references, e.g. Bach

    >   I don't see anything wrong with the capitalization.

- Rubinov author names are garbled :)

    >   Fixed! (This is actually Lizier and Rubinov!!!)

# Additional Changes

I decided to using $p=0.04$ and $p=0.18$ for the edge probabilities for Erdős-Rényi graphs to make comparisons between them and the Barabási-Albert graphs more direct. This way they have the same edge densities on average, and the result is that heat maps are almost identical!

