/*  OPS.PL  */
/*  Shelved on the 3rd of October 1988  */


/****************************************************************************/
/********* PROGRAM: ops *****************************************************/
/****************************************************************************
 
    This program may be used and amended for non-profit making
    purposes on condition that this header be left intact and in situ.
 
    Copyright: Steven Salvini 1986, 1987, 1988
 
    Amended:
            Graeme Sandison: 1987
            Steven Salvini:  1987
            Steven Salvini:  1988
 
 ****************************************************************************
 
    ops:
    declares the operators used
 
 ****************************************************************************/

:- op(900,xfx,:).
:- op(800,xfx,was).
:- op(870,fx,if).
:- op(880,xfx,then).
:- op(450,xfy,#).
:- op(550,xfy,or).
:- op(540,xfy,and).
:- op(530,fx,false).
:- op(300,fx,'derived by').
:- op(300,fx,'derived from').
:- op(600,xfx,from).
:- op(600,xfx,with).
:- op(600,xfx,by).

/****************************************************************************/
/********* END OF PROGRAM: ops **********************************************/
/****************************************************************************/
