```
_    ____ ___ ____ ____ ____ ____ ___ ____ _  _ ____ ____ _  _ 
|    |___  |  [__  |    |___ |__/  |  |    |__| |___ |    |_/  
|___ |___  |  ___] |___ |___ |  \  |  |___ |  | |___ |___ | \_ 
```

# LetsCertCheck

## Introduction

_Lets Cert Check_ retrieves the expiry of provided domains' certificates.

## Availability

_LetsCertCheck_ source is available on
[GitHub](https://github.com/krayon/letscertcheck) and
[GitLab](https://gitlab.com/krayon/letscertcheck with the primary (public)
repository being [GitHub](https://github.com/krayon/letscertcheck) .

_LetsCertCheck_ binary and archive should be signed with my GPG key (
[231A 94F4 81EC F212](http://pgp.mit.edu/pks/lookup?op=get&search=0x231A94F481ECF212)
).

## Bug Tracker

- -

## Usage

```
$ letscertcheck --help

Lets Cert Check v0.00
http://github.com/krayon/letscertcheck/


Lets Cert Check retrieves the expiry of provided domains' certificates.

Usage: letscertcheck.bash -h|--help
       letscertcheck.bash -V|--version
       letscertcheck.bash -C|--configuration
       letscertcheck.bash [-v|--verbose]
               [-x|--example]

-h|--help           - Displays this help
-V|--version        - Displays the program version
-C|--configuration  - Outputs the default configuration that can be placed in
                          /etc/letscertcheck.conf
                      or
                          /home/krayon/.letscertcheckrc
                      for editing.
-n|--nocolour|--nocolor
                    - Output is not coloured. This is the same as setting
                      COLOUR_OUTPUT=0 in your config.
-v|--verbose        - Displays extra debugging information.  This is the same
                      as setting DEBUG=1 in your config.
-x|--example        - Shows example output for a series of test domains.

Example: letscertcheck.bash
```

## Features

- -

## Version History

- v0.0.0
  - Initial version, doesn't do anything :P

## TODO

- Make it do stuff

----
[//]: # ( vim: set ts=4 sw=4 et cindent tw=80 ai si syn=markdown ft=markdown: )
