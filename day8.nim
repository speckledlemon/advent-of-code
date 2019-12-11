from algorithm import sort
from sequtils import map, count, toSeq
from strutils import parseInt
from sugar import `=>`

# `nimble install itertools`
from itertools import chunked

when isMainModule:
  let
    width = 25
    height = 6
    digitToMin = 0
    digitLeft = 1
    digitRight = 2
    f = open("day8_input.txt")
    day8input = readLine(f).map(d => parseInt($d))
  close(f)
  let
    pixelsPerLayer = width * height
    numLayers = int(day8input.len / pixelsPerLayer)
    layers = toSeq(chunked(day8input, pixelsPerLayer))
  var digitToMinCountToLayerId: seq[(int, int)]
  for i, layer in layers:
    digitToMinCountToLayerId.add((count(layer, digitToMin), i))
  digitToMinCountToLayerId.sort()
  let
    layerIdxWithMinDigitCount = digitToMinCountToLayerId[0][1]
    layerWithMinDigitCount = layers[layerIdxWithMinDigitCount]
    countDigitLeft = count(layerWithMinDigitCount, digitLeft)
    countDigitRight = count(layerWithMinDigitCount, digitRight)
  echo "part 1: ", countDigitLeft * countDigitRight
