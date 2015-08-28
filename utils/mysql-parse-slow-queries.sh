# uses percona query script to parse MySQL Slow Query log for useful data

wget percona.com/get/pt-query-digest

perl pt-query-digest /var/lib/mysqllogs/slow-log > ~/slow-analysis.txt