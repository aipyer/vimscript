" Language:     Verilog HDL
" Maintainer:	Chih-Tsun Huang <cthuang@cs.nthu.edu.tw>
" Last Change:	2017 Aug 25 by Chih-Tsun Huang
" URL:		    http://www.cs.nthu.edu.tw/~cthuang/vim/indent/verilog.vim
"
" Credits:
"   Suggestions for improvement, bug reports by
"     Takuya Fujiwara <tyru.exe@gmail.com>
"     Thilo Six <debian@Xk2c.de>
"     Leo Butlero <lbutler@brocade.com>
"
" Buffer Variables:
"     b:verilog_indent_modules : indenting after the declaration
"				 of module blocks
"     b:verilog_indent_width   : indenting width
"     b:verilog_indent_verbose : verbose to each indenting
"

" Only load this indent file when no other was loaded.
if exists("b:did_indent")
  finish
endif
let b:did_indent = 1

setlocal indentexpr=GetVerilogIndent()
setlocal indentkeys=0=always,0=module,0=endmodule,0=function,0=endfunction,0=task,0=endtask
setlocal indentkeys+==if,=else
setlocal indentkeys+=!^B,o,O,0)

" Only define the function once.
if exists("*GetVerilogIndent")
  finish
endif

let s:cpo_save = &cpo
set cpo&vim

function GetVerilogIndent()

    if exists('b:verilog_indent_width')
        let offset = b:verilog_indent_width
    else
        let offset = shiftwidth()
    endif
    if exists('b:verilog_indent_modules')
        let indent_modules = offset
    else
        let indent_module = 0
    endif

    " Find a non-black line above the current line.
    "let lnum = prevnonblank(v:lnum - 1)

    " At the start of the file use zero indent.
    "if lnum == 0
    "    return 0
    "endif

    let curr_line = getline(v:lnum)
    let last_line = getline(v:lnum - 1)
    let ind = indent(v:lnum - 1)

    if curr_line =~ '\m^\s*\<\(module\|endmodule\)\>' ||
     \ curr_line =~ '\m^\s*\<\(function\|endfunction\)\>' ||
     \ curr_line =~ '\m^\s*\<\(task\|endtask\)\>'
        return 0
    endif
    " TODO: Find a corresponding 'if' 
    if curr_line =~ '\m^\s*\<else\>'
        
    endif
    if last_line =~ '\m^\s*\n'
        return 0
    endif
    if last_line =~ '\m^\s*\<\(always\|module\|function\|task\)\>'
        return ind + offset
    endif
    if last_line =~ '\m\<if\>\s\?[^;]*;\s\?\<else\>'
        return ind
    endif
    if last_line =~ '\m\<\(if\|else\)\>'
        return ind + offset
    endif

    return ind

endfunction

let &cpo = s:cpo_save
unlet s:cpo_save

" vim:sw=2
