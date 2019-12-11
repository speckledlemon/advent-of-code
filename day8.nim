from algorithm import sort
from sequtils import map, count, toSeq
from strutils import parseInt, join, replace
from sugar import `=>`

# `nimble install itertools`
from itertools import chunked

type
  Layers = seq[seq[int]]
  Pixel = enum
    black = 0
    white = 1
    transparent = 2

proc makeLayers(inp: string, width, height: int): Layers =
  toSeq(chunked(inp.map(d => parseInt($d)), width * height))

proc part1(layers: Layers, digitToMin, digitLeft, digitRight: int): int =
  var digitToMinCountToLayerId: seq[(int, int)]
  for i, layer in layers:
    digitToMinCountToLayerId.add((count(layer, digitToMin), i))
  digitToMinCountToLayerId.sort()
  let
    layerIdxWithMinDigitCount = digitToMinCountToLayerId[0][1]
    layerWithMinDigitCount = layers[layerIdxWithMinDigitCount]
    countDigitLeft = count(layerWithMinDigitCount, digitLeft)
    countDigitRight = count(layerWithMinDigitCount, digitRight)
  result = countDigitLeft * countDigitRight

proc part2(layers: Layers, width: int) =
  var
    pixelAtLayer: int
    visibleLayer: seq[int]
  for pixelIdx in 0..layers[0].len - 1:    
    # strategy: find the first instance of a pixel that isn't transparent and
    # that's the color that shows
    for layerIdx in 0..layers.len - 1:
      pixelAtLayer = layers[layerIdx][pixelIdx]
      if Pixel(pixelAtLayer) != Pixel.transparent:
        visibleLayer.add(pixelAtLayer)
        break
  for row in chunked(visibleLayer, width):
    echo row.join().replace('1', '#').replace('0', ' ')

when isMainModule:
  let
    width = 25
    height = 6
    digitToMin = 0
    digitLeft = 1
    digitRight = 2
    f = open("day8_input.txt")
    day8input = readLine(f)
    layers = makeLayers(day8input, width, height)
  close(f)
  echo "part 1: ", part1(layers, digitToMin, digitLeft, digitRight)
  part2(layers, width)
