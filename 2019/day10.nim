from algorithm import sorted
from fenv import epsilon
from strutils import strip, splitLines, join
import sets

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
  for line in splitLines(mapString):
    i = 0
    for c in line:
      if c == '#':
        result.add((x: float(i), y: float(j)))
      i += 1
    j += 1

## https://stackoverflow.com/a/328122
proc isBetween(a, b, c: Point): bool =
  let crossProduct = (c.y - a.y) * (b.x - a.x) - (c.x - a.x) * (b.y - a.y)
  if abs(crossProduct) > epsilon(float):
    return false
  let dotProduct = (c.x - a.x) * (b.x - a.x) + (c.y - a.y) * (b.y - a.y)
  if dotProduct < 0:
    return false
  let squaredlengthba = (b.x - a.x)*(b.x - a.x) + (b.y - a.y) * (b.y - a.y)
  if dotproduct > squaredlengthba:
    return false
  return true

proc isBetween(point: Point, line: Line): bool =
  isBetween(line.start, point, line.finish)

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
  for endpoint in candidates:
    if not rejected.contains(endpoint):
      lineSegment = (start: observerPoint, finish: endpoint)
      for possibleBlocker in candidates:
        if possibleBlocker != endpoint:
          if possibleBlocker.isBetween(lineSegment):
            rejected.incl(endpoint)
  candidates - rejected

proc getBestPoint(allPoints: seq[Point]): (int, Point) =
  var visibleFromPoint: seq[(int, Point)]
  for point in allPoints:
    visibleFromPoint.add((allPoints.getVisiblePointsFromGivenPoint(point).len, point))
  sorted(visibleFromPoint)[high(visibleFromPoint)]

when isMainModule:
  let
    map = """
.#..#
.....
#####
....#
...##
""".strip()
    points = map.mapToPoints()
  doAssert points == @[(x: 1.0, y: 0.0), (x: 4.0, y: 0.0), (x: 0.0, y: 2.0), (
      x: 1.0, y: 2.0), (x: 2.0, y: 2.0), (x: 3.0, y: 2.0), (x: 4.0, y: 2.0), (
      x: 4.0, y: 3.0), (x: 3.0, y: 4.0), (x: 4.0, y: 4.0)]
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

  echo "part 1: ", readAllLines("day10_input.txt").join("\n").mapToPoints().getBestPoint()[0]
