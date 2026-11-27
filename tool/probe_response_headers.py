#!/usr/bin/env python3
"""Inspect RESPONSE HEADERS + server identity + proxy env.

Purpose: the API keeps answering {"code":200,"message":"success"} with NO
"data" key, on BOTH the direct host and the mirror.  That is not what a
working comics API looks like.  Before theorising, establish WHO we are
actually talking to:

  * response headers (Server, Via, X-Cache, CF-Ray, ...)
  * whether an HTTP proxy is configured in the environment (urllib honours
    http_proxy/https_proxy, and a transparent proxy would explain a canned
    200 body)
  * DNS resolution for the hosts
"""
import http.client
import os
import socket
import ssl
import sys
import urllib.parse

HOSTS = [
    ("picaapi.picacomic.com", "/comics?page=1"),
    ("bika-api.jpacg.cc", "/picaapi.picacomic.com/comics?page=1"),
]

print("=== proxy environment ===")
for k in ("http_proxy", "https_proxy", "HTTP_PROXY", "HTTPS_PROXY",
          "ALL_PROXY", "all_proxy", "no_proxy", "NO_PROXY"):
    print("  %-12s = %r" % (k, os.environ.get(k)))

print("\n=== DNS ===")
for host, _ in HOSTS:
    try:
        infos = socket.getaddrinfo(host, 443, proto=socket.IPPROTO_TCP)
        addrs = sorted({i[4][0] for i in infos})
        print("  %-26s -> %s" % (host, ", ".join(addrs)))
    except Exception as e:
        print("  %-26s -> DNS FAIL %r" % (host, repr(e)[:90]))

print("\n=== raw TLS response headers ===")
for host, path in HOSTS:
    print("-" * 74)
    print("HOST %s PATH %s" % (host, path))
    try:
        ctx = ssl.create_default_context()
        conn = http.client.HTTPSConnection(host, 443, timeout=20, context=ctx)
        conn.request("GET", path, headers={
            "api-key": "C69BAF41DA5ABD1FFEDC6D2FEA56B",
            "accept": "application/vnd.picacomic.com.v1+json",
            "app-channel": "3",
            "app-uuid": "defaultUuid",
            "app-version": "2.2.1.3.3.4",
            "image-quality": "original",
            "app-platform": "android",
            "app-build-version": "45",
            "user-agent": "okhttp/3.8.1",
            "version": "v1.5.4",
        })
        resp = conn.getresponse()
        print("  status: %s %s" % (resp.status, resp.reason))
        for k, v in resp.getheaders():
            print("    %-22s %s" % (k, v[:90]))
        body = resp.read()
        print("  body len=%d" % len(body))
        print("  body: %r" % body[:400])
        conn.close()
    except Exception as e:
        print("  FAIL %r" % (repr(e)[:200]))
