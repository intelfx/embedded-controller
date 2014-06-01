embedded-controller
===================

A tiny bash wrapper around ec_access.c to read and write EC RAM fields using their symbolic names.

1. Decompile your DSDT using iasl.
2. Use `ec_parse_definitions.sh` to parse EmbeddedControl opregion definition from the DSDT.
3. Compile `ec_access.c` tool.
4. Use `ec_access_field.sh` to read and write EC RAM fields.
