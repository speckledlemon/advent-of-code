from math import sum
from sequtils import map
from strutils import parseBiggestInt
from sugar import `=>`
import ./aoc_utils

const zero = parseBiggestInt("0")

proc getFuel(mass: SomeSignedInt): SomeSignedInt =
  mass div 3 - 2

proc getAllFuel(mass: SomeSignedInt): SomeSignedInt =
  var additionalFuel = getFuel(mass)
  while additionalFuel >= zero:
    result += additionalFuel
    additionalFuel = getFuel(additionalFuel)

when isMainModule:
  let inputLines = readAllLines("day1_input.txt")

  doAssert getFuel(12) == 2
  doAssert getFuel(14) == 2
  doAssert getFuel(1969) == 654
  doAssert getFuel(100756) == 33583

  echo "part 1: ", sum(inputLines.map(s => getFuel(parseBiggestInt(s))))

  doAssert getAllFuel(14) == 2
  doAssert getAllFuel(1969) == 966
  doAssert getAllFuel(100756) == 50346

  echo "part 2: ", sum(inputLines.map(s => getAllFuel(parseBiggestInt(s))))
