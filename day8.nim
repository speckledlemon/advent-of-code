from algorithm import sort
from sequtils import map, count, toSeq
from strutils import parseInt, join, replace
from sugar import `=>`

# `nimble install itertools`
from itertools import chunked

type
  Pixel = enum
    black = 0
    white = 1
    transparent = 2

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

  var
    pixelAtLayer: int
    visibleLayer: seq[int]
  for pixelIdx in 0..pixelsPerLayer - 1:    
    # strategy: find the first instance of a pixel that isn't transparent and
    # that's the color that shows
    for layerIdx in 0..numLayers - 1:
      pixelAtLayer = layers[layerIdx][pixelIdx]
      if Pixel(pixelAtLayer) != Pixel.transparent:
        visibleLayer.add(pixelAtLayer)
        break
  for row in chunked(visibleLayer, width):
    echo row.join().replace('1', '#').replace('0', ' ')
