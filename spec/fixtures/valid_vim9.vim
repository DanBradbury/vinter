vim9script
# A valid Vim9 script file for testing
echo "hello"   # comment
echo "hello "
     .. yourName
     .. ", how are you?"

var count = 0
count += 3
const myList = [1, 2]
final myList = [1, 2]
myList[0] = 9		# OK
myList->add(3)		# OK
var Lambda = (arg) => expression
var Lambda = (arg): type => expression
filter(list, (k, v) =>
    v > 0)
var Lambda = (arg) => {
  g:was_called = 'yes'
  return expression
    }
