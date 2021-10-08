#!/usr/bin/env bash

# Convert text encoding
iconv -f ISO_8859-1 -t UTF-8 "$1" | \

# Handle line feeds
awk -v RS="\r\n" '       # line separator is CRLF
  { gsub(/\n/, " ") }    # replace LF with a space
  { gsub(/^ /, "") }     # remove leading space on a line
  { gsub(/[ ]+/, " ") }  # squeeze runs of space
  { print }
' | \

awk -F';' -v OFS=, '
  # 2.345,67 -> 2345.67
  func amt(val, dir) {
    gsub("[.]", "",val)  # remove the thousand-separator (.)
    gsub(",", ".",val)   # use decimal point instead of comma for decimal separator
    return (dir == "H" ? "" : "-")val
  }

  # 30.09.2021 -> 2021-09-30
  func date(val, output_type) {
    split(val, parts, ".")
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

  # remove quotation marks around each field
  { for(i=1; i<=NF; i++) gsub("\"", "", $i) }

  # skip headers
  NR==1, $1=="Buchungstag" { next }

  # balances
  $10 == "Anfangssaldo" { balance("opening"); next }
  $10 == "Endsaldo"     { balance("closing"); next }

  # transactions
  NF {
    # $1   posting date
    # $4   counterparty
    # $9   description
    # $12  amount
    # $13  credit (H) / debit (S)
    print date($1, "line"), amt($12, $13), $9 (length($4) ? " (" $4 ")" : "")
  }
'