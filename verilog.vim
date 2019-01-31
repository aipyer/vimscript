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
setlocal indentkeys+=0=begin,0=end
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
    let pat_com_pre_key     = '\m^\s*\<\(always\|module\|function\|task\)\>'
    let pat_com_module_pair = '\m^\s*\<\(module\|endmodule\)\>'
    let pat_com_func_pair   = '\m^\s*\<\(function\|endfunction\)\>'
    let pat_com_task_pair   = '\m^\s*\<\(task\|endtask\)\>'
    let pat_com_if_and_else = '\m\<if\>\s*(.*)[^;]*;\s*\<else\>\s\+[^;]*;'
    let pat_com_if_or_else  = '\m\<\(if\|else\)\>'
    let pat_com_pre_else    = '\m^\s*\<else\>'
    let pat_com_blank_line  = '\m^\s*\n'
    let pat_com_end         = '\m\<end\>'
    let pat_com_pre_end     = '\m^\s*\<end\>'
    let pat_com_begin       = '\m\<begin\>'
    let pat_com_pre_begin   = '\m^\s*\<begin\>'
    let pat_com_if          = '\m\<if\>'
    let pat_com_begin_if    = '\m\<begin\>\(\s\+\|(.*)[^;]*\)\<if\>'
    let pat_com_if_begin    = '\m\<if\>\s*\<begin\>'


    " current line is preceded by 'module', 'function', 'task', and so on
    if curr_line =~ pat_com_module_pair ||
     \ curr_line =~ pat_com_func_pair   ||
     \ curr_line =~ pat_com_task_pair
        return 0
    endif
    " current line is preceded by 'begin'
    if curr_line =~ pat_com_pre_begin
        if v:lnum > 1
            return indent(v:lnum - 1)
        endif
    endif
    " current line is preceded by 'end', find the corresponding 'begin'
    if curr_line =~ pat_com_pre_end
        let begin_idx = -1
        let i = 1
        while i < v:lnum
            let line = getline(v:lnum - i)
            if begin_idx == -1
                if line =~ pat_com_begin
                    return indent(v:lnum - i)
                elseif line =~ pat_com_end
                    let begin_idx = begin_idx - 1
                endif
            else
                if line =~ pat_com_begin
                    let begin_idx = begin_idx + 1
                elseif line =~ pat_com_end
                    let begin_idx = begin_idx - 1
                endif
            endif
            let i = i + 1
        endwhile
    endif
            
    " current line is preceded by 'else', find the corresponding 'if'
    " Case 1:
    " if (xxx) begin
    "     if (xxx)
    "         xxx;
    " end
    " else 
    "     xxx;
    "
    " Case 2:
    " if (xxx)
    "     xxx;
    " else 
    "     xxx;
    if curr_line =~ pat_com_pre_else
        let begin_end_flag = 0      " no end, no begin
        let i = 1
        while i < v:lnum 
            let line = getline(v:lnum - i)
            if begin_end_flag == 0 
                if line =~ pat_com_end 
                    let begin_end_flag = 1
                elseif line =~ pat_com_if
                    return indent(v:lnum - i)
                endif
            else
                if line =~ pat_com_begin
                    if line =~ pat_com_if_begin
                        return indent(v:lnum - i)
                    else
                        let begin_end_flag = 0
                    endif
                endif
            endif
            let i = i + 1
        endwhile
    endif
    " last line is composed of <Space>, <Tab>
    if last_line =~ pat_com_blank_line
        return 0
    endif
    " last line is preceded by 'begin'
    if last_line =~ pat_com_pre_begin
        return ind + offset
    endif
    " last line is preceded by 'module', 'always', 'function', 'task', and so on
    "if last_line =~ '\m^\s*\<\(always\|module\|function\|task\)\>'
    if last_line =~ pat_com_pre_key
        return ind + offset
    endif
    " last line just like: if (xx) xxx; else xxx;
    if last_line =~ pat_com_if_else
        return ind
    endif
    " last line like: if or else
    if last_line =~ pat_com_if_or_else
        return ind + offset
    endif

    return ind

endfunction

let &cpo = s:cpo_save
unlet s:cpo_save

" vim:sw=2
