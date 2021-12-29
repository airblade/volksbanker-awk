#!/usr/bin/env bash

[ -z "$1" ] && echo 'Usage: vba FILE' && exit 1

# Convert text encoding
iconv -f ISO_8859-1 -t UTF-8 "$1" | \

awk -F'"?;"?' -v OFS=, -v RS="\\r\\n" '

  # 2.345,67 -> 2345.67
  func amt(val, dir) {
    gsub("[.]", "",val)  # remove the thousand-separator (.)
    gsub(",", ".",val)   # use decimal point instead of comma for decimal separator
    return (dir == "H" ? "" : "-") val
  }

  # 30.09.2021 -> 2021-09-30
  #
  # output_type - "balance" - when printing the opening/closing balance
  #             | "line" - when printing a transaction line
  #
  func date(val, output_type) {
    split(val, parts, ".")

    # fix bad dates at end of february (volkbank produces dates like 30.02.2021)
    if (parts[2] == "02" && parts[1] >= 28)
      parts[1] = "28"

    if (output_type == "line")
      return parts[1] "/" parts[2] "/" parts[3]
    else
      return parts[3] "-" parts[2] "-" parts[1]
  }

  func balance(name) {
    # $1   date
    # $11  currency
    # $12  amount
    # $13  debit / credit
    print name " balance: " date($1, "balance") ": " amt($12, $13) " " $11 > "/dev/stderr"
  }

  {
    gsub(/\n/, " ")      # replace LF with a space
    gsub(/^ /, "")       # remove leading space on a line
    gsub(/[ ]+/, " ")    # squeeze runs of space

    # remove leading and trailing quotation marks
    gsub(/^"/, "", $1); gsub(/"$/, "", $NF)
  }

  function quote(str) {
    if (match(str, ","))
      return "\"" str "\""
    else
      return str
  }

  # skip headers
  NR == 1, $1 == "Buchungstag" { next }

  # balances
  $10 == "Anfangssaldo" { balance("opening"); next }
  $10 == "Endsaldo"     { balance("closing"); next }

  # detect semi-colon within a field, which would be erroneously
  # treated as a field separator; or use csvquote
  NF && NF != 13 {
    print "error parsing line " NR ": " $0 > "/dev/stderr"
    exit 1
  }

  # transactions
  NF {
    # $1   posting date
    # $4   counterparty
    # $9   description
    # $12  amount
    # $13  credit (H) / debit (S)
    print date($1, "line"), amt($12, $13), quote($9 (length($4) ? " (" $4 ")" : ""))
  }
'

# vim: ft=awk
