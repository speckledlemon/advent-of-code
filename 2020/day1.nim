import options
import sequtils
import strutils
import sugar
import ./aoc_utils
import unittest

func sumTo2020[T: SomeNumber](nums: openArray[T]): Option[T] =
  for c1 in nums:
    for c2 in nums:
      if c1 + c2 == 2020:
        return some(c1 * c2)
  none(T)

suite "day1":
  test "sumTo2020":
    let expenseReport = [1721, 979, 366, 299, 675, 1456]
    check: sumTo2020(expenseReport).get() == 514579

when isMainModule:
  let inputLines = readAllLines("day1_input.txt")
  echo "part 1: ", sumTo2020(map(inputLines, s => parseBiggestInt(s))).get()
