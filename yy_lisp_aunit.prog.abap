*&---------------------------------------------------------------------*
*&  Include           YY_LISP_AUNIT
*&---------------------------------------------------------------------*
*& ported from ZUSR_LISP_TEST by JNN (www.informatik-dv.com)

*&---------------------------------------------------------------------*
*& https://github.com/mydoghasworms/abap-lisp
*& Tests for the Lisp interpreter written in ABAP
*& Copy and paste this code into a type 1 (report) program, making sure
*& the necessary dependencies are met
*&---------------------------------------------------------------------*
*& Martin Ceronio, martin.ceronio@infosize.co.za
*& June 2015
*& MIT License (see below)
*&---------------------------------------------------------------------*
*  The MIT License (MIT)
*
*  Copyright (c) 2015 Martin Ceronio
*
*  Permission is hereby granted, free of charge, to any person obtaining a copy
*  of this software and associated documentation files (the "Software"), to deal
*  in the Software without restriction, including without limitation the rights
*  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
*  copies of the Software, and to permit persons to whom the Software is
*  furnished to do so, subject to the following conditions:
*
*  The above copyright notice and this permission notice shall be included in
*  all copies or substantial portions of the Software.
*
*  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
*  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
*  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
*  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
*  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
*  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
*  THE SOFTWARE.

*----------------------------------------------------------------------*
*       CLASS lcl_output_port DEFINITION
*----------------------------------------------------------------------*
   CLASS lcl_output_port DEFINITION.
     PUBLIC SECTION.
       CLASS-METHODS new
         RETURNING VALUE(ro_port) TYPE REF TO lcl_output_port.
       INTERFACES lif_port.
       ALIASES: write FOR lif_port~write,
                read FOR lif_port~read.
       METHODS get RETURNING VALUE(rv_text) TYPE string.
     PRIVATE SECTION.
       DATA print_offset TYPE i.
       DATA buffer TYPE string.

       METHODS writeln IMPORTING text TYPE string.
       METHODS add IMPORTING text TYPE string.
   ENDCLASS.

*----------------------------------------------------------------------*
*       CLASS lcl_output_port  IMPLEMENTATION
*----------------------------------------------------------------------*
   CLASS lcl_output_port IMPLEMENTATION.

     METHOD new.
       CREATE OBJECT ro_port.
     ENDMETHOD.                    "new

     METHOD get.
       rv_text = buffer.
     ENDMETHOD.                    "get

     METHOD add.
       buffer = buffer && text.
     ENDMETHOD.                    "add

     METHOD writeln.
       add( |\n{ repeat( val = ` ` occ = print_offset ) }{ text }| ).
     ENDMETHOD.                    "writeln

* Write out a given element
     METHOD write.
       DATA lo_elem TYPE REF TO lcl_lisp.
       CHECK element IS BOUND.

       CASE element->type.
         WHEN lcl_lisp=>type_conscell.
           writeln( `(` ).
           lo_elem = element.
           DO.
             ADD 2 TO print_offset.
             write( lo_elem->car ).
             SUBTRACT 2 FROM print_offset.
             IF lo_elem->cdr IS NOT BOUND OR lo_elem->cdr EQ lcl_lisp=>nil.
               EXIT.
             ENDIF.
             lo_elem = lo_elem->cdr.
           ENDDO.
           add( ` )` ).
         WHEN lcl_lisp=>type_number OR lcl_lisp=>type_symbol.
           add( ` ` && element->value ).
       ENDCASE.
     ENDMETHOD.                    "write

     METHOD read.
       rv_input = iv_input.
     ENDMETHOD.

   ENDCLASS.                    "lcl_console IMPLEMENTATION

*----------------------------------------------------------------------*
*       CLASS ltc_interpreter DEFINITION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
   CLASS ltc_interpreter DEFINITION FOR TESTING
     RISK LEVEL HARMLESS DURATION SHORT.
     PROTECTED SECTION.
       "    DATA code TYPE string.
       DATA mo_int TYPE REF TO lcl_lisp_interpreter.
*   Initialize Lisp interpreter
       METHODS test IMPORTING title    TYPE string
                              code     TYPE string
                              actual   TYPE any
                              expected TYPE any
                              level    TYPE aunit_level.
       METHODS test_f IMPORTING title    TYPE string
                                code     TYPE string
                                actual   TYPE numeric
                                expected TYPE numeric.

       METHODS code_test IMPORTING code     TYPE string
                                   expected TYPE any
                                   level    TYPE aunit_level
                                     DEFAULT if_aunit_constants=>critical.
       METHODS code_test_f IMPORTING code     TYPE string
                                     expected TYPE numeric.

       METHODS riff_shuffle_code RETURNING VALUE(code) TYPE string.

     PRIVATE SECTION.
       METHODS setup.
       METHODS teardown.

*   Stability tests - No Dump should occur
       METHODS stability_1 FOR TESTING.
       METHODS stability_2 FOR TESTING.
*--------------------------------------------------------------------*
*   BASIC TESTS
       METHODS: basic_define_error FOR TESTING,
         basic_define_a_23 FOR TESTING,
*     Test strings
         basic_string_value FOR TESTING,
         basic_string_esc_double_quote FOR TESTING,
         basic_string_quot_esc_dbl_quot FOR TESTING,

*     Evaluating multiple expressions
         basic_multiple_expr FOR TESTING.
   ENDCLASS.                    "ltc_interpreter DEFINITION

*----------------------------------------------------------------------*
*       CLASS ltc_interpreter IMPLEMENTATION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
   CLASS ltc_interpreter IMPLEMENTATION.

     METHOD setup.
       CREATE OBJECT mo_int.
     ENDMETHOD.                    "setup

     METHOD teardown.
       FREE mo_int.
     ENDMETHOD.                    "teardown

* Conduct a test with given code
     METHOD test.
       cl_abap_unit_assert=>assert_equals(
         act = actual
         exp = expected
         msg = |Error { title } :{ code }\nActual : { actual }\nExpected :{ expected }\n|
         level = level ).

*    write:/ '<- ', code.
*    write:/ '-> ', actual.
     ENDMETHOD.                    "test

     METHOD test_f.
       cl_abap_unit_assert=>assert_equals_float(
         act = actual
         exp = expected
         msg = |Error { title } :{ code }\n| ).
     ENDMETHOD.                    "test_f

*    Conduct a test with given code
     METHOD code_test.
       test( code = code
             actual = mo_int->eval_source( code )
             expected = expected
             title = 'CODE'
             level = level ).
     ENDMETHOD.                    "code_test

     METHOD code_test_f.
       DATA lv_result TYPE f.
       lv_result = mo_int->eval_source( code ).
       test_f( code = code
               actual = lv_result
               expected = expected
               title = 'CODE' ).
     ENDMETHOD.                    "code_test_f

     METHOD stability_1.
       code_test( code = 'a'
                  expected = `Eval: Symbol a is unbound` ).
     ENDMETHOD.                    "stability_1

     METHOD stability_2.
       code_test( code = '(define a)'
                  expected = `Eval: Incorrect input` ).
     ENDMETHOD.                    "stability_2

     METHOD basic_define_error.
       code_test( code = '(define 22 23)'
                  expected = `Eval: 22 cannot be a variable identifier` ).
     ENDMETHOD.                    "basic_define_error

     METHOD basic_define_a_23.
       code_test( code = '(define a 23)'
                  expected = `a` ).
       code_test( code = 'a'
                  expected = `23` ).
     ENDMETHOD.                    "basic_define_a_23

     METHOD basic_string_value.
       code_test( code = '"string value"'
                  expected = `string value` ).
     ENDMETHOD.                    "basic_string_value

     METHOD basic_string_esc_double_quote.
       code_test( code = '"string value with \" escaped double quote"'
                  expected = 'string value with \" escaped double quote' ).
     ENDMETHOD.                    "basic_string_esc_double_quote

     METHOD basic_string_quot_esc_dbl_quot.
       code_test( code = '(quote "string value with \" escaped double quote")'
                  expected = 'string value with \" escaped double quote' ).
     ENDMETHOD.                    "basic_string_quot_esc_dbl_quot

     METHOD basic_multiple_expr.
*   Evaluating multiple expressions
       code_test( code = '(define a (list 1 2 3 4)) (define b (cdr a)) a b'
                  expected = 'a b ( 1 2 3 4 ) ( 2 3 4 )' ).
     ENDMETHOD.                    "basic_multiple_expr

     METHOD riff_shuffle_code.
       code =
        |(define riff-shuffle | &
        | ( lambda (deck) (begin | &
        | (define take | &
        | (lambda (n seq) (if (<= n 0) (quote ()) (cons (car seq) (take (- n 1) (cdr seq)))))) | &
        | (define drop | &
        | (lambda (n seq) (if (<= n 0) seq (drop (- n 1) (cdr seq)))))| &
        | (define mid | &
        | (lambda (seq) (/ (length seq) 2)))| &
        | ((combine append) (take (mid deck) deck) (drop (mid deck) deck))| &
        | )))|.
     ENDMETHOD.                    "riff_shuffle_code

   ENDCLASS.                    "ltc_interpreter IMPLEMENTATION

*----------------------------------------------------------------------*
*       CLASS ltc_parse DEFINITION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
   CLASS ltc_parse DEFINITION INHERITING FROM ltc_interpreter
     FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.
     PRIVATE SECTION.
       DATA output TYPE REF TO lcl_output_port.

       METHODS setup.
       METHODS teardown.
       METHODS parse IMPORTING code TYPE string.
       METHODS parse_test IMPORTING code     TYPE string
                                    expected TYPE string
                                    level    TYPE aunit_level DEFAULT if_aunit_constants=>critical.
       METHODS empty FOR TESTING.
       METHODS lambda FOR TESTING.
       METHODS lambda_comments FOR TESTING.
       METHODS riff_shuffle FOR TESTING.
   ENDCLASS.                    "ltc_parse DEFINITION

*----------------------------------------------------------------------*
*       CLASS ltc_parse IMPLEMENTATION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
   CLASS ltc_parse IMPLEMENTATION.

     METHOD setup.
       CREATE OBJECT output.
       CREATE OBJECT mo_int.
     ENDMETHOD.                    "setup

     METHOD teardown.
       FREE output.
       FREE mo_int.
     ENDMETHOD.                    "teardown

     METHOD parse.
       DATA elements TYPE lcl_lisp_interpreter=>tt_element.
       DATA element TYPE REF TO lcl_lisp.

       elements = mo_int->parse( code ).
       cl_abap_unit_assert=>assert_not_initial(
         act = lines( elements )
         msg = |No evaluated element from first expression| ).

       READ TABLE elements INDEX 1 INTO element.
       output->write( element ).
     ENDMETHOD.                    "parse

* Test parsing of a given piece of code and write out result
     METHOD parse_test.
       parse( code ).
       test( actual = output->get( )
             code = code
             expected = expected
             title = 'PARSE'
             level = level ).
     ENDMETHOD.                    "parse_test

     METHOD empty.
       parse_test( code = ''
                   expected = | nil| ).
     ENDMETHOD.                    "lambda

     METHOD lambda.
       parse_test( code = '(define a(lambda()20))'
                   expected = |\n( define a\n  ( lambda nil  ) )| ).
     ENDMETHOD.                    "lambda

     METHOD lambda_comments.
       parse_test( code = |;; Comments\n| &
                          |(define a(lambda()20)) ; comments|
                   expected = |\n( define a\n  ( lambda nil  ) )| ).
     ENDMETHOD.                    "lambda

     METHOD riff_shuffle.
       parse_test( code = riff_shuffle_code( )
                   expected =
   |\n( define riff-shuffle\n  ( lambda\n    ( deck )\n    ( begin\n      ( define take\n        ( lambda| &
   |\n          ( n seq )\n          ( if\n            ( <= n  )\n            ( quote nil )\n            ( cons| &
   |\n              ( car seq )\n              ( take\n                ( - n  )\n                ( cdr seq ) ) ) ) ) )| &
   |\n      ( define drop\n        ( lambda\n          ( n seq )\n          ( if\n            ( <= n  ) seq| &
   |\n            ( drop\n              ( - n  )\n              ( cdr seq ) ) ) ) )\n      ( define mid\n| &
   |        ( lambda\n          ( seq )\n          ( /\n            ( length seq )  ) ) )\n      (\n| &
   |        ( combine append )\n        ( take\n          ( mid deck ) deck )\n        ( drop| &
   |\n          ( mid deck ) deck ) ) ) ) )|
             ).
     ENDMETHOD.                    "riff_shuffle

   ENDCLASS.                    "ltc_parse IMPLEMENTATION

*----------------------------------------------------------------------*
*       CLASS ltc_basic DEFINITION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
   CLASS ltc_basic DEFINITION INHERITING FROM ltc_interpreter
     FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.
     PRIVATE SECTION.

       METHODS setup.
       METHODS teardown.

       METHODS quote_19 FOR TESTING.
       METHODS quote_a FOR TESTING.
       METHODS quote_symbol_19 FOR TESTING.
       METHODS quote_symbol_a FOR TESTING.
       METHODS quote_list123 FOR TESTING.

       METHODS set_1 FOR TESTING.
       METHODS set_2 FOR TESTING.
       METHODS set_3 FOR TESTING.

       METHODS let_1 FOR TESTING.
       METHODS let_2 FOR TESTING.
       METHODS let_3 FOR TESTING.

       METHODS letrec_1 FOR TESTING.
       METHODS letrec_2 FOR TESTING.

       METHODS is_symbol_true FOR TESTING.
       METHODS is_symbol_false FOR TESTING.
       METHODS is_hash_true FOR TESTING.
       METHODS is_hash_false FOR TESTING.
       METHODS is_procedure_true FOR TESTING.
       METHODS is_procedure_true_1 FOR TESTING.
       METHODS is_procedure_true_2 FOR TESTING.
       METHODS is_procedure_false FOR TESTING.
       METHODS is_string_true FOR TESTING.
       METHODS is_string_false FOR TESTING.
       METHODS is_number_true FOR TESTING.
       METHODS is_number_false FOR TESTING.

   ENDCLASS.                    "ltc_basic DEFINITION

*----------------------------------------------------------------------*
*       CLASS ltc_basic IMPLEMENTATION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
   CLASS ltc_basic IMPLEMENTATION.

     METHOD setup.
       CREATE OBJECT mo_int.
     ENDMETHOD.                    "setup

     METHOD teardown.
       FREE mo_int.
     ENDMETHOD.                    "teardown

     METHOD quote_19.
       code_test( code = '(quote 19)'
                  expected = '19' ).
     ENDMETHOD.                    "quote_19

     METHOD quote_a.
       code_test( code = '(quote a)'
                  expected = 'a' ).
     ENDMETHOD.                    "quote_a

     METHOD quote_symbol_19.
       code_test( code = '''19'
                  expected = '19' ).
     ENDMETHOD.                    "quote_symbol_19

     METHOD quote_symbol_a.
       code_test( code = '''a'
                  expected = 'a' ).
     ENDMETHOD.                    "quote_symbol_a

     METHOD quote_list123.
       code_test( code = '''(list 1 2 3)'
                  expected = '( list 1 2 3 )' ).
     ENDMETHOD.                    "quote_list123

     METHOD set_1.
       code_test( code = '(define x 3)'
                  expected = 'x' ).
       code_test( code = '(set! x 7)'
                  expected = 'x' ).
       code_test( code = 'x'
                  expected = '7' ).
     ENDMETHOD.                    "set_1

     METHOD set_2.
       code_test( code = '(set! x 5)'
                  expected = 'Eval: Symbol x is unbound' ).
     ENDMETHOD.                    "set_2

     METHOD set_3.
       code_test( code = '(define *seed* 1)'
                  expected = '*seed*' ).
       code_test( code = |(define (srand seed)| &
                         |(set! *seed* seed)| &
                         |*seed*)|
                  expected = 'srand' ).
       code_test( code = '(srand 2)'
                  expected = '2' ).
     ENDMETHOD.

     METHOD let_1.
       code_test( code = '(let ((x 4) (y 5)) (+ x y))'
                  expected = '9' ).
     ENDMETHOD.                    "let_1

     METHOD let_2.
       code_test( code = |(let ((x 2) (y 3))| &
                         |  (let ((foo (lambda (z) (+ x y z)))| &
                         |        (x 7))| &
                         |    (foo 4)))|
                  expected = '9' ).
     ENDMETHOD.

     METHOD let_3.
*      not allowed if we strictly follow the Scheme standard
       code_test( code = |(let ((x 2) (x 0))| &
                         |    (+ x 5))|
                  expected = '5' ).
     ENDMETHOD.

     METHOD letrec_1.
       code_test( code = '(define (not x) (if (eq? x #f) #t #f) )'
                  expected = 'not' ).
       code_test( code = |(letrec ((is-even? (lambda (n)| &
                         |                     (or (zero? n)| &
                         |                         (is-odd? (- n 1)))))| &
                         |         (is-odd? (lambda (n)| &
                         |                     (and (not (zero? n))| &
                         |                          (is-even? (- n 1))))) )| &
                         |(is-odd? 11))|
                  expected = 'true' ).
     ENDMETHOD.

     METHOD letrec_2.
       code_test( code = |(letrec ((a 5)| &
                         |         (b (+ a 3)))| &
                         |b)|
                  expected = '8' ).
     ENDMETHOD.

     METHOD is_symbol_true.
       code_test( code = |(define x 5)|
                  expected = 'x' ).
       code_test( code = |(symbol? 'x)|
                  expected = 'true' ).
       code_test( code = |(symbol? x)|
                  expected = 'false' ).
     ENDMETHOD.

     METHOD is_symbol_false.
       code_test( code = |(symbol? 4)|
                  expected = 'false' ).
     ENDMETHOD.

     METHOD is_hash_true.
       code_test( code = |(define h (make-hash '(dog 4 car 5))|
                  expected = 'h' ).
       code_test( code = |(hash? h)|
                  expected = 'true' ).
     ENDMETHOD.

     METHOD is_hash_false.
       code_test( code = |(hash? 5)|
                  expected = 'false' ).
     ENDMETHOD.

     METHOD is_procedure_true.
       code_test( code = |(define (fn x) (+ x 5))|
                  expected = 'fn' ).
       code_test( code = |(procedure? fn)|
                  expected = 'true' ).
     ENDMETHOD.

     METHOD is_procedure_true_1.
       code_test( code = |(procedure? car)|
                  expected = 'true' ).
       code_test( code = |(procedure? 'car)|
                  expected = 'false' ).
     ENDMETHOD.

     METHOD is_procedure_true_2.
       code_test( code = |(procedure? (lambda (x) (* x x)))|
                  expected = 'true' ).
       code_test( code = |(procedure? '(lambda (x) (* x x)))|
                  expected = 'false' ).
     ENDMETHOD.

     METHOD is_procedure_false.
       code_test( code = |(define x 5)|
                  expected = 'x' ).
       code_test( code = |(procedure? x)|
                  expected = 'false' ).
     ENDMETHOD.

     METHOD is_string_true.
       code_test( code = |(define txt "Badenkop")|
                  expected = 'txt' ).
       code_test( code = |(string? txt)|
                  expected = 'true' ).
     ENDMETHOD.

     METHOD is_string_false.
       code_test( code = |(string? 34)|
                  expected = 'false' ).
     ENDMETHOD.

     METHOD is_number_true.
       code_test( code = |(define n 5)|
                  expected = 'n' ).
       code_test( code = |(number? n)|
                  expected = 'true' ).
     ENDMETHOD.

     METHOD is_number_false.
       code_test( code = |(define d "5")|
                  expected = 'd' ).
       code_test( code = |(number? d)|
                  expected = 'false' ).
     ENDMETHOD.

   ENDCLASS.                    "ltc_basic IMPLEMENTATION

*----------------------------------------------------------------------*
*       CLASS ltc_functional_tests DEFINITION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
   CLASS ltc_functional_tests DEFINITION INHERITING FROM ltc_interpreter
     FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.
     PRIVATE SECTION.
       METHODS setup.
       METHODS teardown.

       METHODS combine.
*   COMBINE + ZIP
       METHODS functional_combine_zip FOR TESTING.

       METHODS functional_compose FOR TESTING.

       METHODS functional_fact_accum FOR TESTING.

   ENDCLASS.                    "ltc_functional_tests DEFINITION

*----------------------------------------------------------------------*
*       CLASS ltc_functional_tests IMPLEMENTATION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
   CLASS ltc_functional_tests IMPLEMENTATION.

     METHOD setup.
       CREATE OBJECT mo_int.
     ENDMETHOD.                    "setup

     METHOD teardown.
       FREE mo_int.
     ENDMETHOD.                    "teardown

     METHOD combine.
       code_test( code = '(define combine (lambda (f) (lambda (x y) (if (nil? x) (quote ()) (f (list (car x) (car y)) ((combine f) (cdr x) (cdr y)))))))'
                  expected = 'combine' ).
     ENDMETHOD.                    "combine

* COMBINE + ZIP
     METHOD functional_combine_zip.
       combine( ).
       code_test( code = '(define zip (combine cons))'
                  expected = 'zip' ).
       code_test( code = 'zip'
                  expected = '<lambda> ( x y )' ).
       code_test( code = '(zip (list 1 2 3 4) (list 5 6 7 8))'
                  expected = '( ( 1 5 ) ( 2 6 ) ( 3 7 ) ( 4 8 ) )' ).
     ENDMETHOD.                    "functional_combine_zip

     METHOD functional_compose.
       combine( ).
       code_test( code = '(define compose (lambda (f g) (lambda (x) (f (g x)))))'
                  expected = 'compose' ).
       code_test( code = '(define repeat (lambda (f) (compose f f)))'
                  expected = 'repeat' ).
       code_test( code = riff_shuffle_code( )
                  expected = 'riff-shuffle' ).
       code_test( code = '(riff-shuffle (list 1 2 3 4 5 6 7 8))'
                  expected = '( 1 5 2 6 3 7 4 8 )' ).
       code_test( code = '((repeat riff-shuffle) (list 1 2 3 4 5 6 7 8))'
                  expected = '( 1 3 5 7 2 4 6 8 )' ).
       code_test( code = '(riff-shuffle (riff-shuffle (riff-shuffle (list 1 2 3 4 5 6 7 8))))'
                  expected = '( 1 2 3 4 5 6 7 8 )' ).
     ENDMETHOD.                    "functional_compose

     METHOD functional_fact_accum.
       code_test( code = '(define (fact x) (define (fact-tail x accum) (if (= x 0) accum (fact-tail (- x 1) (* x accum)))) (fact-tail x 1))'
                  expected = 'fact' ).
       code_test( code = '(fact 8)' "FIXME: returns fact-tail
                  expected = '40320' ).
     ENDMETHOD.                    "functional_fact_accum

   ENDCLASS.                    "ltc_functional_tests IMPLEMENTATION

*----------------------------------------------------------------------*
*       CLASS ltc_math DEFINITION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
   CLASS ltc_math DEFINITION INHERITING FROM ltc_interpreter
     FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.
     PRIVATE SECTION.
       METHODS setup.
       METHODS teardown.

       METHODS math_addition FOR TESTING.

       METHODS math_mult_1 FOR TESTING.
       METHODS math_mult_2 FOR TESTING.
       METHODS math_mult_3 FOR TESTING.

       METHODS math_subtract_1 FOR TESTING.
       METHODS math_subtract_2 FOR TESTING.
       METHODS math_subtract_3 FOR TESTING.

       METHODS math_division_1 FOR TESTING.
       METHODS math_division_2 FOR TESTING.
       METHODS math_division_3 FOR TESTING.
       METHODS math_division_4 FOR TESTING.

       METHODS math_sin FOR TESTING.
       METHODS math_cos FOR TESTING.
       METHODS math_tan FOR TESTING.
       METHODS math_sinh_1 FOR TESTING.
       METHODS math_cosh_1 FOR TESTING.
       METHODS math_tanh_1 FOR TESTING.

       METHODS math_sinh FOR TESTING.
       METHODS math_cosh FOR TESTING.
       METHODS math_tanh FOR TESTING.
       METHODS math_asinh FOR TESTING.
       METHODS math_acosh FOR TESTING.
       METHODS math_atanh FOR TESTING.
       METHODS math_asin FOR TESTING.
       METHODS math_acos FOR TESTING.
       METHODS math_atan FOR TESTING.

       METHODS math_exp FOR TESTING.
       METHODS math_expt FOR TESTING.
       METHODS math_expt_1 FOR TESTING.
       METHODS math_sqrt FOR TESTING.
       METHODS math_log FOR TESTING.

       METHODS math_floor FOR TESTING.
       METHODS math_ceiling FOR TESTING.
       METHODS math_truncate FOR TESTING.
       METHODS math_round FOR TESTING.

       METHODS math_remainder FOR TESTING.
       METHODS math_modulo FOR TESTING.
       METHODS math_random FOR TESTING.

   ENDCLASS.                    "ltc_math DEFINITION

*----------------------------------------------------------------------*
*       CLASS ltc_math IMPLEMENTATION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
   CLASS ltc_math IMPLEMENTATION.

     METHOD setup.
       CREATE OBJECT mo_int.
     ENDMETHOD.                    "setup

     METHOD teardown.
       FREE mo_int.
     ENDMETHOD.                    "teardown

     METHOD math_addition.
       code_test( code = '(+ 22 24 25)'
                  expected = '71' ).
     ENDMETHOD.                    "math_addition

     METHOD math_mult_1.
*   Test multiplication
       code_test( code = '(* 22)'
                  expected = '22' ).
     ENDMETHOD.                    "math_mult_1

     METHOD math_mult_2.
       code_test( code = '(* 11 12)'
                  expected = '132' ).
     ENDMETHOD.                    "math_mult_2

     METHOD math_mult_3.
       code_test( code = '(* 11 12 13)'
                  expected = '1716' ).
     ENDMETHOD.                    "math_mult_3

     METHOD math_subtract_1.
       code_test( code = '(- 22)'
                  expected = '-22' ).
     ENDMETHOD.                    "math_subtract_1

     METHOD math_subtract_2.
       code_test( code = '(- 22 23 24)'
                  expected = '-25' ).
     ENDMETHOD.                    "math_subtract_2

     METHOD math_subtract_3.
       code_test( code = '(- (- (- (- (- 5 1) 1) 1) 1) 1)'
                  expected = '0' ).
     ENDMETHOD.                    "math_subtract_3

     METHOD math_division_1.
*   Test division
       code_test( code = '(/ 2)'
                  expected = '0.5' ).
     ENDMETHOD.                    "math_division_1

     METHOD math_division_2.
       code_test( code =  '(/ 10)'
                  expected = '0.1' ).
     ENDMETHOD.                    "math_division_2

     METHOD math_division_3.
       code_test( code =  '(/ 5 10)'
                  expected = '0.5' ).
     ENDMETHOD.                    "math_division_3

     METHOD math_division_4.
       code_test_f( code =  '(/ 11 12 13)'
                    expected = '0.07051282051282051282051282051282052' ).
     ENDMETHOD.                    "math_division_4

     METHOD math_sin.
       code_test( code =  '(sin 0)'
                  expected = '0' ).
     ENDMETHOD.                    "math_sin

     METHOD math_cos.
       code_test( code =  '(cos 0)'
                  expected = '1' ).
     ENDMETHOD.                    "math_cos

     METHOD math_tan.
       code_test( code =  '(tan 0)'
                  expected = '0' ).
     ENDMETHOD.                    "math_tan

     METHOD math_sinh.
       code_test( code =  '(sinh 0)'
                  expected = '0' ).
     ENDMETHOD.                    "math_sinh

     METHOD math_cosh.
       code_test( code =  '(cosh 0)'
                  expected = '1' ).
     ENDMETHOD.                    "math_cosh

     METHOD math_tanh.
       code_test( code =  '(tanh 0)'
                  expected = '0' ).
     ENDMETHOD.                    "math_tanh

     METHOD math_sinh_1.
       code_test_f( code =  '(sinh 0.5)'
                    expected = '0.52109530549374736162242562641149' ).
     ENDMETHOD.                    "math_sinh_1

     METHOD math_cosh_1.
       code_test_f( code =  '(cosh 1)'
                    expected = '1.5430806348152437784779056207571' ).
     ENDMETHOD.                    "math_cosh_1

     METHOD math_tanh_1.
       code_test_f( code =  '(tanh 1)'
                    expected = '0.76159415595576488811945828260479' ).
     ENDMETHOD.                    "math_tanh_1

     METHOD math_asinh.
       code_test_f( code =  '(asinh 0)'
                    expected = 0 ).
     ENDMETHOD.                    "math_asinh

     METHOD math_acosh.
       code_test_f( code =  '(acosh 1)'
                    expected = 0 ).
     ENDMETHOD.                    "math_acosh

     METHOD math_atanh.
       code_test_f( code =  '(atanh 0)'
                    expected = 0 ).
     ENDMETHOD.                    "math_atanh

     METHOD math_asin.
       code_test_f( code =  '(asin 1)'
                    expected = '1.5707963267948966192313216916398' ).
     ENDMETHOD.                    "math_asin

     METHOD math_acos.
       code_test_f( code =  '(acos 0)'
                    expected = '1.5707963267948966192313216916398' ).
     ENDMETHOD.                    "math_acos

     METHOD math_atan.
       code_test_f( code =  '(atan 1)'
                    expected = '0.78539816339744830961566084581988' ).
     ENDMETHOD.                    "math_atan

     METHOD math_exp.
       code_test_f( code =  '(exp 2)'
                    expected = '7.389056098930650227230427460575' ).
     ENDMETHOD.                    "math_exp

     METHOD math_expt.
       code_test( code =  '(expt 2 10)'
                  expected = '1024' ).
       code_test_f( code =  '(expt 2 0.5)'
                    expected = '1.4142135623730950488016887242097' ).
     ENDMETHOD.                    "math_expt

     METHOD math_expt_1.
       code_test( code =  '(exp 2 10)'
                  expected = 'Eval: ( 2 10 ) Parameter mismatch' ).
     ENDMETHOD.                    "math_expt_1

     METHOD math_sqrt.
       code_test_f( code =  '(sqrt 2)'
                    expected = '1.4142135623730950488016887242097' ).
     ENDMETHOD.                    "math_sqrt

     METHOD math_log.
       code_test_f( code =  '(log 7.389056)'
                    expected = '1.999999986611192' ).
     ENDMETHOD.                    "math_log

     METHOD math_floor.
       "(floor x) - This returns the largest integer that is no larger than x.
       code_test( code =  '(floor 7.3890560989306504)'
                  expected = '7' ).
     ENDMETHOD.                    "math_floor

     METHOD math_ceiling.
       "(ceiling x) - This returns the smallest integer that is no smaller than x.
       code_test( code =  '(ceiling 1.4142135623730951)'
                  expected = '2' ).
     ENDMETHOD.                    "math_ceiling

     METHOD math_truncate.
       "(truncate x) - returns the integer value closest to x that is no larger than the absolute value of x.
       code_test( code =  '(truncate -2.945)'
                  expected = '-2' ).
     ENDMETHOD.                    "math_truncate

     METHOD math_round.
       "(round x) -
*   This rounds value of x to the nearest integer as is usual in mathematics.
*   It even works when halfway between values.
       code_test( code =  '(round 7.389056)'
                  expected = '7' ).
       code_test( code =  '(round 7.789056)'
                  expected = '8' ).
       code_test( code =  '(round -7.789056)'
                  expected = '-8' ).
     ENDMETHOD.                    "math_round

     METHOD math_remainder.
       code_test( code =  '(remainder 5 4)'
                  expected = '1' ).
       code_test( code =  '(remainder -5 4)'
                  expected = '-1' ).
       code_test( code =  '(remainder 5 -4)'
                  expected = '1' ).
       code_test( code =  '(remainder -5 -4)'
                  expected = '-1' ).
     ENDMETHOD.                    "math_remainder

     METHOD math_modulo.
       code_test( code =  '(modulo 5 4)'
                  expected = '1' ).
       code_test( code =  '(modulo -5 4)'
                  expected = '3' ).
       code_test( code =  '(modulo 5 -4)'
                  expected = '-3' ).
       code_test( code =  '(modulo -5 -4)'
                  expected = '-1' ).
     ENDMETHOD.                    "math_modulo

     METHOD math_random.
       code_test( code =  '(random 0)'
                  expected = '0' ).
       code_test( code =  '(begin (define a (random 1)) (or (= a 0) (= a 1)) )'
                  expected = 'true' ).
       code_test( code =  '(random -5 4)'
                  expected = 'Eval: ( -5 4 ) Parameter mismatch' ).
       code_test( code =  '(random -4)'
                  expected = |Eval: { NEW cx_abap_random( textid = '68D40B4034D28D24E10000000A114BF5' )->get_text( ) }| ). " Invalid interval boundaries
       code_test( code =  '(< (random 10) 11)'
                  expected = 'true' ).
       code_test( code =  '(random 100000000000000)'
                  expected = |Eval: { NEW cx_sy_conversion_overflow( textid = '5E429A39EE412B43E10000000A11447B'
                                                                     value = '100000000000000' )->get_text( ) }| ). "Overflow converting from &
     ENDMETHOD.                    "math_modulo

   ENDCLASS.                    "ltc_math IMPLEMENTATION

*----------------------------------------------------------------------*
*       CLASS ltc_list DEFINITION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
   CLASS ltc_list DEFINITION INHERITING FROM ltc_interpreter
     FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.
     PRIVATE SECTION.
       METHODS setup.
       METHODS teardown.

       METHODS is_list_1 FOR TESTING.
       METHODS is_list_2 FOR TESTING.
       METHODS is_list_3 FOR TESTING.
       METHODS is_list_4 FOR TESTING.

       METHODS list_nil_1 FOR TESTING.
       METHODS list_nil_2 FOR TESTING.
       METHODS list_test_1 FOR TESTING.
       METHODS list_test_2 FOR TESTING.
       METHODS list_append_1 FOR TESTING.
       METHODS list_append_error FOR TESTING.
       METHODS list_append_3 FOR TESTING.
       METHODS list_append_arg_0 FOR TESTING.
       METHODS list_append_arg_1 FOR TESTING.
       METHODS list_append_arg_2 FOR TESTING.

       METHODS list_length_0 FOR TESTING.
       METHODS list_length_1 FOR TESTING.
       METHODS list_length_2 FOR TESTING.

       METHODS list_memq_0 FOR TESTING.
       METHODS list_memq_1 FOR TESTING.
       METHODS list_memq_2 FOR TESTING.
       METHODS list_memq_3 FOR TESTING.

       METHODS list_member FOR TESTING.
       METHODS list_memv FOR TESTING.

*   CAR & CDR test
       METHODS list_car_1 FOR TESTING.
       METHODS list_cdr_1 FOR TESTING.
       METHODS list_car_car_cdr FOR TESTING.
       METHODS list_car_nil FOR TESTING.
       METHODS list_car_list FOR TESTING.
       METHODS list_cons_two_lists FOR TESTING.
       METHODS list_cons_with_nil FOR TESTING.
       METHODS list_cons_with_list FOR TESTING.
       METHODS list_cons_two_elems FOR TESTING.

       METHODS code_count.
       METHODS list_count_1 FOR TESTING.
       METHODS list_count_2 FOR TESTING.
   ENDCLASS.                    "ltc_list DEFINITION

*----------------------------------------------------------------------*
*       CLASS ltc_list IMPLEMENTATION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
   CLASS ltc_list IMPLEMENTATION.

     METHOD setup.
       CREATE OBJECT mo_int.
     ENDMETHOD.                    "setup

     METHOD teardown.
       FREE mo_int.
     ENDMETHOD.                    "teardown

     METHOD is_list_1.
       code_test( code = '(list? ''())'
                  expected = 'true' ).
     ENDMETHOD.

     METHOD is_list_2.
       code_test( code = '(list? ''(1))'
                  expected = 'true' ).
     ENDMETHOD.

     METHOD is_list_3.
       code_test( code = '(list? 1)'
                  expected = 'false' ).
     ENDMETHOD.

     METHOD is_list_4.
       code_test( code = '(define x (append ''(1 2) 3))'
                  expected = 'x' ).
       code_test( code = '(list? x)'
                  expected = 'false' ).
     ENDMETHOD.

     METHOD list_nil_1.
*  Test list
       code_test( code = '(list ())'
                  expected = 'nil' ).
     ENDMETHOD.                    "list_nil_1

     METHOD list_nil_2.
       code_test( code = '(list nil)'
                  expected = '( nil )' ).
     ENDMETHOD.                    "list_nil_2

     METHOD list_test_1.
*   Test list
       code_test( code = '(list 22 23 24)'
                  expected = '( 22 23 24 )' ).
     ENDMETHOD.                    "list_test_1

     METHOD list_test_2.
       code_test( code = '(list 22 (list 23 24))'
                  expected = '( 22 ( 23 24 ) )' ).
     ENDMETHOD.                    "list_test_2

     METHOD list_append_1.
*   Test append
       code_test( code = '(append (list 22 (list 23 24)) 23)'
                  expected = '( 22 ( 23 24 ) . 23 )' ).
     ENDMETHOD.                    "list_append_1

     METHOD list_append_error.
       code_test( code = '(append (append (list 22 (list 23 24)) 23) 28)'  "Should give an error
                  expected = 'Eval: ( ( 23 24 ) . 23 ) is not a proper list' ).
     ENDMETHOD.

     METHOD list_append_3.
       code_test( code = '(append (list 1) (list 2))'
                  expected = '( 1 2 )' ).
     ENDMETHOD.                    "list_append_3

     METHOD list_append_arg_0.
       code_test( code = '(append)'
                  expected = 'Eval: Incorrect input' ).
     ENDMETHOD.

     METHOD list_append_arg_1.
       code_test( code = '(append 3)'
                  expected = '3' ).
     ENDMETHOD.

     METHOD list_append_arg_2.
       code_test( code = |(append '(3))|
                  expected = '( 3 )' ).
     ENDMETHOD.

     METHOD list_length_0.
*   Test length
       code_test( code = '(length nil)'
                  expected = '0' ).
     ENDMETHOD.                    "list_length_0

     METHOD list_length_1.
*   Test length
       code_test( code = '(length (list 21 22 23 24))'
                  expected = '4' ).
     ENDMETHOD.                    "list_length_1

     METHOD list_length_2.
       code_test( code = '(length (list 22 (list 23 24)))'
                  expected = '2' ).
     ENDMETHOD.                    "list_length_2

     METHOD list_memq_0.
       code_test( code = |(memq 'a '(a b c))|
                  expected = '( a b c )' ).
     ENDMETHOD.

     METHOD list_memq_1.
       code_test( code = |(memq 'b '(a b c))|
                  expected = '( b c )' ).
     ENDMETHOD.

     METHOD list_memq_2.
       code_test( code = |(memq 'a '(b c d))|
                  expected = 'false' ).
     ENDMETHOD.

     METHOD list_memq_3.
       code_test( code = |(memq (list 'a) '(b (a) c))|
                  expected = 'false' ).
     ENDMETHOD.

     METHOD list_member.
       code_test( code = |(member (list 'a)| &
                         |        '(b (a) c))|
                  expected = '( ( a ) c )' ).
     ENDMETHOD.

     METHOD list_memv.
       code_test( code = |(memv 101 '(100 101 102))|
                  expected = '( 101 102 )' ).
     ENDMETHOD.

* CAR & CDR test
     METHOD list_car_1.
*   Test append
       code_test( code = '(car (list 22 (list 23 24)))'
                  expected = '22' ).
     ENDMETHOD.                    "list_car_1

     METHOD list_cdr_1.
       code_test( code = '(cdr (list 22 (list 23 24)))'
                  expected = '( ( 23 24 ) )' ).
     ENDMETHOD.                    "list_cdr_1

     METHOD list_car_car_cdr.
       code_test( code = '(car (car (cdr (list 22 (list 23 24)))))'
                  expected = '23' ).
     ENDMETHOD.                    "list_car_car_cdr

     METHOD list_car_nil.
       code_test( code = '(car nil)'
                  expected = 'nil' ).
     ENDMETHOD.                    "list_car_nil

     METHOD list_car_list.
       code_test( code = '(car (list 1))'
                  expected = '1' ).
     ENDMETHOD.                    "list_car_list

     METHOD list_cons_two_lists.
*   Test CONS
       code_test( code = '(cons (list 1 2) (list 3 4))'
                  expected = '( ( 1 2 ) 3 4 )' ).
     ENDMETHOD.                    "list_cons_two_lists

     METHOD list_cons_with_nil.
       code_test( code = '(cons 1 nil)'
                  expected = '( 1 )' ).
     ENDMETHOD.                    "list_cons_with_nil

     METHOD list_cons_with_list.
       code_test( code = '(cons 2 (list 3 4))'
                  expected = '( 2 3 4 )' ).
     ENDMETHOD.                    "list_cons_with_list

     METHOD list_cons_two_elems.
       code_test( code = '(cons 2 3)'
                  expected = '( 2 . 3 )' ).
     ENDMETHOD.                    "list_cons_two_elems

     METHOD code_count.
       code_test( code = |(define first car)|
                  expected = 'first' ).
       code_test( code = |(define rest cdr)|
                  expected = 'rest' ).
       code_test( code = |(define (count item L)             | &
                         |  (if (nil? L) 0                   | &
                         |     (+ (if (equal? item (first L)) 1 0)   | &
                         |        (count item (rest L)) )  ))|
                  expected = 'count' ).
     ENDMETHOD.

     METHOD list_count_1.
       code_count( ).
       code_test( code = |(count 0 (list 0 1 2 3 0 0))|
                  expected = '3' ).
     ENDMETHOD.

     METHOD list_count_2.
       code_count( ).
       code_test( code = |(count (quote the) (quote (the more the merrier the bigger the better)))|
                  expected = '4' ).
     ENDMETHOD.

   ENDCLASS.                    "ltc_list IMPLEMENTATION

*----------------------------------------------------------------------*
*       CLASS ltc_library_function DEFINITION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
   CLASS ltc_library_function DEFINITION INHERITING FROM ltc_interpreter
     FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.
     PRIVATE SECTION.
       METHODS setup.
       METHODS teardown.

       METHODS abs FOR TESTING.
   ENDCLASS.                    "ltc_library_function DEFINITION

*----------------------------------------------------------------------*
*       CLASS ltc_library_function IMPLEMENTATION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
   CLASS ltc_library_function IMPLEMENTATION.

     METHOD setup.
       CREATE OBJECT mo_int.
     ENDMETHOD.                    "setup

     METHOD teardown.
       FREE mo_int.
     ENDMETHOD.                    "teardown

     METHOD abs.
       code_test( code = |(define (abs n)| &
                         |  (if (< n 0)| &
                         |  (- n)| &
                         |  n) )|
                  expected = |abs| ).
       code_test( code = |(abs -2)|
                  expected = |2| ).
       code_test( code = |(abs 12)|
                  expected = |12| ).
       code_test( code = |(abs 0)|
                  expected = |0| ).
     ENDMETHOD.                    "abs

   ENDCLASS.                    "ltc_library_function IMPLEMENTATION

*----------------------------------------------------------------------*
*       CLASS ltc_higher_order DEFINITION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
   CLASS ltc_higher_order DEFINITION INHERITING FROM ltc_interpreter
     FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.
     PRIVATE SECTION.
       METHODS setup.
       METHODS teardown.

       METHODS fold_right RETURNING VALUE(code) TYPE string.

       METHODS foldr FOR TESTING.
       METHODS foldl FOR TESTING.
       METHODS map FOR TESTING.
       METHODS filter FOR TESTING.
   ENDCLASS.                    "ltc_higher_order DEFINITION

*----------------------------------------------------------------------*
*       CLASS ltc_higher_order IMPLEMENTATION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
   CLASS ltc_higher_order IMPLEMENTATION.

     METHOD setup.
       CREATE OBJECT mo_int.
     ENDMETHOD.                    "setup

     METHOD teardown.
       FREE mo_int.
     ENDMETHOD.                    "teardown

     METHOD fold_right.
       code = |(define (fold-right f init seq)| &
              |  (if (null? seq)| &
              |  init| &
              |  (f (car seq)| &
              |       (fold-right f init (cdr seq)))))|.
     ENDMETHOD.                    "fold_right

     METHOD foldr.
       code_test( code = fold_right( )
                  expected = 'fold-right' ).
       code_test( code = |(fold-right + 1 (list 1 2 3 7))|
                  expected = '14' ).
       code_test( code = |(define (last lst)| &
                         |  (if (null? lst)| &
                         |    nil| &
                         |    (if (null? (cdr lst))| &
                         |      (car lst)| &
                         |      (last (cdr lst)) )| &
                         |  ))|
                  expected = 'last' ).
       code_test( code = |(define (delete-adjacent-duplicates lst)| &
                         |  (fold-right (lambda (elem ret)| &
                         |                (if (equal? elem (car ret))| &
                         |                    ret| &
                         |                    (cons elem ret)))| &
                         |              (list (last lst))| &
                         |              lst))|
                  expected = 'delete-adjacent-duplicates' ).
       code_test( code = |(delete-adjacent-duplicates '(1 2 3 3 4 4 4 5))|
                  expected = |( 1 2 3 4 5 )| ).
     ENDMETHOD.                    "foldr

     METHOD foldl.
       code_test( code = |(define (fold-left f init seq)| &
                         |  (if (null? seq)| &
                         |  init| &
                         |  (fold-left f| &
                         |             (f init (car seq))| &
                         |             (cdr seq))))|
                  expected = |fold-left| ).
       code_test( code = |(fold-left + 0 (list 1 2 3))|
                  expected = '6' ).

       code_test( code = |(define (reverse l)| &
                         |  (fold-left (lambda (i j)| &
                         |               (cons j i))| &
                         |               '()| &
                         |               l))|
                  expected = |reverse| ).
       code_test( code = |(reverse (list 1 2 3))|
                  expected = '( 3 2 1 )' ).

     ENDMETHOD.                    "foldl

     METHOD map.
       code_test( code = |(define (map f lst)| &
                         |  (if (null? lst)| &
                         |    '()| &
                         |    (cons (f (car lst)) (map f (cdr lst)))))|
                  expected = |map| ).
       code_test( code = |(map (lambda (n) (+ n 3))| &
                         |     '(1 2 3 4 5) )|
                  expected = |( 4 5 6 7 8 )| ).
     ENDMETHOD.                    "map

     METHOD filter.
       code_test( code = fold_right( )
                  expected = 'fold-right' ).
       code_test( code = |(define (filter pred? lst)| &
                         |  (fold-right (lambda (x y) (if (pred? x)| &
                         |                                (cons x y)| &
                         |                                y) )| &
                         |              '() lst))|
                  expected = |filter| ).
       code_test( code = |(filter (lambda (n) (> n 4))| &
                         |     '(1 2 3 4 5 7) )|
                  expected = |( 5 7 )| ).
     ENDMETHOD.                    "filter

   ENDCLASS.                    "ltc_higher_order IMPLEMENTATION

*----------------------------------------------------------------------*
*       CLASS ltc_comparison DEFINITION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
   CLASS ltc_comparison DEFINITION INHERITING FROM ltc_interpreter
     FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.
     PRIVATE SECTION.
       METHODS setup.
       METHODS teardown.

       METHODS compa_gt_1 FOR TESTING.
       METHODS compa_gt_2 FOR TESTING.
       METHODS compa_gt_3 FOR TESTING.
       METHODS compa_gt_4 FOR TESTING.

       METHODS compa_gte_1 FOR TESTING.
       METHODS compa_gte_2 FOR TESTING.
       METHODS compa_gte_3 FOR TESTING.

       METHODS compa_lte_1 FOR TESTING.
       METHODS compa_lte_2 FOR TESTING.
       METHODS compa_lte_3 FOR TESTING.

       METHODS compa_equal_1 FOR TESTING.
       METHODS compa_equal_2 FOR TESTING.
       METHODS compa_equal_3 FOR TESTING.

       METHODS compa_if_1 FOR TESTING.
       METHODS compa_if_2 FOR TESTING.
       METHODS compa_if_3 FOR TESTING.

       METHODS compa_eq_1 FOR TESTING.
       METHODS compa_eq_2 FOR TESTING.
       METHODS compa_eq_3 FOR TESTING.

       METHODS compa_nil_1 FOR TESTING.
       METHODS compa_nil_2 FOR TESTING.
       METHODS compa_nil_3 FOR TESTING.
       METHODS compa_nil_4 FOR TESTING.

       METHODS compa_string FOR TESTING.
   ENDCLASS.                    "ltc_comparison DEFINITION

*----------------------------------------------------------------------*
*       CLASS ltc_comparison IMPLEMENTATION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
   CLASS ltc_comparison IMPLEMENTATION.

     METHOD setup.
       CREATE OBJECT mo_int.
     ENDMETHOD.                    "setup

     METHOD teardown.
       FREE mo_int.
     ENDMETHOD.                    "teardown

     METHOD compa_gt_1.
*   Test GT
       code_test( code = '(> 1 2)'
                  expected = 'false' ).
     ENDMETHOD.                    "compa_gt_1

     METHOD compa_gt_2.
       code_test( code = '(> 2 1)'
                  expected = 'true' ).
     ENDMETHOD.                    "compa_gt_2

     METHOD compa_gt_3.
       code_test( code = '(> 4 3 2 1)'
                  expected = 'true' ).
     ENDMETHOD.                    "compa_gt_3

     METHOD compa_gt_4.
       code_test( code = '(> 4 3 2 2)'
                  expected = 'false' ).
     ENDMETHOD.                    "compa_gt_4
*
     METHOD compa_gte_1.
*   Test GTE
       code_test( code = '(>= 2 2)'
                  expected = 'true' ).
     ENDMETHOD.                    "compa_gte_1

     METHOD compa_gte_2.
       code_test( code = '(>= 4 3 3 2)'
                  expected = 'true' ).
     ENDMETHOD.                    "compa_gte_2

     METHOD compa_gte_3.
       code_test( code = '(>= 1 4)'
                  expected = 'false' ).
     ENDMETHOD.                    "compa_gte_3

     METHOD compa_lte_1.
*   Test LT
       code_test( code = '(< 1 2 3)'
                  expected = 'true' ).
     ENDMETHOD.                    "compa_lte_1

     METHOD compa_lte_2.
       code_test( code = '(< 1 2 2)'
                  expected = 'false' ).
     ENDMETHOD.                    "compa_lte_2

     METHOD compa_lte_3.
       code_test( code = '(< 3 1)'
                  expected = 'false' ).
     ENDMETHOD.                    "compa_lte_3

     METHOD compa_equal_1.
*   Test equal?
       code_test( code = '(equal? 22 23)'
                  expected = 'false' ).
     ENDMETHOD.                    "compa_equal_1

     METHOD compa_equal_2.
       code_test( code = '(equal? 22 22)'
                  expected = 'true' ).
     ENDMETHOD.                    "compa_equal_2

     METHOD compa_equal_3.
       code_test( code = '(equal? (list 21) (list 21))'
                  expected = 'true' ).
     ENDMETHOD.                    "compa_equal_3

     METHOD compa_if_1.
*   Test IF
       code_test( code = '(if 22 23)'
                  expected = '23' ).
     ENDMETHOD.                    "compa_if_1

     METHOD compa_if_2.
       code_test( code = '(if (< 2 1) 23)'
                  expected = 'false' ).
     ENDMETHOD.                    "compa_if_2

     METHOD compa_if_3.
       code_test( code = '(if (< 2 1) 23 24)'
                  expected = '24' ).
     ENDMETHOD.                    "compa_if_3

     METHOD compa_eq_1.
*      Test =
       code_test( code = '(= 2 3)'
                  expected = 'false' ).
     ENDMETHOD.                    "compa_eq_1

     METHOD compa_eq_2.
       code_test( code = '(= 3 3)'
                  expected = 'true' ).
     ENDMETHOD.                    "compa_eq_2

     METHOD compa_eq_3.
*      equality of many things
       code_test( code = '(= (+ 3 4) 7 (+ 2 5))'
                  expected = 'true' ).
     ENDMETHOD.                    "compa_eq_2

     METHOD compa_nil_1.
*      Test nil?
       code_test( code = '(nil? ())'
                  expected = 'Eval: Incorrect input' ).
     ENDMETHOD.                    "compa_nil_1

     METHOD compa_nil_2.
       code_test( code = '(nil? nil)'
                  expected = 'true' ).
     ENDMETHOD.                    "compa_nil_2

     METHOD compa_nil_3.
       code_test( code = '(nil? (cdr (list 1)))'
                  expected = 'true' ).
     ENDMETHOD.                    "compa_nil_3

     METHOD compa_nil_4.
       code_test( code = '(nil? (cdr (list 1 2)))'
                  expected = 'false' ).
     ENDMETHOD.                    "compa_nil_4

     METHOD compa_string.
       code_test( code = '(define str "A string")'
                  expected = 'str' ).
       code_test( code = '(< str "The string")'
                  expected = 'Eval: A string is not a number [<]' ).
     ENDMETHOD.                    "compa_string

   ENDCLASS.                    "ltc_comparison IMPLEMENTATION

*----------------------------------------------------------------------*
*       CLASS ltc_basic_functions DEFINITION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
   CLASS ltc_basic_functions DEFINITION INHERITING FROM ltc_interpreter
     FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.
     PRIVATE SECTION.
       METHODS setup.
       METHODS teardown.

       METHODS funct_lambda_0 FOR TESTING.
       METHODS funct_lambda_1 FOR TESTING.
       METHODS funct_lambda_2 FOR TESTING.

       METHODS funct_fact FOR TESTING.

       METHODS funct_arg_count FOR TESTING.
       METHODS funct_arg_missing FOR TESTING.
   ENDCLASS.                    "ltc_basic_functions DEFINITION

*----------------------------------------------------------------------*
*       CLASS ltc_basic_functions IMPLEMENTATION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
   CLASS ltc_basic_functions IMPLEMENTATION.

     METHOD setup.
       CREATE OBJECT mo_int.
     ENDMETHOD.                    "setup

     METHOD teardown.
       FREE mo_int.
     ENDMETHOD.                    "teardown

     METHOD funct_lambda_0.
       code_test( code = '(define (b n) (* 11 n))'
                  expected = 'b' ).
       code_test( code = 'b'
                  expected = '<lambda> ( n )' ).
       code_test( code = '(b 20)'
                  expected = '220' ).
     ENDMETHOD.                    "funct_lambda_0

     METHOD funct_lambda_1.
*   Test LAMBDA
       code_test( code = '(define b (lambda (b) (* 10 b)))'
                  expected = 'b' ).
       code_test( code = 'b'
                  expected = '<lambda> ( b )' ).
       code_test( code = '(b 20)'
                  expected = '200' ).
     ENDMETHOD.                    "funct_lambda_1

     METHOD funct_lambda_2.
       code_test( code = '((lambda (a) (+ a 20)) 10 )'
                  expected = '30' ).
     ENDMETHOD.                    "funct_lambda_2

     METHOD funct_fact.
*   Function shorthand
       code_test( code = '(define (fact x) (if (= x 0) 1 (* x (fact (- x 1)))))'
                  expected = 'fact' ).
       code_test( code = '(fact 8)'
                  expected = '40320' ).
     ENDMETHOD.                    "funct_fact

     METHOD funct_arg_count.
       code_test( code = '(define (f x y) (+ x y))'
                  expected = 'f' ).
       code_test( code = '(f 1 2 3)'
                  expected = 'Eval: Expected 2 parameter(s), found ( 1 2 3 )' ).
     ENDMETHOD.                    "funct_arg_count

     METHOD funct_arg_missing.
       code_test( code = '(define (add x y) (+ x y))'
                  expected = 'add' ).
       code_test( code = '(add 1)'
                  expected = 'Eval: Missing parameter(s) ( y )' ).
     ENDMETHOD.                    "funct_arg_count

   ENDCLASS.                    "ltc_basic_functions IMPLEMENTATION

*----------------------------------------------------------------------*
*       CLASS ltc_hash_element DEFINITION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
   CLASS ltc_hash_element DEFINITION INHERITING FROM ltc_interpreter
     FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.
     PRIVATE SECTION.
       METHODS setup.
       METHODS teardown.

       METHODS hash FOR TESTING.
   ENDCLASS.                    "ltc_hash_element DEFINITION

*----------------------------------------------------------------------*
*       CLASS ltc_hash_element IMPLEMENTATION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
   CLASS ltc_hash_element IMPLEMENTATION.

     METHOD setup.
       CREATE OBJECT mo_int.
     ENDMETHOD.                    "setup

     METHOD teardown.
       FREE mo_int.
     ENDMETHOD.                    "teardown

     METHOD hash.
*   Hash implementation
       code_test( code = '(define h1 (make-hash ''(dog "bow-wow" cat "meow" kennel (dog cat hedgehog))))'
                  expected = 'h1' ).
       code_test( code = 'h1'
                  expected = '<hash>' ).
       code_test( code = '(hash-keys h1)'
                  expected = '( dog cat kennel )' ).
       code_test( code = '(hash-get h1 ''kennel)'
                  expected = '( dog cat hedgehog )' ).
       code_test( code = '(hash-remove h1 ''kennel)'
                  expected = 'nil' ).
       code_test( code = '(hash-get h1 ''sparrow)'
                  expected = 'nil' ).
       code_test( code = '(hash-insert h1 ''sparrow "whoosh")'
                  expected = 'nil' ).
       code_test( code = '(hash-get h1 ''sparrow)'
                  expected = 'whoosh' ).
       code_test( code = '(hash-keys h1)'
                  expected = '( dog cat sparrow )' ).
     ENDMETHOD.                    "hash

   ENDCLASS.                    "ltc_hash_element IMPLEMENTATION

*----------------------------------------------------------------------*
*       CLASS ltc_abap_integration DEFINITION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
   CLASS ltc_abap_integration DEFINITION INHERITING FROM ltc_interpreter
     FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.
     PRIVATE SECTION.
       METHODS setup.
       METHODS teardown.

       METHODS abap_data_mandt FOR TESTING.
       METHODS abap_data_t005g FOR TESTING.
       METHODS empty_structure FOR TESTING.
       METHODS user_name FOR TESTING.
   ENDCLASS.                    "ltc_abap_integration DEFINITION

*----------------------------------------------------------------------*
*       CLASS ltc_abap_integration IMPLEMENTATION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
   CLASS ltc_abap_integration IMPLEMENTATION.

     METHOD setup.
       CREATE OBJECT mo_int.
     ENDMETHOD.                    "setup

     METHOD teardown.
       FREE mo_int.
     ENDMETHOD.                    "teardown

     METHOD abap_data_mandt.
       code_test( code = '(define mandt (ab-data "MANDT"))'
                  expected = 'mandt' ).
       code_test( code = '(ab-set-value mandt "000")'
                  expected = 'nil' ).
       code_test( code = 'mandt'
                  expected = '<ABAP Data>' ).
     ENDMETHOD.                    "abap_data

     METHOD abap_data_t005g.
       code_test( code = '(define t005g (ab-data "T005G"))'
                  expected = 't005g' ).
       code_test( code = '(ab-set t005g "LAND1" "ZA")'  " Set field "LAND1" to "ZA"
                  expected = 'nil' ).
       code_test( code = '(ab-get t005g "LAND1")'       " Return the value of field "LAND1"
                  expected = 'ZA' ).
     ENDMETHOD.                    "abap_data

     METHOD empty_structure.
       code_test( code = '(define t005g (ab-data "T005G"))'
                  expected = 't005g' ).
       code_test( code = '(ab-set-value t005g ''("000" "ZA" "ABC" "JHB"))'
                  expected = 'nil' ).
       code_test( code = '(ab-get-value t005g)'
                  expected = '( 000 ZA ABC JHB )' ).
       code_test( code = '(ab-get t005g "LAND1")'
                  expected = 'ZA' ).
     ENDMETHOD.                    "empty_structure

     METHOD user_name.
       DATA lv_uname TYPE string.
       lv_uname = sy-uname.
       code_test( code = '(ab-get ab-sy "UNAME")'
                  expected = lv_uname ).
     ENDMETHOD.                    "user_name

   ENDCLASS.                    "ltc_abap_integration IMPLEMENTATION

*----------------------------------------------------------------------*
*       CLASS ltc_abap_function_module DEFINITION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
   CLASS ltc_abap_function_module DEFINITION INHERITING FROM ltc_interpreter
     FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.
     PRIVATE SECTION.
       METHODS setup.
       METHODS teardown.
       METHODS get_first_profile RETURNING VALUE(rv_prof) TYPE xuprofile.
       METHODS get_ip_address RETURNING VALUE(rv_addrstr) TYPE ni_nodeaddr.

       METHODS fm_user_info FOR TESTING.
       METHODS fm_test_rfc FOR TESTING.
       METHODS fm_user_details FOR TESTING.


   ENDCLASS.                    "ltc_abap_function_module DEFINITION

*----------------------------------------------------------------------*
*       CLASS ltc_abap_function_module IMPLEMENTATION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
   CLASS ltc_abap_function_module IMPLEMENTATION.

     METHOD setup.
       CREATE OBJECT mo_int.
     ENDMETHOD.                    "setup

     METHOD teardown.
       FREE mo_int.
     ENDMETHOD.                    "teardown

     METHOD get_ip_address.
       CALL FUNCTION 'TH_USER_INFO'
         IMPORTING
           addrstr = rv_addrstr.
     ENDMETHOD.                    "get_ip_address

     METHOD fm_user_info.
*;(let ( ( f1 (ab-function "TH_USER_INFO")  )  )
*;       ( begin (f1) (ab-get f1 "ADDRSTR")  )
       code_test( code = '(ab-function "TH_USER_INFO")'
                  expected = '<ABAP function module TH_USER_INFO>' ).
       code_test( code = '(define f1 (ab-function "TH_USER_INFO"))'
                  expected = 'f1' ).
       code_test( code = '(f1)'
                  expected = '<ABAP function module TH_USER_INFO>' ).
       code_test( code = '(ab-get f1 "ADDRSTR")'
                  expected = get_ip_address( ) ).
     ENDMETHOD.                    "fm_user_info

     METHOD fm_test_rfc.
*; (let ( (f2 (ab-function "TH_TEST_RFC"))  )
*;        ( begin (ab-set f2 "TEXT_IN" "Calling from ABAP Lisp" )
*;                  (f2) (ab-get f2 "TEXT_OUT")  ) )
       code_test( code = '(define f2 (ab-function "TH_TEST_RFC"))'
                  expected = 'f2' ).
       code_test( code = '(ab-set f2 "TEXT_IN" "Calling from ABAP Lisp")'
                  expected = 'nil' ).
       code_test( code = '(f2)'
                  expected = '<ABAP function module TH_TEST_RFC>' ).
       code_test( code = '(ab-get f2 "TEXT_OUT")'
                  expected = 'Calling from ABAP Lisp' ).
     ENDMETHOD.                    "fm_test_rfc

     METHOD get_first_profile.
       DATA lt_profiles TYPE STANDARD TABLE OF bapiprof.
       DATA ls_profiles TYPE bapiprof.
       DATA lt_return TYPE bapiret2_t.

       CALL FUNCTION 'BAPI_USER_GET_DETAIL'
         EXPORTING
           username = sy-uname
         TABLES
           profiles = lt_profiles
           return   = lt_return.

       READ TABLE lt_profiles INDEX 1 INTO ls_profiles.
       rv_prof = ls_profiles-bapiprof.
     ENDMETHOD.                    "get_first_profile


     METHOD fm_user_details.
*(let (( profiles
*        (let ( (f3 (ab-function "BAPI_USER_GET_DETAIL"))  )
*        ( begin (ab-set f3 "USERNAME" (ab-get ab-sy "UNAME") )
*                  (f3) (ab-get f3 "PROFILES")  ) )
*        ) )
*   (let ((profile (ab-get profiles 1)) )
*             (ab-get profile "BAPIPROF" )  )
*)
       code_test( code = '(define f3 (ab-function "BAPI_USER_GET_DETAIL"))'
                  expected = 'f3' ).
       code_test( code = '(ab-set f3 "USERNAME" (ab-get ab-sy "UNAME"))'
                  expected = 'nil' ).
       code_test( code = '(f3)'
                  expected = '<ABAP function module BAPI_USER_GET_DETAIL>' ).
       code_test( code = '(define profiles (ab-get f3 "PROFILES"))'
                  expected = 'profiles' ).
       code_test( code = 'profiles'
                  expected = '<ABAP Table>' ).

       code_test( code = '(define profile (ab-get profiles 1))'
                  expected = 'profile' ).
       code_test( code = '(ab-get profile "BAPIPROF")'
                  expected = get_first_profile( ) ).
     ENDMETHOD.                    "fm_user_details

   ENDCLASS.                    "ltc_abap_function_module IMPLEMENTATION
