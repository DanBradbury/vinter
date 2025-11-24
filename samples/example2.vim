vim9script

# Example with lists and dictionaries

var names: list<string> = ['Alice', 'Bob', 'Charlie']
var scores: dict<number> = {Alice: 95, Bob: 87, Charlie: 92}

def GetTopScore(): number
  var maxScore: number = 0
  for score in values(scores)
    if score > maxScore
      maxScore = score
    endif
  endfor
  return maxScore
enddef

def FilterNames(minLength: number): list<string>
  var filtered: list<string> = []
  for name in names
    if len(name) >= minLength
      filtered->add(name)
    endif
  endfor
  return filtered
enddef
