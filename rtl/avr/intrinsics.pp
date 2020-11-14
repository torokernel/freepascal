{

    This file is part of the Free Pascal run time library.
    Copyright (c) 2016 by the Free Pascal development team.

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}
unit intrinsics;

  interface

    const
    {$i cpuinnr.inc}

    procedure avr_cli;[INTERNPROC: in_avr_cli];
    procedure avr_sei;[INTERNPROC: in_avr_sei];
    procedure avr_wdr;[INTERNPROC: in_avr_wdr];
    procedure avr_sleep;[INTERNPROC: in_avr_sleep];
    procedure avr_nop;[INTERNPROC: in_avr_nop];

  implementation

end.

