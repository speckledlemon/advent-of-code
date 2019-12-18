from algorithm import sorted
from sugar import `=>`
import math
import sequtils
import strutils
import sets
import ./aoc_utils
import unittest

type
  Point = tuple[x: int, y: int]
  Line = tuple[start: Point, finish: Point]

const
  origin = (x: 0, y: 0)
  singletonForNoIntersection = (x: high(int), y: high(int))

proc makeLinesFromString(directions: string): seq[Line] =
  let splitDirections = filter(directions.split(','), proc (direction: string): bool = direction != "")
  # always start from the Cartesian origin
  var
    currentX = 0
    currentY = 0
    start = (x: currentX, y: currentY)
  for strDirection in splitDirections:
    start = (x: currentX, y: currentY)
    let
      direction = strDirection[0]
      numSteps = parseInt(strDirection[1..high(strDirection)])
    case direction:
      of 'R':
        currentX += numSteps
      of 'L':
        currentX -= numSteps
      of 'U':
        currentY += numSteps
      of 'D':
        currentY -= numSteps
      else:
        # TODO can't be bothered to figure this out yet ¯\_(ツ)_/¯
        raise
    result.add((start: start, finish: (x: currentX, y: currentY)))

# don't bother with a special type for the return value since it's going to be
# unpacked immediately
proc lineToCoefficients(line: Line): (int, int, int) =
  let
    a = line.finish.y - line.start.y
    b = line.start.x - line.finish.x
    c = (a * line.start.x) + (b * line.start.y)
  (a, b, c)

## Return the point of intersection for two infinitely extending lines, each
## represented by a line segment. If the lines don't intersect, returns a
## false point with coordinates of the largest representable integer type.
proc getIntersectionOfLines(line1: Line, line2: Line): Point =
  let
    (a1, b1, c1) = lineToCoefficients(line1)
    (a2, b2, c2) = lineToCoefficients(line2)
    determinant = (a1 * b2) - (a2 * b1)
  result = if determinant == 0:
             # lines are parallel
             singletonForNoIntersection
           else:
             let
               intersectionX = ((b2 * c1) - (b1 * c2)) / determinant
               intersectionY = ((a1 * c2) - (a2 * c1)) / determinant
             # echo intersectionX, " ", intersectionY
             # The implementation is general until here: we can safely assume
             # that all lines are either vertical or horizontal.
             (x: int(intersectionX), y: int(intersectionY))

proc getIntersectionOfSegments(seg1: Line, seg2: Line): Point =
  let infiniteLineIntersection = getIntersectionOfLines(seg1, seg2)
  if infiniteLineIntersection == singletonForNoIntersection:
    result = singletonForNoIntersection
  else:
    let
      xIsValid1 = (min(seg1.start.x, seg1.finish.x) <= infiniteLineIntersection.x) and (infiniteLineIntersection.x <= max(seg1.start.x, seg1.finish.x))
      xIsValid2 = (min(seg2.start.x, seg2.finish.x) <= infiniteLineIntersection.x) and (infiniteLineIntersection.x <= max(seg2.start.x, seg2.finish.x))
      yIsValid1 = (min(seg1.start.y, seg1.finish.y) <= infiniteLineIntersection.y) and (infiniteLineIntersection.y <= max(seg1.start.y, seg1.finish.y))
      yIsValid2 = (min(seg2.start.y, seg2.finish.y) <= infiniteLineIntersection.y) and (infiniteLineIntersection.y <= max(seg2.start.y, seg2.finish.y))
    if not xIsValid1 or not xIsValid2 or not yIsValid1 or not yIsValid2:
      result = singletonForNoIntersection
    else:
      result = infiniteLineIntersection

proc findIntersections(wire1: seq[Line], wire2: seq[Line]): HashSet[Point] =
  var intersection: Point
  for segment1 in wire1:
    for segment2 in wire2:
      intersection = getIntersectionOfSegments(segment1, segment2)
      if intersection != singletonForNoIntersection:
        result.incl(intersection)
  # the origin doesn't count as an intersection
  result.excl(origin)

## The Manhattan (L1) distance between a point and the Cartesian origin is the
## sum of the absolute value of each individual coordinate.
proc manhattanDistance(p: Point): int =
  abs(p.x) + abs(p.y)

proc getClosestIntersection(strDirections1: string, strDirections2: string): int =
  sorted(
    toSeq(
      findIntersections(
        makeLinesFromString(strDirections1),
        makeLinesFromString(strDirections2)
      ).map(p => manhattanDistance(p))
    )
  )[0]

proc len(line: Line): int =
  let
    xc = (line.finish.x - line.start.x) ^ 2
    yc = (line.finish.y - line.start.y) ^ 2
  # again, only vertical or horizontal lines are present
  int(sqrt(float(xc + yc)))

proc pathLength(wire: seq[Line], stoppingIndexInclusive: int): int =
  if stoppingIndexInclusive > 0:
    for i in 0..stoppingIndexInclusive:
      result += len(wire[i])

proc findIntersectionsWithPath(wire1: seq[Line], wire2: seq[Line]): HashSet[(int, Point)] =
  var
    intersection: Point
    pl1: int
    pl2: int
    remainder1: int
    remainder2: int
  for i1, segment1 in wire1:
    for i2, segment2 in wire2:
      intersection = getIntersectionOfSegments(segment1, segment2)
      if intersection != singletonForNoIntersection:
        # It is more complicated than just the sum of the path lengths. It is
        # the sum of the path lengths up until the segments that intersect,
        # then for the two segments that intersect, is the length of each
        # segment from their start points to the intersection point.
        pl1 = pathLength(wire1, i1 - 1)
        pl2 = pathLength(wire2, i2 - 1)
        remainder1 = len((start: wire1[i1].start, finish: intersection))
        remainder2 = len((start: wire2[i2].start, finish: intersection))
        result.incl((pl1 + pl2 + remainder1 + remainder2, intersection))
  # the origin doesn't count as an intersection
  result.excl((0, origin))

proc getFewestCombinedSteps(strDirections1: string, strDirections2: string): int =
  sorted(
    toSeq(
      findIntersectionsWithPath(
        makeLinesFromString(strDirections1),
        makeLinesFromString(strDirections2)
      )
    )
  )[0][0]

suite "day3":
  test "makeLinesFromString":
    check: makeLinesFromString("R8,U5,L5,D3,") == @[(start: (x: 0, y: 0), finish: (x: 8, y: 0)),
                                                   (start: (x: 8, y: 0), finish: (x: 8, y: 5)),
                                                   (start: (x: 8, y: 5), finish: (x: 3, y: 5)),
                                                   (start: (x: 3, y: 5), finish: (x: 3, y: 2))]
    check: makeLinesFromString("U7,R6,D4,L4") == @[(start: (x: 0, y: 0), finish: (x: 0, y: 7)),
                                                  (start: (x: 0, y: 7), finish: (x: 6, y: 7)),
                                                  (start: (x: 6, y: 7), finish: (x: 6, y: 3)),
                                                  (start: (x: 6, y: 3), finish: (x: 2, y: 3))]
  test "findInterections":
    let
      lines1 = makeLinesFromString("R8,U5,L5,D3,")
      lines2 = makeLinesFromString("U7,R6,D4,L4")
    check(findIntersections(lines1, lines2) == toHashSet(@[(x: 6, y: 5), (x: 3, y: 3)]))

  test "getClosestIntersection":
    check: getClosestIntersection("R8,U5,L5,D3,", "U7,R6,D4,L4") == 6
    check: getClosestIntersection("R75,D30,R83,U83,L12,D49,R71,U7,L72",
                                  "U62,R66,U55,R34,D71,R55,D58,R83") == 159
    check: getClosestIntersection("R98,U47,R26,D63,R33,U87,L62,D20,R33,U53,R51",
                                  "U98,R91,D20,R16,D67,R40,U7,R15,U6,R7") == 135

  test "getFewestCombinedSteps":
    check: getFewestCombinedSteps("R8,U5,L5,D3,", "U7,R6,D4,L4") == 30
    check: getFewestCombinedSteps("R75,D30,R83,U83,L12,D49,R71,U7,L72",
                                  "U62,R66,U55,R34,D71,R55,D58,R83") == 610
    check: getFewestCombinedSteps("R98,U47,R26,D63,R33,U87,L62,D20,R33,U53,R51",
                                  "U98,R91,D20,R16,D67,R40,U7,R15,U6,R7") == 410


when isMainModule:
  let inputs = readAllLines("day3_input.txt")
  echo "part 1: ", getClosestIntersection(inputs[0], inputs[1])
  echo "part 2: ", getFewestCombinedSteps(inputs[0], inputs[1])
