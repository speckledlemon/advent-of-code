proc readAllLines*(filename: string): seq[string] =
  result = newSeq[string]()
  for line in filename.lines:
    result.add(line)
