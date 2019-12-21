## A lot of this was stolen directly from
## https://github.com/Dementophobia/advent-of-code-2019.git.

from algorithm import sorted
import math
import re
import sequtils
import sets
import strutils
import sugar
import ./aoc_utils
import unittest
# `nimble install itertools`
import itertools
# `nimble install timeit`
import timeit

type
  CelestialBody = array[6, int]

proc parseLine(line: string): CelestialBody =
  var
    x: int
    y: int
    z: int
  if line =~ re"<x=(-?\d+), y=(-?\d+), z=(-?\d+)>":
    x = matches[0].parseInt()
    y = matches[1].parseInt()
    z = matches[2].parseInt()
  [x, y, z, 0, 0, 0]

proc applyGravity(bodies: var seq[CelestialBody]) =
  # ABCD -> AB, AC, AD, BC, BD, CD
  for p in combinations(toSeq(low(bodies)..high(bodies)), 2):
    for dim in 0..2:
      if bodies[p[0]][dim] > bodies[p[1]][dim]:
        bodies[p[0]][dim + 3] -= 1
        bodies[p[1]][dim + 3] += 1
      elif bodies[p[0]][dim] < bodies[p[1]][dim]:
        bodies[p[0]][dim + 3] += 1
        bodies[p[1]][dim + 3] -= 1

proc applyVelocity(bodies: var seq[CelestialBody]) =
  for b in bodies.mitems:
    b[0] += b[3]
    b[1] += b[4]
    b[2] += b[5]

proc step(bodies: var seq[CelestialBody]) =
  bodies.applyGravity()
  bodies.applyVelocity()
proc step(bodies: var seq[CelestialBody], numSteps: Positive) =
  for i in 1..numSteps:
    bodies.step()

proc calculateEnergy(bodies: seq[CelestialBody]): int {.discardable.} =
  for b in bodies:
    result += (b[0].abs + b[1].abs + b[2].abs) * (b[3].abs + b[4].abs + b[5].abs)

proc applyGravity(moonsDim, velocitiesDim: var seq[int]) =
  assert moonsDim.len == velocitiesDim.len
  # ABCD -> AB, AC, AD, BC, BD, CD
  for p in combinations(toSeq(low(moonsDim)..high(moonsDim)), 2):
    if moonsDim[p[0]] > moonsDim[p[1]]:
      velocitiesDim[p[0]] -= 1
      velocitiesDim[p[1]] += 1
    elif moonsDim[p[0]] < moonsDim[p[1]]:
      velocitiesDim[p[0]] += 1
      velocitiesDim[p[1]] -= 1

proc applyVelocity(moonsDim, velocitiesDim: var seq[int]) =
  assert moonsDim.len == velocitiesDim.len
  for i in low(moonsDim)..high(moonsDim):
    moonsDim[i] += velocitiesDim[i]

proc matchesStartState(bodies: var seq[CelestialBody], moonsDim, velocitiesDim: var seq[int], dim: int): bool =
  assert bodies.len == moonsDim.len
  assert bodies.len == velocitiesDim.len
  result = true
  for i in low(bodies)..high(bodies):
    if bodies[i][dim] != moonsDim[i] or bodies[i][dim + 3] != velocitiesDim[i]:
      return false

## Get all prime factors of the given value in ascending order.
proc getPrimeFactors(value: int): seq[int] =
  var
    n = value
    i = 2
  while i * 1 <= n:
    if n mod i != 0:
      i += 1
    else:
      n = n div i
      result.add(i)
  if n > 1:
    result.add(n)
  result.sorted()

proc calculateLCM[T: SomeInteger](values: openArray[T]): T =
  let primesPerValue = values.map(v => v.getPrimeFactors())
  var allPrimes: HashSet[T]
  for ps in primesPerValue:
    allPrimes = allPrimes + ps.toHashSet()
  result = 1
  var amount: T
  for prime in allPrimes:
    amount = primesPerValue.map(ps => ps.count(prime)).max
    result *= (prime ^ amount)

proc timeToSeenState(bodies: seq[CelestialBody]): int {.discardable.} =
  var
    # just so we can pass by reference afterward
    moonsAndVelocities = deepCopy(bodies)
    steps: array[3, int]
  for dim in 0..2:
    var
      moonsDim: seq[int]
      velocitiesDim: seq[int]
    for i in low(moonsAndVelocities)..high(moonsAndVelocities):
      moonsDim.add(moonsAndVelocities[i][dim])
      velocitiesDim.add(moonsAndVelocities[i][dim + 3])
    while true:
      applyGravity(moonsDim, velocitiesDim)
      applyVelocity(moonsDim, velocitiesDim)
      steps[dim] += 1
      if matchesStartState(moonsAndVelocities, moonsDim, velocitiesDim, dim):
        break
  calculateLCM(steps)

suite "day12":
  test "parseLine":
    let
      exlines = """
<x=-1, y=0, z=2>
<x=2, y=-10, z=-7>
<x=4, y=-8, z=8>
<x=3, y=5, z=-1>
""".strip().split("\n")
      res = @[
        [-1, 0, 2, 0, 0, 0],
        [2, -10, -7, 0, 0, 0],
        [4, -8, 8, 0, 0, 0],
        [3, 5, -1, 0, 0, 0]
      ]
    check: exlines.map(l => l.parseLine()) == res
  test "applyGravity":
    var start = @[
        [-1, 0, 2, 0, 0, 0],
        [2, -10, -7, 0, 0, 0],
        [4, -8, 8, 0, 0, 0],
        [3, 5, -1, 0, 0, 0]
      ]
    start.applyGravity()
    check: start == @[
        [-1, 0, 2, 3, -1, -1],
        [2, -10, -7, 1, 3, 3],
        [4, -8, 8, -3, 1, -3],
        [3, 5, -1, -1, -3, 1]
    ]
  test "applyVelocity":
    var start = @[
        [-1, 0, 2, 3, -1, -1],
        [2, -10, -7, 1, 3, 3],
        [4, -8, 8, -3, 1, -3],
        [3, 5, -1, -1, -3, 1]
    ]
    start.applyVelocity()
    check: start == @[
        [2, -1, 1, 3, -1, -1],
        [3, -7, -4, 1, 3, 3],
        [1, -7, 5, -3, 1, -3],
        [2, 2, 0, -1, -3, 1]
    ]
  test "step":
    var
      start = @[
        [-1, 0, 2, 0, 0, 0],
        [2, -10, -7, 0, 0, 0],
        [4, -8, 8, 0, 0, 0],
        [3, 5, -1, 0, 0, 0]
      ]
    let
      after10 = @[
        [2, 1, -3, -3, -2, 1],
        [1, -8, 0, -1, 1, 3],
        [3, -6, 1, 3, 2, -3],
        [2, 0, 4, 1, -1, -1]
      ]
    start.step(10)
    check: start == after10
pp  test "calculateEnergy":
    let after10 = @[
        [2, 1, -3, -3, -2, 1],
        [1, -8, 0, -1, 1, 3],
        [3, -6, 1, 3, 2, -3],
        [2, 0, 4, 1, -1, -1]
      ]
    check: after10.calculateEnergy() == 179

  test "getPrimeFactors":
    check: getPrimeFactors(286332) == @[2, 2, 3, 107, 223]
    check: getPrimeFactors(231614) == @[2, 115807]
    check: getPrimeFactors(60424) == @[2, 2, 2, 7, 13, 83]

  test "calculateLCM":
    check: calculateLCM(@[286332, 231614, 60424]) == 500903629351944

  test "timeToSeenState":
    let
      ex1 = """
<x=-1, y=0, z=2>
<x=2, y=-10, z=-7>
<x=4, y=-8, z=8>
<x=3, y=5, z=-1>
""".strip().split("\n").map(l => l.parseLine())
      ex2 = """
<x=-8, y=-10, z=0>
<x=5, y=5, z=10>
<x=2, y=-7, z=3>
<x=9, y=-8, z=-3>
""".strip().split("\n").map(l => l.parseLine())
    check: ex1.timeToSeenState() == 2772
    check: ex2.timeToSeenState() == 4686774924

when isMainModule:
  var bodies = readAllLines("day12_input.txt").map(l => l.parseLine())
  bodies.step(1000)
  echo "part 1: ", bodies.calculateEnergy()
  echo "part 2: ", bodies.timeToSeenState()

  # echo timeGo(bodies.calculateEnergy())
  echo timeGo(bodies.timeToSeenState())
