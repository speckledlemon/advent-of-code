from algorithm import reversed
from sequtils import map
from strutils import split, parseInt
from sugar import `=>`

proc stringToProgram(s: string): seq[int] =
  s.split(',').map(i => parseInt(i))

type
  Opcode = enum
    add = 1
    multiply = 2
    input = 3
    output = 4
    jumpIfTrue = 5
    jumpIfFalse = 6
    lessThan = 7
    equals = 8
    adjustRelativeBase = 9
    halt = 99
  Mode = enum
    position = 0
    immediate = 1
    relative = 2
  OutputMode {.pure.} = enum
    ret
    halt

## The length of an Opcode accounts for the number of arguments it takes, plus
## one for the opcode itself.
proc len(oc: Opcode): int =
  case oc:
    of add: 4
    of multiply: 4
    of input: 2
    of output: 2
    of jumpIfTrue: 3
    of jumpIfFalse: 3
    of lessThan: 4
    of equals: 4
    of adjustRelativeBase: 2
    of halt: 1

proc parseInstruction(instruction: string): (seq[Mode], Opcode) =
  assert instruction.len >= 1
  let
    maxNumArguments = 3
    h = high(instruction)
    opcodeStr = if instruction.len == 2: instruction[(h - 1)..h]
                else: $instruction[h]
    opcode = Opcode(parseInt(opcodeStr))
    # The given string can be anywhere between 1-5 digits long.
    modeStr = if instruction.len > 1: instruction[low(instruction)..(h - 2)]
              else: ""
  var splitModes = reversed(modeStr)
  while splitModes.len < maxNumArguments:
    splitModes.add('0')
  result = (splitModes.map(c => Mode(parseInt($c))), opcode)

proc extendProgram[T: SomeInteger](program: seq[T], newLen: int): seq[T] =
  result = program
  while result.len < newLen:
    result.add(0)

proc getPtr[T: SomeInteger](tape: seq[T], offset: T, mode: Mode,
    relativeBase: T = 0): T =
  case mode:
    of Mode.position: tape[offset]
    of Mode.immediate: offset
    of Mode.relative: tape[offset] + relativeBase

proc getArg[T: SomeInteger](tape: seq[T], offset: T, mode: Mode,
    relativeBase: T = 0): T =
  let programPtr = getPtr(tape, offset, mode, relativeBase)
  tape[programPtr]

type
  IntcodeComputer = object
    program: seq[int]
    instructionPointer: int
    relativeBase: int
    output: int
    halted: bool

template extendProgram(mode: Mode): untyped =
  let actualPtr = getPtr(result.program, result.instructionPointer +
      opcode.len - 1, mode, result.relativeBase)
  if actualPtr > high(result.program):
    result.program = extendProgram(result.program, 2 * actualPtr)
template first(): untyped =
  # TODO is the extend necessary here?
  extendProgram(modes[0])
  getArg(result.program, result.instructionPointer + 1, modes[0],
      result.relativeBase)
template second(): untyped =
  # TODO is the extend necessary here?
  extendProgram(modes[1])
  getArg(result.program, result.instructionPointer + 2, modes[1],
      result.relativeBase)
template res(): untyped =
  # TODO why isn't it possible for the variables in the template to be visible
  # here?
  extendProgram(modes[2])
  let actualPtr = getPtr(result.program, result.instructionPointer +
      opcode.len - 1, modes[2], result.relativeBase)
  result.program[actualPtr]

proc processProgram[T: SomeInteger](computer: IntcodeComputer, inputs: seq[T],
                                    outputMode: OutputMode = ret): IntcodeComputer =
  result = computer
  result.halted = false
  var inputCounter: T
  while true:
    result = result.step(inputs, outputMode, inputCounter)
    if result.halted and outputMode == OutputMode.halt:
      break
    if result.output != 0 and outputMode == OutputMode.ret:
      return result

proc step[T: SomeInteger](computer: IntcodeComputer, inputs: seq[T],
                          outputMode: OutputMode, inputCounter: var T): IntcodeComputer =
  result = computer
  var
    modes: seq[Mode]
    opcode: Opcode
  try:
    (modes, opcode) = parseInstruction($result.program[result.instructionPointer])
  except RangeError:
    return result
  except IndexError:
    return result
  case opcode:
    of Opcode.add:
      res() = first() + second()
      result.instructionPointer += opcode.len
    of Opcode.multiply:
      res() = first() * second()
      result.instructionPointer += opcode.len
    of Opcode.input:
      res() = inputs[inputCounter]
      inputCounter += 1
      result.instructionPointer += opcode.len
    of Opcode.output:
      result.output = first()
      result.instructionPointer += opcode.len
      case outputMode:
        of OutputMode.ret:
          if result.output != 0:
            return result
        of OutputMode.halt:
          return result
    of Opcode.jumpIfTrue:
      result.instructionPointer = if first() != 0: second()
                                  else: result.instructionPointer + opcode.len
    of Opcode.jumpIfFalse:
      result.instructionPointer = if first() == 0: second()
                                  else: result.instructionPointer + opcode.len
    of Opcode.lessThan:
      res() = T(first() < second())
      result.instructionPointer += opcode.len
    of Opcode.equals:
      res() = T(first() == second())
      result.instructionPointer += opcode.len
    of Opcode.adjustRelativeBase:
      result.relativeBase += first()
      result.instructionPointer += opcode.len
    of Opcode.halt:
      result.instructionPointer += opcode.len
      case outputMode:
        of OutputMode.ret:
          return result
        of OutputMode.halt:
          result.halted = true

when isMainModule:

  doAssert parseInstruction("103") == (@[Mode.immediate, Mode.position, Mode.position], Opcode.input)
  doAssert parseInstruction("203") == (@[Mode.relative, Mode.position, Mode.position], Opcode.input)
  doAssert parseInstruction("204") == (@[Mode.relative, Mode.position, Mode.position], Opcode.output)
  doAssert parseInstruction("109") == (@[Mode.immediate, Mode.position, Mode.position], Opcode.adjustRelativeBase)

  let
    emptyInput = newSeq[int]()
    tp1 = @[-1]
    tp2 = @[1, 2, 3, 4]
  doAssert extendProgram(tp1, 4) == @[-1, 0, 0, 0]
  doAssert extendProgram(tp2, 2) == @[1, 2, 3, 4]

  let program0 = stringToProgram("109,19,204,-34")
  var
    computer0 = IntcodeComputer(program: program0, relativeBase: 2000)
    inputCounter0 = 0
  computer0 = computer0.step(emptyInput, ret, inputCounter0)
  doAssert computer0.instructionPointer == 2
  doAssert computer0.relativeBase == 2019
  computer0 = computer0.step(emptyInput, ret, inputCounter0)
  doAssert computer0.instructionPointer == 4
  doAssert computer0.relativeBase == 2019
  doAssert getPtr(program0, 3, Mode.relative, 2019) == 1985

  # Program taken from
  # https://www.reddit.com/r/adventofcode/comments/eaboz7/quine_for_preday9_intcode_computer/
  let redditQuineInput = stringToProgram("4,44,8,1,35,41,5,41,36,1,9,1,1,5,13,37,1,3,42,42,8,42,38,43,5,43,39,1,37,40,1,5,31,37,99,87,16,0,2,34,44,0,0,0,4,44,8,1,35,41,5,41,36,1,9,1,1,5,13,37,1,3,42,42,8,42,38,43,5,43,39,1,37,40,1,5,31,37,99,87,16,0,2,34,44,0,0,0")
  var
    redditQuineComputer = IntcodeComputer(program: redditQuineInput)
    redditQuineOutput = newSeq[int]()
  while not redditQuineComputer.halted:
    redditQuineComputer = redditQuineComputer.processProgram(emptyInput, OutputMode.halt)
    if not redditQuineComputer.halted:
      redditQuineOutput.add(redditQuineComputer.output)
  doAssert redditQuineInput == redditQuineOutput

  let program1 = stringToProgram("109,1,204,-1,1001,100,1,100,1008,100,16,101,1006,101,0,99")
  var
    computer1 = IntcodeComputer(program: program1)
    computer1Output = newSeq[int]()
  while not computer1.halted:
    computer1 = computer1.processProgram(emptyInput, OutputMode.halt)
    if not computer1.halted:
       computer1Output.add(computer1.output)
  doAssert program1 == computer1Output

  let
    computer2 = IntcodeComputer(program: stringToProgram("1102,34915192,34915192,7,4,7,99,0"))
    computer3 = IntcodeComputer(program: stringToProgram("104,1125899906842624,99"))
  doAssert computer2.processProgram(emptyInput).output == 34915192 * 34915192
  doAssert computer3.processProgram(emptyInput).output == 1125899906842624

  let
    f = open("day9_input.txt")
    unprocessedProgram = readLine(f).stringToProgram()
  close(f)
  var
    computer = IntcodeComputer(program: unprocessedProgram)
    day9output = newSeq[int]()
  computer = computer.processProgram(@[1], OutputMode.halt)
  day9output.add(computer.output)
  while not computer.halted:
    computer = computer.processProgram(emptyInput, OutputMode.halt)
    day9output.add(computer.output)
  echo day9output
