# openresty-container

*Multi-Stage OpenResty Container Image*

Comparing to official images, it

- Modifies Nginx runtime configuration *slightly*
- Adds GeoIP support

It also drops a few modules that are not very commonly used (by me):

- HTTP/2
- gRPC
- SCGI
- FastCGI
- Mail server
- Stream server
- Stub status
- Secure link
- Random index
- Auth request
- MP4
- FLV
- DAV

To further customize it, simply ... read the code and change whatever you want to change

```bash
docker build . -t whatever/openresty:1.15.8.2-slim
```
