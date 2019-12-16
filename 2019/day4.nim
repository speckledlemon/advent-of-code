from algorithm import isSorted
from strutils import intToStr
import tables
import timeit

proc getCandidates(lo: int, hi: int): int {.discardable.} =
  var
    s: string
    isCandidateNotDecreasing: bool
    doesCandidateHaveDouble: bool
  for i in lo..hi:
    isCandidateNotDecreasing = true
    doesCandidateHaveDouble = false
    s = intToStr(i)
    for j in low(s) + 1..high(s):
      # check that no number is decreasing
      if s[j - 1] > s[j]:
        isCandidateNotDecreasing = false
        break
      # check that there is a double
      if s[j - 1] == s[j]:
        doesCandidateHaveDouble = true
    if isCandidateNotDecreasing and doesCandidateHaveDouble:
      result += 1

proc getStricterCandidates(lo: int, hi: int): int {.discardable.} =
  var
    s: string
    isCandidateNotDecreasing: bool
    doesCandidateHaveDouble: bool
    groupCounts: CountTable[char]
  for i in lo..hi:
    s = intToStr(i)
    isCandidateNotDecreasing = isSorted(s)
    groupCounts = toCountTable(s)
    doesCandidateHaveDouble = false
    for v in groupCounts.values:
      if v == 2:
        doesCandidateHaveDouble = true
    if isCandidateNotDecreasing and doesCandidateHaveDouble:
      result += 1

when isMainModule:
  let
    lo = 246515
    hi = 739105
  echo "part 1: ", getCandidates(lo, hi)
  echo "part 2: ", getStricterCandidates(lo, hi)
  echo timeGo(getCandidates(lo, hi))
  echo timeGo(getStricterCandidates(lo, hi))
