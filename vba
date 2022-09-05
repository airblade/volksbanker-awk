#!/usr/bin/env bash

[ -z "$1" ] && echo 'Usage: vba FILE' && exit 1

awk -F';' -v OFS=, '

  # 2.345,67 -> 2345.67
  func amt(val, dir) {
    gsub("[.]", "",val)  # remove the thousand-separator (.)
    gsub(",", ".",val)   # use decimal point instead of comma for decimal separator
    return val
  }

  # 30.09.2021 -> 2021/09/30
  func date(val) {
    split(val, parts, ".")

    # fix bad dates at end of february (volksbank produces dates like 30.02.2021)
    if (parts[2] == "02" && parts[1] >= 28)
      parts[1] = "28"

    return parts[1] "/" parts[2] "/" parts[3]
  }

  function quote(str) {
    if (match(str, ","))
      return "\"" str "\""
    else
      return str
  }

  # skip header
  NR == 1 { next }

  # closing balance
  NR == 2 {
    # $5   posting date
    # $13  currency
    # $14  balance after transaction
    print "closing balance: " date($5) ": " amt($14) " " $13 > "/dev/stderr"
  }

  # detect semi-colon within a field, which would be erroneously
  # treated as a field separator; or use csvquote
  NF && NF != 19 {
    print "error parsing line " NR ": " $0 > "/dev/stderr"
    exit 1
  }

  # transactions
  NF {
    # $5   posting date
    # $7   counterparty
    # $11  description
    # $12  amount
    print date($5), amt($12), quote($11 (length($7) ? " (" $7 ")" : ""))
  }
' < "$1"

# vim: ft=awk
