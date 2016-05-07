#!/usr/bin/env python
 
import cgi
import http.client
import json
import sys
import urllib

import cgitb
cgitb.enable()

def do_julia():
    print("Content-Type: application/json")
    print()

    form = cgi.FieldStorage()

    method = form.getvalue("method", "GET")
    cmd = form.getvalue("cmd")

    if cmd == 'eval':
        text = urllib.parse.quote(form.getvalue("text"))
        print("julia raw eval: {r}".format(r=text), file=sys.stderr)
        params = urllib.parse.urlencode({"text": text})
    elif cmd == 'store':
        method = 'PUT'
        val = form.getvalue("val")
        params = urllib.parse.urlencode({
            "keys": form.getvalue("keys"),
            "val": val if val is not None else ''})
    elif cmd == 'fetch':
        params = urllib.parse.urlencode({
            "keys": form.getvalue("keys")})
    elif cmd == 'dirty':
        pass
    else:
        pass

    print("julia: {c} {a}".format(c=cmd, a=params), file=sys.stderr)

    conn = http.client.HTTPConnection("localhost:8080")
    conn.request(method, "/" + cmd + '?' + params)
    response = conn.getresponse()

    res = response.read().decode('utf8')
    print(res, file=sys.stderr)
    print(res)

    conn.close()

do_julia()
