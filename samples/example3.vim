vim9script

# Example with classes and objects (vim9script features)

var buffer_config: dict<any> = {
  tabstop: 4,
  expandtab: true,
  number: true
}

def SetupBuffer(): void
  for [key, value] in items(buffer_config)
    execute $'setlocal {key}={value}'
  endfor
enddef

def CreateBuffer(name: string): number
  execute $'new {name}'
  return bufnr('%')
enddef

def ProcessItems(items: list<string>, callback: func(string): string): list<string>
  var results: list<string> = []
  for item in items
    results->add(callback(item))
  endfor
  return results
enddef
