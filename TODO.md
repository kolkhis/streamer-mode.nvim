# Streamer Mode TODO

## Regex
* [x] Make Matchadds Case Insensitive

* [x] Hide the contents of all SSH private keys (`id_rsa`, `id_ed25519`, `id_dsa`, etc.)  
  in any `.ssh` directory.  
    * [x] Add full-file conceals for `id_rsa`, `id_ed25519`, etc.
        * i.e., `*/.ssh/*[^\.pub]`
    * [x] Add support for private SSH keys with custom filenames.  

* [ ] Get this to work inside of Telescope pickers/previewers.


* [ ] Add option for user to add custom regex to act as keywords
    * Add `patterns` option to `setup()`
    * Then add those patterns to the `M.patterns`


* [x] Use `matchdelete()` on each match instead of `clearmatches()`
    * This should prevent any conflicts with other plugins/matches.

- [x] Add `exclude_all_default_paths` and `exclude_default_keywords`.

- [x] Make sure `conceallevel` is always returned to its original state.

- [x] Some default options should always be applied - e.g., `conceal_char`

- [x] Added `exclude_all_default_paths` (bool) to config.
    - Set to `true` (default `false`) to exclude all the `paths` in the default config.  
    - There is only one value in the default paths, `'*'` (all paths/anywhere).  

- [x] Added `exclude_all_default_keywords` (bool) to config. Set to `true` 
    (default `false`) to exclude all the `keywords` in the default config.  

- [x] Added `exclude_default_keywords` (table) to config. Add the defaults you wish 
  to exclude in string format.
    * e.g., `exclude_default_keywords = { "alias", "$env:" }`


