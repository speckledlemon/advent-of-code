from math import sum
from sequtils import map
from strutils import parseBiggestInt
from sugar import `=>`
import ./aoc_utils
import unittest

const zero = parseBiggestInt("0")

proc getFuel(mass: SomeSignedInt): SomeSignedInt =
  mass div 3 - 2

proc getAllFuel(mass: SomeSignedInt): SomeSignedInt =
  var additionalFuel = getFuel(mass)
  while additionalFuel >= zero:
    result += additionalFuel
    additionalFuel = getFuel(additionalFuel)

suite "day1":
  test "getFuel":
    check(getFuel(12) == 2)
    check(getFuel(14) == 2)
    check(getFuel(1969) == 654)
    check(getFuel(100756) == 33583)
  test "getAllFuel":
    check(getAllFuel(14) == 2)
    check(getAllFuel(1969) == 966)
    check(getAllFuel(100756) == 50346)

when isMainModule:
  let inputLines = readAllLines("day1_input.txt")
  echo "part 1: ", sum(inputLines.map(s => getFuel(parseBiggestInt(s))))
  echo "part 2: ", sum(inputLines.map(s => getAllFuel(parseBiggestInt(s))))
