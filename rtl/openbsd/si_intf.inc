{
    This file is part of the Free Pascal run time library.
    Copyright (c) 2019 by Free Pascal development team

    This file implements the public interface parts of the startup
    code for OpenBSD programs or shared object (.so) libraries.

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}

{$SMARTLINK OFF}

var
  operatingsystem_parameter_envp: ppchar; public name 'operatingsystem_parameter_envp';
  operatingsystem_parameter_argc: longint; public name 'operatingsystem_parameter_argc';
  operatingsystem_parameter_argv: ppchar; public name 'operatingsystem_parameter_argv';
  environ: ppchar; public name 'environ';
  __progname: pchar = ''; public name '__progname';
  __progname_storage: array [0..255] of char; public name '__progname_storage';