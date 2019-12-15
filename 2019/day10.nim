from algorithm import sorted, sort
from fenv import epsilon
from math import pow, sqrt
from sequtils import filter
from strutils import strip, splitLines, join
import sets

# from itertools import permutations

proc readAllLines(filename: string): seq[string] =
  result = newSeq[string]()
  for line in filename.lines:
    result.add(line)

type
  Point = tuple[x: float, y: float]
  Line = tuple[start: Point, finish: Point]

proc mapToPoints(mapString: string): seq[Point] =
  var
    i = 0
    j = 0
  for line in splitLines(mapString.strip()):
    i = 0
    for c in line:
      if c == '#':
        result.add((x: float(i), y: float(j)))
      i += 1
    j += 1

## Is the point `c` on the infinite line created by the line segment from `a`
## to `b`?
##
## Adapted from https://stackoverflow.com/a/328122
proc isOnInfiniteLine(a, b, c: Point): bool =
  let crossProduct = (c.y - a.y) * (b.x - a.x) - (c.x - a.x) * (b.y - a.y)
  if abs(crossProduct) > epsilon(float):
    return false
  let dotProduct = (c.x - a.x) * (b.x - a.x) + (c.y - a.y) * (b.y - a.y)
  if dotProduct < 0:
    return false
  # let squaredlengthba = (b.x - a.x) * (b.x - a.x) + (b.y - a.y) * (b.y - a.y)
  # if dotproduct > squaredlengthba:
  #   return false
  return true

# TODO rewrite this using `isOnInfiniteLine`
## Is the point `c` within the line segment created by `a` and `b`?
##
## Adapted from https://stackoverflow.com/a/328122
proc isBetween(a, b, c: Point): bool =
  let crossProduct = (c.y - a.y) * (b.x - a.x) - (c.x - a.x) * (b.y - a.y)
  if abs(crossProduct) > epsilon(float):
    return false
  let dotProduct = (c.x - a.x) * (b.x - a.x) + (c.y - a.y) * (b.y - a.y)
  if dotProduct < 0:
    return false
  let squaredlengthba = (b.x - a.x) * (b.x - a.x) + (b.y - a.y) * (b.y - a.y)
  if dotproduct > squaredlengthba:
    return false
  return true

proc isOnInfiniteLine(point: Point, line: Line): bool =
  isOnInfiniteLine(line.start, line.finish, point)

proc isBetween(point: Point, line: Line): bool =
  isBetween(line.start, line.finish, point)

proc distance(p1, p2: Point): float =
  sqrt(pow(p1.x - p2.x, 2.0) + pow(p1.y - p2.y, 2.0))

proc len(line: Line): float =
  line.start.distance(line.finish)

## One assumption is that each point truly is a point: it is infinitely
## narrow, like a Dirac delta function in 2D space. Therefore, for a point P
## to be blocking the line of sight from the observer X to another point Q, P
## has to be within machine precision distance of the line segment XQ.
proc getVisiblePointsFromGivenPoint(allPoints: seq[Point],
    observerPoint: Point): HashSet[Point] =
  var
    candidates = toHashSet(allPoints)
    rejected: HashSet[Point]
    lineSegment: Line
  # All points are candidates for being visible from the observer except for
  # the point that _is_ the observer or those points that are "rejected". For
  # each candidate that isn't rejected, form the line segment between it and
  # the observer.
  #
  # (This might be more efficient but it isn't what I ended up doing.) If any
  # other points lie within this line segment, reject all points but the
  # closest point and remove them from the candidates, adding the closest
  # point to the result. Otherwise, add the point at end of the line segment
  # to the result.
  candidates.excl(observerPoint)
  for finish in candidates:
    if not rejected.contains(finish):
      lineSegment = (start: observerPoint, finish: finish)
      for possibleBlocker in candidates:
        if possibleBlocker != lineSegment.finish:
          if possibleBlocker.isBetween(lineSegment):
            rejected.incl(possibleBlocker)
  candidates - rejected

proc getBestPoint(allPoints: seq[Point]): (int, Point) =
  var visibleFromPoint: seq[(int, Point)]
  for point in allPoints:
    visibleFromPoint.add((allPoints.getVisiblePointsFromGivenPoint(point).len, point))
  sorted(visibleFromPoint)[high(visibleFromPoint)]

type
  Map = object
    asteroids: seq[Point]
    laser: Point
    ## The angle is with respect to the line pointing straight up from the
    ## laser.
    angleInDegrees: range[0..360]
    destroyedAsteroids: seq[Point]

proc getAllPointsOnInfiniteLine(line: Line, points: seq[Point]): seq[(float, Point)] =
  for point in points:
    if point.isOnInfiniteLine(line):
      result.add((line.start.distance(point), point))
  sort(result)

## Fire the laser and advance the laser angle by one degree clockwise.
proc fire(map: Map): Map =
  result = deepCopy(map)
  # Assume the laser is pointing straight up. Start by drawing a line segment
  # between the laser and the top of the map. We do this by creating the line
  # segment that connects the laser to the topmost space straight up; this
  # space doesn't need to contain an asteroid. This point has the same `x`
  # coordinate as the laser but has a `y` value of 0.
  var line = (start: map.laser, finish: (x: map.laser.x, y: 0.0))
  # Now rotate this line clockwise by the required number of degrees. TODO
  let asteroidsInLine = sorted(line.getAllPointsOnInfiniteLine(map.asteroids))
  if asteroidsInLine.len > 0:
    # The laser is only capable of blowing up the closest asteroid.
    result.asteroids = result.asteroids.filter(proc (p: Point): bool = p !=
        asteroidsInLine[0][1])
    result.destroyedAsteroids.add(asteroidsInLine[0][1])
  result.angleInDegrees += 1

when isMainModule:
  let
    map1 = """
.#..#
.....
#####
....#
...##
"""
    points = map1.mapToPoints()
  doAssert points == @[(x: 1.0, y: 0.0), (x: 4.0, y: 0.0), (x: 0.0, y: 2.0), (
      x: 1.0, y: 2.0), (x: 2.0, y: 2.0), (x: 3.0, y: 2.0), (x: 4.0, y: 2.0), (
      x: 4.0, y: 3.0), (x: 3.0, y: 4.0), (x: 4.0, y: 4.0)]
  # let pts = @[(x: 1.0, y: 1.0), (x: 2.0, y: 2.0), (x: 3.0, y: 3.0)]
  # for permutation in permutations(pts):
  #   echo permutation, " ", isBetween(permutation[0], permutation[1], permutation[2])
  doAssert isOnInfiniteLine((x: 1.0, y: 0.0), (x: 3.0, y: 4.0), (x: 2.0, y: 2.0))
  doAssert isOnInfiniteLine((x: 1.0, y: 0.0), (x: 2.0, y: 2.0), (x: 3.0, y: 4.0))
  doAssert isBetween((x: 1.0, y: 0.0), (x: 3.0, y: 4.0), (x: 2.0, y: 2.0))
  doAssert not isBetween((x: 1.0, y: 0.0), (x: 2.0, y: 2.0), (x: 3.0, y: 4.0))
  doAssert points.getVisiblePointsFromGivenPoint(points[0]).len == 7
  doAssert points.getVisiblePointsFromGivenPoint(points[1]).len == 7
  doAssert points.getVisiblePointsFromGivenPoint(points[2]).len == 6
  doAssert points.getVisiblePointsFromGivenPoint(points[3]).len == 7
  doAssert points.getVisiblePointsFromGivenPoint(points[4]).len == 7
  doAssert points.getVisiblePointsFromGivenPoint(points[5]).len == 7
  doAssert points.getVisiblePointsFromGivenPoint(points[6]).len == 5
  doAssert points.getVisiblePointsFromGivenPoint(points[7]).len == 7
  doAssert points.getVisiblePointsFromGivenPoint(points[8]).len == 8
  doAssert points.getVisiblePointsFromGivenPoint(points[9]).len == 7
  doAssert points.getBestPoint() == (8, (x: 3.0, y: 4.0))

  let
    map2 = """......#.#.
#..#.#....
..#######.
.#.#.###..
.#..#.....
..#....#.#
#..#....#.
.##.#..###
##...#..#.
.#....####
"""
    map3 = """
#.#...#.#.
.###....#.
.#....#...
##.#.#.#.#
....#.#.#.
.##..###.#
..#...##..
..##....##
......#...
.####.###.
"""
    map4 = """
.#..#..###
####.###.#
....###.#.
..###.##.#
##.##.#.#.
....###..#
..#.#..#.#
#..#.#.###
.##...##.#
.....#.#..
"""
    map5 = """
.#..##.###...#######
##.############..##.
.#.######.########.#
.###.#######.####.#.
#####.##.#.##.###.##
..#####..#.#########
####################
#.####....###.#.#.##
##.#################
#####.##.###..####..
..######..##.#######
####.##.####...##..#
.#####..#.######.###
##...#.##########...
#.##########.#######
.####.#.###.###.#.##
....##.##.###..#####
.#.#.###########.###
#.#.#.#####.####.###
###.##.####.##.#..##
"""
  doAssert map2.mapToPoints().getBestPoint() == (33, (x: 5.0, y: 8.0))
  doAssert map3.mapToPoints().getBestPoint() == (35, (x: 1.0, y: 2.0))
  doAssert map4.mapToPoints().getBestPoint() == (41, (x: 6.0, y: 3.0))
  doAssert map5.mapToPoints().getBestPoint() == (210, (x: 11.0, y: 13.0))

  # echo "part 1: ", readAllLines("day10_input.txt").join("\n").mapToPoints().getBestPoint()[0]

  let
    map6 = Map(
      asteroids: """
.#....#####...#..
##...##.#####..##
##...#...#.#####.
..#.....#...###..
..#.#.....#....##
""".mapToPoints(),
      laser: (x: 8.0, y: 3.0)
    )
  var
    vaporizedMap6 = map6
  echo vaporizedMap6
  vaporizedMap6 = vaporizedMap6.fire()
  echo vaporizedMap6
  vaporizedMap6 = vaporizedMap6.fire()
  echo vaporizedMap6
  vaporizedMap6 = vaporizedMap6.fire()
  echo vaporizedMap6
  # .#....###24...#..
  # ##...##.13#67..9#
  # ##...#...5.8####.
  # ..#.....X...###..
  # ..#.#.....#....##

  # .#....###.....#..
  # ##...##...#.....#
  # ##...#......1234.
  # ..#.....X...5##..
  # ..#.9.....8....76

  # .8....###.....#..
  # 56...9#...#.....#
  # 34...7...........
  # ..2.....X....##..
  # ..1..............

  # ......234.....6..
  # ......1...5.....7
  # .................
  # ........X....89..
  # .................
