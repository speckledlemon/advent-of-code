import options
import sequtils
import strutils
import sugar
import ./aoc_utils
import unittest

func sumTo2020Pair[T: SomeNumber](nums: openArray[T]): Option[T] =
  for c1 in nums:
    for c2 in nums:
      if c1 + c2 == 2020:
        return some(c1 * c2)
  none(T)

func sumTo2020Triple[T: SomeNumber](nums: openArray[T]): Option[T] =
  for c1 in nums:
    for c2 in nums:
      for c3 in nums:
        if c1 + c2 + c3 == 2020:
          return some(c1 * c2 * c3)
  none(T)

suite "day1":
  test "sumTo2020":
    let expenseReport = [1721, 979, 366, 299, 675, 1456]
    # 1721 and 299
    check: sumTo2020Pair(expenseReport).get() == 514579
    # 979 and 366 and 675
    check: sumTo2020Triple(expenseReport).get() == 241861950

when isMainModule:
  let
    inputLines = readAllLines("day1_input.txt")
    nums = map(inputLines, s => parseBiggestInt(s))
  echo "part 1: ", sumTo2020Pair(nums).get()
  echo "part 2: ", sumTo2020Triple(nums).get()
