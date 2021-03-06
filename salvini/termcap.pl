/*  TERMCAP.PL  */
/*  Shelved on the 3rd of October 1988  */


% Author: Chris Miller, Heriot-Watt
% Written: 28/9/85

% # termcap.
% lib(termcap).
%   defines a number of screen-handling functions using the
%   termcap library to achieve terminal independence.
%   In order for these routines to work, a version of Prolog
%   with the predicate getenv/2 is needed; also, if TERMCAP does
%   not contain the capability string then the program "tset" must
%   exist, since I am too lazy to write the stuff to search the
%   termcap file and pick up the characteristics! There may be very odd
%   problems if more than one user with a given home directory invokes
%   initterm simultaneously, since I have not used a unique temporary file
%   name.
%   If Richard O'Keefe's "autowrap" modifications are incorporated,
%   then odd results will occur unless output is told to '/dev/tty'
%   instead of 'user'.

% The useful functions defined are
%   initterm    set up the capabilities (this is called
%           automatically the first time that it is needed)
%   termcap(Feature, Cap)
%           Feature is a 2-letter atom defining the capability;
%           Cap is unified with one of
%               true            Boolean capability
%               Integer         Numeric capability
%               cap(Pad, String)    String capability
%               []          Capability absent
%   tputs(cap(Pad, String))
%           output String with a guess as to the correct padding!
%           (the guess is based on a linespeed of 9600 baud, and
%           does not take account of the number of lines affected
%           by an operation).
%   cursor(X)   where X is one of
%               left, right, up, down, home
%           performs the appropriate movement. [cursor(down) may
%           not work unless the terminal CRMOD feature has been
%           unset, e.g. by "stty nl"].
%   cursor(Row, Col)
%           direct cursor addressing.
%   clear_screen.
%   clear_to_end_of_screen.
%   clear_line.
%   underline(X)    where X is 'off' or 'on'
%   inverse(X)  where X is 'off' or 'on'
%   standout    inverse if possible, else underline
%   standend    end standout
% #

:- (current_predicate(writef, _) ; lib(writef)).

% # initterm.
%   gets the terminal type and capabilities.
%   In this version, the capabilities are ONLY read from the TERMCAP
%   variable; /etc/termcap and private termcap files are never searched.
% #

initterm:-
    initterm_done,
    !.
initterm :-
    assert(initterm_done),
    getenv('TERMCAP', Termcap),
    name(Termcap, T),
    !,
    initterm(T).
initterm :-
    gettermcap(Termcap),
    assert(terminal_capabilities(Termcap)).
initterm([47 | Rest]) :-
    !,
    gettermcap(Termcap),
    assert(terminal_capabilities(Termcap)).
initterm(Termcap) :-
    assert(terminal_capabilities(Termcap)).

gettermcap(Termcap) :-
    shell("/bin/sh -c >$HOME/.tcap 'eval `SHELL=/bin/sh tset -sQ` echo \$TERMCAP'"),
    seeing(S, '~/.tcap'),
    getstring(Termcap),
    rename('~/.tcap', []),
    see(S).

getstring([Hd|Tl]) :-
    get0(Hd),
    Hd \== 10,
    Hd \== 26,
    !,
    getstring(Tl).
getstring([]).

% # termcap.
% termcap(Capability, Value)
%   unifies Value with the capability for the (2-character atom)
%   Capability.  Value is [] if the capability is missing,
%   true for a boolean capability, and a string or an integer for
%   string or integer capabilities.
% #

termcap(Cap, _) :-
    termcapability(Cap, []),
    !,
    fail.
termcap(Cap, Val) :-
    termcapability(Cap, Val),
    !.
termcap(Cap, Val) :-
    (initterm_done; initterm),
    !,
    terminal_capabilities(Termcap),
    name(Cap, CapName),
    termcap(Termcap, CapName, Val),
    assert(termcapability(Cap, Val)).

termcap([58, Char1, Char2, 58 | List], [Char1, Char2], true) :-     % bool
    !.
termcap([58, Char1, Char2, 35 | List], [Char1, Char2], Val) :-      % int
    leading_int(List, _, 0, Val),
    !.
termcap([58, Char1, Char2, 61 | List], [Char1, Char2], cap(Val, Str)):- % str
    leading_int(List, Rest, 0, Val),
    leading_string(Rest, "", String),
    cap_string(String, Str),
    !.
termcap([92, _, List], Cap, Val) :-
    !,
    termcap(List, Cap, Val).
termcap([_ | List], Cap,  Val) :-
    !,
    termcap(List, Cap, Val).
termcap([], _, []).

leading_int([C | List], L, I, V) :-
    C >= 48,
    C =< 57,
    !,
    X is 10 * I + C - 48,
    leading_int(List, L, X, V).
leading_int(L, L, I, I).

leading_string([58 | _], String, String) :-
    !.
leading_string([92, C | Rest], String, [92, C | S]) :-
    !,
    leading_string(Rest,  String, S).
leading_string([C | Rest], String, [C | S]) :-
    !,
    leading_string(Rest, String, S).

cap_string(String, Cap) :-
    delpad(String, NoPad),
    trans(NoPad, Cap).

delpad([42|String], String) :- !.
delpad(String, String).

trans([94, C | String], [CC | Trans]) :-
    !,
    CC is C mod 32,
    trans(String, Trans).
trans([92, D1, D2, D3 | String], [C | Trans]) :-
    D1 >= 48,
    D1 =< 55,
    D2 >= 48,
    D2 =< 55,
    D3 >= 48,
    D3 =< 55,
    !,
    C is 64 * (D1 - 48) + 8 * (D2 - 48) + (D3 - 48),
    trans(String, Trans).
trans([92, C | String], [BS | Trans]) :-
    backslash(C, BS),
    !,
    trans(String, Trans).
trans([92, C | String], [C | Trans]) :-
    !,
    trans(String, Trans).
trans([], []).
trans([C|String], [C|Trans]) :-
    trans(String, Trans).

backslash(69, 27).
backslash(101, 27).
backslash(78, 10).
backslash(110, 10).
backslash(82, 13).
backslash(114, 13).
backslash(84, 9).
backslash(116, 9).
backslash(66, 8).
backslash(98, 8).
backslash(70, 12).
backslash(102, 12).

% ----------------------------------------------------

clear_screen :-
    termcap(cl, C),
    tputs(C).
clear_to_end_of_screen :-
    termcap(cd, C),
    tputs(C).
clear_line :-
    termcap(dl, C),
    tputs(C).

cursor(left) :-
    termcap(bs, true),
    !,
    put(8).
cursor(left) :-
    termcap(bc, C),
    tputs(C).
cursor(right) :-
    termcap(nd, C),
    tputs(C).
cursor(up) :-
    termcap(up, C),
    tputs(C).
cursor(down) :-
    termcap(do, C),
    tputs(C).
cursor(home) :-
    termcap(ho, H),
    tputs(H).
cursor(Row, Col) :-
    termcap(cm, cap(Pad, CM)),
    pad(Pad),
    cm(CM, Row, Col),
    ttyflush.

cm([], _, _).
cm([37, 100 | Rest], Row, Col) :-
    !,
    write(Row),
    cm(Rest, Col, Row).
cm([37, 50 | Rest], Row, Col) :-
    !,
    writef("%2l", [Row]),
    cm(Rest, Col, Row).
cm([37, 51 | Rest], Row, Col) :-
    !,
    writef("%3l", [Row]),
    cm(Rest, Col, Row).
cm([37, 46 | Rest], Row, Col) :-
    !,
    put(Row),
    cm(Rest, Col, Row).
cm([37, 43, N | Rest], Row, Col) :-
    !,
    M is Row + N,
    put(M),
    cm(Rest, Col, Row).
cm([37, 62, X, Y | Rest], Row, Col) :-
    !,
    ((Row >= X, M is Row + Y); M is Row),
    cm(Rest, M, Col).
cm([37, 114 | Rest], Row, Col) :-
    cm(Rest, Col, Row).
cm([37, C | Rest], Row, Col) :-
    !,
    put(C),
    cm(Rest, Row, Col).
cm([C | Rest], Row, Col) :-
    put(C),
    cm(Rest, Row, Col).

underline(on) :-
    termcap(us, C),
    tputs(C).
underline(off) :-
    termcap(ue, C),
    tputs(C).
inverse(on) :-
    termcap(so, C),
    tputs(C).
inverse(off) :-
    termcap(se, C),
    tputs(C).
standout :-
    inverse(on),
    !.
standout :-
    underline(on).
standend :-
    inverse(off),
    !.
standend :-
    underline(off).

tputs(cap(Pad, S)) :-
    pad(Pad),
    name(N, S),
    write(N),
    ttyflush.

pad :-
    termcap(pc, cap(_,[PC])),
    put(PC).
pad :-
    put(0).
pad(0) :- !.
pad(N) :-
    pad,
    M is N-1,
    pad(M).
