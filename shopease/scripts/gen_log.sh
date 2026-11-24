#!/bin/bash
# Generates a sample ShopEase web access log (300 lines, same result every time)
pages=(/ /products /cart /checkout /login)
for i in $(seq 1 300); do
  if (( i % 5 == 0 )); then ip="10.0.0.99"; else ip="10.0.0.$(( (i * 7) % 20 + 1 ))"; fi
  case $(( i % 10 )) in
    1) code=500 ;;
    3|7) code=404 ;;
    *) code=200 ;;
  esac
  page=${pages[$(( i % 5 ))]}
  printf '%s - - [15/Nov/2026:10:%02d:%02d +0530] "GET %s HTTP/1.1" %s 512\n' "$ip" $(( i / 60 )) $(( i % 60 )) "$page" "$code"
done
