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
var count = 0
var timer = timer_start(500, (_) => {
   count += 1
   echom 'Handler called ' .. count
     }, {repeat: 3})
var Lambda = (arg) => ({key: 42})
var mylist = [
  'one',
  'two',
  ]
var mydict = {
  one: 1,
  two: 2,
  }
var result = Func(
    arg1,
    arg2
    )
var text = lead
     .. middle
     .. end
var total = start +
      end -
      correction
var result = positive
    ? PosFunc(arg)
    : NegFunc(arg)
var result = GetBuilder()
    ->BuilderSetWidth(333)
    ->BuilderSetHeight(777)
    ->BuilderBuild()
var result = MyDict
    .member

autocmd BufNewFile *.match if condition
  |   echo 'match'
  | endif
def MyFunc(
  text: string,
  separator = '-'
  ): string
  echo 'thing'
enddef
[var1, var2] =
  Func()
echo [1,
  2] [3,
    4]
Func(arg)	   # OK
Func(
      arg)	   # OK
Func(
      arg	   # OK
      )
var dict = {key: value}
var dict = {'key with space': value}
var dict = {"key\twith\ttabs": value}
var dict = {'': value}			# empty key
1 || false   == true
0 || 1       == true
0 || false   == false
1 && true    == true
0 && 1       == false
!'yes'			== false
!![]			== false
!![1, 2, 3]		== true
'hello ' .. 123  == 'hello 123'
'hello ' .. v:true  == 'hello true'
true
false
null
null_blob
null_channel
null_class
null_dict
null_function
null_job
null_list
null_object
null_partial
null_string

