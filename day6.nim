from sequtils import map
from strutils import split, strip
from sugar import `=>`
import tables
import sets

proc readAllLines(filename: string): seq[string] =
  result = newSeq[string]()
  for line in filename.lines:
    result.add(line)

proc linesToPairs(ls: seq[string]): seq[(string, string)] =
  ls.map(l => l.split(')')).map(s => (s[0], s[1]))

## Implement a directed graph as an adjacency list.
type Graph = Table[string, HashSet[string]]

proc fromPairs(ps: openArray[(string, string)]): Graph =
  for p in ps:
    if not result.contains(p[0]):
      result[p[0]] = initHashSet[string]()
    result[p[0]].incl(p[1])

proc countOrbits(g: Graph, startNode: string, depth: int = 1): int =
  let children = g.getOrDefault(startNode)
  # echo children, " ", depth
  for child in children:
    result += depth + countOrbits(g, child, depth + 1)

when isMainModule:
  # A - B - C
  doAssert countOrbits(fromPairs(@[("A", "B"), ("B", "C")]), "A") == 3
  # A - B - C - D
  doAssert countOrbits(fromPairs(@[("A", "B"), ("B", "C"), ("C", "D")]), "A") == 6
  # A - B - C
  #      \
  #       D
  doAssert countOrbits(fromPairs(@[("A", "B"), ("B", "C"), ("B", "D")]), "A") == 5
  let testOrbit = """
COM)B
B)C
C)D
D)E
E)F
B)G
G)H
D)I
E)J
J)K
K)L
""".strip().split().linesToPairs()
  #         G - H       J - K - L
  #        /           /
  # COM - B - C - D - E - F
  #                \
  #                 I
  # direct orbits is total number of edges: 11
  # indirect orbits is sum of (each node's depth - 1)
  # total orbits is depth of each node
  doAssert countOrbits(fromPairs(testOrbit), "COM") == 42

  echo "part 1: ", readAllLines("day6_input.txt").linesToPairs().fromPairs().countOrbits("COM")
