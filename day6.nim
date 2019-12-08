from sequtils import map
from strutils import split, strip
from sugar import `=>`
import tables
import sets

proc readAllLines(filename: string): seq[string] =
  result = newSeq[string]()
  for line in filename.lines:
    result.add(line)

proc linesToPairs(ls: openArray[string]): seq[(string, string)] =
  ls.map(l => l.split(')')).map(s => (s[0], s[1]))

## Implement a directed graph as an adjacency list.
type Graph = Table[string, HashSet[string]]

proc vertices(g: Graph): HashSet[string] =
  for k in g.keys:
    result.incl(k)

proc neighbors(g: Graph, node: string): HashSet[string] =
  g[node]

## Find the distance between vertices with labels u and v.
proc distance(g: Graph, u: string, v: string): int =
  1

proc minDistance(vertices: HashSet[string], distances: Table[string, int]): string =
  var
    vCopy = vertices
    minIndex = vCopy.pop
    minDistance = distances[minIndex]
  for i in vertices:
    let distance = distances[i]
    if distance < minDistance:
      minDistance = distance
      minIndex = i
  minIndex

proc dijkstra(g: Graph, source: string): (Table[string, int], Table[string, string]) =
  var
    q: HashSet[string]
    dist: Table[string, int]
    prev: Table[string, string]
    u: string
    alt: int
  for v in g.vertices():
    # TODO this should be infinity
    dist[v] = 999999
    prev[v] = ""
    q.incl(v)
  dist[source] = 0
  while q.len > 0:
    u = minDistance(q, dist)
    q.excl(u)
    for v in g.neighbors(u):
      alt = dist[u] + g.distance(u, v)
      if alt < dist[v]:
        dist[v] = alt
        prev[v] = u
  (dist, prev)

template loadGraph(start: int, finish: int): untyped =
  if not result.contains(p[start]):
    result[p[start]] = initHashSet[string]()
  result[p[start]].incl(p[finish])

proc fromPairs(ps: openArray[(string, string)], directed: bool = true): Graph =
  for p in ps:
    loadGraph(0, 1)
    if not directed:
      loadGraph(1, 0)

proc countOrbits(g: Graph, startNode: string, depth: int = 1): int =
  let children = g.getOrDefault(startNode)
  for child in children:
    result += depth + countOrbits(g, child, depth + 1)

proc numOrbitalTransfers(g: Graph): int =
  dijkstra(g, "YOU")[0]["SAN"] - 2

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

  let ps = readAllLines("day6_input.txt").linesToPairs()

  echo "part 1: ", ps.fromPairs().countOrbits("COM")

  let part2example = """
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
K)YOU
I)SAN
""".strip().split().linesToPairs().fromPairs(false)
  doAssert numOrbitalTransfers(part2example) == 4
  echo "part 2: ", ps.fromPairs(false).numOrbitalTransfers()
