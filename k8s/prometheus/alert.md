global:
  resolve_timeout: 5m
route:
  group_by: ['instance']
  group_wait: 10m
  group_interval: 10s
  repeat_interval: 10m
  receiver: 'web.hook.prometheusalert'
receivers:
- name: 'web.hook.prometheusalert'
  webhook_configs:
  - url: 'http://prometheus-alert-center:8080/prometheus/alert'



# kubectl -n monitoring edit secret alertmanager-main 直接修改
  
  # base64
  Z2xvYmFsOgogIHJlc29sdmVfdGltZW91dDogNW0Kcm91dGU6CiAgZ3JvdXBfYnk6IFsnaW5zdGFuY2UnXQogIGdyb3VwX3dhaXQ6IDEwbQogIGdyb3VwX2ludGVydmFsOiAxMHMKICByZXBlYXRfaW50ZXJ2YWw6IDEwbQogIHJlY2VpdmVyOiAnd2ViLmhvb2sucHJvbWV0aGV1c2FsZXJ0JwpyZWNlaXZlcnM6Ci0gbmFtZTogJ3dlYi5ob29rLnByb21ldGhldXNhbGVydCcKICB3ZWJob29rX2NvbmZpZ3M6CiAgLSB1cmw6ICdodHRwOi8vcHJvbWV0aGV1cy1hbGVydC1jZW50ZXI6ODA4MC9wcm9tZXRoZXVzL2FsZXJ0Jw==