grep '^Server' /tmp/host.log  | cut -d'|' -f2- | sort -n  > /tmp/server
grep '^Client' /tmp/peer1.log  | cut -d'|' -f2- | sort -n  > /tmp/client
nvim -d /tmp/server /tmp/client
