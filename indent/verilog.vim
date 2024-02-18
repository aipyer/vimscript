" Language:    Verilog HDL
" Maintainer:  Kody He <kody.he@hotmail.com>
" Last Change: 
" URL:         https://github.com/wolikang/vimscript/indent/verilog.vim
"
" Credits:
"   Suggestions for improvement, bug reports by
"
" Buffer Variables:
"     b:verilog_indent_width   : indenting width
"
" TODO:
"   1. Support macro definition like '`if', '`else', etc.
"   2. 

" Only load this indent file when no other was loaded.
if exists("b:did_indent")
    finish
endif
let b:did_indent = 1

setlocal indentexpr=GetVerilogIndent()
setlocal indentkeys=0=always,0=initial,0=module,0=endmodule,0=function,0=endfunction,0=task,0=endtask
setlocal indentkeys+=0=generate,0=endgenerate,0=specify,0=endspecify
setlocal indentkeys+=0=begin,0=end,0=case,0=endcase
setlocal indentkeys+=0=assign,0=input,0=output,0=inout,0=wire,0=reg
setlocal indentkeys+=0=if,0=else
setlocal indentkeys+=0=localparam,0=parameter
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

    let curr_line = getline(v:lnum)
    let last_line = getline(v:lnum - 1)
    let ind = indent(v:lnum - 1)

    " NOTE: By default, 'begin' and 'end' is never on the same line
    "       By default, 'case' and 'endcase' never supports nested usage
    let pat_com_pre_key             = '\m^\s*\<\(always\|initial\|module\|function\|task\)\>'
    let pat_com_pre_always_initial  = '\m^\s*\<\(always\|initial\)\>'
    let pat_com_module_pair         = '\m^\s*\<\(module\|endmodule\)\>'
    let pat_com_func_pair           = '\m^\s*\<\(function\|endfunction\)\>'
    let pat_com_task_pair           = '\m^\s*\<\(task\|endtask\)\>'
    let pat_com_generate_pair       = '\m^\s*\<\(generate\|endgenerate\)\>'
    let pat_com_specify_pair        = '\m^\s*\<\(specify\|endspecify\)\>'
    let pat_com_if_and_else         = '\m\<if\>\s*(.*)[^;]*;\s*\<else\>\s\+[^;]*;'
    let pat_com_if_or_else          = '\m\<\(if\|else\)\>'
    let pat_com_pre_else            = '\m^\s*\<else\>'
    let pat_com_blank_line          = '\m^\s*\n'
    let pat_com_end                 = '\m\<end\>'
    let pat_com_pre_end             = '\m^\s*\<end\>'
    let pat_com_begin               = '\m\<begin\>'
    let pat_com_pre_begin           = '\m^\s*\<begin\>'
    let pat_com_if                  = '\m\<if\>'
    let pat_com_if_begin            = '\m\<if\>\s*(.*)\s*\<begin\>'
    let pat_com_pre_case            = '\m^\s*\<case\>'
    let pat_com_pre_endcase         = '\m^\s*\<endcase\>'
    let pat_com_pre_assign          = '\m^\s*\<assign\>'
    let pat_com_pre_input           = '\m^\s*\<input\>'
    let pat_com_pre_output          = '\m^\s*\<output\>'
    let pat_com_pre_inout           = '\m^\s*\<inout\>'
    let pat_com_pre_wire            = '\m^\s*\<wire\>'
    let pat_com_pre_reg             = '\m^\s*\<reg\>'
    let pat_com_pre_param           = '\m^\s*\<\(parameter\|localparam\)\>'
    let pat_com_inst_param          = '\m^\s*[a-zA-Z][a-zA-Z0-9_]*\s*#('
    let pat_com_pre_right_brackets  = '\m^\s*)'
    let pat_com_left_brackets       = '\m(\(\/\/.*\|\/\*.*\*\/\|\s*\)$'
    let pat_com_left_right_brackets = '\m\((\|)\)'
    let pat_com_pre_case_branch     = '\m^\s*[a-zA-Z_][a-zA-Z0-9_]*:'
    let pat_com_post_begin          = '\m\<begin\>\s*$'

    " current line is preceded by 'always', 'initial', etc.
    if curr_line =~ pat_com_pre_always_initial
        return 0
    endif
    " current line is preceded by 'module', 'function', 'task', etc.
    if curr_line =~ pat_com_module_pair     ||
     \ curr_line =~ pat_com_func_pair       ||
     \ curr_line =~ pat_com_task_pair       ||
     \ curr_line =~ pat_com_generate_pair   ||
     \ curr_line =~ pat_com_specify_pair
        return 0
    endif
    " current line is preceded by 'begin'
    if curr_line =~ pat_com_pre_begin
        if v:lnum > 1
            return indent(v:lnum - 1)
        endif
    endif
    " current line is preceded by 'end', find the corresponding 'begin'
    " Case 1:
    " begin
    "     ...
    " end
    "
    " Case 2: nested usage
    " begin
    "     ...
    "     begin
    "         ...
    "     end
    "     ...
    " end
    "
    " Case 3: (No Support)
    " begin xxx; end
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
    "
    " Case 3: (No Support)
    " if (xxx) begin
    "     sss;
    " end else begin
    "     sss;
    " end
    if curr_line =~ pat_com_pre_else
        let begin_idx = 0                       " no end, no begin
        let i = 1
        while i < v:lnum 
            let line = getline(v:lnum - i)
            if begin_idx == 0 
                if line =~ pat_com_end 
                    let begin_idx = begin_idx - 1
                elseif line =~ pat_com_if
                    return indent(v:lnum - i)
                endif
            else
                if line =~ pat_com_begin
                    if line =~ pat_com_if_begin
                        if begin_idx == -1
                            return indent(v:lnum - i)
                        else
                            let begin_idx = begin_idx + 1
                        endif
                    else
                        let begin_idx = begin_idx + 1
                    endif
                elseif line =~ pat_com_end
                    let begin_idx = begin_idx - 1
                endif
            endif
            let i = i + 1
        endwhile
    endif
    " current line is preceded by 'endcase'
    if curr_line =~ pat_com_pre_endcase
        for i in range(1, v:lnum - 1)
            let line = getline(v:lnum - i)
            if line =~ pat_com_pre_case
                return indent(v:lnum - i)
            endif
        endfor
    endif
    " current line is preceded by 'input', 'output', 'inout', 'wire', 'reg',
    " etc.
    if curr_line =~ pat_com_pre_input   ||
     \ curr_inne =~ pat_com_pre_output  ||
     \ curr_line =~ pat_com_pre_inout   ||
     \ curr_line =~ pat_com_pre_wire    ||
     \ curr_line =~ pat_com_pre_reg 
        return 0
    endif
    " current line is preceded by 'parameter', 'localparam'
    if curr_line =~ pat_com_pre_param
        return 0
    endif
    " current line is preceded by 'assign'
    if curr_line =~ pat_com_pre_assign
        return 0
    endif
    " current line is preceded by ')'
    if curr_line =~ pat_com_pre_right_brackets
        let left_brackets_idx = -1
        for i in range(1, v:lnum - 1)
            let line = getline(v:lnum - i)
            if left_brackets_idx == -1
                if line =~ pat_com_left_right_brackets
                    
                endif
            endif
        endfor
    endif
    " last line is composed of <Space>, <Tab>
    if last_line =~ pat_com_blank_line
        return 0
    endif
    " last line is preceded by 'begin'
    "if last_line =~ pat_com_pre_begin
    if last_line =~ pat_com_post_begin
        return ind + offset
    endif
    " last line is preceded by 'module', 'always', 'function', 'task', etc.
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
    " last line is a branch of 'case' condition
    if last_line =~ pat_com_pre_case_branch
        return ind + offset
    endif
    " last line is preceded by 'case'
    if last_line =~ pat_com_pre_case
        return ind + offset
    endif
    " last line like: xxx #(
    if last_line =~ pat_com_inst_param
        return ind + offset
    endif
    " last line like: ...(
    if last_line =~ pat_com_left_brackets
        return ind + offset
    endif

    return ind

endfunction

let &cpo = s:cpo_save
unlet s:cpo_save

" vim:sw=2
